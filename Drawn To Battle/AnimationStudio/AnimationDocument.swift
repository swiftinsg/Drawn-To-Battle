import SwiftUI
import Combine
import Foundation



struct AnimationFrame: Codable, Equatable, Identifiable {
    var id: UUID
    var pose: StickmanPose

    var hold: Int

    init(id: UUID = UUID(), pose: StickmanPose, hold: Int = 0) {
        self.id = id
        self.pose = pose
        self.hold = hold
    }
}


struct AnimationProject: Codable, Equatable {
    var name: String
    var frames: [AnimationFrame]
    var fps: Int


    static var defaultFPS: Int {
        UserDefaults.standard.object(forKey: "DrawnToBattle.defaultFPS") as? Int ?? 12
    }

    static func blank() -> AnimationProject {
        AnimationProject(name: "Untitled", frames: [AnimationFrame(pose: StickmanPose())], fps: defaultFPS)
    }
}

// MARK: - Store (save / load)

enum AnimationProjectStore {

    static var directory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("Animations", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static func listProjects() -> [(url: URL, name: String, modified: Date)] {
        let fm = FileManager.default
        let files = (try? fm.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.contentModificationDateKey])) ?? []
        return files
            .filter { $0.pathExtension == "dtb" }
            .map { url in
                let name = url.deletingPathExtension().lastPathComponent
                let modified = (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                return (url, name, modified)
            }
            .sorted { $0.modified > $1.modified }
    }

    static func save(_ project: AnimationProject) throws -> URL {
        let url = directory.appendingPathComponent("\(project.name).dtb")
        let data = try JSONEncoder().encode(project)
        try data.write(to: url, options: .atomic)
        return url
    }

    static func load(from url: URL) throws -> AnimationProject {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(AnimationProject.self, from: data)
    }

    static func delete(at url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
}

// MARK: - Observable studio state

/// Observable state shared across the studio views.
final class StudioState: ObservableObject {
    @Published var project: AnimationProject
    /// Index of the frame currently being edited.
    @Published var selectedIndex: Int {
        didSet { clampSelection() }
    }

    /// Multi-select state for deleting a group of frames at once.
    @Published var isMultiSelecting = false
    @Published var selectedFrameIDs: Set<UUID> = []

    @Published var isPlaying = false

    @Published var hasUnsavedChanges = false

    @Published var onionSkin = false

    @Published var playbackSpeed: Double = 1

    @Published var editingBlueprintID: String?

    /// Per-blueprint "how to animate" lesson, shown when an unlearned move is
    /// opened. The blueprint is only marked learned when the lesson is finished.
    @Published var showBlueprintTutorial = false

    /// The blueprint currently open in the studio, if any.
    var editingBlueprint: MoveBlueprint? {
        editingBlueprintID.flatMap { BlueprintCatalog.blueprint(id: $0) }
    }

    var game: GameSave?

    private var playbackTimer: Timer?
    private var playbackFrameIndex = 0
    private var playbackHoldCounter = 0
    /// Debounced write so continuous dragging does not hammer the filesystem.
    private var autosaveWorkItem: DispatchWorkItem?

    init(project: AnimationProject = .blank()) {
        self.project = project
        self.selectedIndex = 0
        self.onionSkin = UserDefaults.standard.bool(forKey: "DrawnToBattle.defaultOnionSkin")
    }


    var currentFrame: AnimationFrame? {
        guard project.frames.indices.contains(selectedIndex) else { return nil }
        return project.frames[selectedIndex]
    }

    func updateCurrentPose(_ transform: (inout StickmanPose) -> Void) {
        guard project.frames.indices.contains(selectedIndex) else { return }
        var pose = project.frames[selectedIndex].pose
        transform(&pose)
        project.frames[selectedIndex].pose = pose
        markAnimatedChange()
    }



