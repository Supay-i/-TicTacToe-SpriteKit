import Foundation

/// Модель игрового поля NxN с обобщённой проверкой "N в ряд".
/// Значение — тип-структура (value type), поэтому копируется при присваивании,
/// что удобно для перебора ходов в minimax без побочных эффектов.
struct Board {

    let size: Int
    let winLength: Int
    private(set) var cells: [[PlayerMark?]]

    init(boardSize: BoardSize) {
        self.size = boardSize.dimension
        self.winLength = boardSize.winLength
        self.cells = Array(repeating: Array(repeating: nil, count: size), count: size)
    }

    /// Список свободных клеток (row, col)
    func availableMoves() -> [(row: Int, col: Int)] {
        var moves: [(Int, Int)] = []
        for r in 0..<size {
            for c in 0..<size {
                if cells[r][c] == nil { moves.append((r, c)) }
            }
        }
        return moves
    }

    func isFull() -> Bool {
        for row in cells {
            if row.contains(where: { $0 == nil }) { return false }
        }
        return true
    }

    /// Поставить метку. Возвращает false, если клетка занята или вне границ.
    @discardableResult
    mutating func place(_ mark: PlayerMark, row: Int, col: Int) -> Bool {
        guard row >= 0, row < size, col >= 0, col < size, cells[row][col] == nil else {
            return false
        }
        cells[row][col] = mark
        return true
    }

    func mark(atRow row: Int, col: Int) -> PlayerMark? { cells[row][col] }

    /// Проверка победителя перебором всех линий длины winLength
    /// по 4 направлениям: горизонталь, вертикаль, обе диагонали.
    func winner() -> PlayerMark? {
        let directions = [(0, 1), (1, 0), (1, 1), (1, -1)]

        for r in 0..<size {
            for c in 0..<size {
                guard let startMark = cells[r][c] else { continue }
                for (dr, dc) in directions {
                    var count = 1
                    var rr = r + dr
                    var cc = c + dc
                    while rr >= 0, rr < size, cc >= 0, cc < size, cells[rr][cc] == startMark {
                        count += 1
                        if count == winLength { return startMark }
                        rr += dr
                        cc += dc
                    }
                }
            }
        }
        return nil
    }

    func result() -> GameResult {
        if let w = winner() { return .win(w) }
        if isFull() { return .draw }
        return .ongoing
    }
}
