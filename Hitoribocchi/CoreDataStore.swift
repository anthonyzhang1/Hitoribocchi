import CoreData

protocol StoreType {
    /// Retrieves all of the decks. The results are sorted alphabetically, from A to Z.
    func getAllDecks() throws -> [Deck]
    
    /// Gets the title of the deck that a card belongs to.
    func getACardsDeckTitle(fromCard card: Card) throws -> String
    
    /// Gets the number of cards in a deck.
    func getDeckCardCount(_ deck: Deck) throws -> Int
    
    /// Inserts a deck into the store.
    func insertDeck(_ deck: Deck) throws
    
    /// Deletes a deck from the store.
    func deleteDeck(_ deck: Deck) throws
    
    /// Gets all the due cards from a deck.
    func getDueCardsFromDeck(_ deck: Deck) throws -> [Card]
    
    /**
     Gets all cards. Each Card entity will return at most `fetchLimit` cards.
     The returned array will be sorted by creation date from newest to oldest.
     */
    func getAllCards(_ fetchLimit: Int) throws -> [Card]
    
    /**
     Searches for cards that contain `searchTerms` within its prompt. Each Card entity will return at most `fetchLimit` cards.
     The returned array will be sorted by creation date from newest to oldest.
     */
    func searchCards(_ searchTerms: String, _ fetchLimit: Int) throws -> [Card]
    
    /// Inserts a basic card into a deck.
    func insertBasicCard(_ card: BasicCard, _ deck: Deck) throws
    
    /// Inserts a multiple choice card into a deck.
    func insertMultipleChoiceCard(_ card: MultipleChoiceCard, _ deck: Deck) throws
    
    /// Update the card's due date and due date multiplier in the store, according to the values in the Card object.
    func updateCardDueDate(_ card: Card) throws
    
    /// Deletes a card from the store.
    func deleteCard(_ card: Card) throws
}

