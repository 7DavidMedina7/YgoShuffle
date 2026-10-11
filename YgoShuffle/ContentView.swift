//
//  ContentView.swift
//  ContentView
//
//  Created by David Alonzo Medina on 8/17/25.
//

import SwiftUI

struct ContentView: View {
    @State private var ruleLists: [RuleList] = {
        if let savedLists = UserDefaults.standard.data(forKey: "ruleLists"),
           let decodedLists = try? JSONDecoder().decode([RuleList].self, from: savedLists),
           !decodedLists.isEmpty {
            return decodedLists
        }
        return [RuleList(name: "Default Rules", rules: DefaultRules.rules)]
    }()
    
    @State private var selectedRuleListID: UUID?
    @State private var spinID = UUID()
    @State private var selectedRule: String? = nil
    @State private var isSpinning = false
    @State private var showingRuleLists = false
    @State private var slotRules: [String] = []
    @State private var spinOffset: CGFloat = 0
    @State private var isDarkMode = true
    @State private var revealID = UUID()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showingHowToPlay = false
    @State private var showingHistory = false
    @State private var showingFilters = false
    @State private var showingSettings = false
    @State private var spinPreferences = SpinPreferences()
    @StateObject private var spinFeedback = SpinFeedback()
    @State private var history = RuleHistory()
    @AppStorage("darkMode") private var persistentDarkMode = true
    
    private var currentRuleList: RuleList {
        ruleLists.first(where: { $0.id == selectedRuleListID })
            ?? ruleLists.first ?? RuleList(name: "Empty", rules: [])
    }
    
    let gradientColors = [
        Color.purple.opacity(0.8),
        Color.blue.opacity(0.8),
        Color.indigo.opacity(0.8)
    ]
    
    let darkGradientColors = [
        Color.black,
        Color.gray.opacity(0.9),
        Color.black
    ]
    
    var body: some View {
        ZStack {
            backgroundGradient
            
            NavigationView {
                ScrollView {
                    VStack(spacing: 30) {
                        headerView
                        ruleListSelector
                        filterButton
                        slotMachineContainer
                        controlButtons
                        historyButton
                        settingsButton
                        Spacer(minLength: 20)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingRuleLists) {
            RuleListManagementView(
                ruleLists: $ruleLists,
                selectedListID: $selectedRuleListID,
                onSave: saveRuleLists
            )
            .preferredColorScheme(.dark)
        }
        .onAppear {
            selectedRuleListID = RuleListPersistence.selectedID(in: ruleLists)
            saveRuleLists()
        }
        .onChange(of: selectedRuleListID) { _, _ in
            cancelSpin()
            saveSelectedList()
        }
        .onChange(of: ruleLists) { _, _ in
            cancelSpin()
        }
        .onDisappear { cancelSpin() }
        .onChange(of: spinPreferences) { _, preferences in
            preferences.save()
            if !preferences.soundEnabled { spinFeedback.stop() }
        }
        .sheet(isPresented: $showingSettings) {
            SpinSettingsView(preferences: $spinPreferences)
                .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showingFilters) {
            RuleCategoryFilterView(
                ruleList: Binding(
                    get: { currentRuleList },
                    set: { updatedList in
                        guard let index = ruleLists.firstIndex(where: { $0.id == updatedList.id }) else { return }
                        ruleLists[index] = updatedList
                        saveRuleLists()
                    }
                )
            )
            .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showingHistory) {
            RuleHistoryView(entries: history.entries, onClear: { history.clear() })
                .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showingHowToPlay) {
            HowToPlayView()
                .preferredColorScheme(.dark)
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: darkGradientColors),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: isSpinning)
    }
    
    private var headerView: some View {
        VStack(spacing: 10) {
            Text("YGO Shuffle")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(titleGradient)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 2, y: 2)
            
            Text("RULE GENERATOR")
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .foregroundColor(.white.opacity(0.9))
                .tracking(3)
        }
        .padding(.top, 20)
    }
    
    private var titleGradient: LinearGradient {
        LinearGradient(
            colors: [.yellow, .orange],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    private var ruleListSelector: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "list.star")
                    .foregroundColor(.yellow)
                Text("Active Rule List:")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
            }
            
            Menu {
                ForEach(ruleLists) { ruleList in
                    Button(action: {
                        selectedRuleListID = ruleList.id
                        saveSelectedList()
                        selectedRule = nil // Clear current selection when switching lists
                    }) {
                        HStack {
                            Text(ruleList.name)
                            if ruleList.id == selectedRuleListID {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(currentRuleList.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        Text("\(currentRuleList.eligibleRules.count) of \(currentRuleList.rules.count) rules enabled")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            }
        }
        .padding(.horizontal)
    }
    
    private var slotMachineContainer: some View {
        NeonSpinnerView(
            rules: slotRules,
            offset: spinOffset,
            selectedRule: selectedRule,
            isSpinning: isSpinning,
            canSpin: !currentRuleList.eligibleRules.isEmpty,
            quickSpin: spinPreferences.quickSpinEnabled,
            revealID: revealID,
            onSpin: pickRandomRule
        )
    }

    private var controlButtons: some View {
        HStack(spacing: 20) {
            Button(action: { showingRuleLists.toggle() }) {
                HStack {
                    Image(systemName: "folder.badge.gearshape")
                    Text("Manage Lists")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 45)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.blue.opacity(0.8))
                        .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
                )
            }
            
            Button(action: { showingHowToPlay.toggle() }) {
                HStack {
                    Image(systemName: "questionmark.circle")
                    Text("How to Play")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 45)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.green.opacity(0.8))
                        .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
                )
            }
        }
        .padding(.horizontal)
    }
    
