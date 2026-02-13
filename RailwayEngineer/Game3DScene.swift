import SceneKit
import SwiftUI

// MARK: - 3D Game Scene
class Game3DScene: NSObject, ObservableObject {
    let scene: SCNScene
    private var cameraNode: SCNNode!
    private var cameraOrbitNode: SCNNode!
    
    // Wave System
    private let waveGenerator = WaveGenerator()
    @Published var currentWave: Int = 0
    private var currentWaveDef: WaveDefinition?
    private var accumulatedTools: [ToolType: Int] = [:]  // 누적 도구 수량
    
    // State
    @Published var gameState: GameState = .idle
    private var levelDef: LevelDefinition!
    private var currentLevelIndex: Int = 0
    
    // Entities
    private var trackNodes: [GridPos: SCNNode] = [:]
    private var destinationNodes: [GridPos: SCNNode] = [:]
    private var trainNodes: [Train3DNode] = []
    private var toolNodes: [GridPos: Tool3DNode] = [:]
    private var gridTileNodes: [SCNNode] = []  // 그리드 타일 노드들
    
    // Track lookup
    private var trackSet: Set<GridPos> = []
    private var trackTypeMap: [GridPos: TrackType] = [:]
    private var allTracks: [TrackCell] = []
    private var allDestinations: [Destination] = []
    
    // Simulation
    private var spawnQueue: [(config: SpawnConfig, spawned: Bool)] = []
    private var simTick: Int = 0
    private var simSpeed: CGFloat = 1
    private var trainsPassed: Int = 0
    private var collisionCount: Int = 0
    private var derailmentCount: Int = 0
    private var totalTrainsPassed: Int = 0  // 전체 누적
    
    // Selection
    var selectedToolType: ToolType?
    var toolSlots: [ToolSlot] = []
    
    // Callbacks
    var onStateChanged: ((GameState) -> Void)?
    var onTrainsPassed: ((Int, Int) -> Void)?
    var onCollision: ((Int) -> Void)?
    var onDerailment: ((Int) -> Void)?
    var onTimerUpdated: ((Int) -> Void)?
    var onToolUsed: ((ToolType, Bool) -> Void)?
    var onWaveChanged: ((Int, String, String) -> Void)?  // (wave, title, description)
    var onWaveComplete: ((Int) -> Void)?  // 웨이브 완료
    
    // Constants
    private let tileSize: CGFloat = 1.0
    private let tileHeight: CGFloat = 0.15
    private let trackHeight: CGFloat = 0.05
    
    override init() {
        scene = SCNScene()
        super.init()
        setupScene()
    }
    
    // MARK: - Scene Setup
    
    private func setupScene() {
        scene.background.contents = NSColor(red: 0.02, green: 0.04, blue: 0.06, alpha: 1.0)
        scene.fogStartDistance = 15
        scene.fogEndDistance = 40
        scene.fogColor = NSColor(red: 0.02, green: 0.04, blue: 0.06, alpha: 1.0)
        
        setupCamera()
        setupLighting()
        setupGround()
    }
    
    private func setupCamera() {
        cameraOrbitNode = SCNNode()
        cameraOrbitNode.position = SCNVector3(
            CGFloat(GameConstants.gridCols) / 2,
            0,
            CGFloat(GameConstants.gridRows) / 2
        )
        scene.rootNode.addChildNode(cameraOrbitNode)
        
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = 45
        cameraNode.camera?.zNear = 0.1
        cameraNode.camera?.zFar = 100
        cameraNode.position = SCNVector3(0, 12, 12)
        cameraNode.eulerAngles = SCNVector3(-CGFloat.pi / 5, 0, 0)
        
        cameraOrbitNode.addChildNode(cameraNode)
    }
    
    private func setupLighting() {
        let sunNode = SCNNode()
        sunNode.light = SCNLight()
        sunNode.light?.type = .directional
        sunNode.light?.color = NSColor(red: 1.0, green: 0.95, blue: 0.9, alpha: 1.0)
        sunNode.light?.intensity = 800
        sunNode.light?.castsShadow = true
        sunNode.light?.shadowMode = .deferred
        sunNode.light?.shadowColor = NSColor(white: 0, alpha: 0.5)
        sunNode.light?.shadowMapSize = CGSize(width: 2048, height: 2048)
        sunNode.eulerAngles = SCNVector3(-CGFloat.pi / 3, CGFloat.pi / 4, 0)
        scene.rootNode.addChildNode(sunNode)
        
        let ambientNode = SCNNode()
        ambientNode.light = SCNLight()
        ambientNode.light?.type = .ambient
        ambientNode.light?.color = NSColor(red: 0.15, green: 0.2, blue: 0.3, alpha: 1.0)
        ambientNode.light?.intensity = 400
        scene.rootNode.addChildNode(ambientNode)
        
        let fillNode = SCNNode()
        fillNode.light = SCNLight()
        fillNode.light?.type = .directional
        fillNode.light?.color = NSColor(red: 0.4, green: 0.6, blue: 0.9, alpha: 1.0)
        fillNode.light?.intensity = 200
        fillNode.eulerAngles = SCNVector3(-CGFloat.pi / 4, -CGFloat.pi / 2, 0)
        scene.rootNode.addChildNode(fillNode)
    }
    
