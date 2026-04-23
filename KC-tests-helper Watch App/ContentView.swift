//
//  ContentView.swift
//  KC-tests-helper Watch App
//
//  Created by Кирилл Котляренко on 26.03.2026.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var store = DataStore()

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    TextField("Поиск…", text: $store.query)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .font(.body)

                    if !store.query.isEmpty {
                        Button {
                            store.query = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 4)

                if store.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)

                        Text("Введите слово для поиска")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    List(store.results) { item in
                        NavigationLink {
                            DetailView(item: item)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.question)
                                    .font(.callout)
                                    .lineLimit(3)
                                    .fixedSize(horizontal: false, vertical: true)

                                Text("\(item.answers.filter(\.is_correct).count) правильных из \(item.answers.count)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Вопросы")
        }
        .onAppear {store.load()}
    }
}

struct DetailView: View {
    let item: QAItem

    @State private var showGallery = false
    @State private var selectedIndex: Int = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(item.question)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .fixedSize(horizontal: false, vertical: true)

                if !item.images.isEmpty {
                    VStack(spacing: 10) {
                        ForEach(Array(item.images.enumerated()), id: \.offset) { index, path in
                            Button {
                                selectedIndex = index
                                showGallery = true
                            } label: {
                                QAImage(path: path)
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .stroke(.quaternary, lineWidth: 0.5)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Divider()
                    .padding(.vertical, 4)

                VStack(spacing: 12) {
                    ForEach(item.answers) { a in
                        HStack(alignment: .top, spacing: 10) {
                            Text(a.is_correct ? "✅" : "◻️")
                                .font(.title3)

                            VStack(alignment: .leading, spacing: 6) {
                                Text(a.text)
                                    .font(.callout)
                                    .fixedSize(horizontal: false, vertical: true)

                                if let imagePath = a.image, !imagePath.isEmpty {
                                    QAImage(path: imagePath)
                                }
                            }

                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Ответ")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showGallery) {
            GalleryView(paths: item.images, startIndex: selectedIndex) {
                showGallery = false
            }
        }
    }
}

struct QAImage: View {
    let path: String

    var body: some View {
        Group {
            if let image = loadImage() {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(8)
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
                .padding(6)
                .background(.ultraThinMaterial)
                .cornerRadius(8)
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
struct GalleryView: View {
    let paths: [String]
    let startIndex: Int
    let onClose: () -> Void

    @State private var currentIndex: Int
    @State private var scale: CGFloat = 1.0

    init(paths: [String], startIndex: Int, onClose: @escaping () -> Void) {
        self.paths = paths
        self.startIndex = startIndex
        self.onClose = onClose
        _currentIndex = State(initialValue: startIndex)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if paths.isEmpty {
                Text("Нет изображений")
                    .foregroundStyle(.white)
                    .font(.callout)
            } else {
                TabView(selection: $currentIndex) {
                    ForEach(Array(paths.enumerated()), id: \.offset) { index, path in
                        ZStack {
                            if let image = loadImage(path: path) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .scaleEffect(scale)
                                    .ignoresSafeArea(edges: .all)
                            } else {
                                VStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle")
                                        .font(.title2)
                                        .foregroundStyle(.white)
                                    Text("Не удалось загрузить")
                                        .font(.callout)
                                        .foregroundStyle(.white.opacity(0.8))
                                    Text(path)
                                        .font(.caption2)
                                        .foregroundStyle(.white.opacity(0.6))
                                        .multilineTextAlignment(.center)
                                        .lineLimit(2)
                                }
                                .padding()
                            }
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
                .digitalCrownRotation($scale, from: 1.0, through: 3.0, by: 0.1, sensitivity: .medium)
                .onChange(of: currentIndex) { oldValue, newValue in
                    scale = 1.0
                }
            }

            VStack {
                HStack {
                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        if paths.count > 1 {
                            Text("\(currentIndex + 1)/\(paths.count)")
                                .font(.caption)
                                .fontWeight(.medium)
                        }

                        if scale > 1.05 {
                            Text("\(Int(scale * 100))%")
                                .font(.caption2)
                        }
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.black.opacity(0.5))
                    .cornerRadius(12)
                }
                .padding([.top, .horizontal])

                Spacer()
            }
        }
    }

    private func loadImage(path: String) -> UIImage? {
        let normalized = path.replacingOccurrences(of: "\\\\", with: "/")
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
