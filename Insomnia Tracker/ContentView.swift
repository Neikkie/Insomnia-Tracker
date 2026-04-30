//
//  ContentView.swift
//  Insomnia Trac
//
//  Created by Shanique Beckford on 4/29/26.
//

import SwiftUI
import Charts
import UserNotifications
import UIKit
#if canImport(FoundationModels)
import FoundationModels
#endif

struct SleepLog: Codable, Identifiable {
    let id: UUID
    let date: Date
    let sleepHours: Double
    let bedtime: Date
    let wakeTime: Date
    let notes: String
    let feeling: String
    let activities: [String]
    let activityLevel: Int
    let lateNightEating: Bool
    let waterIntakeGlasses: Int
    let coffeeIntakeCups: Int
    let alcoholIntakeDrinks: Int
    let difficultyFallingAsleep: Int
    let nighttimeWakeUps: Int
    let morningEnergy: Int

    enum CodingKeys: String, CodingKey {
        case id
        case date
        case sleepHours
        case bedtime
        case wakeTime
        case notes
        case feeling
        case activities
        case activityLevel
        case lateNightEating
        case waterIntakeGlasses
        case coffeeIntakeCups
        case alcoholIntakeDrinks
        case dailyActivities
        case eatingHabit
        case drinkingHabit
        case difficultyFallingAsleep
        case nighttimeWakeUps
        case morningEnergy
    }

    init(
        id: UUID = UUID(),
        date: Date,
        sleepHours: Double,
        bedtime: Date,
        wakeTime: Date,
        notes: String,
        feeling: String,
        activities: [String],
        activityLevel: Int,
        lateNightEating: Bool,
        waterIntakeGlasses: Int,
        coffeeIntakeCups: Int,
        alcoholIntakeDrinks: Int,
        difficultyFallingAsleep: Int,
        nighttimeWakeUps: Int,
        morningEnergy: Int
    ) {
        self.id = id
        self.date = date
        self.sleepHours = sleepHours
        self.bedtime = bedtime
        self.wakeTime = wakeTime
        self.notes = notes
        self.feeling = feeling
        self.activities = activities
        self.activityLevel = activityLevel
        self.lateNightEating = lateNightEating
        self.waterIntakeGlasses = waterIntakeGlasses
        self.coffeeIntakeCups = coffeeIntakeCups
        self.alcoholIntakeDrinks = alcoholIntakeDrinks
        self.difficultyFallingAsleep = difficultyFallingAsleep
        self.nighttimeWakeUps = nighttimeWakeUps
        self.morningEnergy = morningEnergy
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        date = try container.decode(Date.self, forKey: .date)
        sleepHours = try container.decodeIfPresent(Double.self, forKey: .sleepHours) ?? 0
        bedtime = try container.decodeIfPresent(Date.self, forKey: .bedtime) ?? date
        wakeTime = try container.decodeIfPresent(Date.self, forKey: .wakeTime) ?? date
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        feeling = try container.decodeIfPresent(String.self, forKey: .feeling) ?? "Tired"

        let decodedActivities = try container.decodeIfPresent([String].self, forKey: .activities)
        if let decodedActivities, !decodedActivities.isEmpty {
            activities = decodedActivities
        } else {
            let legacyActivities = try container.decodeIfPresent(String.self, forKey: .dailyActivities) ?? ""
            activities = legacyActivities
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }

        activityLevel = try container.decodeIfPresent(Int.self, forKey: .activityLevel) ?? 3
        lateNightEating = try container.decodeIfPresent(Bool.self, forKey: .lateNightEating)
            ?? ((try container.decodeIfPresent(String.self, forKey: .eatingHabit) ?? "").lowercased().contains("late"))
        waterIntakeGlasses = try container.decodeIfPresent(Int.self, forKey: .waterIntakeGlasses)
            ?? ((try container.decodeIfPresent(String.self, forKey: .drinkingHabit) ?? "").lowercased().contains("low") ? 3 : 6)
        coffeeIntakeCups = try container.decodeIfPresent(Int.self, forKey: .coffeeIntakeCups) ?? 0
        alcoholIntakeDrinks = try container.decodeIfPresent(Int.self, forKey: .alcoholIntakeDrinks) ?? 0

        difficultyFallingAsleep = try container.decode(Int.self, forKey: .difficultyFallingAsleep)
        nighttimeWakeUps = try container.decode(Int.self, forKey: .nighttimeWakeUps)
        morningEnergy = try container.decode(Int.self, forKey: .morningEnergy)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(date, forKey: .date)
        try container.encode(sleepHours, forKey: .sleepHours)
        try container.encode(bedtime, forKey: .bedtime)
        try container.encode(wakeTime, forKey: .wakeTime)
        try container.encode(notes, forKey: .notes)
        try container.encode(feeling, forKey: .feeling)
        try container.encode(activities, forKey: .activities)
        try container.encode(activityLevel, forKey: .activityLevel)
        try container.encode(lateNightEating, forKey: .lateNightEating)
        try container.encode(waterIntakeGlasses, forKey: .waterIntakeGlasses)
        try container.encode(coffeeIntakeCups, forKey: .coffeeIntakeCups)
        try container.encode(alcoholIntakeDrinks, forKey: .alcoholIntakeDrinks)
        try container.encode(difficultyFallingAsleep, forKey: .difficultyFallingAsleep)
        try container.encode(nighttimeWakeUps, forKey: .nighttimeWakeUps)
        try container.encode(morningEnergy, forKey: .morningEnergy)
    }

    var insomniaScore: Double {
        let adjustedEnergy = 6 - morningEnergy
        let total = difficultyFallingAsleep + nighttimeWakeUps + adjustedEnergy
        return Double(total) / 3.0
    }
}

private enum AppTab: Hashable {
    case overview
    case log
    case history
    case settings
}

struct ContentView: View {
    @Environment(\.openURL) private var openURL
    @AppStorage("sleepLogsData") private var sleepLogsData = ""
    @AppStorage("hasSeenWelcomeScreen") private var hasSeenWelcomeScreen = false
    @AppStorage("reminderHour") private var reminderHour = 21
    @AppStorage("reminderMinute") private var reminderMinute = 0
    @AppStorage("morningReminderHour") private var morningReminderHour = 8
    @AppStorage("morningReminderMinute") private var morningReminderMinute = 0

