import SwiftUI
import Combine

// MARK: - Frame

/// One frame of a stickman animation.
struct AnimationFrame: Codable, Equatable, Identifiable {
    var id: UUID
    var pose: StickmanPose
    /// Extra frames this frame holds during playback (0 = 1 display tick).
    var hold: Int

    init(id: UUID = UUID(), pose: StickmanPose, hold: Int = 0) {
        self.id = id
        self.pose = pose
        self.hold = hold
    }
}

// MARK: - Project document

/// The whole animation project: frames plus playback settings.
struct AnimationProject: Codable, Equatable {
    var name: String
    var frames: [AnimationFrame]
    var fps: Int

    static let defaultFPS = 12

    static func blank() -> AnimationProject {
        AnimationProject(name: "Untitled", frames: [AnimationFrame(pose: StickmanPose())], fps: defaultFPS)
    }
}

// MARK: - Store (save / load)

enum AnimationProjectStore {
    /// Documents/Animations directory inside the app sandbox.
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
    /// Whether playback is running.
    @Published var isPlaying = false
    /// Whether the project has unsaved changes.
    @Published var hasUnsavedChanges = false
    /// Onion skinning: draw faded ghosts of the previous frames.
    @Published var onionSkin = false
    /// Playback speed multiplier (0.5 / 1 / 2).
    @Published var playbackSpeed: Double = 1
    /// Set while editing a blueprint's animation. Saving then stores the
    /// customization on the blueprint instead of a separate project file.
    @Published var editingBlueprintID: String?
    /// The game save used to persist blueprint edits. Assigned by the screens
    /// that present the studio.
    var game: GameSave?

    private var playbackTimer: Timer?
    private var playbackFrameIndex = 0
    private var playbackHoldCounter = 0

    init(project: AnimationProject = .blank()) {
        self.project = project
        self.selectedIndex = 0
    }

    // MARK: Editing

    var currentFrame: AnimationFrame? {
        guard project.frames.indices.contains(selectedIndex) else { return nil }
        return project.frames[selectedIndex]
    }

    func updateCurrentPose(_ transform: (inout StickmanPose) -> Void) {
        guard project.frames.indices.contains(selectedIndex) else { return }
        var pose = project.frames[selectedIndex].pose
        transform(&pose)
        project.frames[selectedIndex].pose = pose
        hasUnsavedChanges = true
    }

    // MARK: Frame management

    func addFrame() {
        // New frames copy the current pose so animators can tweak incrementally.
        let pose = currentFrame?.pose ?? StickmanPose()
        let insertAt = min(selectedIndex + 1, project.frames.count)
        project.frames.insert(AnimationFrame(pose: pose), at: insertAt)
        selectedIndex = insertAt
        hasUnsavedChanges = true
    }

    func duplicateFrame(at index: Int) {
        guard project.frames.indices.contains(index) else { return }
        var copy = project.frames[index]
        copy.id = UUID()
        project.frames.insert(copy, at: index + 1)
        selectedIndex = index + 1
        hasUnsavedChanges = true
    }

    func deleteFrame(at index: Int) {
        guard project.frames.count > 1, project.frames.indices.contains(index) else { return }
        project.frames.remove(at: index)
        clampSelection()
        hasUnsavedChanges = true
    }

    func moveFrame(from source: Int, to destination: Int) {
        guard project.frames.indices.contains(source) else { return }
        let dest = max(0, min(destination, project.frames.count - 1))
        let frame = project.frames.remove(at: source)
        project.frames.insert(frame, at: dest)
        selectedIndex = dest
        hasUnsavedChanges = true
    }

    func selectFrame(_ index: Int) {
        guard project.frames.indices.contains(index) else { return }
        selectedIndex = index
    }

    private func clampSelection() {
        if !project.frames.indices.contains(selectedIndex) {
            selectedIndex = max(0, project.frames.count - 1)
        }
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

    /// Cycles playback speed 1× → 2× → ½×.
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

    // MARK: Save / load

    @discardableResult
    func save() throws -> URL? {
        stop()
        hasUnsavedChanges = false
        // Editing a blueprint: store the customization on the blueprint itself.
        if let blueprintID = editingBlueprintID, let game {
            game.setBlueprintEdit(blueprintID, project: project)
            return nil
        }
        return try AnimationProjectStore.save(project)
    }

    /// Loads a blueprint for editing: the player's previous edit if they have
    /// one, otherwise the blueprint's base animation.
    func editBlueprint(_ blueprint: MoveBlueprint, edited: AnimationProject?) {
        stop()
        project = edited ?? blueprint.baseAnimation
        editingBlueprintID = blueprint.id
        selectedIndex = 0
        hasUnsavedChanges = false
    }

    func load(from url: URL) throws {
        stop()
        let loaded = try AnimationProjectStore.load(from: url)
        project = loaded
        selectedIndex = 0
        hasUnsavedChanges = false
        editingBlueprintID = nil
    }

    func newProject() {
        stop()
        project = .blank()
        selectedIndex = 0
        hasUnsavedChanges = false
        editingBlueprintID = nil
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
