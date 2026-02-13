import SwiftUI
import SceneKit

// MARK: - Content View
struct ContentView: View {
    @StateObject private var vm = GameViewModel()
    
    var body: some View {
        ZStack {
            Color(nsColor: GameConstants.bgColor).ignoresSafeArea()
            
            if vm.showStartScreen {
                StartScreen(vm: vm)
            } else {
                mainGameView
            }
            
            if vm.showWaveCompleteOverlay { WaveCompleteOverlay(vm: vm) }
            if vm.showFailOverlay { FailOverlay(vm: vm) }
        }
    }
    
    private var mainGameView: some View {
        VStack(spacing: 0) {
            TopBar(vm: vm)
            HStack(spacing: 0) {
                LeftPanel(vm: vm).frame(width: 300)
                Rectangle().fill(Color.white.opacity(0.06)).frame(width: 1)
                Game3DView(gameScene: vm.game3DScene, vm: vm)
            }
            StatusBar(vm: vm)
        }
    }
}

// MARK: - 3D Game View
struct Game3DView: NSViewRepresentable {
    let gameScene: Game3DScene
    @ObservedObject var vm: GameViewModel
    
    func makeNSView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = gameScene.scene
        scnView.allowsCameraControl = false
        scnView.showsStatistics = false
        scnView.backgroundColor = NSColor(red: 0.02, green: 0.04, blue: 0.06, alpha: 1)
        scnView.antialiasingMode = .multisampling4X
        
        // Enable click handling
        let clickGesture = NSClickGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleClick(_:)))
        scnView.addGestureRecognizer(clickGesture)
        
        // Enable right-click
        let rightClickGesture = NSClickGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleRightClick(_:)))
        rightClickGesture.buttonMask = 0x2
        scnView.addGestureRecognizer(rightClickGesture)
        
        // Pan gesture for camera rotation
        let panGesture = NSPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        scnView.addGestureRecognizer(panGesture)
        
        // Scroll for zoom
        context.coordinator.scnView = scnView
        
        return scnView
    }
    
    func updateNSView(_ nsView: SCNView, context: Context) {
        // Update scene if needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(gameScene: gameScene, vm: vm)
    }
    
    class Coordinator: NSObject {
        let gameScene: Game3DScene
        let vm: GameViewModel
        weak var scnView: SCNView?
        
        init(gameScene: Game3DScene, vm: GameViewModel) {
            self.gameScene = gameScene
            self.vm = vm
        }
        
        @objc func handleClick(_ gesture: NSClickGestureRecognizer) {
            guard let scnView = scnView else { return }
            let location = gesture.location(in: scnView)
            
            let hitResults = scnView.hitTest(location, options: [
                .searchMode: SCNHitTestSearchMode.closest.rawValue
            ])
            
            if let hit = hitResults.first {
                let worldPos = hit.worldCoordinates
                let gridPos = gameScene.worldToGrid(worldPos)
                
                switch gameScene.gameState {
                case .running, .paused:
                    gameScene.toggleToolAt(gridPos: gridPos)
                case .idle:
                    if let toolType = vm.selectedToolType {
                        gameScene.placeTool(toolType, at: gridPos)
                    }
                default:
                    break
                }
            }
        }
        
        @objc func handleRightClick(_ gesture: NSClickGestureRecognizer) {
            guard let scnView = scnView else { return }
            guard case .idle = gameScene.gameState else { return }
            
            let location = gesture.location(in: scnView)
            let hitResults = scnView.hitTest(location, options: nil)
            
            if let hit = hitResults.first {
                let worldPos = hit.worldCoordinates
                let gridPos = gameScene.worldToGrid(worldPos)
                gameScene.removeTool(at: gridPos)
            }
        }
        
        @objc func handlePan(_ gesture: NSPanGestureRecognizer) {
            let translation = gesture.translation(in: scnView)
            gameScene.rotateCamera(by: translation.x * 0.01)
            gesture.setTranslation(.zero, in: scnView)
        }
    }
}