    private func setupGround() {
        let groundGeometry = SCNPlane(width: 50, height: 50)
        let groundMaterial = SCNMaterial()
        groundMaterial.diffuse.contents = NSColor(red: 0.03, green: 0.05, blue: 0.08, alpha: 1.0)
        groundMaterial.roughness.contents = 0.9
        groundGeometry.materials = [groundMaterial]
        
        let groundNode = SCNNode(geometry: groundGeometry)
        groundNode.eulerAngles.x = -CGFloat.pi / 2
        groundNode.position = SCNVector3(
            CGFloat(GameConstants.gridCols) / 2,
            -0.5,
            CGFloat(GameConstants.gridRows) / 2
        )
        scene.rootNode.addChildNode(groundNode)
    }
    
    // MARK: - Level Loading (Legacy)
    
    func loadLevel(index: Int) {
        // 웨이브 모드로 시작
        startWaveMode()
    }
    
    // MARK: - Wave System
    
    func startWaveMode() {
        currentWave = 0
        accumulatedTools.removeAll()
        totalTrainsPassed = 0
        
        // 기본 트랙과 목적지 설정
        allTracks = waveGenerator.baseTrack()
        allDestinations = waveGenerator.baseDestinations()
        
        // 씬 초기화
        clearScene()
        buildBaseMap()
        
        // 첫 웨이브 시작
        startWave(1)
    }
    
    func startWave(_ waveNumber: Int) {
        currentWave = waveNumber
        let waveDef = waveGenerator.generateWave(waveNumber)
        currentWaveDef = waveDef
        
        // 새 트랙 추가
        for track in waveDef.newTracks {
            if !allTracks.contains(where: { $0.pos == track.pos }) {
                allTracks.append(track)
                addTrackNode(track)
            }
        }
        
        // 새 목적지 추가
        for dest in waveDef.newDestinations {
            if !allDestinations.contains(where: { $0.pos == dest.pos }) {
                allDestinations.append(dest)
                addDestinationNode(dest)
            }
        }
        
        // 트랙 룩업 갱신
        trackSet.removeAll()
        trackTypeMap.removeAll()
        for track in allTracks {
            trackSet.insert(track.pos)
            trackTypeMap[track.pos] = track.type
        }
        
        // 도구 누적
        for newTool in waveDef.newTools {
            accumulatedTools[newTool.type, default: 0] += newTool.maxCount
        }
        
        // 도구 슬롯 업데이트 (누적 - 사용중)
        updateToolSlots()
        
        // 스폰 큐 설정
        spawnQueue = waveDef.spawns.map { (config: $0, spawned: false) }
        
        // 이전 기차들 제거
        trainNodes.forEach { $0.removeFromParentNode() }
        trainNodes.removeAll()
        
        // 상태 초기화
        gameState = .idle
        simTick = 0
        trainsPassed = 0
        
        onStateChanged?(.idle)
        onTrainsPassed?(0, waveDef.requiredPasses)
        onWaveChanged?(waveNumber, waveDef.title, waveDef.description)
    }
    
    private func updateToolSlots() {
        var newSlots: [ToolSlot] = []
        
        for (toolType, maxCount) in accumulatedTools {
            // 현재 배치된 도구 수 계산
            let usedCount = toolNodes.values.filter { $0.toolType == toolType }.count
            var slot = ToolSlot(type: toolType, maxCount: maxCount)
            slot.usedCount = usedCount
            newSlots.append(slot)
        }
        
        // 타입 순서대로 정렬
        newSlots.sort { $0.type.rawValue < $1.type.rawValue }
        toolSlots = newSlots
    }
    
    func nextWave() {
        startWave(currentWave + 1)
    }
    
    func resetLevel() {
        // 현재 웨이브 다시 시작
        if let waveDef = currentWaveDef {
            spawnQueue = waveDef.spawns.map { (config: $0, spawned: false) }
            
            trainNodes.forEach { $0.removeFromParentNode() }
            trainNodes.removeAll()
            
            gameState = .idle
            simTick = 0
            trainsPassed = 0
            collisionCount = 0
            derailmentCount = 0
            
            onStateChanged?(.idle)
            onTrainsPassed?(0, waveDef.requiredPasses)
            onCollision?(0)
            onDerailment?(0)
            onTimerUpdated?(0)
        }
    }
    
    func fullReset() {
        // 완전 초기화 (웨이브 1부터)
        clearScene()
        for (_, node) in toolNodes { node.removeFromParentNode() }
        toolNodes.removeAll()
        accumulatedTools.removeAll()
        startWaveMode()
    }
    
    private func clearScene() {
        for (_, node) in trackNodes { node.removeFromParentNode() }
        for (_, node) in destinationNodes { node.removeFromParentNode() }
        for train in trainNodes { train.removeFromParentNode() }
        for node in gridTileNodes { node.removeFromParentNode() }
        
        trackNodes.removeAll()
        destinationNodes.removeAll()
        trainNodes.removeAll()
        gridTileNodes.removeAll()
        trackSet.removeAll()
        trackTypeMap.removeAll()
        
        collisionCount = 0
        derailmentCount = 0
    }
    
    private func buildBaseMap() {
        // 트랙 설정
        for track in allTracks {
            trackSet.insert(track.pos)
            trackTypeMap[track.pos] = track.type
        }
        
        buildGrid()
        buildTracks()
        buildDestinations()
    }
    
