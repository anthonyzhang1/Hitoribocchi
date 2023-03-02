import UIKit

class AddBasicCardViewController: UIViewController {
    let store = CoreDataStore()
    var deck: Deck? // retrieved from the sender
    
    @IBOutlet weak var deckLabel: UILabel!
    @IBOutlet weak var promptInput: UITextView!
    @IBOutlet weak var solutionInput: UITextView!
    
    @IBAction func addCardButtonClicked(_ sender: UIButton) {
        guard let prompt = promptInput.text,
              let solution = solutionInput.text,
              let deck = deck
        else { return }
        
        let card = BasicCard(id: UUID().uuidString, prompt: prompt, solution: solution, creationDate: .now, dueDate: .now, nextDueDateMultiplier: Constants.NEW_CARD_DUE_DATE_MULTIPLIER)
        
        do { // Try to add the card to the deck into the Core Data store. Clear the input fields on success.
            try store.insertBasicCard(card, deck)
            promptInput.text = ""
            solutionInput.text = ""
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
        
        solutionInput.layer.borderColor = UIColor.systemGray.cgColor
        solutionInput.layer.borderWidth = 1.0
        solutionInput.layer.cornerRadius = 5.0
        solutionInput.textColor = .lightGray
        solutionInput.text = "Enter the answer to the prompt."
        solutionInput.delegate = self
    }
}

/* Handles the placeholder text logic in the TextView. */
extension AddBasicCardViewController: UITextViewDelegate {
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
            else if textView == solutionInput { textView.text = "Enter the answer to the prompt." }
            
            textView.textColor = .lightGray
        }
    }
}
