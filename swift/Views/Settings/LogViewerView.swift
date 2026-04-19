// LogViewerView.swift — Improved in-app viewer for pcsx2_log.txt
// SPDX-License-Identifier: GPL-3.0+

import SwiftUI

import UIKit

// Helper Views

struct LogLine: Identifiable {
  let id = UUID()
  let timestamp: String
  let tag: String
  let message: String
  let level: LogLevel

  enum LogLevel {
    case error, warning, info, trace, unknown

    var color: Color {
      switch self {
      case .error: return .red
      case .warning: return .orange
      case .info: return .primary
      case .trace: return .secondary
      case .unknown: return .primary
      }
    }
  }
}
struct LogViewerView: View {
  @Environment(\.openURL) private var openURL
  @AppStorage("logUploadServerURL") private var serverURLString = "http://127.0.0.1:8000/api/logs"

  @State private var settings = SettingsStore.shared

  @State private var rawLogText = ""
  @State private var logLines: [LogLine] = []
  @State private var filteredLines: [LogLine] = []

  @State private var logPath = ""
  @State private var statusMessage = ""
  @State private var searchText = ""

  @State private var showErrors = true
  @State private var showWarnings = true
  @State private var showInfo = true
  @State private var showTrace = false

  @State private var isSendingToServer = false

  private let defaultServerURL = "http://127.0.0.1:8000/api/logs"
  private let maxReadBytes = 500_000  // Increased to 500KB

  private let diagnosticMarkers = [
    "GameDB:", "Serial:", "Enabled Gamefix", "Changing EE/FPU clamp mode",
    "Changing VU1 clamp mode", "not found in GameDB", "@@EE_SEL_PATH@@",
    "@@IOP_SEL_PATH@@", "@@VU_SEL@@", "@@ISO_BOOT@@", "@@GAMEDB_OTA@@",
  ]

  var body: some View {
    VStack(spacing: 0) {
      // Filters and Search
      VStack(spacing: 8) {
        SearchBar(text: $searchText)
          .onChange(of: searchText) { _, _ in applyFilters() }

        HStack {
          FilterChip(title: "Errors", isOn: $showErrors, color: .red)
          FilterChip(title: "Warns", isOn: $showWarnings, color: .orange)
          FilterChip(title: "Info", isOn: $showInfo, color: .blue)
          FilterChip(title: "Trace", isOn: $showTrace, color: .secondary)
          Spacer()

          Menu {
            Button("Reload File") { loadLogs() }
            Button("Clear Search") { searchText = "" }
            Divider()
            Button("Use Localhost URL") { serverURLString = defaultServerURL }
          } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
              .imageScale(.large)
          }
        }
        .padding(.horizontal)
        .onChange(of: showErrors) { _, _ in applyFilters() }
        .onChange(of: showWarnings) { _, _ in applyFilters() }
        .onChange(of: showInfo) { _, _ in applyFilters() }
        .onChange(of: showTrace) { _, _ in applyFilters() }
      }
      .padding(.vertical, 8)
      .background(Color(.systemGroupedBackground))

      // Status Bar
      if !statusMessage.isEmpty {
        Text(statusMessage)
          .font(.caption2)
          .foregroundStyle(.secondary)
          .padding(.horizontal)
          .padding(.vertical, 4)
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(Color(.secondarySystemBackground))
      }

      // Log List
      ScrollViewReader { proxy in
        List {
          ForEach(filteredLines) { line in
            VStack(alignment: .leading, spacing: 2) {
              HStack(alignment: .top) {
                if !line.timestamp.isEmpty {
                  Text(line.timestamp)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.secondary)
                }
                if !line.tag.isEmpty {
                  Text(line.tag)
                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                    .foregroundStyle(line.level.color)
                }
                Spacer()
              }

              Text(line.message)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(line.level.color)
                .textSelection(.enabled)
            }
            .padding(.vertical, 2)
            .id(line.id)
          }
        }
        .listStyle(.plain)
        .overlay {
          if filteredLines.isEmpty {
            ContentUnavailableView(
              "No Logs Found", systemImage: "doc.text.magnifyingglass",
              description: Text("Try changing filters or search terms."))
          }
        }
      }

