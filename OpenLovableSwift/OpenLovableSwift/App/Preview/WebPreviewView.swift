//
//  WebPreviewView.swift
//  OpenLovableSwift
//
//  Created by Arya Mirsepasi on 12.08.25.
//

import SwiftUI
import WebKit

struct WebPreviewView: NSViewRepresentable {
  let url: URL

  func makeNSView(context: Context) -> WKWebView {
    let wv = WKWebView()
    wv.allowsBackForwardNavigationGestures = true
    wv.setValue(false, forKey: "drawsBackground") // nicer blend with macOS appearances
    return wv
  }

  func updateNSView(_ view: WKWebView, context: Context) {
    if view.url != url {
      view.load(URLRequest(url: url, cachePolicy: .reloadRevalidatingCacheData, timeoutInterval: 15))
    }
  }
}