    private func addTrackNode(_ track: TrackCell) {
        trackSet.insert(track.pos)
        trackTypeMap[track.pos] = track.type
        
        let node = createTrackNode(track)
        node.position = gridToWorld(track.pos)
        node.position.y = tileHeight + trackHeight / 2
        scene.rootNode.addChildNode(node)
        trackNodes[track.pos] = node
    }
    
    private func addDestinationNode(_ dest: Destination) {
        let node = createDestinationNode(dest)
        node.position = gridToWorld(dest.pos)
        node.position.y = tileHeight
        scene.rootNode.addChildNode(node)
        destinationNodes[dest.pos] = node
    }
    
    // MARK: - Grid Building
    
    private func buildGrid() {
        let cols = GameConstants.gridCols
        let rows = GameConstants.gridRows
        
        for gx in 0..<cols {
            for gy in 0..<rows {
                let hasTrack = trackSet.contains(GridPos(x: gx, y: gy))
                createGridTile(x: gx, z: gy, hasTrack: hasTrack)
            }
        }
    }
    
    private func createGridTile(x: Int, z: Int, hasTrack: Bool) {
        let boxSize = tileSize * 0.95
        let height = hasTrack ? tileHeight : tileHeight * 0.5
        
        let box = SCNBox(width: boxSize, height: height, length: boxSize, chamferRadius: 0.02)
        
        let material = SCNMaterial()
        if hasTrack {
            material.diffuse.contents = NSColor(red: 0.12, green: 0.15, blue: 0.2, alpha: 1.0)
        } else {
            material.diffuse.contents = NSColor(red: 0.06, green: 0.08, blue: 0.12, alpha: 1.0)
        }
        material.roughness.contents = 0.8
        material.lightingModel = .physicallyBased
        box.materials = [material]
        
        let node = SCNNode(geometry: box)
        node.position = SCNVector3(
            CGFloat(x) * tileSize,
            height / 2 - 0.1,
            CGFloat(z) * tileSize
        )
        node.castsShadow = true
        
        scene.rootNode.addChildNode(node)
    }
    
    // MARK: - Track Building
    
    private func buildTracks() {
        for track in allTracks {
            let node = createTrackNode(track)
            node.position = gridToWorld(track.pos)
            node.position.y = tileHeight + trackHeight / 2
            scene.rootNode.addChildNode(node)
            trackNodes[track.pos] = node
        }
    }
    
    private func createTrackNode(_ track: TrackCell) -> SCNNode {
        let container = SCNNode()
        
        switch track.type {
        case .horizontal:
            addRails(to: container, isHorizontal: true)
        case .vertical:
            addRails(to: container, isHorizontal: false)
        case .junction:
            addRails(to: container, isHorizontal: true)
            addRails(to: container, isHorizontal: false)
            addJunctionMarker(to: container, color: GameConstants.accentGreen)
        case .cross:
            addRails(to: container, isHorizontal: true)
            addRails(to: container, isHorizontal: false)
            addJunctionMarker(to: container, color: GameConstants.accentRed)
        case .curve:
            addCurveRails(to: container)
        case .downhill:
            addRails(to: container, isHorizontal: true)
            addDownhillMarker(to: container)
        }
        
        return container
    }
    
    private func addRails(to container: SCNNode, isHorizontal: Bool) {
        let railLength = tileSize * 0.9
        let railWidth: CGFloat = 0.03
        let railHeight = trackHeight
        let railSpacing: CGFloat = 0.12
        
        let railMaterial = SCNMaterial()
        railMaterial.diffuse.contents = NSColor(red: 0.4, green: 0.45, blue: 0.5, alpha: 1.0)
        railMaterial.metalness.contents = 0.7
        railMaterial.roughness.contents = 0.4
        
        for offset in [-railSpacing / 2, railSpacing / 2] {
            let w = isHorizontal ? railLength : railWidth
            let l = isHorizontal ? railWidth : railLength
            let railGeometry = SCNBox(width: w, height: railHeight, length: l, chamferRadius: 0.005)
            railGeometry.materials = [railMaterial]
            
            let railNode = SCNNode(geometry: railGeometry)
            if isHorizontal {
                railNode.position.z = offset
            } else {
                railNode.position.x = offset
            }
            container.addChildNode(railNode)
        }
        
        // Ties
        let tieCount = 5
        let tieMaterial = SCNMaterial()
        tieMaterial.diffuse.contents = NSColor(red: 0.25, green: 0.2, blue: 0.15, alpha: 1.0)
        tieMaterial.roughness.contents = 0.9
        
        for i in 0..<tieCount {
            let t = CGFloat(i) / CGFloat(tieCount - 1) - 0.5
            let tieW = isHorizontal ? 0.04 : 0.25
            let tieL = isHorizontal ? 0.25 : 0.04
            let tieGeometry = SCNBox(width: tieW, height: 0.02, length: tieL, chamferRadius: 0.002)
            tieGeometry.materials = [tieMaterial]
            
            let tieNode = SCNNode(geometry: tieGeometry)
            if isHorizontal {
                tieNode.position.x = t * tileSize * 0.8
            } else {
                tieNode.position.z = t * tileSize * 0.8
            }
            tieNode.position.y = -trackHeight / 2 + 0.01
            container.addChildNode(tieNode)
        }
    }
    
