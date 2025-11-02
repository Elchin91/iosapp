//
//  HomeView.swift
//  M10Clone
//
//  Created by Claude on 2025-11-02.
//

import SwiftUI

struct HomeView: View {
    @State private var balanceVisible = true
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color(hex: "E8FCFF"), Color.white],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Header section
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "qrcode")
                                    .font(.system(size: 20))
                                    .foregroundColor(AppColors.textPrimary)
                                Text("Мой QR")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(AppColors.textPrimary)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 16)
                        
                        // Main Balance Card
                        VStack(spacing: 0) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Доступно")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(AppColors.textSecondary)
                                
                                HStack(alignment: .bottom, spacing: 8) {
                                    Text(balanceVisible ? "41.77" : "••••")
                                        .font(.system(size: 48, weight: .semibold))
                                        .foregroundColor(AppColors.textPrimary)
                                    
                                    Text("₼")
                                        .font(.system(size: 48, weight: .semibold))
                                        .foregroundColor(AppColors.textPrimary)
                                    
                                    Button(action: {
                                        balanceVisible.toggle()
                                    }) {
                                        Image(systemName: balanceVisible ? "eye.slash" : "eye")
                                            .font(.system(size: 20))
                                            .foregroundColor(AppColors.textSecondary)
                                    }
                                    .padding(.leading, 8)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.top, 24)
                            
                            // Action buttons
                            HStack(spacing: 12) {
                                Button(action: {}) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "plus")
                                            .font(.system(size: 16))
                                        Text("Пополнить")
                                            .font(.system(size: 16, weight: .medium))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .background(AppColors.textPrimary)
                                    .cornerRadius(16)
                                }
                                
                                Button(action: {}) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "arrow.up.right")
                                            .font(.system(size: 16))
                                        Text("Перевести")
                                            .font(.system(size: 16, weight: .medium))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .background(AppColors.textPrimary)
                                    .cornerRadius(16)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                            .padding(.bottom, 24)
                        }
                        .background(Color.white)
                        .cornerRadius(24)
                        .shadow(color: Color.black.opacity(0.12), radius: 32, x: 0, y: 12)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                        
                        // Мои платежи section
                        HStack(spacing: 16) {
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 24))
                                .foregroundColor(AppColors.textPrimary)
                                .frame(width: 46, height: 46)
                                .background(Color(hex: "D2C7FC").opacity(0.3))
                                .cornerRadius(12)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Мои платежи")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(AppColors.textPrimary)
                                Text("8 сохраненных платежей")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16))
                                .foregroundColor(AppColors.iconSecondary)
                        }
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                        
                        // Benefit cards horizontal scroll
                        VStack(alignment: .leading, spacing: 16) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    BenefitCard(
                                        title: "Пожертвование в фонд «YAŞAT»",
                                        backgroundColor: Color(hex: "02205F"),
                                        textColor: .white
                                    )
                                    BenefitCard(
                                        title: "Квиз на Хеллоуин",
                                        backgroundColor: Color.black,
                                        textColor: .white
                                    )
                                    BenefitCard(
                                        title: "Скоро! Переводы за границу",
                                        backgroundColor: Color(hex: "E8FCFF"),
                                        textColor: AppColors.textPrimary
                                    )
                                    BenefitCard(
                                        title: "Переводы в Россию",
                                        backgroundColor: Color(hex: "E8FCFF"),
                                        textColor: AppColors.textPrimary
                                    )
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                        .padding(.bottom, 24)
                        
                        // НАШИ СЕРВИСЫ section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("НАШИ СЕРВИСЫ")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppColors.textSecondary)
                                .padding(.horizontal, 16)
                            
                            HStack(spacing: 16) {
                                ServiceCard(
                                    title: "Кредит до 25 000₼",
                                    backgroundColor: Color(hex: "3CE4FC")
                                )
                                ServiceCard(
                                    title: "BakıKart",
                                    backgroundColor: Color.white
                                )
                            }
                            .padding(.horizontal, 16)
                        }
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    EmptyView()
                }
            }
        }
    }
}

struct BenefitCard: View {
    let title: String
    let backgroundColor: Color
    let textColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(textColor)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .padding(16)
        }
        .frame(width: 172.5, height: 132)
        .background(backgroundColor)
        .cornerRadius(16)
    }
}

struct ServiceCard: View {
    let title: String
    let backgroundColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(backgroundColor == Color.white ? AppColors.textPrimary : .white)
                .multilineTextAlignment(.leading)
                .padding(16)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .frame(height: 132)
        .background(backgroundColor)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(backgroundColor == Color.white ? Color.clear : Color.clear)
        )
    }
}

#Preview {
    HomeView()
}
