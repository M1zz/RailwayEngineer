import Foundation

// MARK: - Wave Definition
struct WaveDefinition {
    let waveNumber: Int
    let title: String
    let description: String
    let requiredPasses: Int
    let newTools: [ToolSlot]       // 이 웨이브에서 새로 주어지는 도구
    let spawns: [SpawnConfig]       // 이 웨이브의 기차들
    let newTracks: [TrackCell]      // 이 웨이브에서 추가되는 트랙 (옵션)
    let newDestinations: [Destination] // 이 웨이브에서 추가되는 목적지 (옵션)
}

// MARK: - Wave Generator
class WaveGenerator {
    
    private var currentWave: Int = 0
    private var accumulatedTools: [ToolType: Int] = [:]  // 누적 도구
    
    // 기본 트랙 - 모든 웨이브에서 공유
    func baseTrack() -> [TrackCell] {
        var tracks: [TrackCell] = []
        
        // 메인 라인 (y=5)
        for x in 1...14 {
            tracks.append(TrackCell(pos: GridPos(x: x, y: 5), type: .horizontal))
        }
        
        // 북쪽 분기 (y=3)
        tracks.append(TrackCell(pos: GridPos(x: 5, y: 5), type: .junction))
        tracks.append(TrackCell(pos: GridPos(x: 5, y: 4), type: .vertical))
        tracks.append(TrackCell(pos: GridPos(x: 5, y: 3), type: .vertical))
        for x in 6...14 {
            tracks.append(TrackCell(pos: GridPos(x: x, y: 3), type: .horizontal))
        }
        
        // 남쪽 분기 (y=7)
        tracks.append(TrackCell(pos: GridPos(x: 5, y: 6), type: .vertical))
        tracks.append(TrackCell(pos: GridPos(x: 5, y: 7), type: .vertical))
        for x in 6...14 {
            tracks.append(TrackCell(pos: GridPos(x: x, y: 7), type: .horizontal))
        }
        
        // 교차점 (x=10)
        for y in 2...8 {
            if y != 3 && y != 5 && y != 7 {
                tracks.append(TrackCell(pos: GridPos(x: 10, y: y), type: .vertical))
            }
        }
        tracks.append(TrackCell(pos: GridPos(x: 10, y: 3), type: .cross))
        tracks.append(TrackCell(pos: GridPos(x: 10, y: 5), type: .cross))
        tracks.append(TrackCell(pos: GridPos(x: 10, y: 7), type: .cross))
        
        return tracks
    }
    
    func baseDestinations() -> [Destination] {
        return [
            Destination(pos: GridPos(x: 14, y: 3), label: "A"),
            Destination(pos: GridPos(x: 14, y: 5), label: "B"),
            Destination(pos: GridPos(x: 14, y: 7), label: "C"),
        ]
    }
    
    // 웨이브 생성
    func generateWave(_ waveNumber: Int) -> WaveDefinition {
        currentWave = waveNumber
        
        switch waveNumber {
        case 1: return wave1()
        case 2: return wave2()
        case 3: return wave3()
        case 4: return wave4()
        case 5: return wave5()
        case 6: return wave6()
        case 7: return wave7()
        case 8: return wave8()
        case 9: return wave9()
        case 10: return wave10()
        default: return generateEndlessWave(waveNumber)
        }
    }
    
    // ═══════════════════════════════════════════════════════════════
    // Wave 1: 시작 - 기차 2대, 신호등 2개
    // ═══════════════════════════════════════════════════════════════
    private func wave1() -> WaveDefinition {
        return WaveDefinition(
            waveNumber: 1,
            title: "첫 번째 운행",
            description: "기차 2대가 들어옵니다. 신호등으로 충돌을 방지하세요.",
            requiredPasses: 2,
            newTools: [ToolSlot(type: .signal, maxCount: 2)],
            spawns: [
                SpawnConfig(x: 1, y: 5, delay: 0, speed: 1.0, dest: "B", color: "#40c4ff", label: "T1"),
                SpawnConfig(x: 1, y: 5, delay: 30, speed: 1.0, dest: "B", color: "#ffd600", label: "T2"),
            ],
            newTracks: [],
            newDestinations: []
        )
    }
    
    // ═══════════════════════════════════════════════════════════════
    // Wave 2: 분기 필요 - 기차 3대, 목적지 다름
    // ═══════════════════════════════════════════════════════════════
    private func wave2() -> WaveDefinition {
        return WaveDefinition(
            waveNumber: 2,
            title: "분기 운행",
            description: "기차 3대가 각각 다른 목적지로 가야 합니다. 신호등을 추가합니다.",
            requiredPasses: 3,
            newTools: [ToolSlot(type: .signal, maxCount: 2)],  // 추가 신호등
            spawns: [
                SpawnConfig(x: 1, y: 5, delay: 0, speed: 1.0, dest: "A", color: "#40c4ff", label: "→A"),
                SpawnConfig(x: 1, y: 5, delay: 25, speed: 1.0, dest: "B", color: "#ffd600", label: "→B"),
                SpawnConfig(x: 1, y: 5, delay: 50, speed: 1.0, dest: "C", color: "#ff9100", label: "→C"),
            ],
            newTracks: [],
            newDestinations: []
        )
    }
    
