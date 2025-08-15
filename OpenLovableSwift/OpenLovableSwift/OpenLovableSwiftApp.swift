//
//  OpenLovableSwiftApp.swift
//  OpenLovableSwift
//
//  Created by Arya Mirsepasi on 12.08.25.
//

import SwiftUI
import Observation
import AIProxy

@main
struct OpenLovableSwiftApp: App {
  @State private var appState = AppState()

  init() {
    AIProxy.configure(
      logLevel: .debug,
      printRequestBodies: false,
      printResponseBodies: false,
      resolveDNSOverTLS: true,
      useStableID: false
    )
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environment(appState)
    }
    .windowResizability(.contentSize)

    Settings {
      SettingsView()
        .environment(appState)
        .frame(minWidth: 520, minHeight: 440)
    }
  }
}
