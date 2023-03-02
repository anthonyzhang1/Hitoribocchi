import Foundation

/// A card with the attributes every other card should also have.
protocol Card: Codable {
    /// Should be a UUID.
    var id: String { get }
    /// The prompt / question the user has to answer.
    var prompt: String { get }
    /// The answer to the prompt / question.
    var solution: String { get }
    /// The date the card was created.
    var creationDate: Date { get }
    /// The date the card is next due.
    var dueDate: Date { get set }
    /// Determines when the next due date will be by multiplying some predetermined amount of time with this multiplier.
    /// Example values: 0.1, 0.8, 2.1.
    var nextDueDateMultiplier: Double { get set }
}

/// A deck of cards.
struct Deck: Codable {
    /// Should be a UUID.
    let id: String
    /// The title of the deck.
    let title: String
}

/// A basic card with only a prompt and a solution. The user tells the app whether they were correct or not, and how confident they were with recalling the answer.
struct BasicCard: Card {
    let id: String
    let prompt: String
    let solution: String
    let creationDate: Date
    var dueDate: Date
    var nextDueDateMultiplier: Double
}

/**
 A card that allows for multiple options, of which only one is correct. This struct is also used for True / False cards.
 The user will not be able to specify whether they were correct or not; it is determined by the app.
 */
struct MultipleChoiceCard: Card {
    let id: String
    let prompt: String
    let solution: String // Should be an element in `options`.
    let creationDate: Date
    var dueDate: Date
    var nextDueDateMultiplier: Double
    /// Each option will be separated with `|`, e.g. "Kennedy | Lincoln | Obama".
    let options: String
}
