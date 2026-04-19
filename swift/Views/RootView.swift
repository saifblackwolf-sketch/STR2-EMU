// RootView.swift — Root view switching between menu and game
// SPDX-License-Identifier: GPL-3.0+

import SwiftUI

struct RootView: View {
  @State private var appState = AppState.shared
  @State private var fileImporter = FileImportHandler.shared
  @AppStorage("iPSX2_ColorScheme") private var colorSchemePreference = 0

  private var preferredColorScheme: ColorScheme? {
    switch colorSchemePreference {
    case 1:
      return .light
    case 2:
      return .dark
    default:
      return nil
    }
  }

  private func updateUIStyle(pref: Int) {
    if !Thread.isMainThread {
      DispatchQueue.main.async {
        updateUIStyle(pref: pref)
      }
      return
    }

    let style: UIUserInterfaceStyle = pref == 1 ? .light : (pref == 2 ? .dark : .unspecified)
    for scene in UIApplication.shared.connectedScenes {
      if let windowScene = scene as? UIWindowScene {
        for window in windowScene.windows {
          window.overrideUserInterfaceStyle = style
        }
      }
    }
  }

  var body: some View {
    ZStack {
      switch appState.currentScreen {
      case .menu:
        Color(uiColor: .systemGroupedBackground)
          .ignoresSafeArea()
        MenuTabView()
      case .playing:
        GameScreenView()
      }
    }
    .onAppear {
      updateUIStyle(pref: colorSchemePreference)
    }
    .onChange(of: colorSchemePreference) { _, newValue in
      updateUIStyle(pref: newValue)
    }
    .preferredColorScheme(preferredColorScheme)
    .onOpenURL { url in
      fileImporter.handleURL(url)
    }
    .alert("File Import", isPresented: $fileImporter.showImportAlert) {
      Button("OK") {}
    } message: {
      Text(fileImporter.lastImportMessage ?? "")
    }
  }
}

struct MenuTabView: View {
  @State private var appState = AppState.shared
  @State private var selectedTab = 0

  var body: some View {
    TabView(selection: $selectedTab) {
      GameListView()
        .tabItem {
          Label("Games", systemImage: "gamecontroller")
        }
        .tag(0)

      BIOSListView()
        .tabItem {
          Label("BIOS", systemImage: "cpu")
        }
        .tag(1)

      HelpView()
        .tabItem {
          Label("Help", systemImage: "questionmark.circle")
        }
        .tag(2)

      NavigationStack {
        SettingsRootView()
      }
      .tabItem {
        Label("Settings", systemImage: "gearshape")
      }
      .tag(3)
    }
    .tint(.blue)
  }
}
