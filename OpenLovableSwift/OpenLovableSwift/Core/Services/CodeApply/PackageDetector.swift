//
//  PackageDetector.swift
//  OpenLovableSwift
//
//  Created by Arya Mirsepasi on 12.08.25.
//

import Foundation

struct PackageDetector {
  /// Scan files for non-relative imports (e.g., "react", "react-dom", "zustand")
  func detect(from files: [GeneratedFile]) -> [String] {
    let importRegex = try! NSRegularExpression(pattern: #"(?m)^\s*import\s.*?from\s*['"]([^'"]+)['"]"#)
    var pkgs = Set<String>()
    for f in files where f.path.hasSuffix(".ts") || f.path.hasSuffix(".tsx") || f.path.hasSuffix(".js") || f.path.hasSuffix(".jsx") {
      let text = f.content as NSString
      for m in importRegex.matches(in: f.content, range: NSRange(location: 0, length: text.length)) {
        let module = text.substring(with: m.range(at: 1))
        guard !module.hasPrefix("./"), !module.hasPrefix("../"), !module.hasPrefix("/") else { continue }
        pkgs.insert(module)
      }
    }
    // Basic dedupe and known dev deps can be added later if needed
    return Array(pkgs).sorted()
  }
}
