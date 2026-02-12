import Foundation

// MARK: - Level Definition
struct LevelDefinition {
    let title: String
    let incidents: [IncidentItem]
    let objective: String
    let requiredPasses: Int
    let tools: [ToolSlot]
    let tracks: [TrackCell]
    let destinations: [Destination]
    let spawns: [SpawnConfig]
}

// MARK: - Level Factory
enum LevelFactory {
    
    static let totalLevels = 10
    
    static func create(level index: Int) -> LevelDefinition {
        switch index {
        case 0: return level1()
        case 1: return level2()
        case 2: return level3()
        case 3: return level4()
        case 4: return level5()
        case 5: return level6()
        case 6: return level7()
        case 7: return level8()
        case 8: return level9()
        case 9: return level10()
        default: return level1()
        }
    }
    
    // MARK: Level 1 — 신호등 추가
    private static func level1() -> LevelDefinition {
        var tracks: [TrackCell] = []
        
        // Main horizontal line
        for i in 1...14 {
            tracks.append(TrackCell(pos: GridPos(x: i, y: 4), type: .horizontal))
        }
        // Junction
        tracks.append(TrackCell(pos: GridPos(x: 7, y: 4), type: .junction))
        // Branch up
        for y in 2...3 { tracks.append(TrackCell(pos: GridPos(x: 7, y: y), type: .vertical)) }
        for x in 8...14 { tracks.append(TrackCell(pos: GridPos(x: x, y: 2), type: .horizontal)) }
        // Branch down
        for y in 5...6 { tracks.append(TrackCell(pos: GridPos(x: 7, y: y), type: .vertical)) }
        for x in 8...14 { tracks.append(TrackCell(pos: GridPos(x: x, y: 6), type: .horizontal)) }
        
        return LevelDefinition(
            title: "신호등 추가",
            incidents: [
                IncidentItem(boldText: "Train collision", normalText: " detected at Junction A"),
                IncidentItem(boldText: "Cause:", normalText: " No signal control")
            ],
            objective: "충돌 없이 기차 3대를 안전하게 통과시키세요.",
            requiredPasses: 3,
            tools: [ToolSlot(type: .signal, maxCount: 3)],
            tracks: tracks,
            destinations: [
                Destination(pos: GridPos(x: 14, y: 4), label: "A"),
                Destination(pos: GridPos(x: 14, y: 2), label: "B"),
                Destination(pos: GridPos(x: 14, y: 6), label: "C"),
            ],
            spawns: [
                SpawnConfig(x: 1, y: 4, delay: 0, speed: 1, dest: "A", color: "#40c4ff", label: "T1"),
                SpawnConfig(x: 1, y: 4, delay: 60, speed: 1, dest: "B", color: "#ffd600", label: "T2"),
                SpawnConfig(x: 1, y: 4, delay: 120, speed: 1, dest: "C", color: "#ff9100", label: "T3"),
            ]
        )
    }
    