    func addFrame() {
        let pose = currentFrame?.pose ?? StickmanPose()
        let insertAt = min(selectedIndex + 1, project.frames.count)
        project.frames.insert(AnimationFrame(pose: pose), at: insertAt)
        selectedIndex = insertAt
        markAnimatedChange()
    }

    func duplicateFrame(at index: Int) {
        guard project.frames.indices.contains(index) else { return }
        var copy = project.frames[index]
        copy.id = UUID()
        project.frames.insert(copy, at: index + 1)
        selectedIndex = index + 1
        markAnimatedChange()
    }

    func deleteFrame(at index: Int) {
        guard project.frames.count > 1, project.frames.indices.contains(index) else { return }
        let id = project.frames[index].id
        project.frames.remove(at: index)
        selectedFrameIDs.remove(id)
        clampSelection()
        markAnimatedChange()
    }

    /// Enter or leave multi-select. Leaving clears the checked frames.
    func setMultiSelecting(_ enabled: Bool) {
        isMultiSelecting = enabled
        if !enabled { selectedFrameIDs.removeAll() }
    }

    /// Toggle a frame's checkmark while multi-select is active.
    func toggleFrameSelection(_ id: UUID) {
        guard isMultiSelecting else { return }
        if selectedFrameIDs.contains(id) {
            selectedFrameIDs.remove(id)
        } else {
            selectedFrameIDs.insert(id)
        }
    }

    /// Delete every checked frame, always keeping at least one frame left.
    func deleteSelectedFrames() {
        guard isMultiSelecting, !selectedFrameIDs.isEmpty else { return }
        let ids = selectedFrameIDs
        let remaining = project.frames.filter { !ids.contains($0.id) }
        guard !remaining.isEmpty else { return }
        project.frames = remaining
        if !remaining.indices.contains(selectedIndex) {
            selectedIndex = min(selectedIndex, remaining.count - 1)
        }
        selectedFrameIDs.removeAll()
        markAnimatedChange()
    }

    func moveFrame(from source: Int, to destination: Int) {
        guard project.frames.indices.contains(source) else { return }
        let dest = max(0, min(destination, project.frames.count - 1))
        let frame = project.frames.remove(at: source)
        project.frames.insert(frame, at: dest)
        selectedIndex = dest
        markAnimatedChange()
    }

    func selectFrame(_ index: Int) {
        guard project.frames.indices.contains(index) else { return }
        selectedIndex = index
        if !isMultiSelecting { selectedFrameIDs.removeAll() }
    }

    private func clampSelection() {
        if !project.frames.indices.contains(selectedIndex) {
            selectedIndex = max(0, project.frames.count - 1)
        }
        let validIDs = Set(project.frames.map(\.id))
        selectedFrameIDs = selectedFrameIDs.filter { validIDs.contains($0) }
    }

    // MARK: Playback

    func play() {
        guard !isPlaying, !project.frames.isEmpty else { return }
        isPlaying = true
        playbackFrameIndex = 0
        playbackHoldCounter = 0
        let interval = 1.0 / (Double(max(1, project.fps)) * playbackSpeed)
        playbackTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.tickPlayback()
        }
    }


    func cyclePlaybackSpeed() {
        if playbackSpeed == 1 { playbackSpeed = 2 }
        else if playbackSpeed == 2 { playbackSpeed = 0.5 }
        else { playbackSpeed = 1 }
        // Restart playback at the new speed if it's running.
        if isPlaying {
            stop()
            play()
        }
    }

    func stop() {
        isPlaying = false
        playbackTimer?.invalidate()
        playbackTimer = nil
    }

    private func tickPlayback() {
        guard let frame = project.frames[safe: playbackFrameIndex] else {
            playbackFrameIndex = 0
            return
        }
        selectedIndex = playbackFrameIndex
        if playbackHoldCounter < frame.hold {
            playbackHoldCounter += 1
        } else {
            playbackHoldCounter = 0
            playbackFrameIndex += 1
            if playbackFrameIndex >= project.frames.count {
                playbackFrameIndex = 0   // loop
            }
        }
    }



