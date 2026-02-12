import SwiftUI
import SpriteKit
import Combine

// MARK: - Game View Model
class GameViewModel: ObservableObject, GameSceneDelegate {
    
    // Published state
    @Published var currentLevel: Int = 0
    @Published var maxUnlockedLevel: Int = 0
    @Published var gameState: GameState = .idle
    @Published var trainsPassed: Int = 0
    @Published var requiredPasses: Int = 3
    @Published var collisionCount: Int = 0
    @Published var derailmentCount: Int = 0
    @Published var timerSeconds: Int = 0
    @Published var simSpeed: CGFloat = 1
    
    @Published var selectedToolType: ToolType? = nil
    @Published var toolSlots: [ToolSlot] = []
    
    @Published var levelTitle: String = ""
    @Published var incidents: [IncidentItem] = []
    @Published var objective: String = ""
    
    @Published var showStartScreen: Bool = true
    @Published var showSuccessOverlay: Bool = false
    @Published var showFailOverlay: Bool = false
    @Published var failMessage: String = ""
    @Published var showLevelSelect: Bool = false
    
    // Scene
    let scene: GameScene
    
    init() {
        scene = GameScene(size: CGSize(width: 1000, height: 600))
        scene.scaleMode = .resizeFill
        scene.gameDelegate = self
        
        // Tool usage callback
        scene.onToolUsed = { [weak self] type, isPlacing in
            self?.handleToolUsed(type: type, isPlacing: isPlacing)
        }
        
        loadProgress()
    }
    
    // MARK: - Level Management
    
    func startGame() {
        showStartScreen = false
        loadLevel(0)
    }
    
    func loadLevel(_ index: Int) {
        currentLevel = index
        let def = LevelFactory.create(level: index)
        
        levelTitle = def.title
        incidents = def.incidents
        objective = def.objective
        requiredPasses = def.requiredPasses
        toolSlots = def.tools
        selectedToolType = nil
        
        scene.selectedToolType = nil
        scene.toolSlots = toolSlots
        scene.loadLevel(index: index)
        
        showSuccessOverlay = false
        showFailOverlay = false
    }
    
    func resetLevel() {
        showFailOverlay = false
        showSuccessOverlay = false
        loadLevel(currentLevel)
    }
    
    func nextLevel() {
        showSuccessOverlay = false
        if currentLevel + 1 < LevelFactory.totalLevels {
            loadLevel(currentLevel + 1)
        } else {
            showLevelSelect = true
        }
    }
    
    // MARK: - Simulation Control
    
    func toggleSimulation() {
        switch gameState {
        case .idle:
            scene.startSimulation()
        case .running:
            scene.pauseSimulation()
        case .paused:
            scene.resumeSimulation()
        default:
            break
        }
    }
    
    func setSpeed(_ speed: CGFloat) {
        simSpeed = speed
        scene.setSimSpeed(speed)
    }
    
    // MARK: - Tool Selection
    
    func selectTool(_ type: ToolType) {
        if selectedToolType == type {
            selectedToolType = nil
            scene.selectedToolType = nil
        } else {
            // Check remaining
            if let slot = toolSlots.first(where: { $0.type == type }), slot.remaining > 0 {
                selectedToolType = type
                scene.selectedToolType = type
            }
        }
    }
    
    private func handleToolUsed(type: ToolType, isPlacing: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let idx = self.toolSlots.firstIndex(where: { $0.type == type }) {
                if isPlacing {
                    self.toolSlots[idx].usedCount += 1
                } else {
                    self.toolSlots[idx].usedCount = max(0, self.toolSlots[idx].usedCount - 1)
                }
                
                // Deselect if no remaining
                if self.toolSlots[idx].remaining <= 0 && self.selectedToolType == type {
                    self.selectedToolType = nil
                    self.scene.selectedToolType = nil
                }
            }
        }
    }
    
    // MARK: - GameSceneDelegate
    
    func gameStateChanged(_ state: GameState) {
        DispatchQueue.main.async { [weak self] in
            self?.gameState = state
            switch state {
            case .success:
                self?.handleSuccess()
            case .fail(let msg):
                self?.failMessage = msg
                self?.showFailOverlay = true
            default:
                break
            }
        }
    }
    
    func trainPassedUpdated(passed: Int, required: Int) {
        DispatchQueue.main.async { [weak self] in
            self?.trainsPassed = passed
            self?.requiredPasses = required
        }
    }
    
    func collisionCountUpdated(_ count: Int) {
        DispatchQueue.main.async { [weak self] in
            self?.collisionCount = count
        }
    }
    
    func derailmentCountUpdated(_ count: Int) {
        DispatchQueue.main.async { [weak self] in
            self?.derailmentCount = count
        }
    }
    
    func timerUpdated(_ ticks: Int) {
        DispatchQueue.main.async { [weak self] in
            self?.timerSeconds = ticks
        }
    }
    
    // MARK: - Success / Progress
    
    private func handleSuccess() {
        if currentLevel >= maxUnlockedLevel {
            maxUnlockedLevel = currentLevel + 1
            saveProgress()
        }
        showSuccessOverlay = true
    }
    
    private func saveProgress() {
        UserDefaults.standard.set(maxUnlockedLevel, forKey: "railwayMaxLevel")
    }
    
    private func loadProgress() {
        maxUnlockedLevel = UserDefaults.standard.integer(forKey: "railwayMaxLevel")
    }
    
    // MARK: - Helpers
    
    var isRunning: Bool {
        if case .running = gameState { return true }
        return false
    }
    
    var isPaused: Bool {
        if case .paused = gameState { return true }
        return false
    }
    
    var statusText: String {
        switch gameState {
        case .idle: return "READY — 도구를 배치하고 RUN을 누르세요"
        case .running: return "RUNNING — 시뮬레이션 진행 중..."
        case .paused: return "PAUSED"
        case .success: return "SYSTEM STABILIZED ✅"
        case .fail: return "SYSTEM FAILURE ❌"
        }
    }
    
    var statusColor: Color {
        switch gameState {
        case .idle: return .green
        case .running: return .yellow
        case .paused: return .yellow
        case .success: return .green
        case .fail: return .red
        }
    }
    
    var formattedTimer: String {
        let secs = timerSeconds
        let m = secs / 60
        let s = secs % 60
        return String(format: "%02d:%02d", m, s)
    }
}
