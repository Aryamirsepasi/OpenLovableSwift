//
//  Message.swift
//  OpenLovableSwift
//
//  Created by Arya Mirsepasi on 12.08.25.
//

import Foundation

struct Message: Identifiable, Sendable {
  enum Role { case system, user, assistant }
  let id = UUID()
  let role: Role
  var content: String
}