    // ═══════════════════════════════════════════════════════════════
    // Wave 3: 속도 차이 - 빠른 기차 + 느린 기차
    // ═══════════════════════════════════════════════════════════════
    private func wave3() -> WaveDefinition {
        return WaveDefinition(
            waveNumber: 3,
            title: "속도 격차",
            description: "빠른 열차가 느린 열차를 따라잡습니다. 조심하세요!",
            requiredPasses: 3,
            newTools: [ToolSlot(type: .signal, maxCount: 1)],
            spawns: [
                SpawnConfig(x: 1, y: 5, delay: 0, speed: 0.5, dest: "B", color: "#8bc34a", label: "🐢느림"),
                SpawnConfig(x: 1, y: 5, delay: 15, speed: 1.5, dest: "A", color: "#f44336", label: "🚀빠름"),
                SpawnConfig(x: 1, y: 5, delay: 40, speed: 1.0, dest: "C", color: "#9c27b0", label: "보통"),
            ],
            newTracks: [],
            newDestinations: []
        )
    }
    
    // ═══════════════════════════════════════════════════════════════
    // Wave 4: 교차 충돌 - 수직 기차 등장
    // ═══════════════════════════════════════════════════════════════
    private func wave4() -> WaveDefinition {
        return WaveDefinition(
            waveNumber: 4,
            title: "교차 운행",
            description: "수직 방향 열차가 등장합니다! 인터락 장치를 제공합니다.",
            requiredPasses: 4,
            newTools: [ToolSlot(type: .interlock, maxCount: 2)],
            spawns: [
                SpawnConfig(x: 1, y: 5, delay: 0, speed: 1.0, dest: "B", color: "#40c4ff", label: "→"),
                SpawnConfig(x: 10, y: 2, delay: 5, speed: 1.0, dest: "B", color: "#ffd600", label: "↓", dir: .down),
                SpawnConfig(x: 1, y: 5, delay: 50, speed: 1.0, dest: "A", color: "#ff9100", label: "→"),
                SpawnConfig(x: 10, y: 8, delay: 55, speed: 1.0, dest: "A", color: "#e040fb", label: "↑", dir: .up),
            ],
            newTracks: [],
            newDestinations: []
        )
    }
    
    // ═══════════════════════════════════════════════════════════════
    // Wave 5: 과적 차량 - 커브 탈선 위험
    // ═══════════════════════════════════════════════════════════════
    private func wave5() -> WaveDefinition {
        // 커브 트랙 추가
        let curveTrack = [
            TrackCell(pos: GridPos(x: 8, y: 5), type: .junction),
            TrackCell(pos: GridPos(x: 8, y: 4), type: .curve),
            TrackCell(pos: GridPos(x: 9, y: 3), type: .junction),
        ]
        
        return WaveDefinition(
            waveNumber: 5,
            title: "과적 경보",
            description: "과적(⚠️) 차량이 커브에서 탈선합니다. 스캐너를 제공합니다.",
            requiredPasses: 4,
            newTools: [ToolSlot(type: .scanner, maxCount: 2)],
            spawns: [
                SpawnConfig(x: 1, y: 5, delay: 0, speed: 1.0, dest: "A", color: "#40c4ff", label: "정상"),
                SpawnConfig(x: 1, y: 5, delay: 30, speed: 0.9, dest: "B", color: "#ff3d3d", label: "⚠️과적", overloaded: true),
                SpawnConfig(x: 1, y: 5, delay: 60, speed: 1.0, dest: "C", color: "#ffd600", label: "정상"),
                SpawnConfig(x: 1, y: 5, delay: 90, speed: 0.8, dest: "A", color: "#ff3d3d", label: "⚠️과적", overloaded: true),
            ],
            newTracks: curveTrack,
            newDestinations: []
        )
    }
    
