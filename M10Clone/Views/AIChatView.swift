//
//  AIChatView.swift
//  M10Clone
//
//  Created by Claude on 2025-11-02.
//

import SwiftUI

struct AIChatView: View {
    @StateObject private var viewModel = AIChatViewModel()
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Messages list
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }

                            if viewModel.isTyping {
                                TypingIndicator()
                                    .id("typing")
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.messages.count) { _ in
                        withAnimation {
                            if let lastMessage = viewModel.messages.last {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: viewModel.isTyping) { isTyping in
                        if isTyping {
                            withAnimation {
                                proxy.scrollTo("typing", anchor: .bottom)
                            }
                        }
                    }
                }

                Divider()

                // Input area
                HStack(spacing: 12) {
                    Button(action: {
                        viewModel.handleAttachment()
                    }) {
                        Image(systemName: "paperclip")
                            .font(.system(size: 22))
                            .foregroundColor(AppColors.primary)
                    }

                    TextField("Сообщение", text: $viewModel.messageText, axis: .vertical)
                        .lineLimit(1...5)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(AppColors.background)
                        .cornerRadius(20)
                        .focused($isTextFieldFocused)

                    Button(action: {
                        viewModel.sendMessage()
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(viewModel.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? AppColors.textSecondary : AppColors.primary)
                    }
                    .disabled(viewModel.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.white)
            }
            .background(Color.white)
            .navigationTitle("AI Ассистент")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(AppColors.primary)
                    }
                }
            }
        }
    }
}

struct MessageBubble: View {
    let message: Message

    var body: some View {
        HStack {
            if message.isUser {
                Spacer(minLength: 60)
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(message.isUser ? AppColors.userBubble : AppColors.aiBubble)
                    .foregroundColor(message.isUser ? .white : AppColors.textPrimary)
                    .cornerRadius(20)

                Text(timeString(from: message.timestamp))
                    .font(.caption2)
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.horizontal, 4)
            }

            if !message.isUser {
                Spacer(minLength: 60)
            }
        }
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct TypingIndicator: View {
    @State private var numberOfDots = 1

    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(AppColors.textSecondary)
                        .frame(width: 8, height: 8)
                        .opacity(index < numberOfDots ? 1 : 0.3)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(AppColors.aiBubble)
            .cornerRadius(20)

            Spacer()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever()) {
                numberOfDots = 3
            }
        }
        .task {
            while true {
                try? await Task.sleep(nanoseconds: 600_000_000)
                numberOfDots = numberOfDots % 3 + 1
            }
        }
    }
}

#Preview {
    AIChatView()
}
