import SwiftUI
import SpriteKit

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
            
            if vm.showSuccessOverlay { SuccessOverlay(vm: vm) }
            if vm.showFailOverlay { FailOverlay(vm: vm) }
            if vm.showLevelSelect { LevelSelectOverlay(vm: vm) }
        }
    }
    
    private var mainGameView: some View {
        VStack(spacing: 0) {
            TopBar(vm: vm)
            HStack(spacing: 0) {
                LeftPanel(vm: vm).frame(width: 300)
                Rectangle().fill(Color.white.opacity(0.06)).frame(width: 1)
                SpriteView(scene: vm.scene).ignoresSafeArea()
            }
            StatusBar(vm: vm)
        }
    }
}

// MARK: - Start Screen
struct StartScreen: View {
    @ObservedObject var vm: GameViewModel
    var body: some View {
        VStack(spacing: 16) {
            Text("🚂").font(.system(size: 64))
            Text("RAILWAY.engineer")
                .font(.custom("Menlo-Bold", size: 42))
                .foregroundColor(Color(nsColor: GameConstants.accentGreen))
            Text("철도 안정화 시뮬레이션")
                .font(.system(size: 16)).foregroundColor(.gray)
            Text("\"플레이어는 기차를 조작하는 사람이 아니라,\n철도 시스템을 안정화하는 엔지니어다.\"")
                .font(.system(size: 14)).foregroundColor(.gray).italic()
                .multilineTextAlignment(.center).padding(.vertical, 12)
            Button(action: { vm.startGame() }) {
                Text("시스템 접속 →")
                    .font(.custom("Menlo-Bold", size: 16))
                    .foregroundColor(.black)
                    .padding(.horizontal, 48).padding(.vertical, 14)
                    .background(Color(nsColor: GameConstants.accentGreen))
                    .cornerRadius(8)
            }.buttonStyle(.plain)
        }
    }
}

// MARK: - Top Bar
struct TopBar: View {
    @ObservedObject var vm: GameViewModel
    var body: some View {
        HStack {
            HStack(spacing: 0) {
                Text("RAILWAY").font(.custom("Menlo-Bold", size: 18))
                    .foregroundColor(Color(nsColor: GameConstants.accentGreen))
                Text(".engineer").font(.custom("Menlo", size: 18)).foregroundColor(.gray)
            }
            Spacer()
            HStack(spacing: 12) {
                Text("LEVEL \(vm.currentLevel + 1)")
                    .font(.custom("Menlo-Bold", size: 13)).foregroundColor(.black)
                    .padding(.horizontal, 12).padding(.vertical, 4)
                    .background(Color(nsColor: GameConstants.accentGreen)).cornerRadius(4)
                Text(vm.levelTitle).font(.system(size: 15, weight: .bold)).foregroundColor(.white)
            }
            Spacer()
            HStack(spacing: 8) {
                // Speed buttons
                HStack(spacing: 4) {
                    ForEach([1, 2, 3], id: \.self) { speed in
                        Button("\(speed)×") { vm.setSpeed(CGFloat(speed)) }
                            .font(.custom("Menlo", size: 10))
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(vm.simSpeed == CGFloat(speed) ?
                                Color(nsColor: GameConstants.accentGreen) : Color.clear)
                            .foregroundColor(vm.simSpeed == CGFloat(speed) ? .black : .gray)
                            .cornerRadius(4)
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.white.opacity(0.15)))
                    }
                }
                Button(action: { vm.toggleSimulation() }) {
                    Text(vm.isRunning ? "⏸ PAUSE" : "▶ RUN")
                        .font(.custom("Menlo-Bold", size: 12)).foregroundColor(.black)
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .background(Color(nsColor: GameConstants.accentGreen)).cornerRadius(6)
                }.buttonStyle(.plain)
                Button(action: { vm.resetLevel() }) {
                    Text("↻ RESET").font(.custom("Menlo", size: 12)).foregroundColor(Color(nsColor: GameConstants.accentRed))
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(nsColor: GameConstants.accentRed)))
                }.buttonStyle(.plain)
                Button(action: { vm.showLevelSelect = true }) {
                    Text("≡ LEVELS").font(.custom("Menlo", size: 12)).foregroundColor(.white)
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.15)))
                }.buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24).padding(.vertical, 12)
        .background(Color(red: 0.075, green: 0.098, blue: 0.125))
    }
}

