//
//  FileWriter.swift
//  OpenLovableSwift
//
//  Created by Arya Mirsepasi on 12.08.25.
//

import Foundation

struct FileWriter {
  func write(files: [GeneratedFile], into root: URL) throws {
    for f in files {
      let dst = root.appendingPathComponent(f.path)
      try FileManager.default.createDirectory(at: dst.deletingLastPathComponent(),
                                              withIntermediateDirectories: true)
      try f.content.data(using: .utf8)?.write(to: dst, options: .atomic)
    }
  }
}
