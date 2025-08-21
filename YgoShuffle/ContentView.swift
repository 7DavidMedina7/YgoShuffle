//
//  ContentView.swift
//  YgoShuffle
//
//  Enhanced with Custom Rule Lists
//

import SwiftUI

// Data model for rule lists
struct RuleList: Codable, Identifiable, Equatable {
    let id = UUID()
    var name: String
    var rules: [String]
    
    static func == (lhs: RuleList, rhs: RuleList) -> Bool {
        lhs.id == rhs.id
    }
}

// Safe array access extension
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

struct ContentView: View {
    @State private var ruleLists: [RuleList] = {
        if let savedLists = UserDefaults.standard.data(forKey: "ruleLists"),
           let decodedLists = try? JSONDecoder().decode([RuleList].self, from: savedLists),
           !decodedLists.isEmpty {
            return decodedLists
        }
        // Default rule list
        return [RuleList(name: "Default Rules", rules: [
            "Shuffle your hand into your deck and then draw that many cards.",
            "Destroy all face-up fusion monsters.",
            "Draw a card from the bottom of your deck.",
            "Destroy all face up synchro monsters.",
            "Swap LP with your opponent.",
            "Shuffle your graveyard into your deck. Then mill the top 15 cards to the graveyard.",
            "Destroy all monsters with 5 or more levels.",
            "Banish all cards in your graveyard.",
            "Destroy all spell and trap cards your opponent controls.",
            "Banish all cards on the field.",
            "If you have less LP than your opponent, special summon one monster from your hand to the field, ignoring summoning conditions.",
            "Turn all monsters face-down; they may not change battle position.",
            "Skip your opponents' next turn.",
            "All monsters become normal monsters with no effects until the end of the turn.",
            "Destroy all face-up XYZ monsters.",
            "Swap the ATK and DEF of all monsters on your opponents' side of the field.",
            "Destroy all monsters with 4 or less levels.",
            "You may not special summon cards for the rest of the turn.",
            "You may only activate one card this turn.",
            "Destroy all monsters on the field.",
            "Draw cards up to the number of cards your opponent controls. At the end phase, banish your entire hand face down.",
            "Your opponent discards a random card from your hand.",
            "All players lose 1500 LP.",
            "Restore your LP back to 8000.",
            "Destroy all link monsters.",
            "Swap a monster with your opponent both of your choice.",
            "Draw two cards.",
            "You cannot attack unless you scream out 'Yu-Gi-Oh!'",
            "You cannot special summon cards from your extra deck for the rest of the turn.",
            "Lose half of your LP.",
            "Card drawn is to be put back at the bottom of the deck.",
            "Lose 500 LP for each spell and trap in the entire field.",
            "All players reveal the top card of their deck. You may play that card immediately, starting with the turn player. Otherwise, keep the card in your hand.",
            "For the rest of the turn, pay 100 LP for each card/effect you activate.",
            "You cannot activate spells or traps for the rest of the turn.",
            "Skip your main phase 1.",
            "Special summon any monster from either player's graveyard ignoring its summoning conditions.",
            "Special summon a token to your side of the field. This token mirror's a monster's ATK, DEF, LEVEL, and EFFECT, from either side of the field.",
            "Make one monster's effect NOT 'once per turn' from your side of the field.",
            "For each monster that attacks directly this turn, banish the top ten cards from your opponent's deck.",
            "Swap hands with your opponent. Send both hands to the graveyard at the end of the turn.",
            "If you control monsters of the same attribute, destroy all your opponent's monsters.",
            "All of your monsters can attack directly until the end of this turn.",
            "Double the ATK or DEF of all your monsters for the rest of the turn."
        ])]
    }()
    
    @State private var selectedRuleListIndex: Int = UserDefaults.standard.integer(forKey: "selectedRuleListIndex")
    @State private var selectedRule: String? = nil
    @State private var isSpinning = false
    @State private var showingRuleLists = false
    @State private var slotRules: [String] = []
    @State private var spinOffset: CGFloat = 0
    @State private var isDarkMode = true
    @State private var isGlowing = false
    @State private var showingHowToPlay = false
    @AppStorage("darkMode") private var persistentDarkMode = true
    