      // Footer Actions
      HStack {
        VStack(alignment: .leading) {
          Text(logPath.isEmpty ? "No file" : URL(fileURLWithPath: logPath).lastPathComponent)
            .font(.caption2)
            .bold()
          Text(logPath.isEmpty ? "" : logPath)
            .font(.system(size: 8))
            .lineLimit(1)
        }
        .foregroundStyle(.secondary)

        Spacer()

        HStack(spacing: 8) {
          Button {
            iPSX2Bridge.logUserMarker("GLITCH")
          } label: {
            Image(systemName: "bookmark.fill")
          }
          .buttonStyle(.bordered)

          Button {
            iPSX2Bridge.triggerGSDump()
          } label: {
            Image(systemName: "camera.viewfinder")
          }
          .buttonStyle(.bordered)

          Button {
            sendSnapshotToServer()
          } label: {
            Label(isSendingToServer ? "Sending..." : "Snapshot", systemImage: "paperplane.fill")
              .font(.subheadline)
          }
          .buttonStyle(.borderedProminent)
          .disabled(isSendingToServer)
        }
      }
      .padding()
      .background(Color(.systemBackground))
    }
    .navigationTitle("Log Viewer")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItemGroup(placement: .topBarTrailing) {
        Button {
          openLogFile()
        } label: {
          Label("Share", systemImage: "square.and.arrow.up")
        }
      }
    }
    .onAppear {
      loadLogs()
    }
  }

  private func loadLogs() {
    let path = iPSX2Bridge.documentsDirectory() + "/pcsx2_log.txt"
    logPath = path

    let url = URL(fileURLWithPath: path)
    guard FileManager.default.fileExists(atPath: path) else {
      statusMessage = "Log file not found. Start a game first."
      return
    }

    do {
      let data = try Data(contentsOf: url)
      let totalBytes = data.count
      let shownData: Data
      if totalBytes > maxReadBytes {
        shownData = data.suffix(maxReadBytes)
        statusMessage = "Showing last \(maxReadBytes / 1024) KB of \(totalBytes / 1024) KB."
      } else {
        shownData = data
        statusMessage = "Loaded \(totalBytes / 1024) KB."
      }

      rawLogText = String(decoding: shownData, as: UTF8.self)
      parseLogs()
    } catch {
      statusMessage = "Read failed: \(error.localizedDescription)"
    }
  }

  private func parseLogs() {
    let lines = rawLogText.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
    var parsed: [LogLine] = []

    for line in lines {
      if line.isEmpty { continue }

      // Format: [ 0.0000] Prefix: message
      var timestamp = ""
      var tag = ""
      var message = line
      var level: LogLine.LogLevel = .info

      // Extract timestamp
      if line.hasPrefix("["), let closingBracket = line.firstIndex(of: "]") {
        timestamp = String(line[line.index(after: line.startIndex)..<closingBracket])
          .trimmingCharacters(in: .whitespaces)
        message = String(line[line.index(after: closingBracket)...]).trimmingCharacters(
          in: .whitespaces)
      }

      // Extract tag
      if let colonIndex = message.firstIndex(of: ":") {
        let potentialTag = String(message[..<colonIndex]).trimmingCharacters(in: .whitespaces)
        if potentialTag.count < 15 {  // Likely a tag
          tag = potentialTag
          message = String(message[message.index(after: colonIndex)...]).trimmingCharacters(
            in: .whitespaces)
        }
      }

      // Determine level
      let lowerMsg = line.lowercased()
      if lowerMsg.contains("error") || lowerMsg.contains("fatal") || lowerMsg.contains("abort") {
        level = .error
      } else if lowerMsg.contains("warning") || lowerMsg.contains("warn") {
        level = .warning
      } else if lowerMsg.contains("@@") || tag == "R5900" || tag == "IOP" || tag == "VUmacro" {
        level = .trace
      }

      parsed.append(LogLine(timestamp: timestamp, tag: tag, message: message, level: level))
    }

    logLines = parsed
    applyFilters()
  }

  private func applyFilters() {
    filteredLines = logLines.filter { line in
      // Level filter
      switch line.level {
      case .error: if !showErrors { return false }
      case .warning: if !showWarnings { return false }
      case .info: if !showInfo { return false }
      case .trace: if !showTrace { return false }
      case .unknown: break
      }

      // Search filter
      if !searchText.isEmpty {
        let search = searchText.lowercased()
        return line.message.lowercased().contains(search) || line.tag.lowercased().contains(search)
          || line.timestamp.lowercased().contains(search)
      }

      return true
    }

    statusMessage += " Visible: \(filteredLines.count)"
  }

  private func createSnapshotPayload() -> String {
    let device = UIDevice.current
    let info = [
      "[iPSX2 Debug Snapshot]",
      "Date: \(Date().description)",
      "Device: \(device.name) (\(device.systemName) \(device.systemVersion))",
      "Model: \(device.model)",
      "Build: \(iPSX2Bridge.buildVersion())",
      "VM Running: \(iPSX2Bridge.isVMRunning() ? "YES" : "NO")",
      "Core: EE=\(settings.eeCoreType == 0 ? "JIT" : "Interpreter") IOP=\(settings.iopRecompiler ? "JIT" : "Interpreter")",
      "---",
    ].joined(separator: "\n")

    // Take last 200 important lines
    let snapshotLines =
      logLines
      .filter { $0.level == .error || $0.level == .warning || $0.level == .info }
      .suffix(200)
      .map { "[\($0.timestamp)] \($0.tag): \($0.message)" }
      .joined(separator: "\n")

    return info + "\n" + snapshotLines
  }

  private func sendSnapshotToServer() {
    let urlStr = serverURLString.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let url = URL(string: urlStr.hasPrefix("http") ? urlStr : "http://\(urlStr)") else {
      statusMessage = "Invalid Server URL"
      return
    }

    let payload = createSnapshotPayload()
    let body: [String: Any] = [
      "source": "iPSX2-iOS",
      "timestamp": ISO8601DateFormatter().string(from: Date()),
      "device": UIDevice.current.name,
      "snapshot": payload,
    ]

    guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else { return }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = jsonData

    isSendingToServer = true
    statusMessage = "Uploading to \(url.host ?? url.absoluteString)..."

    URLSession.shared.dataTask(with: request) { data, response, error in
      DispatchQueue.main.async {
        isSendingToServer = false
        if let error = error {
          statusMessage = "Upload failed: \(error.localizedDescription)"
        } else if let httpResponse = response as? HTTPURLResponse,
          (200...299).contains(httpResponse.statusCode)
        {
          statusMessage = "Snapshot uploaded successfully!"
        } else {
          statusMessage = "Upload failed (HTTP \((response as? HTTPURLResponse)?.statusCode ?? 0))"
        }
      }
    }.resume()
  }

  private func openLogFile() {
    guard !logPath.isEmpty else { return }
    let url = URL(fileURLWithPath: logPath)
    let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
      let rootVC = windowScene.windows.first?.rootViewController
    {
      vc.popoverPresentationController?.sourceView = rootVC.view
      rootVC.present(vc, animated: true)
    }
  }
}
struct SearchBar: View {
  @Binding var text: String
  var body: some View {
    HStack {
      Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
      TextField("Search logs...", text: $text)
        .textFieldStyle(.plain)
        .autocorrectionDisabled()
        .textInputAutocapitalization(.never)
      if !text.isEmpty {
        Button {
          text = ""
        } label: {
          Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
        }
      }
    }
    .padding(8)
    .background(Color(.secondarySystemGroupedBackground))
    .clipShape(RoundedRectangle(cornerRadius: 10))
    .padding(.horizontal)
  }
}
struct FilterChip: View {
  let title: String
  @Binding var isOn: Bool
  let color: Color
  var body: some View {
    Toggle(title, isOn: $isOn)
      .toggleStyle(.button)
      .buttonStyle(.bordered)
      .tint(isOn ? color : .secondary)
      .controlSize(.small)
  }
}
