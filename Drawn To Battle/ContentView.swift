//
//  ContentView.swift
//  Drawn To Battle
//

import SwiftUI

struct ContentView: View {
    private enum Stage { case start, naming, hub }

    @State private var stage: Stage = .start
    @StateObject private var studioState = StudioState()
    @StateObject private var game = GameSave()

    // Debug: SIMCTL_CHILD_DTB_ROUTE=<hub|solar|username|gacha|collection|battle-earth|battle-uranus|battle-sun|studio> skips the start screen.
    private var debugRoute: String? {
        ProcessInfo.processInfo.environment["DTB_ROUTE"]
    }

    var body: some View {
        root
            .animation(.easeInOut(duration: 0.35), value: stage)
            .onAppear {
                if debugRoute != nil { stage = .hub }
                if debugRoute == "collection-demo" && game.ownedBlueprints.isEmpty {
                    for id in ["jab", "hammer_drop", "lunge_step", "cross",
                               "smear_speedline", "copter_spin", "guillotine_kick",
                               "tornado", "supernova", "smear_ghost"] {
                        game.ownedBlueprints.insert(id)
                    }
                    if let bp = BlueprintCatalog.blueprint(id: "smear_speedline") {
                        game.equip(blueprint: bp)
                    }
                }
            }
    }

    @ViewBuilder
    private var root: some View {
        switch stage {
        case .start:
            StartScreenView {
                // First-time fighters name themselves before entering the hub.
                stage = game.hasUsername ? .hub : .naming
            }
        case .naming:
            UsernameView(game: game) {
                stage = .hub
            }
        case .hub:
            hub
        }
    }

    @ViewBuilder
    private var hub: some View {
        switch debugRoute {
        case "gacha":
            GachaView(game: game)
        case "collection":
            CollectionView(game: game)
        // Debug/demo: seeds a few owned blueprints to exercise the edit UI.
        case "collection-demo":
            CollectionView(game: game)
        case "solar":
            SolarSystemView(game: game)
        case "username":
            UsernameView(game: game) { }
        case "settings":
            SettingsView(game: game)
        case "battle-earth":
            BattleView(boss: BossDefinition.boss(id: "earth")!, game: game) { }
        // Debug routes to eyeball the other bosses' props/poses.
        case "battle-mars", "battle-uranus":
            BattleView(boss: BossDefinition.boss(id: "mars")!, game: game) { }
        case "battle-sun":
            BattleView(boss: BossDefinition.boss(id: "sun")!, game: game) { }
        // Debug route to eyeball the Animation Studio (onion skin, speed toggle).
        case "studio":
            AnimationStudioView(studio: studioState, onBack: { })
        default:
            HomeHubView(game: game, studio: studioState)
        }
    }
}

#Preview {
    ContentView()
}
