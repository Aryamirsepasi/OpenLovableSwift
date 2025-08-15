//
//  ScraperService.swift
//  OpenLovableSwift
//
//  Created by Arya Mirsepasi on 12.08.25.
//

import Foundation
import SwiftSoup

struct ScrapeResult: Sendable { var title: String; var description: String; var text: String; var links: [URL] }

struct ScraperService {
  func scrape(_ url: URL) async throws -> ScrapeResult {
    let (data, _) = try await URLSession.shared.data(from: url)
    guard let html = String(data: data, encoding: .utf8) else { throw URLError(.cannotDecodeContentData) }
    let doc = try SwiftSoup.parse(html)
    let title = try doc.select("title").first()?.text() ?? ""
    let desc = try doc.select("meta[name=description]").first()?.attr("content") ?? ""
    let text = try doc.body()?.text() ?? ""
    let links: [URL] = try doc.select("a[href]").compactMap { try URL(string: $0.attr("abs:href")) }
    return .init(title: title, description: desc, text: text, links: links)
  }
}
