import SpriteKit

/// Основная игровая сцена: отрисовывает поле, обрабатывает ходы игрока(ов)
/// и запускает ход ИИ в режиме "Игрок vs Компьютер".
final class GameScene: SKScene {

    private var board: Board!
    private var boardSize: BoardSize = .small
    private var mode: GameMode = .playerVsAI
    private var difficulty: Difficulty = .medium
    private var ai: MinimaxAI?

    private var currentPlayer: PlayerMark = .x
    private let humanMark: PlayerMark = .x
    private let aiMark: PlayerMark = .o
    private var gameOver = false

    private var cellNodes: [[SKShapeNode]] = []
    private var boardOrigin: CGPoint = .zero
    private var cellSize: CGFloat = 0

    private var statusLabel: SKLabelNode!
    private var restartButton: SKLabelNode!
    private var menuButton: SKLabelNode!

    /// Вызывается перед показом сцены для настройки параметров партии
    func configure(boardSize: BoardSize, mode: GameMode, difficulty: Difficulty) {
        self.boardSize = boardSize
        self.mode = mode
        self.difficulty = difficulty
    }

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.08, green: 0.09, blue: 0.14, alpha: 1.0)
        startNewGame()
    }

    private func startNewGame() {
        removeAllChildren()
        board = Board(boardSize: boardSize)
        ai = (mode == .playerVsAI) ? MinimaxAI(aiMark: aiMark, difficulty: difficulty) : nil
        currentPlayer = .x
        gameOver = false

        buildBoardGrid()
        buildStatusUI()
        updateStatusLabel()
    }

    // MARK: - Построение сетки

    private func buildBoardGrid() {
        let n = boardSize.dimension
        let boardLength = min(frame.width, frame.height) * 0.8
        cellSize = boardLength / CGFloat(n)
        boardOrigin = CGPoint(x: frame.midX - boardLength / 2, y: frame.midY - boardLength / 2 + 40)

        cellNodes = Array(repeating: Array(repeating: SKShapeNode(), count: n), count: n)

        // Фон поля
        let backgroundRect = SKShapeNode(rectOf: CGSize(width: boardLength, height: boardLength), cornerRadius: 8)
        backgroundRect.position = CGPoint(x: boardOrigin.x + boardLength / 2, y: boardOrigin.y + boardLength / 2)
        backgroundRect.fillColor = SKColor(white: 1.0, alpha: 0.05)
        backgroundRect.strokeColor = .clear
        addChild(backgroundRect)

        for r in 0..<n {
            for c in 0..<n {
                let cell = SKShapeNode(rectOf: CGSize(width: cellSize - 4, height: cellSize - 4), cornerRadius: 6)
                cell.position = cellCenter(row: r, col: c)
                cell.strokeColor = SKColor(white: 1.0, alpha: 0.25)
                cell.lineWidth = 1.5
                cell.fillColor = .clear
                cell.name = "cell_\(r)_\(c)"
                addChild(cell)
                cellNodes[r][c] = cell
            }
        }
    }

    private func cellCenter(row: Int, col: Int) -> CGPoint {
        // row=0 отображаем снизу для наглядности координат; можно инвертировать при желании
        CGPoint(
            x: boardOrigin.x + CGFloat(col) * cellSize + cellSize / 2,
            y: boardOrigin.y + CGFloat(row) * cellSize + cellSize / 2
        )
    }

    private func buildStatusUI() {
        statusLabel = SKLabelNode(text: "")
        statusLabel.fontName = "AvenirNext-Bold"
        statusLabel.fontSize = 24
        statusLabel.fontColor = .white
        statusLabel.position = CGPoint(x: frame.midX, y: frame.maxY - 100)
        addChild(statusLabel)

        restartButton = SKLabelNode(text: "⟳ Заново")
        restartButton.fontName = "AvenirNext-DemiBold"
        restartButton.fontSize = 20
        restartButton.fontColor = .systemYellow
        restartButton.name = "restart"
        restartButton.position = CGPoint(x: frame.midX - 80, y: frame.minY + 60)
        addChild(restartButton)

        menuButton = SKLabelNode(text: "☰ Меню")
        menuButton.fontName = "AvenirNext-DemiBold"
        menuButton.fontSize = 20
        menuButton.fontColor = .lightGray
        menuButton.name = "menu"
        menuButton.position = CGPoint(x: frame.midX + 80, y: frame.minY + 60)
        addChild(menuButton)
    }

    private func updateStatusLabel() {
        switch board.result() {
        case .win(let winner):
            statusLabel.text = "Победили: \(winner.rawValue)!"
        case .draw:
            statusLabel.text = "Ничья!"
        case .ongoing:
            if mode == .playerVsAI {
                statusLabel.text = (currentPlayer == humanMark) ? "Ваш ход (\(humanMark.rawValue))" : "Ход компьютера…"
            } else {
                statusLabel.text = "Ход игрока \(currentPlayer.rawValue)"
            }
        }
    }

    // MARK: - Обработка касаний

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let node = atPoint(location)

        if node.name == "restart" {
            startNewGame()
            return
        }
        if node.name == "menu" {
            let menu = MenuScene(size: size)
            menu.scaleMode = .aspectFill
            view?.presentScene(menu, transition: .fade(withDuration: 0.4))
            return
        }

        guard !gameOver, let name = node.name, name.hasPrefix("cell_") else { return }
        // В режиме против ИИ во время хода компьютера ходы игрока игнорируются
        if mode == .playerVsAI && currentPlayer != humanMark { return }

        let parts = name.split(separator: "_")
        guard parts.count == 3, let row = Int(parts[1]), let col = Int(parts[2]) else { return }

        performMove(row: row, col: col)
    }

    // MARK: - Логика хода

    private func performMove(row: Int, col: Int) {
        guard board.place(currentPlayer, row: row, col: col) else { return }
        drawMark(currentPlayer, row: row, col: col)
        evaluateAfterMove()
    }

    private func evaluateAfterMove() {
        switch board.result() {
        case .win, .draw:
            gameOver = true
            updateStatusLabel()
            return
        case .ongoing:
            break
        }

        currentPlayer = currentPlayer.opposite
        updateStatusLabel()

        if mode == .playerVsAI && currentPlayer == aiMark {
            // Небольшая задержка перед ходом ИИ — субъективно ощущается как "раздумье"
            run(.sequence([.wait(forDuration: 0.35), .run { [weak self] in self?.performAIMove() }]))
        }
    }

    private func performAIMove() {
        guard !gameOver, let ai = ai, let move = ai.bestMove(on: board) else { return }
        performMove(row: move.row, col: move.col)
    }

    // MARK: - Отрисовка X / O

    private func drawMark(_ mark: PlayerMark, row: Int, col: Int) {
        let center = cellCenter(row: row, col: col)
        let inset = cellSize * 0.28

        let shapeNode: SKShapeNode
        if mark == .x {
            let path = CGMutablePath()
            path.move(to: CGPoint(x: -inset, y: -inset))
            path.addLine(to: CGPoint(x: inset, y: inset))
            path.move(to: CGPoint(x: -inset, y: inset))
            path.addLine(to: CGPoint(x: inset, y: -inset))
            shapeNode = SKShapeNode(path: path)
            shapeNode.strokeColor = .systemPink
        } else {
            shapeNode = SKShapeNode(circleOfRadius: inset)
            shapeNode.strokeColor = .systemTeal
        }
        shapeNode.lineWidth = 6
        shapeNode.lineCap = .round
        shapeNode.position = center
        shapeNode.setScale(0.1)
        addChild(shapeNode)
        shapeNode.run(.scale(to: 1.0, duration: 0.18))
    }
}
