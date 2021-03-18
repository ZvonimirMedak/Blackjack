//
//  ViewController.swift
//  Blackjack
//
//  Created by Zvonimir Medak on 18.03.2021..
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit

class ViewController: UIViewController {
    
    let dealerStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.alignment = .leading
        sv.distribution = .equalSpacing
        sv.spacing = 10
        return sv
    }()
    
    let playerStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.alignment = .center
        sv.distribution = .equalSpacing
        sv.spacing = 10
        return sv
    }()
    
    let hitButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .blue
        button.setTitle("HIT ME", for: .normal)
        return button
    }()
    
    let passButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .red
        button.setTitle("PASS", for: .normal)
        return button
    }()
    
    let disposeBag = DisposeBag()
    let viewModel: ViewModel
    
    public init(viewModel: ViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
        initializeVM()
        viewModel.loadDataSubject.onNext(())
    }


}

private extension ViewController {
    
    func setupUI() {
        view.addSubviews(dealerStackView, playerStackView, passButton, hitButton)
        setupConstraints()
    }
    
    func setupConstraints() {
        dealerStackView.snp.makeConstraints { (maker) in
            maker.leading.trailing.top.equalToSuperview().inset(UIEdgeInsets(top: 90, left: 15, bottom: 0, right: 15))
        }
        
        playerStackView.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview().inset(15)
            maker.top.equalTo(dealerStackView.snp.bottom).inset(-90)
        }
        
        passButton.snp.makeConstraints { (maker) in
            maker.trailing.equalToSuperview().inset(40)
            maker.bottom.equalToSuperview().inset(30)
        }
        
        hitButton.snp.makeConstraints { (maker) in
            maker.leading.equalToSuperview().inset(40)
            maker.bottom.equalToSuperview().inset(30)
        }
    }
}

private extension ViewController {
    
    func initializeVM() {
        disposeBag.insert(viewModel.initializeViewModel())
        initializeBustedSubject(for: viewModel.bustedSubject).disposed(by: disposeBag)
        initializeCardsDealtObservable(for: viewModel.dealtCardsRelay).disposed(by: disposeBag)
        initializeGameFinishedSubject(for: viewModel.gameFinishedSubject).disposed(by: disposeBag)
        
        hitButton.rx.tap
            .observe(on: MainScheduler.instance)
            .subscribe(on: ConcurrentDispatchQueueScheduler.init(qos: .background))
            .subscribe(onNext: {[unowned self] (_) in
                viewModel.userInteractionSubject.onNext(.hitMe)
            })
            .disposed(by: disposeBag)
        
        passButton.rx.tap
            .observe(on: MainScheduler.instance)
            .subscribe(on: ConcurrentDispatchQueueScheduler.init(qos: .background))
            .subscribe(onNext: { [unowned self] (_) in
                viewModel.userInteractionSubject.onNext(.pass)
                unhideDealerCards(viewModel.dealtCardsRelay.value)
            })
            .disposed(by: disposeBag)
    }
    
    func initializeGameFinishedSubject(for subject: PublishSubject<Player>) -> Disposable {
        return subject
            .subscribe(on: ConcurrentDispatchQueueScheduler.init(qos: .background))
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [unowned self] (type) in
                handleGameOverType(for: type, isBusted: false)
            })
    }
    
    func initializeBustedSubject(for subject: PublishSubject<Player>) -> Disposable {
        return subject
            .subscribe(on: ConcurrentDispatchQueueScheduler.init(qos: .background))
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [unowned self] (type) in
                handleGameOverType(for: type, isBusted: true)
            })
    }
    
    func initializeCardsDealtObservable(for subject: BehaviorRelay<[Card]>) -> Disposable {
        return subject
            .subscribe(on: ConcurrentDispatchQueueScheduler.init(qos: .background))
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: {[unowned self] (cards) in
                addNewCards(cards)
            })
    }
    
    func handleGameOverType(for type: Player, isBusted: Bool) {
        let handler = { [unowned self] (alertAction: UIAlertAction) in
            for subview in playerStackView.arrangedSubviews {
                playerStackView.removeArrangedSubview(subview)
            }
            for subview in dealerStackView.arrangedSubviews {
                dealerStackView.removeArrangedSubview(subview)
            }
            viewModel.userInteractionSubject.onNext(.reset)
        }
        switch type {
        case .player:
            if isBusted{
                showAlertController(message: "Player is busted, dealer wins", handler: handler)
            }else {
                showAlertController(message: "Player wins by points", handler: handler)
            }
            
        case .dealer:
            if isBusted{
                showAlertController(message: "Dealer is busted, player wins", handler: handler)
            }else {
                showAlertController(message: "Dealer wins by points", handler: handler)
            }
            
        case .noone:
            showAlertController(message: "It's a draw", handler: handler)
        }
    }
    
    func addNewCards(_ cards: [Card]) {
        if playerStackView.arrangedSubviews.isEmpty {
            for card in cards {
                let view = UIImageView()
                if card.isHidden {
                    view.image = UIImage(named: "red_back")
                }else {
                    view.image = card.image
                }
                view.snp.makeConstraints { (maker) in
                    maker.height.width.equalTo(40)
                }
                switch card.owner {
                case .dealer:
                    dealerStackView.addArrangedSubview(view)
                case .player:
                    playerStackView.addArrangedSubview(view)
                default:
                    print("none")
                }
            }
        }else {
            let lastCard = cards.last
            let view = UIImageView(image: lastCard?.image)
            view.snp.makeConstraints { (maker) in
                maker.height.width.equalTo(40)
            }
            guard let safeOwner = lastCard?.owner else {return}
            switch safeOwner {
            case .dealer:
                guard let safeImageView = playerStackView.arrangedSubviews.last as? UIImageView else {return}
                if lastCard?.image != safeImageView.image {
                    dealerStackView.addArrangedSubview(view)
                }
            case .player:
                guard let safeImageView = playerStackView.arrangedSubviews.last as? UIImageView else {return}
                if lastCard?.image != safeImageView.image {
                    playerStackView.addArrangedSubview(view)
                }
            case .noone:
                print("none")
            }
        }
    }
    
    func unhideDealerCards(_ cards: [Card]) {
        let dealerCards = cards.filter { (card) -> Bool in
            card.owner == .dealer
        }
        for subview in dealerStackView.arrangedSubviews {
            guard let imageView = subview as? UIImageView else {return}
            if imageView.image == UIImage(named: "red_back") {
                imageView.image = dealerCards[1].image
            }
        }
    }

}