    // MARK: Level 2 — 과적 차량 문제
    private static func level2() -> LevelDefinition {
        var tracks: [TrackCell] = []
        for i in 1...14 { tracks.append(TrackCell(pos: GridPos(x: i, y: 4), type: .horizontal)) }
        // Junction at x=5
        tracks.append(TrackCell(pos: GridPos(x: 5, y: 4), type: .junction))
        // Curve route (dangerous)
        tracks.append(TrackCell(pos: GridPos(x: 5, y: 3), type: .curve))
        tracks.append(TrackCell(pos: GridPos(x: 6, y: 2), type: .curve))
        for x in 7...8 { tracks.append(TrackCell(pos: GridPos(x: x, y: 2), type: .horizontal)) }
        tracks.append(TrackCell(pos: GridPos(x: 9, y: 3), type: .curve))
        tracks.append(TrackCell(pos: GridPos(x: 9, y: 4), type: .junction))
        // Straight bypass
        for y in 5...6 { tracks.append(TrackCell(pos: GridPos(x: 5, y: y), type: .vertical)) }
        for x in 6...8 { tracks.append(TrackCell(pos: GridPos(x: x, y: 6), type: .horizontal)) }
        for y in 5...5 { tracks.append(TrackCell(pos: GridPos(x: 9, y: y), type: .vertical)) }
        
        return LevelDefinition(
            title: "과적 차량 문제",
            incidents: [
                IncidentItem(boldText: "Derailment", normalText: " at Curve Section B"),
                IncidentItem(boldText: "Cause:", normalText: " Overloaded cargo on curve")
            ],
            objective: "과적 차량을 감지하고 직선 경로로 우회시키세요.",
            requiredPasses: 4,
            tools: [
                ToolSlot(type: .signal, maxCount: 2),
                ToolSlot(type: .scanner, maxCount: 2),
            ],
            tracks: tracks,
            destinations: [Destination(pos: GridPos(x: 14, y: 4), label: "DEPOT")],
            spawns: [
                SpawnConfig(x: 1, y: 4, delay: 0, speed: 1, dest: "DEPOT", color: "#40c4ff", label: "T1"),
                SpawnConfig(x: 1, y: 4, delay: 50, speed: 1, dest: "DEPOT", color: "#ff3d3d", label: "T2", overloaded: true),
                SpawnConfig(x: 1, y: 4, delay: 100, speed: 1, dest: "DEPOT", color: "#40c4ff", label: "T3"),
                SpawnConfig(x: 1, y: 4, delay: 150, speed: 1, dest: "DEPOT", color: "#ff3d3d", label: "T4", overloaded: true),
            ]
        )
    }
    
    // MARK: Level 3 — 속도 차이 문제
    private static func level3() -> LevelDefinition {
        var tracks: [TrackCell] = []
        for i in 1...14 { tracks.append(TrackCell(pos: GridPos(x: i, y: 4), type: .horizontal)) }
        tracks.append(TrackCell(pos: GridPos(x: 6, y: 4), type: .junction))
        tracks.append(TrackCell(pos: GridPos(x: 6, y: 3), type: .vertical))
        for x in 7...8 { tracks.append(TrackCell(pos: GridPos(x: x, y: 3), type: .horizontal)) }
        tracks.append(TrackCell(pos: GridPos(x: 9, y: 3), type: .vertical))
        tracks.append(TrackCell(pos: GridPos(x: 9, y: 4), type: .junction))
        
        return LevelDefinition(
            title: "속도 차이 문제",
            incidents: [
                IncidentItem(boldText: "Rear collision", normalText: " on main track"),
                IncidentItem(boldText: "Cause:", normalText: " Fast train caught slow train")
            ],
            objective: "대기선을 활용해 속도가 다른 기차 충돌을 방지하세요.",
            requiredPasses: 3,
            tools: [
                ToolSlot(type: .signal, maxCount: 3),
                ToolSlot(type: .waitline, maxCount: 2),
            ],
            tracks: tracks,
            destinations: [Destination(pos: GridPos(x: 14, y: 4), label: "EXIT")],
            spawns: [
                SpawnConfig(x: 1, y: 4, delay: 0, speed: 0.5, dest: "EXIT", color: "#ff9100", label: "SLOW"),
                SpawnConfig(x: 1, y: 4, delay: 20, speed: 1.5, dest: "EXIT", color: "#40c4ff", label: "FAST"),
                SpawnConfig(x: 1, y: 4, delay: 80, speed: 1, dest: "EXIT", color: "#ffd600", label: "MED"),
            ]
        )
    }
    
