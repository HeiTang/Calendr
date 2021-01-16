//
//  CalendarCellView.swift
//  Calendr
//
//  Created by Paker on 24/12/20.
//

import Cocoa
import RxSwift
import RxCocoa

class CalendarCellView: NSView {

    private let disposeBag = DisposeBag()

    private let viewModel: Observable<CalendarCellViewModel>
    private let hoverObserver: AnyObserver<Date?>
    private let clickObserver: AnyObserver<Date>

    private let contentStackView = NSStackView(.vertical)
    private let eventsStackView = NSStackView(.horizontal)
    private let label = Label()

    init(
        viewModel: Observable<CalendarCellViewModel>,
        hoverObserver: AnyObserver<Date?>,
        clickObserver: AnyObserver<Date>
    ) {

        self.viewModel = viewModel
        self.hoverObserver = hoverObserver
        self.clickObserver = clickObserver

        super.init(frame: .zero)

        configureLayout()

        setUpBindings()
    }

    private func configureLayout() {

        forAutoLayout()

        wantsLayer = true
        layer!.borderWidth = 2
        layer!.cornerRadius = 5

        label.alignment = .center
        label.font = .systemFont(ofSize: 12)
        label.size(equalTo: CGSize(width: 24, height: 13))

        eventsStackView.spacing = 2
        eventsStackView.height(equalTo: Constants.eventDotSize)

        let eventsContainer = NSView()
        eventsContainer.addSubview(eventsStackView)
        eventsStackView
            .top(equalTo: eventsContainer)
            .bottom(equalTo: eventsContainer)
            .center(in: eventsContainer, orientation: .horizontal)

        contentStackView.spacing = 2
        contentStackView.addArrangedSubviews(label, eventsContainer)

        addSubview(contentStackView)

        contentStackView.center(in: self)
    }

    private func setUpBindings() {

        viewModel
            .map(\.text)
            .bind(to: label.rx.text)
            .disposed(by: disposeBag)

        viewModel
            .map(\.alpha)
            .bind(to: label.rx.alpha)
            .disposed(by: disposeBag)

        viewModel
            .map(\.borderColor)
            .bind(to: layer!.rx.borderColor)
            .disposed(by: disposeBag)

        viewModel
            .map(\.dots)
            .map { $0.map(Self.makeEventDot) }
            .bind(to: eventsStackView.rx.arrangedSubviews)
            .disposed(by: disposeBag)

        rx.sentMessage(#selector(NSView.mouseUp))
            .withLatestFrom(viewModel.map(\.date))
            .bind(to: clickObserver)
            .disposed(by: disposeBag)

        Observable.merge(
            rx.sentMessage(#selector(NSView.mouseEntered))
                .withLatestFrom(viewModel.map(\.date)).toOptional(),
            rx.sentMessage(#selector(NSView.mouseExited))
                .toVoid().map { nil }
        )
        .bind(to: hoverObserver)
        .disposed(by: disposeBag)
    }

    override func updateTrackingAreas() {
        trackingAreas.forEach(removeTrackingArea(_:))
        addTrackingRect(bounds, owner: self, userData: nil, assumeInside: false)
    }

    private static func makeEventDot(color: CGColor) -> NSView {
        let view = NSView()
        view.size(equalTo: Constants.eventDotSize)
        view.wantsLayer = true
        view.layer.map { layer in
            layer.backgroundColor = color
            layer.cornerRadius = Constants.eventDotSize / 2
        }
        return view
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private enum Constants {

    static let eventDotSize: CGFloat = 3
}