    private var currentRuleList: RuleList {
        guard selectedRuleListIndex < ruleLists.count else {
            return ruleLists.first ?? RuleList(name: "Empty", rules: [])
        }
        return ruleLists[selectedRuleListIndex]
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
                        slotMachineContainer
                        controlButtons
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
                selectedListIndex: $selectedRuleListIndex,
                onSave: saveRuleLists
            )
            .preferredColorScheme(.dark)
        }
        .onAppear {
            // Validate selected index on app start
            if selectedRuleListIndex >= ruleLists.count {
                selectedRuleListIndex = 0
            }
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
                ForEach(Array(ruleLists.enumerated()), id: \.offset) { index, ruleList in
                    Button(action: {
                        selectedRuleListIndex = index
                        saveSelectedList()
                        selectedRule = nil // Clear current selection when switching lists
                    }) {
                        HStack {
                            Text(ruleList.name)
                            if index == selectedRuleListIndex {
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
                        Text("\(currentRuleList.rules.count) rules")
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
        .disabled(isSpinning || currentRuleList.rules.isEmpty)
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
        Text(currentRuleList.rules.isEmpty ? "NO RULES AVAILABLE" : (isSpinning ? "SPINNING..." : "SPIN FOR RULE"))
            .font(.system(size: 18, weight: .bold, design: .rounded))
    }
    
    private var spinButtonBackground: some View {
        RoundedRectangle(cornerRadius: 25)
            .fill(spinButtonGradient)
            .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
    }
    
    private var spinButtonGradient: LinearGradient {
        LinearGradient(
            colors: currentRuleList.rules.isEmpty ?
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
    
    // Pick random rule with slot machine animation
    func pickRandomRule() {
        guard !currentRuleList.rules.isEmpty else { return }
        
        isSpinning = true
        
        // Create infinite loop of rules to fill entire animation duration
        var infiniteRules: [String] = []
        
        // Much faster scroll speed for authentic casino feel
        let pixelsPerSecond: CGFloat = 800
        let animationDuration: CGFloat = 2.0
        let ruleHeight: CGFloat = 45
        
        let totalPixelsToScroll = pixelsPerSecond * animationDuration
        let totalRulesNeeded = Int(totalPixelsToScroll / ruleHeight) + 10
        
        // Keep repeating the rules until we have enough to fill the animation
        while infiniteRules.count < totalRulesNeeded {
            infiniteRules.append(contentsOf: currentRuleList.rules.shuffled())
        }
        
        slotRules = infiniteRules
        
        // Start animation
        withAnimation(.easeOut(duration: 0.1)) {
            spinOffset = 0
        }
        
        // Fast scroll through the calculated distance
        let scrollDistance = totalPixelsToScroll - 150
        
        // 2-second animation with fast rule display
        withAnimation(.linear(duration: 2.0)) {
            spinOffset = -scrollDistance
        }
        
        // Final selection after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            var finalRule = currentRuleList.rules.randomElement() ?? ""
            
            if finalRule == "Re-roll the generator." {
                // Handle re-roll with extra drama
                withAnimation(.easeInOut(duration: 0.5)) {
                    selectedRule = "🎲 RE-ROLLING! 🎲"
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    repeat {
                        finalRule = currentRuleList.rules.randomElement() ?? ""
                    } while finalRule == "Re-roll the generator."
                    
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                        isGlowing = false // Reset glow state
                        selectedRule = finalRule
                        isSpinning = false
                    }
                }
            } else {
                // Final dramatic reveal
                withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                    isGlowing = false // Reset glow state
                    selectedRule = finalRule
                    isSpinning = false
                }
            }
        }
    }
    
    // Save to UserDefaults
    func saveRuleLists() {
        if let encoded = try? JSONEncoder().encode(ruleLists) {
            UserDefaults.standard.set(encoded, forKey: "ruleLists")
            print("Saved \(ruleLists.count) rule lists")
        } else {
            print("Failed to encode rule lists")
        }
    }
    
    func saveSelectedList() {
        UserDefaults.standard.set(selectedRuleListIndex, forKey: "selectedRuleListIndex")
    }
}

// Slot Machine Animation View
struct SlotMachineView: View {
    let rules: [String]
    let offset: CGFloat
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(rules.enumerated()), id: \.offset) { index, rule in
                Text(rule)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(Color.green.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .frame(height: 45)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.black.opacity(0.3),
                                        Color.yellow.opacity(0.1),
                                        Color.black.opacity(0.3)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .opacity(Double(index % 3) * 0.3 + 0.1)
                    )
            }
        }
        .offset(y: offset)
    }
}

