import SpriteKit

// MARK: - Game Scene Delegate
protocol GameSceneDelegate: AnyObject {
    func gameStateChanged(_ state: GameState)
    func trainPassedUpdated(passed: Int, required: Int)
    func collisionCountUpdated(_ count: Int)
    func derailmentCountUpdated(_ count: Int)
    func timerUpdated(_ seconds: Int)
}

// MARK: - Game Scene
class GameScene: SKScene {

    weak var gameDelegate: GameSceneDelegate?

    // State
    private(set) var gameState: GameState = .idle
    private var levelDef: LevelDefinition!
    private var currentLevelIndex: Int = 0

    // Entities
    private var trackNodes: [GridPos: SKNode] = [:]
    private var destinationNodes: [GridPos: SKNode] = [:]
    private var trainNodes: [TrainNode] = []
    private var toolNodes: [GridPos: PlacedToolNode] = [:]

    // Simulation
    private var spawnQueue: [(config: SpawnConfig, spawned: Bool)] = []
    private var simTick: Int = 0
    private var tickAccumulator: TimeInterval = 0
    private var simSpeed: CGFloat = 1
    private var trainsPassed: Int = 0
    private var collisionCount: Int = 0
    private var derailmentCount: Int = 0

    // Track lookup
    private var trackSet: Set<GridPos> = []
    private var trackTypeMap: [GridPos: TrackType] = [:]

    // Selected tool for placement
    var selectedToolType: ToolType?
    var toolSlots: [ToolSlot] = []  // managed by SwiftUI, referenced here

    // Callbacks for tool count updates
    var onToolUsed: ((ToolType, Bool) -> Void)?  // (type, isPlacing)

    // Camera for panning
    private let cameraNode = SKCameraNode()
    private var isDragging = false
    private var lastMousePosition = CGPoint.zero

    // MARK: - Setup

    override func didMove(to view: SKView) {
        backgroundColor = GameConstants.bgColor
        addChild(cameraNode)
        camera = cameraNode
        // Center camera on isometric grid center
        let midGrid = GridPos(x: GameConstants.gridCols / 2, y: GameConstants.gridRows / 2)
        cameraNode.position = midGrid.scenePosition()
    }

    func loadLevel(index: Int) {
        currentLevelIndex = index
        levelDef = LevelFactory.create(level: index)
        resetLevel()
    }

    func resetLevel() {
        // Clear everything
        removeAllChildren()
        trackNodes.removeAll()
        destinationNodes.removeAll()
        trainNodes.removeAll()
        toolNodes.removeAll()
        trackSet.removeAll()
        trackTypeMap.removeAll()

        gameState = .idle
        simTick = 0
        tickAccumulator = 0
        trainsPassed = 0
        collisionCount = 0
        derailmentCount = 0

        spawnQueue = levelDef.spawns.map { (config: $0, spawned: false) }

        // Build track lookup
        for track in levelDef.tracks {
            trackSet.insert(track.pos)
            trackTypeMap[track.pos] = track.type
        }

        // Re-add camera
        addChild(cameraNode)
        camera = cameraNode
        let midGrid = GridPos(x: GameConstants.gridCols / 2, y: GameConstants.gridRows / 2)
        cameraNode.position = midGrid.scenePosition()

        drawGrid()
        drawTracks()
        drawDestinations()

        gameDelegate?.gameStateChanged(.idle)
        gameDelegate?.trainPassedUpdated(passed: 0, required: levelDef.requiredPasses)
        gameDelegate?.collisionCountUpdated(0)
        gameDelegate?.derailmentCountUpdated(0)
        gameDelegate?.timerUpdated(0)
    }

    // MARK: - Isometric Helpers

