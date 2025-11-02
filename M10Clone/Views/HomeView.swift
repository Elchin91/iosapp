//
//  HomeView.swift
//  M10Clone
//
//  Created by Claude on 2025-11-02.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Balance Card - главная карточка баланса в стиле M10
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Баланс")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.white.opacity(0.9))

                                Text("15,250.00 ₼")
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(.white)
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.up.right")
                                        .font(.system(size: 12))
                                    Text("+2,350 ₼ за этот месяц")
                                        .font(.system(size: 13))
                                }
                                .foregroundColor(.white.opacity(0.85))
                            }
                            
                            Spacer()
                            
                            // Иконка уведомлений
                            Button(action: {}) {
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(Color.white.opacity(0.2))
                                    .clipShape(Circle())
                            }
                        }
                        
                        // Быстрые действия на карточке баланса
                        HStack(spacing: 12) {
                            QuickActionMiniButton(icon: "arrow.up", title: "Отправить", color: .white)
                            QuickActionMiniButton(icon: "arrow.down", title: "Получить", color: .white)
                            QuickActionMiniButton(icon: "plus.circle", title: "Пополнить", color: .white)
                            QuickActionMiniButton(icon: "arrow.left.arrow.right", title: "Обменять", color: .white)
                        }
                    }
                    .padding(24)
                    .background(
                        LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDark],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    // Бонусы/Lim10 секция
                    HStack(spacing: 16) {
                        BonusCard(
                            icon: "star.fill",
                            title: "Lim10",
                            amount: "1,250",
                            color: Color(hex: "FFD700")
                        )
                        BonusCard(
                            icon: "gift.fill",
                            title: "Бонусы",
                            amount: "350",
                            color: AppColors.primary
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                    // Категории быстрых платежей
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Платежи")
                            .font(.system(size: 20, weight: .bold))
                            .padding(.horizontal, 16)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                PaymentCategoryButton(
                                    icon: "phone.fill",
                                    title: "Мобильная\nсвязь",
                                    color: AppColors.primary
                                )
                                PaymentCategoryButton(
                                    icon: "bolt.fill",
                                    title: "Коммунальные\nуслуги",
                                    color: Color(hex: "FF6B35")
                                )
                                PaymentCategoryButton(
                                    icon: "wifi",
                                    title: "Интернет",
                                    color: Color(hex: "4ECDC4")
                                )
                                PaymentCategoryButton(
                                    icon: "tv.fill",
                                    title: "ТВ и\nСтриминг",
                                    color: Color(hex: "FF6B9D")
                                )
                                PaymentCategoryButton(
                                    icon: "gamecontroller.fill",
                                    title: "Игры",
                                    color: AppColors.primary
                                )
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.top, 24)

                    // Последние операции
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Последние операции")
                                .font(.system(size: 20, weight: .bold))
                            Spacer()
                            Button("Все") {
                                // Показать все операции
                            }
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(AppColors.primary)
                        }
                        .padding(.horizontal, 16)

                        VStack(spacing: 0) {
                            TransactionRow(
                                icon: "cart.fill",
                                title: "Пятерочка",
                                subtitle: "Покупка",
                                date: "Сегодня, 14:23",
                                amount: "-500 ₼",
                                isPositive: false,
                                categoryColor: Color(hex: "FF6B35")
                            )
                            Divider().padding(.leading, 72)
                            
                            TransactionRow(
                                icon: "person.fill",
                                title: "От Иван Петров",
                                subtitle: "Перевод",
                                date: "Вчера, 18:45",
                                amount: "+2,000 ₼",
                                isPositive: true,
                                categoryColor: AppColors.success
                            )
                            Divider().padding(.leading, 72)
                            
                            TransactionRow(
                                icon: "wifi",
                                title: "Azercell",
                                subtitle: "Мобильная связь",
                                date: "01 Ноя, 10:30",
                                amount: "-350 ₼",
                                isPositive: false,
                                categoryColor: AppColors.primary
                            )
                            Divider().padding(.leading, 72)
                            
                            TransactionRow(
                                icon: "bolt.fill",
                                title: "AzəriQaz",
                                subtitle: "Коммунальные",
                                date: "31 Окт, 09:15",
                                amount: "-120 ₼",
                                isPositive: false,
                                categoryColor: Color(hex: "FF6B35")
                            )
                        }
                        .background(Color.white)
                        .cornerRadius(16)
                        .padding(.horizontal, 16)
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 20)
                }
            }
            .background(AppColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Image(systemName: "m10.logo")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppColors.primary)
                }
            }
        }
    }
}

struct QuickActionMiniButton: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(Color.white.opacity(0.2))
                .clipShape(Circle())
            
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(color)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

struct BonusCard: View {
    let icon: String
    let title: String
    let amount: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 48, height: 48)
                .background(color.opacity(0.15))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
                Text(amount)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct PaymentCategoryButton: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(color)
                .frame(width: 64, height: 64)
                .background(color.opacity(0.15))
                .clipShape(Circle())
            
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(width: 80)
    }
}

struct TransactionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let date: String
    let amount: String
    let isPositive: Bool
    let categoryColor: Color

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.white)
                .frame(width: 48, height: 48)
                .background(categoryColor)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)
                HStack(spacing: 4) {
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.textSecondary)
                    Text("•")
                        .foregroundColor(AppColors.textSecondary)
                    Text(date)
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            
            Spacer()
            
            Text(amount)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(isPositive ? AppColors.success : AppColors.textPrimary)
        }
        .padding(16)
    }
}

#Preview {
    HomeView()
}