// Rule List Management View
// Rule List Management View with Duplicate Functionality
struct RuleListManagementView: View {
    @Binding var ruleLists: [RuleList]
    @Binding var selectedListIndex: Int
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingNewListAlert = false
    @State private var newListName = ""
    @State private var editingListId: UUID? = nil
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Rule Lists")) {
                    ForEach(Array(ruleLists.enumerated()), id: \.element.id) { index, ruleList in
                        NavigationLink(destination: RulesManagementView(
                            ruleList: Binding(
                                get: { ruleLists[index] },
                                set: {
                                    ruleLists[index] = $0
                                    onSave()
                                }
                            ),
                            onSave: onSave
                        )) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(ruleList.name)
                                        .font(.headline)
                                    Text("\(ruleList.rules.count) rules")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if index == selectedListIndex {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button("Delete", role: .destructive) {
                                deleteRuleList(at: index)
                            }
                            .disabled(ruleLists.count == 1) // Don't allow deleting the last list
                        }
                        .swipeActions(edge: .leading) {
                            Button("Duplicate") {
                                duplicateRuleList(at: index)
                            }
                            .tint(.blue)
                        }
                        .contextMenu {
                            Button("Select as Active") {
                                selectedListIndex = index
                                onSave()
                            }
                            
                            Button("Duplicate") {
                                duplicateRuleList(at: index)
                            }
                            
                            if ruleLists.count > 1 {
                                Button("Delete", role: .destructive) {
                                    deleteRuleList(at: index)
                                }
                            }
                        }
                    }
                    .onMove(perform: moveRuleList)
                }
                
                Section(footer: Text("Tip: Swipe left on a list to delete it, or swipe right to duplicate it.")) {
                    EmptyView()
                }
            }
            .navigationTitle("Rule Lists")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        EditButton()
                        Button("Add List") {
                            showingNewListAlert = true
                        }
                    }
                }
            }
            .alert("New Rule List", isPresented: $showingNewListAlert) {
                TextField("List Name", text: $newListName)
                Button("Cancel", role: .cancel) {
                    newListName = ""
                }
                Button("Create") {
                    createNewRuleList()
                }
                .disabled(newListName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            } message: {
                Text("Enter a name for your new rule list")
            }
        }
    }
    
    func createNewRuleList() {
        let trimmedName = newListName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        let newList = RuleList(name: trimmedName, rules: [])
        ruleLists.append(newList)
        onSave()
        newListName = ""
    }
    
    func duplicateRuleList(at index: Int) {
        guard index < ruleLists.count else { return }
        
        let originalList = ruleLists[index]
        let duplicatedName = generateDuplicateName(from: originalList.name)
        let duplicatedList = RuleList(name: duplicatedName, rules: originalList.rules)
        
        // Insert the duplicated list right after the original
        ruleLists.insert(duplicatedList, at: index + 1)
        
        // Update selected index if needed
        if index < selectedListIndex {
            selectedListIndex += 1
        }
        
        onSave()
    }
    
    private func generateDuplicateName(from originalName: String) -> String {
        let baseName: String
        let copyNumber: Int
        
        // Check if the name already has a "Copy" suffix with a number
        let copyPattern = #"^(.*?)(?: Copy(?: (\d+))?)?$"#
        if let regex = try? NSRegularExpression(pattern: copyPattern),
           let match = regex.firstMatch(in: originalName, range: NSRange(originalName.startIndex..., in: originalName)) {
            
            if let baseRange = Range(match.range(at: 1), in: originalName) {
                baseName = String(originalName[baseRange]).trimmingCharacters(in: .whitespaces)
                
                if let numberRange = Range(match.range(at: 2), in: originalName),
                   let number = Int(originalName[numberRange]) {
                    copyNumber = number + 1
                } else if originalName.contains("Copy") {
                    copyNumber = 2
                } else {
                    copyNumber = 1
                }
            } else {
                baseName = originalName
                copyNumber = 1
            }
        } else {
            baseName = originalName
            copyNumber = 1
        }
        
        // Generate the new name
        let newName = copyNumber == 1 ? "\(baseName) Copy" : "\(baseName) Copy \(copyNumber)"
        
        // Check if this name already exists and increment if needed
        var finalName = newName
        var counter = copyNumber
        while ruleLists.contains(where: { $0.name == finalName }) {
            counter += 1
            finalName = "\(baseName) Copy \(counter)"
        }
        
        return finalName
    }
    
    func deleteRuleList(at index: Int) {
        guard ruleLists.count > 1 else { return } // Don't delete the last list
        
        // If we're deleting the currently selected list, select the first one
        if index == selectedListIndex {
            selectedListIndex = 0
        } else if index < selectedListIndex {
            selectedListIndex -= 1
        }
        
        ruleLists.remove(at: index)
        onSave()
    }
    
    func moveRuleList(from source: IndexSet, to destination: Int) {
        // Update selected index when moving lists
        if let sourceIndex = source.first {
            if sourceIndex == selectedListIndex {
                selectedListIndex = destination > sourceIndex ? destination - 1 : destination
            } else if sourceIndex < selectedListIndex && destination > selectedListIndex {
                selectedListIndex -= 1
            } else if sourceIndex > selectedListIndex && destination <= selectedListIndex {
                selectedListIndex += 1
            }
        }
        
        ruleLists.move(fromOffsets: source, toOffset: destination)
        onSave()
    }
}

