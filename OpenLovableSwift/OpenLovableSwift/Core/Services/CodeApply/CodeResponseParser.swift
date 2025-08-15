//
//  CodeResponseParser.swift
//  OpenLovableSwift
//
//  Created by Arya Mirsepasi on 12.08.25.
//

import Foundation

struct GeneratedFile: Sendable { let path: String; let content: String }
struct GeneratedArtifact: Sendable {
  var files: [GeneratedFile] = []
  var packages: [String] = []
  var commands: [String] = []
  var explanation: String?
  var structure: String?
}

enum CodeParseError: Error { case empty }

struct CodeResponseParser {
  func parse(_ response: String) throws -> GeneratedArtifact {
    guard !response.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw CodeParseError.empty }
    var out = GeneratedArtifact()

    // <file path="...">...</file>
    let fileRegex = try! NSRegularExpression(
      pattern: #"<file\s+path="([^"]+)">([\s\S]*?)</file>"#,
      options: [.dotMatchesLineSeparators]
    )
    for m in fileRegex.matches(in: response, range: NSRange(response.startIndex..., in: response)) {
      let p = String(response[Range(m.range(at: 1), in: response)!])
      let c = String(response[Range(m.range(at: 2), in: response)!])
      out.files.append(.init(path: p.trimmingCharacters(in: .whitespacesAndNewlines),
                             content: c))
    }

    // <package>react</package>
    let pkgRegex = try! NSRegularExpression(pattern: #"<package>(.*?)</package>"#, options: [.dotMatchesLineSeparators])
    for m in pkgRegex.matches(in: response, range: NSRange(response.startIndex..., in: response)) {
      out.packages.append(String(response[Range(m.range(at: 1), in: response)!]).trimmingCharacters(in: .whitespacesAndNewlines))
    }

    // <packages> ... lines ... </packages>
    if let block = capture(response, pattern: #"<packages>([\s\S]*?)</packages>"#) {
      out.packages.append(contentsOf: block
        .split(whereSeparator: { $0.isNewline || $0 == "," })
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty })
    }

    // <command>npm run dev</command>
    let cmdRegex = try! NSRegularExpression(pattern: #"<command>(.*?)</command>"#, options: [.dotMatchesLineSeparators])
    for m in cmdRegex.matches(in: response, range: NSRange(response.startIndex..., in: response)) {
      out.commands.append(String(response[Range(m.range(at: 1), in: response)!]).trimmingCharacters(in: .whitespacesAndNewlines))
    }

    out.explanation = capture(response, pattern: #"<explanation>([\s\S]*?)</explanation>"#)
    out.structure   = capture(response, pattern: #"<structure>([\s\S]*?)</structure>"#)
    out.packages = Array(Set(out.packages)).sorted()
    return out
  }

  private func capture(_ text: String, pattern: String) -> String? {
    guard let r = text.range(of: pattern, options: .regularExpression) else { return nil }
    var s = String(text[r])
    let tags = ["explanation", "structure", "packages"]
    for t in tags {
      s = s.replacingOccurrences(of: "<\(t)>", with: "")
           .replacingOccurrences(of: "</\(t)>", with: "")
    }
    return s.trimmingCharacters(in: .whitespacesAndNewlines)
  }
}