    @State private var sleepLogs: [SleepLog] = []
    @State private var selectedSleepHours = 7.5
    @State private var selectedBedtime = Calendar.current.date(bySettingHour: 23, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var selectedWakeTime = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var selectedNotes = ""
    @State private var selectedFeeling = "Tired"
    @State private var selectedActivities: Set<String> = []
    @State private var customActivityInput = ""
    @State private var selectedActivityLevel = 3
    @State private var selectedLateNightEating = false
    @State private var selectedWaterIntakeGlasses = 6
    @State private var selectedCoffeeIntakeCups = 0
    @State private var selectedAlcoholIntakeDrinks = 0
    @State private var selectedDifficulty = 3
    @State private var selectedWakeUps = 2
    @State private var selectedEnergy = 3
    @State private var selectedDate = Date()
    @State private var selectedTab: AppTab = .overview
    @State private var editingLogID: UUID?
    @State private var notificationsEnabled = false
    @State private var notificationPermissionDenied = false
    @State private var statusMessage = ""
    @State private var animateCards = false
    @State private var animateBackground = false
    @State private var animateTrendIcon = false
    @State private var showWelcomeScreen = false
    @State private var aiCoachSummary = ""
    @State private var aiCoachHeadline = ""
    @State private var aiCoachStatusMessage = ""
    @State private var isGeneratingAISummary = false

    private let commonActivities = ["Workout", "Work", "School", "Study", "Walking", "Screen Time", "Social", "Napping", "Travel", "Gaming"]
    private let moonGlow = Color(red: 0.98, green: 0.92, blue: 0.83)
    private let dawnLavender = Color(red: 0.73, green: 0.58, blue: 0.98)
    private let starlight = Color(red: 0.86, green: 0.89, blue: 1.0)
    private let twilightBlue = Color(red: 0.13, green: 0.17, blue: 0.46)

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        overviewHeroCard
                        overviewMetricsGrid
                        sleepHistoryChartCard
                        recommendationsCard
                    }
                    .padding()
                    .opacity(animateCards ? 1 : 0)
                    .offset(y: animateCards ? 0 : 10)
                    .animation(.easeOut(duration: 0.35), value: animateCards)
                }
                .background(overviewBackground)
                .navigationTitle("Overview")
            }
            .tabItem {
                Label("Overview", systemImage: "chart.line.uptrend.xyaxis")
            }
            .tag(AppTab.overview)

            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        logFormCard
                    }
                    .padding()
                    .padding(.bottom, 120)
                    .opacity(animateCards ? 1 : 0)
                    .offset(y: animateCards ? 0 : 10)
                    .animation(.easeOut(duration: 0.4), value: animateCards)
                }
                .background(appBackground)
                .navigationTitle("Log")
                .safeAreaInset(edge: .bottom) {
                    logActionBar
                }
            }
            .tabItem {
                Label("Log", systemImage: "square.and.pencil")
            }
            .tag(AppTab.log)

            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        historyListCard
                    }
                    .padding()
                    .opacity(animateCards ? 1 : 0)
                    .offset(y: animateCards ? 0 : 10)
                    .animation(.easeOut(duration: 0.42), value: animateCards)
                }
                .background(appBackground)
                .navigationTitle("History")
            }
            .tabItem {
                Label("History", systemImage: "clock.arrow.circlepath")
            }
            .tag(AppTab.history)

            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        notificationSettingsCard
                        supportCard
                        aboutLegalCard
                    }
                    .padding()
                    .opacity(animateCards ? 1 : 0)
                    .offset(y: animateCards ? 0 : 10)
                    .animation(.easeOut(duration: 0.45), value: animateCards)
                }
                .background(appBackground)
                .navigationTitle("Settings")
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
            .tag(AppTab.settings)
        }
        .tint(dawnLavender)
        .preferredColorScheme(.dark)
        .onAppear {
            loadLogs()
            checkNotificationStatus()
            animateCards = true
            animateBackground = true
            animateTrendIcon = true
            if !hasSeenWelcomeScreen {
                showWelcomeScreen = true
            }
        }
        .onChange(of: selectedDate) { newValue in
            selectedBedtime = combine(date: newValue, withTimeFrom: selectedBedtime)
            selectedWakeTime = combine(date: newValue, withTimeFrom: selectedWakeTime)
        }
        .fullScreenCover(isPresented: $showWelcomeScreen) {
            WelcomeScreen(
                onContinue: {
                    hasSeenWelcomeScreen = true
                    showWelcomeScreen = false
                },
                onLoadSampleData: {
                    loadSampleData()
                    hasSeenWelcomeScreen = true
                    showWelcomeScreen = false
                }
            )
        }
    }

    private var logHeaderTitle: String {
        editingLogID == nil ? "Nightly Check-In" : "Edit Sleep Log"
    }

    private var logHeaderSubtitle: String {
        editingLogID == nil
            ? "Log the essentials first, then add extra details only when they matter."
            : "Update the details you want to correct, then save the refreshed entry."
    }

    private var logPrimaryButtonTitle: String {
        editingLogID == nil ? "Save Log" : "Update Log"
    }

    private var logFootnoteText: String {
        editingLogID == nil
            ? "Your sleep log stays on this device and updates the Overview dashboard."
            : "Updating this entry will refresh your dashboard insights and AI summary."
    }

    private var shouldShowOpenSettingsButton: Bool {
        notificationPermissionDenied && !notificationsEnabled
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(url)
    }

    private func startEditing(_ log: SleepLog) {
        editingLogID = log.id
        selectedDate = log.date
        selectedSleepHours = log.sleepHours
        selectedBedtime = log.bedtime
        selectedWakeTime = log.wakeTime
        selectedNotes = log.notes
        selectedFeeling = log.feeling
        selectedActivities = Set(log.activities)
        customActivityInput = ""
        selectedActivityLevel = log.activityLevel
        selectedLateNightEating = log.lateNightEating
        selectedWaterIntakeGlasses = log.waterIntakeGlasses
        selectedCoffeeIntakeCups = log.coffeeIntakeCups
        selectedAlcoholIntakeDrinks = log.alcoholIntakeDrinks
        selectedDifficulty = log.difficultyFallingAsleep
        selectedWakeUps = log.nighttimeWakeUps
        selectedEnergy = log.morningEnergy
        selectedTab = .log
    }

    private func loadSampleData() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let samples: [SleepLog] = [
            sampleLog(daysAgo: 6, hours: 6.0, bedtimeHour: 0, bedtimeMinute: 10, wakeHour: 6, wakeMinute: 35, feeling: "Tired", activities: ["Work", "Screen Time"], activityLevel: 2, lateNightEating: true, water: 4, coffee: 3, alcohol: 1, difficulty: 4, wakeUps: 3, energy: 2, notes: "Fell asleep later than planned after scrolling."),
            sampleLog(daysAgo: 5, hours: 6.5, bedtimeHour: 23, bedtimeMinute: 40, wakeHour: 6, wakeMinute: 50, feeling: "Anxious", activities: ["Work", "Study"], activityLevel: 3, lateNightEating: false, water: 5, coffee: 2, alcohol: 0, difficulty: 4, wakeUps: 2, energy: 2, notes: "Busy day and mind still racing at bedtime."),
            sampleLog(daysAgo: 4, hours: 7.0, bedtimeHour: 23, bedtimeMinute: 5, wakeHour: 7, wakeMinute: 0, feeling: "Calm", activities: ["Walking", "Work"], activityLevel: 3, lateNightEating: false, water: 6, coffee: 1, alcohol: 0, difficulty: 3, wakeUps: 2, energy: 3, notes: "Better wind-down routine."),
            sampleLog(daysAgo: 3, hours: 7.5, bedtimeHour: 22, bedtimeMinute: 55, wakeHour: 7, wakeMinute: 10, feeling: "Energetic", activities: ["Workout", "Work"], activityLevel: 4, lateNightEating: false, water: 7, coffee: 1, alcohol: 0, difficulty: 2, wakeUps: 1, energy: 4, notes: "Workout seemed to help."),
            sampleLog(daysAgo: 2, hours: 6.0, bedtimeHour: 0, bedtimeMinute: 20, wakeHour: 6, wakeMinute: 30, feeling: "Tired", activities: ["Social", "Screen Time"], activityLevel: 2, lateNightEating: true, water: 4, coffee: 2, alcohol: 2, difficulty: 4, wakeUps: 3, energy: 2, notes: "Late dinner and social plans pushed bedtime back."),
            sampleLog(daysAgo: 1, hours: 7.2, bedtimeHour: 23, bedtimeMinute: 15, wakeHour: 7, wakeMinute: 5, feeling: "Calm", activities: ["Walking", "Work"], activityLevel: 3, lateNightEating: false, water: 6, coffee: 1, alcohol: 0, difficulty: 2, wakeUps: 1, energy: 4, notes: "More settled night overall."),
            sampleLog(daysAgo: 0, hours: 7.8, bedtimeHour: 22, bedtimeMinute: 50, wakeHour: 7, wakeMinute: 20, feeling: "Energetic", activities: ["Workout", "Reading"], activityLevel: 4, lateNightEating: false, water: 7, coffee: 1, alcohol: 0, difficulty: 2, wakeUps: 1, energy: 4, notes: "Strongest night of the week.")
        ]

        sleepLogs = samples.sorted { $0.date > $1.date }
        persistLogs()
        invalidateAISummary()
        resetLogForm()
        selectedDate = today
        selectedTab = .overview
    }

    private func sampleLog(
        daysAgo: Int,
        hours: Double,
        bedtimeHour: Int,
        bedtimeMinute: Int,
        wakeHour: Int,
        wakeMinute: Int,
        feeling: String,
        activities: [String],
        activityLevel: Int,
        lateNightEating: Bool,
        water: Int,
        coffee: Int,
        alcohol: Int,
        difficulty: Int,
        wakeUps: Int,
        energy: Int,
        notes: String
    ) -> SleepLog {
        let calendar = Calendar.current
        let day = calendar.date(byAdding: .day, value: -daysAgo, to: calendar.startOfDay(for: Date())) ?? Date()
        let bedtime = calendar.date(bySettingHour: bedtimeHour, minute: bedtimeMinute, second: 0, of: day) ?? day
        let wakeTime = calendar.date(bySettingHour: wakeHour, minute: wakeMinute, second: 0, of: day) ?? day

        return SleepLog(
            date: day,
            sleepHours: hours,
            bedtime: bedtime,
            wakeTime: wakeTime,
            notes: notes,
            feeling: feeling,
            activities: activities,
            activityLevel: activityLevel,
            lateNightEating: lateNightEating,
            waterIntakeGlasses: water,
            coffeeIntakeCups: coffee,
            alcoholIntakeDrinks: alcohol,
            difficultyFallingAsleep: difficulty,
            nighttimeWakeUps: wakeUps,
            morningEnergy: energy
        )
    }

    private func jumpToLogTab() {
        selectedTab = .log
    }

    private var appBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.04, blue: 0.16),
                    Color(red: 0.07, green: 0.10, blue: 0.30),
                    Color(red: 0.16, green: 0.12, blue: 0.39)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(moonGlow.opacity(0.20))
                .frame(width: 280, height: 280)
                .blur(radius: 24)
                .offset(x: animateBackground ? -150 : -90, y: animateBackground ? -220 : -160)

            Circle()
                .fill(dawnLavender.opacity(0.36))
                .frame(width: 300, height: 300)
                .blur(radius: 22)
                .offset(x: animateBackground ? 180 : 120, y: animateBackground ? 180 : 110)

            Circle()
                .fill(twilightBlue.opacity(0.42))
                .frame(width: 240, height: 240)
                .blur(radius: 18)
                .offset(x: animateBackground ? 40 : -20, y: animateBackground ? -20 : 40)
        }
        .animation(.easeInOut(duration: 8).repeatForever(autoreverses: true), value: animateBackground)
        .ignoresSafeArea()
    }

    private var overviewBackground: some View {
        ZStack {
            appBackground

            GeometryReader { geometry in
                ZStack {
                    Circle()
                        .fill(dawnLavender.opacity(0.12))
                        .frame(width: 190, height: 190)
                        .blur(radius: 22)
                        .offset(
                            x: animateBackground ? geometry.size.width * 0.28 : geometry.size.width * 0.18,
                            y: animateBackground ? -geometry.size.height * 0.12 : -geometry.size.height * 0.05
                        )

                    Circle()
                        .fill(moonGlow.opacity(0.08))
                        .frame(width: 140, height: 140)
                        .blur(radius: 18)
                        .offset(
                            x: animateBackground ? -geometry.size.width * 0.22 : -geometry.size.width * 0.12,
                            y: animateBackground ? geometry.size.height * 0.18 : geometry.size.height * 0.10
                        )

                    overviewStar(
                        systemName: "sparkle",
                        size: 14,
                        opacity: 0.75,
                        x: geometry.size.width * 0.18,
                        y: geometry.size.height * 0.12,
                        animatedX: geometry.size.width * 0.22,
                        animatedY: geometry.size.height * 0.09
                    )

                    overviewStar(
                        systemName: "moon.stars.fill",
                        size: 18,
                        opacity: 0.34,
                        x: geometry.size.width * 0.82,
                        y: geometry.size.height * 0.18,
                        animatedX: geometry.size.width * 0.76,
                        animatedY: geometry.size.height * 0.14
                    )

                    overviewStar(
                        systemName: "sparkles",
                        size: 15,
                        opacity: 0.42,
                        x: geometry.size.width * 0.74,
                        y: geometry.size.height * 0.58,
                        animatedX: geometry.size.width * 0.78,
                        animatedY: geometry.size.height * 0.54
                    )

                    overviewStar(
                        systemName: "sparkle",
                        size: 12,
                        opacity: 0.54,
                        x: geometry.size.width * 0.26,
                        y: geometry.size.height * 0.74,
                        animatedX: geometry.size.width * 0.20,
                        animatedY: geometry.size.height * 0.70
                    )

                    overviewStar(
                        systemName: "star.fill",
                        size: 10,
                        opacity: 0.28,
                        x: geometry.size.width * 0.88,
                        y: geometry.size.height * 0.84,
                        animatedX: geometry.size.width * 0.83,
                        animatedY: geometry.size.height * 0.79
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .allowsHitTesting(false)
        }
    }

    private func overviewStar(
        systemName: String,
        size: CGFloat,
        opacity: Double,
        x: CGFloat,
        y: CGFloat,
        animatedX: CGFloat,
        animatedY: CGFloat
    ) -> some View {
        Image(systemName: systemName)
            .font(.system(size: size, weight: .semibold))
            .foregroundStyle(moonGlow.opacity(opacity))
            .shadow(color: moonGlow.opacity(0.18), radius: 10, x: 0, y: 0)
            .position(
                x: animateBackground ? animatedX : x,
                y: animateBackground ? animatedY : y
            )
            .opacity(animateTrendIcon ? opacity : opacity * 0.55)
            .scaleEffect(animateTrendIcon ? 1.04 : 0.92)
            .animation(.easeInOut(duration: 9).repeatForever(autoreverses: true), value: animateBackground)
            .animation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true), value: animateTrendIcon)
    }

    private var overviewHeroCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your sleep snapshot")
                        .font(.headline)
                        .foregroundStyle(starlight.opacity(0.95))

                    Text(heroTitle)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(heroSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(starlight.opacity(0.78))
                }

                Spacer()

                ZStack {
                    Circle()
                        .fill(moonGlow.opacity(0.14))
                        .frame(width: 56, height: 56)

                    Image(systemName: heroSymbolName)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(moonGlow)
                        .symbolEffect(.pulse.byLayer, isActive: animateTrendIcon)
                }
            }

            HStack(spacing: 12) {
                overviewPill(title: "7-day avg", value: weeklyLogs.isEmpty ? "--" : "\(formattedOneDecimal(averageSleepHours))h")
                overviewPill(title: "Score", value: weeklyLogs.isEmpty ? "--" : "\(formattedOneDecimal(sevenDayAverage)) / 5")
                overviewPill(title: "Logs", value: "\(weeklyLogs.count)")
            }

            VStack(alignment: .leading, spacing: 8) {
                Button {
                    jumpToLogTab()
                } label: {
                    HStack {
                        Label(weeklyLogs.isEmpty ? "Add Your First Sleep Log" : "Add Sleep Log", systemImage: "square.and.pencil")
                            .font(.headline)
                        Spacer()
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title3)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .background(.white.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                Text("Overview shows your trends and insights. Use the Log tab to add a new sleep entry.")
                    .font(.caption)
                    .foregroundStyle(starlight.opacity(0.72))
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [twilightBlue.opacity(0.75), dawnLavender.opacity(0.45)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(starlight.opacity(0.14), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 18, x: 0, y: 10)
    }

    private var overviewMetricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            metricTile(
                title: "Average Sleep",
                value: weeklyLogs.isEmpty ? "--" : "\(formattedOneDecimal(averageSleepHours))h",
                detail: sleepGoalMessage,
                symbol: "moon.zzz.fill",
                accent: moonGlow
            )

            metricTile(
                title: "Consistency",
                value: weeklyLogs.isEmpty ? "--" : "\(formattedOneDecimal(sleepConsistencyRange))h",
                detail: weeklyLogs.isEmpty ? "Track a few nights to measure your range." : consistencyMessage,
                symbol: "waveform.path",
                accent: starlight
            )

            metricTile(
                title: "Morning Energy",
                value: weeklyLogs.isEmpty ? "--" : "\(formattedOneDecimal(averageMorningEnergy)) / 5",
                detail: weeklyLogs.isEmpty ? "Morning energy will appear here." : energySummary,
                symbol: "sun.max.fill",
                accent: dawnLavender
            )

            metricTile(
                title: "Wake-Ups",
                value: weeklyLogs.isEmpty ? "--" : "\(formattedOneDecimal(averageNighttimeWakeUps)) / night",
                detail: weeklyLogs.isEmpty ? "Wake-up trends will appear here." : wakeUpSummary,
                symbol: "bell.and.waves.left.and.right.fill",
                accent: moonGlow
            )
        }
    }

    private var sleepHistoryChartCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sleep History")
                        .font(.headline)
                    Text("A line chart makes it easier to spot sleep trends across nights.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("Goal: 7-9h")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(moonGlow.opacity(0.14))
                    .clipShape(Capsule())
            }

            if weeklyLogs.isEmpty {
                emptyOverviewState(
                    title: "No sleep history yet",
                    message: "Once you add logs, your nightly sleep trend will appear here."
                )
            } else {
                Chart {
                    RuleMark(y: .value("Lower Goal", 7))
                        .foregroundStyle(moonGlow.opacity(0.45))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))

                    RuleMark(y: .value("Upper Goal", 9))
                        .foregroundStyle(moonGlow.opacity(0.25))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))

                    ForEach(weeklyLogs) { log in
                        AreaMark(
                            x: .value("Day", log.date, unit: .day),
                            y: .value("Sleep Hours", log.sleepHours)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(
                            .linearGradient(
                                colors: [dawnLavender.opacity(0.55), twilightBlue.opacity(0.12)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                        LineMark(
                            x: .value("Day", log.date, unit: .day),
                            y: .value("Sleep Hours", log.sleepHours)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(starlight)
                        .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))

                        PointMark(
                            x: .value("Day", log.date, unit: .day),
                            y: .value("Sleep Hours", log.sleepHours)
                        )
                        .foregroundStyle(log.sleepHours >= 7 ? moonGlow : dawnLavender)
                        .symbolSize(70)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisGridLine().foregroundStyle(.white.opacity(0.08))
                        AxisValueLabel(format: .dateTime.weekday(.abbreviated), centered: true)
                            .foregroundStyle(.secondary)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: [0, 4, 7, 9, 12]) { value in
                        AxisGridLine().foregroundStyle(.white.opacity(0.08))
                        AxisValueLabel().foregroundStyle(.secondary)
                    }
                }
                .chartYScale(domain: 0...max(12, highestSleepHours + 1))
                .frame(height: 220)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }

    private func overviewPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(starlight.opacity(0.65))

            Text(value)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func metricTile(title: String, value: String, detail: String, symbol: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: symbol)
                    .foregroundStyle(accent)
                Spacer()
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Text(value)
                .font(.title3.weight(.bold))

            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
    }

    private func emptyOverviewState(title: String, message: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 18)
    }

    private var logFormCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            compactHeaderCard(
                title: logHeaderTitle,
                subtitle: logHeaderSubtitle,
                symbol: "square.and.pencil.circle.fill"
            )

            sectionCard(
                title: "Sleep basics",
                subtitle: "Capture the day, hours, and how you felt in one quick pass."
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "calendar")
                            .foregroundStyle(moonGlow)
                            .frame(width: 40, height: 40)
                            .background(dawnLavender.opacity(0.16))
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Selected date")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(selectedDate.formatted(date: .complete, time: .omitted))
                                .font(.subheadline.weight(.semibold))
                        }

                        Spacer()

                        DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                            .labelsHidden()
                            .datePickerStyle(.compact)
                            .blendMode(.plusLighter)
                    }
                    .padding(14)
                    .background(.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    HStack {
                        Text("Hours slept")
                            .foregroundStyle(.secondary)
                        Text("\(selectedSleepHours, specifier: "%.1f")h")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.white)
                    }

                    Slider(value: $selectedSleepHours, in: 0...14, step: 0.5)

                    Text("Recommended range: 7-9 hours")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("How do you feel today?")
                            .font(.subheadline.weight(.semibold))
                        Picker("How do you feel?", selection: $selectedFeeling) {
                            Text("Tired").tag("Tired")
                            Text("Anxious").tag("Anxious")
                            Text("Energetic").tag("Energetic")
                            Text("Calm").tag("Calm")
                        }
                        .pickerStyle(.segmented)
                    }
                }
            }

            sectionCard(
                title: "What was your sleep window?",
                subtitle: "Capture when you went to bed and when you woke up."
            ) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                    reminderSettingCard(
                        title: "Bedtime",
                        subtitle: "When you tried to sleep."
                    ) {
                        DatePicker("Bedtime", selection: $selectedBedtime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }

                    reminderSettingCard(
                        title: "Wake time",
                        subtitle: "When you got up for the day."
                    ) {
                        DatePicker("Wake Time", selection: $selectedWakeTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }
                }
            }

            sectionCard(
                title: "How was your sleep quality?",
                subtitle: "Use the sliders to rate the night."
            ) {
                VStack(alignment: .leading, spacing: 10) {
                    metricRow(
                        title: "Difficulty Falling Asleep",
                        value: selectedDifficulty,
                        valueDescription: difficultyText(for: selectedDifficulty)
                    )

                    metricRow(
                        title: "Nighttime Wake-Ups",
                        value: selectedWakeUps,
                        valueDescription: wakeUpText(for: selectedWakeUps)
                    )

                    metricRow(
                        title: "Morning Energy",
                        value: selectedEnergy,
                        valueDescription: energyText(for: selectedEnergy)
                    )
                }
            }

            sectionCard(
                title: "Optional details",
                subtitle: "Open this only when you want to add extra context."
            ) {
                DisclosureGroup("Show routines, habits, and notes") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Activities")
                            .font(.subheadline.weight(.semibold))

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 8)], spacing: 8) {
                            ForEach(commonActivities, id: \.self) { activity in
                                Button {
                                    toggleActivity(activity)
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: selectedActivities.contains(activity) ? "checkmark.circle.fill" : "circle")
                                            .font(.caption.weight(.semibold))
                                        Text(activity)
                                            .font(.caption.weight(.medium))
                                        Spacer(minLength: 0)
                                    }
                                    .foregroundStyle(selectedActivities.contains(activity) ? .white : starlight.opacity(0.9))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(
                                        selectedActivities.contains(activity)
                                            ? dawnLavender.opacity(0.28)
                                            : Color.white.opacity(0.05)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        HStack {
                            TextField("Add custom activity", text: $customActivityInput)
                            Button("Add") {
                                addCustomActivity()
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(12)
                        .background(.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                        if !selectedActivities.isEmpty {
                            selectedActivitiesWrap
                        }

                        habitStepperCard(
                            title: "Activity level",
                            value: "\(selectedActivityLevel)/5",
                            subtitle: "How active were you during the day?"
                        ) {
                            Slider(value: Binding(
                                get: { Double(selectedActivityLevel) },
                                set: { selectedActivityLevel = Int($0.rounded()) }
                            ), in: 1...5, step: 1)
                        }

                        Toggle(isOn: $selectedLateNightEating) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Late-night eating")
                                Text("Helpful if meals or snacks affected your sleep.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(14)
                        .background(.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                        habitStepperCard(
                            title: "Water intake",
                            value: "\(selectedWaterIntakeGlasses) glasses",
                            subtitle: "Approximate total for the day."
                        ) {
                            Stepper("", value: $selectedWaterIntakeGlasses, in: 0...16)
                                .labelsHidden()
                        }

                        habitStepperCard(
                            title: "Coffee intake",
                            value: "\(selectedCoffeeIntakeCups) cup\(selectedCoffeeIntakeCups == 1 ? "" : "s")",
                            subtitle: "Include coffee or strong caffeine drinks."
                        ) {
                            Stepper("", value: $selectedCoffeeIntakeCups, in: 0...10)
                                .labelsHidden()
                        }

                        habitStepperCard(
                            title: "Alcohol intake",
                            value: "\(selectedAlcoholIntakeDrinks) drink\(selectedAlcoholIntakeDrinks == 1 ? "" : "s")",
                            subtitle: "Helpful if drinks may have affected your sleep."
                        ) {
                            Stepper("", value: $selectedAlcoholIntakeDrinks, in: 0...10)
                                .labelsHidden()
                        }

                        TextEditor(text: $selectedNotes)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 110)
                            .padding(12)
                            .background(.white.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                        Text("Notes help future insights feel more personal.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 12)
                }
                .tint(moonGlow)
            }

        }
    }

    private var logActionBar: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                if editingLogID != nil {
                    Button("Cancel") {
                        resetLogForm()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }

                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        saveLog()
                    }
                } label: {
                    HStack {
                        Spacer()
                        Label(logPrimaryButtonTitle, systemImage: editingLogID == nil ? "checkmark.circle.fill" : "square.and.arrow.down.fill")
                            .font(.headline)
                        Spacer()
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }

            Text(logFootnoteText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(.white.opacity(0.08))
                .frame(height: 1)
        }
    }

    @ViewBuilder
    private func metricRow(title: String, value: Int, valueDescription: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                Spacer()
                Text("\(value)/5")
                    .fontWeight(.semibold)
            }

            Slider(
                value: Binding(
                    get: { Double(value) },
                    set: { newValue in
                        let rounded = Int(newValue.rounded())
                        if title == "Difficulty Falling Asleep" {
                            selectedDifficulty = rounded
                        } else if title == "Nighttime Wake-Ups" {
                            selectedWakeUps = rounded
                        } else {
                            selectedEnergy = rounded
                        }
                    }
                ),
                in: 1...5,
                step: 1
            )

            Text(valueDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func difficultyText(for value: Int) -> String {
        switch value {
        case 1...2: return "Low difficulty"
        case 3: return "Moderate difficulty"
        default: return "High difficulty"
        }
    }

    private func wakeUpText(for value: Int) -> String {
        switch value {
        case 1...2: return "Few wake-ups"
        case 3: return "Some wake-ups"
        default: return "Frequent wake-ups"
        }
    }

    private func energyText(for value: Int) -> String {
        switch value {
        case 1...2: return "Low morning energy"
        case 3: return "Moderate morning energy"
        default: return "High morning energy"
        }
    }

    private func toggleActivity(_ activity: String) {
        if selectedActivities.contains(activity) {
            selectedActivities.remove(activity)
        } else {
            selectedActivities.insert(activity)
        }
    }

    private func addCustomActivity() {
        let trimmed = customActivityInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        selectedActivities.insert(trimmed)
        customActivityInput = ""
    }

    private var historyListCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            compactHeaderCard(
                title: "Sleep Journal",
                subtitle: "Browse saved nights, edit mistakes, and remove entries you no longer want to keep.",
                symbol: "book.closed.circle.fill"
            )

            if sleepLogs.isEmpty {
                emptyOverviewState(
                    title: "No logs yet",
                    message: "Your saved sleep entries will show up here after you add your first check-in."
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(sleepLogs) { log in
                        historyLogCard(log)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }

    private var selectedActivitiesWrap: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Selected activities")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                ForEach(selectedActivities.sorted(), id: \.self) { activity in
                    Text(activity)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(dawnLavender.opacity(0.18))
                        .clipShape(Capsule())
                }
            }
        }
    }

    private var notificationSettingsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            compactHeaderCard(
                title: "Preferences",
                subtitle: "Set reminders and keep support details close by.",
                symbol: "gearshape.2.fill"
            )

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Reminders")
                        .font(.headline)
                    Text("Set your evening check-in and morning reflection times.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(notificationsEnabled ? "Enabled" : "Off")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(notificationsEnabled ? moonGlow : .secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background((notificationsEnabled ? moonGlow : Color.white).opacity(0.10))
                    .clipShape(Capsule())
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                reminderSettingCard(
                    title: "Evening reminder",
                    subtitle: "Best for logging your habits before bed."
                ) {
                    DatePicker(
                        "Evening Reminder",
                        selection: Binding(
                            get: { dateFrom(hour: reminderHour, minute: reminderMinute) },
                            set: { updateReminder(from: $0, evening: true) }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()
                }

                reminderSettingCard(
                    title: "Morning reminder",
                    subtitle: "Best for checking energy and wake-ups."
                ) {
                    DatePicker(
                        "Morning Reminder",
                        selection: Binding(
                            get: { dateFrom(hour: morningReminderHour, minute: morningReminderMinute) },
                            set: { updateReminder(from: $0, evening: false) }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()
                }
            }

            if !statusMessage.isEmpty {
                Text(statusMessage)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            if shouldShowOpenSettingsButton {
                Button("Open Settings") {
                    openSystemSettings()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }

            Button(notificationsEnabled ? "Update Notifications" : "Enable Notifications") {
                configureNotifications()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
    }

    private var recommendationsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Apple Intelligence Sleep Coach")
                        .font(.headline)
                    Text("Private, on-device coaching from your recent sleep patterns.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Label("On-device AI", systemImage: "apple.intelligence")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(moonGlow)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(dawnLavender.opacity(0.16))
                    .clipShape(Capsule())
            }

            if aiCoachSummary.isEmpty {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: recommendationSymbolName)
                        .foregroundStyle(moonGlow)
                        .font(.title3)
                        .frame(width: 40, height: 40)
                        .background(dawnLavender.opacity(0.16))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 6) {
                        Text(recommendationTitle)
                            .font(.title3.weight(.bold))

                        Text(recommendationMessage)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.92))
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text(aiCoachHeadline.isEmpty ? "Weekly AI Summary" : aiCoachHeadline)
                        .font(.title3.weight(.bold))

                    Text(aiCoachSummary)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.92))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                .background(.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            if !aiCoachSupportMessage.isEmpty {
                Text(aiCoachSupportMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if !aiCoachStatusMessage.isEmpty {
                Text(aiCoachStatusMessage)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(moonGlow)
            }

            Button {
                generateAISummary()
            } label: {
                HStack {
                    if isGeneratingAISummary {
                        ProgressView()
                            .tint(.white)
                    }

                    Text(aiCoachButtonTitle)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(dawnLavender)
            .disabled(isGeneratingAISummary || weeklyLogs.count < 3)
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
    }

    private var aboutLegalCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            DisclosureGroup("About, privacy, and legal") {
                VStack(alignment: .leading, spacing: 12) {
                    settingsInfoCard(
                        title: "Privacy",
                        symbol: "hand.raised",
                        description: "Your information is stored only on your device. This app does not upload your sleep data to external servers."
                    )

                    settingsInfoCard(
                        title: "Legal",
                        symbol: "doc.text",
                        description: "This app is an informational wellness tool and is not a substitute for professional healthcare advice or diagnosis."
                    )

                    settingsInfoCard(
                        title: "Disclaimer",
                        symbol: "info.circle",
                        description: "This app is for tracking purposes only. It is not intended to diagnose, treat, or provide medical advice."
                    )

                    settingsInfoCard(
                        title: "Apple Intelligence",
                        symbol: "apple.intelligence",
                        description: "AI sleep summaries are generated on device when Apple Intelligence is available. Your logs stay on your device."
                    )
                }
                .padding(.top, 12)
            }
            .tint(moonGlow)
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var supportCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "envelope.fill")
                    .foregroundStyle(moonGlow)
                    .frame(width: 36, height: 36)
                    .background(dawnLavender.opacity(0.18))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text("Support & Feedback")
                        .font(.headline)
                    Text("Questions, bugs, or ideas? Reach out anytime.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            if let supportEmailURL {
                Link(destination: supportEmailURL) {
                    HStack {
                        Text("support.chaniiapps@gmail.com")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                    }
                    .font(.subheadline.weight(.semibold))
                    .padding(14)
                    .background(.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func sectionCard<Content: View>(title: String, subtitle: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            content()
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
    }

    private func compactHeaderCard(title: String, subtitle: String, symbol: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(moonGlow)
                .frame(width: 40, height: 40)
                .background(dawnLavender.opacity(0.16))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
    }

    private func habitStepperCard<Content: View>(title: String, value: String, subtitle: String, @ViewBuilder control: () -> Content) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)

            control()
        }
        .padding(14)
        .background(.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func reminderSettingCard<Content: View>(title: String, subtitle: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, minHeight: 134, alignment: .topLeading)
        .padding()
        .background(.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func settingsInfoCard(title: String, symbol: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(moonGlow)
                .frame(width: 36, height: 36)
                .background(dawnLavender.opacity(0.18))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var supportEmailURL: URL? {
        URL(string: "mailto:support.chaniiapps@gmail.com")
    }

    private func reminderTimeLabel(hour: Int, minute: Int) -> String {
        dateFrom(hour: hour, minute: minute).formatted(date: .omitted, time: .shortened)
    }

    @ViewBuilder
    private func historyLogCard(_ log: SleepLog) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(log.date.formatted(date: .complete, time: .omitted))
                        .font(.headline)
                    Text("\(formattedOneDecimal(log.sleepHours)) hours slept")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 8) {
                    Button {
                        startEditing(log)
                    } label: {
                        Image(systemName: "pencil")
                            .font(.subheadline.weight(.semibold))
                            .padding(10)
                            .background(.white.opacity(0.05))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)

                    Button(role: .destructive) {
                        deleteLog(log)
                    } label: {
                        Image(systemName: "trash")
                            .font(.subheadline.weight(.semibold))
                            .padding(10)
                            .background(.white.opacity(0.05))
                            .clipShape(Circle())
                    }
                }
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 10)], spacing: 10) {
                historyValuePill(title: "Bedtime", value: log.bedtime.formatted(date: .omitted, time: .shortened))
                historyValuePill(title: "Wake", value: log.wakeTime.formatted(date: .omitted, time: .shortened))
                historyValuePill(title: "Feeling", value: log.feeling)
                historyValuePill(title: "Alcohol", value: "\(log.alcoholIntakeDrinks) drink\(log.alcoholIntakeDrinks == 1 ? "" : "s")")
                historyValuePill(title: "Score", value: "\(formattedOneDecimal(log.insomniaScore)) / 5")
            }

            if !log.activities.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Activities")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                        ForEach(log.activities, id: \.self) { activity in
                            Text(activity)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(dawnLavender.opacity(0.16))
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            if !log.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Notes")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(log.notes)
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.9))
                }
                .padding(12)
                .background(.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .padding()
        .background(.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func historyValuePill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(starlight.opacity(0.65))
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var weeklyLogs: [SleepLog] {
        Array(sleepLogs.prefix(7).reversed())
    }

    private var averageSleepHours: Double {
        guard !weeklyLogs.isEmpty else { return 0 }
        let sum = weeklyLogs.reduce(0) { $0 + $1.sleepHours }
        return sum / Double(weeklyLogs.count)
    }

    private var averageMorningEnergy: Double {
        guard !weeklyLogs.isEmpty else { return 0 }
        let sum = weeklyLogs.reduce(0) { $0 + Double($1.morningEnergy) }
        return sum / Double(weeklyLogs.count)
    }

    private var averageNighttimeWakeUps: Double {
        guard !weeklyLogs.isEmpty else { return 0 }
        let sum = weeklyLogs.reduce(0) { $0 + Double($1.nighttimeWakeUps) }
        return sum / Double(weeklyLogs.count)
    }

    private var averageCoffeeIntake: Double {
        guard !weeklyLogs.isEmpty else { return 0 }
        let sum = weeklyLogs.reduce(0) { $0 + Double($1.coffeeIntakeCups) }
        return sum / Double(weeklyLogs.count)
    }

    private var lateNightEatingCount: Int {
        weeklyLogs.filter(\.lateNightEating).count
    }

    private var highestSleepHours: Double {
        weeklyLogs.map(\.sleepHours).max() ?? 0
    }

    private var mostCommonFeeling: String {
        let counts = Dictionary(grouping: weeklyLogs, by: \.feeling).mapValues(\.count)
        return counts.max(by: { $0.value < $1.value })?.key ?? "No data"
    }

    private var sleepConsistencyRange: Double {
        let hours = weeklyLogs.map(\.sleepHours)
        guard let min = hours.min(), let max = hours.max() else { return 0 }
        return max - min
    }

    private var bedtimeConsistencyRangeHours: Double {
        let bedtimes = weeklyLogs.map(\.bedtime)
        guard let min = bedtimes.min(by: { bedtimeMinutes($0) < bedtimeMinutes($1) }),
              let max = bedtimes.max(by: { bedtimeMinutes($0) < bedtimeMinutes($1) }) else {
            return 0
        }
        return Double(bedtimeMinutes(max) - bedtimeMinutes(min)) / 60.0
    }

    private var consistencyMessage: String {
        switch sleepConsistencyRange {
        case ..<1:
            return "Your sleep timing looks steady across the week."
        case ..<2.5:
            return "A little variation is showing up, but it is still manageable."
        default:
            return "Your nights are swinging a lot. A steadier routine may help."
        }
    }

    private var energySummary: String {
        switch averageMorningEnergy {
        case ..<2:
            return "Mornings have been feeling low energy."
        case ..<3.5:
            return "Energy is moderate most mornings."
        default:
            return "You are waking up with stronger energy lately."
        }
    }

    private var wakeUpSummary: String {
        switch averageNighttimeWakeUps {
        case ..<1.5:
            return "You are usually staying asleep through the night."
        case ..<3:
            return "Some interruptions are showing up overnight."
        default:
            return "Frequent wake-ups may be disrupting your sleep quality."
        }
    }

    private var sleepGoalMessage: String {
        if weeklyLogs.isEmpty {
            return "Track at least a few nights to get personalized insights."
        }
        if averageSleepHours < 7 {
            return "Try targeting 7-9 hours. Your weekly average is below the recommended range."
        }
        if averageSleepHours > 9 {
            return "Your weekly average is above 9 hours. Monitor daytime fatigue and sleep quality."
        }
        return "Great job. Your average sleep is inside the recommended 7-9 hour range."
    }

    private var habitChangePrediction: String {
        guard sleepLogs.count >= 6 else {
            return "Need at least 6 logs to predict if habit changes impacted sleep."
        }

        let sorted = sleepLogs.sorted { $0.date > $1.date }
        let recent = Array(sorted.prefix(3))
        let previous = Array(sorted.dropFirst(3).prefix(3))

        let recentSleep = recent.map(\.sleepHours).reduce(0, +) / Double(recent.count)
        let previousSleep = previous.map(\.sleepHours).reduce(0, +) / Double(previous.count)
        let recentInsomnia = recent.map(\.insomniaScore).reduce(0, +) / Double(recent.count)
        let previousInsomnia = previous.map(\.insomniaScore).reduce(0, +) / Double(previous.count)

        let sleepDrop = previousSleep - recentSleep
        let insomniaRise = recentInsomnia - previousInsomnia

        guard sleepDrop >= 0.5 || insomniaRise >= 0.4 else {
            return "No clear habit-related decline detected in recent logs."
        }

        let activityDrop = (previous.map { Double($0.activityLevel) }.reduce(0, +) / 3.0) - (recent.map { Double($0.activityLevel) }.reduce(0, +) / 3.0)
        let waterDrop = (previous.map { Double($0.waterIntakeGlasses) }.reduce(0, +) / 3.0) - (recent.map { Double($0.waterIntakeGlasses) }.reduce(0, +) / 3.0)
        let coffeeIncrease = (recent.map { Double($0.coffeeIntakeCups) }.reduce(0, +) / 3.0) - (previous.map { Double($0.coffeeIntakeCups) }.reduce(0, +) / 3.0)
        let lateNightIncrease = (recent.filter(\.lateNightEating).count - previous.filter(\.lateNightEating).count)

        let candidates: [(String, Double)] = [
            ("Lower activity level", max(0, activityDrop)),
            ("Less water intake", max(0, waterDrop / 2.0)),
            ("Higher coffee intake", max(0, coffeeIncrease)),
            ("More late-night eating", max(0, Double(lateNightIncrease)))
        ]

        guard let strongest = candidates.max(by: { $0.1 < $1.1 }), strongest.1 > 0 else {
            return "Sleep changed recently, but the app cannot identify a single strong habit shift yet."
        }

        return "Possible cause: \(strongest.0) in recent days compared with earlier logs."
    }

    private var recommendationTitle: String {
        if weeklyLogs.isEmpty {
            return "Build your first week of data"
        }
        if averageSleepHours < 7 {
            return "Aim for a longer sleep window"
        }
        if averageCoffeeIntake >= 2 {
            return "Try a lighter caffeine day"
        }
        if lateNightEatingCount >= 3 {
            return "Experiment with earlier evening meals"
        }
        if bedtimeConsistencyRangeHours > 1.5 {
            return "Keep bedtime more consistent"
        }
        if averageNighttimeWakeUps >= 3 {
            return "Reduce overnight interruptions"
        }
        return "Keep the routine going"
    }

    private var recommendationMessage: String {
        if weeklyLogs.isEmpty {
            return "Once you log a few nights, the app can start suggesting changes based on your own sleep patterns."
        }
        if averageSleepHours < 7 {
            return "Your recent average is \(formattedOneDecimal(averageSleepHours)) hours. Try protecting a 7-9 hour sleep window for the next few nights."
        }
        if averageCoffeeIntake >= 2 {
            return "Coffee is averaging \(formattedOneDecimal(averageCoffeeIntake)) cups. Try reducing late-day caffeine and watch whether your sleep score improves."
        }
        if lateNightEatingCount >= 3 {
            return "Late-night eating showed up \(lateNightEatingCount) times this week. Try finishing meals earlier and compare your wake-ups."
        }
        if bedtimeConsistencyRangeHours > 1.5 {
            return "Your bedtime has shifted by about \(formattedOneDecimal(bedtimeConsistencyRangeHours)) hours. A steadier bedtime often helps sleep quality feel more predictable."
        }
        if averageNighttimeWakeUps >= 3 {
            return "You are averaging \(formattedOneDecimal(averageNighttimeWakeUps)) wake-ups a night. Focus on a calmer wind-down and compare your next few entries."
        }
        return "Your recent routine looks fairly steady. Keep logging so the app can spot subtler changes over time."
    }

    private var recommendationSymbolName: String {
        if weeklyLogs.isEmpty {
            return "sparkles"
        }
        if averageSleepHours < 7 {
            return "bed.double.fill"
        }
        if averageCoffeeIntake >= 2 {
            return "cup.and.saucer.fill"
        }
        if lateNightEatingCount >= 3 {
            return "fork.knife"
        }
        if bedtimeConsistencyRangeHours > 1.5 {
            return "clock.badge"
        }
        if averageNighttimeWakeUps >= 3 {
            return "bell.badge.fill"
        }
        return "checkmark.seal.fill"
    }

    private var aiCoachButtonTitle: String {
        if isGeneratingAISummary {
            return "Generating Summary..."
        }
        return aiCoachSummary.isEmpty ? "Generate Weekly AI Summary" : "Refresh AI Summary"
    }

    private var aiCoachSupportMessage: String {
        if weeklyLogs.count < 3 {
            return "Log at least 3 nights to unlock a more useful AI summary."
        }

        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            switch SystemLanguageModel.default.availability {
            case .available:
                return "Apple Intelligence is available. Generate a short weekly recap and one gentle next step."
            case .unavailable(let reason):
                return aiAvailabilityMessage(for: reason)
            }
        }
        #endif

        return "Apple Intelligence is unavailable here, so the app is showing its built-in recommendation instead."
    }

    private var sevenDayAverage: Double {
        let recent = sleepLogs.prefix(7)
        guard !recent.isEmpty else { return 0 }
        let sum = recent.reduce(0) { $0 + $1.insomniaScore }
        return sum / Double(recent.count)
    }

    private var trendMessage: String {
        switch sevenDayAverage {
        case 0:
            return "Start logging to see your trend."
        case ..<2:
            return "Low insomnia trend"
        case ..<3.5:
            return "Moderate insomnia trend"
        default:
            return "High insomnia trend"
        }
    }

    private var heroTitle: String {
        if weeklyLogs.isEmpty {
            return "Start your first sleep log"
        }
        if averageSleepHours < 7 {
            return "You are running short on sleep"
        }
        if averageSleepHours > 9 {
            return "You are spending long hours asleep"
        }
        return "Your sleep is in a healthy range"
    }

    private var heroSubtitle: String {
        if weeklyLogs.isEmpty {
            return "This screen is for trends and insights. Start by adding a sleep log, then come back here to review your patterns."
        }
        return "\(trendMessage). \(sleepGoalMessage)"
    }

    private var heroSymbolName: String {
        if weeklyLogs.isEmpty {
            return "moon.stars"
        }
        if averageSleepHours < 7 || sevenDayAverage >= 3.5 {
            return "bed.double.circle"
        }
        return "sparkles"
    }

    private func formattedOneDecimal(_ value: Double) -> String {
        String(format: "%.1f", value)
    }

    private func weeklyAISnapshot() -> String {
        weeklyLogs.enumerated().map { index, log in
            let activities = log.activities.isEmpty ? "none" : log.activities.joined(separator: ", ")
            return """
            Night \(index + 1): \(shortDateString(log.date)); sleep \(formattedOneDecimal(log.sleepHours))h; bedtime \(shortTimeString(log.bedtime)); wake \(shortTimeString(log.wakeTime)); energy \(log.morningEnergy)/5; wake-ups \(log.nighttimeWakeUps); caffeine \(log.coffeeIntakeCups) cup(s); alcohol \(log.alcoholIntakeDrinks) drink(s); water \(log.waterIntakeGlasses) glass(es); late-night eating \(log.lateNightEating ? "yes" : "no"); activities \(activities); feeling \(log.feeling).
            """
        }
        .joined(separator: "\n")
    }

    private func saveLog() {
        let log = SleepLog(
            id: editingLogID ?? UUID(),
            date: selectedDate,
            sleepHours: selectedSleepHours,
            bedtime: combine(date: selectedDate, withTimeFrom: selectedBedtime),
            wakeTime: combine(date: selectedDate, withTimeFrom: selectedWakeTime),
            notes: selectedNotes.trimmingCharacters(in: .whitespacesAndNewlines),
            feeling: selectedFeeling,
            activities: selectedActivities.sorted(),
            activityLevel: selectedActivityLevel,
            lateNightEating: selectedLateNightEating,
            waterIntakeGlasses: selectedWaterIntakeGlasses,
            coffeeIntakeCups: selectedCoffeeIntakeCups,
            alcoholIntakeDrinks: selectedAlcoholIntakeDrinks,
            difficultyFallingAsleep: selectedDifficulty,
            nighttimeWakeUps: selectedWakeUps,
            morningEnergy: selectedEnergy
        )

        if let editingLogID,
           let index = sleepLogs.firstIndex(where: { $0.id == editingLogID }) {
            sleepLogs[index] = log
        } else {
            sleepLogs.insert(log, at: 0)
        }

        sleepLogs.sort { $0.date > $1.date }
        persistLogs()
        invalidateAISummary()
        resetLogForm()
        selectedTab = .history
    }

    private func loadLogs() {
        guard let data = sleepLogsData.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([SleepLog].self, from: data) else {
            sleepLogs = []
            return
        }
        sleepLogs = decoded.sorted { $0.date > $1.date }
    }

    private func persistLogs() {
        guard let data = try? JSONEncoder().encode(sleepLogs),
              let dataString = String(data: data, encoding: .utf8) else {
            return
        }
        sleepLogsData = dataString
    }

    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationsEnabled = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
                notificationPermissionDenied = settings.authorizationStatus == .denied
            }
        }
    }

    private func configureNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.2)) {
                    notificationsEnabled = granted
                    notificationPermissionDenied = !granted
                    if granted {
                        scheduleDailyNotifications()
                        statusMessage = "Notifications scheduled"
                    } else {
                        statusMessage = "Permission not granted. You can enable notifications in Settings."
                    }
                }
            }
        }
    }

    private func scheduleDailyNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["eveningCheckIn", "morningCheckIn"])

        let evening = UNMutableNotificationContent()
        evening.title = "Sleep Check-In"
        evening.body = "Log your sleep indicators for tonight."
        evening.sound = .default

        var eveningComponents = DateComponents()
        eveningComponents.hour = reminderHour
        eveningComponents.minute = reminderMinute

        let eveningTrigger = UNCalendarNotificationTrigger(dateMatching: eveningComponents, repeats: true)
        let eveningRequest = UNNotificationRequest(identifier: "eveningCheckIn", content: evening, trigger: eveningTrigger)

        let morning = UNMutableNotificationContent()
        morning.title = "Morning Sleep Reflection"
        morning.body = "How was your sleep? Log your morning energy and wake-ups."
        morning.sound = .default

        var morningComponents = DateComponents()
        morningComponents.hour = morningReminderHour
        morningComponents.minute = morningReminderMinute

        let morningTrigger = UNCalendarNotificationTrigger(dateMatching: morningComponents, repeats: true)
        let morningRequest = UNNotificationRequest(identifier: "morningCheckIn", content: morning, trigger: morningTrigger)

        center.add(eveningRequest)
        center.add(morningRequest)
    }

    private func dateFrom(hour: Int, minute: Int) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? Date()
    }

    private func updateReminder(from date: Date, evening: Bool) {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        guard let hour = components.hour, let minute = components.minute else { return }

        if evening {
            reminderHour = hour
            reminderMinute = minute
        } else {
            morningReminderHour = hour
            morningReminderMinute = minute
        }

        if notificationsEnabled {
            scheduleDailyNotifications()
            statusMessage = "Notifications updated"
        }
    }

    private func deleteLog(_ log: SleepLog) {
        sleepLogs.removeAll { $0.id == log.id }
        persistLogs()
        invalidateAISummary()
        if editingLogID == log.id {
            resetLogForm()
        }
    }

    private func resetLogForm() {
        editingLogID = nil
        selectedSleepHours = 7.5
        selectedBedtime = Calendar.current.date(bySettingHour: 23, minute: 0, second: 0, of: selectedDate) ?? selectedDate
        selectedWakeTime = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: selectedDate) ?? selectedDate
        selectedNotes = ""
        selectedFeeling = "Tired"
        selectedActivities = []
        customActivityInput = ""
        selectedActivityLevel = 3
        selectedLateNightEating = false
        selectedWaterIntakeGlasses = 6
        selectedCoffeeIntakeCups = 0
        selectedAlcoholIntakeDrinks = 0
        selectedDifficulty = 3
        selectedWakeUps = 2
        selectedEnergy = 3
    }

    private func bedtimeMinutes(_ date: Date) -> Int {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0
        let normalizedHour = hour < 12 ? hour + 24 : hour
        return (normalizedHour * 60) + minute
    }

    private func combine(date: Date, withTimeFrom time: Date) -> Date {
        let calendar = Calendar.current
        let dayComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)

        var components = DateComponents()
        components.year = dayComponents.year
        components.month = dayComponents.month
        components.day = dayComponents.day
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute

        return calendar.date(from: components) ?? date
    }

    private func invalidateAISummary() {
        aiCoachSummary = ""
        aiCoachHeadline = ""
        aiCoachStatusMessage = ""
    }

    private func shortDateString(_ date: Date) -> String {
        date.formatted(.dateTime.month(.abbreviated).day())
    }

    private func shortTimeString(_ date: Date) -> String {
        date.formatted(.dateTime.hour().minute())
    }

    #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    private func aiAvailabilityMessage(for reason: SystemLanguageModel.Availability.UnavailableReason) -> String {
        switch reason {
        case .deviceNotEligible:
            return "Apple Intelligence is not supported on this device, so the app is using its built-in recommendation instead."
        case .appleIntelligenceNotEnabled:
            return "Apple Intelligence is turned off on this device. You can still use the built-in recommendation card."
        case .modelNotReady:
            return "Apple Intelligence is still getting ready on this device. Try again a little later."
        @unknown default:
            return "Apple Intelligence is unavailable right now, so the app is using its built-in recommendation instead."
        }
    }

    private func generateAISummary() {
        guard weeklyLogs.count >= 3 else {
            aiCoachStatusMessage = "Log a few more nights first, then generate your weekly summary."
            return
        }

        guard #available(iOS 26.0, *) else {
            aiCoachStatusMessage = "Apple Intelligence is unavailable here, so the app is showing its built-in recommendation instead."
            return
        }

        let model = SystemLanguageModel.default
        guard model.isAvailable else {
            if case .unavailable(let reason) = model.availability {
                aiCoachStatusMessage = aiAvailabilityMessage(for: reason)
            } else {
                aiCoachStatusMessage = "Apple Intelligence is unavailable right now."
            }
            return
        }

        isGeneratingAISummary = true
        aiCoachStatusMessage = "Generating your private on-device summary..."

        let snapshot = weeklyAISnapshot()

        Task {
            do {
                let session = LanguageModelSession(
                    model: model,
                    instructions: """
                    You are a concise sleep wellness coach inside the Insomnia Trac app.
                    Use only the user-provided sleep log data.
                    Do not diagnose, treat, or claim medical certainty.
                    Keep the tone warm, specific, and practical.
                    Return exactly two paragraphs:
                    1. A short heading on the first line, then a 2-sentence weekly summary.
                    2. One gentle action step that the user can try this week.
                    Keep the total response under 90 words.
                    """
                )

                let response = try await session.respond(
                    to: """
                    Summarize the user's last week of sleep data and suggest the single most helpful next step.

                    Weekly averages:
                    - Sleep: \(formattedOneDecimal(averageSleepHours)) hours
                    - Morning energy: \(formattedOneDecimal(averageMorningEnergy)) / 5
                    - Wake-ups: \(formattedOneDecimal(averageNighttimeWakeUps))
                    - Coffee: \(formattedOneDecimal(averageCoffeeIntake)) cups
                    - Late-night eating: \(lateNightEatingCount) nights
                    - Bedtime range: \(formattedOneDecimal(bedtimeConsistencyRangeHours)) hours

                    Detailed entries:
                    \(snapshot)
                    """
                )

                let rawText = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
                let segments = rawText.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                let headline = segments.first?.trimmingCharacters(in: CharacterSet(charactersIn: "#*- ").union(.whitespacesAndNewlines)) ?? "Weekly AI Summary"
                let body = segments.dropFirst().joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)

                await MainActor.run {
                    aiCoachHeadline = headline
                    aiCoachSummary = body.isEmpty ? rawText : body
                    aiCoachStatusMessage = "Generated with Apple Intelligence on device."
                    isGeneratingAISummary = false
                }
            } catch {
                await MainActor.run {
                    aiCoachStatusMessage = "Apple Intelligence could not generate a summary right now. The built-in recommendation is still available."
                    isGeneratingAISummary = false
                }
            }
        }
    }
    #else
    private func generateAISummary() {
        aiCoachStatusMessage = "Apple Intelligence is unavailable in this build, so the app is showing its built-in recommendation instead."
    }
    #endif
}

