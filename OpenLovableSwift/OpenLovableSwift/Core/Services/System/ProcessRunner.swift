//
//  ProcessRunner.swift
//  OpenLovableSwift
//
//  Created by Arya Mirsepasi on 12.08.25.
//

import Foundation

struct ProcessOutput: Sendable {
  var code: Int32
  var stdout: String
  var stderr: String
}

enum ProcessError: Error { case launchFailed, nonZeroExit(code: Int32, stderr: String) }

enum ProcessRunner {
  @discardableResult
  static func run(_ launchPath: String, _ args: [String], cwd: URL? = nil, env: [String:String] = [:]) throws -> ProcessOutput {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: launchPath)
    p.arguments = args
    if let cwd { p.currentDirectoryURL = cwd }
    p.environment = envMerged(with: env)

    let outPipe = Pipe(), errPipe = Pipe()
    p.standardOutput = outPipe; p.standardError = errPipe
    try p.run()
    p.waitUntilExit()

    let out = String(data: outPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    let err = String(data: errPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    return .init(code: p.terminationStatus, stdout: out, stderr: err)
  }

  static func stream(_ launchPath: String, _ args: [String], cwd: URL? = nil, env: [String:String] = [:]) throws -> (process: Process, lines: AsyncStream<String>) {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: launchPath)
    p.arguments = args
    if let cwd { p.currentDirectoryURL = cwd }
    p.environment = envMerged(with: env)

    let outPipe = Pipe(), errPipe = Pipe()
    p.standardOutput = outPipe; p.standardError = errPipe

    try p.run()

    let outHandle = outPipe.fileHandleForReading
    let errHandle = errPipe.fileHandleForReading

    let stream = AsyncStream<String> { continuation in
      func readLines(_ fh: FileHandle) {
        Task.detached {
          do {
            for try await line in fh.bytes.lines {
              continuation.yield(line)
            }
          } catch {
            // End the stream if reading fails
          }
        }
      }
      readLines(outHandle)
      readLines(errHandle)

      Task.detached {
        p.waitUntilExit()
        continuation.finish()
      }
    }

    return (process: p, lines: stream)
  }

  private static func envMerged(with env: [String:String]) -> [String:String] {
    var merged = ProcessInfo.processInfo.environment
    let defaultPATH = "/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
    merged["PATH"] = [env["PATH"] ?? "", merged["PATH"] ?? "", defaultPATH]
      .filter { !$0.isEmpty }
      .joined(separator: ":")
    for (k,v) in env { merged[k] = v }
    return merged
  }
}