// MARK: - Left Panel
struct LeftPanel: View {
    @ObservedObject var vm: GameViewModel
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Incident Report
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Circle().fill(Color(nsColor: GameConstants.accentRed)).frame(width: 8, height: 8)
                        Text("INCIDENT REPORT").font(.custom("Menlo", size: 11))
                            .foregroundColor(Color(nsColor: GameConstants.accentRed))
                            .tracking(2)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(vm.incidents.enumerated()), id: \.offset) { _, item in
                            HStack(alignment: .top, spacing: 0) {
                                Rectangle().fill(Color(nsColor: GameConstants.accentRed)).frame(width: 2)
                                VStack(alignment: .leading) {
                                    (Text(item.boldText).bold() + Text(item.normalText))
                                        .font(.system(size: 13)).foregroundColor(.gray)
                                }.padding(.leading, 10)
                            }
                        }
                    }
                    .padding(16)
                    .background(Color(nsColor: GameConstants.accentRed).opacity(0.06))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(nsColor: GameConstants.accentRed).opacity(0.15)))
                    .cornerRadius(8)
                }.padding(20)
                
                Divider().background(Color.white.opacity(0.06))
                
                // Objective
                VStack(alignment: .leading, spacing: 12) {
                    Text("OBJECTIVE").font(.custom("Menlo", size: 11))
                        .foregroundColor(Color(nsColor: GameConstants.accentBlue)).tracking(2)
                    Text(vm.objective).font(.system(size: 14)).foregroundColor(.white).lineSpacing(4)
                }.padding(20)
                
                Divider().background(Color.white.opacity(0.06))
                
                // Tools
                VStack(alignment: .leading, spacing: 12) {
                    Text("AVAILABLE TOOLS").font(.custom("Menlo", size: 11))
                        .foregroundColor(Color(nsColor: GameConstants.accentBlue)).tracking(2)
                    ForEach(Array(vm.toolSlots.enumerated()), id: \.element.id) { _, slot in
                        ToolItemView(slot: slot, isSelected: vm.selectedToolType == slot.type) {
                            vm.selectTool(slot.type)
                        }
                    }
                }.padding(20)
                
                Divider().background(Color.white.opacity(0.06))
                
                // System Status
                VStack(alignment: .leading, spacing: 12) {
                    Text("SYSTEM STATUS").font(.custom("Menlo", size: 11))
                        .foregroundColor(Color(nsColor: GameConstants.accentBlue)).tracking(2)
                    StatusRow(label: "Trains Passed", value: "\(vm.trainsPassed) / \(vm.requiredPasses)",
                              color: Color(nsColor: GameConstants.accentGreen))
                    StatusRow(label: "Collisions", value: "\(vm.collisionCount)",
                              color: Color(nsColor: GameConstants.accentRed))
                    StatusRow(label: "Derailments", value: "\(vm.derailmentCount)",
                              color: Color(nsColor: GameConstants.accentOrange))
                }.padding(20)
                
                Spacer()
            }
        }
        .background(Color(red: 0.075, green: 0.098, blue: 0.125))
    }
}

struct ToolItemView: View {
    let slot: ToolSlot
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(slot.type.icon).font(.system(size: 20))
                VStack(alignment: .leading, spacing: 2) {
                    Text(slot.type.displayName).font(.system(size: 13, weight: .bold)).foregroundColor(.white)
                    Text(slot.type.description).font(.system(size: 11)).foregroundColor(.gray)
                }
                Spacer()
                Text("×\(slot.remaining)")
                    .font(.custom("Menlo", size: 12))
                    .foregroundColor(slot.remaining == 0 ?
                        Color(nsColor: GameConstants.accentRed) :
                        Color(nsColor: GameConstants.accentYellow))
            }
            .padding(10)
            .background(isSelected ? Color(nsColor: GameConstants.accentGreen).opacity(0.08) :
                Color(red: 0.1, green: 0.133, blue: 0.19))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color(nsColor: GameConstants.accentGreen) :
                        Color.clear, lineWidth: 2)
            )
        }.buttonStyle(.plain)
    }
}

struct StatusRow: View {
    let label: String
    let value: String
    let color: Color
    var body: some View {
        HStack {
            Text(label).font(.system(size: 12)).foregroundColor(.gray)
            Spacer()
            Text(value).font(.custom("Menlo", size: 12)).foregroundColor(color)
        }
    }
}