struct WelcomeScreen: View {
    let onContinue: () -> Void
    let onLoadSampleData: () -> Void

    @State private var animateBackground = false
    @State private var revealContent = false
    @State private var pulseMoon = false

    private let moonGlow = Color(red: 0.98, green: 0.92, blue: 0.83)
    private let dawnLavender = Color(red: 0.73, green: 0.58, blue: 0.98)
    private let starlight = Color(red: 0.86, green: 0.89, blue: 1.0)
    private let twilightBlue = Color(red: 0.13, green: 0.17, blue: 0.46)

    var body: some View {
        ZStack {
            welcomeBackground

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    heroCard
                    quickBenefitsCard
                    howToUseCard
                    disclaimerCard

                    VStack(spacing: 12) {
                        Button {
                            onLoadSampleData()
                        } label: {
                            HStack {
                                Spacer()
                                Label("Load Sample Week", systemImage: "sparkles.rectangle.stack.fill")
                                    .font(.headline)
                                Spacer()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)

                        Button {
                            onContinue()
                        } label: {
                            HStack {
                                Spacer()
                                Label("Start Tracking", systemImage: "arrow.right.circle.fill")
                                    .font(.headline)
                                Spacer()
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)

                        Text("Use sample data if you want to explore the dashboard, history, and AI sleep coach right away.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 4)
                }
                .padding()
                .opacity(revealContent ? 1 : 0)
                .offset(y: revealContent ? 0 : 18)
                .animation(.easeOut(duration: 0.55), value: revealContent)
            }
        }
        .preferredColorScheme(.dark)
        .interactiveDismissDisabled()
        .onAppear {
            animateBackground = true
            revealContent = true
            pulseMoon = true
        }
    }

    private var welcomeBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.01, green: 0.03, blue: 0.14),
                    Color(red: 0.07, green: 0.09, blue: 0.29),
                    Color(red: 0.16, green: 0.11, blue: 0.38)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(moonGlow.opacity(0.18))
                .frame(width: 260, height: 260)
                .blur(radius: 24)
                .offset(x: animateBackground ? -140 : -80, y: animateBackground ? -260 : -180)

            Circle()
                .fill(dawnLavender.opacity(0.28))
                .frame(width: 320, height: 320)
                .blur(radius: 22)
                .offset(x: animateBackground ? 180 : 100, y: animateBackground ? 180 : 100)

            Circle()
                .fill(twilightBlue.opacity(0.40))
                .frame(width: 220, height: 220)
                .blur(radius: 18)
                .offset(x: animateBackground ? 30 : -10, y: animateBackground ? -10 : 50)
        }
        .animation(.easeInOut(duration: 8).repeatForever(autoreverses: true), value: animateBackground)
        .ignoresSafeArea()
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Welcome")
                        .font(.headline)
                        .foregroundStyle(starlight.opacity(0.9))