    // ═══════════════════════════════════════════════════════════════
    // Wave 6: 내리막 - 과속 위험
    // ═══════════════════════════════════════════════════════════════
    private func wave6() -> WaveDefinition {
        // 내리막 구간으로 변경
        let downhillTracks = [
            TrackCell(pos: GridPos(x: 3, y: 5), type: .downhill),
            TrackCell(pos: GridPos(x: 4, y: 5), type: .downhill),
        ]
        
        return WaveDefinition(
            waveNumber: 6,
            title: "내리막 위험",
            description: "내리막(▼▼)에서 가속됩니다. 제동장치를 제공합니다.",
            requiredPasses: 4,
            newTools: [ToolSlot(type: .brake, maxCount: 3)],
            spawns: [
                SpawnConfig(x: 1, y: 5, delay: 0, speed: 1.0, dest: "B", color: "#40c4ff", label: "T1"),
                SpawnConfig(x: 1, y: 5, delay: 35, speed: 1.2, dest: "A", color: "#ffd600", label: "T2"),
                SpawnConfig(x: 1, y: 5, delay: 70, speed: 1.0, dest: "C", color: "#ff9100", label: "T3"),
                SpawnConfig(x: 1, y: 5, delay: 100, speed: 1.3, dest: "B", color: "#e040fb", label: "T4"),
            ],
            newTracks: downhillTracks,
            newDestinations: []
        )
    }
    
    // ═══════════════════════════════════════════════════════════════
    // Wave 7: 자동 분기 - 라우터
    // ═══════════════════════════════════════════════════════════════
    private func wave7() -> WaveDefinition {
        return WaveDefinition(
            waveNumber: 7,
            title: "자동 분기 시스템",
            description: "라우터(🏷)로 화물 종류별 자동 분기가 가능합니다.",
            requiredPasses: 5,
            newTools: [ToolSlot(type: .router, maxCount: 2)],
            spawns: [
                SpawnConfig(x: 1, y: 5, delay: 0, speed: 1.0, dest: "A", color: "#424242", label: "석탄", cargo: .coal),
                SpawnConfig(x: 1, y: 5, delay: 25, speed: 1.0, dest: "B", color: "#2196f3", label: "승객", cargo: .passenger),
                SpawnConfig(x: 1, y: 5, delay: 50, speed: 1.0, dest: "C", color: "#795548", label: "목재", cargo: .wood),
                SpawnConfig(x: 1, y: 5, delay: 75, speed: 1.0, dest: "B", color: "#2196f3", label: "승객", cargo: .passenger),
                SpawnConfig(x: 1, y: 5, delay: 100, speed: 1.0, dest: "A", color: "#424242", label: "석탄", cargo: .coal),
            ],
            newTracks: [],
            newDestinations: []
        )
    }
    
    // ═══════════════════════════════════════════════════════════════
    // Wave 8: 긴 열차
    // ═══════════════════════════════════════════════════════════════
    private func wave8() -> WaveDefinition {
        return WaveDefinition(
            waveNumber: 8,
            title: "대형 열차",
            description: "긴 열차가 등장합니다. 길이 검사기(📏)를 제공합니다.",
            requiredPasses: 4,
            newTools: [ToolSlot(type: .lengthCheck, maxCount: 2)],
            spawns: [
                SpawnConfig(x: 1, y: 5, delay: 0, speed: 1.0, dest: "A", color: "#40c4ff", label: "짧음", trainLength: 1),
                SpawnConfig(x: 1, y: 5, delay: 30, speed: 0.7, dest: "B", color: "#ff5722", label: "긴열차", trainLength: 4),
                SpawnConfig(x: 1, y: 5, delay: 70, speed: 1.0, dest: "C", color: "#ffd600", label: "짧음", trainLength: 1),
                SpawnConfig(x: 1, y: 5, delay: 100, speed: 0.6, dest: "A", color: "#ff5722", label: "긴열차", trainLength: 5),
            ],
            newTracks: [],
            newDestinations: []
        )
    }
    
    // ═══════════════════════════════════════════════════════════════
    // Wave 9: 복합 문제
    // ═══════════════════════════════════════════════════════════════
    private func wave9() -> WaveDefinition {
        return WaveDefinition(
            waveNumber: 9,
            title: "복합 운행",
            description: "과적 + 속도 + 교차 + 분기를 동시에 처리하세요!",
            requiredPasses: 6,
            newTools: [ToolSlot(type: .signal, maxCount: 2)],  // 추가 신호등
            spawns: [
                SpawnConfig(x: 1, y: 5, delay: 0, speed: 1.0, dest: "A", color: "#40c4ff", label: "→A"),
                SpawnConfig(x: 10, y: 2, delay: 10, speed: 1.0, dest: "B", color: "#ffd600", label: "↓B", dir: .down),
                SpawnConfig(x: 1, y: 5, delay: 30, speed: 0.8, dest: "C", color: "#ff3d3d", label: "⚠️과적", overloaded: true),
                SpawnConfig(x: 1, y: 5, delay: 50, speed: 1.5, dest: "B", color: "#f44336", label: "🚀빠름"),
                SpawnConfig(x: 10, y: 8, delay: 60, speed: 1.0, dest: "A", color: "#9c27b0", label: "↑A", dir: .up),
                SpawnConfig(x: 1, y: 5, delay: 90, speed: 1.0, dest: "C", color: "#00bcd4", label: "→C"),
            ],
            newTracks: [],
            newDestinations: []
        )
    }
    
