import Foundation
import SpriteKit

// MARK: - Game Constants
enum GameConstants {
    static let cellSize: CGFloat = 48
    static let trainSize: CGFloat = 36
    static let toolSize: CGFloat = 40
    static let moveTickRate: TimeInterval = 0.4  // seconds per move tick at 1x

    // Isometric tile dimensions
    static let isoTileWidth: CGFloat = 64
    static let isoTileHeight: CGFloat = 32
    static let isoOriginX: CGFloat = 500   // center of scene
    static let isoOriginY: CGFloat = 480   // top area, tiles go down-right

    // Grid dimensions
    static let gridCols: Int = 16
    static let gridRows: Int = 10

    // Z-Positions (layering)
    static let zGrid: CGFloat = 0
    static let zTrack: CGFloat = 1
    static let zDestination: CGFloat = 2
    static let zTool: CGFloat = 3
    static let zTrain: CGFloat = 10
    static let zUI: CGFloat = 20

    // Colors
    static let bgColor = NSColor(red: 0.04, green: 0.055, blue: 0.08, alpha: 1)
    static let gridColor = NSColor(white: 1, alpha: 0.03)
    static let trackColor = NSColor(red: 0.23, green: 0.29, blue: 0.36, alpha: 1)
    static let trackHighlight = NSColor(red: 0.35, green: 0.48, blue: 0.61, alpha: 1)
    static let accentGreen = NSColor(red: 0, green: 0.9, blue: 0.46, alpha: 1)
    static let accentRed = NSColor(red: 1, green: 0.24, blue: 0.24, alpha: 1)
    static let accentYellow = NSColor(red: 1, green: 0.84, blue: 0, alpha: 1)
    static let accentBlue = NSColor(red: 0.25, green: 0.77, blue: 1, alpha: 1)
    static let accentOrange = NSColor(red: 1, green: 0.57, blue: 0, alpha: 1)

    // MARK: - Isometric Depth Sorting
    static func isoZPosition(layer: CGFloat, gridX: Int, gridY: Int) -> CGFloat {
        let depthOrder = CGFloat(gridX + gridY) / 30.0
        return layer + depthOrder
    }
}

// MARK: - Track Type
enum TrackType: String, Codable {
    case horizontal
    case vertical
    case curve
    case junction
    case cross
    case downhill
}

// MARK: - Train Direction
enum TrainDirection: Codable {
    case right, left, up, down

    var dx: Int {
        switch self {
        case .right: return 1
        case .left: return -1
        default: return 0
        }
    }

    var dy: Int {
        switch self {
        case .down: return -1  // SpriteKit Y is flipped
        case .up: return 1
        default: return 0
        }
    }

    var opposite: TrainDirection {
        switch self {
        case .right: return .left
        case .left: return .right
        case .up: return .down
        case .down: return .up
        }
    }
}

// MARK: - Tool Type
enum ToolType: String, Codable, CaseIterable, Identifiable {
    case signal
    case scanner
    case waitline
    case switchTrack
    case router
    case brake
    case interlock
    case lengthCheck

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .signal: return "🚦"
        case .scanner: return "📡"
        case .waitline: return "⏸"
        case .switchTrack: return "🔀"
        case .router: return "🏷"
        case .brake: return "🛑"
        case .interlock: return "🔒"
        case .lengthCheck: return "📏"
        }
    }

    var displayName: String {
        switch self {
        case .signal: return "신호등"
        case .scanner: return "화물 스캐너"
        case .waitline: return "대기선"
        case .switchTrack: return "분기기"
        case .router: return "라우터"
        case .brake: return "제동 구간"
        case .interlock: return "인터락"
        case .lengthCheck: return "길이 검사"
        }
    }

    var description: String {
        switch self {
        case .signal: return "기차를 정지/출발 제어"
        case .scanner: return "과적 감지 후 경로 전환"
        case .waitline: return "기차를 일시 대기"
        case .switchTrack: return "트랙 방향 전환"
        case .router: return "화물 종류별 자동 분기"
        case .brake: return "기차 속도를 감속"
        case .interlock: return "교차로 상호 배제 제어"
        case .lengthCheck: return "열차 길이 확인 후 분기"
        }
    }
}

// MARK: - Cargo Type
enum CargoType: String, Codable {
    case passenger
    case coal
    case wood
    case cargo
    case urgent
}

// MARK: - Grid Position
struct GridPos: Hashable, Codable {
    let x: Int
    let y: Int

    func scenePosition() -> CGPoint {
        let isoX = CGFloat(x - y) * GameConstants.isoTileWidth / 2 + GameConstants.isoOriginX
        let isoY = -CGFloat(x + y) * GameConstants.isoTileHeight / 2 + GameConstants.isoOriginY
        return CGPoint(x: isoX, y: isoY)
    }

    func manhattanDistance(to other: GridPos) -> Int {
        abs(x - other.x) + abs(y - other.y)
    }
}

// MARK: - CGPoint Extensions
extension CGPoint {
    var normalized: CGPoint {
        let len = sqrt(x * x + y * y)
        guard len > 0 else { return .zero }
        return CGPoint(x: x / len, y: y / len)
    }

    static func * (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
        CGPoint(x: lhs.x * rhs, y: lhs.y * rhs)
    }

    static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }

    static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
}

// MARK: - Track Cell
struct TrackCell: Codable, Hashable {
    let pos: GridPos
    let type: TrackType
}

// MARK: - Destination
struct Destination: Codable {
    let pos: GridPos
    let label: String
}

// MARK: - Spawn Config
struct SpawnConfig: Codable {
    let pos: GridPos
    let delay: Int           // frames before spawn
    let speed: CGFloat
    let destination: String
    let colorHex: String
    let label: String
    let direction: TrainDirection
    let isOverloaded: Bool
    let cargo: CargoType?
    let trainLength: Int

    init(x: Int, y: Int, delay: Int, speed: CGFloat, dest: String,
         color: String, label: String, dir: TrainDirection = .right,
         overloaded: Bool = false, cargo: CargoType? = nil, trainLength: Int = 1) {
        self.pos = GridPos(x: x, y: y)
        self.delay = delay
        self.speed = speed
        self.destination = dest
        self.colorHex = color
        self.label = label
        self.direction = dir
        self.isOverloaded = overloaded
        self.cargo = cargo
        self.trainLength = trainLength
    }
}

// MARK: - Tool Slot (available tools for a level)
struct ToolSlot: Identifiable {
    let id = UUID()
    let type: ToolType
    var maxCount: Int
    var usedCount: Int = 0

    var remaining: Int { maxCount - usedCount }
}

// MARK: - Incident Item
struct IncidentItem {
    let boldText: String
    let normalText: String
}

// MARK: - Game State
enum GameState {
    case idle
    case running
    case paused
    case success
    case fail(String)
}

// MARK: - NSColor from hex
extension NSColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var rgb: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgb)
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: 1
        )
    }
}