    /// Create a diamond CGPath for an isometric tile
    private func diamondPath() -> CGPath {
        let tw = GameConstants.isoTileWidth
        let th = GameConstants.isoTileHeight
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: th / 2))       // top
        path.addLine(to: CGPoint(x: tw / 2, y: 0))     // right
        path.addLine(to: CGPoint(x: 0, y: -th / 2))    // bottom
        path.addLine(to: CGPoint(x: -tw / 2, y: 0))    // left
        path.closeSubpath()
        return path
    }

    /// Isometric direction vectors for tile edges
    /// "right" on the iso grid: from left vertex to bottom vertex direction → (+tw/2, -th/2)
    private var isoRight: CGPoint {
        CGPoint(x: GameConstants.isoTileWidth / 2, y: -GameConstants.isoTileHeight / 2)
    }
    /// "down" on the iso grid: from top vertex to right vertex → but we use grid-down = (+tw/2, +th/2) visually going down-left
    private var isoDown: CGPoint {
        CGPoint(x: -GameConstants.isoTileWidth / 2, y: -GameConstants.isoTileHeight / 2)
    }

    // MARK: - Drawing

    private func drawGrid() {
        let cols = GameConstants.gridCols
        let rows = GameConstants.gridRows

        for gx in 0..<cols {
            for gy in 0..<rows {
                let pos = GridPos(x: gx, y: gy)
                let center = pos.scenePosition()

                let tile = SKShapeNode(path: diamondPath())
                tile.position = center
                tile.fillColor = .clear
                tile.strokeColor = GameConstants.gridColor
                tile.lineWidth = 0.5
                tile.zPosition = GameConstants.zGrid
                // Subtle ground shading: tiles further from camera are slightly darker
                let shade = 1.0 - CGFloat(gx + gy) * 0.008
                tile.alpha = shade
                addChild(tile)
            }
        }
    }

    private func drawTracks() {
        for track in levelDef.tracks {
            let node = createTrackNode(track)
            node.position = track.pos.scenePosition()
            node.zPosition = GameConstants.isoZPosition(layer: GameConstants.zTrack, gridX: track.pos.x, gridY: track.pos.y)
            addChild(node)
            trackNodes[track.pos] = node
        }
    }

    private func createTrackNode(_ track: TrackCell) -> SKNode {
        let container = SKNode()
        let tw = GameConstants.isoTileWidth
        let th = GameConstants.isoTileHeight

        // Diamond background fill
        let bg = SKShapeNode(path: diamondPath())
        bg.fillColor = NSColor(white: 1, alpha: 0.02)
        bg.strokeColor = .clear
        container.addChild(bg)

        switch track.type {
        case .horizontal, .downhill:
            // Rails along iso-X axis: left vertex → right vertex
            addIsoRails(to: container, from: CGPoint(x: -tw / 2, y: 0), to: CGPoint(x: tw / 2, y: 0), color: GameConstants.trackColor)

            if track.type == .downhill {
                let overlay = SKShapeNode(path: diamondPath())
                overlay.fillColor = NSColor(red: 1, green: 0.57, blue: 0, alpha: 0.12)
                overlay.strokeColor = .clear
                container.addChild(overlay)

                let arrow = SKLabelNode(text: "▼▼")
                arrow.fontName = "Menlo"
                arrow.fontSize = 9
                arrow.fontColor = GameConstants.accentOrange
                arrow.position = CGPoint(x: 0, y: -th / 2 + 4)
                arrow.verticalAlignmentMode = .center
                container.addChild(arrow)
            }

        case .vertical:
            // Rails along iso-Y axis: top vertex → bottom vertex
            addIsoRails(to: container, from: CGPoint(x: 0, y: th / 2), to: CGPoint(x: 0, y: -th / 2), color: GameConstants.trackColor)

        case .junction:
            let overlay = SKShapeNode(path: diamondPath())
            overlay.fillColor = NSColor(red: 0, green: 0.9, blue: 0.46, alpha: 0.06)
            overlay.strokeColor = .clear
            container.addChild(overlay)

            // Horizontal rail (left→right)
            addIsoRails(to: container, from: CGPoint(x: -tw / 2, y: 0), to: CGPoint(x: tw / 2, y: 0), color: GameConstants.trackHighlight)
            // Vertical rail (top→bottom)
            addIsoRails(to: container, from: CGPoint(x: 0, y: th / 2), to: CGPoint(x: 0, y: -th / 2), color: GameConstants.trackHighlight)

        case .cross:
            let overlay = SKShapeNode(path: diamondPath())
            overlay.fillColor = NSColor(red: 1, green: 0.24, blue: 0.24, alpha: 0.1)
            overlay.strokeColor = .clear
            container.addChild(overlay)

            addIsoRails(to: container, from: CGPoint(x: -tw / 2, y: 0), to: CGPoint(x: tw / 2, y: 0), color: GameConstants.trackHighlight)
            addIsoRails(to: container, from: CGPoint(x: 0, y: th / 2), to: CGPoint(x: 0, y: -th / 2), color: GameConstants.trackHighlight)

            let crossMark = SKLabelNode(text: "✕")
            crossMark.fontName = "Menlo-Bold"
            crossMark.fontSize = 10
            crossMark.fontColor = GameConstants.accentRed.withAlphaComponent(0.6)
            crossMark.verticalAlignmentMode = .center
            container.addChild(crossMark)

        case .curve:
            let overlay = SKShapeNode(path: diamondPath())
            overlay.fillColor = NSColor(red: 1, green: 0.84, blue: 0, alpha: 0.05)
            overlay.strokeColor = .clear
            container.addChild(overlay)

            // Bezier curve connecting two adjacent iso vertices (left→top)
            let arc = SKShapeNode()
            let arcPath = CGMutablePath()
            let start = CGPoint(x: -tw / 2, y: 0)     // left vertex
            let end = CGPoint(x: 0, y: th / 2)         // top vertex
            let cp = CGPoint(x: -tw / 6, y: th / 4)
            arcPath.move(to: start)
            arcPath.addQuadCurve(to: end, control: cp)
            arc.path = arcPath
            arc.strokeColor = GameConstants.trackColor
            arc.lineWidth = 3
            arc.fillColor = .clear
            arc.lineCap = .round
            container.addChild(arc)

            // Second rail line offset slightly
            let arc2 = SKShapeNode()
            let arcPath2 = CGMutablePath()
            let offset: CGFloat = 3
            let start2 = CGPoint(x: start.x + offset, y: start.y + offset * 0.5)
            let end2 = CGPoint(x: end.x + offset, y: end.y - offset * 0.5)
            let cp2 = CGPoint(x: cp.x + offset, y: cp.y)
            arcPath2.move(to: start2)
            arcPath2.addQuadCurve(to: end2, control: cp2)
            arc2.path = arcPath2
            arc2.strokeColor = GameConstants.trackColor
            arc2.lineWidth = 2
            arc2.fillColor = .clear
            arc2.lineCap = .round
            container.addChild(arc2)
        }

        return container
    }

    /// Draw two parallel rails + ties between two points (isometric style)
    private func addIsoRails(to container: SKNode, from start: CGPoint, to end: CGPoint, color: NSColor) {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let len = sqrt(dx * dx + dy * dy)
        guard len > 0 else { return }

        // Perpendicular offset for parallel rails
        let perpX = -dy / len * 3
        let perpY = dx / len * 3

        // Rail 1
        let rail1 = SKShapeNode()
        let path1 = CGMutablePath()
        path1.move(to: CGPoint(x: start.x + perpX, y: start.y + perpY))
        path1.addLine(to: CGPoint(x: end.x + perpX, y: end.y + perpY))
        rail1.path = path1
        rail1.strokeColor = color
        rail1.lineWidth = 2.5
        rail1.lineCap = .round
        container.addChild(rail1)

        // Rail 2
        let rail2 = SKShapeNode()
        let path2 = CGMutablePath()
        path2.move(to: CGPoint(x: start.x - perpX, y: start.y - perpY))
        path2.addLine(to: CGPoint(x: end.x - perpX, y: end.y - perpY))
        rail2.path = path2
        rail2.strokeColor = color
        rail2.lineWidth = 2.5
        rail2.lineCap = .round
        container.addChild(rail2)

        // Ties (cross bars)
        let tieCount = 5
        for i in 0..<tieCount {
            let t = CGFloat(i + 1) / CGFloat(tieCount + 1)
            let mx = start.x + dx * t
            let my = start.y + dy * t

            let tie = SKShapeNode()
            let tiePath = CGMutablePath()
            tiePath.move(to: CGPoint(x: mx + perpX * 1.5, y: my + perpY * 1.5))
            tiePath.addLine(to: CGPoint(x: mx - perpX * 1.5, y: my - perpY * 1.5))
            tie.path = tiePath
            tie.strokeColor = color.withAlphaComponent(0.4)
            tie.lineWidth = 2
            container.addChild(tie)
        }
    }

    private func drawDestinations() {
        for dest in levelDef.destinations {
            let container = SKNode()
            container.position = dest.pos.scenePosition()
            container.zPosition = GameConstants.isoZPosition(layer: GameConstants.zDestination, gridX: dest.pos.x, gridY: dest.pos.y)

            let bg = SKShapeNode(path: diamondPath())
            bg.fillColor = NSColor(red: 0, green: 0.9, blue: 0.46, alpha: 0.08)
            bg.strokeColor = GameConstants.accentGreen
            bg.lineWidth = 2
            container.addChild(bg)

            let label = SKLabelNode(text: dest.label)
            label.fontName = "Menlo-Bold"
            label.fontSize = 10
            label.fontColor = GameConstants.accentGreen
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            container.addChild(label)

            // Pulse animation
            let fadeOut = SKAction.fadeAlpha(to: 0.5, duration: 1)
            let fadeIn = SKAction.fadeAlpha(to: 1, duration: 1)
            bg.run(SKAction.repeatForever(SKAction.sequence([fadeOut, fadeIn])))

            addChild(container)
            destinationNodes[dest.pos] = container
        }
    }

    // MARK: - Simulation Control

    func startSimulation() {
        guard case .idle = gameState else { return }

        gameState = .running
        simTick = 0
        tickAccumulator = 0
        trainsPassed = 0
        collisionCount = 0
        derailmentCount = 0

        // Remove old trains
        trainNodes.forEach { $0.removeFromParent() }
        trainNodes.removeAll()

        spawnQueue = levelDef.spawns.map { (config: $0, spawned: false) }

        gameDelegate?.gameStateChanged(.running)
    }

    func pauseSimulation() {
        guard case .running = gameState else { return }
        gameState = .paused
        gameDelegate?.gameStateChanged(.paused)
    }

    func resumeSimulation() {
        guard case .paused = gameState else { return }
        gameState = .running
        gameDelegate?.gameStateChanged(.running)
    }

    func setSimSpeed(_ speed: CGFloat) {
        simSpeed = speed
    }

    // MARK: - Game Loop

    override func update(_ currentTime: TimeInterval) {
        guard case .running = gameState else { return }

        let tickInterval = GameConstants.moveTickRate / TimeInterval(simSpeed)
        tickAccumulator += 1.0 / 60.0  // assuming 60fps

        while tickAccumulator >= tickInterval {
            tickAccumulator -= tickInterval
            simTick += 1

            processSpawns()
            processTrains()
            checkCollisions()
            checkDerailments()
            checkWinCondition()

            gameDelegate?.timerUpdated(simTick)
        }
    }

    private func processSpawns() {
        for i in spawnQueue.indices {
            guard !spawnQueue[i].spawned else { continue }
            guard simTick >= spawnQueue[i].config.delay else { continue }

            spawnQueue[i].spawned = true
            let config = spawnQueue[i].config

            let train = TrainNode(config: config)
            addChild(train)
            trainNodes.append(train)
        }
    }

    private func processTrains() {
        for train in trainNodes {
            guard !train.isFinished && !train.isStopped else {
                // Check if stopped at signal and signal turned green
                if train.isStopped {
                    let pos = GridPos(x: train.gridX, y: train.gridY)
                    if let tool = toolNodes[pos], tool.toolType == .signal, tool.isActive {
                        train.isStopped = false
                        train.updateStopState()
                    }
                }
                continue
            }

            // Calculate effective speed
            var effectiveSpeed = train.trainSpeed
            let currentPos = GridPos(x: train.gridX, y: train.gridY)

            // Brake check
            if let tool = toolNodes[currentPos], tool.toolType == .brake {
                effectiveSpeed = min(effectiveSpeed, 0.5)
            }

            // Downhill acceleration
            if trackTypeMap[currentPos] == .downhill {
                if toolNodes[currentPos]?.toolType != .brake {
                    effectiveSpeed *= 1.5
                }
            }

            train.trainSpeed = effectiveSpeed
            train.updateSpeedIndicator()

            // Move accumulator
            train.moveAccumulator += effectiveSpeed * 0.15
            guard train.moveAccumulator >= 1 else { continue }
            train.moveAccumulator = 0

            // Determine next position
            let nextPos = determineNextPosition(for: train)

            // Check for signal at next position
            if let tool = toolNodes[nextPos], tool.toolType == .signal, !tool.isActive {
                train.isStopped = true
                train.updateStopState()
                continue
            }

            // Interlock check
            if let tool = toolNodes[nextPos], tool.toolType == .interlock {
                let otherTrainOnCrossing = trainNodes.first {
                    !$0.isFinished && $0.trainID != train.trainID &&
                    GridPos(x: $0.gridX, y: $0.gridY) == nextPos
                }
                if otherTrainOnCrossing != nil {
                    train.isStopped = true
                    train.updateStopState()
                    continue
                }
            }

            // Move train
            let duration = GameConstants.moveTickRate / TimeInterval(simSpeed)
            train.moveTo(gridPos: nextPos, duration: duration * 0.8)

            // Check arrival at destination
            if let dest = levelDef.destinations.first(where: { $0.pos == nextPos }) {
                let correctDest = dest.label == train.destination ||
                                  train.destination == nil ||
                                  levelDef.destinations.count == 1
                if correctDest {
                    train.animateArrival()
                    trainsPassed += 1
                    gameDelegate?.trainPassedUpdated(passed: trainsPassed, required: levelDef.requiredPasses)
                }
            }

            // Out of bounds check using grid constants
            let cols = GameConstants.gridCols
            let rows = GameConstants.gridRows
            if train.gridX < -1 || train.gridX > cols + 1 || train.gridY < -1 || train.gridY > rows + 1 {
                train.isFinished = true
                train.removeFromParent()
            }
        }
    }

    private func determineNextPosition(for train: TrainNode) -> GridPos {
        let currentPos = GridPos(x: train.gridX, y: train.gridY)

        // Check for router
        if let tool = toolNodes[currentPos], tool.toolType == .router,
           let dest = train.destination,
           let destInfo = levelDef.destinations.first(where: { $0.label == dest }) {
            let neighbors = connectedNeighbors(from: currentPos, direction: train.direction)
            return closestNeighborTo(target: destInfo.pos, from: neighbors) ?? defaultNextPos(from: currentPos, direction: train.direction)
        }

        // Check for scanner (overloaded → bypass down)
        if let tool = toolNodes[currentPos], tool.toolType == .scanner, train.isOverloaded {
            let neighbors = connectedNeighbors(from: currentPos, direction: train.direction)
            // Prefer going down/up to bypass
            if let bypass = neighbors.first(where: { $0.y != currentPos.y }) {
                updateTrainDirection(train, to: bypass)
                return bypass
            }
        }

        // Check for length check
        if let tool = toolNodes[currentPos], tool.toolType == .lengthCheck {
            let neighbors = connectedNeighbors(from: currentPos, direction: train.direction)
            if train.trainLength > 2 {
                // Long train → go down (longer siding)
                if let longRoute = neighbors.first(where: { $0.y < currentPos.y }) {
                    updateTrainDirection(train, to: longRoute)
                    return longRoute
                }
            } else {
                // Short train → go up (shorter siding)
                if let shortRoute = neighbors.first(where: { $0.y > currentPos.y }) {
                    updateTrainDirection(train, to: shortRoute)
                    return shortRoute
                }
            }
        }

        // Default movement
        let next = defaultNextPos(from: currentPos, direction: train.direction)
        updateTrainDirection(train, to: next)
        return next
    }

    private func connectedNeighbors(from pos: GridPos, direction: TrainDirection) -> [GridPos] {
        let candidates = [
            GridPos(x: pos.x + 1, y: pos.y),
            GridPos(x: pos.x - 1, y: pos.y),
            GridPos(x: pos.x, y: pos.y + 1),
            GridPos(x: pos.x, y: pos.y - 1),
        ]

        let onTrack = candidates.filter { trackSet.contains($0) }

        // Filter out going backward
        let forward = onTrack.filter { neighbor in
            switch direction {
            case .right: return neighbor.x >= pos.x
            case .left: return neighbor.x <= pos.x
            case .up: return neighbor.y >= pos.y
            case .down: return neighbor.y <= pos.y
            }
        }

        return forward.isEmpty ? onTrack : forward
    }

    private func defaultNextPos(from pos: GridPos, direction: TrainDirection) -> GridPos {
        let neighbors = connectedNeighbors(from: pos, direction: direction)

        // Prefer continuing in same direction
        let preferred: GridPos
        switch direction {
        case .right: preferred = GridPos(x: pos.x + 1, y: pos.y)
        case .left: preferred = GridPos(x: pos.x - 1, y: pos.y)
        case .up: preferred = GridPos(x: pos.x, y: pos.y + 1)
        case .down: preferred = GridPos(x: pos.x, y: pos.y - 1)
        }

        if neighbors.contains(preferred) { return preferred }
        return neighbors.first ?? preferred
    }

    private func closestNeighborTo(target: GridPos, from neighbors: [GridPos]) -> GridPos? {
        neighbors.min(by: { $0.manhattanDistance(to: target) < $1.manhattanDistance(to: target) })
    }

    private func updateTrainDirection(_ train: TrainNode, to next: GridPos) {
        let current = GridPos(x: train.gridX, y: train.gridY)
        if next.x > current.x { train.direction = .right }
        else if next.x < current.x { train.direction = .left }
        else if next.y > current.y { train.direction = .up }
        else if next.y < current.y { train.direction = .down }
    }

    // MARK: - Collision & Derailment Checks

    private func checkCollisions() {
        let active = trainNodes.filter { !$0.isFinished }
        for i in 0..<active.count {
            for j in (i+1)..<active.count {
                if active[i].gridX == active[j].gridX && active[i].gridY == active[j].gridY {
                    collisionCount += 1
                    active[i].animateCrash()
                    active[j].animateCrash()

                    let msg = "\(active[i].trainLabel)과(와) \(active[j].trainLabel)이(가) 충돌했습니다!"
                    gameState = .fail(msg)
                    gameDelegate?.collisionCountUpdated(collisionCount)
                    gameDelegate?.gameStateChanged(gameState)
                    return
                }
            }
        }
    }

    private func checkDerailments() {
        for train in trainNodes where !train.isFinished {
            let pos = GridPos(x: train.gridX, y: train.gridY)

            // Overloaded on curve
            if train.isOverloaded && trackTypeMap[pos] == .curve {
                derailmentCount += 1
                train.animateDerail()
                let msg = "\(train.trainLabel)이(가) 커브에서 탈선했습니다! (과적)"
                gameState = .fail(msg)
                gameDelegate?.derailmentCountUpdated(derailmentCount)
                gameDelegate?.gameStateChanged(gameState)
                return
            }

            // Overspeed on downhill
            if trackTypeMap[pos] == .downhill && train.trainSpeed > 1.2 {
                if toolNodes[pos]?.toolType != .brake {
                    // Probability-based derailment
                    if Int.random(in: 0..<100) < 5 {
                        derailmentCount += 1
                        train.animateDerail()
                        let msg = "\(train.trainLabel)이(가) 내리막에서 과속 탈선했습니다!"
                        gameState = .fail(msg)
                        gameDelegate?.derailmentCountUpdated(derailmentCount)
                        gameDelegate?.gameStateChanged(gameState)
                        return
                    }
                }
            }
        }
    }

    private func checkWinCondition() {
        if trainsPassed >= levelDef.requiredPasses {
            gameState = .success
            gameDelegate?.gameStateChanged(.success)
        }
    }

    // MARK: - Mouse Input

    override func mouseDown(with event: NSEvent) {
        isDragging = false
        lastMousePosition = event.locationInWindow
    }

    override func mouseDragged(with event: NSEvent) {
        let current = event.locationInWindow
        let dx = current.x - lastMousePosition.x
        let dy = current.y - lastMousePosition.y

        if !isDragging {
            let dist = sqrt(dx * dx + dy * dy)
            if dist > 3 { isDragging = true }
        }

        if isDragging {
            cameraNode.position.x -= dx
            cameraNode.position.y -= dy
            lastMousePosition = current
        }
    }

    override func mouseUp(with event: NSEvent) {
        guard !isDragging else { return }

        let location = event.location(in: self)
        let gridPos = sceneToGrid(location)

        switch gameState {
        case .running, .paused:
            if let tool = toolNodes[gridPos], tool.toolType == .signal {
                tool.toggle()
            }
        case .idle:
            if let toolType = selectedToolType {
                placeTool(toolType, at: gridPos)
            }
        default:
            break
        }
    }

    override func scrollWheel(with event: NSEvent) {
        cameraNode.position.x -= event.scrollingDeltaX
        cameraNode.position.y += event.scrollingDeltaY
    }

    override func rightMouseDown(with event: NSEvent) {
        let location = event.location(in: self)
        let gridPos = sceneToGrid(location)

        guard case .idle = gameState else { return }
        removeTool(at: gridPos)
    }

    /// Convert isometric scene coordinates back to grid position
    private func sceneToGrid(_ point: CGPoint) -> GridPos {
        let adjustedX = point.x - GameConstants.isoOriginX
        let adjustedY = -(point.y - GameConstants.isoOriginY)
        let tw = GameConstants.isoTileWidth
        let th = GameConstants.isoTileHeight
        let gx = Int(floor(adjustedX / tw + adjustedY / th))
        let gy = Int(floor(adjustedY / th - adjustedX / tw))
        return GridPos(x: gx, y: gy)
    }

    // MARK: - Tool Placement

    func placeTool(_ type: ToolType, at gridPos: GridPos) {
        guard trackSet.contains(gridPos) else { return }
        guard toolNodes[gridPos] == nil else { return }

        let node = PlacedToolNode(gridPos: gridPos, toolType: type)
        addChild(node)
        toolNodes[gridPos] = node
        onToolUsed?(type, true)
    }

    func removeTool(at gridPos: GridPos) {
        guard let node = toolNodes[gridPos] else { return }
        let type = node.toolType
        node.animateRemove { [weak self] in
            self?.toolNodes.removeValue(forKey: gridPos)
            self?.onToolUsed?(type, false)
        }
    }

    func removeAllTools() {
        for (pos, _) in toolNodes {
            removeTool(at: pos)
        }
    }
}
