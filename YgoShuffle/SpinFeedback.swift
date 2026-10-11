import SwiftUI
import AVFoundation
import UIKit

@MainActor
final class SpinFeedback: ObservableObject {
    private var player: AVAudioPlayer?

    func started(preferences: SpinPreferences) {
        if preferences.hapticsEnabled {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        if preferences.soundEnabled { play("spin-start") }
    }

    func revealed(preferences: SpinPreferences) {
        if preferences.hapticsEnabled {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        if preferences.soundEnabled { play("spin-reveal") }
    }

    func stop() {
        player?.stop()
        player = nil
    }

    private func play(_ name: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else { return }
        do {
            // Ambient audio respects silent mode and mixes with other audio.
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            player = try AVAudioPlayer(contentsOf: url)
            player?.volume = 0.35
            player?.play()
        } catch {
            // Audio feedback must never prevent the generator from completing.
            player = nil
        }
    }
}
