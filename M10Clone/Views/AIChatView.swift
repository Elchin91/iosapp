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
            ZStack {
                Color.white.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Messages list
                    ScrollViewReader { proxy in
                        ScrollView {
                            if viewModel.isLoading {
                                ProgressView("Yüklənir...")
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            } else if viewModel.messages.isEmpty {
                                emptyStateView
                            } else {
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
                                .padding(.vertical, 16)
                            }
                        }
                        .onChange(of: viewModel.messages.count) { _ in
                            scrollToBottom(proxy)
                        }
                        .onChange(of: viewModel.isTyping) { isTyping in
                            if isTyping {
                                scrollToBottom(proxy)
                            }
                        }
                    }
                    
                    // Error Banner
                    if let errorMessage = viewModel.errorMessage {
                        ErrorBanner(
                            message: errorMessage,
                            onRetry: {
                                Task {
                                    await viewModel.retry()
                                }
                            },
                            onDismiss: {
                                viewModel.clearError()
                            }
                        )
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
                                .frame(width: 44, height: 44)
                                .background(AppColors.primary.opacity(0.1))
                                .clipShape(Circle())
                        }
                        
                        TextField("Mesajınızı yazın...", text: $viewModel.messageText, axis: .vertical)
                            .lineLimit(1...5)
                            .textFieldStyle(.plain)
                            .font(.system(size: 16))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .cornerRadius(24)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(AppColors.borderPrimary.opacity(0.1), lineWidth: 1)
                            )
                            .focused($isTextFieldFocused)
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                            .disabled(viewModel.isTyping)
                        
                        Button(action: {
                            viewModel.sendMessage()
                            isTextFieldFocused = false
                        }) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 36))
                                .foregroundColor(
                                    viewModel.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isTyping
                                    ? AppColors.textSecondary
                                    : AppColors.primary
                                )
                        }
                        .disabled(viewModel.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isTyping)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 18))
                            .foregroundColor(AppColors.brandPrimary)
                        Text("AI Dəstək")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 20))
                            .foregroundColor(AppColors.primary)
                    }
                }
            }
            .onChange(of: isTextFieldFocused) { focused in
                if !focused {
                    // Скрываем клавиатуру при потере фокуса
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 60))
                .foregroundColor(AppColors.brandPrimary.opacity(0.3))
            
            Text("Salam! Necə kömək edə bilərəm?")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
            
            Text("BakıKART, pul köçürmələri və digər xidmətlər haqqında soruşa bilərsiniz")
                .font(.system(size: 14))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Helper Methods
    
    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        guard !viewModel.messages.isEmpty else { return }
        
        if let lastMessage = viewModel.messages.last {
            withAnimation {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        } else if viewModel.isTyping {
            withAnimation {
                proxy.scrollTo("typing", anchor: .bottom)
            }
        }
    }
}

struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if !message.isUser {
                // AI Avatar
                Circle()
                    .fill(AppColors.brandPrimary)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "sparkles")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    )
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(.system(size: 16))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        message.isUser
                            ? AppColors.primary
                            : AppColors.backgroundSecondary
                    )
                    .foregroundColor(message.isUser ? .white : AppColors.textPrimary)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                
                // Sources
                if let sources = message.sources, !sources.isEmpty {
                    SourcesView(sources: sources)
                }
                
                // Timestamp
                Text(message.timestamp, style: .time)
                    .font(.system(size: 11))
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.horizontal, 12)
            }
            
            if message.isUser {
                Spacer(minLength: 60)
            } else {
                Spacer(minLength: 60)
            }
        }
        .padding(.horizontal, 16)
    }
}

struct SourcesView: View {
    let sources: [MessageSource]
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    Image(systemName: "doc.text.fill")
                        .font(.caption)
                    Text("Mənbələr (\(sources.count))")
                        .font(.caption)
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                }
                .foregroundColor(AppColors.brandAccent)
                .padding(8)
            }
            
            if isExpanded {
                ForEach(sources) { source in
                    if let url = source.url {
                        Link(destination: url) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: "link")
                                        .font(.caption2)
                                    Text(source.title)
                                        .font(.caption)
                                        .lineLimit(2)
                                }
                                
                                if let excerpt = source.excerpt {
                                    Text(excerpt)
                                        .font(.caption2)
                                        .foregroundColor(AppColors.textSecondary)
                                        .lineLimit(3)
                                }
                            }
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(hex: "6946F7").opacity(0.05))
                            .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .padding(8)
        .background(Color(hex: "6946F7").opacity(0.1))
        .cornerRadius(12)
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
            .background(AppColors.backgroundSecondary)
            .cornerRadius(20)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { _ in
                numberOfDots = (numberOfDots % 3) + 1
            }
        }
    }
}

struct ErrorBanner: View {
    let message: String
    let onRetry: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.red)
            
            Spacer()
            
            Button("Yenidən", action: onRetry)
                .font(.caption)
                .foregroundColor(.blue)
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding()
        .background(Color.red.opacity(0.1))
    }
}

#Preview {
    AIChatView()
}

}
