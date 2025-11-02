//
//  TransfersView.swift
//  M10Clone
//
//  Created by Claude on 2025-11-02.
//

import SwiftUI

struct TransfersView: View {
    @State private var recipientInput = ""
    @State private var amount = ""
    @State private var selectedTransferType: TransferType = .phone

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Transfer amount card
                    VStack(spacing: 16) {
                        Text("Сумма")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(AppColors.textSecondary)
                        
                        HStack {
                            TextField("0", text: $amount)
                                .font(.system(size: 48, weight: .bold))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.center)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Text("₼")
                                .font(.system(size: 36, weight: .semibold))
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(24)
                    .background(Color.white)
                    .cornerRadius(16)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    // Transfer type selector
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Кому")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(AppColors.textSecondary)
                            .padding(.horizontal, 16)

                        Picker("Тип перевода", selection: $selectedTransferType) {
                            Text("По телефону").tag(TransferType.phone)
                            Text("По карте").tag(TransferType.card)
                            Text("По счету").tag(TransferType.account)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 16)

                        HStack(spacing: 12) {
                            Image(systemName: selectedTransferType.icon)
                                .font(.system(size: 20))
                                .foregroundColor(AppColors.primary)
                                .frame(width: 40)

                            TextField(selectedTransferType.placeholder, text: $recipientInput)
                                .font(.system(size: 16))
                                .keyboardType(selectedTransferType.keyboardType)
                        }
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(12)
                        .padding(.horizontal, 16)
                    }

                    // Recent contacts
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Недавние")
                            .font(.system(size: 20, weight: .bold))
                            .padding(.horizontal, 16)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ContactButton(name: "Иван", initial: "И", phone: "+994 50 123 45 67", color: AppColors.primary)
                                ContactButton(name: "Мария", initial: "М", phone: "+994 55 234 56 78", color: AppColors.secondary)
                                ContactButton(name: "Петр", initial: "П", phone: "+994 70 345 67 89", color: AppColors.accent)
                                ContactButton(name: "Анна", initial: "А", phone: "+994 77 456 78 90", color: Color(hex: "FF6B9D"))
                            }
                            .padding(.horizontal, 16)
                        }
                    }

                    // Transfer templates
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Шаблоны переводов")
                            .font(.system(size: 20, weight: .bold))
                            .padding(.horizontal, 16)

                        VStack(spacing: 0) {
                            ForEach(transferTemplates, id: \.id) { template in
                                TransferTemplateRow(
                                    name: template.name,
                                    phone: template.phone,
                                    amount: template.amount
                                )
                                if template.id != transferTemplates.last?.id {
                                    Divider().padding(.leading, 72)
                                }
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(16)
                        .padding(.horizontal, 16)
                    }

                    // Info banner
                    HStack(spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(AppColors.primary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Переводы без комиссии")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(AppColors.textPrimary)
                            Text("Моментально на любую карту Азербайджана")
                                .font(.system(size: 13))
                                .foregroundColor(AppColors.textSecondary)
                        }
                        
                        Spacer()
                    }
                    .padding(16)
                    .background(AppColors.primary.opacity(0.1))
                    .cornerRadius(16)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)

                    // Send button
                    Button(action: {
                        // Отправить перевод
                    }) {
                        Text("Отправить")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(18)
                            .background(
                                LinearGradient(
                                    colors: [AppColors.primary, AppColors.primaryDark],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
            .background(AppColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Переводы")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                }
            }
        }
    }
    
    var transferTemplates: [TransferTemplate] {
        [
            TransferTemplate(id: UUID(), name: "Иван Петров", phone: "+994 50 123 45 67", amount: "5,000 ₼"),
            TransferTemplate(id: UUID(), name: "Мария Сидорова", phone: "+994 55 234 56 78", amount: "2,500 ₼"),
            TransferTemplate(id: UUID(), name: "Петр Иванов", phone: "+994 70 345 67 89", amount: "1,000 ₼")
        ]
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
        case .phone: return "+994 50 123 45 67"
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

struct TransferTemplate: Identifiable {
    let id: UUID
    let name: String
    let phone: String
    let amount: String
}

struct ContactButton: View {
    let name: String
    let initial: String
    let phone: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: 64, height: 64)
                .overlay(
                    Text(initial)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(color)
                )
            
            Text(name)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppColors.textPrimary)
        }
        .frame(width: 80)
    }
}

struct TransferTemplateRow: View {
    let name: String
    let phone: String
    let amount: String

    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(AppColors.primary.opacity(0.15))
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.primary)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)
                Text(phone)
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(amount)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.primary)
                Text("Шаблон")
                    .font(.system(size: 11))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding(16)
    }
}

#Preview {
    TransfersView()
}
