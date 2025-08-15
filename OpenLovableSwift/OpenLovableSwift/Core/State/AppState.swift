//
//  AppState.swift
//  OpenLovableSwift
//
//  Created by Arya Mirsepasi on 12.08.25.
//

import Foundation
import Observation

@Observable
final class AppState {
    // UI state
    var messages: [Message] = []
    var isSending = false
    var draft: String = ""
    
    // Project state
    var project: Project = .empty()
    var selectedFileID: UUID? = nil
    var logs: [String] = []
    var previewURL: URL? = nil
    
    // Services
    private let sandbox = ProjectSandbox()
    private let parser = CodeResponseParser()
    private let detector = PackageDetector()
    private let writer = FileWriter()
    private let dev = DevServerManager()
    
    // Settings + current provider
    var settings: AISettings = .load()
    private var ai: AIProvider?
    
    func rebuildProvider() {
        ai = makeProvider(from: settings)
    }
    
    // Boot with a tiny starter project
    init() {
        self.messages = [
            .init(role: .system, content: "You are Lovable. Generate Vite React TypeScript apps.")
        ]
        rebuildProvider()
        newProject(named: "lovable-react-app")
    }
    
    private func makeProvider(from s: AISettings) -> AIProvider {
        switch s.backend {
        case .openai:
            return OpenAIProvider(
                config: .init(
                    model: s.modelOpenAI,
                    partialKey: s.partialKey.nilIfEmpty,
                    serviceURL: s.serviceURL.nilIfEmpty,
                    unprotectedAPIKey: s.openAIKey.nilIfEmpty
                )
            )
        case .anthropic:
            return AnthropicProvider(
                config: .init(
                    model: s.modelAnthropic,
                    partialKey: s.partialKey.nilIfEmpty,
                    serviceURL: s.serviceURL.nilIfEmpty,
                    unprotectedAPIKey: s.anthropicKey.nilIfEmpty,
                    maxTokens: 4096
                )
            )
        case .openrouter:
            return OpenRouterProvider(
                config: .init(
                    model: s.modelOpenRouter,
                    partialKey: s.partialKey.nilIfEmpty,
                    serviceURL: s.serviceURL.nilIfEmpty,
                    unprotectedAPIKey: s.openRouterKey.nilIfEmpty
                )
            )
        case .mistral:
            return MistralProvider(
                config: .init(
                    model: s.modelMistral,
                    partialKey: s.partialKey.nilIfEmpty,
                    serviceURL: s.serviceURL.nilIfEmpty,
                    unprotectedAPIKey: s.mistralKey.nilIfEmpty
                )
            )
        }
    }
    
    func newProject(named: String) {
        do {
            let root = try sandbox.createNewProject(named: named)
            self.project = Project(name: named, rootPath: root.path, files: starterFiles())
            self.selectedFileID = self.project.defaultSelectedFileID
            self.logs = ["Created project at \(root.path)"]
            self.previewURL = nil
            // write starter files to disk
            try writer.write(files: self.project.allFiles().compactMap {
                guard !$0.isDirectory, let content = $0.content else { return nil }
                return GeneratedFile(path: $0.path, content: content)
            }, into: root)
        } catch {
            logs.append("Error creating project: \(error)")
        }
    }
    
