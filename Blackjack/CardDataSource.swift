//
//  CardDataSource.swift
//  Blackjack
//
//  Created by Zvonimir Medak on 18.03.2021..
//

import Foundation
import UIKit

public class CardDataSource {
    
    func createCards() -> [Card] {
        var cards: [Card] = []
        for i in 1...13 {
            var imageName: String
            var cardValue: Int
            switch i {
            case 1:
                imageName = "ace_"
                cardValue = 11
            case 2:
                imageName = "two_"
                cardValue = 2
            case 3:
                imageName = "three_"
                cardValue = 3
            case 4:
                imageName = "four_"
                cardValue = 4
            case 5:
                imageName = "five_"
                cardValue = 5
            case 6:
                imageName = "six_"
                cardValue = 6
            case 7:
                imageName = "seven_"
                cardValue = 7
            case 8:
                imageName = "eight_"
                cardValue = 8
            case 9:
                imageName = "nine_"
                cardValue = 9
            case 10:
                imageName = "ten_"
                cardValue = 10
            case 11:
                imageName = "jack_"
                cardValue = 10
            case 12:
                imageName = "queen_"
                cardValue = 10
            default:
                imageName = "king_"
                cardValue = 10
            }
            for j in 1...4 {
                switch j{
                case 1:
                    imageName.append("c")
                case 2:
                    imageName.removeLast()
                    imageName.append("d")
                case 3:
                    imageName.removeLast()
                    imageName.append("h")
                default:
                    imageName.removeLast()
                    imageName.append("s")
                }
                cards.append(Card(isHidden: false, image: UIImage(named: imageName)!, value: cardValue))
            }
        }
        return cards
    }
}
