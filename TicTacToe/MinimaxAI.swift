import Foundation

/// Игрок-компьютер. Использует minimax с альфа-бета отсечением.
/// Для маленького поля (3x3) поиск полный (до конца партии).
/// Для большого поля (5x5) поиск ограничен по глубине, а незавершённые
/// позиции оцениваются эвристической функцией (иначе перебор
/// становится вычислительно неподъёмным).
final class MinimaxAI {

    let aiMark: PlayerMark
    let humanMark: PlayerMark
    let difficulty: Difficulty

    init(aiMark: PlayerMark, difficulty: Difficulty) {
        self.aiMark = aiMark
        self.humanMark = aiMark.opposite
        self.difficulty = difficulty
    }

    /// Выбор хода в зависимости от сложности
    func bestMove(on board: Board) -> (row: Int, col: Int)? {
        switch difficulty {
        case .easy:
            return easyMove(on: board)
        case .medium:
            return searchMove(on: board, maxDepth: mediumDepth(for: board))
        case .hard:
            return searchMove(on: board, maxDepth: hardDepth(for: board))
        }
    }

    // MARK: - Лёгкий уровень: случайные ходы + элемент эвристики

    private func easyMove(on board: Board) -> (row: Int, col: Int)? {
        let moves = board.availableMoves()
        guard !moves.isEmpty else { return nil }

        // С вероятностью 35% играем осознанно: выигрываем, если можем,
        // иначе блокируем немедленную угрозу соперника.
        if Double.random(in: 0...1) < 0.35 {
            if let winning = immediateWinningMove(for: aiMark, on: board) { return winning }
            if let blocking = immediateWinningMove(for: humanMark, on: board) { return blocking }
        }
        return moves.randomElement()
    }

    private func immediateWinningMove(for mark: PlayerMark, on board: Board) -> (row: Int, col: Int)? {
        for move in board.availableMoves() {
            var trial = board
            trial.place(mark, row: move.row, col: move.col)
            if case .win(let winner) = trial.result(), winner == mark {
                return move
            }
        }
        return nil
    }

    // MARK: - Глубина поиска по сложности

    private func mediumDepth(for board: Board) -> Int {
        board.size == 3 ? 3 : 3
    }

    private func hardDepth(for board: Board) -> Int {
        // 3x3: полный перебор (максимум 9 ходов) — гарантированно
        //      либо непобедимый ИИ, либо неизбежный проигрыш при ошибке игрока.
        // 5x5: полный перебор невозможен за разумное время, поэтому
        //      ограничиваем глубину и используем эвристику.
        board.size == 3 ? 9 : 5
    }

    // MARK: - Поиск лучшего хода

    private func searchMove(on board: Board, maxDepth: Int) -> (row: Int, col: Int)? {
        let moves = board.availableMoves()
        guard !moves.isEmpty else { return nil }

        var bestScore = Int.min
        var bestMoves: [(row: Int, col: Int)] = []

        for move in moves {
            var trial = board
            trial.place(aiMark, row: move.row, col: move.col)
            let score = minimax(
                board: trial,
                depth: maxDepth - 1,
                isMaximizing: false,
                alpha: Int.min,
                beta: Int.max
            )
            if score > bestScore {
                bestScore = score
                bestMoves = [move]
            } else if score == bestScore {
                bestMoves.append(move)
            }
        }
        // Среди равноценных ходов выбираем случайный, чтобы партии не были однообразными
        return bestMoves.randomElement()
    }

    private func minimax(board: Board, depth: Int, isMaximizing: Bool, alpha: Int, beta: Int) -> Int {
        switch board.result() {
        case .win(let winner):
            let baseScore = (winner == aiMark) ? 1000 : -1000
            // Учитываем глубину, чтобы ИИ предпочитал быстрые победы и медленные поражения
            return baseScore + (isMaximizing ? -depth : depth)
        case .draw:
            return 0
        case .ongoing:
            if depth == 0 {
                return evaluateHeuristic(board)
            }
        }

        var alpha = alpha
        var beta = beta

        if isMaximizing {
            var best = Int.min
            for move in board.availableMoves() {
                var trial = board
                trial.place(aiMark, row: move.row, col: move.col)
                let score = minimax(board: trial, depth: depth - 1, isMaximizing: false, alpha: alpha, beta: beta)
                best = max(best, score)
                alpha = max(alpha, best)
                if beta <= alpha { break } // отсечение
            }
            return best
        } else {
            var best = Int.max
            for move in board.availableMoves() {
                var trial = board
                trial.place(humanMark, row: move.row, col: move.col)
                let score = minimax(board: trial, depth: depth - 1, isMaximizing: true, alpha: alpha, beta: beta)
                best = min(best, score)
                beta = min(beta, best)
                if beta <= alpha { break } // отсечение
            }
            return best
        }
    }

    // MARK: - Эвристическая оценка незавершённой позиции (для 5x5 с ограниченной глубиной)

    /// Оценивает позицию по количеству потенциально выигрышных линий,
    /// открытых для каждого игрока: чем больше "живых" линий и чем они
    /// заполненнее своими метками (без блокировки соперником), тем выше оценка.
    private func evaluateHeuristic(_ board: Board) -> Int {
        var score = 0
        let directions = [(0, 1), (1, 0), (1, 1), (1, -1)]
        let n = board.size
        let winLen = board.winLength

        for r in 0..<n {
            for c in 0..<n {
                for (dr, dc) in directions {
                    let endR = r + dr * (winLen - 1)
                    let endC = c + dc * (winLen - 1)
                    guard endR >= 0, endR < n, endC >= 0, endC < n else { continue }

                    var aiCount = 0
                    var humanCount = 0
                    for step in 0..<winLen {
                        let mark = board.mark(atRow: r + dr * step, col: c + dc * step)
                        if mark == aiMark { aiCount += 1 }
                        else if mark == humanMark { humanCount += 1 }
                    }
                    // Линия "жива" только если в ней нет меток соперника
                    if humanCount == 0 && aiCount > 0 {
                        score += weight(for: aiCount)
                    } else if aiCount == 0 && humanCount > 0 {
                        score -= weight(for: humanCount)
                    }
                }
            }
        }
        return score
    }

    private func weight(for count: Int) -> Int {
        switch count {
        case 1: return 1
        case 2: return 10
        case 3: return 100
        default: return 1000
        }
    }
}
