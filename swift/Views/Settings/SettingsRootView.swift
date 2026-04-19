// SettingsRootView.swift — Settings navigation root
// SPDX-License-Identifier: GPL-3.0+

import SwiftUI

struct SettingsRootView: View {
  @AppStorage("iPSX2_ColorScheme") private var colorSchemePreference = 0

  var body: some View {
    List {
      Section("Appearance") {
        HStack {
          Label("Theme", systemImage: "circle.lefthalf.filled")
          Spacer()
          Picker("Theme", selection: $colorSchemePreference) {
            Text("System").tag(0)
            Text("Light").tag(1)
            Text("Dark").tag(2)
          }
          .pickerStyle(.segmented)
          .fixedSize()
        }
      }

      Section {
        NavigationLink {
          EmulatorSettingsView()
        } label: {
          Label("Emulator", systemImage: "cpu")
        }
        NavigationLink {
          GraphicsSettingsView()
        } label: {
          Label("Graphics", systemImage: "paintbrush")
        }
        NavigationLink {
          OverlaySettingsView()
        } label: {
          Label("Overlay (OSD)", systemImage: "text.below.photo")
        }
        NavigationLink {
          GamepadSettingsView()
        } label: {
          Label("Game Controller", systemImage: "gamecontroller")
        }
        NavigationLink {
          VirtualPadSettingsView()
        } label: {
          Label("Virtual Pad", systemImage: "hand.draw")
        }
        NavigationLink {
          LogSettingsView()
        } label: {
          Label("Logs", systemImage: "doc.text.magnifyingglass")
        }
      }

      Section {
        NavigationLink {
          LicenseView()
        } label: {
          Label("Licenses & Credits", systemImage: "doc.text")
        }
      }

      Section("About") {
        HStack {
          Text("Version")
          Spacer()
          Text(iPSX2Bridge.buildVersion())
            .foregroundStyle(.secondary)
            .font(.caption)
        }
      }
    }
    .navigationTitle("Settings")
    .navigationBarTitleDisplayMode(.inline)
  }
}
