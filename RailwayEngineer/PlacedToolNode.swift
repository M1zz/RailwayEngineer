import SpriteKit

// MARK: - Placed Tool Node
class PlacedToolNode: SKNode {

    let toolID = UUID()
    let gridPos: GridPos
    let toolType: ToolType
    var isActive: Bool {
        didSet { updateVisuals() }
    }

    private let bgNode: SKShapeNode
    private let borderNode: SKShapeNode
    private let iconNode: SKLabelNode
    private let stateIndicator: SKShapeNode

    /// Create a diamond CGPath sized slightly smaller than the tile
    private static func diamondPath() -> CGPath {
        let tw = GameConstants.isoTileWidth - 6
        let th = GameConstants.isoTileHeight - 3
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: th / 2))       // top
        path.addLine(to: CGPoint(x: tw / 2, y: 0))     // right
        path.addLine(to: CGPoint(x: 0, y: -th / 2))    // bottom
        path.addLine(to: CGPoint(x: -tw / 2, y: 0))    // left
        path.closeSubpath()
        return path
    }

    init(gridPos: GridPos, toolType: ToolType) {
        self.gridPos = gridPos
        self.toolType = toolType
        // Signals start RED (inactive), others start active
        self.isActive = toolType != .signal

        let diamond = PlacedToolNode.diamondPath()

        bgNode = SKShapeNode(path: diamond)
        bgNode.strokeColor = .clear
        bgNode.lineWidth = 0

        borderNode = SKShapeNode(path: diamond)
        borderNode.fillColor = .clear
        borderNode.lineWidth = 2

        iconNode = SKLabelNode(text: toolType.icon)
        iconNode.fontSize = 18
        iconNode.verticalAlignmentMode = .center
        iconNode.horizontalAlignmentMode = .center

        stateIndicator = SKShapeNode(circleOfRadius: 3)
        // Position near top vertex of diamond
        let th = GameConstants.isoTileHeight - 3
        stateIndicator.position = CGPoint(x: 0, y: th / 2 - 2)

        super.init()

        self.position = gridPos.scenePosition()
        self.zPosition = GameConstants.isoZPosition(layer: GameConstants.zTool, gridX: gridPos.x, gridY: gridPos.y)

        addChild(bgNode)
        addChild(borderNode)
        addChild(iconNode)

        if toolType == .signal {
            addChild(stateIndicator)
        }

        updateVisuals()
        animatePlace()
    }

    required init?(coder: NSCoder) { fatalError() }

    func updateVisuals() {
        if toolType == .signal {
            if isActive {
                bgNode.fillColor = NSColor(red: 0, green: 0.9, blue: 0.46, alpha: 0.12)
                borderNode.strokeColor = GameConstants.accentGreen
                stateIndicator.fillColor = GameConstants.accentGreen
            } else {
                bgNode.fillColor = NSColor(red: 1, green: 0.24, blue: 0.24, alpha: 0.08)
                borderNode.strokeColor = GameConstants.accentRed
                stateIndicator.fillColor = GameConstants.accentRed
            }

            // Pulse animation on state indicator
            stateIndicator.removeAllActions()
            let fadeOut = SKAction.fadeAlpha(to: 0.3, duration: 0.6)
            let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.6)
            stateIndicator.run(SKAction.repeatForever(SKAction.sequence([fadeOut, fadeIn])))
        } else {
            bgNode.fillColor = NSColor(red: 0, green: 0.9, blue: 0.46, alpha: 0.08)
            borderNode.strokeColor = GameConstants.accentGreen.withAlphaComponent(0.6)
        }
    }

    func toggle() {
        guard toolType == .signal else { return }
        isActive.toggle()
    }

    private func animatePlace() {
        self.setScale(0)
        self.alpha = 0
        let scaleUp = SKAction.scale(to: 1.1, duration: 0.15)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
        let fadeIn = SKAction.fadeIn(withDuration: 0.15)
        let group = SKAction.group([SKAction.sequence([scaleUp, scaleDown]), fadeIn])
        run(group)
    }

    func animateRemove(completion: @escaping () -> Void) {
        let scaleDown = SKAction.scale(to: 0, duration: 0.15)
        let fadeOut = SKAction.fadeOut(withDuration: 0.15)
        run(SKAction.group([scaleDown, fadeOut])) { [weak self] in
            self?.removeFromParent()
            completion()
        }
    }
}