    // MARK: Level 4 — 병목 문제
    private static func level4() -> LevelDefinition {
        var tracks: [TrackCell] = []
        for i in 1...14 { tracks.append(TrackCell(pos: GridPos(x: i, y: 4), type: .horizontal)) }
        tracks.append(TrackCell(pos: GridPos(x: 5, y: 4), type: .junction))
        // Bypass up
        for y in 2...3 { tracks.append(TrackCell(pos: GridPos(x: 5, y: y), type: .vertical)) }
        for x in 6...9 { tracks.append(TrackCell(pos: GridPos(x: x, y: 2), type: .horizontal)) }
        tracks.append(TrackCell(pos: GridPos(x: 9, y: 3), type: .vertical))
        tracks.append(TrackCell(pos: GridPos(x: 9, y: 4), type: .junction))
        // Bypass down
        for y in 5...6 { tracks.append(TrackCell(pos: GridPos(x: 5, y: y), type: .vertical)) }
        for x in 6...9 { tracks.append(TrackCell(pos: GridPos(x: x, y: 6), type: .horizontal)) }
        tracks.append(TrackCell(pos: GridPos(x: 9, y: 5), type: .vertical))
        
        return LevelDefinition(
            title: "병목 문제",
            incidents: [
                IncidentItem(boldText: "Gridlock", normalText: " at single-track section"),
                IncidentItem(boldText: "Cause:", normalText: " Single track bottleneck")
            ],
            objective: "우회로를 사용하여 병목 구간을 해소하세요.",
            requiredPasses: 5,
            tools: [
                ToolSlot(type: .signal, maxCount: 4),
                ToolSlot(type: .switchTrack, maxCount: 3),
            ],
            tracks: tracks,
            destinations: [Destination(pos: GridPos(x: 14, y: 4), label: "EXIT")],
            spawns: [
                SpawnConfig(x: 1, y: 4, delay: 0, speed: 1, dest: "EXIT", color: "#40c4ff", label: "T1"),
                SpawnConfig(x: 1, y: 4, delay: 15, speed: 1, dest: "EXIT", color: "#ffd600", label: "T2"),
                SpawnConfig(x: 1, y: 4, delay: 30, speed: 1, dest: "EXIT", color: "#ff9100", label: "T3"),
                SpawnConfig(x: 1, y: 4, delay: 45, speed: 1, dest: "EXIT", color: "#00e676", label: "T4"),
                SpawnConfig(x: 1, y: 4, delay: 60, speed: 1, dest: "EXIT", color: "#e040fb", label: "T5"),
            ]
        )
    }
    
    // MARK: Level 5 — 목적지 분리
    private static func level5() -> LevelDefinition {
        var tracks: [TrackCell] = []
        for i in 1...8 { tracks.append(TrackCell(pos: GridPos(x: i, y: 5), type: .horizontal)) }
        tracks.append(TrackCell(pos: GridPos(x: 8, y: 5), type: .junction))
        // Route A (top)
        for y in 2...4 { tracks.append(TrackCell(pos: GridPos(x: 8, y: y), type: .vertical)) }
        for x in 9...14 { tracks.append(TrackCell(pos: GridPos(x: x, y: 2), type: .horizontal)) }
        // Route B (middle)
        for x in 9...14 { tracks.append(TrackCell(pos: GridPos(x: x, y: 5), type: .horizontal)) }
        // Route C (bottom)
        for y in 6...8 { tracks.append(TrackCell(pos: GridPos(x: 8, y: y), type: .vertical)) }
        for x in 9...14 { tracks.append(TrackCell(pos: GridPos(x: x, y: 8), type: .horizontal)) }
        
        return LevelDefinition(
            title: "목적지 분리",
            incidents: [
                IncidentItem(boldText: "Misrouted cargo", normalText: " at Distribution Hub"),
                IncidentItem(boldText: "Cause:", normalText: " No routing system")
            ],
            objective: "화물 종류에 따라 올바른 목적지로 분기시키세요.",
            requiredPasses: 4,
            tools: [
                ToolSlot(type: .signal, maxCount: 3),
                ToolSlot(type: .router, maxCount: 2),
            ],
            tracks: tracks,
            destinations: [
                Destination(pos: GridPos(x: 14, y: 2), label: "석탄"),
                Destination(pos: GridPos(x: 14, y: 5), label: "승객"),
                Destination(pos: GridPos(x: 14, y: 8), label: "목재"),
            ],
            spawns: [
                SpawnConfig(x: 1, y: 5, delay: 0, speed: 1, dest: "석탄", color: "#555555", label: "석탄", cargo: .coal),
                SpawnConfig(x: 1, y: 5, delay: 50, speed: 1, dest: "승객", color: "#40c4ff", label: "승객", cargo: .passenger),
                SpawnConfig(x: 1, y: 5, delay: 100, speed: 1, dest: "목재", color: "#8d6e63", label: "목재", cargo: .wood),
                SpawnConfig(x: 1, y: 5, delay: 150, speed: 1, dest: "승객", color: "#40c4ff", label: "승객", cargo: .passenger),
            ]
        )
    }
    
