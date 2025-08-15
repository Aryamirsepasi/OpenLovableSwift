//
//  DevServerManager.swift
//  OpenLovableSwift
//
//  Created by Arya Mirsepasi on 12.08.25.
//

import Foundation

actor DevServerManager {
    private var viteProcess: Process?
    private(set) var port: Int = 5173
    
    /// Installs packages (if any) and starts Vite dev server.
    /// Returns a single merged stream of stdout/stderr from the `npm run dev` process.
    func start(in root: URL, packages: [String]) async throws -> AsyncStream<String> {
        try await stop()
        
        // Ensure package.json exists
        let pkgURL = root.appendingPathComponent("package.json")
        if !FileManager.default.fileExists(atPath: pkgURL.path) {
            try """
      {
        "name": "lovable-app",
        "private": true,
        "version": "0.0.1",
        "type": "module",
        "scripts": { "dev": "vite", "build": "vite build", "preview": "vite preview" },
        "dependencies": {},
        "devDependencies": { "vite": "^5.4.0" }
      }
      """.data(using: .utf8)!.write(to: pkgURL, options: .atomic)
        }
        
        // npm install (packages + ensure baseline)
        let installArgs: [String] = packages.isEmpty ? ["npm","install"] : ["npm","install"] + packages
        let install = try ProcessRunner.run("/usr/bin/env", installArgs, cwd: root)
        if install.code != 0 {
            throw ProcessError.nonZeroExit(code: install.code, stderr: install.stderr)
        }
        
        
        // Start dev server
        let (proc, lines) = try ProcessRunner.stream("/usr/bin/env", ["npm", "run", "dev", "--", "--port", "\(port)", "--host"], cwd: root)
        viteProcess = proc
        return lines
    }
    
    func stop() async throws {
        if let p = viteProcess, p.isRunning { p.terminate() }
        viteProcess = nil
    }
}
