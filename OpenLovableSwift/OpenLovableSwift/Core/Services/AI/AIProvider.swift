//
//  Untitled.swift
//  OpenLovableSwift
//
//  Created by Arya Mirsepasi on 12.08.25.
//

import Foundation

public struct AIMessage: Sendable {
    public enum Role: String, Sendable { case system, user, assistant }
    public var role: Role
    public var content: String
    public init(role: Role, content: String) {
        self.role = role
        self.content = content
    }
}

public protocol AIProvider: Sendable {
    /// Stream assistant text chunks.
    func stream(messages: [AIMessage]) -> AsyncThrowingStream<String, Error>
}