    // MARK: Level 6 — 내리막 탈선
    private static func level6() -> LevelDefinition {
        var tracks: [TrackCell] = []
        for i in 1...14 {
            let type: TrackType = (6...9).contains(i) ? .downhill : .horizontal
            tracks.append(TrackCell(pos: GridPos(x: i, y: 4), type: type))
        }
        
        return LevelDefinition(
            title: "내리막 탈선 문제",
            incidents: [
                IncidentItem(boldText: "Overspeeding", normalText: " detected at downhill section"),
                IncidentItem(boldText: "Cause:", normalText: " No braking zone")
            ],
            objective: "제동 구간을 설치하여 내리막 구간에서의 과속을 방지하세요.",
            requiredPasses: 3,
            tools: [
                ToolSlot(type: .signal, maxCount: 2),
                ToolSlot(type: .brake, maxCount: 3),
            ],
            tracks: tracks,
            destinations: [Destination(pos: GridPos(x: 14, y: 4), label: "EXIT")],
            spawns: [
                SpawnConfig(x: 1, y: 4, delay: 0, speed: 1, dest: "EXIT", color: "#40c4ff", label: "T1"),
                SpawnConfig(x: 1, y: 4, delay: 60, speed: 1.2, dest: "EXIT", color: "#ffd600", label: "T2"),
                SpawnConfig(x: 1, y: 4, delay: 120, speed: 0.8, dest: "EXIT", color: "#ff9100", label: "T3"),
            ]
        )
    }
    
    // MARK: Level 7 — 교차로 충돌
    private static func level7() -> LevelDefinition {
        var tracks: [TrackCell] = []
        for i in 1...14 { tracks.append(TrackCell(pos: GridPos(x: i, y: 5), type: .horizontal)) }
        // Vertical crossing
        for y in 1...4 { tracks.append(TrackCell(pos: GridPos(x: 7, y: y), type: .vertical)) }
        tracks.append(TrackCell(pos: GridPos(x: 7, y: 5), type: .cross))
        for y in 6...9 { tracks.append(TrackCell(pos: GridPos(x: 7, y: y), type: .vertical)) }
        
        return LevelDefinition(
            title: "교차로 충돌 문제",
            incidents: [
                IncidentItem(boldText: "Crossing collision", normalText: " at intersection"),
                IncidentItem(boldText: "Cause:", normalText: " No interlock signal")
            ],
            objective: "인터락 신호를 설치하여 교차로 충돌을 방지하세요.",
            requiredPasses: 4,
            tools: [
                ToolSlot(type: .signal, maxCount: 4),
                ToolSlot(type: .interlock, maxCount: 2),
            ],
            tracks: tracks,
            destinations: [
                Destination(pos: GridPos(x: 14, y: 5), label: "EAST"),
                Destination(pos: GridPos(x: 7, y: 9), label: "SOUTH"),
            ],
            spawns: [
                SpawnConfig(x: 1, y: 5, delay: 0, speed: 1, dest: "EAST", color: "#40c4ff", label: "H1"),
                SpawnConfig(x: 7, y: 1, delay: 10, speed: 1, dest: "SOUTH", color: "#ffd600", label: "V1", dir: .down),
                SpawnConfig(x: 1, y: 5, delay: 60, speed: 1, dest: "EAST", color: "#ff9100", label: "H2"),
                SpawnConfig(x: 7, y: 1, delay: 70, speed: 1, dest: "SOUTH", color: "#e040fb", label: "V2", dir: .down),
            ]
        )
    }
    
