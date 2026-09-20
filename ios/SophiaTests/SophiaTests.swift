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

    @Test func presentedSchemeAlwaysResolvesAConcreteValue() {
        #expect(AppearancePreference.dark.resolvedPresentedColorScheme() == .dark)
        #expect(AppearancePreference.light.resolvedPresentedColorScheme() == .light)
        let automatic = AppearancePreference.system.resolvedPresentedColorScheme()
        let screenIsDark = UIScreen.main.traitCollection.userInterfaceStyle == .dark
        #expect(automatic == (screenIsDark ? .dark : .light))
        #expect(AppearancePreference.dark.presentedUserInterfaceStyle == .dark)
        #expect(AppearancePreference.light.presentedUserInterfaceStyle == .light)
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

// MARK: - Home deck

/// The deck replaced `courses.shuffled()`, so these check the two things a shuffle
/// gave for free and a weighted draw can lose: every course still reachable, and no
/// subject able to vanish from someone's deck.
struct HomeDeckBuilderTests {

    private var catalogue: [Course] { CourseData.allCourses }

    private func seeded(_ value: UInt64) -> SeededGenerator { SeededGenerator(seed: value) }

    @Test func generatedAffinityMatchesTheShippedCatalogue() {
        let ids = Set(catalogue.map(\.id))
        let scored = Set(CourseAffinity.quality.keys)
        // A stale CourseAffinity.swift is the one failure mode of a generated file:
        // ids it knows that the app no longer ships would score courses nobody can
        // ever be dealt. Re-run scripts/build_course_affinity.py.
        #expect(scored.subtracting(ids).isEmpty)
        for (courseId, neighbours) in CourseAffinity.neighbourIds {
            #expect(ids.contains(courseId))
            #expect(Set(neighbours).subtracting(ids).isEmpty)
            #expect(neighbours.count == CourseAffinity.neighbourLifts[courseId]?.count)
        }
    }

    @Test func baseWeightsFavourScienceAndSumToOne() {
        let weights = HomeDeckBuilder.subjectWeights(context: .empty)
        let total = weights.values.reduce(0, +)
        #expect(abs(total - 1) < 0.0001)

        let science = weights[Subject.sciences.storageKey] ?? 0
        let myth = weights[Subject.mythologie.storageKey] ?? 0
        // Roughly a third of the deck, and well ahead of mythology — which is what
        // readers did when every course got identical exposure.
        #expect(science > 0.3 && science < 0.4)
        #expect(science > myth * 3)
    }

    @Test func historyBendsTheWeightsButNeverStarvesASubject() {
        let scienceOnly = DeckContext(
            completedBySubject: [Subject.sciences.storageKey: 20]
        )
        let weights = HomeDeckBuilder.subjectWeights(context: scienceOnly)

        let science = weights[Subject.sciences.storageKey] ?? 0
        #expect(science > (HomeDeckBuilder.subjectWeights(context: .empty)[Subject.sciences.storageKey] ?? 0))

        for subject in Subject.allCases {
            #expect((weights[subject.storageKey] ?? 0) >= HomeDeckBuilder.subjectFloor - 0.0001)
        }
        #expect(abs(weights.values.reduce(0, +) - 1) < 0.0001)
    }

    @Test func theObjectiveNudgesANewReaderAndThenStopsMattering() {
        let objective = Set([Subject.mythologie.storageKey])
        let fresh = HomeDeckBuilder.subjectWeights(
            context: DeckContext(objectiveSubjects: objective)
        )
        let neutral = HomeDeckBuilder.subjectWeights(context: .empty)
        #expect((fresh[Subject.mythologie.storageKey] ?? 0) > (neutral[Subject.mythologie.storageKey] ?? 0))

        // Past `objectiveFadesAfter`, what was ticked once no longer competes with
        // what the reader actually reads.
        let experienced = DeckContext(
            completedBySubject: [Subject.histoire.storageKey: HomeDeckBuilder.objectiveFadesAfter],
            objectiveSubjects: objective
        )
        let without = DeckContext(
            completedBySubject: [Subject.histoire.storageKey: HomeDeckBuilder.objectiveFadesAfter]
        )
        #expect(
            HomeDeckBuilder.subjectWeights(context: experienced)
                == HomeDeckBuilder.subjectWeights(context: without)
        )
    }

    @Test func dealsEveryUnfinishedCourseExactlyOnce() {
        let finished = Set(catalogue.prefix(10).map(\.id))
        var generator = seeded(42)
        let deck = HomeDeckBuilder.deck(
            from: catalogue,
            context: .empty,
            isCompleted: { finished.contains($0) },
            using: &generator
        )

        #expect(deck.count == catalogue.count - finished.count)
        #expect(Set(deck.map(\.id)).count == deck.count)
        #expect(deck.allSatisfy { !finished.contains($0.id) })
    }

    @Test func neverDealsThreeCardsOfTheSameSubjectInARow() {
        // Several seeds: the run guard has to hold for every draw, not one lucky deal.
        for seed in UInt64(1)...25 {
            var generator = seeded(seed)
            let deck = HomeDeckBuilder.deck(
                from: catalogue,
                context: DeckContext(completedBySubject: [Subject.sciences.storageKey: 30]),
                isCompleted: { _ in false },
                using: &generator
            )
            // Only the head: once a subject runs out of cards a run becomes the only
            // way to deal the rest, and dropping those would be worse than a run. 40
            // cards is short of the smallest pool, so nothing here is forced.
            let head = deck.prefix(40).map(\.subject.storageKey)
            for index in 2..<head.count {
                let run = head[index - 2] == head[index - 1] && head[index - 1] == head[index]
                #expect(!run, "three \(head[index]) cards in a row at \(index), seed \(seed)")
            }
        }
    }

    @Test func aFreshReaderGetsAboutAThirdScienceUpFront() {
        var science = 0
        var total = 0
        for seed in UInt64(1)...40 {
            var generator = seeded(seed)
            let deck = HomeDeckBuilder.deck(
                from: catalogue,
                context: .empty,
                isCompleted: { _ in false },
                using: &generator
            )
            for course in deck.prefix(20) {
                total += 1
                if course.subject == .sciences { science += 1 }
            }
        }
        let share = Double(science) / Double(total)
        // Exploration never deals the dominant subject, so the 35 % quota arrives
        // diluted to roughly 26 % — still well clear of the 16.7 % a shuffle gave it.
        #expect(share > 0.2 && share < 0.4, "science share \(share)")
    }

    @Test func everySubjectStillAppearsForASingleMindedReader() {
        var generator = seeded(7)
        let deck = HomeDeckBuilder.deck(
            from: catalogue,
            context: DeckContext(completedBySubject: [Subject.sciences.storageKey: 40]),
            isCompleted: { _ in false },
            using: &generator
        )
        let subjectsUpFront = Set(deck.prefix(150).map(\.subject))
        #expect(subjectsUpFront.count == Subject.allCases.count)
    }

    @Test func sameSeedDealsTheSameDeck() {
        var first = seeded(99)
        var second = seeded(99)
        let a = HomeDeckBuilder.deck(from: catalogue, context: .empty, isCompleted: { _ in false }, using: &first)
        let b = HomeDeckBuilder.deck(from: catalogue, context: .empty, isCompleted: { _ in false }, using: &second)
        #expect(a.map(\.id) == b.map(\.id))
    }

    @Test func skippingACourseLowersItsScoreAndReadingItsNeighbourRaisesIt() {
        // "Pourquoi rêve-t-on" — the most finished course in the catalogue, so its
        // quality term is 1 and any movement below comes from the other two terms.
        let dreams = "course_42_pourquoi_reve_t_on"
        guard let course = catalogue.first(where: { $0.id == dreams }) else {
            Issue.record("\(dreams) missing from the catalogue")
            return
        }

        let neutral = HomeDeckBuilder.score(course, context: .empty)
        let skipped = HomeDeckBuilder.score(
            course, context: DeckContext(skipCounts: [dreams: 4])
        )
        #expect(skipped < neutral)

        guard let neighbour = CourseAffinity.neighbours(of: dreams).first else {
            Issue.record("\(dreams) has no neighbour to test with")
            return
        }
        let afterNeighbour = HomeDeckBuilder.score(
            course, context: DeckContext(recentCourseIds: [neighbour.id])
        )
        #expect(afterNeighbour > neutral)
    }
}

struct DeckSkipStoreTests {

    private func withIsolatedDefaults(_ body: (UserDefaults) -> Void) {
        let suite = "sophia.deckskip.tests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else {
            Issue.record("Could not create isolated UserDefaults suite")
            return
        }
        defaults.removePersistentDomain(forName: suite)
        body(defaults)
        defaults.removePersistentDomain(forName: suite)
    }

    @Test func countsSkipsUpToTheCapAndClearsOnOpen() {
        withIsolatedDefaults { defaults in
            for _ in 0..<20 {
                DeckSkipStore.registerSkip("course_1", defaults: defaults)
            }
            let capped = DeckSkipStore.counts(defaults: defaults)["course_1"] ?? 0
            #expect(capped > 0 && capped <= 8)

            DeckSkipStore.clear("course_1", defaults: defaults)
            #expect(DeckSkipStore.counts(defaults: defaults)["course_1"] == nil)
        }
    }

    @Test func staysBoundedWhenEveryCourseIsSkipped() {
        withIsolatedDefaults { defaults in
            for index in 0..<400 {
                DeckSkipStore.registerSkip("course_\(index)", defaults: defaults)
            }
            #expect(DeckSkipStore.counts(defaults: defaults).count <= 120)
        }
    }
}
