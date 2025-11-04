//
//  PaymentsView.swift
//  M10Clone
//
//  Created by Claude on 2025-11-02.
//

import SwiftUI

struct PaymentsView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Header with title and search
                    HStack {
                        Text("Сервисы")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)
                        Spacer()
                        Button(action: {}) {
                        Image(systemName: "magnifyingglass")
                                .font(.system(size: 20))
                                .foregroundColor(AppColors.textPrimary)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                    
                    // Services cards horizontal scroll
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ServicePromoCard(
                                title: "Мой гараж",
                                backgroundColor: AppColors.backgroundSecondary,
                                isNew: true
                            )
                            ServicePromoCard(
                                title: "Кабинет Azeriqaz",
                                backgroundColor: AppColors.backgroundSecondary,
                                isNew: true
                            )
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 24)

                    // Мои платежи section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Мои платежи")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(AppColors.textPrimary)
                            Spacer()
                            Button("Все >") {
                                // Show all payments
                            }
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(AppColors.textPrimary)
                        }
                        .padding(.horizontal, 16)

                        // Payment shortcuts horizontal scroll
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                PaymentShortcutCard(
                                    icon: "phone.fill",
                                    title: "Мой номер",
                                    backgroundColor: Color(hex: "E3F2FD")
                                )
                                PaymentShortcutCard(
                                    icon: "phone.fill",
                                    title: "Azercell",
                                    subtitle: "102533806",
                                    backgroundColor: Color(hex: "E8EAF6")
                                )
                                PaymentShortcutCard(
                                    icon: "phone.fill",
                                    title: "Azercell",
                                    subtitle: "505199991",
                                    backgroundColor: Color(hex: "E8EAF6")
                                )
                                PaymentShortcutCard(
                                    icon: "phone.fill",
                                    title: "Nar",
                                    subtitle: "99450123456",
                                    backgroundColor: Color(hex: "E8EAF6")
                                )
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.bottom, 24)
                    
                    // Payment categories list
                    VStack(spacing: 0) {
                        PaymentCategoryRow(
                            icon: "phone.fill",
                            title: "Мобильные операторы",
                            percentage: "2%"
                        )
                        Divider().padding(.leading, 72)
                        PaymentCategoryRow(
                            icon: "house.fill",
                            title: "Коммунальные услуги",
                            percentage: "2%"
                        )
                        Divider().padding(.leading, 72)
                        PaymentCategoryRow(
                            icon: "creditcard.fill",
                            title: "BakıKart"
                        )
                        Divider().padding(.leading, 72)
                        PaymentCategoryRow(
                            icon: "building.columns.fill",
                            title: "Банковские услуги"
                        )
                                    Divider().padding(.leading, 72)
                        PaymentCategoryRow(
                            icon: "doc.text.fill",
                            title: "Штрафы"
                        )
                        }
                        .background(Color.white)
                        .cornerRadius(16)
                        .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                }
            }
            .background(AppColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    EmptyView()
                }
            }
        }
    }
}

struct ServicePromoCard: View {
    let title: String
    let backgroundColor: Color
    let isNew: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if isNew {
            HStack {
                    Text("Новинка")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: "76BC1E"))
                        .cornerRadius(12)
                Spacer()
                }
                .padding(.bottom, 8)
            }
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .frame(width: 172.5, height: 132)
        .padding(16)
        .background(backgroundColor)
        .cornerRadius(16)
    }
}

struct PaymentShortcutCard: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    let backgroundColor: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(AppColors.textPrimary)
                .frame(width: 56, height: 56)
                .background(backgroundColor)
                .cornerRadius(12)
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .frame(width: 80)
    }
}

struct PaymentCategoryRow: View {
    let icon: String
    let title: String
    var percentage: String? = nil

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(Color(hex: "76BC1E"))
                .frame(width: 40, height: 40)
            
                Text(title)
                .font(.system(size: 16, weight: .regular))
                    .foregroundColor(AppColors.textPrimary)
            
            Spacer()
            
            if let percentage = percentage {
                Text("◆ \(percentage)")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: "6946F7"))
                    .cornerRadius(12)
            }
        }
        .padding(16)
    }
}

#Preview {
    PaymentsView()
}
