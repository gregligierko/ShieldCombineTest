//
//  ContentView.swift
//  ShieldCombineTest2
//
//  Created by Greg Ligierko on 01/10/2025.
//
import SwiftUI
import FamilyControls
import ManagedSettings

@main
struct ShieldTestApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @StateObject private var shieldManager = ShieldManager()
    @State private var showSpecificPicker = false
    @State private var showExceptPicker = false

    var body: some View {
        NavigationView {
            List {
                Section("Authorization") {
                    Button("Request Authorization") {
                        Task {
                            await shieldManager.requestAuthorization()
                        }
                    }

                    Text("Status: \(shieldManager.authorizationStatus)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section("Store A - Specific App Shield") {
                    Button("Pick App to Block") {
                        showSpecificPicker = true
                    }

                    if !shieldManager.specificSelection.applicationTokens.isEmpty {
                        Text("Selected: \(shieldManager.specificSelection.applicationTokens.count) app(s)")
                            .font(.caption)
                    }

                    Button("Apply Shield to Store A") {
                        shieldManager.applySpecificShield()
                    }
                    .disabled(shieldManager.specificSelection.applicationTokens.isEmpty)

                    Button("Clear Store A") {
                        shieldManager.clearSpecificShield()
                    }
                }

                Section("Store B - All Except Shield") {
                    Button("Pick Apps to Exempt") {
                        showExceptPicker = true
                    }

                    if !shieldManager.exceptSelection.applicationTokens.isEmpty {
                        Text("Exempted: \(shieldManager.exceptSelection.applicationTokens.count) app(s)")
                            .font(.caption)
                    }

                    Button("Apply Shield to Store B (All Except)") {
                        shieldManager.applyExceptShield()
                    }
                    .disabled(shieldManager.exceptSelection.applicationTokens.isEmpty)

                    Button("Clear Store B") {
                        shieldManager.clearExceptShield()
                    }
                }

                Section("Combined Test") {
                    Button("Apply Both Shields") {
                        shieldManager.applyBothShields()
                    }
                    .disabled(shieldManager.specificSelection.applicationTokens.isEmpty ||
                             shieldManager.exceptSelection.applicationTokens.isEmpty)

                    Button("Clear Both Shields") {
                        shieldManager.clearBothShields()
                    }
                }

                Section("Status") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Store A (Specific): \(shieldManager.isStoreAActive ? "Active" : "Inactive")")
                        Text("Store B (All Except): \(shieldManager.isStoreBActive ? "Active" : "Inactive")")
                    }
                    .font(.caption)
                }
            }
            .navigationTitle("Shield Test")
        }
        .familyActivityPicker(
            isPresented: $showSpecificPicker,
            selection: $shieldManager.specificSelection
        )
        .familyActivityPicker(
            isPresented: $showExceptPicker,
            selection: $shieldManager.exceptSelection
        )
    }
}

@MainActor
class ShieldManager: ObservableObject {
    // Two separate stores
    private let storeA = ManagedSettingsStore(named: .storeA)
    private let storeB = ManagedSettingsStore(named: .storeB)

    @Published var specificSelection = FamilyActivitySelection()
    @Published var exceptSelection = FamilyActivitySelection()
    @Published var authorizationStatus = "Unknown"
    @Published var isStoreAActive = false
    @Published var isStoreBActive = false

    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            authorizationStatus = "Approved"
        } catch {
            authorizationStatus = "Denied: \(error.localizedDescription)"
        }
    }

    // Store A: Block specific apps
    func applySpecificShield() {
        print("📱 Applying SPECIFIC shield to Store A")
        print("   Apps to block: \(specificSelection.applicationTokens.count)")

        storeA.shield.applications = specificSelection.applicationTokens
        storeA.shield.applicationCategories = .specific(specificSelection.categoryTokens)
        storeA.shield.webDomains = specificSelection.webDomainTokens

        isStoreAActive = true
        print("✅ Store A applied")
    }

    // Store B: Block all except selected apps
    func applyExceptShield() {
        print("🌍 Applying ALL EXCEPT shield to Store B")
        print("   Apps to exempt: \(exceptSelection.applicationTokens.count)")

        // This is the critical line that should allow all except selected apps
        storeB.shield.applicationCategories = .all(except: exceptSelection.applicationTokens)
        storeB.shield.webDomainCategories = .all(except: exceptSelection.webDomainTokens)

        isStoreBActive = true
        print("✅ Store B applied")
    }

    // Apply both shields simultaneously
    func applyBothShields() {
        print("\n🔄 Applying BOTH shields...")
        applySpecificShield()
        applyExceptShield()
        print("🔄 Both shields applied\n")
    }

    func clearSpecificShield() {
        print("🧹 Clearing Store A")
        storeA.clearAllSettings()
        isStoreAActive = false
    }

    func clearExceptShield() {
        print("🧹 Clearing Store B")
        storeB.clearAllSettings()
        isStoreBActive = false
    }

    func clearBothShields() {
        print("🧹 Clearing both stores")
        clearSpecificShield()
        clearExceptShield()
    }
}

// Store name extensions
extension ManagedSettingsStore.Name {
    static let storeA = Self("com.test.storeA")
    static let storeB = Self("com.test.storeB")
}
