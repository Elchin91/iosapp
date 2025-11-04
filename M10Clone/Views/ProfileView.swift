//
//  ProfileView.swift
//  M10Clone
//
//  Created by Claude on 2025-11-02.
//

import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationView {
            ZStack {
                Color.white.ignoresSafeArea()
                
            ScrollView {
                VStack(spacing: 0) {
                        // Header section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Профиль")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(AppColors.textPrimary)

                            Text("+994 50 519 99 91")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(AppColors.textPrimary)
                    }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                        .padding(.top, 8)
                    .padding(.bottom, 24)

                        // Top cards
                        HStack(spacing: 16) {
                            ProfileCard(
                                icon: "person.fill",
                                title: "Мои данные"
                            )
                            ProfileCard(
                                icon: "qrcode",
                                title: "Мой QR"
                            )
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)

                        // Menu list
                        VStack(spacing: 0) {
                            MenuRow(
                                icon: "briefcase.fill",
                                title: "Ведите свой бизнес с m10"
                            )
                            Divider().padding(.leading, 72)
                            MenuRow(
                                icon: "gearshape.fill",
                                title: "Настройки"
                            )
                            Divider().padding(.leading, 72)
                            MenuRow(
                                icon: "doc.fill",
                                title: "Документы"
                            )
                            Divider().padding(.leading, 72)
                            MenuRow(
                                icon: "percent",
                                title: "Тарифы и лимиты"
                            )
                            Divider().padding(.leading, 72)
                            MenuRow(
                                icon: "doc.text.fill",
                                title: "Выписка со счета"
                            )
                            Divider().padding(.leading, 72)
                            MenuRow(
                                icon: "headphones",
                                title: "Поддержка"
                            )
                            Divider().padding(.leading, 72)
                            MenuRow(
                                icon: "flag.fill",
                                title: "Язык",
                                subtitle: "Русский"
                            )
                            Divider().padding(.leading, 72)
                            MenuRow(
                                icon: "drop.fill",
                                title: "Карьера в PashaPay"
                            )
                        }
                        .background(Color.white)
                        .cornerRadius(16)
                        .padding(.horizontal, 16)
                    .padding(.bottom, 24)

                    // Logout button
                    Button(action: {}) {
                            Text("Выйти из m10")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(AppColors.textPrimary)
                            .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(AppColors.backgroundSecondary)
                            .cornerRadius(16)
                    }
                    .padding(.horizontal, 16)
                        .padding(.bottom, 100)
                }
            }
                
                // Floating Action Button (FAB)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {}) {
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.yellow)
                                .frame(width: 56, height: 56)
                                .background(Color(hex: "03EDC3"))
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                        }
                        .padding(.trailing, 16)
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

struct ProfileCard: View {
    let icon: String
    let title: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(.white)
                .frame(width: 64, height: 64)
                .background(Color(hex: "6946F7"))
                .clipShape(Circle())
            
                Text(title)
                .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(AppColors.backgroundSecondary)
        .cornerRadius(16)
    }
}

struct MenuRow: View {
    let icon: String
    let title: String
    var subtitle: String? = nil

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                    .foregroundColor(AppColors.textPrimary)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(AppColors.textPrimary)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 14, weight: .regular))
                .foregroundColor(AppColors.textSecondary)
                    }
                }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(AppColors.iconSecondary)
        }
        .padding(16)
        .background(AppColors.backgroundSecondary)
    }
}

#Preview {
    ProfileView()
}
