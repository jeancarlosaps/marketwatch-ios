import RxCocoa
import RxSwift
import UIKit

final class MarketListViewController: UIViewController {
    static let searchDebounce: RxTimeInterval = .milliseconds(300)

    private let viewModel: MarketListViewModel
    private let themeManager: ThemeManager
    private let onSelectAsset: (String, String) -> Void
    private let disposeBag = DisposeBag()

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let refreshControl = UIRefreshControl()
    private let footerView = MarketListFooterView()
    private let feedbackView = FeedbackStateView()
    private let skeletonStack = UIStackView()
    private let searchController = UISearchController(searchResultsController: nil)

    private var items: [MarketListItem] = []

    init(
        viewModel: MarketListViewModel,
        themeManager: ThemeManager,
        onSelectAsset: @escaping (String, String) -> Void
    ) {
        self.viewModel = viewModel
        self.themeManager = themeManager
        self.onSelectAsset = onSelectAsset
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bind()
        viewModel.loadInitial()
    }

    private func setupUI() {
        title = String(localized: "Mercado")
        view.backgroundColor = MWColor.canvas
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        updateAppearanceButton()
        configureSearch()
        configureTable()
        configureOverlays()
        activateConstraints()
    }

    private func updateAppearanceButton() {
        let current = themeManager.preference
        let actions = AppearancePreference.allCases.map { option in
            UIAction(title: option.menuTitle,
                     image: UIImage(systemName: option.symbolName),
                     state: option == current ? .on : .off) { [weak self] _ in
                self?.themeManager.select(option)
                self?.updateAppearanceButton()
            }
        }
        let button = UIBarButtonItem(
            image: UIImage(systemName: current.symbolName),
            menu: UIMenu(title: String(localized: "Aparência"), children: actions)
        )
        button.accessibilityLabel = String(localized: "Aparência")
        button.accessibilityValue = current.menuTitle
        navigationItem.rightBarButtonItem = button
    }

    private func configureSearch() {
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = String(localized: "Buscar criptomoedas")
        searchController.searchBar.autocapitalizationType = .none
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }

    private func configureTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 72, bottom: 0, right: MWLayout.spaceMD)
        tableView.separatorColor = MWColor.separator
        tableView.rowHeight = UITableView.automaticDimension
        // Price + variation badge needs more than a single-line row.
        tableView.estimatedRowHeight = 88
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(MarketCoinCell.self, forCellReuseIdentifier: MarketCoinCell.reuseIdentifier)
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        refreshControl.tintColor = MWColor.accent
        footerView.onRetry = { [weak self] in
            self?.viewModel.retryPagination()
        }
        tableView.tableFooterView = footerView
        resizeFooter()
    }

    private func configureOverlays() {
        feedbackView.translatesAutoresizingMaskIntoConstraints = false
        feedbackView.isHidden = true
        feedbackView.onAction = { [weak self] in
            self?.viewModel.retryInitial()
        }

        skeletonStack.axis = .vertical
        skeletonStack.spacing = MWLayout.spaceSM
        skeletonStack.translatesAutoresizingMaskIntoConstraints = false
        skeletonStack.isHidden = true
        for _ in 0 ..< 6 {
            let block = SkeletonBlockView()
            block.translatesAutoresizingMaskIntoConstraints = false
            block.heightAnchor.constraint(equalToConstant: 64).isActive = true
            skeletonStack.addArrangedSubview(block)
        }

        view.addSubview(tableView)
        view.addSubview(feedbackView)
        view.addSubview(skeletonStack)
    }

    private func activateConstraints() {
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            feedbackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: MWLayout.spaceMD),
            feedbackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -MWLayout.spaceMD),
            feedbackView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            skeletonStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: MWLayout.spaceMD),
            skeletonStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: MWLayout.spaceMD),
            skeletonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -MWLayout.spaceMD),
        ])
    }

    private func bind() {
        viewModel.content
            .drive(onNext: { [weak self] state in
                self?.render(content: state)
            })
            .disposed(by: disposeBag)

        viewModel.footer
            .drive(onNext: { [weak self] state in
                self?.render(footer: state)
            })
            .disposed(by: disposeBag)

        viewModel.isRefreshing
            .drive(onNext: { [weak self] refreshing in
                guard let self else { return }
                if refreshing {
                    if !refreshControl.isRefreshing {
                        refreshControl.beginRefreshing()
                    }
                } else if refreshControl.isRefreshing {
                    refreshControl.endRefreshing()
                }
            })
            .disposed(by: disposeBag)

        viewModel.assetSelected
            .emit(onNext: { [weak self] id, name in
                self?.onSelectAsset(id, name)
            })
            .disposed(by: disposeBag)

        // Emits on typing and when editing ends, so Cancel clears the filter.
        // The initial value is skipped so it cannot replace the loading state.
        searchController.searchBar.rx.text.orEmpty
            .skip(1)
            .debounce(Self.searchDebounce, scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] query in
                self?.viewModel.updateSearchQuery(query)
            })
            .disposed(by: disposeBag)
    }

    private func render(content state: MarketListContentState) {
        switch state {
        case .loading:
            items = []
            tableView.reloadData()
            tableView.isHidden = true
            feedbackView.isHidden = true
            skeletonStack.isHidden = false
        case let .items(nextItems):
            items = nextItems
            tableView.reloadData()
            tableView.isHidden = false
            feedbackView.isHidden = true
            skeletonStack.isHidden = true
        case .empty:
            items = []
            tableView.reloadData()
            tableView.isHidden = true
            skeletonStack.isHidden = true
            feedbackView.isHidden = false
            feedbackView.configure(kind: .empty,
                                   title: String(localized: "Nenhuma criptomoeda"),
                                   message: String(localized: "Puxe para atualizar ou tente novamente."),
                                   actionTitle: String(localized: "Tentar novamente"))
        case .searchEmpty:
            items = []
            tableView.reloadData()
            tableView.isHidden = true
            skeletonStack.isHidden = true
            feedbackView.isHidden = false
            feedbackView.configure(kind: .empty,
                                   title: String(localized: "Nenhum resultado"),
                                   message: String(localized: "Nenhum ativo carregado corresponde à busca."),
                                   actionTitle: nil)
        case let .error(message):
            items = []
            tableView.reloadData()
            tableView.isHidden = true
            skeletonStack.isHidden = true
            feedbackView.isHidden = false
            feedbackView.configure(kind: .error,
                                   title: String(localized: "Falha ao carregar"),
                                   message: message,
                                   actionTitle: String(localized: "Tentar novamente"))
        }
    }

    private func render(footer state: MarketListFooterState) {
        footerView.configure(state)
        resizeFooter()
    }

    private func resizeFooter() {
        footerView.setNeedsLayout()
        footerView.layoutIfNeeded()
        let height = footerView.isHidden ? 0 : footerView.systemLayoutSizeFitting(CGSize(width: tableView.bounds.width,
                                                                                         height: UIView.layoutFittingCompressedSize.height),
                                                                                  withHorizontalFittingPriority: .required,
                                                                                  verticalFittingPriority: .fittingSizeLevel).height
        var frame = footerView.frame
        frame.size.width = tableView.bounds.width
        frame.size.height = height
        footerView.frame = frame
        tableView.tableFooterView = footerView
    }

    @objc
    private func handleRefresh() {
        viewModel.refresh()
    }
}

extension MarketListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: MarketCoinCell.reuseIdentifier,
                                                       for: indexPath) as? MarketCoinCell else {
            return UITableViewCell()
        }
        cell.configure(with: items[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.selectItem(at: indexPath.row)
    }

    func tableView(_: UITableView, willDisplay _: UITableViewCell, forRowAt indexPath: IndexPath) {
        viewModel.loadNextPageIfNeeded(showingIndex: indexPath.row)
    }
}

private extension AppearancePreference {
    var menuTitle: String {
        switch self {
        case .automatic:
            String(localized: "Automático")
        case .light:
            String(localized: "Claro")
        case .dark:
            String(localized: "Escuro")
        }
    }

    var symbolName: String {
        switch self {
        case .automatic:
            "circle.lefthalf.filled"
        case .light:
            "sun.max"
        case .dark:
            "moon.stars"
        }
    }
}