    // ═══════════════════════════════════════════════════════════════
    // Wave 10: 긴급 상황
    // ═══════════════════════════════════════════════════════════════
    private func wave10() -> WaveDefinition {
        return WaveDefinition(
            waveNumber: 10,
            title: "긴급 상황",
            description: "동시에 많은 열차가 쏟아집니다! 모든 도구를 활용하세요!",
            requiredPasses: 8,
            newTools: [
                ToolSlot(type: .signal, maxCount: 3),
                ToolSlot(type: .brake, maxCount: 2),
            ],
            spawns: [
                SpawnConfig(x: 1, y: 5, delay: 0, speed: 1.0, dest: "A", color: "#40c4ff", label: "1"),
                SpawnConfig(x: 1, y: 5, delay: 10, speed: 1.2, dest: "B", color: "#ffd600", label: "2"),
                SpawnConfig(x: 10, y: 2, delay: 15, speed: 1.0, dest: "C", color: "#ff9100", label: "3", dir: .down),
                SpawnConfig(x: 1, y: 5, delay: 25, speed: 0.8, dest: "A", color: "#ff3d3d", label: "⚠️", overloaded: true),
                SpawnConfig(x: 1, y: 5, delay: 35, speed: 1.5, dest: "B", color: "#f44336", label: "5"),
                SpawnConfig(x: 10, y: 8, delay: 40, speed: 1.0, dest: "A", color: "#9c27b0", label: "6", dir: .up),
                SpawnConfig(x: 1, y: 5, delay: 55, speed: 1.0, dest: "C", color: "#00bcd4", label: "7"),
                SpawnConfig(x: 1, y: 5, delay: 70, speed: 0.7, dest: "B", color: "#ff5722", label: "긴열차", trainLength: 4),
            ],
            newTracks: [],
            newDestinations: []
        )
    }
    
    // ═══════════════════════════════════════════════════════════════
    // 엔드리스 웨이브 - 11 이후
    // ═══════════════════════════════════════════════════════════════
    private func generateEndlessWave(_ waveNumber: Int) -> WaveDefinition {
        let difficulty = waveNumber - 10
        let trainCount = min(4 + difficulty, 12)
        let requiredPasses = trainCount
        
        // 랜덤 스폰 생성
        var spawns: [SpawnConfig] = []
        let colors = ["#40c4ff", "#ffd600", "#ff9100", "#e040fb", "#00e676", "#ff3d3d", "#2196f3", "#795548"]
        let destinations = ["A", "B", "C"]
        
        for i in 0..<trainCount {
            let delay = i * (25 - min(difficulty, 15))
            let speed = CGFloat.random(in: 0.6...1.5)
            let dest = destinations.randomElement()!
            let color = colors.randomElement()!
            let isOverloaded = Int.random(in: 0..<100) < (10 + difficulty * 3)
            let isVertical = Int.random(in: 0..<100) < (20 + difficulty * 2)
            let trainLength = Int.random(in: 0..<100) < 15 ? Int.random(in: 3...5) : 1
            
            if isVertical && i % 3 == 0 {
                let startY = Bool.random() ? 2 : 8
                let dir: TrainDirection = startY == 2 ? .down : .up
                spawns.append(SpawnConfig(
                    x: 10, y: startY, delay: delay, speed: speed, dest: dest,
                    color: color, label: "V\(i+1)", dir: dir,
                    overloaded: isOverloaded, trainLength: trainLength
                ))
            } else {
                spawns.append(SpawnConfig(
                    x: 1, y: 5, delay: delay, speed: speed, dest: dest,
                    color: color, label: "T\(i+1)",
                    overloaded: isOverloaded, trainLength: trainLength
                ))
            }
        }
        
        // 보너스 도구 (3웨이브마다)
        var newTools: [ToolSlot] = []
        if waveNumber % 3 == 0 {
            newTools.append(ToolSlot(type: .signal, maxCount: 2))
        }
        if waveNumber % 5 == 0 {
            newTools.append(ToolSlot(type: .brake, maxCount: 1))
        }
        
        return WaveDefinition(
            waveNumber: waveNumber,
            title: "웨이브 \(waveNumber)",
            description: "열차 \(trainCount)대 운행. 난이도 증가!",
            requiredPasses: requiredPasses,
            newTools: newTools,
            spawns: spawns,
            newTracks: [],
            newDestinations: []
        )
    }
}
