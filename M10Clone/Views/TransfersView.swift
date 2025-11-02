//
//  TransfersView.swift
//  M10Clone
//
//  Created by Claude on 2025-11-02.
//

import SwiftUI

struct TransfersView: View {
    @State private var recipientInput = ""
    @State private var selectedTransferType: TransferType = .phone

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Transfer type selector
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Кому")
                            .font(.headline)

                        Picker("Тип перевода", selection: $selectedTransferType) {
                            Text("По телефону").tag(TransferType.phone)
                            Text("По карте").tag(TransferType.card)
                            Text("По счету").tag(TransferType.account)
                        }
                        .pickerStyle(.segmented)

                        HStack {
                            Image(systemName: selectedTransferType.icon)
                                .foregroundColor(AppColors.primary)

                            TextField(selectedTransferType.placeholder, text: $recipientInput)
                                .keyboardType(selectedTransferType.keyboardType)
                                .textFieldStyle(.plain)
                        }
                        .padding()
                        .background(AppColors.background)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)

                    // Recent contacts
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Недавние")
                            .font(.headline)
                            .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ContactButton(name: "Иван", initial: "И", color: AppColors.primary)
                                ContactButton(name: "Мария", initial: "М", color: AppColors.secondary)
                                ContactButton(name: "Петр", initial: "П", color: AppColors.accent)
                                ContactButton(name: "Анна", initial: "А", color: AppColors.primaryLight)
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Transfer templates
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Шаблоны переводов")
                            .font(.headline)
                            .padding(.horizontal)

                        VStack(spacing: 12) {
                            TransferTemplateRow(
                                name: "Иван Петров",
                                phone: "+7 (999) 123-45-67",
                                amount: "5,000 ₽"
                            )
                            TransferTemplateRow(
                                name: "Мария Сидорова",
                                phone: "+7 (999) 987-65-43",
                                amount: "2,500 ₽"
                            )
                        }
                        .padding(.horizontal)
                    }

                    // Info banner
                    HStack(spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(AppColors.primary)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Переводы без комиссии")
                                .font(.subheadline.bold())
                                .foregroundColor(AppColors.textPrimary)
                            Text("Моментально на любую карту")
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }

                        Spacer()
                    }
                    .padding()
                    .background(AppColors.primary.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    Spacer(minLength: 20)
                }
                .padding(.vertical)
            }
            .background(Color.white)
            .navigationTitle("Переводы")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "qrcode.viewfinder")
                            .foregroundColor(AppColors.primary)
                    }
                }
            }
        }
    }
}

enum TransferType {
    case phone
    case card
    case account

    var icon: String {
        switch self {
        case .phone: return "phone.fill"
        case .card: return "creditcard.fill"
        case .account: return "building.columns.fill"
        }
    }

    var placeholder: String {
        switch self {
        case .phone: return "+7 (___) ___-__-__"
        case .card: return "Номер карты"
        case .account: return "Номер счета"
        }
    }

    var keyboardType: UIKeyboardType {
        switch self {
        case .phone, .card, .account: return .numberPad
        }
    }
}

struct ContactButton: View {
    let name: String
    let initial: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(color.opacity(0.1))
                .frame(width: 60, height: 60)
                .overlay(
                    Text(initial)
                        .font(.title2.bold())
                        .foregroundColor(color)
                )

            Text(name)
                .font(.caption)
                .foregroundColor(AppColors.textPrimary)
        }
    }
}

struct TransferTemplateRow: View {
    let name: String
    let phone: String
    let amount: String

    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(AppColors.primary.opacity(0.1))
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundColor(AppColors.primary)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.body)
                    .foregroundColor(AppColors.textPrimary)
                Text(phone)
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()

            Text(amount)
                .font(.body.bold())
                .foregroundColor(AppColors.primary)
        }
        .padding()
        .background(AppColors.background)
        .cornerRadius(12)
    }
}

#Preview {
    TransfersView()
}
