/* This file holds constants and functions used by the multiple view controller files. */

import UIKit

/// Holds constants that are used throughout the project. We have a lot of constants because there is a lot of numbers used to calculate the card's next due date.
struct Constants {
    /* ----------- Card Search Values --------------- */
    
    /// The maximum number of cards returned for each Card entity when searching. The actual number of results can be up to N times greater than this value, where N is the number of card entities that exist.
    static let SEARCH_FETCH_LIMIT = 50
    
    /* -------- True / False Card Values ---------- */
    
    /// Used to represent the correct solution when creating a true/false question card.
    static let TRUE_STRING = "True"
    
    /// Used to represent the correct solution when creating a true/false question card.
    static let FALSE_STRING = "False"
    
    /// The options value for true/false cards, i.e. "True | False".
    static let TRUE_FALSE_OPTIONS = "\(TRUE_STRING) | \(FALSE_STRING)"
    
    /* ----------- Basic Card Answer Button Tags ------------ */
    
    /// The tag value for the "Retry" button in the Study Cards screen, for basic cards.
    static let RETRY_BUTTON_TAG = 0
    
    /// The tag value for the "Hard" button in the Study Cards screen, for basic cards.
    static let HARD_BUTTON_TAG = 1
    
    /// The tag value for the "Okay" button in the Study Cards screen, for basic cards.
    static let OKAY_BUTTON_TAG = 2
    
    /// The tag value for the "Easy" button in the Study Cards screen, for basic cards.
    static let EASY_BUTTON_TAG = 3
    
    /* --------- Time Conversation Values used for showing the due date as a custom string ---------- */
    
    /// How many seconds there are in a minute.
    static let SECONDS_IN_ONE_MINUTE = 60
    
    /// How many hours there are in a day, roughly.
    static let HOURS_IN_ONE_DAY = 24
    
    /// How many days there are in a month, roughly.
    static let DAYS_IN_ONE_MONTH = 30
    
    /// How many months there are in a year.
    static let MONTHS_IN_ONE_YEAR = 12
    
    /// How many minutes there are in an hour.
    static let MINUTES_IN_ONE_HOUR = 60
    
    /// How many minutes there are in a day, roughly.
    static let MINUTES_IN_ONE_DAY: Int = MINUTES_IN_ONE_HOUR * HOURS_IN_ONE_DAY
    
    /// How many minutes there are in a month, roughly.
    static let MINUTES_IN_ONE_MONTH: Int = MINUTES_IN_ONE_DAY * DAYS_IN_ONE_MONTH
    
    /// How many minutes there are in a year, roughly.
    static let MINUTES_IN_ONE_YEAR: Int = MINUTES_IN_ONE_MONTH * MONTHS_IN_ONE_YEAR
    
    /* ------------- Values used for calculating Due Date Multipliers ------------- */
    
    /// The due date multiplier that new cards are initialized with. By default, x0.10.
    static let NEW_CARD_DUE_DATE_MULTIPLIER = 0.10
    
    /// Used to set a card's due date multiplier to 20% of its original value. This is used when the user clicks "Retry".
    static let RETRY_DUE_DATE_MULTIPLIER_FACTOR = 0.20
    
    /// Used to set a card's due date multiplier to 80% of its original value. This is used when the user clicks "Hard".
    static let HARD_DUE_DATE_MULTIPLIER_FACTOR = 0.80
    
    /// Used to set a card's due date multiplier to 130% of its original value. This is used when the user clicks "Okay".
    static let OKAY_DUE_DATE_MULTIPLIER_FACTOR = 1.30
    
    /// Used to set a card's due date multiplier to 170% of its original value. This is used when the user clicks "Easy".
    static let EASY_DUE_DATE_MULTIPLIER_FACTOR = 1.70
    
    /// Used to set a card's due date multiplier to 20% of its original value. This is used when the user gets a multiple choice card wrong.
    static let INCORRECT_DUE_DATE_MULTIPLIER_FACTOR = 0.20
    
    /// Used to set a card's due date multiplier to 150% of its original value. This is used when the user gets a multiple choice card right.
    static let CORRECT_DUE_DATE_MULTIPLIER_FACTOR = 1.50
    
    /// Used to increase a card's due date multiplier by a flat 0%. This is used when clicking the user clicks "Retry".
    static let RETRY_DUE_DATE_MULTIPLIER_INCREMENT = 0.00
    
    /// Used to increase a card's due date multiplier by a flat 0%. This is used when clicking the user clicks "Hard".
    static let HARD_DUE_DATE_MULTIPLIER_INCREMENT = 0.00
    
    /// Used to increase a card's due date multiplier by a flat 30%. This is used when clicking the user clicks "Okay".
    static let OKAY_DUE_DATE_MULTIPLIER_INCREMENT = 0.30
    
    /// Used to increase a card's due date multiplier by a flat 80%. This is used when clicking the user clicks "Easy".
    static let EASY_DUE_DATE_MULTIPLIER_INCREMENT = 0.80
    
    /// Used to increase a card's due date multiplier by a flat 0%. This is used when the user gets a multiple choice card wrong.
    static let INCORRECT_DUE_DATE_MULTIPLIER_INCREMENT = 0.00
    
    /// Used to increase a card's due date multiplier by a flat 60%. This is used when the user gets a multiple choice card right.
    static let CORRECT_DUE_DATE_MULTIPLIER_INCREMENT = 0.60
    
    /// How many minutes (before applying the due date multiplier) until a card is due again after pressing "Retry".
    static let RETRY_BASE_MINUTES_UNTIL_DUE_DATE = 0.0
    
    /// How many minutes (before applying the due date multiplier) until a card is due again after pressing "Hard".
    static let HARD_BASE_MINUTES_UNTIL_DUE_DATE = 20.0
    
    /// How many minutes (before applying the due date multiplier) until a card is due again after pressing "Okay".
    static let OKAY_BASE_MINUTES_UNTIL_DUE_DATE = 100.0
    
    /// How many minutes (before applying the due date multiplier) until a card is due again after pressing "Easy".
    static let EASY_BASE_MINUTES_UNTIL_DUE_DATE = 300.0
    
    /// How many minutes (before applying the due date multiplier) until a multiple choice card is due again after getting it wrong.
    static let INCORRECT_BASE_MINUTES_UNTIL_DUE_DATE = 0.0
    
    /// How many minutes (before applying the due date multiplier) until a multiple choice card is due again after getting it right.
    static let CORRECT_BASE_MINUTES_UNTIL_DUE_DATE = 100.0
}

/* Gives all UIViewControllers access to these helper functions. */
extension UIViewController {
    /// Shows an alert with the specified `title` and `message` parameters.
    func showErrorAlert(_ title: String, _ message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        // add OK button to the error
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        self.present(alert, animated: true, completion: nil) // show the alert
    }
    
    /// Hides the on-screen keyboard when clicking anywhere on the screen that is not the keyboard.
    func dismissKeyboardOnOutsideClick() {
        let click = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        
        // Allows the user to interact with the screen even when the keyboard is active. The click will dismiss the keyboard though.
        click.cancelsTouchesInView = false
        view.addGestureRecognizer(click)
    }
    
    /// Closes the keyboard.
    @objc func dismissKeyboard() { view.endEditing(true) }
}
