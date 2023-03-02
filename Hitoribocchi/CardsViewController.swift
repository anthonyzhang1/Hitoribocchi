import UIKit

class CardsViewController: UIViewController {
    let calendar = Calendar.current // used to calculate the new due dates after answering a card
    let store = CoreDataStore()
    var deck: Deck? // retrieved from the sender
    var dueCards: [Card] = [] // retrieved from the store and displayed to the user
    /// The index of the currently shown card.
    var currentCardIndex = 0
    
    @IBOutlet weak var promptLabel: UILabel!
    @IBOutlet weak var seperatorBar: UIView!
    @IBOutlet weak var solutionLabel: UILabel!
    
    /// Used to hide/show the basic card response buttons.
    @IBOutlet weak var basicCardView: UIView!
    
    /* Basic card buttons for gauging the user's confidence with recalling the solution to the flashcard. */
    @IBOutlet weak var retryButton: UIButton!
    @IBOutlet weak var hardButton: UIButton!
    @IBOutlet weak var okayButton: UIButton!
    @IBOutlet weak var easyButton: UIButton!
    
    /// Used to hide/show the multiple choice options.
    @IBOutlet weak var multipleChoiceCardView: UIView!
    
    /* Buttons for the multiple choice options. */
    @IBOutlet weak var optionAButton: UIButton!
    @IBOutlet weak var optionBButton: UIButton!
    @IBOutlet weak var optionCButton: UIButton!
    @IBOutlet weak var optionDButton: UIButton!
    
    /// Show an action sheet prompting the user what type of flashcard to add when they click the Add button.
    @IBAction func addButtonClicked(_ sender: UIBarButtonItem) {
        let prompt = UIAlertController(title: "Select the type of flashcard to add.", message: nil, preferredStyle: .actionSheet)
        
        // Add the Basic Flashcard option
        prompt.addAction(UIAlertAction(title: "Basic", style: .default) { _ in
            self.performSegue(withIdentifier: "addBasicCardSegue", sender: sender)
        })
        
        // Add the True/False Flashcard option
        prompt.addAction(UIAlertAction(title: "True / False", style: .default) { _ in
            self.performSegue(withIdentifier: "addTrueFalseCardSegue", sender: sender)
        })
        
        // Add the Multiple Choice Flashcard option
        prompt.addAction(UIAlertAction(title: "Multiple Choice", style: .default) { _ in
            self.performSegue(withIdentifier: "addMultipleChoiceCardSegue", sender: sender)
        })
        
        // Add the Cancel option
        prompt.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(prompt, animated: true, completion: nil) // show the alert
    }
    