    // MARK: Autosave

    /// Pose and frame edits save themselves. The delay keeps a drag from
    /// writing a file on every touch move.
    private func markAnimatedChange() {
        hasUnsavedChanges = true
        game?.hasAnimated = true
        scheduleAutosave()
    }

    /// Name and FPS edits are saved too, but do not unlock battles.
    func markProjectChanged() {
        hasUnsavedChanges = true
        scheduleAutosave()
    }

    private func scheduleAutosave() {
        autosaveWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            _ = try? self.persistProject()
            self.hasUnsavedChanges = false
        }
        autosaveWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45, execute: work)
    }

    private func cancelAutosave() {
        autosaveWorkItem?.cancel()
        autosaveWorkItem = nil
    }

    private func persistProject() throws -> URL? {
        if let blueprintID = editingBlueprintID, let game {
            game.setBlueprintEdit(blueprintID, project: project)
            return nil
        }
        return try AnimationProjectStore.save(project)
    }

    /// Writes immediately when the studio closes, so the last edit survives.
    func flushAutosave() {
        guard hasUnsavedChanges else { return }
        cancelAutosave()
        _ = try? persistProject()
        hasUnsavedChanges = false
    }

    @discardableResult
    func save() throws -> URL? {
        stop()
        cancelAutosave()
        let url = try persistProject()
        hasUnsavedChanges = false
        return url
    }

    func editBlueprint(_ blueprint: MoveBlueprint, edited: AnimationProject?) {
        stop()
        cancelAutosave()
        // A move you haven't learned opens as a blank canvas with its lesson.
        // Finishing the lesson marks it learned; closing early leaves it locked.
        let unlearned = !(game?.isBlueprintLearned(blueprint.id) ?? true)
        showBlueprintTutorial = unlearned

        project = edited ?? (unlearned ? .blank() : blueprint.baseAnimation)
        editingBlueprintID = blueprint.id
        selectedIndex = 0
        hasUnsavedChanges = false
    }

    func load(from url: URL) throws {
        stop()
        cancelAutosave()
        let loaded = try AnimationProjectStore.load(from: url)
        project = loaded
        selectedIndex = 0
        hasUnsavedChanges = false
        editingBlueprintID = nil
    }

    func newProject() {
        stop()
        cancelAutosave()
        project = .blank()
        selectedIndex = 0
        hasUnsavedChanges = false
        editingBlueprintID = nil
    }

    // MARK: Clipboard

    /// Frame copy-pasted into the studio (or nil when there is none).
    @Published var pastedFrame: AnimationFrame?

    func copySelectedFrame() {
        pastedFrame = currentFrame
    }

    func pasteFrame() {
        guard let frame = pastedFrame, project.frames.indices.contains(selectedIndex) else { return }
        var copy = frame
        copy.id = UUID()
        project.frames.insert(copy, at: selectedIndex + 1)
        selectedIndex = min(selectedIndex + 1, project.frames.count - 1)
        hasUnsavedChanges = true
        game?.hasAnimated = true
    }

    // MARK: Timeline readouts

    /// Duration the selected frame is held, in seconds (hold ticks at fps).
    var currentFrameDuration: TimeInterval {
        guard project.frames.indices.contains(selectedIndex), project.fps > 0 else { return 0 }
        return TimeInterval(max(0, project.frames[selectedIndex].hold)) / TimeInterval(project.fps)
    }

    /// Time the selected frame starts, in seconds from the start of the project.
    var currentFrameStartTime: TimeInterval {
        guard project.frames.indices.contains(selectedIndex) else { return 0 }
        let fps = TimeInterval(max(1, project.fps))
        return Array(project.frames[..<selectedIndex]).reduce(0.0) { acc, f in
            acc + TimeInterval(max(0, f.hold)) / fps
        }
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
