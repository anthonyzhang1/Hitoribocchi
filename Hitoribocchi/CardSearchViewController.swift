import UIKit

class CardSearchViewController: UIViewController {    
    let store = CoreDataStore()
    var cards: [Card] = [] // the cards to display
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var cardTableView: UITableView!
    
    /// Sends the clicked on Card to the Card Details view.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let cardDetailsViewController = segue.destination as? CardDetailsViewController,
           let cardIndex = cardTableView.indexPathForSelectedRow?.row
        { cardDetailsViewController.currentCard = cards[cardIndex] }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dismissKeyboardOnOutsideClick()
        
        searchBar.delegate = self
        cardTableView.delegate = self
        cardTableView.dataSource = self
        
        searchBarSearchButtonClicked(searchBar) // show all the recently created cards on view load
    }
    
    /// Update the table results in case the user deleted anything since last visiting the page.
    override func viewDidAppear(_ animated: Bool) { searchBarSearchButtonClicked(searchBar) }
}

extension CardSearchViewController: UISearchBarDelegate {
    /// Executes the search when the user presses Return. Gets the matched cards from the store and updates the table with the cards.
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchTerms = searchBar.text
        else { return }
        
        do {
            // If search terms were provided, execute the search.
            // If no search terms were provided, retrieve all recently created cards.
            if (searchTerms.count > 0) { cards = try store.searchCards(searchTerms, Constants.SEARCH_FETCH_LIMIT) }
            else { cards = try store.getAllCards(Constants.SEARCH_FETCH_LIMIT) }
            
            DispatchQueue.main.async { self.cardTableView.reloadData() }
        } catch {
            showErrorAlert("Error", "Sorry, there was an error retrieving the cards.")
        }
    }
}

extension CardSearchViewController: UITableViewDelegate, UITableViewDataSource {
    /// Returns the number of cards in the cards array.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return cards.count }
    
    /// Loads the table cell's contents.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = cards[indexPath.row].prompt
        cell.textLabel?.numberOfLines = 0;
        cell.textLabel?.lineBreakMode = .byWordWrapping;
        
        return cell
    }
    
    /// Called when selecting a table cell. Takes the user to the Card Details view.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "searchToCardDetailsSegue", sender: indexPath)
        
        // deselect the row after we transition to the new screen
        cardTableView.deselectRow(at: indexPath, animated: true)
    }
    
    /// Called when swiping on a table cell. Allows the user to delete the card.
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            do { // try to delete the card
                try store.deleteCard(cards[indexPath.row])
                searchBarSearchButtonClicked(searchBar) // update the table so that the deleted card disappears
            } catch {
                showErrorAlert("Error", "Sorry, there was an error deleting the card.")
            }
        }
    }
}
