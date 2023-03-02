import UIKit

class AddMultipleChoiceViewController: UIViewController {
    let store = CoreDataStore()
    var deck: Deck? // retrieved from the sender
    
    @IBOutlet weak var deckLabel: UILabel!
    @IBOutlet weak var promptInput: UITextView!
    @IBOutlet weak var optionsInput: UITextView!
    @IBOutlet weak var solutionInput: UITextView!
    
    @IBAction func addCardButtonClicked(_ sender: UIButton) {
        guard let prompt = promptInput.text,
              let trimmedSolution = solutionInput.text?.trimmingCharacters(in: .whitespaces), // trim whitespace
              let options = optionsInput.text,
              let deck = deck
        else { return }
        
        // Split the options into an array of options for input validation
        let splitOptions = options.split(separator: "|").map({ $0.trimmingCharacters(in: .whitespaces) })
        
        if splitOptions.count > 4 { // At most 4 multiple choice options allowed
            showErrorAlert("Error", "Multiple choice cards can have at most 4 options, i.e. 3 '|' characters.")
            return
        } else if !splitOptions.map({ String($0) }).contains(trimmedSolution) { // the solution must be one of the provided options
            showErrorAlert("Error", "The solution must be one of the multiple choice options.")
            return
        }
        
        let card = MultipleChoiceCard(id: UUID().uuidString, prompt: prompt, solution: trimmedSolution, creationDate: .now, dueDate: .now, nextDueDateMultiplier: Constants.NEW_CARD_DUE_DATE_MULTIPLIER, options: options)
        self.addMultipleChoiceCardToDeck(card, deck)
    }
    
    /// Try to add the card to the deck into the Core Data store. Clear the input fields on success.
    func addMultipleChoiceCardToDeck(_ card: MultipleChoiceCard, _ deck: Deck) {
        do {
            try store.insertMultipleChoiceCard(card, deck)
            promptInput.text = ""
            solutionInput.text = ""
            optionsInput.text = ""
        } catch {
            showErrorAlert("Error", "Sorry, there was an error adding to the deck.")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dismissKeyboardOnOutsideClick()
        
        if let deck = deck { deckLabel.text = "Deck: \(deck.title)" }
        else { return }
        
        /* Make the UITextViews have placeholder text and a border somewhat like UITextField does. */
        promptInput.layer.borderColor = UIColor.systemGray.cgColor
        promptInput.layer.borderWidth = 1.0
        promptInput.layer.cornerRadius = 5.0
        promptInput.textColor = .lightGray
        promptInput.text = "Enter the card's question / prompt."
        promptInput.delegate = self
        
        optionsInput.layer.borderColor = UIColor.systemGray.cgColor
        optionsInput.layer.borderWidth = 1.0
        optionsInput.layer.cornerRadius = 5.0
        optionsInput.textColor = .lightGray
        optionsInput.text = "Enter the possible choices separated by |,\ne.g. Corn | Tree | Dog. Max 4 options."
        optionsInput.delegate = self
        
        solutionInput.layer.borderColor = UIColor.systemGray.cgColor
        solutionInput.layer.borderWidth = 1.0
        solutionInput.layer.cornerRadius = 5.0
        solutionInput.textColor = .lightGray
        solutionInput.text = "Enter the correct choice from the provided options, e.g. Tree."
        solutionInput.delegate = self
    }
}

/* Handles the placeholder text logic in the TextView. */
extension AddMultipleChoiceViewController: UITextViewDelegate {
    /// Changes the text color from grey to black when the user types in the text view.
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .lightGray {
            textView.text = nil
            textView.textColor = .black
        }
    }
    
    /// Show the placeholder text if the user clears the text view.
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            if textView == promptInput { textView.text = "Enter the card's question / prompt." }
            else if textView == optionsInput { textView.text = "Enter the possible choices separated by |,\ne.g. Corn | Tree | Dog. Max 4 options." }
            else if textView == solutionInput { textView.text = "Enter the correct choice from the provided options, e.g. Tree." }
            
            textView.textColor = .lightGray
        }
    }
}
