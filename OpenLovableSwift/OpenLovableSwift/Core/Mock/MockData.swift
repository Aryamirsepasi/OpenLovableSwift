//
//  MockData.swift
//  OpenLovableSwift
//
//  Created by Arya Mirsepasi on 12.08.25.
//

import Foundation

enum MockData {
  static let messages: [Message] = [
    .init(role: .system,    content: "You are Lovable. Generate React/Vite apps."),
    .init(role: .user,      content: "Build a landing page for a coffee brand. Hero, features, and CTA."),
    .init(role: .assistant, content: "Scaffolding Vite + React + TypeScript. Adding Tailwind. Creating files...")
  ]

  static let project: Project = {
    let indexHTML = FileNode(
      name: "index.html",
      path: "index.html",
      isDirectory: false,
      content:
"""
<!doctype html>
<html>
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Café Nova</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
"""
    )

    let mainTSX = FileNode(
      name: "main.tsx",
      path: "src/main.tsx",
      isDirectory: false,
      content:
"""
import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App'
import './index.css'

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
)
"""
    )

    let appTSX = FileNode(
      name: "App.tsx",
      path: "src/App.tsx",
      isDirectory: false,
      content:
"""
import React from 'react'

export default function App() {
  return (
    <div style={{ fontFamily: 'system-ui', padding: 40 }}>
      <header style={{ display: 'grid', gap: 12 }}>
        <h1>☕️ Café Nova</h1>
        <p>Small-batch beans, roasted daily.</p>
        <div>
          <button>Shop Beans</button>
        </div>
      </header>
      <section style={{ marginTop: 48 }}>
        <h2>Why you'll love it</h2>
        <ul>
          <li>Freshly roasted</li>
          <li>Sustainable sourcing</li>
          <li>Fast shipping</li>
        </ul>
      </section>
    </div>
  )
}
"""
    )

    let indexCSS = FileNode(
      name: "index.css",
      path: "src/index.css",
      isDirectory: false,
      content:
"""
:root { color-scheme: light dark; }
html, body, #root { height: 100%; margin: 0; }
button { padding: 10px 16px; border-radius: 8px; cursor: pointer; }
"""
    )

    let srcDir = FileNode(name: "src", path: "src", isDirectory: true, children: [mainTSX, appTSX, indexCSS])
    let publicDir = FileNode(name: "public", path: "public", isDirectory: true, children: [])
    let pkg = FileNode(
      name: "package.json",
      path: "package.json",
      isDirectory: false,
      content:
"""
{
  "name": "cafe-nova",
  "private": true,
  "version": "0.0.1",
  "type": "module",
  "scripts": { "dev": "vite", "build": "vite build", "preview": "vite preview" },
  "dependencies": { "react": "^18.3.1", "react-dom": "^18.3.1" },
  "devDependencies": { "typescript": "^5.6.2", "vite": "^5.4.0", "@types/react": "^18.2.74", "@types/react-dom": "^18.2.24" }
}
"""
    )

    return Project(name: "cafe-nova", rootPath: "/tmp/cafe-nova", files: [indexHTML, publicDir, srcDir, pkg])
  }()

  static let logs: [String] = [
    "Initializing Vite project...",
    "Installing dependencies: react, react-dom, vite, typescript",
    "Starting dev server on http://localhost:5173",
    "[vite] ready in 382ms"
  ]

  static let previewURL = URL(string: "https://example.com") // placeholder for mock UI
}
