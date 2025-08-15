//
//  Project.swift
//  OpenLovableSwift
//
//  Created by Arya Mirsepasi on 12.08.25.
//

import Foundation

struct Project: Sendable {
  var name: String
  var rootPath: String
  var files: [FileNode] // tree

  static func empty() -> Project { .init(name: "Untitled", rootPath: "", files: []) }

  var defaultSelectedFileID: UUID? {
    // pick the first JS/TS/TSX file if available
    allFiles().first(where: { $0.path.hasSuffix(".tsx") || $0.path.hasSuffix(".ts") || $0.path.hasSuffix(".jsx") || $0.path.hasSuffix(".js") })?.id
      ?? allFiles().first?.id
  }

  func allFiles() -> [FileNode] {
    func walk(_ node: FileNode) -> [FileNode] {
      if node.isDirectory { return node.children.flatMap(walk) }
      else { return [node] }
    }
    return files.flatMap(walk)
  }

  mutating func updateFileContent(id: UUID, content: String) {
    func update(_ nodes: inout [FileNode]) {
      for i in nodes.indices {
        if nodes[i].id == id, !nodes[i].isDirectory {
          nodes[i].content = content
          return
        }
        if nodes[i].isDirectory {
          update(&nodes[i].children)
        }
      }
    }
    update(&files)
  }
}

struct FileNode: Identifiable, Hashable, Sendable {
  let id: UUID
  var name: String
  var path: String        // relative path from project root
  var isDirectory: Bool
  var children: [FileNode] = []
  var content: String? = nil // only for files
    var childNodes: [FileNode]? {
      isDirectory ? children : nil
    }

  init(id: UUID = UUID(), name: String, path: String, isDirectory: Bool, children: [FileNode] = [], content: String? = nil) {
    self.id = id
    self.name = name
    self.path = path
    self.isDirectory = isDirectory
    self.children = children
    self.content = content
  }
}
