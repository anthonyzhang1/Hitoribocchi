import UIKit

class DeckViewController: UIViewController {
    let store = CoreDataStore()
    
    @IBOutlet weak var deckTableView: UITableView!
    var decks: [Deck] = [] // will be displayed in the table
    
    /**
     Gets the decks from the CoreData store and fill the `decks` array with the retrieved decks.
     Updates the table with the decks in case any were added since displaying the view.
     */
    func getDecksFromStore() {
        do {
            decks = try store.getAllDecks()
            DispatchQueue.main.async { self.deckTableView.reloadData() }
        } catch {
            showErrorAlert("Error", "Sorry, there was an error retrieving the decks.")
        }
    }
    
    /// Show the add deck alert prompt when the add deck button is pressed.
    @IBAction func showAddDeckAlert(_ sender: Any) {
        let alert = UIAlertController(title: "Add New Deck", message: nil, preferredStyle: .alert)
        
        // Add the add deck button to the alert box
        alert.addAction(UIAlertAction(title: "Add", style: .default) { _ in
            guard let title = alert.textFields?.first?.text
            else { return }
            
            // autogenerate the id with UUID and take the title from the user's input
            let deck = Deck(id: UUID().uuidString, title: title)
            
            do { // Try to add the deck to the Core Data store. Refresh the table on success.
                try self.store.insertDeck(deck)
                self.getDecksFromStore()
            } catch {
                self.showErrorAlert("Error", "Sorry, there was an error adding the deck.")
            }
        })
        
        // Add the cancel button to the alert box
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        // Add the textfield asking for the deck's title to the alert box
        alert.addTextField { textField in textField.placeholder = "Deck Title" }
        
        present(alert, animated: true, completion: nil) // show the alert
    }
    
    /// Gets the decks to display them in the table.
    override func viewDidLoad() {
        super.viewDidLoad()
        deckTableView.delegate = self
        deckTableView.dataSource = self
        
        getDecksFromStore()
    }
    
    /// Sends the clicked on Deck to the Cards view.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let cardsViewController = segue.destination as? CardsViewController,
           let deckIndex = deckTableView.indexPathForSelectedRow?.row
        { cardsViewController.deck = decks[deckIndex] }
    }
}

extension DeckViewController: UITableViewDelegate, UITableViewDataSource {
    /// Returns the number of rows in the deck table.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return decks.count }
    
    /// Loads the table cell's contents.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = decks[indexPath.row].title
        cell.textLabel?.numberOfLines = 0;
        cell.textLabel?.lineBreakMode = .byWordWrapping;
        
        return cell
    }
    
    /// Called when selecting a table cell. Takes the user to the Cards view.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "cardSegue", sender: indexPath)
        
        // deselect the row after we transition to the new screen
        deckTableView.deselectRow(at: indexPath, animated: true)
    }
    
    /// Called when swiping on a table cell. Allows the user to delete decks.
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            do { // Try to delete the deck from the Core Data store. Refresh the table on success.
                try store.deleteDeck(decks[indexPath.row])
                getDecksFromStore()
            } catch {
                showErrorAlert("Error", "Sorry, there was an error deleting the deck.")
            }
        }
    }
}