                    Text("Insomnia Trac")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("A calm sleep journal that helps you log your nights, spot patterns, and build a clearer picture of what affects your rest.")
                        .font(.subheadline)
                        .foregroundStyle(starlight.opacity(0.76))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                ZStack {
                    Circle()
                        .fill(moonGlow.opacity(0.14))
                        .frame(width: 72, height: 72)
                        .scaleEffect(pulseMoon ? 1.04 : 0.92)
                        .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true), value: pulseMoon)

                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(moonGlow)
                }
            }

            HStack(spacing: 12) {
                welcomePill(title: "Track", value: "sleep and habits")
                welcomePill(title: "Understand", value: "patterns and AI tips")
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [twilightBlue.opacity(0.74), dawnLavender.opacity(0.42)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(starlight.opacity(0.14), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: .black.opacity(0.20), radius: 18, x: 0, y: 10)
    }

    private var quickBenefitsCard: some View {
        welcomeSectionCard(
            title: "What you can do",
            subtitle: "The essentials, without the extra reading."
        ) {
            VStack(spacing: 12) {
                welcomeFeatureRow(
                    symbol: "square.and.pencil",
                    title: "Log your sleep",
                    detail: "Capture hours, bedtime, wake time, habits, mood, and notes."
                )
                welcomeFeatureRow(
                    symbol: "chart.line.uptrend.xyaxis",
                    title: "See patterns",
                    detail: "Review trends, averages, and the habits that may affect your rest."
                )
                welcomeFeatureRow(
                    symbol: "apple.intelligence",
                    title: "Get AI guidance",
                    detail: "Generate a private on-device weekly summary and one gentle next step."
                )
            }
        }
    }

    private var howToUseCard: some View {
        welcomeSectionCard(
            title: "How to use it",
            subtitle: "A simple routine helps the app become more helpful."
        ) {
            VStack(alignment: .leading, spacing: 12) {
                welcomeStep(number: "1", text: "Use the Log tab to save your sleep details.")
                welcomeStep(number: "2", text: "Add habits and notes when they matter.")
                welcomeStep(number: "3", text: "Come back to Overview for trends and AI insights.")
            }
        }
    }

    private var disclaimerCard: some View {
        welcomeSectionCard(
            title: "Important disclaimer",
            subtitle: "Please read this before using the app."
        ) {
            Text("Insomnia Trac is a wellness tracking tool. It does not diagnose, treat, or replace professional medical care.")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.9))
        }
    }

    private func welcomePill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(starlight.opacity(0.65))
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func welcomeSectionCard<Content: View>(title: String, subtitle: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            content()
        }
        .padding(18)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
    }

    private func welcomeFeatureRow(symbol: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(moonGlow)
                .frame(width: 36, height: 36)
                .background(dawnLavender.opacity(0.16))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func welcomeStep(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(dawnLavender.opacity(0.30))
                .clipShape(Circle())

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.92))
        }
    }
}

#Preview {
    ContentView()
}
