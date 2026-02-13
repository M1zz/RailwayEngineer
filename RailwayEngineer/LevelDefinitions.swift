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
    
    // ═══════════════════════════════════════════════════════════════
    // MARK: Level 1 — 첫 신호등
    // 가장 단순: 직선 트랙, 기차 2대가 연속으로 옴
    // 신호등 1개로 첫 번째 기차를 정지시키고 두 번째를 먼저 보냄
    // ═══════════════════════════════════════════════════════════════
    private static func level1() -> LevelDefinition {
        var tracks: [TrackCell] = []
        
        // 단순 직선 트랙
        for x in 2...13 {
            tracks.append(TrackCell(pos: GridPos(x: x, y: 5), type: .horizontal))
        }
        
        return LevelDefinition(
            title: "첫 번째 신호등",
            incidents: [
                IncidentItem(boldText: "튜토리얼:", normalText: " 신호등 사용법을 배워봅시다"),
            ],
            objective: "신호등을 트랙에 배치하세요. RUN 중에 신호등을 클릭하면 ON/OFF 됩니다. 기차 2대를 안전하게 통과시키세요.",
            requiredPasses: 2,
            tools: [
                ToolSlot(type: .signal, maxCount: 2),
            ],
            tracks: tracks,
            destinations: [
                Destination(pos: GridPos(x: 13, y: 5), label: "출구"),
            ],
            spawns: [
                SpawnConfig(x: 2, y: 5, delay: 0, speed: 1.0, dest: "출구", color: "#40c4ff", label: "T1"),
                SpawnConfig(x: 2, y: 5, delay: 40, speed: 1.0, dest: "출구", color: "#ffd600", label: "T2"),
            ]
        )
    }
    
    // ═══════════════════════════════════════════════════════════════
    // MARK: Level 2 — 분기점 충돌 방지
    // Y자 분기: 같은 지점에 도착하면 충돌
    // 신호등으로 타이밍을 조절해야 함
    // ═══════════════════════════════════════════════════════════════
    private static func level2() -> LevelDefinition {
        var tracks: [TrackCell] = []
        
        // 위쪽 트랙 (y=3)
        for x in 2...7 {
            tracks.append(TrackCell(pos: GridPos(x: x, y: 3), type: .horizontal))
        }
        // 아래쪽 트랙 (y=7)
        for x in 2...7 {
            tracks.append(TrackCell(pos: GridPos(x: x, y: 7), type: .horizontal))
        }
        // 합류 지점 (y=5, x=8)
        tracks.append(TrackCell(pos: GridPos(x: 8, y: 3), type: .curve))
        tracks.append(TrackCell(pos: GridPos(x: 8, y: 4), type: .vertical))
        tracks.append(TrackCell(pos: GridPos(x: 8, y: 5), type: .junction))
        tracks.append(TrackCell(pos: GridPos(x: 8, y: 6), type: .vertical))
        tracks.append(TrackCell(pos: GridPos(x: 8, y: 7), type: .curve))
        // 출구 트랙
        for x in 9...13 {
            tracks.append(TrackCell(pos: GridPos(x: x, y: 5), type: .horizontal))
        }
        
        return LevelDefinition(
            title: "합류 지점",
            incidents: [
                IncidentItem(boldText: "충돌 위험:", normalText: " 두 기차가 동시에 합류 지점에 도착"),
            ],
            objective: "두 기차가 합류 지점(⬛)에서 만나지 않도록 신호등으로 조절하세요.",
            requiredPasses: 2,
            tools: [
                ToolSlot(type: .signal, maxCount: 2),
            ],
            tracks: tracks,
            destinations: [
                Destination(pos: GridPos(x: 13, y: 5), label: "출구"),
            ],
            spawns: [
                SpawnConfig(x: 2, y: 3, delay: 0, speed: 1.0, dest: "출구", color: "#40c4ff", label: "위"),
                SpawnConfig(x: 2, y: 7, delay: 0, speed: 1.0, dest: "출구", color: "#ff9100", label: "아래"),
            ]
        )
    }
    
    // ═══════════════════════════════════════════════════════════════
    // MARK: Level 3 — 속도 차이
    // 빠른 기차가 느린 기차를 따라잡아 충돌
    // 대기선(우회로)으로 해결
    // ═══════════════════════════════════════════════════════════════
    private static func level3() -> LevelDefinition {
        var tracks: [TrackCell] = []
        
        // 메인 트랙
        for x in 2...13 {
            tracks.append(TrackCell(pos: GridPos(x: x, y: 5), type: .horizontal))
        }
        // 우회로 (대피선)
        tracks.append(TrackCell(pos: GridPos(x: 6, y: 5), type: .junction))
        tracks.append(TrackCell(pos: GridPos(x: 6, y: 4), type: .vertical))
        tracks.append(TrackCell(pos: GridPos(x: 6, y: 3), type: .vertical))
        for x in 7...9 {
            tracks.append(TrackCell(pos: GridPos(x: x, y: 3), type: .horizontal))
        }
        tracks.append(TrackCell(pos: GridPos(x: 10, y: 3), type: .vertical))
        tracks.append(TrackCell(pos: GridPos(x: 10, y: 4), type: .vertical))
        tracks.append(TrackCell(pos: GridPos(x: 10, y: 5), type: .junction))
        
        return LevelDefinition(
            title: "속도 차이",
            incidents: [
                IncidentItem(boldText: "추돌 사고:", normalText: " 빠른 열차가 느린 열차를 따라잡음"),
            ],
            objective: "느린 열차(🐢)를 대피선에 정지시키고 빠른 열차(🚀)를 먼저 보내세요.",
            requiredPasses: 2,
            tools: [
                ToolSlot(type: .signal, maxCount: 3),
            ],
            tracks: tracks,
            destinations: [
                Destination(pos: GridPos(x: 13, y: 5), label: "출구"),
            ],
            spawns: [
                SpawnConfig(x: 2, y: 5, delay: 0, speed: 0.5, dest: "출구", color: "#8bc34a", label: "🐢느림"),
                SpawnConfig(x: 2, y: 5, delay: 30, speed: 1.5, dest: "출구", color: "#f44336", label: "🚀빠름"),
            ]
        )
    }
    
    // ═══════════════════════════════════════════════════════════════
    // MARK: Level 4 — 교차로
    // 십자 교차: 수직/수평 기차가 교차점에서 충돌
    // 인터락으로 교대로 통과
    // ═══════════════════════════════════════════════════════════════
    private static func level4() -> LevelDefinition {
        var tracks: [TrackCell] = []
        
        // 수평 트랙
        for x in 2...13 {
            tracks.append(TrackCell(pos: GridPos(x: x, y: 5), type: .horizontal))
        }
        // 수직 트랙
        for y in 2...8 {
            if y != 5 {
                tracks.append(TrackCell(pos: GridPos(x: 8, y: y), type: .vertical))
            }
        }
        // 교차점
        tracks.append(TrackCell(pos: GridPos(x: 8, y: 5), type: .cross))
        
        return LevelDefinition(
            title: "교차로",
            incidents: [
                IncidentItem(boldText: "교차 충돌:", normalText: " 수직/수평 열차가 교차점에서 충돌"),
            ],
            objective: "인터락을 교차점에 설치하면 한 번에 한 대만 통과합니다. 신호등으로 대기시키세요.",
            requiredPasses: 4,
            tools: [
                ToolSlot(type: .signal, maxCount: 4),
                ToolSlot(type: .interlock, maxCount: 1),
            ],
            tracks: tracks,
            destinations: [
                Destination(pos: GridPos(x: 13, y: 5), label: "동"),
                Destination(pos: GridPos(x: 8, y: 8), label: "남"),
            ],
            spawns: [
                SpawnConfig(x: 2, y: 5, delay: 0, speed: 1.0, dest: "동", color: "#40c4ff", label: "→E"),
                SpawnConfig(x: 8, y: 2, delay: 5, speed: 1.0, dest: "남", color: "#ffd600", label: "↓S", dir: .down),
                SpawnConfig(x: 2, y: 5, delay: 60, speed: 1.0, dest: "동", color: "#ff9100", label: "→E"),
                SpawnConfig(x: 8, y: 2, delay: 65, speed: 1.0, dest: "남", color: "#e040fb", label: "↓S", dir: .down),
            ]
        )
    }
    
    // ═══════════════════════════════════════════════════════════════
    // MARK: Level 5 — 내리막 제동
    // 내리막 구간에서 가속 → 과속 탈선
    // 브레이크로 감속
    // ═══════════════════════════════════════════════════════════════
    private static func level5() -> LevelDefinition {
        var tracks: [TrackCell] = []
        
        // 메인 트랙 (중간에 내리막)
        for x in 2...5 {
            tracks.append(TrackCell(pos: GridPos(x: x, y: 5), type: .horizontal))
        }
        for x in 6...9 {
            tracks.append(TrackCell(pos: GridPos(x: x, y: 5), type: .downhill))
        }
        for x in 10...13 {
            tracks.append(TrackCell(pos: GridPos(x: x, y: 5), type: .horizontal))
        }
        
        return LevelDefinition(
            title: "내리막 제동",
            incidents: [
                IncidentItem(boldText: "과속 탈선:", normalText: " 내리막(▼▼)에서 가속하여 탈선"),
            ],
            objective: "내리막 구간 앞에 제동장치(🛑)를 설치하여 속도를 줄이세요.",
            requiredPasses: 3,
            tools: [
                ToolSlot(type: .brake, maxCount: 3),
            ],
            tracks: tracks,
            destinations: [
                Destination(pos: GridPos(x: 13, y: 5), label: "출구"),
            ],
            spawns: [
                SpawnConfig(x: 2, y: 5, delay: 0, speed: 1.0, dest: "출구", color: "#40c4ff", label: "T1"),
                SpawnConfig(x: 2, y: 5, delay: 50, speed: 1.2, dest: "출구", color: "#ffd600", label: "T2"),
                SpawnConfig(x: 2, y: 5, delay: 100, speed: 0.9, dest: "출구", color: "#ff9100", label: "T3"),
            ]
        )
    }
    
    // ═══════════════════════════════════════════════════════════════
    // MARK: Level 6 — 과적 차량
    // 과적(⚠️) 차량이 커브에서 탈선
    // 스캐너로 감지 후 직선 우회
    // ═══════════════════════════════════════════════════════════════
    private static func level6() -> LevelDefinition {
        var tracks: [TrackCell] = []
        
        // 메인 직선 트랙
        for x in 2...13 {
            tracks.append(TrackCell(pos: GridPos(x: x, y: 5), type: .horizontal))
        }
        // 커브 경로 (위험)
        tracks.append(TrackCell(pos: GridPos(x: 5, y: 5), type: .junction))
        tracks.append(TrackCell(pos: GridPos(x: 5, y: 4), type: .curve))
        tracks.append(TrackCell(pos: GridPos(x: 6, y: 3), type: .curve))
        for x in 7...9 {
            tracks.append(TrackCell(pos: GridPos(x: x, y: 3), type: .horizontal))
        }
        tracks.append(TrackCell(pos: GridPos(x: 10, y: 4), type: .curve))
        tracks.append(TrackCell(pos: GridPos(x: 10, y: 5), type: .junction))
        
        return LevelDefinition(
            title: "과적 차량",
            incidents: [
                IncidentItem(boldText: "커브 탈선:", normalText: " 과적(⚠️) 차량이 커브에서 탈선"),
            ],
            objective: "스캐너(📡)를 설치하면 과적 차량을 감지하여 직선 경로로 보냅니다.",
            requiredPasses: 4,
            tools: [
                ToolSlot(type: .signal, maxCount: 2),
                ToolSlot(type: .scanner, maxCount: 1),
            ],
            tracks: tracks,
            destinations: [
                Destination(pos: GridPos(x: 13, y: 5), label: "출구"),
            ],
            spawns: [
                SpawnConfig(x: 2, y: 5, delay: 0, speed: 1.0, dest: "출구", color: "#40c4ff", label: "정상"),
                SpawnConfig(x: 2, y: 5, delay: 50, speed: 0.9, dest: "출구", color: "#ff3d3d", label: "⚠️과적", overloaded: true),
                SpawnConfig(x: 2, y: 5, delay: 100, speed: 1.0, dest: "출구", color: "#ffd600", label: "정상"),
                SpawnConfig(x: 2, y: 5, delay: 150, speed: 0.8, dest: "출구", color: "#ff3d3d", label: "⚠️과적", overloaded: true),
            ]
        )
    }
    
    // ═══════════════════════════════════════════════════════════════
    // MARK: Level 7 — 목적지 분기
    // 여러 목적지로 분기
    // 라우터로 자동 분기
    // ═══════════════════════════════════════════════════════════════
    private static func level7() -> LevelDefinition {
        var tracks: [TrackCell] = []
        
        // 입구 트랙
        for x in 2...6 {
            tracks.append(TrackCell(pos: GridPos(x: x, y: 5), type: .horizontal))
        }
        // 분기점
        tracks.append(TrackCell(pos: GridPos(x: 7, y: 5), type: .junction))
        // 위 경로 (A)
        tracks.append(TrackCell(pos: GridPos(x: 7, y: 4), type: .vertical))
        tracks.append(TrackCell(pos: GridPos(x: 7, y: 3), type: .vertical))
        for x in 8...13 {
            tracks.append(TrackCell(pos: GridPos(x: x, y: 3), type: .horizontal))
        }
        // 중간 경로 (B)
        for x in 8...13 {
            tracks.append(TrackCell(pos: GridPos(x: x, y: 5), type: .horizontal))
        }
        // 아래 경로 (C)
        tracks.append(TrackCell(pos: GridPos(x: 7, y: 6), type: .vertical))
        tracks.append(TrackCell(pos: GridPos(x: 7, y: 7), type: .vertical))
        for x in 8...13 {
            tracks.append(TrackCell(pos: GridPos(x: x, y: 7), type: .horizontal))
        }
        
        return LevelDefinition(
            title: "목적지 분기",
            incidents: [
                IncidentItem(boldText: "배송 오류:", normalText: " 화물이 잘못된 목적지로 배송됨"),
            ],
            objective: "라우터(🏷)를 분기점에 설치하면 화물 종류에 따라 자동 분기됩니다.",
            requiredPasses: 4,
            tools: [
                ToolSlot(type: .signal, maxCount: 2),
                ToolSlot(type: .router, maxCount: 1),
            ],
            tracks: tracks,
            destinations: [
                Destination(pos: GridPos(x: 13, y: 3), label: "석탄"),
                Destination(pos: GridPos(x: 13, y: 5), label: "승객"),
                Destination(pos: GridPos(x: 13, y: 7), label: "목재"),
            ],
            spawns: [
                SpawnConfig(x: 2, y: 5, delay: 0, speed: 1.0, dest: "석탄", color: "#424242", label: "석탄", cargo: .coal),
                SpawnConfig(x: 2, y: 5, delay: 50, speed: 1.0, dest: "승객", color: "#2196f3", label: "승객", cargo: .passenger),
                SpawnConfig(x: 2, y: 5, delay: 100, speed: 1.0, dest: "목재", color: "#795548", label: "목재", cargo: .wood),
                SpawnConfig(x: 2, y: 5, delay: 150, speed: 1.0, dest: "승객", color: "#2196f3", label: "승객", cargo: .passenger),
            ]
        )
    }
    
    // ═══════════════════════════════════════════════════════════════
    // MARK: Level 8 — 긴 열차
    // 긴 열차는 짧은 대피선에 못 들어감
    // 길이 체크로 분기
    // ═══════════════════════════════════════════════════════════════
    private static func level8() -> LevelDefinition {
        var tracks: [TrackCell] = []
        
        // 메인 트랙
        for x in 2...13 {
            tracks.append(TrackCell(pos: GridPos(x: x, y: 5), type: .horizontal))
        }
        // 분기점
        tracks.append(TrackCell(pos: GridPos(x: 5, y: 5), type: .junction))
        // 짧은 대피선 (위)
        tracks.append(TrackCell(pos: GridPos(x: 5, y: 4), type: .vertical))
        for x in 6...7 {
            tracks.append(TrackCell(pos: GridPos(x: x, y: 4), type: .horizontal))
        }
        // 긴 대피선 (아래)
        tracks.append(TrackCell(pos: GridPos(x: 5, y: 6), type: .vertical))
        for x in 6...10 {
            tracks.append(TrackCell(pos: GridPos(x: x, y: 6), type: .horizontal))
        }
        tracks.append(TrackCell(pos: GridPos(x: 11, y: 6), type: .vertical))
        tracks.append(TrackCell(pos: GridPos(x: 11, y: 5), type: .junction))
        
        return LevelDefinition(
            title: "긴 열차",
            incidents: [
                IncidentItem(boldText: "대피선 충돌:", normalText: " 긴 열차가 짧은 대피선에 진입"),
            ],
            objective: "길이검사기(📏)를 설치하여 긴 열차는 긴 대피선으로 보내세요.",
            requiredPasses: 3,
            tools: [
                ToolSlot(type: .signal, maxCount: 2),
                ToolSlot(type: .lengthCheck, maxCount: 1),
            ],
            tracks: tracks,
            destinations: [
                Destination(pos: GridPos(x: 13, y: 5), label: "출구"),
            ],
            spawns: [
                SpawnConfig(x: 2, y: 5, delay: 0, speed: 1.0, dest: "출구", color: "#40c4ff", label: "짧음", trainLength: 1),
                SpawnConfig(x: 2, y: 5, delay: 50, speed: 0.8, dest: "출구", color: "#ff5722", label: "긴열차", trainLength: 4),
                SpawnConfig(x: 2, y: 5, delay: 100, speed: 1.0, dest: "출구", color: "#ffd600", label: "짧음", trainLength: 1),
            ]
        )
    }
    
    // ═══════════════════════════════════════════════════════════════
    // MARK: Level 9 — 제한된 자원
    // 신호등 2개만으로 많은 기차 처리
    // 정밀한 타이밍 필요
    // ═══════════════════════════════════════════════════════════════
    private static func level9() -> LevelDefinition {
        var tracks: [TrackCell] = []
        
        // 메인 트랙
        for x in 2...13 {
            tracks.append(TrackCell(pos: GridPos(x: x, y: 5), type: .horizontal))
        }
        // 대피선 1
        tracks.append(TrackCell(pos: GridPos(x: 5, y: 5), type: .junction))
        tracks.append(TrackCell(pos: GridPos(x: 5, y: 4), type: .vertical))
        tracks.append(TrackCell(pos: GridPos(x: 5, y: 3), type: .vertical))
        for x in 6...8 {
            tracks.append(TrackCell(pos: GridPos(x: x, y: 3), type: .horizontal))
        }
        tracks.append(TrackCell(pos: GridPos(x: 9, y: 3), type: .vertical))
        tracks.append(TrackCell(pos: GridPos(x: 9, y: 4), type: .vertical))
        tracks.append(TrackCell(pos: GridPos(x: 9, y: 5), type: .junction))
        
        return LevelDefinition(
            title: "제한된 자원",
            incidents: [
                IncidentItem(boldText: "예산 삭감:", normalText: " 신호등 2개만 사용 가능"),
            ],
            objective: "신호등 2개만으로 5대의 기차를 안전하게 통과시키세요. 타이밍이 중요합니다!",
            requiredPasses: 5,
            tools: [
                ToolSlot(type: .signal, maxCount: 2),
            ],
            tracks: tracks,
            destinations: [
                Destination(pos: GridPos(x: 13, y: 5), label: "출구"),
            ],
            spawns: [
                SpawnConfig(x: 2, y: 5, delay: 0, speed: 1.0, dest: "출구", color: "#40c4ff", label: "T1"),
                SpawnConfig(x: 2, y: 5, delay: 20, speed: 1.2, dest: "출구", color: "#ffd600", label: "T2"),
                SpawnConfig(x: 2, y: 5, delay: 40, speed: 0.8, dest: "출구", color: "#ff9100", label: "T3"),
                SpawnConfig(x: 2, y: 5, delay: 70, speed: 1.0, dest: "출구", color: "#e040fb", label: "T4"),
                SpawnConfig(x: 2, y: 5, delay: 100, speed: 1.1, dest: "출구", color: "#00e676", label: "T5"),
            ]
        )
    }
    
    // ═══════════════════════════════════════════════════════════════
    // MARK: Level 10 — 종합 테스트
    // 모든 요소 종합
    // ═══════════════════════════════════════════════════════════════
    private static func level10() -> LevelDefinition {
        var tracks: [TrackCell] = []
        
        // 메인 트랙
        for x in 2...13 {
            tracks.append(TrackCell(pos: GridPos(x: x, y: 5), type: .horizontal))
        }
        // 내리막 구간
        for x in 4...5 {
            tracks.append(TrackCell(pos: GridPos(x: x, y: 5), type: .downhill))
        }
        // 분기점
        tracks.append(TrackCell(pos: GridPos(x: 7, y: 5), type: .junction))
        // 위 경로 (커브 - 과적 위험)
        tracks.append(TrackCell(pos: GridPos(x: 7, y: 4), type: .curve))
        tracks.append(TrackCell(pos: GridPos(x: 8, y: 3), type: .curve))
        for x in 9...13 {
            tracks.append(TrackCell(pos: GridPos(x: x, y: 3), type: .horizontal))
        }
        // 아래 경로 (직선 - 안전)
        tracks.append(TrackCell(pos: GridPos(x: 7, y: 6), type: .vertical))
        tracks.append(TrackCell(pos: GridPos(x: 7, y: 7), type: .vertical))
        for x in 8...13 {
            tracks.append(TrackCell(pos: GridPos(x: x, y: 7), type: .horizontal))
        }
        // 교차점
        tracks.append(TrackCell(pos: GridPos(x: 10, y: 4), type: .vertical))
        tracks.append(TrackCell(pos: GridPos(x: 10, y: 5), type: .cross))
        tracks.append(TrackCell(pos: GridPos(x: 10, y: 6), type: .vertical))
        
        return LevelDefinition(
            title: "종합 시스템 테스트",
            incidents: [
                IncidentItem(boldText: "최종 시험:", normalText: " 모든 시스템을 종합 운용"),
                IncidentItem(boldText: "주의:", normalText: " 내리막, 교차로, 과적, 목적지 분기"),
            ],
            objective: "내리막 제동, 과적 스캐너, 라우터, 인터락을 모두 활용하세요.",
            requiredPasses: 5,
            tools: [
                ToolSlot(type: .signal, maxCount: 4),
                ToolSlot(type: .brake, maxCount: 2),
                ToolSlot(type: .scanner, maxCount: 1),
                ToolSlot(type: .router, maxCount: 1),
                ToolSlot(type: .interlock, maxCount: 1),
            ],
            tracks: tracks,
            destinations: [
                Destination(pos: GridPos(x: 13, y: 3), label: "화물"),
                Destination(pos: GridPos(x: 13, y: 5), label: "승객"),
                Destination(pos: GridPos(x: 13, y: 7), label: "대형"),
            ],
            spawns: [
                SpawnConfig(x: 2, y: 5, delay: 0, speed: 1.0, dest: "승객", color: "#2196f3", label: "승객", cargo: .passenger),
                SpawnConfig(x: 2, y: 5, delay: 40, speed: 1.2, dest: "화물", color: "#ff3d3d", label: "⚠️과적", overloaded: true, cargo: .cargo),
                SpawnConfig(x: 2, y: 5, delay: 80, speed: 1.0, dest: "대형", color: "#795548", label: "대형", cargo: .wood),
                SpawnConfig(x: 2, y: 5, delay: 120, speed: 0.9, dest: "승객", color: "#2196f3", label: "승객", cargo: .passenger),
                SpawnConfig(x: 2, y: 5, delay: 160, speed: 1.1, dest: "화물", color: "#ff9100", label: "화물", cargo: .cargo),
            ]
        )
    }
}
