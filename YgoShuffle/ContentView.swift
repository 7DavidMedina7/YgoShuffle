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
    @State private var reelWindowHeight: CGFloat = 300
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
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            GeometryReader { geometry in
                let landscape = geometry.size.width > geometry.size.height
                let windowHeight = max(80, min(340, geometry.size.height - (landscape ? 150 : 338)))
                Group {
                    if landscape {
                        HStack(spacing: 12) {
                            VStack(spacing: 10) {
                                headerView
                                ruleListSelector
                                utilityControls
                            }
                            .frame(width: min(260, geometry.size.width * 0.36))
                            slotMachineContainer(windowHeight: windowHeight)
                        }
                    } else {
                        VStack(spacing: 10) {
                            headerView
                                .frame(height: 38)
                            ruleListSelector
                                .frame(height: 62)
                            slotMachineContainer(windowHeight: windowHeight)
                            utilityControls
                                .frame(height: 54)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.vertical, 8)
                .onAppear { reelWindowHeight = windowHeight }
                .onChange(of: geometry.size) { _, _ in
                    cancelSpin()
                    reelWindowHeight = windowHeight
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
            installUpdatedDefaultRules()
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
    
    private var headerView: some View {
        Text("YGO Shuffle")
            .font(.system(size: 28, weight: .bold, design: .rounded))
            .foregroundStyle(AppTheme.accent)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }

    private var ruleListSelector: some View {
        HStack(spacing: 8) {
            Menu {
                ForEach(ruleLists) { list in
                    Button {
                        selectedRuleListID = list.id
                        saveSelectedList()
                        selectedRule = nil
                    } label: {
                        if list.id == selectedRuleListID {
                            Label(list.name, systemImage: "checkmark")
                        } else {
                            Text(list.name)
                        }
                    }
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "list.star").foregroundStyle(AppTheme.accent)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(currentRuleList.name)
                            .font(.system(size: 15, weight: .semibold))
                            .lineLimit(1)
                        Text("\(currentRuleList.eligibleRules.count) of \(currentRuleList.rules.count) rules enabled")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.6))
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.down").font(.caption2)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .frame(height: 58)
                .background(AppTheme.raisedSurface, in: RoundedRectangle(cornerRadius: 14))
            }
            .accessibilityLabel("Active list: \(currentRuleList.name)")

            Button { showingFilters = true } label: {
                VStack(spacing: 3) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.title3)
                    Text("Filters").font(.system(size: 10, weight: .medium))
                }
                .foregroundStyle(AppTheme.accent)
                .frame(width: 54, height: 58)
                .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 14))
            }
            .accessibilityLabel("Rule category filters")
        }
        .padding(.horizontal, 16)
    }

    private func slotMachineContainer(windowHeight: CGFloat) -> some View {
        NeonSpinnerView(
            rules: slotRules,
            offset: spinOffset,
            selectedRule: selectedRule,
            isSpinning: isSpinning,
            canSpin: !currentRuleList.eligibleRules.isEmpty,
            quickSpin: spinPreferences.quickSpinEnabled,
            revealID: revealID,
            onSpin: pickRandomRule,
            windowHeight: windowHeight
        )
    }

    private var utilityControls: some View {
        HStack(spacing: 6) {
            utilityButton("Lists", icon: "folder.badge.gearshape", color: AppTheme.surface, textColor: AppTheme.accent) { showingRuleLists = true }
            utilityButton("History", icon: "clock.arrow.circlepath", color: AppTheme.surface, textColor: AppTheme.accent) { showingHistory = true }
            utilityButton("How to Play", icon: "questionmark.circle", color: AppTheme.surface, textColor: AppTheme.accent) { showingHowToPlay = true }
            utilityButton("Settings", icon: "gearshape", color: AppTheme.surface, textColor: AppTheme.accent) { showingSettings = true }
        }
        .padding(.horizontal, 16)
    }

    private func utilityButton(_ title: String, icon: String, color: Color, textColor: Color = .white, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: icon).font(.system(size: 18))
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .foregroundStyle(textColor)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 48)
            .background(color, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
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
        guard let reel = SpinReelPlan.make(from: rules, landingRule: landingRule, duration: duration,
                                           windowHeight: Double(reelWindowHeight)) else {
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
    
    // Refresh whenever the bundled rules change, keeping previously saved lists intact.
    private func installUpdatedDefaultRules() {
        let revisionKey = "installedDefaultRulesSnapshot"
        let defaults = UserDefaults.standard
        let bundled = DefaultRules.rules
        guard defaults.stringArray(forKey: revisionKey) != bundled else { return }
        if let index = ruleLists.firstIndex(where: { $0.name == "Default Rules" }) {
            if ruleLists[index].rules.map(\.text) != bundled {
                let wasSelected = selectedRuleListID == ruleLists[index].id
                var backupName = "Default Rules (Previous)"
                var suffix = 2
                while ruleLists.contains(where: { $0.name == backupName }) {
                    backupName = "Default Rules (Previous \(suffix))"
                    suffix += 1
                }
                ruleLists[index].name = backupName
                let updated = RuleList(name: "Default Rules", rules: bundled)
                ruleLists.append(updated)
                if wasSelected { selectedRuleListID = updated.id }
            }
        } else {
            ruleLists.append(RuleList(name: "Default Rules", rules: bundled))
        }
        saveRuleLists()
        defaults.set(bundled, forKey: revisionKey)
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