    // MARK: Level 8 — 긴 열차 문제
    private static func level8() -> LevelDefinition {
        var tracks: [TrackCell] = []
        for i in 1...14 { tracks.append(TrackCell(pos: GridPos(x: i, y: 4), type: .horizontal)) }
        tracks.append(TrackCell(pos: GridPos(x: 6, y: 4), type: .junction))
        // Short siding
        tracks.append(TrackCell(pos: GridPos(x: 6, y: 3), type: .vertical))
        for x in 7...8 { tracks.append(TrackCell(pos: GridPos(x: x, y: 3), type: .horizontal)) }
        // Long siding
        for y in 5...6 { tracks.append(TrackCell(pos: GridPos(x: 6, y: y), type: .vertical)) }
        for x in 7...12 { tracks.append(TrackCell(pos: GridPos(x: x, y: 6), type: .horizontal)) }
        
        return LevelDefinition(
            title: "긴 열차 문제",
            incidents: [
                IncidentItem(boldText: "Long train stuck", normalText: " at junction"),
                IncidentItem(boldText: "Cause:", normalText: " Track too short for train length")
            ],
            objective: "열차 길이를 확인하고 적절한 경로로 분기하세요.",
            requiredPasses: 3,
            tools: [
                ToolSlot(type: .signal, maxCount: 3),
                ToolSlot(type: .lengthCheck, maxCount: 2),
            ],
            tracks: tracks,
            destinations: [Destination(pos: GridPos(x: 14, y: 4), label: "EXIT")],
            spawns: [
                SpawnConfig(x: 1, y: 4, delay: 0, speed: 1, dest: "EXIT", color: "#40c4ff", label: "SHORT", trainLength: 1),
                SpawnConfig(x: 1, y: 4, delay: 60, speed: 0.8, dest: "EXIT", color: "#ff3d3d", label: "LONG", trainLength: 3),
                SpawnConfig(x: 1, y: 4, delay: 120, speed: 1, dest: "EXIT", color: "#ffd600", label: "SHORT", trainLength: 1),
            ]
        )
    }
    
    // MARK: Level 9 — 제한된 자원
    private static func level9() -> LevelDefinition {
        var tracks: [TrackCell] = []
        for i in 1...14 { tracks.append(TrackCell(pos: GridPos(x: i, y: 4), type: .horizontal)) }
        tracks.append(TrackCell(pos: GridPos(x: 7, y: 4), type: .junction))
        tracks.append(TrackCell(pos: GridPos(x: 7, y: 3), type: .vertical))
        for x in 8...9 { tracks.append(TrackCell(pos: GridPos(x: x, y: 3), type: .horizontal)) }
        tracks.append(TrackCell(pos: GridPos(x: 10, y: 3), type: .vertical))
        tracks.append(TrackCell(pos: GridPos(x: 10, y: 4), type: .junction))
        tracks.append(TrackCell(pos: GridPos(x: 7, y: 5), type: .vertical))
        for x in 8...9 { tracks.append(TrackCell(pos: GridPos(x: x, y: 5), type: .horizontal)) }
        tracks.append(TrackCell(pos: GridPos(x: 10, y: 5), type: .vertical))
        
        return LevelDefinition(
            title: "제한된 자원",
            incidents: [
                IncidentItem(boldText: "Budget cut", normalText: " — limited equipment"),
                IncidentItem(boldText: "Constraint:", normalText: " Only 2 signals available")
            ],
            objective: "신호등 2개만으로 5대의 기차를 안전하게 통과시키세요.",
            requiredPasses: 5,
            tools: [ToolSlot(type: .signal, maxCount: 2)],
            tracks: tracks,
            destinations: [Destination(pos: GridPos(x: 14, y: 4), label: "EXIT")],
            spawns: [
                SpawnConfig(x: 1, y: 4, delay: 0, speed: 1, dest: "EXIT", color: "#40c4ff", label: "T1"),
                SpawnConfig(x: 1, y: 4, delay: 25, speed: 1.2, dest: "EXIT", color: "#ffd600", label: "T2"),
                SpawnConfig(x: 1, y: 4, delay: 50, speed: 0.8, dest: "EXIT", color: "#ff9100", label: "T3"),
                SpawnConfig(x: 1, y: 4, delay: 80, speed: 1, dest: "EXIT", color: "#e040fb", label: "T4"),
                SpawnConfig(x: 1, y: 4, delay: 110, speed: 1.3, dest: "EXIT", color: "#00e676", label: "T5"),
            ]
        )
    }
    