    private func addCurveRails(to container: SCNNode) {
        let railMaterial = SCNMaterial()
        railMaterial.diffuse.contents = NSColor(red: 0.4, green: 0.45, blue: 0.5, alpha: 1.0)
        railMaterial.metalness.contents = 0.7
        
        let curveRadius = tileSize * 0.4
        let segments = 8
        
        for railOffset: CGFloat in [-0.06, 0.06] {
            let radius = curveRadius + railOffset
            
            for i in 0..<segments {
                let angle1 = CGFloat(i) / CGFloat(segments) * CGFloat.pi / 2
                let angle2 = CGFloat(i + 1) / CGFloat(segments) * CGFloat.pi / 2
                
                let x1 = cos(angle1) * radius - tileSize / 2
                let z1 = sin(angle1) * radius - tileSize / 2
                let x2 = cos(angle2) * radius - tileSize / 2
                let z2 = sin(angle2) * radius - tileSize / 2
                
                let segLength = sqrt(pow(x2 - x1, 2) + pow(z2 - z1, 2))
                let segGeometry = SCNBox(width: segLength, height: trackHeight, length: 0.03, chamferRadius: 0)
                segGeometry.materials = [railMaterial]
                
                let segNode = SCNNode(geometry: segGeometry)
                segNode.position = SCNVector3((x1 + x2) / 2, 0, (z1 + z2) / 2)
                segNode.eulerAngles.y = atan2(z2 - z1, x2 - x1)
                container.addChildNode(segNode)
            }
        }
    }
    
    private func addJunctionMarker(to container: SCNNode, color: NSColor) {
        let markerGeometry = SCNCylinder(radius: 0.08, height: 0.02)
        let markerMaterial = SCNMaterial()
        markerMaterial.diffuse.contents = color.withAlphaComponent(0.8)
        markerMaterial.emission.contents = color.withAlphaComponent(0.4)
        markerGeometry.materials = [markerMaterial]
        
        let markerNode = SCNNode(geometry: markerGeometry)
        markerNode.position.y = trackHeight / 2 + 0.01
        container.addChildNode(markerNode)
    }
    
    private func addDownhillMarker(to container: SCNNode) {
        let arrowGeometry = SCNPyramid(width: 0.1, height: 0.05, length: 0.15)
        let arrowMaterial = SCNMaterial()
        arrowMaterial.diffuse.contents = GameConstants.accentOrange
        arrowMaterial.emission.contents = GameConstants.accentOrange.withAlphaComponent(0.3)
        arrowGeometry.materials = [arrowMaterial]
        
        let arrowNode = SCNNode(geometry: arrowGeometry)
        arrowNode.eulerAngles.x = CGFloat.pi / 2
        arrowNode.position.y = trackHeight + 0.03
        container.addChildNode(arrowNode)
    }
    
    // MARK: - Destinations
    
    private func buildDestinations() {
        for dest in allDestinations {
            let node = createDestinationNode(dest)
            node.position = gridToWorld(dest.pos)
            node.position.y = tileHeight
            scene.rootNode.addChildNode(node)
            destinationNodes[dest.pos] = node
        }
    }
    
    private func createDestinationNode(_ dest: Destination) -> SCNNode {
        let container = SCNNode()
        
        let platformGeometry = SCNBox(width: tileSize * 0.9, height: 0.05, length: tileSize * 0.9, chamferRadius: 0.03)
        let platformMaterial = SCNMaterial()
        platformMaterial.diffuse.contents = GameConstants.accentGreen.withAlphaComponent(0.3)
        platformMaterial.emission.contents = GameConstants.accentGreen.withAlphaComponent(0.2)
        platformGeometry.materials = [platformMaterial]
        
        let platformNode = SCNNode(geometry: platformGeometry)
        container.addChildNode(platformNode)
        
        let pillarGeometry = SCNCylinder(radius: 0.03, height: 0.4)
        let pillarMaterial = SCNMaterial()
        pillarMaterial.diffuse.contents = GameConstants.accentGreen
        pillarGeometry.materials = [pillarMaterial]
        
        let pillarNode = SCNNode(geometry: pillarGeometry)
        pillarNode.position = SCNVector3(0, 0.2, -0.3)
        container.addChildNode(pillarNode)
        
        let signGeometry = SCNBox(width: 0.3, height: 0.15, length: 0.02, chamferRadius: 0.01)
        let signMaterial = SCNMaterial()
        signMaterial.diffuse.contents = createLabelTexture(text: dest.label)
        signGeometry.materials = [signMaterial]
        
        let signNode = SCNNode(geometry: signGeometry)
        signNode.position = SCNVector3(0, 0.45, -0.3)
        container.addChildNode(signNode)
        
        let pulse = SCNAction.sequence([
            SCNAction.fadeOpacity(to: 0.6, duration: 1.0),
            SCNAction.fadeOpacity(to: 1.0, duration: 1.0)
        ])
        platformNode.runAction(SCNAction.repeatForever(pulse))
        
        return container
    }
    
