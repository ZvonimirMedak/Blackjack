//
//  AppDelegate.swift
//  Blackjack
//
//  Created by Zvonimir Medak on 18.03.2021..
//

import UIKit
import RxSwift
import RxCocoa

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        window = UIWindow(frame: UIScreen.main.bounds)
        guard let window = window else {return false}
        let initialViewController = UINavigationController(rootViewController: ViewController(viewModel: ViewModel(userInteractionSubject: PublishSubject(), dealtCardsRelay: BehaviorRelay.init(value: []), bustedSubject: PublishSubject(), cards: CardDataSource().createCards(), loadDataSubject: ReplaySubject.create(bufferSize: 1), gameFinishedSubject: PublishSubject())))
        initialViewController.isNavigationBarHidden = true
        window.rootViewController = initialViewController
        window.makeKeyAndVisible()
        return true
    }



}

