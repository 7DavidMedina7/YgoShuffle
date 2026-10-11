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
    @State private var isGlowing = false
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
        VStack(spacing: 20) {
            slotMachineDisplay
            spinButton
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 25)
        .background(containerBackground)
        .padding(.horizontal)
    }
    
    private var slotMachineDisplay: some View {
        VStack {
            Text("🎰 RULE SLOT 🎰")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.bottom, 5)
            
            slotWindow
        }
    }
    
    private var slotWindow: some View {
        RoundedRectangle(cornerRadius: 15)
            .fill(Color.black.opacity(0.95))
            .frame(height: 200)
            .overlay(slotWindowBorder)
            .overlay(slotContent)
            .overlay(
                // Casino-style slot machine lines
                VStack {
                    Divider()
                        .background(Color.yellow.opacity(0.3))
                    Spacer()
                    Divider()
                        .background(Color.yellow.opacity(0.3))
                    Spacer()
                    Divider()
                        .background(Color.yellow.opacity(0.3))
                }
                .padding(.vertical, 20)
            )
            .clipped()
    }
    
    private var slotWindowBorder: some View {
        RoundedRectangle(cornerRadius: 15)
            .stroke(slotBorderGradient, lineWidth: 3)
    }
    
    private var slotBorderGradient: LinearGradient {
        LinearGradient(
            colors: [.yellow, .orange, .red],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    @ViewBuilder
    private var slotContent: some View {
        if isSpinning {
            SlotMachineView(rules: slotRules, offset: spinOffset)
        } else if let selectedRule = selectedRule {
            selectedRuleView(selectedRule)
        } else {
            placeholderView
        }
    }
    
    private func selectedRuleView(_ rule: String) -> some View {
        Text(rule)
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isGlowing ? Color.yellow.opacity(0.1) : Color.clear)
                    .shadow(
                        color: isGlowing ? .yellow : .clear,
                        radius: isGlowing ? 30 : 0
                    )
                    .shadow(
                        color: isGlowing ? .orange : .clear,
                        radius: isGlowing ? 20 : 0
                    )
                    .shadow(
                        color: isGlowing ? .red : .clear,
                        radius: isGlowing ? 15 : 0
                    )
                    .overlay(
                        // Extra visible border when glowing
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isGlowing ? Color.yellow : Color.clear, lineWidth: 2)
                    )
            )
            .scaleEffect(isGlowing ? 1.1 : 1.0)
            .transition(.scale.combined(with: .opacity))
            .animation(.easeInOut(duration: 0.6), value: isGlowing)
            .onChange(of: rule) { _, newRule in
                print("🔄 Rule changed to: \(newRule)")
                
                // Reset glow state
                isGlowing = false
                print("❌ Glow reset to false")
                
                // Start glow effect after short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    print("✨ Starting glow animation")
                    withAnimation(.easeInOut(duration: 0.6).repeatCount(4, autoreverses: true)) {
                        isGlowing = true
                    }
                    print("🟡 isGlowing set to: \(isGlowing)")
                    
                    // Stop glowing after animation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
                        print("🔚 Stopping glow animation")
                        withAnimation(.easeOut(duration: 0.5)) {
                            isGlowing = false
                        }
                    }
                }
            }
            .onAppear {
                print("👁️ selectedRuleView appeared with rule: \(rule)")
                
                // Trigger glow on first appearance
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    print("✨ Starting initial glow animation")
                    withAnimation(.easeInOut(duration: 0.6).repeatCount(4, autoreverses: true)) {
                        isGlowing = true
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
                        print("🔚 Stopping initial glow animation")
                        withAnimation(.easeOut(duration: 0.5)) {
                            isGlowing = false
                        }
                    }
                }
            }
    }
    
    private var placeholderView: some View {
        VStack {
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            Text("Press the button to spin!")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
    
    private var spinButton: some View {
        Button(action: pickRandomRule) {
            spinButtonContent
        }
        .disabled(isSpinning || currentRuleList.eligibleRules.isEmpty)
    }
    
    private var spinButtonContent: some View {
        HStack {
            spinButtonIcon
            spinButtonText
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 55)
        .background(spinButtonBackground)
        .scaleEffect(isSpinning ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isSpinning)
    }
    
    private var spinButtonIcon: some View {
        Image(systemName: isSpinning ? "arrow.2.circlepath" : "dice.fill")
            .font(.title2)
            .rotationEffect(.degrees(isSpinning ? 360 : 0))
            .animation(.linear(duration: 0.5).repeatForever(autoreverses: false), value: isSpinning)
    }
    
    private var spinButtonText: some View {
        Text(currentRuleList.eligibleRules.isEmpty ? "NO ENABLED RULES" : (isSpinning ? "SPINNING..." : "SPIN FOR RULE"))
            .font(.system(size: 18, weight: .bold, design: .rounded))
    }
    
    private var spinButtonBackground: some View {
        RoundedRectangle(cornerRadius: 25)
            .fill(spinButtonGradient)
            .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
    }
    
    private var spinButtonGradient: LinearGradient {
        LinearGradient(
            colors: currentRuleList.eligibleRules.isEmpty ?
                [.gray.opacity(0.3), .gray.opacity(0.2)] :
                (isSpinning ?
                    [.gray.opacity(0.6), .gray.opacity(0.4)] :
                    [.red.opacity(0.8), .orange.opacity(0.8)]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    private var containerBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.white.opacity(0.1))
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.2))
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
        let duration = spinPreferences.spinDuration
        let rerollDuration = spinPreferences.rerollDuration
        let token = UUID()
        spinID = token
        
        isSpinning = true
        spinFeedback.started(preferences: spinPreferences)
        
        // Create infinite loop of rules to fill entire animation duration
        var infiniteRules: [String] = []
        
        // Much faster scroll speed for authentic casino feel
        let pixelsPerSecond: CGFloat = 800
        let animationDuration = CGFloat(duration)
        let ruleHeight: CGFloat = 45
        
        let totalPixelsToScroll = pixelsPerSecond * animationDuration
        let totalRulesNeeded = Int(totalPixelsToScroll / ruleHeight) + 10
        
        // Keep repeating the rules until we have enough to fill the animation
        while infiniteRules.count < totalRulesNeeded {
            infiniteRules.append(contentsOf: rules.shuffled())
        }
        
        slotRules = infiniteRules
        
        // Start animation
        withAnimation(.easeOut(duration: 0.1)) {
            spinOffset = 0
        }
        
        // Fast scroll through the calculated distance
        let scrollDistance = totalPixelsToScroll - 150
        
        // Scroll using the duration selected at the start of this spin.
        withAnimation(.linear(duration: duration)) {
            spinOffset = -scrollDistance
        }
        
        // Reveal only if this spin has not been canceled.
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            guard spinID == token else { return }
            if outcome.didReroll {
                // Reveal the re-roll message while keeping the button locked.
                selectedRule = "🎲 RE-ROLLING! 🎲"
                slotRules = ["🎲 RE-ROLLING! 🎲"]
                spinOffset = 0
                DispatchQueue.main.asyncAfter(deadline: .now() + rerollDuration) {
                    guard spinID == token else { return }
                    finishSpin(with: outcome.rule, list: sourceList)
                }
            } else {
                finishSpin(with: outcome.rule, list: sourceList)
            }
        }
    }

    private func finishSpin(with rule: String, list: RuleList) {
        history.record(rule: rule, list: list)
        spinFeedback.revealed(preferences: spinPreferences)
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
            isGlowing = false
            selectedRule = rule
            isSpinning = false
        }
    }

    private func cancelSpin() {
        spinFeedback.stop()
        spinID = UUID()
        isSpinning = false
        selectedRule = nil
        isGlowing = false
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
