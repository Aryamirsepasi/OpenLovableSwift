//
//  NodeDoctor.swift
//  OpenLovableSwift
//
//  Created by Arya Mirsepasi on 12.08.25.
//

import Foundation

struct NodeDoctorResult: Sendable {
  var ok: Bool
  var npmPath: String?
  var nodePath: String?
  var message: String
}

enum NodeDoctor {
  static func check() -> NodeDoctorResult {
    func which(_ tool: String) -> String? {
      (try? ProcessRunner.run("/usr/bin/env", ["which", tool]).stdout.trimmingCharacters(in: .whitespacesAndNewlines))
        .flatMap { $0.isEmpty ? nil : $0 }
    }

    let nodePath = which("node")
    let npmPath  = which("npm")

    // Try running "npm -v" to catch EPERM
    if let npmPath {
      let out = try? ProcessRunner.run("/usr/bin/env", ["npm", "-v"])
      if let out, out.code == 0 {
        return .init(ok: true, npmPath: npmPath, nodePath: nodePath, message: "npm OK: \(out.stdout.trimmingCharacters(in: .whitespacesAndNewlines))")
      } else {
        let msg = (out?.stderr ?? out?.stdout ?? "unknown").lowercased()
        if msg.contains("operation not permitted") {
          return .init(ok: false, npmPath: npmPath, nodePath: nodePath,
                       message: "Sandbox is blocking execution of npm/node. Disable App Sandbox for dev, or embed Node in the app bundle. stderr: \(out?.stderr ?? "")")
        }
        return .init(ok: false, npmPath: npmPath, nodePath: nodePath,
                     message: "npm failed to run. stderr: \(out?.stderr ?? "")")
      }
    } else {
      return .init(ok: false, npmPath: nil, nodePath: nodePath, message: "npm not found in PATH.")
    }
  }
}
