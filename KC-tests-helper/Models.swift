//
//  Models.swift
//  KC-tests-helper
//
//  Created by Кирилл Котляренко on 26.03.2026.
//

import Foundation

struct Answer: Codable, Identifiable {
    let id: String
    let text: String
    let is_correct: Bool
    let image: String?
}

struct QAItem: Codable, Identifiable {
    let id: UUID
    let question: String
    let answers: [Answer]
    let images: [String]

    var correctAnswers: [Answer] {
        answers.filter(\.is_correct)
    }

    var incorrectAnswers: [Answer] {
        answers.filter { !$0.is_correct }
    }

    enum CodingKeys: String, CodingKey {
        case question, answers, images
    }

    init(question: String, answers: [Answer], images: [String]) {
        self.id = UUID()
        self.question = question
        self.answers = answers
        self.images = images
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.question = try c.decode(String.self, forKey: .question)
        self.answers = try c.decode([Answer].self, forKey: .answers)
        self.images = (try? c.decode([String].self, forKey: .images)) ?? []
    }
}
