//
//  ConsoleView.swift
//  OpenLovableSwift
//
//  Created by Arya Mirsepasi on 12.08.25.
//

import SwiftUI

struct ConsoleView: View {
  let lines: [String]

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Label("Console", systemImage: "terminal")
          .font(.subheadline)
          .foregroundStyle(.secondary)
        Spacer()
      }
      .padding(.horizontal, 10)
      .padding(.vertical, 6)
      .background(.bar)

      ScrollView {
        LazyVStack(alignment: .leading, spacing: 2) {
          ForEach(lines.indices, id: \.self) { i in
            Text(lines[i])
              .font(.system(.caption, design: .monospaced))
              .frame(maxWidth: .infinity, alignment: .leading)
          }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
      }
      .background(Color(nsColor: .textBackgroundColor))
    }
    .clipShape(RoundedRectangle(cornerRadius: 8))
    .padding(6)
  }
}
