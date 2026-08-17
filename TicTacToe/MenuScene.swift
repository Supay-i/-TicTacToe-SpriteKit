import SpriteKit

/// Стартовое меню: выбор размера поля, режима игры и (для игры с ИИ) сложности.
final class MenuScene: SKScene {

    private var selectedSize: BoardSize = .small
    private var selectedMode: GameMode = .playerVsAI
    private var selectedDifficulty: Difficulty = .medium

    private var sizeButtons: [BoardSize: SKLabelNode] = [:]
    private var modeButtons: [String: SKLabelNode] = [:]
    private var difficultyButtons: [Difficulty: SKLabelNode] = [:]
    private var difficultyContainer = SKNode()

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.08, green: 0.09, blue: 0.14, alpha: 1.0)
        buildUI()
    }

    private func buildUI() {
        let title = SKLabelNode(text: "Крестики-нолики")
        title.fontName = "AvenirNext-Bold"
        title.fontSize = 34
        title.fontColor = .white
        title.position = CGPoint(x: frame.midX, y: frame.maxY - 120)
        addChild(title)

        // --- Выбор размера поля ---
        addSectionLabel("Размер поля", y: frame.maxY - 200)
        let sizeY = frame.maxY - 250
        for (index, size) in BoardSize.allCases.enumerated() {
            let label = makeButton(text: size.title, name: "size_\(size.rawValue)")
            label.position = CGPoint(x: frame.midX + CGFloat(index * 2 - 1) * 100, y: sizeY)
            addChild(label)
            sizeButtons[size] = label
        }

        // --- Выбор режима ---
        addSectionLabel("Режим игры", y: frame.maxY - 330)
        let modeY = frame.maxY - 380
        let pvpLabel = makeButton(text: "Игрок vs Игрок", name: "mode_pvp")
        pvpLabel.position = CGPoint(x: frame.midX - 130, y: modeY)
        addChild(pvpLabel)
        modeButtons["pvp"] = pvpLabel

        let pvaiLabel = makeButton(text: "Игрок vs Компьютер", name: "mode_pvai")
        pvaiLabel.position = CGPoint(x: frame.midX + 130, y: modeY)
        addChild(pvaiLabel)
        modeButtons["pvai"] = pvaiLabel

        // --- Выбор сложности (видим только для PvAI) ---
        difficultyContainer.position = .zero
        addChild(difficultyContainer)
        let diffTitle = SKLabelNode(text: "Сложность ИИ")
        diffTitle.fontName = "AvenirNext-Medium"
        diffTitle.fontSize = 20
        diffTitle.fontColor = .lightGray
        diffTitle.position = CGPoint(x: frame.midX, y: frame.maxY - 450)
        difficultyContainer.addChild(diffTitle)

        let diffY = frame.maxY - 500
        for (index, diff) in [Difficulty.easy, .medium, .hard].enumerated() {
            let label = makeButton(text: diff.title, name: "diff_\(diff)")
            label.position = CGPoint(x: frame.midX + CGFloat(index - 1) * 130, y: diffY)
            difficultyContainer.addChild(label)
            difficultyButtons[diff] = label
        }

        // --- Кнопка старта ---
        let startButton = makeButton(text: "▶ Начать игру", name: "start")
        startButton.fontSize = 26
        startButton.fontColor = .systemGreen
        startButton.position = CGPoint(x: frame.midX, y: frame.minY + 120)
        addChild(startButton)

        refreshHighlights()
    }

    private func addSectionLabel(_ text: String, y: CGFloat) {
        let label = SKLabelNode(text: text)
        label.fontName = "AvenirNext-Medium"
        label.fontSize = 20
        label.fontColor = .lightGray
        label.position = CGPoint(x: frame.midX, y: y)
        addChild(label)
    }

    private func makeButton(text: String, name: String) -> SKLabelNode {
        let label = SKLabelNode(text: text)
        label.fontName = "AvenirNext-DemiBold"
        label.fontSize = 22
        label.fontColor = .white
        label.name = name
        return label
    }

    private func refreshHighlights() {
        for (size, label) in sizeButtons {
            label.fontColor = (size == selectedSize) ? .systemYellow : .white
        }
        modeButtons["pvp"]?.fontColor = (selectedMode == .playerVsPlayer) ? .systemYellow : .white
        modeButtons["pvai"]?.fontColor = (selectedMode == .playerVsAI) ? .systemYellow : .white

        difficultyContainer.isHidden = (selectedMode != .playerVsAI)
        for (diff, label) in difficultyButtons {
            label.fontColor = (diff == selectedDifficulty) ? .systemYellow : .white
        }
    }

    // MARK: - Обработка нажатий

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let node = atPoint(location)
        guard let name = node.name else { return }

        if name.hasPrefix("size_"), let raw = Int(name.replacingOccurrences(of: "size_", with: "")),
           let size = BoardSize(rawValue: raw) {
            selectedSize = size
        } else if name == "mode_pvp" {
            selectedMode = .playerVsPlayer
        } else if name == "mode_pvai" {
            selectedMode = .playerVsAI
        } else if name.hasPrefix("diff_") {
            if name.contains("easy") { selectedDifficulty = .easy }
            else if name.contains("medium") { selectedDifficulty = .medium }
            else if name.contains("hard") { selectedDifficulty = .hard }
        } else if name == "start" {
            startGame()
            return
        }
        refreshHighlights()
    }

    private func startGame() {
        let gameScene = GameScene(size: size)
        gameScene.scaleMode = .aspectFill
        gameScene.configure(boardSize: selectedSize, mode: selectedMode, difficulty: selectedDifficulty)
        view?.presentScene(gameScene, transition: .fade(withDuration: 0.4))
    }
}
