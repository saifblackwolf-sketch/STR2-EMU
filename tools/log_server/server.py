from __future__ import annotations

import asyncio
import html
import re
import socket
from datetime import datetime
from pathlib import Path

from fastapi import FastAPI, HTTPException
from fastapi.responses import HTMLResponse, PlainTextResponse
from pydantic import BaseModel
import uvicorn

BASE_DIR = Path(__file__).resolve().parent
LOG_DIR = BASE_DIR / "saved_logs"
LOG_DIR.mkdir(parents=True, exist_ok=True)

app = FastAPI(title="iPSX2 Unified Log Server")

class LogUpload(BaseModel):
    source: str = "iPSX2"
    timestamp: str | None = None
    log_path: str | None = None
    snapshot: str

def _safe_name(value: str) -> str:
    cleaned = re.sub(r"[^a-zA-Z0-9._-]", "_", value.strip())
    return cleaned or "unknown"

# --- HTTP Routes ---

@app.get("/", response_class=HTMLResponse)
def index() -> str:
    files = sorted(LOG_DIR.glob("*.log"), key=lambda p: p.stat().st_mtime, reverse=True)
    items = "\n".join(
        f'<li><a href="/logs/{html.escape(p.name)}">{html.escape(p.name)}</a></li>'
        for p in files
    )

    return f"""
    <html>
      <head>
        <title>iPSX2 Unified Log Viewer</title>
        <style>
          body {{ font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace; margin: 2rem; background: #121212; color: #e0e0e0; }}
          h1 {{ color: #bb86fc; }}
          a {{ color: #03dac6; }}
          .hint {{ color: #999; margin-bottom: 1rem; }}
          ul {{ list-style-type: none; padding: 0; }}
          li {{ padding: 0.5rem 0; border-bottom: 1px solid #333; }}
        </style>
      </head>
      <body>
        <h1>iPSX2 Logs</h1>
        <div class="hint">TCP Live Port: 5050 | HTTP API: 8000</div>
        <ul>{items or '<li>No logs yet</li>'}</ul>
      </body>
    </html>
    """

@app.post("/api/logs")
def upload_log(payload: LogUpload) -> dict[str, str]:
    snapshot = payload.snapshot.strip()
    if not snapshot:
        raise HTTPException(status_code=400, detail="snapshot must not be empty")

    now = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
    source = _safe_name(payload.source)
    filename = f"{now}_{source}_snapshot.log"
    output_file = LOG_DIR / filename

    header = [
        f"received_at_utc: {datetime.utcnow().isoformat()}Z",
        f"source: {payload.source}",
        f"client_timestamp: {payload.timestamp or ''}",
        f"client_log_path: {payload.log_path or ''}",
        "type: snapshot",
        "---",
        ""
    ]

    output_file.write_text("\n".join(header) + snapshot + "\n", encoding="utf-8")
    print(f"[*] Received HTTP snapshot: {filename}")
    return {"ok": "true", "file": filename}

@app.get("/logs/{file_name}", response_class=PlainTextResponse)
def read_log(file_name: str) -> str:
    safe_name = Path(file_name).name
    file_path = LOG_DIR / safe_name
    if not file_path.exists() or file_path.suffix != ".log":
        raise HTTPException(status_code=404, detail="log file not found")
    return file_path.read_text(encoding="utf-8")

# --- TCP Live Logger ---

async def handle_tcp_client(reader: asyncio.StreamReader, writer: asyncio.StreamWriter):
    addr = writer.get_extra_info('peername')
    print(f"[*] New TCP connection from {addr}")
    
    # Create a file for this session
    now = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
    filename = f"{now}_live_stream.log"
    file_path = LOG_DIR / filename
    
    try:
        with open(file_path, "a", encoding="utf-8") as f:
            f.write(f"--- Live Stream Started: {datetime.utcnow().isoformat()}Z ---\n")
            f.flush()
            
            while True:
                data = await reader.read(8192)
                if not data:
                    break
                
                text = data.decode('utf-8', errors='ignore')
                # Print to console (strip ANSI if needed, but keeping for now)
                print(text, end='', flush=True)
                
                # Write to file
                f.write(text)
                f.flush()
                
    except Exception as e:
        print(f"[!] TCP Error: {e}")
    finally:
        print(f"[*] Connection closed from {addr}. Saved to {filename}")
        writer.close()
        await writer.wait_closed()

async def run_tcp_server():
    server = await asyncio.start_server(handle_tcp_client, '0.0.0.0', 5050)
    addr = server.sockets[0].getsockname()
    print(f"[*] TCP Log Server listening on {addr}")
    async with server:
        await server.serve_forever()

# --- Entry Point ---

async def main():
    # Run FastAPI and TCP Server concurrently
    config = uvicorn.Config(app, host="0.0.0.0", port=8000, log_level="warning")
    server = uvicorn.Server(config)
    
    await asyncio.gather(
        server.serve(),
        run_tcp_server()
    )

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        pass
