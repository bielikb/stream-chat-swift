//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A view controller that renders all the reactions of a message.
open class ChatMessageReactionAuthorsVC:
    _ViewController,
    ThemeProvider,
    ChatMessageControllerDelegate,
    UICollectionViewDataSource,
    UICollectionViewDelegate,
    UICollectionViewDelegateFlowLayout {
    /// The message controller of message that the reactions belong.
    open var messageController: ChatMessageController!

    /// Label that shows how many reactions the message has.
    open lazy var topLabel: UILabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withBidirectionalLanguagesSupport
        .withAdjustingFontForContentSizeCategory

    /// `UICollectionViewFlowLayout` instance for the collection view.
    open lazy var flowLayout: UICollectionViewFlowLayout = ChatMessageReactionAuthorsFlowLayout()

    /// `UICollectionView` instance to display the reaction authors.
    open lazy var collectionView: UICollectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: flowLayout
    ).withoutAutoresizingMaskConstraints

    /// The width and height of each reaction author cell.
    open var reactionAuthorCellSize: CGSize {
        CGSize(width: 64, height: 110)
    }

    /// By default it is 10. It will prefetch the reactions before showing the last 10th reaction.
    open var prefetchThreshold: Int {
        10
    }

    /// A Boolean indicating whether the reactions are currently loading.
    public var isLoadingReactions: Bool = false

    override open func setUp() {
        super.setUp()

        collectionView.register(
            components.reactionAuthorsCell.self,
            forCellWithReuseIdentifier: components.reactionAuthorsCell.reuseId
        )

        collectionView.collectionViewLayout = flowLayout
        collectionView.contentInsetAdjustmentBehavior = .always
        collectionView.delegate = self
        collectionView.dataSource = self

        collectionView.isPagingEnabled = true
        collectionView.alwaysBounceVertical = false
        collectionView.alwaysBounceHorizontal = false

        messageController.delegate = self
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        view.layer.cornerRadius = 16
        view.layer.masksToBounds = true
        view.backgroundColor = appearance.colorPalette.background

        flowLayout.scrollDirection = .vertical
        flowLayout.sectionInset = .init(top: 0, left: 8, bottom: 0, right: 8)
        flowLayout.minimumLineSpacing = 20
        flowLayout.minimumInteritemSpacing = 16

        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false

        topLabel.font = appearance.fonts.title3
        topLabel.textColor = appearance.colorPalette.text
        topLabel.textAlignment = .center
    }

    override open func setUpLayout() {
        super.setUpLayout()

        view.addSubview(topLabel)
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            topLabel.topAnchor.pin(equalTo: view.topAnchor, constant: 16),
            topLabel.leadingAnchor.pin(equalTo: view.leadingAnchor),
            topLabel.trailingAnchor.pin(equalTo: view.trailingAnchor),
            collectionView.leadingAnchor.pin(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.pin(equalTo: view.trailingAnchor),
            collectionView.topAnchor.pin(equalTo: topLabel.bottomAnchor, constant: 24),
            collectionView.bottomAnchor.pin(equalTo: view.bottomAnchor, constant: 0)
        ])
    }

    override open func updateContent() {
        super.updateContent()

        let numberOfReactions = messageController.message?.totalReactionsCount ?? 0
        topLabel.text = L10n.Reaction.Authors.numberOfReactions(numberOfReactions)
    }

    // MARK: - Collection View Data Source & Delegate

    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        messageController.reactions.count
    }

    override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionView.collectionViewLayout.invalidateLayout()
        super.viewWillTransition(to: size, with: coordinator)
    }

    open func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: components.reactionAuthorsCell.reuseId,
            for: indexPath
        ) as! ChatMessageReactionAuthorViewCell

        let reactions = messageController.reactions
        if let currentUserId = messageController?.client.currentUserId {
            cell.content = ChatMessageReactionAuthorViewCell.Content(
                reaction: reactions[indexPath.item],
                currentUserId: currentUserId
            )
        }

        return cell
    }

    open func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        prefetchNextReactions(currentIndexPath: indexPath)
    }

    open func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        reactionAuthorCellSize
    }

    // MARK: - ChatMessageControllerDelegate

    open func messageController(
        _ controller: ChatMessageController, didChangeReactions changes: [ListChange<ChatMessageReaction>]
    ) {
        collectionView.reloadData()
    }

    // MARK: - Public API

    open func prefetchNextReactions(currentIndexPath indexPath: IndexPath) {
        if isLoadingReactions {
            return
        }

        if indexPath.row > messageController.reactions.count - prefetchThreshold {
            return
        }

        let totalReactionsCount = messageController.message?.totalReactionsCount ?? 0
        if totalReactionsCount == messageController.reactions.count {
            return
        }

        isLoadingReactions = true
        messageController.loadNextReactions { [weak self] _ in
            self?.isLoadingReactions = false
        }
    }
}