// MARK: - Start Screen
struct StartScreen: View {
    @ObservedObject var vm: GameViewModel
    var body: some View {
        VStack(spacing: 20) {
            // 3D Train icon
            Text("🚂").font(.system(size: 80))
                .shadow(color: Color(nsColor: GameConstants.accentGreen).opacity(0.5), radius: 20)
            
            Text("RAILWAY.engineer")
                .font(.custom("Menlo-Bold", size: 48))
                .foregroundColor(Color(nsColor: GameConstants.accentGreen))
            
            Text("철도 안정화 시뮬레이션")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.gray)
            
            Text("\"플레이어는 기차를 조작하는 사람이 아니라,\n철도 시스템을 안정화하는 엔지니어다.\"")
                .font(.system(size: 15))
                .foregroundColor(.gray.opacity(0.8))
                .italic()
                .multilineTextAlignment(.center)
                .padding(.vertical, 16)
            
            Button(action: { vm.startGame() }) {
                HStack {
                    Text("시스템 접속")
                        .font(.custom("Menlo-Bold", size: 18))
                    Image(systemName: "arrow.right")
                }
                .foregroundColor(.black)
                .padding(.horizontal, 56)
                .padding(.vertical, 16)
                .background(Color(nsColor: GameConstants.accentGreen))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .shadow(color: Color(nsColor: GameConstants.accentGreen).opacity(0.4), radius: 15)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RadialGradient(
                colors: [
                    Color(nsColor: GameConstants.accentGreen).opacity(0.1),
                    Color.clear
                ],
                center: .center,
                startRadius: 100,
                endRadius: 400
            )
        )
    }
}