    // MARK: Level 10 — 복합 문제
    private static func level10() -> LevelDefinition {
        var tracks: [TrackCell] = []
        for i in 1...14 { tracks.append(TrackCell(pos: GridPos(x: i, y: 5), type: .horizontal)) }
        tracks.append(TrackCell(pos: GridPos(x: 5, y: 5), type: .junction))
        // Top route
        for y in 3...4 { tracks.append(TrackCell(pos: GridPos(x: 5, y: y), type: .vertical)) }
        for x in 6...14 { tracks.append(TrackCell(pos: GridPos(x: x, y: 3), type: .horizontal)) }
        // Bottom route
        for y in 6...7 { tracks.append(TrackCell(pos: GridPos(x: 5, y: y), type: .vertical)) }
        for x in 6...14 { tracks.append(TrackCell(pos: GridPos(x: x, y: 7), type: .horizontal)) }
        // Downhill
        for x in 8...9 {
            tracks.append(TrackCell(pos: GridPos(x: x, y: 5), type: .downhill))
        }
        
        return LevelDefinition(
            title: "복합 시스템 안정화",
            incidents: [
                IncidentItem(boldText: "Multiple failures", normalText: " across the network"),
                IncidentItem(boldText: "Issues:", normalText: " Overloaded + Speed + Routing")
            ],
            objective: "과적, 속도, 목적지를 모두 고려하여 시스템을 안정화하세요.",
            requiredPasses: 6,
            tools: [
                ToolSlot(type: .signal, maxCount: 4),
                ToolSlot(type: .scanner, maxCount: 1),
                ToolSlot(type: .router, maxCount: 2),
                ToolSlot(type: .brake, maxCount: 2),
            ],
            tracks: tracks,
            destinations: [
                Destination(pos: GridPos(x: 14, y: 3), label: "화물"),
                Destination(pos: GridPos(x: 14, y: 5), label: "승객"),
                Destination(pos: GridPos(x: 14, y: 7), label: "긴급"),
            ],
            spawns: [
                SpawnConfig(x: 1, y: 5, delay: 0, speed: 1, dest: "승객", color: "#40c4ff", label: "승객", cargo: .passenger),
                SpawnConfig(x: 1, y: 5, delay: 40, speed: 1.5, dest: "화물", color: "#ff3d3d", label: "과적", overloaded: true, cargo: .cargo),
                SpawnConfig(x: 1, y: 5, delay: 80, speed: 0.7, dest: "긴급", color: "#ffd600", label: "긴급", cargo: .urgent),
                SpawnConfig(x: 1, y: 5, delay: 120, speed: 1, dest: "승객", color: "#40c4ff", label: "승객", cargo: .passenger),
                SpawnConfig(x: 1, y: 5, delay: 160, speed: 1.3, dest: "화물", color: "#ff9100", label: "화물", cargo: .cargo),
                SpawnConfig(x: 1, y: 5, delay: 200, speed: 1, dest: "긴급", color: "#e040fb", label: "긴급", cargo: .urgent),
            ]
        )
    }
}
