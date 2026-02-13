import SwiftUI
import SceneKit
import Combine

// MARK: - Game View Model
class GameViewModel: ObservableObject {
    
    // Wave System
    @Published var currentWave: Int = 0
    @Published var waveTitle: String = ""
    @Published var waveDescription: String = ""
    @Published var totalTrainsPassed: Int = 0
    
    // Published state
    @Published var gameState: GameState = .idle
    @Published var trainsPassed: Int = 0
    @Published var requiredPasses: Int = 3
    @Published var collisionCount: Int = 0
    @Published var derailmentCount: Int = 0
    @Published var timerSeconds: Int = 0
    @Published var simSpeed: CGFloat = 1
    
    @Published var selectedToolType: ToolType? = nil
    @Published var toolSlots: [ToolSlot] = []
    
    @Published var showStartScreen: Bool = true
    @Published var showWaveCompleteOverlay: Bool = false
    @Published var showFailOverlay: Bool = false
    @Published var failMessage: String = ""
    
    // 3D Scene
    let game3DScene: Game3DScene
    
    init() {
        game3DScene = Game3DScene()
        setupCallbacks()
    }
    
    private func setupCallbacks() {
        game3DScene.onStateChanged = { [weak self] state in
            self?.gameStateChanged(state)
        }
        game3DScene.onTrainsPassed = { [weak self] passed, required in
            self?.trainPassedUpdated(passed: passed, required: required)
        }
        game3DScene.onCollision = { [weak self] count in
            self?.collisionCountUpdated(count)
        }
        game3DScene.onDerailment = { [weak self] count in
            self?.derailmentCountUpdated(count)
        }
        game3DScene.onTimerUpdated = { [weak self] ticks in
            self?.timerUpdated(ticks)
        }
        game3DScene.onToolUsed = { [weak self] type, isPlacing in
            self?.handleToolUsed(type: type, isPlacing: isPlacing)
        }
        game3DScene.onWaveChanged = { [weak self] wave, title, description in
            self?.waveChanged(wave: wave, title: title, description: description)
        }
        game3DScene.onWaveComplete = { [weak self] wave in
            self?.waveComplete(wave: wave)
        }
    }
    
    // MARK: - Game Start
    
    func startGame() {
        showStartScreen = false
        game3DScene.startWaveMode()
    }
    
    func resetCurrentWave() {
        showFailOverlay = false
        showWaveCompleteOverlay = false
        game3DScene.resetLevel()
    }
    
    func fullReset() {
        showFailOverlay = false
        showWaveCompleteOverlay = false
        totalTrainsPassed = 0
        game3DScene.fullReset()
    }
    
    // MARK: - Simulation Control
    
    func toggleSimulation() {
        switch gameState {
        case .idle:
            game3DScene.startSimulation()
        case .running:
            game3DScene.pauseSimulation()
        case .paused:
            game3DScene.resumeSimulation()
        default:
            break
        }
    }
    
    func setSpeed(_ speed: CGFloat) {
        simSpeed = speed
        game3DScene.setSimSpeed(speed)
    }
    
    // MARK: - Tool Selection
    
    func selectTool(_ type: ToolType) {
        if selectedToolType == type {
            selectedToolType = nil
            game3DScene.selectedToolType = nil
        } else {
            if let slot = toolSlots.first(where: { $0.type == type }), slot.remaining > 0 {
                selectedToolType = type
                game3DScene.selectedToolType = type
            }
        }
    }
    
    private func handleToolUsed(type: ToolType, isPlacing: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            // 도구 슬롯은 game3DScene에서 관리하므로 동기화
            self.toolSlots = self.game3DScene.toolSlots
            
            if self.toolSlots.first(where: { $0.type == type })?.remaining ?? 0 <= 0 {
                if self.selectedToolType == type {
                    self.selectedToolType = nil
                    self.game3DScene.selectedToolType = nil
                }
            }
        }
    }
    
    // MARK: - Scene Callbacks
    
    func gameStateChanged(_ state: GameState) {
        DispatchQueue.main.async { [weak self] in
            self?.gameState = state
            switch state {
            case .success:
                // 웨이브 완료는 onWaveComplete에서 처리
                break
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
    
    func waveChanged(wave: Int, title: String, description: String) {
        DispatchQueue.main.async { [weak self] in
            self?.currentWave = wave
            self?.waveTitle = title
            self?.waveDescription = description
            self?.showWaveCompleteOverlay = false
            self?.toolSlots = self?.game3DScene.toolSlots ?? []
        }
    }
    
    func waveComplete(wave: Int) {
        DispatchQueue.main.async { [weak self] in
            self?.totalTrainsPassed += self?.trainsPassed ?? 0
            self?.showWaveCompleteOverlay = true
        }
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
        case .running: return "WAVE \(currentWave) 진행 중..."
        case .paused: return "PAUSED"
        case .success: return "WAVE \(currentWave) CLEAR! ✅"
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
