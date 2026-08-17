import Foundation

/// Метка игрока на поле
enum PlayerMark: String {
    case x = "X"
    case o = "O"

    var opposite: PlayerMark { self == .x ? .o : .x }
}

/// Режим игры
enum GameMode {
    case playerVsPlayer
    case playerVsAI
}

/// Уровень сложности ИИ
enum Difficulty {
    case easy
    case medium
    case hard

    var title: String {
        switch self {
        case .easy: return "Лёгкий"
        case .medium: return "Средний"
        case .hard: return "Сложный"
        }
    }
}

/// Размер игрового поля и длина выигрышной линии
enum BoardSize: Int, CaseIterable {
    case small = 3   // 3x3, линия из 3
    case large = 5   // 5x5, линия из 4

    var dimension: Int { rawValue }

    /// Сколько подряд стоящих меток нужно для победы
    var winLength: Int {
        switch self {
        case .small: return 3
        case .large: return 4
        }
    }

    var title: String { "\(dimension)×\(dimension)" }
}

/// Результат завершения партии
enum GameResult {
    case win(PlayerMark)
    case draw
    case ongoing
}
