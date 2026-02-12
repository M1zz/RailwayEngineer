import SpriteKit

// MARK: - Train Node
class TrainNode: SKNode {

    let trainID = UUID()
    var gridX: Int
    var gridY: Int
    var trainSpeed: CGFloat
    let baseSpeed: CGFloat
    var direction: TrainDirection {
        didSet {
            if direction != oldValue {
                rebuildLocomotive()
            }
        }
    }
    var trainLabel: String
    var destination: String?
    var isOverloaded: Bool
    var cargo: CargoType?
    var trainLength: Int
    var isStopped: Bool = false
    var isFinished: Bool = false
    var moveAccumulator: CGFloat = 0

    private var locomotiveNode: SKNode
    private let labelNode: SKLabelNode
    private let warningNode: SKLabelNode
    private let speedIndicator: SKLabelNode
    private let stopIndicator: SKLabelNode

    let trainColor: NSColor

    init(config: SpawnConfig) {
        self.gridX = config.pos.x
        self.gridY = config.pos.y
        self.trainSpeed = config.speed
        self.baseSpeed = config.speed
        self.direction = config.direction
        self.trainLabel = config.label
        self.destination = config.destination
        self.isOverloaded = config.isOverloaded
        self.cargo = config.cargo
        self.trainLength = config.trainLength
        self.trainColor = NSColor(hex: config.colorHex)

        locomotiveNode = SKNode()

        // Label
        labelNode = SKLabelNode(text: config.label)
        labelNode.fontName = "Menlo-Bold"
        labelNode.fontSize = 8
        labelNode.fontColor = .white
        labelNode.verticalAlignmentMode = .center
        labelNode.horizontalAlignmentMode = .center

        // Warning (overloaded)
        warningNode = SKLabelNode(text: "⚠")
        warningNode.fontSize = 10
        warningNode.verticalAlignmentMode = .center
        warningNode.isHidden = !config.isOverloaded

        // Speed indicator
        speedIndicator = SKLabelNode(text: "")
        speedIndicator.fontName = "Menlo"
        speedIndicator.fontSize = 7
        speedIndicator.fontColor = GameConstants.accentYellow
        speedIndicator.verticalAlignmentMode = .center
        speedIndicator.horizontalAlignmentMode = .center

        // Stop indicator
        stopIndicator = SKLabelNode(text: "⛔")
        stopIndicator.fontSize = 11
        stopIndicator.verticalAlignmentMode = .center
        stopIndicator.isHidden = true

        super.init()

        self.position = config.pos.scenePosition()
        self.zPosition = GameConstants.isoZPosition(layer: GameConstants.zTrain, gridX: gridX, gridY: gridY)

        addChild(locomotiveNode)
        addChild(labelNode)
        addChild(warningNode)
        addChild(speedIndicator)
        addChild(stopIndicator)

        rebuildLocomotive()
        updateSpeedIndicator()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Direction Vectors

    /// Returns (forward, perpendicular) vectors for isometric rendering based on train direction
    private func isoDirectionVectors() -> (forward: CGPoint, perp: CGPoint) {
        let tw = GameConstants.isoTileWidth
        let th = GameConstants.isoTileHeight
        switch direction {
        case .right:
            // Grid +X → iso goes right-down: (tw/2, -th/2)
            let fwd = CGPoint(x: tw / 2, y: -th / 2).normalized
            let perp = CGPoint(x: th / 2, y: tw / 2).normalized
            return (fwd, perp)
        case .left:
            let fwd = CGPoint(x: -tw / 2, y: th / 2).normalized
            let perp = CGPoint(x: -th / 2, y: -tw / 2).normalized
            return (fwd, perp)
        case .down:
            // Grid -Y → iso goes left-down: (-tw/2, -th/2)
            let fwd = CGPoint(x: -tw / 2, y: -th / 2).normalized
            let perp = CGPoint(x: -th / 2, y: tw / 2).normalized
            return (fwd, perp)
        case .up:
            let fwd = CGPoint(x: tw / 2, y: th / 2).normalized
            let perp = CGPoint(x: th / 2, y: -tw / 2).normalized
            return (fwd, perp)
        }
    }

    // MARK: - Locomotive Builder

    private func rebuildLocomotive() {
        locomotiveNode.removeAllChildren()

        let (fwd, perp) = isoDirectionVectors()
        let bodyLen: CGFloat = 22
        let bodyHalf: CGFloat = 7
        let cabinLen: CGFloat = 7

        // Positions along the locomotive axis
        let front = fwd * bodyLen
        let back = fwd * (-bodyLen * 0.4)
        let cabinBack = fwd * (-bodyLen * 0.8)

        // MARK: Body (parallelogram)
        let bodyPath = CGMutablePath()
        bodyPath.move(to: front + perp * bodyHalf)
        bodyPath.addLine(to: front - perp * bodyHalf)
        bodyPath.addLine(to: back - perp * bodyHalf)
        bodyPath.addLine(to: back + perp * bodyHalf)
        bodyPath.closeSubpath()

        let body = SKShapeNode(path: bodyPath)
        body.fillColor = trainColor
        body.strokeColor = trainColor.withAlphaComponent(0.6)
        body.lineWidth = 1
        body.glowWidth = 3
        locomotiveNode.addChild(body)

        // MARK: Cabin (slightly brighter, taller area at back)
        let cabinColor = trainColor.blended(withFraction: 0.3, of: .white) ?? trainColor
        let cabinPath = CGMutablePath()
        let cabinTop = perp * (bodyHalf + 2)
        cabinPath.move(to: back + cabinTop)
        cabinPath.addLine(to: back - cabinTop)
        cabinPath.addLine(to: cabinBack - cabinTop)
        cabinPath.addLine(to: cabinBack + cabinTop)
        cabinPath.closeSubpath()

        let cabin = SKShapeNode(path: cabinPath)
        cabin.fillColor = cabinColor
        cabin.strokeColor = cabinColor.withAlphaComponent(0.4)
        cabin.lineWidth = 1
        locomotiveNode.addChild(cabin)

        // MARK: Cabin "roof" (height illusion - small offset shape)
        let roofOffset = CGPoint(x: 0, y: 4) // lift up for 2.5D depth
        let roofPath = CGMutablePath()
        roofPath.move(to: back + cabinTop + roofOffset)
        roofPath.addLine(to: back - cabinTop + roofOffset)
        roofPath.addLine(to: cabinBack - cabinTop + roofOffset)
        roofPath.addLine(to: cabinBack + cabinTop + roofOffset)
        roofPath.closeSubpath()

        let roof = SKShapeNode(path: roofPath)
        let roofColor = cabinColor.blended(withFraction: 0.2, of: .white) ?? cabinColor
        roof.fillColor = roofColor
        roof.strokeColor = roofColor.withAlphaComponent(0.3)
        roof.lineWidth = 0.5
        locomotiveNode.addChild(roof)

        // Side walls connecting cabin to roof
        let sideWallPath = CGMutablePath()
        sideWallPath.move(to: back + cabinTop)
        sideWallPath.addLine(to: back + cabinTop + roofOffset)
        sideWallPath.addLine(to: cabinBack + cabinTop + roofOffset)
        sideWallPath.addLine(to: cabinBack + cabinTop)
        sideWallPath.closeSubpath()
        let sideWall = SKShapeNode(path: sideWallPath)
        sideWall.fillColor = cabinColor.withAlphaComponent(0.7)
        sideWall.strokeColor = .clear
        locomotiveNode.addChild(sideWall)

        // MARK: Smokestack (small rectangle at front)
        let stackCenter = fwd * (bodyLen * 0.6)
        let stackW: CGFloat = 3
        let stackH: CGFloat = 6
        let stackPath = CGMutablePath()
        stackPath.addRect(CGRect(x: stackCenter.x - stackW / 2, y: stackCenter.y, width: stackW, height: stackH))
        let stack = SKShapeNode(path: stackPath)
        stack.fillColor = NSColor(white: 0.25, alpha: 1)
        stack.strokeColor = NSColor(white: 0.15, alpha: 1)
        stack.lineWidth = 0.5
        locomotiveNode.addChild(stack)

        // MARK: Wheels (3 small circles below body)
        let wheelColor = NSColor(white: 0.2, alpha: 1)
        let wheelY = perp * (-bodyHalf - 2)
        for i in 0..<3 {
            let t = CGFloat(i) / 2.0
            let pos = front * (1 - t * 1.2) + back * (t * 0.5)
            let wheelPos = pos + wheelY
            let wheel = SKShapeNode(circleOfRadius: 2.5)
            wheel.position = wheelPos
            wheel.fillColor = wheelColor
            wheel.strokeColor = NSColor(white: 0.1, alpha: 1)
            wheel.lineWidth = 0.5
            locomotiveNode.addChild(wheel)
        }

        // MARK: Window (bright rectangle on cabin)
        let windowCenter = (back + cabinBack) * 0.5 + roofOffset * 0.5
        let windowSize: CGFloat = 4
        let window = SKShapeNode(rect: CGRect(
            x: windowCenter.x - windowSize / 2,
            y: windowCenter.y - windowSize / 2,
            width: windowSize,
            height: windowSize
        ))
        window.fillColor = NSColor(red: 0.6, green: 0.85, blue: 1, alpha: 0.8)
        window.strokeColor = NSColor(white: 0.8, alpha: 0.5)
        window.lineWidth = 0.5
        locomotiveNode.addChild(window)

        // Update accessory positions based on direction
        let labelOffset = CGPoint(x: 0, y: 14)
        labelNode.position = labelOffset
        warningNode.position = front + perp * (bodyHalf + 6)
        speedIndicator.position = CGPoint(x: 0, y: 20)
        stopIndicator.position = CGPoint(x: 0, y: 22)
    }

    func updateSpeedIndicator() {
        if trainSpeed > 1.2 {
            speedIndicator.text = "FAST"
            speedIndicator.fontColor = GameConstants.accentYellow
            speedIndicator.isHidden = false
        } else if trainSpeed < 0.7 {
            speedIndicator.text = "SLOW"
            speedIndicator.fontColor = GameConstants.accentOrange
            speedIndicator.isHidden = false
        } else {
            speedIndicator.isHidden = true
        }
    }

    func updateStopState() {
        stopIndicator.isHidden = !isStopped
        if isStopped {
            locomotiveNode.alpha = 0.7
        } else {
            locomotiveNode.alpha = 1.0
        }
    }

    func moveTo(gridPos: GridPos, duration: TimeInterval) {
        gridX = gridPos.x
        gridY = gridPos.y
        let targetPos = gridPos.scenePosition()
        let moveAction = SKAction.move(to: targetPos, duration: duration)
        moveAction.timingMode = .easeInEaseOut
        run(moveAction)

        // Update z-position for depth sorting
        self.zPosition = GameConstants.isoZPosition(layer: GameConstants.zTrain, gridX: gridX, gridY: gridY)
    }

    func animateArrival() {
        isFinished = true
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let scaleDown = SKAction.scale(to: 0.5, duration: 0.3)
        let group = SKAction.group([fadeOut, scaleDown])
        run(group) { [weak self] in
            self?.removeFromParent()
        }
    }

    func animateCrash() {
        isFinished = true
        let shake1 = SKAction.moveBy(x: 5, y: 0, duration: 0.05)
        let shake2 = SKAction.moveBy(x: -10, y: 0, duration: 0.05)
        let shake3 = SKAction.moveBy(x: 5, y: 0, duration: 0.05)
        let shakeSeq = SKAction.sequence([shake1, shake2, shake3])
        let repeatShake = SKAction.repeat(shakeSeq, count: 4)

        // Turn body red
        if let body = locomotiveNode.children.first as? SKShapeNode {
            body.fillColor = GameConstants.accentRed
        }

        // Explosion particles
        let explosion = SKLabelNode(text: "💥")
        explosion.fontSize = 32
        explosion.position = .zero
        explosion.zPosition = 5
        addChild(explosion)

        let scale = SKAction.scale(to: 2, duration: 0.3)
        let fade = SKAction.fadeOut(withDuration: 0.3)
        explosion.run(SKAction.group([scale, fade]))

        run(repeatShake)
    }

    func animateDerail() {
        isFinished = true
        if let body = locomotiveNode.children.first as? SKShapeNode {
            body.fillColor = GameConstants.accentOrange
        }

        let rotate = SKAction.rotate(byAngle: .pi * 0.5, duration: 0.4)
        let moveOff = SKAction.moveBy(x: 0, y: -30, duration: 0.4)
        let group = SKAction.group([rotate, moveOff])
        run(group)

        let derailLabel = SKLabelNode(text: "DERAIL")
        derailLabel.fontName = "Menlo-Bold"
        derailLabel.fontSize = 10
        derailLabel.fontColor = GameConstants.accentRed
        derailLabel.position = CGPoint(x: 0, y: 28)
        addChild(derailLabel)
    }
}