struct CoreDataStore: StoreType {
    private static let container: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Hitoribocchi")
        
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error { fatalError("Device full or data model was modified without a migration.") }
        }
        
        return container
    }()
    
    func getAllDecks() throws -> [Deck] {
        let context = Self.container.viewContext
        let deckEntities = try context.fetch(DeckEntity.fetchRequest())
        
        return deckEntities.compactMap { deckEntity in
            guard let id = deckEntity.id,
                  let title = deckEntity.title
            else { fatalError("A deck entity in Core Data is corrupted.") }
            
            return Deck(id: id, title: title)
        }.sorted { $0.title < $1.title } // sort alphabetically, in ascending order
    }
    
    func getACardsDeckTitle(fromCard card: Card) throws -> String {
        let context = Self.container.viewContext
        
        if card is BasicCard { // basic card
            let fetchRequest = BasicCardEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id = %@", card.id) // find the card with the matching id
            let matchedCardEntity = try context.fetch(fetchRequest)[0]
            
            guard let deckTitle = matchedCardEntity.deck?.title
            else { return "Error!" }
            
            return deckTitle
            
        } else { // multiple choice card
            let fetchRequest = MultipleChoiceCardEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id = %@", card.id) // find the card with the matching id
            let matchedCardEntity = try context.fetch(fetchRequest)[0]
            
            guard let deckTitle = matchedCardEntity.deck?.title
            else { return "Error!" }
            
            return deckTitle
        }
    }
    
    func getDeckCardCount(_ deck: Deck) throws -> Int {
        let context = Self.container.viewContext
        
        /* Get the deck entity for the deck provided in the argument. */
        let fetchRequest = DeckEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id = %@", deck.id)
        
        guard let deckEntity = try context.fetch(fetchRequest).first
        else { return 0 } // supposedly never executed by xcode if you try to throw an error here
        
        /* Counts the number of cards in a deck and returns it. */
        if let basicCardCount = deckEntity.basicCards?.count,
           let multipleChoiceCardCount = deckEntity.multipleChoiceCards?.count
        { return basicCardCount + multipleChoiceCardCount }
        else { return 0 }
    }
    
    func insertDeck(_ deck: Deck) throws {
        let context = Self.container.viewContext
        let entity = DeckEntity(context: context)
        entity.id = deck.id
        entity.title = deck.title
        
        try context.save()
    }
    
    func deleteDeck(_ deck: Deck) throws {
        let context = Self.container.viewContext
        
        /* Find the deck in the store with the corresponding id. */
        let fetchRequest = DeckEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id = %@", deck.id)
        
        guard let entity = try context.fetch(fetchRequest).first
        else { return }
        
        context.delete(entity) // delete the deck entity
        try context.save()
    }
    
    func getDueCardsFromDeck(_ deck: Deck) throws -> [Card] {
        let context = Self.container.viewContext
        var returnArray: [Card] // stores the cards we will return
        
        // get the deck entity for the deck provided in the argument
        let fetchRequest = DeckEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id = %@", deck.id)
        
        guard let deckEntity = try context.fetch(fetchRequest).first
        else { return [] }
        
        // get all the card entities that belong to the deck
        guard let basicCardEntities = deckEntity.basicCards?.allObjects as? [BasicCardEntity],
              let multipleChoiceCardEntities = deckEntity.multipleChoiceCards?.allObjects as? [MultipleChoiceCardEntity]
        else { return [] } // fatalError is supposedly never executed by xcode here
        
        // map the due basic cards into the return array
        returnArray = basicCardEntities.compactMap { basicCardEntity in
            guard let id = basicCardEntity.id,
                  let prompt = basicCardEntity.prompt,
                  let solution = basicCardEntity.solution,
                  let creationDate = basicCardEntity.creationDate,
                  let dueDate = basicCardEntity.dueDate
            else { fatalError("A basic card entity in Core Data is corrupted.") }
            
            // do not get cards not yet due
            if .now < dueDate { return nil }
            
            return BasicCard(id: id, prompt: prompt, solution: solution, creationDate: creationDate, dueDate: dueDate, nextDueDateMultiplier: basicCardEntity.nextDueDateMultiplier)
        }
        
        // append to the return array the multiple choice cards
        returnArray += multipleChoiceCardEntities.compactMap { multipleChoiceCardEntity in
            guard let id = multipleChoiceCardEntity.id,
                  let prompt = multipleChoiceCardEntity.prompt,
                  let solution = multipleChoiceCardEntity.solution,
                  let creationDate = multipleChoiceCardEntity.creationDate,
                  let dueDate = multipleChoiceCardEntity.dueDate,
                  let options = multipleChoiceCardEntity.options
            else { fatalError("A multiple choice card entity in Core Data is corrupted.") }
            
            // do not get cards not yet due
            if .now < dueDate { return nil }
            
            return MultipleChoiceCard(id: id, prompt: prompt, solution: solution, creationDate: creationDate, dueDate: dueDate, nextDueDateMultiplier: multipleChoiceCardEntity.nextDueDateMultiplier, options: options)
        }
        
        return returnArray
    }
    
    func getAllCards(_ fetchLimit: Int) throws -> [Card] {
        let context = Self.container.viewContext
        var returnArray: [Card] // stores the cards we will return
        
        // fetch the basic cards first
        let basicCardFetchRequest = BasicCardEntity.fetchRequest()
        basicCardFetchRequest.fetchLimit = fetchLimit
        let basicCardEntities = try context.fetch(basicCardFetchRequest)
        
        // map the searched basic cards into the return array
        returnArray = basicCardEntities.compactMap { basicCardEntity in
            guard let id = basicCardEntity.id,
                  let prompt = basicCardEntity.prompt,
                  let solution = basicCardEntity.solution,
                  let creationDate = basicCardEntity.creationDate,
                  let dueDate = basicCardEntity.dueDate
            else { fatalError("A basic card entity in Core Data is corrupted.") }
            
            return BasicCard(id: id, prompt: prompt, solution: solution, creationDate: creationDate, dueDate: dueDate, nextDueDateMultiplier: basicCardEntity.nextDueDateMultiplier)
        }
        
        // fetch the multiple choice cards
        let multipleChoiceCardFetchRequest = MultipleChoiceCardEntity.fetchRequest()
        multipleChoiceCardFetchRequest.fetchLimit = fetchLimit
        let multipleChoiceCardEntities = try context.fetch(multipleChoiceCardFetchRequest)
        
        // append to the return array the searched multiple choice cards
        returnArray += multipleChoiceCardEntities.compactMap { multipleChoiceCardEntity in
            guard let id = multipleChoiceCardEntity.id,
                  let prompt = multipleChoiceCardEntity.prompt,
                  let solution = multipleChoiceCardEntity.solution,
                  let creationDate = multipleChoiceCardEntity.creationDate,
                  let dueDate = multipleChoiceCardEntity.dueDate,
                  let options = multipleChoiceCardEntity.options
            else { fatalError("A multiple choice card entity in Core Data is corrupted.") }
            
            return MultipleChoiceCard(id: id, prompt: prompt, solution: solution, creationDate: creationDate, dueDate: dueDate, nextDueDateMultiplier: multipleChoiceCardEntity.nextDueDateMultiplier, options: options)
        }
        
        // Sorts the array by creation date, newest first, oldest last, then returns it
        return returnArray.sorted { $0.creationDate > $1.creationDate }
    }
    
    func searchCards(_ searchTerms: String, _ fetchLimit: Int) throws -> [Card] {
        let context = Self.container.viewContext
        var returnArray: [Card] // stores the cards we will return
        
        /// The search algorithm. We match all cards with a prompt that contains the search terms, ignoring case and diacritics.
        let fetchPredicate = NSPredicate(format: "prompt CONTAINS[cd] %@", searchTerms)
        
        // fetch the basic cards first
        let basicCardFetchRequest = BasicCardEntity.fetchRequest()
        basicCardFetchRequest.predicate = fetchPredicate
        basicCardFetchRequest.fetchLimit = fetchLimit
        let basicCardEntities = try context.fetch(basicCardFetchRequest)
        
        // map the searched basic cards into the return array
        returnArray = basicCardEntities.compactMap { basicCardEntity in
            guard let id = basicCardEntity.id,
                  let prompt = basicCardEntity.prompt,
                  let solution = basicCardEntity.solution,
                  let creationDate = basicCardEntity.creationDate,
                  let dueDate = basicCardEntity.dueDate
            else { fatalError("A basic card entity in Core Data is corrupted.") }
            
            return BasicCard(id: id, prompt: prompt, solution: solution, creationDate: creationDate, dueDate: dueDate, nextDueDateMultiplier: basicCardEntity.nextDueDateMultiplier)
        }
        
        // fetch the multiple choice cards
        let multipleChoiceCardFetchRequest = MultipleChoiceCardEntity.fetchRequest()
        multipleChoiceCardFetchRequest.predicate = fetchPredicate
        multipleChoiceCardFetchRequest.fetchLimit = fetchLimit
        let multipleChoiceCardEntities = try context.fetch(multipleChoiceCardFetchRequest)
        
        // append to the return array the searched multiple choice cards
        returnArray += multipleChoiceCardEntities.compactMap { multipleChoiceCardEntity in
            guard let id = multipleChoiceCardEntity.id,
                  let prompt = multipleChoiceCardEntity.prompt,
                  let solution = multipleChoiceCardEntity.solution,
                  let creationDate = multipleChoiceCardEntity.creationDate,
                  let dueDate = multipleChoiceCardEntity.dueDate,
                  let options = multipleChoiceCardEntity.options
            else { fatalError("A multiple choice card entity in Core Data is corrupted.") }
            
            return MultipleChoiceCard(id: id, prompt: prompt, solution: solution, creationDate: creationDate, dueDate: dueDate, nextDueDateMultiplier: multipleChoiceCardEntity.nextDueDateMultiplier, options: options)
        }
        
        // Sorts the array by creation date, newest first, oldest last, then returns it
        return returnArray.sorted { $0.creationDate > $1.creationDate }
    }
    
    
    func insertBasicCard(_ card: BasicCard, _ deck: Deck) throws {
        let context = Self.container.viewContext
        
        // get the deck entity that this card belongs to
        let fetchRequest = DeckEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id = %@", deck.id)
        
        guard let deckEntity = try context.fetch(fetchRequest).first
        else { return }
        
        let cardEntity = BasicCardEntity(context: context)
        cardEntity.id = card.id
        cardEntity.prompt = card.prompt
        cardEntity.solution = card.solution
        cardEntity.creationDate = card.creationDate
        cardEntity.dueDate = card.dueDate
        cardEntity.nextDueDateMultiplier = card.nextDueDateMultiplier
        cardEntity.deck = deckEntity // relationship attribute
        
        try context.save()
    }
    
    func insertMultipleChoiceCard(_ card: MultipleChoiceCard, _ deck: Deck) throws {
        let context = Self.container.viewContext
        
        // get the deck entity that this card belongs to
        let fetchRequest = DeckEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id = %@", deck.id)
        
        guard let deckEntity = try context.fetch(fetchRequest).first
        else { return }
        
        let cardEntity = MultipleChoiceCardEntity(context: context)
        cardEntity.id = card.id
        cardEntity.prompt = card.prompt
        cardEntity.solution = card.solution
        cardEntity.creationDate = card.creationDate
        cardEntity.dueDate = card.dueDate
        cardEntity.nextDueDateMultiplier = card.nextDueDateMultiplier
        cardEntity.options = card.options
        cardEntity.deck = deckEntity // relationship attribute
        
        try context.save()
    }
    
    func updateCardDueDate(_ card: Card) throws {
        let context = Self.container.viewContext
        
        if card is BasicCard { // basic card
            let fetchRequest = BasicCardEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id = %@", card.id) // find the card with the matching id
            
            guard let cardEntity = try context.fetch(fetchRequest).first
            else { return }
            
            cardEntity.dueDate = card.dueDate
            cardEntity.nextDueDateMultiplier = card.nextDueDateMultiplier
        }
        else if card is MultipleChoiceCard { // multiple choice card
            let fetchRequest = MultipleChoiceCardEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id = %@", card.id) // find the card with the matching id
            
            guard let cardEntity = try context.fetch(fetchRequest).first
            else { return }
            
            cardEntity.dueDate = card.dueDate
            cardEntity.nextDueDateMultiplier = card.nextDueDateMultiplier
        }
        
        try context.save()
    }
    
    func deleteCard(_ card: Card) throws {
        let context = Self.container.viewContext
        
        if card is BasicCard { // basic card
            let fetchRequest = BasicCardEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id = %@", card.id) // find the card with the matching id
            
            guard let entity = try context.fetch(fetchRequest).first
            else { return }
            
            context.delete(entity) // delete the matched entity
        }
        else { // multiple choice card
            let fetchRequest = MultipleChoiceCardEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id = %@", card.id) // find the card with the matching id
            
            guard let entity = try context.fetch(fetchRequest).first
            else { return }
            
            context.delete(entity) // delete the matched entity
        }
        
        try context.save()
    }
}