    private func createLabelTexture(text: String) -> NSImage {
        let size = NSSize(width: 128, height: 64)
        let image = NSImage(size: size)
        
        image.lockFocus()
        
        GameConstants.accentGreen.setFill()
        NSBezierPath(rect: NSRect(origin: .zero, size: size)).fill()
        
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont(name: "Menlo-Bold", size: 24) ?? NSFont.systemFont(ofSize: 24),
            .foregroundColor: NSColor.black
        ]
        let string = NSAttributedString(string: text, attributes: attrs)
        let stringSize = string.size()
        let point = NSPoint(x: (size.width - stringSize.width) / 2, y: (size.height - stringSize.height) / 2)
        string.draw(at: point)
        
        image.unlockFocus()
        return image
    }
    
    // MARK: - Simulation
    
    func startSimulation() {
        guard case .idle = gameState else { return }
        
        gameState = .running
        simTick = 0
        trainsPassed = 0
        collisionCount = 0
        derailmentCount = 0
        
        trainNodes.forEach { $0.removeFromParentNode() }
        trainNodes.removeAll()
        
        // 웨이브 모드면 currentWaveDef 사용, 아니면 levelDef
        let spawns = currentWaveDef?.spawns ?? levelDef.spawns
        spawnQueue = spawns.map { (config: $0, spawned: false) }
        
        onStateChanged?(.running)
        startGameLoop()
    }
    
    func pauseSimulation() {
        guard case .running = gameState else { return }
        gameState = .paused
        onStateChanged?(.paused)
    }
    
    func resumeSimulation() {
        guard case .paused = gameState else { return }
        gameState = .running
        onStateChanged?(.running)
    }
    
    func setSimSpeed(_ speed: CGFloat) {
        simSpeed = speed
    }
    
    private var gameLoopTimer: Timer?
    
    private func startGameLoop() {
        gameLoopTimer?.invalidate()
        let interval = GameConstants.moveTickRate / TimeInterval(simSpeed)
        gameLoopTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.gameTick()
        }
    }
    
    private func gameTick() {
        guard case .running = gameState else {
            gameLoopTimer?.invalidate()
            return
        }
        
        simTick += 1
        
        processSpawns()
        processTrains()
        checkCollisions()
        checkDerailments()
        checkWinCondition()
        
        onTimerUpdated?(simTick)
    }
    
    private func processSpawns() {
        for i in spawnQueue.indices {
            guard !spawnQueue[i].spawned else { continue }
            guard simTick >= spawnQueue[i].config.delay else { continue }
            
            spawnQueue[i].spawned = true
            let config = spawnQueue[i].config
            
            let train = Train3DNode(config: config)
            train.position = gridToWorld(config.pos)
            train.position.y = tileHeight + 0.1
            scene.rootNode.addChildNode(train)
            trainNodes.append(train)
        }
    }
    
    private func processTrains() {
        for train in trainNodes {
            guard !train.isFinished && !train.isStopped else { continue }
            
            let nextPos = determineNextPosition(for: train)
            
            if let tool = toolNodes[nextPos], tool.toolType == .signal, !tool.isActive {
                train.isStopped = true
                continue
            }
            
            let duration = GameConstants.moveTickRate / TimeInterval(simSpeed)
            var targetPosition = gridToWorld(nextPos)
            targetPosition.y = tileHeight + 0.1
            
            train.moveTo(gridPos: nextPos, worldPosition: targetPosition, duration: duration * 0.8)
            
            if let dest = allDestinations.first(where: { $0.pos == nextPos }) {
                let correctDest = dest.label == train.destination || train.destination == nil || allDestinations.count == 1
                if correctDest {
                    train.animateArrival()
                    trainsPassed += 1
                    let required = currentWaveDef?.requiredPasses ?? levelDef.requiredPasses
                    onTrainsPassed?(trainsPassed, required)
                }
            }
            
            if train.gridX < -1 || train.gridX > GameConstants.gridCols + 1 ||
               train.gridY < -1 || train.gridY > GameConstants.gridRows + 1 {
                train.isFinished = true
                train.removeFromParentNode()
            }
        }
    }
    
    private func determineNextPosition(for train: Train3DNode) -> GridPos {
        let currentPos = GridPos(x: train.gridX, y: train.gridY)
        return defaultNextPos(from: currentPos, direction: train.direction)
    }
    
    private func defaultNextPos(from pos: GridPos, direction: TrainDirection) -> GridPos {
        let candidates = [
            GridPos(x: pos.x + 1, y: pos.y),
            GridPos(x: pos.x - 1, y: pos.y),
            GridPos(x: pos.x, y: pos.y + 1),
            GridPos(x: pos.x, y: pos.y - 1),
        ]
        
        let onTrack = candidates.filter { trackSet.contains($0) }
        
        let preferred: GridPos
        switch direction {
        case .right: preferred = GridPos(x: pos.x + 1, y: pos.y)
        case .left: preferred = GridPos(x: pos.x - 1, y: pos.y)
        case .up: preferred = GridPos(x: pos.x, y: pos.y + 1)
        case .down: preferred = GridPos(x: pos.x, y: pos.y - 1)
        }
        
        if onTrack.contains(preferred) { return preferred }
        
        let forward = onTrack.filter { neighbor in
            switch direction {
            case .right: return neighbor.x >= pos.x
            case .left: return neighbor.x <= pos.x
            case .up: return neighbor.y >= pos.y
            case .down: return neighbor.y <= pos.y
            }
        }
        
        return forward.first ?? onTrack.first ?? preferred
    }
    
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
                    gameLoopTimer?.invalidate()
                    onCollision?(collisionCount)
                    onStateChanged?(gameState)
                    return
                }
            }
        }
    }
    
    private func checkDerailments() {
        for train in trainNodes where !train.isFinished {
            let pos = GridPos(x: train.gridX, y: train.gridY)
            
            if train.isOverloaded && trackTypeMap[pos] == .curve {
                derailmentCount += 1
                train.animateDerail()
                let msg = "\(train.trainLabel)이(가) 커브에서 탈선했습니다! (과적)"
                gameState = .fail(msg)
                gameLoopTimer?.invalidate()
                onDerailment?(derailmentCount)
                onStateChanged?(gameState)
                return
            }
        }
    }
    
    private func checkWinCondition() {
        guard let waveDef = currentWaveDef else { return }
        
        if trainsPassed >= waveDef.requiredPasses {
            gameState = .success
            gameLoopTimer?.invalidate()
            totalTrainsPassed += trainsPassed
            onWaveComplete?(currentWave)
            onStateChanged?(.success)
            
            // 3초 후 자동으로 다음 웨이브 시작
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.nextWave()
            }
        }
    }
    
    // MARK: - Tool Placement
    
    func placeTool(_ type: ToolType, at gridPos: GridPos) {
        guard trackSet.contains(gridPos) else { return }
        guard toolNodes[gridPos] == nil else { return }
        
        let node = Tool3DNode(gridPos: gridPos, toolType: type)
        node.position = gridToWorld(gridPos)
        node.position.y = tileHeight + 0.1
        scene.rootNode.addChildNode(node)
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
    
    func toggleToolAt(gridPos: GridPos) {
        if let tool = toolNodes[gridPos], tool.toolType == .signal {
            tool.toggle()
        }
    }
    
    // MARK: - Helpers
    
    private func gridToWorld(_ pos: GridPos) -> SCNVector3 {
        SCNVector3(CGFloat(pos.x) * tileSize, 0, CGFloat(pos.y) * tileSize)
    }
    
    func worldToGrid(_ point: SCNVector3) -> GridPos {
        GridPos(x: Int(round(Double(point.x) / Double(tileSize))), y: Int(round(Double(point.z) / Double(tileSize))))
    }
    
    // MARK: - Camera Control
    
    func rotateCamera(by angle: CGFloat) {
        let action = SCNAction.rotateBy(x: 0, y: angle, z: 0, duration: 0.3)
        action.timingMode = .easeOut
        cameraOrbitNode.runAction(action)
    }
    
    func zoomCamera(by delta: CGFloat) {
        let currentZ = cameraNode.position.z
        let newZ = max(5, min(25, currentZ + delta))
        let currentY = cameraNode.position.y
        let newY = max(3, min(20, currentY + delta * 0.8))
        
        let action = SCNAction.move(to: SCNVector3(0, newY, newZ), duration: 0.2)
        action.timingMode = .easeOut
        cameraNode.runAction(action)
    }
}

