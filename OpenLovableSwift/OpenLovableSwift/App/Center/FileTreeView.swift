//
//  FileTreeView.swift
//  OpenLovableSwift
//
//  Created by Arya Mirsepasi on 12.08.25.
//

import SwiftUI

struct FileTreeView: View {
  @Environment(AppState.self) private var app
  @Binding var selection: UUID?

  var body: some View {
    ScrollView {
        OutlineGroup(app.project.files, children: \.childNodes) { node in
          HStack {
            Image(systemName: node.isDirectory ? "folder" : icon(for: node.name))
              .foregroundStyle(node.isDirectory ? .yellow : .secondary)
            Text(node.name)
              .font(node.isDirectory ? .callout.weight(.semibold) : .callout)
            Spacer()
          }
          .padding(.vertical, 3)
          .contentShape(Rectangle())
          .background(
            (selection == node.id ? Color.accentColor.opacity(0.12) : .clear)
              .clipShape(RoundedRectangle(cornerRadius: 6))
          )
          .onTapGesture {
            if !node.isDirectory { selection = node.id }
          }
          .padding(.leading, node.isDirectory ? 0 : 8)
          .padding(.horizontal, 8)
        }
      .padding(.vertical, 8)
    }
    .background(.regularMaterial.opacity(0.2))
  }

  private func icon(for name: String) -> String {
    if name.hasSuffix(".tsx") || name.hasSuffix(".jsx") { return "chevron.left.forwardslash.chevron.right" }
    if name.hasSuffix(".ts") || name.hasSuffix(".js")   { return "chevron.left.forwardslash.chevron.right" }
    if name.hasSuffix(".css")                            { return "curlybraces.square" }
    if name.hasSuffix(".json")                           { return "doc.plaintext" }
    if name.hasSuffix(".html")                           { return "doc.richtext" }
    return "doc"
  }
}
