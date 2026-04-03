//
//  ContentView.swift
//  AlertDrawer
//
//  Created by Abhijit Sahoo on 29/03/26.
//

import SwiftUI

// MARK: - Accent Color
extension Color {
    static let accentPink = Color(red: 0.93, green: 0.18, blue: 0.47)
}

// MARK: - Content View
struct ContentView: View {
    @State private var config: DrawerConfig = .init(
        tint: .accentPink,
        foreground: .white,
        clipShape: .init(.capsule)
    )
    
    @State private var notificationsOn: Bool = true
    @State private var reduceHaptics: Bool = true
    @State private var faceIDOn: Bool = false
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: Header
                HStack {
                    Text("Account Settings")
                        .font(.title2.bold())
                    
                    Spacer()
                    
                    Button {
                        // Dismiss action
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.gray)
                            .frame(width: 30, height: 30)
                            .background(Color.white.opacity(0.1), in: Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 28)
                .padding(.bottom, 24)
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        // MARK: Profile Section
                        HStack(spacing: 14) {
                            // Avatar placeholder
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.orange, .pink],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 48, height: 48)
                                .overlay {
                                    Text("A")
                                        .font(.title3.bold())
                                        .foregroundStyle(.white)
                                }
                            
                            Text("hiii@sendai.fun")
                                .font(.subheadline)
                                .foregroundStyle(.white)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)

                        // MARK: Settings Rows
                        
                        SettingsDivider()
                        
                        // Address Book
                        SettingsRow(
                            icon: "person.text.rectangle.fill",
                            title: "Address Book",
                            trailing: .chevron
                        )
                        
                        SettingsDivider()
                        
                        // Appearance
                        SettingsRow(
                            icon: "moon.fill",
                            title: "Appearance",
                            trailing: .menu("Dark")
                        )
                        
                        SettingsDivider()
                        
                        // Language
                        SettingsRow(
                            icon: "face.smiling.inverse",
                            title: "Language",
                            trailing: .menu("English")
                        )
                        
                        SettingsDivider()
                        
                        // Notifications
                        SettingsRow(
                            icon: "bell.badge.fill",
                            title: "Notifications",
                            trailing: .toggle($notificationsOn)
                        )
                        
                        SettingsDivider()
                        
                        // Reduce Haptics
                        SettingsRow(
                            icon: "waveform",
                            title: "Reduce Haptics",
                            trailing: .toggle($reduceHaptics)
                        )
                        
                        SettingsDivider()
                        
                        // Face ID
                        SettingsRow(
                            icon: "faceid",
                            title: "Face ID",
                            trailing: .toggle($faceIDOn)
                        )
                        
                        SettingsDivider()
                        
                        // Terms of Service
                        SettingsRow(
                            icon: "doc.text.fill",
                            title: "Terms of Service",
                            trailing: .chevron
                        )
                        
                        // MARK: Logout Button (Drawer Trigger)
                        DrawerButton(config: $config) {
                            HStack(spacing: 12) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 20))
                                    .foregroundStyle(Color.accentPink)
                                    .frame(width: 30)
                                
                                Text("Logout")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(Color.accentPink)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 18)
                        }
                    }
                }
            }
            .background(Color(white: 0.15))
            .clipShape(.rect(topLeadingRadius: 20, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 20))
        }
        .fontDesign(.rounded)
        .preferredColorScheme(.dark)
        // MARK: Alert Drawer
        .alertDrawer(
            config: $config,
            primaryTitle: "Logout",
            secondaryTitle: "Cancel"
        ) {
            // Primary (Logout) tapped
            return true
        } onSecondaryClick: {
            // Cancel tapped
            return true
        } content: {
            VStack(alignment: .leading, spacing: 14) {
                // Grab Handle
                Capsule()
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: 36, height: 5)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 4)
                
                // Warning Icon + Title
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.red)
                    
                    Text("Logout")
                        .font(.title3.bold())
                }
                
                // Description
                Text("You'll be logged out of your account on this device.")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Settings Row Component
enum TrailingAccessory {
    case chevron
    case menu(String)
    case toggle(Binding<Bool>)
}

struct SettingsRow: View {
    var icon: String
    var title: String
    var trailing: TrailingAccessory
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(Color(white: 0.48))
                .frame(width: 30)
            
            Text(title)
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
            
            Spacer()
            
            trailingView
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
    }

    @ViewBuilder
    private var trailingView: some View {
        switch trailing {
        case .chevron:
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.gray.opacity(0.6))
            
        case .menu(let value):
            HStack(spacing: 6) {
                Text(value)
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                
                Image(systemName: "ellipsis")
                    .font(.system(size: 14))
                    .foregroundStyle(.gray)
                    .rotationEffect(.degrees(90))
            }
            
        case .toggle(let isOn):
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(.accentPink)
        }
    }
}

// MARK: - Divider
struct SettingsDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.12))
            .frame(height: 0.5)
            .padding(.leading, 64)
    }
}

#Preview {
    ContentView()
}
