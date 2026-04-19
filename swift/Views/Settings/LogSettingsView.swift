// LogSettingsView.swift — Unified logging and debug settings
// SPDX-License-Identifier: GPL-3.0+

import SwiftUI

struct LogSettingsView: View {
  @State private var settings = SettingsStore.shared
  @AppStorage("logUploadServerURL") private var logUploadServerURL =
    "http://127.0.0.1:8000/api/logs"

  var body: some View {
    Form {
      Section {
        NavigationLink {
          LogViewerView()
        } label: {
          Label("View Log File", systemImage: "doc.text.magnifyingglass")
        }
      } footer: {
        Text("View the local PCSX2 log file (pcsx2_log.txt).")
      }

      Section("UDP Log Server") {
        Toggle("Enable UDP Streaming", isOn: $settings.logServerEnabled)

        HStack {
          Text("Host")
          TextField("127.0.0.1", text: $settings.logServerHost)
            .multilineTextAlignment(.trailing)
            .keyboardType(.numbersAndPunctuation)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
        }
        .disabled(!settings.logServerEnabled)
        .opacity(settings.logServerEnabled ? 1.0 : 0.5)

        HStack {
          Text("Port")
          TextField("5050", value: $settings.logServerPort, format: .number)
            .multilineTextAlignment(.trailing)
            .keyboardType(.numberPad)
        }
        .disabled(!settings.logServerEnabled)
        .opacity(settings.logServerEnabled ? 1.0 : 0.5)

        Toggle("Include Timestamps", isOn: $settings.logTimestamps)

        Text("Stream live logs to your computer running tools/log_server/server.py")
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Section("Log Upload Server") {
        TextField("Server URL", text: $logUploadServerURL)
          .textInputAutocapitalization(.never)
          .autocorrectionDisabled()
          .keyboardType(.URL)

        Text("Server for sending log snapshots (e.g. for debugging).")
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Section("Debug") {
        Toggle("Instruction Tracing", isOn: $settings.traceExecution)
        Text("Massive logging to UDP Log Server (very slow!). Requires Interpreter cores.")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .navigationTitle("Logs")
    .navigationBarTitleDisplayMode(.inline)
  }
}
