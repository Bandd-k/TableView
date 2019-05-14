import UIKit

final class ViewController: UIViewController {
    var tableView: GoogleTableView!
    let finalModel = MutableSectionModel(items: [CellModel(title: "first", message: "privet"), CellModel(title: "second", message: "hello")])
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTableView()
        tableView.reloadData()
    }

    private func setUpTableView() {
        tableView = GoogleTableView()
        view.addSubview(tableView)
        tableView.owner = self
        tableView.pinToSuperview()
        tableView.register(configurator: TableViewCell.configurator)
        tableView.sections.append(finalModel)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.finalModel.items.removeFirst()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.finalModel.items.append(CellModel(title: "newElement", message: "chao"))
        }
    }
}

extension ViewController: GoogleTableViewOwner {
    func tableView(_ tableView: GoogleTableView, didSelectRow model: Any, at indexPath: IndexPath) {
        guard let model = model as? CellModel else { return }
        print(model.title)
    }
}

final class TableViewCell: UITableViewCell {
    static let configurator = CellConfigurator<TableViewCell, CellModel>(
        heightForItem: { _ in return 50 },
        configureCell: { cell, item, _ in
            cell.title.text = item.title
            cell.icon.image = UIImage(named: "information")
    })

    struct Layout {
        static let spacing: CGFloat = 10
        static let imageSize: CGFloat = 30
    }
    private let title: UILabel
    private let icon: UIImageView
    static var identifier: String { return String(describing: TableViewCell.self) }
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.title = UILabel()
        self.icon = UIImageView()
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = Layout.spacing
        stack.alignment = .center
        stack.addArrangedSubview(self.icon)
        self.icon.pinSize(CGSize(width: Layout.imageSize, height: Layout.imageSize))

        stack.addArrangedSubview(self.title)

        self.contentView.addSubview(stack)
        stack.pinToSuperview()
        backgroundColor = .white
    }

    func configure(model: CellModel) {
        self.title.text = model.title
        self.icon.image = UIImage(named: "information")
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

}

class CellModel: Equatable {
    // it is just for fast test
    static func == (lhs: CellModel, rhs: CellModel) -> Bool {
        return lhs === rhs
    }
    let title: String
    let message: String
    init(title: String, message: String) {
        self.title = title
        self.message = message
    }
}