    // Called by the ChatView “Send” button
    func sendDraftMessage() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        draft = ""
        messages.append(.init(role: .user, content: text))
        Task { await generateAndApply(for: text) }
    }
    
    // MAIN PIPELINE: AI -> parse -> write -> npm install -> vite dev
    @MainActor
    private func generateAndApply(for userRequest: String) async {
        isSending = true
        defer { isSending = false }
        
        // 1) Build chat
        var chat: [AIMessage] = [
            .init(role: .system, content: PromptTemplates.systemReact),
            .init(role: .user, content: "Project: \(project.name)")
        ]
        for m in messages where m.role != .system {
            let role: AIMessage.Role = (m.role == .user) ? .user : .assistant
            chat.append(.init(role: role, content: m.content))
        }
        
        // 2) Stream assistant text
        var buffer = ""
        do {
            let provider = ai ?? makeProvider(from: settings)
            for try await chunk in provider.stream(messages: chat) {
                buffer += chunk
            }
        } catch {
            logs.append("AI error: \(error)")
            messages.append(.init(role: .assistant,
                                  content: "Sorry, I hit an error talking to the model."))
            return
        }
        
        // 3) Parse blocks
        let artifact: GeneratedArtifact
        do {
            artifact = try parser.parse(buffer)
        } catch {
            logs.append("Parse error: \(error)")
            messages.append(.init(role: .assistant, content: "I couldn't parse the generation output."))
            return
        }
        
        // 4) Write files
        do {
            let root = URL(fileURLWithPath: project.rootPath)
            try sandbox.write(files: artifact.files, into: root)
            applyFilesToMemory(artifact.files) // mirror into in-memory tree for the editor
            logs.append("Wrote \(artifact.files.count) files.")
        } catch {
            logs.append("Write error: \(error)")
        }
        
        // 5) Detect & merge packages
        let detected = detector.detect(from: artifact.files)
        var pkgs = Set(artifact.packages).union(detected)
        // Ensure core dependencies if the code references React/Vite TS
        if needsCoreReactDeps(in: artifact.files) {
            pkgs.insert("react"); pkgs.insert("react-dom")
            pkgs.insert("vite"); pkgs.insert("typescript")
            pkgs.insert("@types/react"); pkgs.insert("@types/react-dom")
        }
        
        // 6) Start dev server (npm install + vite dev) and stream logs + preview
        logs.append("Installing packages: \(pkgs.sorted().joined(separator: ", "))")
        do {
            let root = URL(fileURLWithPath: project.rootPath)
            
            let doctor = NodeDoctor.check()
            if !doctor.ok {
                logs.append("Node Doctor: \(doctor.message)")
                logs.append("TIP: In Signing & Capabilities, disable App Sandbox for dev builds.")
                return
            }
            
            let lines = try await dev.start(in: root, packages: Array(pkgs))
            previewURL = URL(string: "http://localhost:5173")
            Task {
                for await line in lines { await MainActor.run { self.logs.append(line) } }
            }
        } catch {
            logs.append("Dev server error: \(error)")
        }
        
        // 7) Show a friendly assistant message
        let assistantSummary = artifact.explanation ?? "Applied files and started the dev server."
        messages.append(.init(role: .assistant, content: assistantSummary))
    }
    
    private func needsCoreReactDeps(in files: [GeneratedFile]) -> Bool {
        files.contains(where: { $0.path.hasSuffix(".tsx") || $0.path.hasSuffix(".jsx") })
    }
    
    private func applyFilesToMemory(_ files: [GeneratedFile]) {
        for f in files {
            // If exists update; else add to tree (in a simple way)
            if let node = project.allFiles().first(where: { $0.path == f.path }) {
                project.updateFileContent(id: node.id, content: f.content)
            } else {
                // naive add to root; a fuller tree insert can be added later
                let new = FileNode(name: (f.path as NSString).lastPathComponent, path: f.path, isDirectory: false, content: f.content)
                project.files.append(new)
            }
        }
        if selectedFileID == nil { selectedFileID = project.defaultSelectedFileID }
    }
    
    // A tiny inline starter just so the preview/editor aren’t empty before first AI run
    private func starterFiles() -> [FileNode] {
        let indexHTML = FileNode(name: "index.html", path: "index.html", isDirectory: false, content:
"""
<!doctype html>
<html>
  <head><meta charset="UTF-8" /><meta name="viewport" content="width=device-width, initial-scale=1.0" /><title>Lovable</title></head>
  <body><div id="root"></div><script type="module" src="/src/main.tsx"></script></body>
</html>
"""
        )
        let mainTSX = FileNode(name: "main.tsx", path: "src/main.tsx", isDirectory: false, content:
"""
import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App'
ReactDOM.createRoot(document.getElementById('root')!).render(<App />)
"""
        )
        let appTSX = FileNode(name: "App.tsx", path: "src/App.tsx", isDirectory: false, content:
"""
export default function App(){ return <div style={{padding:20,fontFamily:'system-ui'}}>Hello Lovable 👋</div> }
"""
        )
        let srcDir = FileNode(name: "src", path: "src", isDirectory: true, children: [mainTSX, appTSX])
        let pkg = FileNode(name: "package.json", path: "package.json", isDirectory: false, content:
"""
{
  "name": "lovable-starter",
  "private": true,
  "version": "0.0.1",
  "type": "module",
  "scripts": { "dev": "vite", "build": "vite build", "preview": "vite preview" }
}
"""
        )
        return [indexHTML, srcDir, pkg]
    }
    
    // Select a file in the editor
    func selectFile(_ nodeID: UUID) {
        selectedFileID = nodeID
    }
    
    // Update the content of the currently selected file (and write it to disk)
    func updateSelectedFileContent(_ newText: String) {
        guard let id = selectedFileID else { return }
        // Update in-memory model
        project.updateFileContent(id: id, content: newText)
        
        // Persist to disk
        if let node = project.allFiles().first(where: { $0.id == id }),
           !node.isDirectory {
            let root = URL(fileURLWithPath: project.rootPath)
            do {
                try FileWriter().write(
                    files: [GeneratedFile(path: node.path, content: newText)],
                    into: root
                )
            } catch {
                logs.append("Write error for \(node.path): \(error)")
            }
        }
    }
    
}
