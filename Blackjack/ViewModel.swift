//
//  ViewModel.swift
//  Blackjack
//
//  Created by Zvonimir Medak on 18.03.2021..
//

import Foundation
import RxSwift
import RxCocoa

enum UserInteraction {
    case hitMe
    case pass
    case reset
}
enum Player {
    case dealer
    case player
    case noone
}
class Card: Equatable {
    var isHidden: Bool
    let image: UIImage
    var value: Int
    var owner: Player?
    
    public init (isHidden: Bool, image: UIImage, value: Int, owner: Player? = nil) {
        self.isHidden = isHidden
        self.image = image
        self.value = value
        self.owner = owner
    }
    
    static func == (lhs: Card, rhs: Card) -> Bool {
        lhs.value == rhs.value && lhs.image == rhs.image && lhs.owner == rhs.owner && rhs.isHidden == lhs.isHidden
    }
}

class ViewModel {
    
    public let userInteractionSubject: PublishSubject<UserInteraction>
    public let dealtCardsRelay: BehaviorRelay<[Card]>
    public let bustedSubject: PublishSubject<Player>
    public let loadDataSubject: ReplaySubject<()>
    public let gameFinishedSubject: PublishSubject<Player>
    private var cards: [Card]
    
    public init(userInteractionSubject: PublishSubject<UserInteraction>, dealtCardsRelay: BehaviorRelay<[Card]>, bustedSubject: PublishSubject<Player>, cards: [Card], loadDataSubject: ReplaySubject<()>, gameFinishedSubject: PublishSubject<Player>) {
        self.userInteractionSubject = userInteractionSubject
        self.dealtCardsRelay = dealtCardsRelay
        self.bustedSubject = bustedSubject
        self.cards = cards
        self.loadDataSubject = loadDataSubject
        self.gameFinishedSubject = gameFinishedSubject
    }
    
    public func initializeViewModel() -> [Disposable] {
        var disposables: [Disposable] = []
        disposables.append(initializeUserInteractionSubject(for: userInteractionSubject))
        disposables.append(initializeLoadDataObservable(for: loadDataSubject))
        return disposables
    }
}


private extension ViewModel {
    
    func initializeUserInteractionSubject(for subject: PublishSubject<UserInteraction>) -> Disposable {
        return subject
            .observe(on: MainScheduler.instance)
            .subscribe(on: ConcurrentDispatchQueueScheduler.init(qos: .background))
            .subscribe(onNext: { [unowned self] (type) in
                handleUserInteractionType(for: type, remainingCards: cards)
            })
    }
    
    func handleUserInteractionType(for type: UserInteraction, remainingCards: [Card]) {
        switch type {
        case .hitMe:
            drawCard(remainingCards, owner: .player)
        case .pass:
            dealtCardsRelay.accept(unhideCards(cards: dealtCardsRelay.value))
            while checkDealerShouldPlay(dealtCardsRelay.value) {
                drawCard(remainingCards, owner: .dealer)
            }
            checkWhoWon(dealtCardsRelay.value)
            
        case .reset:
            cards = CardDataSource().createCards()
            loadDataSubject.onNext(())
        }
    }
    
    func drawCard(_ remainingCards: [Card], owner: Player) {
        let randomCardIndex = Int.random(in: 0...remainingCards.count - 1)
        let selectedCard = remainingCards[randomCardIndex]
        selectedCard.owner = owner
        var currentValue = dealtCardsRelay.value
        currentValue.append(selectedCard)
        cards.remove(at: randomCardIndex)
        dealtCardsRelay.accept(currentValue)
        checkIfTheGameIsOver(currentValue, for: owner)
    }
    
    func checkWhoWon(_ cards: [Card]) {
        var dealerValue = 0
        var playerValue = 0
        for card in cards {
            guard let safeOwner = card.owner else {return}
            switch safeOwner {
            case .dealer:
                dealerValue += card.value
            default:
                playerValue += card.value
            }
        }
        if dealerValue > playerValue {
            gameFinishedSubject.onNext(.dealer)
        }else if dealerValue == playerValue {
            gameFinishedSubject.onNext(.noone)
        }
        else {
            gameFinishedSubject.onNext(.player)
        }
    }
    
    func unhideCards(cards: [Card]) -> [Card] {
        let currentCards = cards
        for card in currentCards {
            if card.isHidden {
                card.isHidden = false
            }
        }
        return currentCards
    }
    
    func checkDealerShouldPlay(_ cards: [Card]) -> Bool {
        let dealerCards = cards.filter { (card) -> Bool in
            card.owner == .dealer
        }
        var cardValue = 0
        for card in dealerCards {
            cardValue += card.value
        }
        if cardValue > 16 {
            return false
        }
        return true
    }
    
    func checkIfTheGameIsOver(_ cards: [Card], for owner: Player) {
        let dealtCards = cards.filter { (card) -> Bool in
            card.owner == owner
        }
        var cardSum: Int = 0
        for card in dealtCards {
            cardSum += card.value
        }
        
        if cardSum > 21 {
            if dealtCards.contains(where: { (card) -> Bool in
                card.value == 11
            }) {
                let ace = dealtCards.filter { (card) -> Bool in
                    card.value == 11
                }
                ace.first?.value = 1
            }else{
                bustedSubject.onNext(owner)
            }
        }
    }
}

private extension ViewModel {
    
    func initializeLoadDataObservable(for subject: ReplaySubject<()>) -> Disposable {
        return subject
            .observe(on: MainScheduler.instance)
            .subscribe(on: ConcurrentDispatchQueueScheduler.init(qos: .background))
            .map{ [unowned self] (_) -> [Card] in
                return createDealtCards(cards: cards)
            }
            .subscribe(onNext: {[unowned self] (cards) in
                dealtCardsRelay.accept(cards)
            })
    }
    
    func createDealtCards(cards: [Card]) -> [Card] {
        var cards = cards
        let randomValues = generateDifferentRandomNumbers(numberOfCards: cards.count)
        let dealtCards: [Card] = [
            Card(isHidden: false, image: cards[randomValues[0]].image, value: cards[randomValues[0]].value, owner: .dealer),
            Card(isHidden: true, image: cards[randomValues[1]].image, value: cards[randomValues[1]].value, owner: .dealer),
            Card(isHidden: false, image: cards[randomValues[2]].image, value: cards[randomValues[2]].value, owner: .player),
            Card(isHidden: false, image: cards[randomValues[3]].image, value: cards[randomValues[3]].value, owner: .player)
        ]
        for dealtCard in dealtCards {
            cards.removeAll { (card) -> Bool in
                card == dealtCard
            }
        }
        self.cards = cards
        return dealtCards
    }
    
    func generateDifferentRandomNumbers(numberOfCards: Int) -> [Int] {
        var numbers: [Int] = []
        while numbers.count != 4 {
            let randomNumber = Int.random(in: 0...numberOfCards - 1)
            if !numbers.contains(randomNumber) {
                numbers.append(randomNumber)
            }
        }
        return numbers
    }
}
