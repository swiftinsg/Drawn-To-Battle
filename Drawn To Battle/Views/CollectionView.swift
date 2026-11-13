import SwiftUI

// MARK: - Collection + loadout

struct CollectionView: View {
    @ObservedObject var game: GameSave
    @Environment(\.dismiss) private var dismiss

    @StateObject private var editStudio = StudioState()
    @State private var editingBlueprint: MoveBlueprint?

    var body: some View {
        ZStack {
            Color(hex: 0x0C0D12).ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar.
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 32)
                            .background(RoundedRectangle(cornerRadius: 9).fill(Color.white.opacity(0.08)))
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    Text("COLLECTION")
                        .font(DrawnToBattleTypography.display(20))
                        .foregroundStyle(.white)
                    Spacer()
                    Text("\(game.ownedBlueprints.count)/\(BlueprintCatalog.all.count)")
                        .font(.system(size: 13, weight: .heavy, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        // Equipped.
                        equippedSection

                        // Blueprints by rarity.
                        ForEach(Rarity.allCases.reversed(), id: \.self) { rarity in
                            let bps = BlueprintCatalog.blueprints(in: rarity)
                            if !bps.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 6) {
                                        Circle().fill(rarity.color).frame(width: 9, height: 9)
                                        Text(rarity.label)
                                            .font(.system(size: 12, weight: .black, design: .rounded))
                                            .foregroundStyle(rarity.color)
                                        Spacer()
                                        Text("\(String(format: "%.0f", rarity.weight))%")
                                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                            .foregroundStyle(.white.opacity(0.35))
                                    }
                                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                        ForEach(bps) { bp in
                                            BlueprintCell(
                                                bp: bp,
                                                owned: game.ownedBlueprints.contains(bp.id),
                                                equipped: isEquipped(bp),
                                                edited: game.blueprintEdit(id: bp.id) != nil,
                                                onEdit: { editingBlueprint = bp },
                                                onReset: { game.clearBlueprintEdit(bp.id) }
                                            ) {
                                                if game.ownedBlueprints.contains(bp.id) {
                                                    game.equip(blueprint: bp)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Studio animations.
                        studioSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
            }
        }
        .fullScreenCover(item: $editingBlueprint) { bp in
            AnimationStudioView(studio: editStudio, onBack: { editingBlueprint = nil })
                .onAppear {
                    editStudio.game = game
                    editStudio.editBlueprint(bp, edited: game.blueprintEdit(id: bp.id))
                }
        }
    }

    private var equippedSection: some View {
        Group {
            if let equipped = game.equipped {
                let analysis = AnimationAnalysis.analyze(equipped.project)
                VStack(alignment: .leading, spacing: 6) {
                    Text("CURRENT LOADOUT")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white.opacity(0.45))
                    HStack {
                        Text(sourceName(equipped.source))
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        Spacer()
                        Text("POWER \(Int(analysis.power))")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundStyle(Color(hex: 0xF5C451))
                    }
                    HStack(spacing: 6) {
                        ForEach(analysis.techniques.sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { tech in
                            Text(tech.label)
                                .font(.system(size: 10, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color.white.opacity(0.1)))
                        }
                        if analysis.techniques.isEmpty {
                            Text("No technique detected")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
            } else {
                Text("No attack equipped — pull a blueprint or equip a Studio animation")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.45))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.04)))
            }
        }
    }

    private var studioSection: some View {
        let projects = AnimationProjectStore.listProjects()
        return VStack(alignment: .leading, spacing: 8) {
            Text("MY ANIMATIONS")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
            if projects.isEmpty {
                Text("Create an animation in the Studio, save it, then equip it here.")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))
            }
            ForEach(projects, id: \.url) { item in
                Button {
                    if let project = try? AnimationProjectStore.load(from: item.url) {
                        game.equip(project: project)
                    }
                } label: {
                    HStack {
                        Image(systemName: "film")
                            .foregroundStyle(Color(hex: 0xF5C451))
                        Text(item.name)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Spacer()
                        if case .studio(let name) = game.equipped?.source, name == item.name {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color(hex: 0xF5C451))
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.05)))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func isEquipped(_ bp: MoveBlueprint) -> Bool {
        if case .blueprint(let id) = game.equipped?.source { return id == bp.id }
        return false
    }

    private func sourceName(_ source: LoadoutSource) -> String {
        switch source {
        case .blueprint(let id):
            var name = BlueprintCatalog.blueprint(id: id)?.name ?? "Blueprint"
            if game.blueprintEdits[id] != nil { name += " (edited)" }
            return name
        case .studio(let name): return "\"\(name)\" (custom)"
        }
    }
}

// MARK: - Blueprint cell

private struct BlueprintCell: View {
    let bp: MoveBlueprint
    let owned: Bool
    let equipped: Bool
    let edited: Bool
    let onEdit: () -> Void
    let onReset: () -> Void
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 4) {
                    Text(String(repeating: "★", count: bp.rarity.stars))
                        .font(.system(size: 7, weight: .black))
                        .foregroundStyle(bp.rarity.color)
                    Spacer()
                    if equipped {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Color(hex: 0xF5C451))
                    }
                }
                Text(owned ? bp.name : "???")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(owned ? .white : .white.opacity(0.35))
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Text(bp.technique.label)
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundStyle(owned ? bp.rarity.color : .white.opacity(0.3))
                    Spacer()
                    if edited {
                        Text("EDITED")
                            .font(.system(size: 7, weight: .black, design: .rounded))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color(hex: 0xA86CFF)))
                    }
                }
                if owned {
                    HStack(spacing: 4) {
                        Button(action: onEdit) {
                            Label("EDIT", systemImage: "pencil")
                                .font(.system(size: 8, weight: .black, design: .rounded))
                                .foregroundStyle(Color(hex: 0xF5C451))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color(hex: 0xF5C451).opacity(0.16)))
                        }
                        .buttonStyle(.plain)
                        if edited {
                            Button(action: onReset) {
                                Label("RESET", systemImage: "arrow.counterclockwise")
                                    .font(.system(size: 8, weight: .black, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.65))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Capsule().fill(Color.white.opacity(0.08)))
                            }
                            .buttonStyle(.plain)
                        }
                        Spacer()
                    }
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(owned ? 0.07 : 0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(owned ? bp.rarity.color.opacity(0.55) : Color.white.opacity(0.08), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}
