//
//  MessageRow.swift
//  OpenLovableSwift
//
//  Created by Arya Mirsepasi on 12.08.25.
//

import SwiftUI

struct MessageRow: View {
  let message: Message

  var body: some View {
    HStack(alignment: .top, spacing: 8) {
      Circle()
        .fill(avatarColor)
        .frame(width: 10, height: 10)
        .padding(.top, 6)

      VStack(alignment: .leading, spacing: 6) {
        Text(roleTitle)
          .font(.caption)
          .foregroundStyle(.secondary)
        Text(message.content)
          .font(.body)
          .textSelection(.enabled)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
  }

  private var roleTitle: String {
    switch message.role {
    case .system: return "System"
    case .user: return "You"
    case .assistant: return "Lovable"
    }
  }

  private var avatarColor: Color {
    switch message.role {
    case .system: return .gray
    case .user: return .blue
    case .assistant: return .pink
    }
  }
}
