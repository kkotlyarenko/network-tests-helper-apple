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
    @Published private(set) var results: [QAItem] = []

    private var cancellables = Set<AnyCancellable>()

    init() {
        $query
            .combineLatest($allItems)
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .map { [weak self] query, items in
                guard let self = self else { return [] }
                let q = self.normalize(query)
                if q.isEmpty { return items }
                let tokens = q.split(whereSeparator: \.isWhitespace).map(String.init)

                return items.filter { item in
                    let hay = self.normalize(item.question + " " + item.answers.map(\.text).joined(separator: " "))
                    return tokens.allSatisfy { hay.contains($0) }
                }
            }
            .assign(to: &$results)
    }

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

    private func normalize(_ s: String) -> String {
        s.lowercased()
            .replacingOccurrences(of: "\u{00A0}", with: " ")
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