// Individual Rule List Management View
struct RulesManagementView: View {
    @Binding var ruleList: RuleList
    let onSave: () -> Void
    @State private var newRule: String = ""
    @State private var editingIndex: Int? = nil
    @State private var editingText: String = ""
    @State private var showingEditAlert = false
    @State private var showingRenameAlert = false
    @State private var newListName: String = ""
    @Environment(\.dismiss) private var dismiss
    
    // Computed property to work with rules directly
    private var rulesBinding: Binding<[String]> {
        Binding(
            get: { ruleList.rules },
            set: { newRules in
                ruleList = RuleList(name: ruleList.name, rules: newRules)
                onSave()
            }
        )
    }
    
    var body: some View {
        VStack {
            // Add new rule section
            VStack(alignment: .leading, spacing: 10) {
                Text("Add New Rule")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack {
                    TextField("Enter new rule...", text: $newRule, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3, reservesSpace: true)
                    
                    Button("Add") {
                        guard !newRule.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                        let trimmedRule = newRule.trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        var currentRules = rulesBinding.wrappedValue
                        currentRules.append(trimmedRule)
                        rulesBinding.wrappedValue = currentRules
                        
                        newRule = ""
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(newRule.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .padding()
            
            // Rules list
            List {
                ForEach(Array(rulesBinding.wrappedValue.enumerated()), id: \.offset) { index, rule in
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Rule #\(index + 1)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(rule)
                                    .font(.body)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                editingIndex = index
                                editingText = rule
                                showingEditAlert = true
                            }) {
                                Image(systemName: "pencil")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 16))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onDelete(perform: deleteRule)
                .onMove(perform: moveRule)
            }
        }
        .navigationTitle(ruleList.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button("Rename") {
                        newListName = ruleList.name
                        showingRenameAlert = true
                    }
                    EditButton()
                }
            }
        }
        .alert("Edit Rule", isPresented: $showingEditAlert) {
            TextField("Rule text", text: $editingText, axis: .vertical)
                .lineLimit(5, reservesSpace: true)
            
            Button("Cancel", role: .cancel) {
                editingIndex = nil
                editingText = ""
            }
            
            Button("Save") {
                if let index = editingIndex,
                   !editingText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    
                    var currentRules = rulesBinding.wrappedValue
                    currentRules[index] = editingText.trimmingCharacters(in: .whitespacesAndNewlines)
                    rulesBinding.wrappedValue = currentRules
                }
                editingIndex = nil
                editingText = ""
            }
            .disabled(editingText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        } message: {
            if let index = editingIndex {
                Text("Edit Rule #\(index + 1)")
            }
        }
        .alert("Rename List", isPresented: $showingRenameAlert) {
            TextField("List Name", text: $newListName)
            Button("Cancel", role: .cancel) {
                newListName = ""
            }
            Button("Save") {
                let trimmedName = newListName.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedName.isEmpty {
                    ruleList = RuleList(name: trimmedName, rules: ruleList.rules)
                    onSave()
                }
                newListName = ""
            }
            .disabled(newListName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        } message: {
            Text("Enter a new name for this rule list")
        }
    }
    
    func deleteRule(at offsets: IndexSet) {
        var currentRules = rulesBinding.wrappedValue
        currentRules.remove(atOffsets: offsets)
        rulesBinding.wrappedValue = currentRules
    }
    
    func moveRule(from source: IndexSet, to destination: Int) {
        var currentRules = rulesBinding.wrappedValue
        currentRules.move(fromOffsets: source, toOffset: destination)
        rulesBinding.wrappedValue = currentRules
    }
}

struct HowToPlayView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(spacing: 10) {
                        Text("🎰 How to Play 🎰")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.yellow, .orange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        Text("YGO Shuffle")
                            .font(.system(size: 16, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 10)
                    
                    // Instructions sections
                    instructionSection(
                        title: "🃏🎲 What is YGO Shuffle?",
                        content: """
                        YGO Shuffle aims to alter any standard Yu-Gi-Oh!
                        duel into a more fun and unpredictable duel. 
                        
                        In YGO Shuffle, the [Rule Generator] is an external
                        entity that prompts effects randomly during each 
                        player's [Standby Phase]. 
                        
                        The catch is that these effects are considered to be 
                        [Spell Speed 4] meaning cards or effects cannot respond or negate them. 
                        
                        The idea is that no deck is safe regardless if you
                        are meta player, a returning casual player, 
                        or simply looking for a new way to play Yu-Gi-Oh!.
                        """
                    
                    )
                    
                    instructionSection(
                        title: "📝 Rules",
                        content: """
                        1. The [Rule Generator] is rolled at the beginning of each players [Standby Phase].
                        
                        2. The effects applied by the [Rule Generator] cannot be responded to or negated by cards or effects.
                        
                        3. Cards and effects are allowed to activate upon resolution of the effect generated by the [Rule Generator].
                        
                        4. The [Rule Generator] is to be re-rolled until something in the game state changes (We encourage adjusting the rule list to best fit your gameplay).
                        """
                    )
                    
                    instructionSection(
                        title: "🎯 Game Tips",
                        content: """
                        • The [Default List] is aimed for Advanced format. You can create new lists depending on the format you play! Edison, Goat, Toss, etc.
                        
                        • While YGO Shuffle is tailored towards Yu-Gi-Oh!, it can also be used for other card games such as Magic and Pokémon!
                        
                        • Add fun party rules! 🎉
                        """
                    )
                    
                    instructionSection(
                        title: "👾 About Me",
                        content: """
                        Created by David A. Medina
                        Instagram: @_davey_wavey_
                        
                        Special thanks to my friends Gerardo Lopez and Miguel Mejia for helping me with the design and accuracy of rules of YGO Shuffle.
                        """
                    )
                    
                    // Replace the sparkles image with your custom image
                    Image("SSA-Raye") // Use the exact name from Assets.xcassets
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 200)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    
                    // Footer
                    VStack(spacing: 8) {
                        Divider()
                            .background(Color.gray)
                        
                        Text("Have fun dueling! 🔥")
                            .font(.headline)
                            .foregroundColor(.orange)
                        
                        Text("Version 1.0")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                }
                .padding()
            }
        }
        .navigationTitle("How to Play")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
    
    private func instructionSection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.primary)
            
            Text(content)
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .lineSpacing(2)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}
