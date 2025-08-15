//
//  ContentView.swift
//  OpenLovableSwift
//
//  Created by Arya Mirsepasi on 12.08.25.
//

import SwiftUI

struct ContentView: View {
  @Environment(AppState.self) private var app

  var body: some View {
      NavigationSplitView {
        ChatView()
          .navigationTitle("Chat")
          .frame(minWidth: 280)
      } content: {
      VStack(spacing: 0) {
        HStack {
          Text("Project").font(.headline)
          Spacer()
          Text(app.project.name).foregroundStyle(.secondary)
        }
        .padding(.horizontal).padding(.top, 8)

        Divider()

        HSplitView {
            FileTreeView(selection: Binding(
              get: { app.selectedFileID },
              set: { newValue in
                if let id = newValue { app.selectFile(id) }
              }
            ))
          .frame(minWidth: 220, idealWidth: 260)

          CodeEditorView(
            text: Binding(
              get: { selectedFileContent ?? "" },
              set: { app.updateSelectedFileContent($0) }
            ),
            fileName: selectedFile?.name
          )
          .frame(minWidth: 380)
        }

        Divider()

        ConsoleView(lines: app.logs)
          .frame(minHeight: 120, idealHeight: 160)
      }
    } detail: {
      VStack(spacing: 0) {
        PreviewToolbar(
          onReload: reloadPreview,
          onOpenInBrowser: openInBrowser
        )
        if let url = app.previewURL {
          WebPreviewView(url: url)
        } else {
          ContentUnavailableView("No Preview", systemImage: "safari", description: Text("Start the dev server to see your app here."))
        }
      }
    }
    .navigationSplitViewStyle(.balanced)
  }

  private var selectedFile: FileNode? {
    guard let id = app.selectedFileID else { return nil }
    return app.project.allFiles().first { $0.id == id }
  }

  private var selectedFileContent: String? { selectedFile?.content }

  private func reloadPreview() {
    guard let base = app.previewURL?.absoluteString else { return }
    app.previewURL = URL(string: "\(base)\(base.contains("?") ? "&" : "?")ts=\(Int(Date().timeIntervalSince1970))")
  }

  private func openInBrowser() {
    guard let url = app.previewURL else { return }
    NSWorkspace.shared.open(url)
  }
}

