//
//  ProjectSandbox.swift
//  OpenLovableSwift
//
//  Created by Arya Mirsepasi on 12.08.25.
//

import Foundation

struct ProjectSandbox {
  func createNewProject(named name: String? = nil) throws -> URL {
    let base = FileManager.default.temporaryDirectory
      .appendingPathComponent("OpenLovableSwift", isDirectory: true)
    try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
    let slug = (name?.replacingOccurrences(of: " ", with: "-").lowercased() ?? "project")
    let url = base.appendingPathComponent("\(slug)-\(UUID().uuidString.prefix(8))", isDirectory: true)
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
  }

  func write(files: [GeneratedFile], into root: URL) throws {
    try FileWriter().write(files: files, into: root)
  }
}
