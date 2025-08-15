//
//  ZipExporter.swift
//  OpenLovableSwift
//
//  Created by Arya Mirsepasi on 12.08.25.
//

import Foundation
import Compression

struct ZipExporter {
  func createZip(of root: URL, to destination: URL) throws {
    // Use /usr/bin/zip for simplicity & reliability
    let out = try ProcessRunner.run("/usr/bin/env", ["zip", "-r", destination.path, "."], cwd: root)
    if out.code != 0 { throw ProcessError.nonZeroExit(code: out.code, stderr: out.stderr) }
  }
}