    /// Show an alert prompting the user if they want to actually delete the card.
    @IBAction func deleteButtonClicked(_ sender: UIBarButtonItem) {
        // handle the case where there is no card being shown, therefore there is no card to delete
        if currentCardIndex >= dueCards.count {
            let alert = UIAlertController(title: "There is no card to delete.", message: "You need to be viewing a card in order to delete it.", preferredStyle: .alert)
            
            // Add the OK button to the alert box
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            
            // Show the alert, and return so that we do not execute the rest of the function
            present(alert, animated: true, completion: nil)
            return
        }
        
        let alert = UIAlertController(title: "Delete Current Card", message: "Are you sure you want to delete this card?", preferredStyle: .alert)
        
        // Add the cancel button to the alert box
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        // Add the delete button to the alert box. When it is clicked, try to delete the currently shown card. The deck is refreshed to update the deck's cards.
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            do {
                try self.store.deleteCard(self.dueCards[self.currentCardIndex])
                self.getDueCardsFromDeck()
                self.displayCurrentCard()
            } catch {
                self.showErrorAlert("Error", "Sorry, there was an error deleting the card.")
            }
        })
        
        present(alert, animated: true, completion: nil) // show the alert
    }
    
    /// Navigates to the Card Details screen for the current card.
    @IBAction func viewDetailsButtonClicked(_ sender: UIBarButtonItem) {
        // handle the case where there is no card being shown, therefore there is no card to view
        if currentCardIndex >= dueCards.count {
            let alert = UIAlertController(title: "There is no card to view the details of.", message: "You need to be viewing a card in order to view its details.", preferredStyle: .alert)
            
            // Add the OK button to the alert box
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            
            // Show the alert, and return so that we do not execute the rest of the function
            present(alert, animated: true, completion: nil)
            return
        }
        
        performSegue(withIdentifier: "cardsToCardDetailsSegue", sender: sender)
    }
    
    /// Sets the new due date of the current basic card based on the button the user clicked. Then, advance to the next card.
    @IBAction func basicCardButtonClicked(_ sender: UIButton) {
        /// The current card being displayed to the user.
        var currentCard = dueCards[currentCardIndex]
        
        switch (sender.tag) {
        case Constants.RETRY_BUTTON_TAG: // retry button clicked
            // calculate the new due date
            guard let newDueDate = calendar.date(byAdding: .minute, value: Int(currentCard.nextDueDateMultiplier * Constants.RETRY_BASE_MINUTES_UNTIL_DUE_DATE), to: .now)
            else { return }
            
            // sets the new due date and the new due date multiplier
            currentCard.dueDate = newDueDate
            currentCard.nextDueDateMultiplier = getNewDueDateMultiplier(oldMultiplier: currentCard.nextDueDateMultiplier, multiplierFactor: Constants.RETRY_DUE_DATE_MULTIPLIER_FACTOR, multiplierIncrement: Constants.RETRY_DUE_DATE_MULTIPLIER_INCREMENT)
            
            updateCardAndAdvance(currentCard)
            break
            
        case Constants.HARD_BUTTON_TAG: // hard button clicked
            // calculate the new due date
            guard let newDueDate = calendar.date(byAdding: .minute, value: Int(currentCard.nextDueDateMultiplier * Constants.HARD_BASE_MINUTES_UNTIL_DUE_DATE), to: .now)
            else { return }
            
            // sets the new due date and the new due date multiplier
            currentCard.dueDate = newDueDate
            currentCard.nextDueDateMultiplier = getNewDueDateMultiplier(oldMultiplier: currentCard.nextDueDateMultiplier, multiplierFactor: Constants.HARD_DUE_DATE_MULTIPLIER_FACTOR, multiplierIncrement: Constants.HARD_DUE_DATE_MULTIPLIER_INCREMENT)
            
            updateCardAndAdvance(currentCard)
            break
            
        case Constants.OKAY_BUTTON_TAG: // okay button clicked
            // calculate the new due date
            guard let newDueDate = calendar.date(byAdding: .minute, value: Int(currentCard.nextDueDateMultiplier * Constants.OKAY_BASE_MINUTES_UNTIL_DUE_DATE), to: .now)
            else { return }
            
            // sets the new due date and the new due date multiplier
            currentCard.dueDate = newDueDate
            currentCard.nextDueDateMultiplier = getNewDueDateMultiplier(oldMultiplier: currentCard.nextDueDateMultiplier, multiplierFactor: Constants.OKAY_DUE_DATE_MULTIPLIER_FACTOR, multiplierIncrement: Constants.OKAY_DUE_DATE_MULTIPLIER_INCREMENT)
            
            updateCardAndAdvance(currentCard)
            break
            
        case Constants.EASY_BUTTON_TAG:
            // calculate the new due date
            guard let newDueDate = calendar.date(byAdding: .minute, value: Int(currentCard.nextDueDateMultiplier * Constants.EASY_BASE_MINUTES_UNTIL_DUE_DATE), to: .now)
            else { return }
            
            // sets the new due date and the new due date multiplier
            currentCard.dueDate = newDueDate
            currentCard.nextDueDateMultiplier = getNewDueDateMultiplier(oldMultiplier: currentCard.nextDueDateMultiplier, multiplierFactor: Constants.EASY_DUE_DATE_MULTIPLIER_FACTOR, multiplierIncrement: Constants.EASY_DUE_DATE_MULTIPLIER_INCREMENT)
            
            updateCardAndAdvance(currentCard)
            break
            
        default:
            showErrorAlert("Error", "Sorry, there was an error updating your card.")
        }
    }
    
    /// Sets the new due date of the current multiple choice card based on the answer the user clicked. If it is wrong, then the card will appear sooner. If it is correct, the card will appear later. Then, advance to the next card. */
    @IBAction func multipleChoiceOptionClicked(_ sender: UIButton) {
        /// The current multiple choice card being displayed to the user.
        guard var currentCard = dueCards[currentCardIndex] as? MultipleChoiceCard
        else { return }
        
        /// The multiple choice options.
        let options = currentCard.options.split(separator: "|").map({ $0.trimmingCharacters(in: .whitespaces) })
        
        // Gets the index of the solution within the multiple choice options.
        guard let solutionIndex = options.firstIndex(of: currentCard.solution)
        else { return }
        
        if solutionIndex != sender.tag { // incorrect answer provided
            solutionLabel.isHidden = false
            solutionLabel.text = "\"\(options[sender.tag])\" is incorrect. This card is now due again."
            solutionLabel.textColor = .red
        }
        else if solutionIndex == sender.tag,
                !solutionLabel.isHidden
        { // correct answer provided after getting the question wrong
            // calculate the new due date
            guard let newDueDate = calendar.date(byAdding: .minute, value: Int(currentCard.nextDueDateMultiplier * Constants.INCORRECT_BASE_MINUTES_UNTIL_DUE_DATE), to: .now)
            else { return }
            
            // sets the new due date and the new due date multiplier
            currentCard.dueDate = newDueDate
            currentCard.nextDueDateMultiplier = getNewDueDateMultiplier(oldMultiplier: currentCard.nextDueDateMultiplier, multiplierFactor: Constants.INCORRECT_DUE_DATE_MULTIPLIER_FACTOR, multiplierIncrement: Constants.INCORRECT_DUE_DATE_MULTIPLIER_INCREMENT)
            
            solutionLabel.textColor = .black
            updateCardAndAdvance(currentCard)
        }
        else if solutionIndex == sender.tag,
                solutionLabel.isHidden
        { // correct answer provided the first time. the user never got the question wrong
            // calculate the new due date
            guard let newDueDate = calendar.date(byAdding: .minute, value: Int(currentCard.nextDueDateMultiplier * Constants.CORRECT_BASE_MINUTES_UNTIL_DUE_DATE), to: .now)
            else { return }
            
            // sets the new due date and the new due date multiplier
            currentCard.dueDate = newDueDate
            currentCard.nextDueDateMultiplier = getNewDueDateMultiplier(oldMultiplier: currentCard.nextDueDateMultiplier, multiplierFactor: Constants.CORRECT_DUE_DATE_MULTIPLIER_FACTOR, multiplierIncrement: Constants.CORRECT_DUE_DATE_MULTIPLIER_INCREMENT)
            
            updateCardAndAdvance(currentCard)
        }
    }
    
    /// Show the solution of a basic card when the screen is tapped.
    @IBAction func screenTapped(_ sender: UITapGestureRecognizer) {
        // make sure that we do not get an out of bounds error
        guard currentCardIndex < dueCards.count
        else { return }
        
        /// The current card being displayed to the user.
        let currentCard = dueCards[currentCardIndex]
        
        if currentCard is BasicCard { // Handle the on click display for a basic card
            seperatorBar.isHidden = false
            solutionLabel.isHidden = false
            solutionLabel.text = currentCard.solution
            basicCardView.isHidden = false
            
            /* Sets the buttons' text so that it shows how long until the current card will be due if that button was pressed. */
            retryButton.setTitle("Retry\n\(getTimeUntilCardDueAsString(Int(currentCard.nextDueDateMultiplier * Constants.RETRY_BASE_MINUTES_UNTIL_DUE_DATE)))", for: .normal)
            
            hardButton.setTitle("Hard\n\(getTimeUntilCardDueAsString(Int(currentCard.nextDueDateMultiplier * Constants.HARD_BASE_MINUTES_UNTIL_DUE_DATE)))", for: .normal)
            
            okayButton.setTitle("Okay\n\(getTimeUntilCardDueAsString(Int(currentCard.nextDueDateMultiplier * Constants.OKAY_BASE_MINUTES_UNTIL_DUE_DATE)))", for: .normal)
            
            easyButton.setTitle("Easy\n\(getTimeUntilCardDueAsString(Int(currentCard.nextDueDateMultiplier * Constants.EASY_BASE_MINUTES_UNTIL_DUE_DATE)))", for: .normal)
        }
    }
    
    /// Gets a string representing how long it will take for a card to be due again, e.g. 20 m, 18 h, 3 d.
    func getTimeUntilCardDueAsString(_ minutesUntilDue: Int) -> String {
        if minutesUntilDue < 1 { // < 1 min until due
            return "< 1 m"
        }
        else if minutesUntilDue < Constants.MINUTES_IN_ONE_HOUR { // 1-59 mins until due
            return "\(minutesUntilDue) m"
        }
        else if minutesUntilDue < Constants.MINUTES_IN_ONE_DAY { // 1-23 hours until due
            return "\(minutesUntilDue / Constants.MINUTES_IN_ONE_HOUR) h"
        }
        else if minutesUntilDue < Constants.MINUTES_IN_ONE_MONTH { // 1-29 days until due
            return "\(minutesUntilDue / Constants.MINUTES_IN_ONE_DAY) d"
        }
        else if minutesUntilDue < Constants.MINUTES_IN_ONE_YEAR { // 1-11 months until due
            return "\(minutesUntilDue / Constants.MINUTES_IN_ONE_MONTH) mo"
        }
        else { // 1+ years until due
            return "\(minutesUntilDue / Constants.MINUTES_IN_ONE_YEAR) y"
        }
    }
    
    /**
     Gets the new due date multiplier for a card. The returned double will always be positive.
     The old due date multiplier is retrieved from the card's attribute. The multiplier factor and increment are determined by the user's response, e.g. how confident they were with a basic card or whether they got a multiple choice question right.
     */
    func getNewDueDateMultiplier(oldMultiplier: Double, multiplierFactor: Double, multiplierIncrement: Double) -> Double {
        let newMultiplier = (oldMultiplier * multiplierFactor) + multiplierIncrement
        return newMultiplier >= 0.01 ? newMultiplier : 0.01 // do not allow <= 0.00 as the new multiplier
    }
    
    /// Handle the displaying of the current card.
    func displayCurrentCard() {
        /* Hide and show the things we need when first seeing a card. */
        promptLabel.isHidden = false
        seperatorBar.isHidden = true
        solutionLabel.isHidden = true
        basicCardView.isHidden = true
        multipleChoiceCardView.isHidden = true
        
        if getDeckCardCount() == 0 { // if the deck has no cards
            promptLabel.text = """
            This deck has no cards.
            
            You can add more cards to this deck by pressing the + button above.
            """
            
            return
        } else if (currentCardIndex >= dueCards.count) { // if no cards are due yet
            promptLabel.text = """
            No cards are due yet.
            
            You can wait for cards to become due, or you can add more cards to this deck.
            """
            
            return
        }
        
        /// The current card being displayed to the user.
        let currentCard = dueCards[currentCardIndex]
        
        promptLabel.text = currentCard.prompt
        
        /* Multiple choice cards need special handling when displaying them. */
        if let currentCard = currentCard as? MultipleChoiceCard {
            multipleChoiceCardView.isHidden = false
            optionAButton.isHidden = true
            optionBButton.isHidden = true
            optionCButton.isHidden = true
            optionDButton.isHidden = true
            
            /// The possible multiple choices.
            let options = currentCard.options.split(separator: "|").map({$0.trimmingCharacters(in: .whitespaces)})
            
            /* Display the multiple choice buttons depending on how many options were provided for this card. */
            if options.count >= 1 {
                optionAButton.isHidden = false
                optionAButton.setTitle(options[0], for: .normal)
            }
            if options.count >= 2 {
                optionBButton.isHidden = false
                optionBButton.setTitle(options[1], for: .normal)
            }
            if options.count >= 3 {
                optionCButton.isHidden = false
                optionCButton.setTitle(options[2], for: .normal)
            }
            if options.count >= 4 {
                optionDButton.isHidden = false
                optionDButton.setTitle(options[3], for: .normal)
            }
        }
    }
    
    /// Update the card's due date in the store and proceed to the next card.
    func updateCardAndAdvance(_ card: Card) {
        do {
            try store.updateCardDueDate(card)
            currentCardIndex += 1
            
            if currentCardIndex >= dueCards.count { // refresh the deck after reaching the end of the due cards
                getDueCardsFromDeck()
                currentCardIndex = 0
            }
            
            displayCurrentCard()
            return
        } catch {
            showErrorAlert("Error", "Sorry, there was an error updating your card.")
        }
    }
    
    /// Gets the cards from the store and fill the `dueCards` array with the retrieved cards. Then, shuffle the deck.
    func getDueCardsFromDeck() {
        guard let deck = deck
        else { return }
        
        do {
            dueCards = try store.getDueCardsFromDeck(deck)
            dueCards = dueCards.shuffled()
            currentCardIndex = 0
        } catch {
            showErrorAlert("Error", "Sorry, there was an error retrieving the cards.")
        }
    }
    
    /// Gets the number of cards in `deck`, including non-due ones.
    func getDeckCardCount() -> Int {
        guard let deck = deck
        else { return 0 }
        
        do {
            return try store.getDeckCardCount(deck)
        } catch {
            self.showErrorAlert("Error", "Sorry, there was an error getting the deck's card count.")
            return 0
        }
    }
    
    /// Get the due cards and display them.
    override func viewDidAppear(_ animated: Bool) {
        getDueCardsFromDeck()
        displayCurrentCard()
    }
    
    /// Sends the deck to one of the Add Card windows, depending on which option the user pressed.
    /// Or, segue to the view card details page if the View Details button was pressed.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addBasicCardSegue" { // add basic cards
            if let addCardViewController = segue.destination as? AddBasicCardViewController,
               let deck = deck
            { addCardViewController.deck = deck }
        } else if segue.identifier == "addTrueFalseCardSegue" { // add true/false cards
            if let addCardViewController = segue.destination as? AddTrueFalseCardViewController,
               let deck = deck
            { addCardViewController.deck = deck }
        } else if segue.identifier == "addMultipleChoiceCardSegue" { // add multiple choice cards
            if let addCardViewController = segue.destination as? AddMultipleChoiceViewController,
               let deck = deck
            { addCardViewController.deck = deck }
        } else if segue.identifier == "cardsToCardDetailsSegue" { // view card details screen
            if let cardDetailsViewController = segue.destination as? CardDetailsViewController
            { cardDetailsViewController.currentCard = dueCards[currentCardIndex] }
        }
    }
}
