//
//  SophiaTests.swift
//  SophiaTests
//
//  Created by Rork on March 20, 2026.
//

import SwiftUI
import Testing
import UIKit
@testable import Sophia

struct SophiaTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }
}

struct AppearancePreferenceTests {

    @Test func defaultPreferenceIsLightNotAutomatic() {
        let suite = "sophia.appearance.tests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else {
            Issue.record("Could not create isolated UserDefaults suite")
            return
        }
        defaults.removePersistentDomain(forName: suite)
        let manager = AppearanceManager(defaults: defaults)
        #expect(manager.preference == .light)
        #expect(manager.preference.preferredColorScheme == .light)
        defaults.removePersistentDomain(forName: suite)
    }

    @Test func darkPinsColorSchemeAndSystemLeavesItUnset() {
        #expect(AppearancePreference.dark.preferredColorScheme == .dark)
        #expect(AppearancePreference.light.preferredColorScheme == .light)
        #expect(AppearancePreference.system.preferredColorScheme == nil)
    }

    @Test func preferencePersistsAcrossLaunches() {
        let suite = "sophia.appearance.tests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else {
            Issue.record("Could not create isolated UserDefaults suite")
            return
        }
        defaults.removePersistentDomain(forName: suite)

        let writer = AppearanceManager(defaults: defaults)
        writer.setPreference(.dark)
        #expect(AppearanceManager(defaults: defaults).preference == .dark)

        writer.setPreference(.system)
        #expect(AppearanceManager(defaults: defaults).preference == .system)

        writer.setPreference(.light)
        #expect(AppearanceManager(defaults: defaults).preference == .light)

        defaults.removePersistentDomain(forName: suite)
    }

    @Test func unknownStoredValueFallsBackToLight() {
        let suite = "sophia.appearance.tests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else {
            Issue.record("Could not create isolated UserDefaults suite")
            return
        }
        defaults.removePersistentDomain(forName: suite)
        defaults.set("sepia", forKey: AppearanceManager.userDefaultsKey)

        let manager = AppearanceManager(defaults: defaults)
        #expect(manager.preference == .light)

        defaults.removePersistentDomain(forName: suite)
    }

    @Test func appearanceStringsExistForEveryLanguage() {
        let keys = [
            "settings.section.appearance",
            "settings.appearance.light",
            "settings.appearance.dark",
            "settings.appearance.automatic",
            "settings.appearance.hint",
        ]
        for language in AppLanguage.allCases {
            for key in keys {
                let value = AppLocalizable.string(key, language: language)
                #expect(value != key, "Missing \(key) for \(language.rawValue)")
                #expect(!value.isEmpty)
            }
        }
    }

    @Test func frenchAndEnglishNightLabels() {
        #expect(AppLocalizable.string("settings.appearance.dark", language: .french) == "Nuit")
        #expect(AppLocalizable.string("settings.appearance.dark", language: .english) == "Night")
        #expect(AppLocalizable.string("settings.appearance.automatic", language: .french) == "Automatique")
    }

    @Test func canvasAndInkFlipBetweenLightAndDark() {
        let lightCanvas = DS.uiCanvas.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
        let darkCanvas = DS.uiCanvas.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
        let lightInk = DS.uiInk.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
        let darkInk = DS.uiInk.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))

        #expect(luminance(of: lightCanvas) > luminance(of: darkCanvas))
        #expect(luminance(of: darkInk) > luminance(of: lightInk))
        #expect(luminance(of: lightCanvas) > 0.9)
        #expect(luminance(of: darkCanvas) < 0.2)
    }

    private func luminance(of color: UIColor) -> CGFloat {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (0.2126 * r) + (0.7152 * g) + (0.0722 * b)
    }
}
