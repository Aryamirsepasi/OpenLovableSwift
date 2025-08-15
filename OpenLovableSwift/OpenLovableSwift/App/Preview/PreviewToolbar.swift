//
//  PreviewToolbar.swift
//  OpenLovableSwift
//
//  Created by Arya Mirsepasi on 12.08.25.
//

import SwiftUI

struct PreviewToolbar: View {
  let onReload: () -> Void
  let onOpenInBrowser: () -> Void

  var body: some View {
    HStack(spacing: 8) {
      Label("Preview", systemImage: "safari")
        .font(.subheadline)
        .foregroundStyle(.secondary)
      Spacer()
      Button {
        onReload()
      } label: {
        Label("Reload", systemImage: "arrow.clockwise")
      }
      .buttonStyle(.borderless)

      Button {
        onOpenInBrowser()
      } label: {
        Label("Open in Browser", systemImage: "arrow.up.right.square")
      }
      .buttonStyle(.borderless)
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 6)
    .background(.bar)
  }
}
