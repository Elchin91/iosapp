//
//  PaymentsView.swift
//  M10Clone
//
//  Created by Claude on 2025-11-02.
//

import SwiftUI

struct PaymentsView: View {
    @State private var searchText = ""

    let categories = [
        PaymentCategory(icon: "phone.fill", title: "Мобильная связь", color: AppColors.primary, description: "Azercell, Bakcell, Nar"),
        PaymentCategory(icon: "bolt.fill", title: "Коммунальные", color: Color(hex: "FF6B35"), description: "Qaz, İşıq, Su"),
        PaymentCategory(icon: "wifi", title: "Интернет", color: Color(hex: "4ECDC4"), description: "AiləNet, Avirtel, AzerOnline"),
        PaymentCategory(icon: "tv.fill", title: "ТВ и Стриминг", color: Color(hex: "FF6B9D"), description: "AiləTV, ATV Plus"),
        PaymentCategory(icon: "gamecontroller.fill", title: "Игры", color: AppColors.primary, description: "Steam, Warface, PUBG"),
        PaymentCategory(icon: "cart.fill", title: "Онлайн магазины", color: Color(hex: "9B59B6"), description: "Lalafo, Wolt, Bolt"),
        PaymentCategory(icon: "building.columns.fill", title: "Банки", color: Color(hex: "3498DB"), description: "Кредиты, вклады"),
        PaymentCategory(icon: "car.fill", title: "Парковка", color: Color(hex: "E67E22"), description: "AzParking, BCR Parking")
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Search bar
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(AppColors.textSecondary)
                        
                        TextField("Поиск услуг", text: $searchText)
                            .font(.system(size: 16))
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    // Categories grid
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 12) {
                        ForEach(categories) { category in
                            PaymentCategoryCard(category: category)
                        }
                    }
                    .padding(16)

                    // Recent payments
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Недавние платежи")
                                .font(.system(size: 20, weight: .bold))
                            Spacer()
                        }
                        .padding(.horizontal, 16)

                        VStack(spacing: 0) {
                            ForEach(recentPayments, id: \.id) { payment in
                                RecentPaymentRow(
                                    icon: payment.icon,
                                    title: payment.title,
                                    subtitle: payment.subtitle,
                                    color: payment.color
                                )
                                if payment.id != recentPayments.last?.id {
                                    Divider().padding(.leading, 72)
                                }
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(16)
                        .padding(.horizontal, 16)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 20)
                }
            }
            .background(AppColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Платежи")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                }
            }
        }
    }
    
    var recentPayments: [RecentPayment] {
        [
            RecentPayment(id: UUID(), icon: "phone.fill", title: "Azercell", subtitle: "+994 50 123 45 67", color: AppColors.primary),
            RecentPayment(id: UUID(), icon: "wifi", title: "AiləNet", subtitle: "Договор 123456789", color: Color(hex: "4ECDC4")),
            RecentPayment(id: UUID(), icon: "bolt.fill", title: "AzəriQaz", subtitle: "Квартира 45", color: Color(hex: "FF6B35")),
            RecentPayment(id: UUID(), icon: "tv.fill", title: "AiləTV", subtitle: "Абонент 987654", color: Color(hex: "FF6B9D"))
        ]
    }
}

struct PaymentCategory: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let color: Color
    let description: String
}

struct PaymentCategoryCard: View {
    let category: PaymentCategory

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: category.icon)
                    .font(.system(size: 24))
                    .foregroundColor(category.color)
                    .frame(width: 48, height: 48)
                    .background(category.color.opacity(0.15))
                    .clipShape(Circle())
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(category.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                Text(category.description)
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct RecentPayment: Identifiable {
    let id: UUID
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
}

struct RecentPaymentRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.white)
                .frame(width: 48, height: 48)
                .background(color)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(16)
    }
}

#Preview {
    PaymentsView()
}
