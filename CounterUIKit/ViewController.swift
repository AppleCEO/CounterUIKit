//
//  ViewController.swift
//  CounterUIKit
//
//  Created by joon-ho kil on 2022/11/15.
//

import UIKit
import ComposableArchitecture
import Combine

class ViewController: UIViewController {
    
    let viewStore: ViewStoreOf<Feature>
    var cancellables: Set<AnyCancellable> = []
    
    init(store: StoreOf<Feature>) {
        self.viewStore = ViewStore(store)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let countLabel = UILabel()
        countLabel.textColor = .white
        let incrementButton = UIButton()
        incrementButton.setTitle("+", for: .normal)
        incrementButton.setTitleColor(.white, for: .normal)
        let decrementButton = UIButton()
        decrementButton.setTitle("-", for: .normal)
        decrementButton.setTitleColor(.white, for: .normal)
        let factButton = UIButton()
        factButton.setTitle("fact", for: .normal)
        factButton.setTitleColor(.white, for: .normal)
        
        // Omitted: Add subviews and set up constraints...
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        incrementButton.translatesAutoresizingMaskIntoConstraints = false
        decrementButton.translatesAutoresizingMaskIntoConstraints = false
        factButton.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(countLabel)
        self.view.addSubview(incrementButton)
        self.view.addSubview(decrementButton)
        self.view.addSubview(factButton)
        
        let countLabelConstraints = [self.view.centerXAnchor.constraint(equalTo: countLabel.centerXAnchor),
                                     self.view.centerYAnchor.constraint(equalTo: countLabel.centerYAnchor)]
        NSLayoutConstraint.activate(countLabelConstraints)
        
        let incrementButtonConstraints = [countLabel.trailingAnchor.constraint(equalTo: incrementButton.leadingAnchor),
                                     countLabel.centerYAnchor.constraint(equalTo: incrementButton.centerYAnchor)]
        NSLayoutConstraint.activate(incrementButtonConstraints)
        
        let decrementButtonConstraints = [countLabel.leadingAnchor.constraint(equalTo: decrementButton.trailingAnchor),
                                     countLabel.centerYAnchor.constraint(equalTo: decrementButton.centerYAnchor)]
        NSLayoutConstraint.activate(decrementButtonConstraints)
        
        let factButtonConstraints = [countLabel.bottomAnchor.constraint(equalTo: factButton.topAnchor),
                                     countLabel.centerXAnchor.constraint(equalTo: factButton.centerXAnchor)]
        NSLayoutConstraint.activate(factButtonConstraints)
        
        incrementButton.addTarget(self, action: #selector(self.incrementButtonTapped), for: .touchUpInside)
        decrementButton.addTarget(self, action: #selector(self.decrementButtonTapped), for: .touchUpInside)
        factButton.addTarget(self, action: #selector(self.factButtonTapped), for: .touchUpInside)
        
        self.viewStore.publisher
            .map { "\($0.count)" }
            .assign(to: \.text, on: countLabel)
            .store(in: &self.cancellables)
        
        self.viewStore.publisher.numberFactAlert
            .sink { [weak self] numberFactAlert in
                let alertController = UIAlertController(
                    title: numberFactAlert, message: nil, preferredStyle: .alert
                )
                alertController.addAction(
                    UIAlertAction(
                        title: "Ok",
                        style: .default,
                        handler: { _ in self?.viewStore.send(.factAlertDismissed) }
                    )
                )
                self?.present(alertController, animated: true, completion: nil)
            }
            .store(in: &self.cancellables)
    }
    
    @objc private func incrementButtonTapped() {
        self.viewStore.send(.incrementButtonTapped)
    }
    @objc private func decrementButtonTapped() {
        self.viewStore.send(.decrementButtonTapped)
    }
    @objc private func factButtonTapped() {
        self.viewStore.send(.numberFactButtonTapped)
    }
    
}

struct Feature: ReducerProtocol {
    struct State: Equatable {
        var count = 0
        var numberFactAlert: String?
    }
    
    enum Action: Equatable {
        case factAlertDismissed
        case decrementButtonTapped
        case incrementButtonTapped
        case numberFactButtonTapped
        case numberFactResponse(TaskResult<String>)
    }
    
    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .factAlertDismissed:
            state.numberFactAlert = nil
            return .none
            
        case .decrementButtonTapped:
            state.count -= 1
            return .none
            
        case .incrementButtonTapped:
            state.count += 1
            return .none
            
        case .numberFactButtonTapped:
            return .task { [count = state.count] in
              await .numberFactResponse(
                TaskResult {
                  String(
                    decoding: try await URLSession.shared
                      .data(from: URL(string: "http://numbersapi.com/\(count)/trivia")!).0,
                    as: UTF8.self
                  )
                }
              )
            }
            
        case let .numberFactResponse(.success(fact)):
            state.numberFactAlert = fact
            return .none
            
        case .numberFactResponse(.failure):
            state.numberFactAlert = "Could not load a number fact :("
            return .none
        }
    }
}