    private var filterButton: some View {
        Button(action: { showingFilters = true }) {
            Label("Categories: \(currentRuleList.enabledCategories.count) of \(RuleCategory.allCases.count) enabled",
                  systemImage: "line.3.horizontal.decrease.circle")
                .font(.subheadline)
                .foregroundColor(.yellow)
        }
        .padding(.horizontal)
    }

    private var settingsButton: some View {
        Button(action: { showingSettings = true }) {
            Label("Spin Settings", systemImage: "gearshape")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal)
    }

    private var historyButton: some View {
        Button(action: { showingHistory = true }) {
            Label("Rule History", systemImage: "clock.arrow.circlepath")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 45)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.purple.opacity(0.8))
                )
        }
        .padding(.horizontal)
    }

    // Pick random rule with slot machine animation
    func pickRandomRule() {
        guard !isSpinning else { return }
        let sourceList = currentRuleList
        let rules = sourceList.eligibleRules
        let previousRule = spinPreferences.avoidConsecutiveDuplicates
            ? history.entries.first(where: { $0.listID == sourceList.id })?.rule : nil
        guard let outcome = RuleGenerator.pick(from: rules, avoiding: previousRule) else {
            selectedRule = "No playable rules available. Add a rule other than Re-roll the generator."
            return
        }
        let duration = reduceMotion ? 0.1 : spinPreferences.spinDuration
        let rerollDuration = reduceMotion ? 0.1 : spinPreferences.rerollDuration
        let token = UUID()
        spinID = token
        
        selectedRule = nil
        isSpinning = true
        spinFeedback.started(preferences: spinPreferences)
        
        let landingRule = outcome.didReroll ? RuleGenerator.rerollRule : outcome.rule
        guard let reel = SpinReelPlan.make(from: rules, landingRule: landingRule, duration: duration) else {
            cancelSpin()
            return
        }
        slotRules = reel.rules

        var resetTransaction = Transaction()
        resetTransaction.disablesAnimations = true
        withTransaction(resetTransaction) { spinOffset = 0 }
        if reduceMotion {
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                completeReel(outcome: outcome, list: sourceList, token: token,
                             rerollDuration: rerollDuration)
            }
        } else {
            // Mount at the starting position before animating toward the chosen row.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                guard spinID == token else { return }
                withAnimation(.timingCurve(0.12, 0.65, 0.2, 1, duration: duration),
                              completionCriteria: .removed) {
                    spinOffset = CGFloat(reel.landingOffset)
                } completion: {
                    guard spinID == token else { return }
                    // Briefly hold the centered result so the reel and reveal read as one choice.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        completeReel(outcome: outcome, list: sourceList, token: token,
                                     rerollDuration: rerollDuration)
                    }
                }
            }
        }
    }

    private func completeReel(outcome: RuleGenerator.Outcome, list: RuleList,
                              token: UUID, rerollDuration: Double) {
        guard spinID == token else { return }
        if outcome.didReroll {
            selectedRule = "🎲 RE-ROLLING! 🎲"
            DispatchQueue.main.asyncAfter(deadline: .now() + rerollDuration) {
                guard spinID == token else { return }
                finishSpin(with: outcome.rule, list: list)
            }
        } else {
            finishSpin(with: outcome.rule, list: list)
        }
    }

    private func finishSpin(with rule: String, list: RuleList) {
        history.record(rule: rule, list: list)
        spinFeedback.revealed(preferences: spinPreferences)
        withAnimation(reduceMotion ? nil : .spring(response: 0.6, dampingFraction: 0.6)) {
            revealID = UUID()
            selectedRule = rule
            isSpinning = false
        }
    }

    private func cancelSpin() {
        spinFeedback.stop()
        spinID = UUID()
        isSpinning = false
        selectedRule = nil
        revealID = UUID()
    }
    
    // Save to UserDefaults
    func saveRuleLists() {
        if let encoded = try? JSONEncoder().encode(ruleLists) {
            UserDefaults.standard.set(encoded, forKey: "ruleLists")
            saveSelectedList()
        } else {
            print("Failed to encode rule lists")
        }
    }
    
    func saveSelectedList() {
        UserDefaults.standard.set(selectedRuleListID?.uuidString, forKey: "selectedRuleListID")
    }
}
