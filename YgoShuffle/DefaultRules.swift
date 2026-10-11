import Foundation

enum DefaultRules {
    static let groups: [(RuleCategory, [String])] = [
        (.drawAndHand, [
            "Shuffle your hand into your deck and then draw that many cards.",
            "Draw cards up to the number of cards your opponent controls. At the End Phase, banish your entire hand face-down.",
            "Draw a card from the bottom of your deck.",
            "Draw two cards.",
            "Your opponent discards a random card from your hand.",
        ]),
        (.lifePoints, [
            "Swap LP with your opponent.",
            "All players lose 1500 LP.",
            "Restore your LP back to 8000.",
            "Pay half of your LP.",
            "Pay 500 LP for each Spell and Trap on the field.",
            "For the rest of the turn, you must pay 300 LP to activate cards or effects.",
            "For the rest of the turn, you must pay 700 LP each time you Normal or Special Summon.",
        ]),
        (.battle, [
            "All of your monsters can attack directly until the end of this turn.",
            "You must banish 10 cards from the top of your deck each time you declare an attack directly with a monster you control.",
            "Skip your Battle phase.",
        ]),
        (.restrictions, [
            "You cannot Special Summon cards from your Extra Deck for the rest of the turn.",
            "You may not Special Summon cards for the rest of the turn.",
            "You may not Special Summon cards from your Main Deck for the rest of the turn.",
            "You cannot activate Spells or Traps for the rest of the turn.",
            "Skip your Main Phase 1.",
            "Skip your Main Phase 2.",
        ]),
        (.monsters, [
            "If you have less LP than your opponent, special summon one monster from your hand to the field, ignoring summoning conditions.",
            "Special Summon a monster from either GY ignoring its summoning conditions.",
            "Special Summon a monster from your Extra Deck ignoring its summoning conditions.",
            "Target 1 face-up monster on the field; Special Summon a Token to your side of the field. This Token gains the ATK, DEF, LEVEL, and EFFECT of the targeted monster.",
            "Make one monster's effect NOT 'once per turn' from your side of the field.",
            "All monsters become normal monsters with no effects until the end of the turn.",
            "Change all monsters to face-down position. They may not change battle position.",
            "Each player chooses 1 monster they control and switches control of those monsters with each other.",
        ]),
        (.monsters, [
            "Double the ATK or DEF of all your monsters for the rest of the turn.",
            "Swap the ATK and DEF of all monsters on your opponent's side of the field.",
            "Half the ATK and DEF of all your monsters for the rest of the turn.",
        ]),
        (.monsters, [
            "Destroy all monsters with 5 or more levels.",
            "Destroy all monsters with 4 or less levels.",
            "Destroy all monsters your opponent controls.",
            "Destroy all monsters you control.",
            "Destroy all monsters on the field.",
            "Destroy all face-up monsters on the field.",
            "Destroy all face-down monsters on the field.",
            "Destroy all face-up Fusion monsters.",
            "Destroy all face up Synchro monsters.",
            "Destroy all face-up XYZ monsters.",
            "Destroy all Link monsters.",
            "Destroy all face-up Pendulum monsters.",
            "If you control monsters of the same attribute, destroy all your opponent's monsters.",
            "Banish all cards on the field.",
            "Both you and your opponent send all Fusion monsters they control on the field to the GY.",
            "Both you and your opponent send all Synchro monsters they control on the field to the GY.",
            "Both you and your opponent send all Xyz monsters they control on the field to the GY.",
            "Both you and your opponent send all Link monsters they control on the field to the GY.",
            "Both you and your opponent send all Pendulum monsters they control on the field to the GY.",
        ]),
        (.spellsAndTraps, [
            "Destroy all Spell and Trap cards your opponent controls.",
            "Destroy all Spells and Traps you control.",
            "Destroy all Spells and Traps in the field",
            "Banish all Spells and Traps your opponent controls.",
            "Banish all Spells and Traps you control.",
            "Banish all Spells and Traps in the field",
            "Return all Spells and Traps your opponent controls.",
            "Return all Spells and Traps you control.",
            "Return all Spells and Traps in the field.",
        ]),
        (.miscellaneous, [
            "Both players excavate the top card of their decks, then if it is a monster that can be Special summoned, Special summon it or if it is a Spell or Trap that can be activated, activate it. Otherwise, add it to the hand.",
            "Swap hands with your opponent. Send both hands to the GY at the end of the turn.",
            "Shuffle your GY into your deck then send the top 15 cards of your to the GY.",
            "Banish all cards in your GY.",
            "Skip your opponents' next turn.",
            "It immediately becomes the End Phase.",
            "Negate the effects of all face-up monsters while they are face-up on the field (but their effects can still be activated). This effect is continous and ends during the End Phase of your opponent's 3rd turn.",
            "Monsters that are banished, as well as monsters in the GY, cannot activate their effects. This effect is continous and ends during the End Phase of your opponent's 3rd turn.",
            "Both players must Set Spell Cards before activating them, and cannot activate them until their next turn after Setting them. This effect is continous and ends during the End Phase of your opponent's 3rd turn."
        ]),
    ]

    static var rules: [String] { groups.flatMap { $0.1 } }

    static func category(for text: String) -> RuleCategory {
        groups.first(where: { $0.1.contains(text) })?.0 ?? .miscellaneous
    }
}
