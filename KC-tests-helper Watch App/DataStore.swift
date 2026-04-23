//
//  DataStore.swift
//  KC-tests-helper
//
//  Created by Кирилл Котляренко on 26.03.2026.
//

import Foundation
import Combine

@MainActor
final class DataStore: ObservableObject {
    @Published var allItems: [QAItem] = []
    @Published var query: String = ""

    func load() {
        guard let url = Bundle.main.url(forResource: "qa", withExtension: "json") else {
            print("qa.json not found in watch bundle")
            return
        }
        do {
            let data = try Data(contentsOf: url)
            allItems = try JSONDecoder().decode([QAItem].self, from: data)
        } catch {
            print("Failed to decode qa.json:", error)
        }
    }

    var results: [QAItem] {
        let q = normalize(query)
        if q.isEmpty { return [] }
        let tokens = q.split(whereSeparator: \.isWhitespace).map(String.init)

        return allItems.filter { item in
            let hay = normalize(item.question + " " + item.answers.map(\.text).joined(separator: " "))
            return tokens.allSatisfy { hay.contains($0) }
        }
    }

    private func normalize(_ s: String) -> String {
        s.lowercased()
            .replacingOccurrences(of: "\u{00A0}", with: " ")
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
