import UIKit

class AddTrueFalseCardViewController: UIViewController {
    let store = CoreDataStore()
    var deck: Deck? // retrieved from the sender
    
    @IBOutlet weak var deckLabel: UILabel!
    @IBOutlet weak var promptInput: UITextView!
    @IBOutlet weak var trueFalseSegmentedControl: UISegmentedControl!
    
    @IBAction func addCardButtonClicked(_ sender: UIButton) {
        guard let prompt = promptInput.text,
              let deck = deck
        else { return }
        
        /// Gets the string in the segmented control's selection.
        let solutionString = trueFalseSegmentedControl.selectedSegmentIndex == 1 ? Constants.TRUE_STRING : Constants.FALSE_STRING
        
        let card = MultipleChoiceCard(id: UUID().uuidString, prompt: prompt, solution: solutionString, creationDate: .now, dueDate: .now, nextDueDateMultiplier: Constants.NEW_CARD_DUE_DATE_MULTIPLIER, options: Constants.TRUE_FALSE_OPTIONS)
        
        do { // Try to add the card to the deck into the Core Data store. Clear the input fields on success.
            try store.insertMultipleChoiceCard(card, deck)
            promptInput.text = ""
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
    }
}

/* Handles the placeholder text logic in the TextView. */
extension AddTrueFalseCardViewController: UITextViewDelegate {
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
            textView.text = "Enter the answer to the prompt."
            textView.textColor = .lightGray
        }
    }
}