// MARK: - Top Bar
struct TopBar: View {
    @ObservedObject var vm: GameViewModel
    var body: some View {
        HStack {
            HStack(spacing: 0) {
                Text("RAILWAY")
                    .font(.custom("Menlo-Bold", size: 20))
                    .foregroundColor(Color(nsColor: GameConstants.accentGreen))
                Text(".engineer")
                    .font(.custom("Menlo", size: 20))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                Text("WAVE \(vm.currentWave)")
                    .font(.custom("Menlo-Bold", size: 14))
                    .foregroundColor(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color(nsColor: GameConstants.accentGreen))
                    .cornerRadius(6)
                
                Text(vm.waveTitle)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                Text("총 통과: \(vm.totalTrainsPassed)")
                    .font(.custom("Menlo", size: 12))
                    .foregroundColor(Color(nsColor: GameConstants.accentYellow))
            }
            
            Spacer()
            
            HStack(spacing: 10) {
                // Speed buttons
                HStack(spacing: 4) {
                    ForEach([1, 2, 3], id: \.self) { speed in
                        Button("\(speed)×") {
                            vm.setSpeed(CGFloat(speed))
                        }
                        .font(.custom("Menlo-Bold", size: 11))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(vm.simSpeed == CGFloat(speed) ?
                            Color(nsColor: GameConstants.accentGreen) : Color.clear)
                        .foregroundColor(vm.simSpeed == CGFloat(speed) ? .black : .gray)
                        .cornerRadius(5)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                    }
                }
                
                Button(action: { vm.toggleSimulation() }) {
                    HStack(spacing: 6) {
                        Image(systemName: vm.isRunning ? "pause.fill" : "play.fill")
                        Text(vm.isRunning ? "PAUSE" : "RUN")
                    }
                    .font(.custom("Menlo-Bold", size: 13))
                    .foregroundColor(.black)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color(nsColor: GameConstants.accentGreen))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                
                Button(action: { vm.resetCurrentWave() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("RETRY")
                    }
                    .font(.custom("Menlo", size: 12))
                    .foregroundColor(Color(nsColor: GameConstants.accentRed))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(nsColor: GameConstants.accentRed), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                
                Button(action: { vm.fullReset() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.uturn.backward")
                        Text("RESTART")
                    }
                    .font(.custom("Menlo", size: 12))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 14)
        .background(Color(red: 0.06, green: 0.08, blue: 0.11))
    }
}

// MARK: - Left Panel
struct LeftPanel: View {
    @ObservedObject var vm: GameViewModel
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Current Wave Info
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 10) {
                        Text("🚂")
                            .font(.system(size: 16))
                        Text("WAVE \(vm.currentWave)")
                            .font(.custom("Menlo-Bold", size: 14))
                            .foregroundColor(Color(nsColor: GameConstants.accentGreen))
                            .tracking(2)
                    }
                    
                    Text(vm.waveTitle)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(vm.waveDescription)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .lineSpacing(4)
                        .padding(.top, 4)
                    
                    // Progress
                    HStack {
                        Text("진행:")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        Text("\(vm.trainsPassed) / \(vm.requiredPasses)")
                            .font(.custom("Menlo-Bold", size: 14))
                            .foregroundColor(Color(nsColor: GameConstants.accentGreen))
                        Spacer()
                    }
                    .padding(.top, 8)
                }
                .padding(22)
                .background(Color(nsColor: GameConstants.accentGreen).opacity(0.05))
                .cornerRadius(10)
                
                Divider().background(Color.white.opacity(0.08))
                
                // Tools
                VStack(alignment: .leading, spacing: 14) {
                    Text("AVAILABLE TOOLS")
                        .font(.custom("Menlo-Bold", size: 12))
                        .foregroundColor(Color(nsColor: GameConstants.accentBlue))
                        .tracking(2)
                    
                    ForEach(Array(vm.toolSlots.enumerated()), id: \.element.id) { _, slot in
                        ToolItemView(slot: slot, isSelected: vm.selectedToolType == slot.type) {
                            vm.selectTool(slot.type)
                        }
                    }
                }
                .padding(22)
                
                Divider().background(Color.white.opacity(0.08))
                
                // System Status
                VStack(alignment: .leading, spacing: 14) {
                    Text("SYSTEM STATUS")
                        .font(.custom("Menlo-Bold", size: 12))
                        .foregroundColor(Color(nsColor: GameConstants.accentBlue))
                        .tracking(2)
                    
                    StatusRow(label: "Trains Passed",
                              value: "\(vm.trainsPassed) / \(vm.requiredPasses)",
                              color: Color(nsColor: GameConstants.accentGreen))
                    StatusRow(label: "Collisions",
                              value: "\(vm.collisionCount)",
                              color: Color(nsColor: GameConstants.accentRed))
                    StatusRow(label: "Derailments",
                              value: "\(vm.derailmentCount)",
                              color: Color(nsColor: GameConstants.accentOrange))
                }
                .padding(22)
                
                Spacer()
            }
        }
        .background(Color(red: 0.06, green: 0.08, blue: 0.11))
    }
}

struct ToolItemView: View {
    let slot: ToolSlot
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(slot.type.icon)
                    .font(.system(size: 24))
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(slot.type.displayName)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    Text(slot.type.description)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Text("×\(slot.remaining)")
                    .font(.custom("Menlo-Bold", size: 14))
                    .foregroundColor(slot.remaining == 0 ?
                        Color(nsColor: GameConstants.accentRed) :
                        Color(nsColor: GameConstants.accentYellow))
            }
            .padding(14)
            .background(isSelected ?
                Color(nsColor: GameConstants.accentGreen).opacity(0.1) :
                Color(red: 0.08, green: 0.11, blue: 0.16))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ?
                        Color(nsColor: GameConstants.accentGreen) :
                        Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

struct StatusRow: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.custom("Menlo-Bold", size: 14))
                .foregroundColor(color)
        }
    }
}

