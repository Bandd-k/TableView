import UIKit

final class ViewController: UIViewController {
    var tableView: NumbrsTableView!
    let models = [CellModel(title: "place", action: { print("hah")}), CellModel(title: "account", action: {})]
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTableView()
        tableView.reloadData()
    }

    private func setUpTableView() {
        tableView = NumbrsTableView()
        view.addSubview(tableView)
        tableView.owner = self
        tableView.pinToSuperview()
        tableView.register(configurator: TableViewCell.configurator)
        tableView.sections.append(SectionModel(items: models))
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            let toAdd = SectionModel(items: self.models)
            self.tableView.sections.append(toAdd)
        }
    }
}

extension ViewController: NumbrsTableViewOwner {
    func tableView(_ tableView: NumbrsTableView, didSelectRow model: Any, at indexPath: IndexPath) {
        guard let model = model as? CellModel else { return }
        model.action()
    }
}

final class TableViewCell: UITableViewCell {
    static let configurator = CellConfigurator<TableViewCell, CellModel>(
        heightForItem: { _ in return 40 },
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

struct CellModel {
    let title: String
    let action: VoidFunc
}
