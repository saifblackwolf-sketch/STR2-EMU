# Local Log Server

This folder contains a small FastAPI webserver that receives logs from the iPSX2 app and stores them on disk.

## 1) Install dependencies

```powershell
cd tools/log_server
python -m pip install -r requirements.txt
```

## 2) Run the server

```powershell
cd tools/log_server
python -m uvicorn server:app --host 0.0.0.0 --port 8000 --reload
```

## 3) Configure iPSX2

To find your notebook/PC IPv4 on Windows:

```powershell
ipconfig | findstr /R /C:"IPv4"
```

In the app Log Viewer, set `Server URL` to one of these:

- `http://127.0.0.1:8000/api/logs` when running in a simulator on the same machine.
- `http://<YOUR_PC_LOCAL_IP>:8000/api/logs` when running on a physical device in the same network.

Then press `Send Snapshot`.

## 4) View saved logs

- Browser list: `http://127.0.0.1:8000/`
- Raw API list: `http://127.0.0.1:8000/api/logs`
- Files are saved in `tools/log_server/saved_logs/`