// MARK: - Train 3D Node
class Train3DNode: SCNNode {
    let trainID = UUID()
    var gridX: Int
    var gridY: Int
    var trainSpeed: CGFloat
    var direction: TrainDirection
    var trainLabel: String
    var destination: String?
    var isOverloaded: Bool
    var isStopped: Bool = false
    var isFinished: Bool = false
    
    let trainColor: NSColor
    
    init(config: SpawnConfig) {
        self.gridX = config.pos.x
        self.gridY = config.pos.y
        self.trainSpeed = config.speed
        self.direction = config.direction
        self.trainLabel = config.label
        self.destination = config.destination
        self.isOverloaded = config.isOverloaded
        self.trainColor = NSColor(hex: config.colorHex)
        
        super.init()
        
        buildTrain()
        updateRotation()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func buildTrain() {
        // 기차 크기 2배 확대
        let bodyGeometry = SCNBox(width: 0.7, height: 0.35, length: 0.4, chamferRadius: 0.05)
        let bodyMaterial = SCNMaterial()
        bodyMaterial.diffuse.contents = trainColor
        bodyMaterial.metalness.contents = 0.3
        bodyMaterial.roughness.contents = 0.5
        bodyGeometry.materials = [bodyMaterial]
        
        let bodyNode = SCNNode(geometry: bodyGeometry)
        bodyNode.position.y = 0.2
        bodyNode.castsShadow = true
        addChildNode(bodyNode)
        
        // 캐빈 (운전실)
        let cabinGeometry = SCNBox(width: 0.32, height: 0.28, length: 0.36, chamferRadius: 0.04)
        let cabinMaterial = SCNMaterial()
        cabinMaterial.diffuse.contents = trainColor.blended(withFraction: 0.2, of: .white) ?? trainColor
        cabinMaterial.metalness.contents = 0.2
        cabinGeometry.materials = [cabinMaterial]
        
        let cabinNode = SCNNode(geometry: cabinGeometry)
        cabinNode.position = SCNVector3(-0.22, 0.32, 0)
        cabinNode.castsShadow = true
        addChildNode(cabinNode)
        
        // 창문
        let windowGeometry = SCNBox(width: 0.02, height: 0.12, length: 0.2, chamferRadius: 0.01)
        let windowMaterial = SCNMaterial()
        windowMaterial.diffuse.contents = NSColor(red: 0.6, green: 0.8, blue: 1.0, alpha: 0.8)
        windowMaterial.emission.contents = NSColor(red: 0.3, green: 0.5, blue: 0.7, alpha: 0.3)
        windowGeometry.materials = [windowMaterial]
        
        let windowNode = SCNNode(geometry: windowGeometry)
        windowNode.position = SCNVector3(-0.06, 0.38, 0)
        addChildNode(windowNode)
        
        // 굴뚝
        let stackGeometry = SCNCylinder(radius: 0.06, height: 0.18)
        let stackMaterial = SCNMaterial()
        stackMaterial.diffuse.contents = NSColor(red: 0.25, green: 0.25, blue: 0.28, alpha: 1)
        stackGeometry.materials = [stackMaterial]
        
        let stackNode = SCNNode(geometry: stackGeometry)
        stackNode.position = SCNVector3(0.2, 0.48, 0)
        addChildNode(stackNode)
        
        // 굴뚝 상단 링
        let stackTopGeometry = SCNCylinder(radius: 0.08, height: 0.04)
        stackTopGeometry.materials = [stackMaterial]
        let stackTopNode = SCNNode(geometry: stackTopGeometry)
        stackTopNode.position = SCNVector3(0.2, 0.58, 0)
        addChildNode(stackTopNode)
        
        // 바퀴 (크게)
        let wheelGeometry = SCNCylinder(radius: 0.08, height: 0.04)
        let wheelMaterial = SCNMaterial()
        wheelMaterial.diffuse.contents = NSColor(red: 0.15, green: 0.15, blue: 0.18, alpha: 1)
        wheelMaterial.metalness.contents = 0.6
        wheelGeometry.materials = [wheelMaterial]
        
        for x: CGFloat in [-0.25, 0.0, 0.25] {
            for z: CGFloat in [-0.18, 0.18] {
                let wheelNode = SCNNode(geometry: wheelGeometry)
                wheelNode.position = SCNVector3(x, 0.08, z)
                wheelNode.eulerAngles.x = CGFloat.pi / 2
                addChildNode(wheelNode)
            }
        }
        
        // 전조등
        let headlightGeometry = SCNCylinder(radius: 0.04, height: 0.02)
        let headlightMaterial = SCNMaterial()
        headlightMaterial.diffuse.contents = NSColor.yellow
        headlightMaterial.emission.contents = NSColor.yellow.withAlphaComponent(0.8)
        headlightGeometry.materials = [headlightMaterial]
        
        let headlightNode = SCNNode(geometry: headlightGeometry)
        headlightNode.position = SCNVector3(0.36, 0.25, 0)
        headlightNode.eulerAngles.z = CGFloat.pi / 2
        addChildNode(headlightNode)
        
        // 전조등 빛
        let spotLight = SCNLight()
        spotLight.type = .spot
        spotLight.color = NSColor.yellow
        spotLight.intensity = 200
        spotLight.spotInnerAngle = 20
        spotLight.spotOuterAngle = 45
        headlightNode.light = spotLight
        
        // 과적 경고 표시
        if isOverloaded {
            let warningGeometry = SCNSphere(radius: 0.1)
            let warningMaterial = SCNMaterial()
            warningMaterial.diffuse.contents = GameConstants.accentOrange
            warningMaterial.emission.contents = GameConstants.accentOrange.withAlphaComponent(0.5)
            warningGeometry.materials = [warningMaterial]
            
            let warningNode = SCNNode(geometry: warningGeometry)
            warningNode.position = SCNVector3(0, 0.6, 0)
            addChildNode(warningNode)
            
            let pulse = SCNAction.sequence([
                SCNAction.scale(to: 1.3, duration: 0.5),
                SCNAction.scale(to: 1.0, duration: 0.5)
            ])
            warningNode.runAction(SCNAction.repeatForever(pulse))
        }
        
        // 라벨
        let textGeometry = SCNText(string: trainLabel, extrusionDepth: 0.02)
        textGeometry.font = NSFont(name: "Menlo-Bold", size: 0.12)
        textGeometry.flatness = 0.1
        let textMaterial = SCNMaterial()
        textMaterial.diffuse.contents = NSColor.white
        textMaterial.emission.contents = NSColor.white.withAlphaComponent(0.3)
        textGeometry.materials = [textMaterial]
        
        let textNode = SCNNode(geometry: textGeometry)
        let (min, max) = textNode.boundingBox
        let textWidth = max.x - min.x
        textNode.position = SCNVector3(-CGFloat(textWidth) / 2, 0.55, 0.22)
        addChildNode(textNode)
    }
    
    private func updateRotation() {
        switch direction {
        case .right: eulerAngles.y = 0
        case .left: eulerAngles.y = CGFloat.pi
        case .up: eulerAngles.y = CGFloat.pi / 2
        case .down: eulerAngles.y = -CGFloat.pi / 2
        }
    }
    
    func moveTo(gridPos: GridPos, worldPosition: SCNVector3, duration: TimeInterval) {
        if gridPos.x > gridX { direction = .right }
        else if gridPos.x < gridX { direction = .left }
        else if gridPos.y > gridY { direction = .up }
        else if gridPos.y < gridY { direction = .down }
        
        gridX = gridPos.x
        gridY = gridPos.y
        
        updateRotation()
        
        let moveAction = SCNAction.move(to: worldPosition, duration: duration)
        moveAction.timingMode = .easeInEaseOut
        runAction(moveAction)
    }
    
    func animateArrival() {
        isFinished = true
        let fadeOut = SCNAction.fadeOut(duration: 0.3)
        let scaleDown = SCNAction.scale(to: 0.5, duration: 0.3)
        let group = SCNAction.group([fadeOut, scaleDown])
        runAction(group) { [weak self] in
            self?.removeFromParentNode()
        }
    }
    
    func animateCrash() {
        isFinished = true
        
        enumerateChildNodes { node, _ in
            if let geometry = node.geometry {
                geometry.firstMaterial?.emission.contents = GameConstants.accentRed
            }
        }
        
        let explosionGeometry = SCNSphere(radius: 0.3)
        let explosionMaterial = SCNMaterial()
        explosionMaterial.diffuse.contents = GameConstants.accentRed.withAlphaComponent(0.8)
        explosionMaterial.emission.contents = GameConstants.accentRed
        explosionGeometry.materials = [explosionMaterial]
        
        let explosionNode = SCNNode(geometry: explosionGeometry)
        explosionNode.position.y = 0.1
        addChildNode(explosionNode)
        
        let expand = SCNAction.scale(to: 2, duration: 0.3)
        let fade = SCNAction.fadeOut(duration: 0.3)
        explosionNode.runAction(SCNAction.group([expand, fade]))
    }
    
    func animateDerail() {
        isFinished = true
        
        let rotate = SCNAction.rotateBy(x: 0, y: 0, z: CGFloat.pi / 2, duration: 0.4)
        let fall = SCNAction.moveBy(x: 0.3, y: -0.2, z: 0, duration: 0.4)
        runAction(SCNAction.group([rotate, fall]))
    }
}

// MARK: - Tool 3D Node
class Tool3DNode: SCNNode {
    let gridPos: GridPos
    let toolType: ToolType
    var isActive: Bool = true
    
