//
//  ContentView.swift
//  KC-tests-helper
//
//  Created by Кирилл Котляренко on 26.03.2026.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var store = DataStore()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)

                        TextField("Поиск по вопросам и ответам…", text: $store.query)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .submitLabel(.search)

                        if !store.query.isEmpty {
                            Button {
                                store.query = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.secondary, .tertiary)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Очистить поиск")
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(.thinMaterial, in: Capsule())
                    .overlay(
                        Capsule()
                            .strokeBorder(.quaternary, lineWidth: 0.5)
                    )

                    HStack {
                        Label {
                            Text("\(store.results.count) из \(store.allItems.count)")
                                .font(.subheadline)
                                .monospacedDigit()
                        } icon: {
                            Image(systemName: "list.bullet")
                        }
                        .foregroundStyle(.secondary)

                        Spacer()

                        if !store.query.isEmpty {
                            Text("Результаты поиска")
                                .font(.caption)
                                .foregroundStyle(.blue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.blue.opacity(0.1), in: Capsule())
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 6)
                .padding(.bottom, 8)

                if store.results.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("Ничего не найдено")
                            .font(.title3)
                            .fontWeight(.medium)
                        Text("Попробуйте изменить запрос")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentTransition(.opacity)
                } else {
                    List(store.results) { item in
                        NavigationLink {
                            DetailView(item: item)
                        } label: {
                            QuestionRowView(item: item)
                        }
                    }
                    .listStyle(.plain)
                    .contentTransition(.opacity)
                }
            }
            .navigationTitle("Вопросы")
            .toolbarTitleDisplayMode(.large)
        }
        .onAppear { store.load() }
    }
}

struct DetailView: View {
    let item: QAItem

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(item.question)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(.quaternary, lineWidth: 0.5)
                    )

                if !item.images.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Изображения", systemImage: "photo.stack")
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        ForEach(item.images, id: \.self) { path in
                            QAImage(path: path)
                        }
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    Label {
                        Text("Ответы (\(item.correctAnswers.count) правильных)")
                            .font(.headline)
                    } icon: {
                        Image(systemName: "list.bullet.circle.fill")
                    }
                    .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(item.answers) { a in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: a.is_correct ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(a.is_correct ? .green : .secondary)
                                    .font(.title3)

                                VStack(alignment: .leading, spacing: 6) {
                                    if let imagePath = a.image, !imagePath.isEmpty {
                                        QAImage(path: imagePath)
                                    }
                                    Text(a.text)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                a.is_correct
                                    ? Color.green.opacity(0.08)
                                    : Color.gray.opacity(0.05),
                                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(
                                        a.is_correct ? Color.green.opacity(0.3) : Color.clear,
                                        lineWidth: 1
                                    )
                            )
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Ответ")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct QAImage: View {
    let path: String

    static func loadUIImage(from path: String) -> UIImage? {
        let normalized = path.replacingOccurrences(of: "\\", with: "/")
        let parts = normalized.split(separator: "/").map(String.init)
        guard let file = parts.last else { return nil }
        let dir = parts.dropLast().joined(separator: "/")

        guard let url = Bundle.main.url(
            forResource: file,
            withExtension: nil,
            subdirectory: dir
        ) else { return nil }

        guard let data = try? Data(contentsOf: url),
              let img = UIImage(data: data) else { return nil }
        return img
    }

    var body: some View {
        Group {
            if let image = loadImage() {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(.quaternary, lineWidth: 0.5)
                    )
                    .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
            } else {
                VStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle")
                        .imageScale(.large)

                    Text("Изображение не загружено")
                        .font(.footnote)
                        .multilineTextAlignment(.center)

                    Text(path)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(8)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(.quaternary, lineWidth: 0.5)
                )
            }
        }
    }

    private func loadImage() -> UIImage? {
        let normalized = path.replacingOccurrences(of: "\\", with: "/")
        let parts = normalized.split(separator: "/").map(String.init)
        guard let file = parts.last else { return nil }
        let dir = parts.dropLast().joined(separator: "/")

        guard let url = Bundle.main.url(
            forResource: file,
            withExtension: nil,
            subdirectory: dir
        ) else {
            print("❌ Image not found in bundle:", normalized)
            return nil
        }

        guard let data = try? Data(contentsOf: url),
              let img = UIImage(data: data) else {
            print("❌ Failed to decode image:", normalized)
            return nil
        }

        return img
    }
}

struct QuestionRowView: View {
    let item: QAItem

    private var correctCount: Int {
        item.answers.filter(\.is_correct).count
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let firstPath = item.images.first, let thumb = QAImage.loadUIImage(from: firstPath) {
                Image(uiImage: thumb)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(.quaternary, lineWidth: 0.5)
                    )
            } else if !item.images.isEmpty {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(.quaternary, lineWidth: 0.5)
                    )
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(item.question)
                    .font(.body)
                    .lineLimit(3)

                HStack(spacing: 12) {
                    Label {
                        Text("\(correctCount) из \(item.answers.count)")
                            .font(.caption)
                            .monospacedDigit()
                    } icon: {
                        Image(systemName: "checkmark.circle.fill")
                    }
                    .foregroundStyle(.green)

                    if !item.images.isEmpty {
                        Label {
                            Text("\(item.images.count)")
                                .font(.caption)
                                .monospacedDigit()
                        } icon: {
                            Image(systemName: "photo.fill")
                        }
                        .foregroundStyle(.blue)
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }
}