// MARK: - Status Bar
struct StatusBar: View {
    @ObservedObject var vm: GameViewModel
    var body: some View {
        HStack {
            HStack(spacing: 6) {
                Circle().fill(vm.statusColor).frame(width: 6, height: 6)
                Text(vm.statusText).font(.custom("Menlo", size: 11)).foregroundColor(.gray)
            }
            Spacer()
            Text(vm.formattedTimer).font(.custom("Menlo", size: 11)).foregroundColor(.gray)
        }
        .padding(.horizontal, 24).padding(.vertical, 8)
        .background(Color(red: 0.075, green: 0.098, blue: 0.125))
    }
}

// MARK: - Success Overlay
struct SuccessOverlay: View {
    @ObservedObject var vm: GameViewModel
    var body: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()
            VStack(spacing: 20) {
                Text("✅").font(.system(size: 64))
                Text("SYSTEM STABILIZED")
                    .font(.system(size: 28, weight: .black))
                    .foregroundColor(Color(nsColor: GameConstants.accentGreen))
                Text("레벨 \(vm.currentLevel + 1) 클리어! \(vm.levelTitle) 문제가 해결되었습니다.")
                    .font(.system(size: 15)).foregroundColor(.gray)
                Button(action: { vm.nextLevel() }) {
                    Text("다음 레벨 →")
                        .font(.custom("Menlo-Bold", size: 14)).foregroundColor(.black)
                        .padding(.horizontal, 32).padding(.vertical, 12)
                        .background(Color(nsColor: GameConstants.accentGreen)).cornerRadius(8)
                }.buttonStyle(.plain)
            }
            .padding(48)
            .background(Color(red: 0.075, green: 0.098, blue: 0.125))
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1)))
        }
    }
}

// MARK: - Fail Overlay
struct FailOverlay: View {
    @ObservedObject var vm: GameViewModel
    var body: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()
            VStack(spacing: 20) {
                Text("💥").font(.system(size: 64))
                Text("SYSTEM FAILURE")
                    .font(.system(size: 28, weight: .black))
                    .foregroundColor(Color(nsColor: GameConstants.accentRed))
                Text(vm.failMessage).font(.system(size: 15)).foregroundColor(.gray)
                Button(action: { vm.resetLevel() }) {
                    Text("재시도")
                        .font(.custom("Menlo-Bold", size: 14))
                        .foregroundColor(Color(nsColor: GameConstants.accentRed))
                        .padding(.horizontal, 32).padding(.vertical, 12)
                        .overlay(RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(nsColor: GameConstants.accentRed)))
                }.buttonStyle(.plain)
            }
            .padding(48)
            .background(Color(red: 0.075, green: 0.098, blue: 0.125))
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1)))
        }
    }
}

// MARK: - Level Select Overlay
struct LevelSelectOverlay: View {
    @ObservedObject var vm: GameViewModel
    let columns = Array(repeating: GridItem(.fixed(56), spacing: 8), count: 5)
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()
                .onTapGesture { vm.showLevelSelect = false }
            VStack(spacing: 20) {
                Text("레벨 선택").font(.system(size: 24, weight: .bold)).foregroundColor(.white)
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(0..<LevelFactory.totalLevels, id: \.self) { i in
                        let completed = i < vm.maxUnlockedLevel
                        let locked = i > vm.maxUnlockedLevel
                        Button(action: {
                            if !locked { vm.showLevelSelect = false; vm.loadLevel(i) }
                        }) {
                            Text("\(i + 1)")
                                .font(.custom("Menlo-Bold", size: 14))
                                .foregroundColor(completed ? Color(nsColor: GameConstants.accentGreen) :
                                    locked ? .gray.opacity(0.3) : .white)
                                .frame(width: 48, height: 48)
                                .background(completed ? Color(nsColor: GameConstants.accentGreen).opacity(0.15) :
                                    Color(red: 0.1, green: 0.133, blue: 0.19))
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(
                                    completed ? Color(nsColor: GameConstants.accentGreen) :
                                    Color.white.opacity(locked ? 0.05 : 0.1)))
                        }.buttonStyle(.plain).disabled(locked)
                    }
                }
                Button(action: { vm.showLevelSelect = false }) {
                    Text("닫기").font(.custom("Menlo", size: 12)).foregroundColor(.white)
                        .padding(.horizontal, 24).padding(.vertical, 8)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.15)))
                }.buttonStyle(.plain)
            }
            .padding(48)
            .background(Color(red: 0.075, green: 0.098, blue: 0.125))
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1)))
        }
    }
}

#Preview {
    ContentView().frame(width: 1400, height: 900)
}