    init(gridPos: GridPos, toolType: ToolType) {
        self.gridPos = gridPos
        self.toolType = toolType
        
        super.init()
        
        buildTool()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func buildTool() {
        switch toolType {
        case .signal:
            buildSignal()
        case .brake:
            buildBrake()
        default:
            buildGeneric()
        }
    }
    
    private func buildSignal() {
        let poleGeometry = SCNCylinder(radius: 0.02, height: 0.4)
        let poleMaterial = SCNMaterial()
        poleMaterial.diffuse.contents = NSColor.darkGray
        poleGeometry.materials = [poleMaterial]
        
        let poleNode = SCNNode(geometry: poleGeometry)
        poleNode.position.y = 0.2
        addChildNode(poleNode)
        
        let lightGeometry = SCNSphere(radius: 0.06)
        let lightMaterial = SCNMaterial()
        lightMaterial.diffuse.contents = isActive ? GameConstants.accentGreen : GameConstants.accentRed
        lightMaterial.emission.contents = (isActive ? GameConstants.accentGreen : GameConstants.accentRed).withAlphaComponent(0.5)
        lightGeometry.materials = [lightMaterial]
        
        let lightNode = SCNNode(geometry: lightGeometry)
        lightNode.name = "signalLight"
        lightNode.position.y = 0.45
        addChildNode(lightNode)
        
        let pointLight = SCNLight()
        pointLight.type = .omni
        pointLight.color = isActive ? GameConstants.accentGreen : GameConstants.accentRed
        pointLight.intensity = 100
        pointLight.attenuationEndDistance = 1
        lightNode.light = pointLight
    }
    
    private func buildBrake() {
        let geometry = SCNBox(width: 0.3, height: 0.05, length: 0.3, chamferRadius: 0.01)
        let material = SCNMaterial()
        material.diffuse.contents = GameConstants.accentRed.withAlphaComponent(0.5)
        material.emission.contents = GameConstants.accentRed.withAlphaComponent(0.2)
        geometry.materials = [material]
        
        let node = SCNNode(geometry: geometry)
        addChildNode(node)
    }
    
    private func buildGeneric() {
        let geometry = SCNBox(width: 0.15, height: 0.25, length: 0.15, chamferRadius: 0.02)
        let material = SCNMaterial()
        material.diffuse.contents = GameConstants.accentBlue
        material.metalness.contents = 0.5
        geometry.materials = [material]
        
        let node = SCNNode(geometry: geometry)
        node.position.y = 0.125
        addChildNode(node)
    }
    
    func toggle() {
        isActive.toggle()
        
        if let lightNode = childNode(withName: "signalLight", recursively: true) {
            let color = isActive ? GameConstants.accentGreen : GameConstants.accentRed
            lightNode.geometry?.firstMaterial?.diffuse.contents = color
            lightNode.geometry?.firstMaterial?.emission.contents = color.withAlphaComponent(0.5)
            lightNode.light?.color = color
        }
    }
    
    func animateRemove(completion: @escaping () -> Void) {
        let scaleDown = SCNAction.scale(to: 0, duration: 0.2)
        runAction(scaleDown) { [weak self] in
            self?.removeFromParentNode()
            completion()
        }
    }
}