// MARK: - Status Bar
struct StatusBar: View {
    @ObservedObject var vm: GameViewModel
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Circle()
                    .fill(vm.statusColor)
                    .frame(width: 8, height: 8)
                Text(vm.statusText)
                    .font(.custom("Menlo", size: 12))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            HStack(spacing: 20) {
                Text("드래그: 카메라 회전")
                    .font(.custom("Menlo", size: 11))
                    .foregroundColor(.gray.opacity(0.6))
                
                Text("좌클릭: 도구 배치 | 우클릭: 도구 제거")
                    .font(.custom("Menlo", size: 11))
                    .foregroundColor(.gray.opacity(0.6))
            }
            
            Spacer()
            
            Text(vm.formattedTimer)
                .font(.custom("Menlo-Bold", size: 12))
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 10)
        .background(Color(red: 0.06, green: 0.08, blue: 0.11))
    }
}

// MARK: - Wave Complete Overlay
struct WaveCompleteOverlay: View {
    @ObservedObject var vm: GameViewModel
    var body: some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("✅")
                    .font(.system(size: 64))
                    .shadow(color: Color(nsColor: GameConstants.accentGreen).opacity(0.5), radius: 20)
                
                Text("WAVE \(vm.currentWave) CLEAR!")
                    .font(.system(size: 28, weight: .black))
                    .foregroundColor(Color(nsColor: GameConstants.accentGreen))
                
                Text(vm.waveTitle)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                
                HStack(spacing: 30) {
                    VStack {
                        Text("이번 웨이브")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        Text("\(vm.trainsPassed)대")
                            .font(.custom("Menlo-Bold", size: 20))
                            .foregroundColor(Color(nsColor: GameConstants.accentGreen))
                    }
                    VStack {
                        Text("총 통과")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        Text("\(vm.totalTrainsPassed)대")
                            .font(.custom("Menlo-Bold", size: 20))
                            .foregroundColor(Color(nsColor: GameConstants.accentYellow))
                    }
                }
                .padding(.vertical, 10)
                
                Text("다음 웨이브 준비 중...")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .italic()
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color(nsColor: GameConstants.accentGreen)))
                    .scaleEffect(1.2)
            }
            .padding(48)
            .background(Color(red: 0.06, green: 0.08, blue: 0.11).opacity(0.95))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(nsColor: GameConstants.accentGreen).opacity(0.3), lineWidth: 1)
            )
            .shadow(color: Color(nsColor: GameConstants.accentGreen).opacity(0.2), radius: 30)
        }
    }
}

// MARK: - Fail Overlay
struct FailOverlay: View {
    @ObservedObject var vm: GameViewModel
    var body: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("💥")
                    .font(.system(size: 72))
                    .shadow(color: Color(nsColor: GameConstants.accentRed).opacity(0.5), radius: 20)
                
                Text("SYSTEM FAILURE")
                    .font(.system(size: 32, weight: .black))
                    .foregroundColor(Color(nsColor: GameConstants.accentRed))
                
                Text("WAVE \(vm.currentWave) 실패")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                
                Text(vm.failMessage)
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 20) {
                    Button(action: { vm.resetCurrentWave() }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("이 웨이브 재시도")
                        }
                        .font(.custom("Menlo-Bold", size: 14))
                        .foregroundColor(Color(nsColor: GameConstants.accentRed))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(nsColor: GameConstants.accentRed), lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { vm.fullReset() }) {
                        HStack {
                            Image(systemName: "arrow.uturn.backward")
                            Text("처음부터")
                        }
                        .font(.custom("Menlo-Bold", size: 14))
                        .foregroundColor(.gray)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(56)
            .background(Color(red: 0.06, green: 0.08, blue: 0.11))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(nsColor: GameConstants.accentRed).opacity(0.3), lineWidth: 1)
            )
        }
    }
}

#Preview {
    ContentView().frame(width: 1400, height: 900)
}
