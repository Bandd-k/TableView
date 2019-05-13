import Foundation
import UIKit

class SectionModel {
    var items: [Any] {
        didSet {
            print("aaa")
            // call update
        }
    }
    var numberOfItems: Int { return items.count }
    init(items: [Any]) {
        self.items = items
    }

    func item(at index: Int) -> Any {
        return items[index]
    }

    private func update(old: [AnyObject], new: [AnyObject]) {
        // calculate diff
    }
}

class NumbrsTableView: UITableView {
    // : UITableViewController
    var sections: [SectionModel] = [] {
        didSet {
            self.reloadData()
            //proper cell updates
        }
    }
    var configurators: [String: AnyCellConfigurator] = [:]
    var cachedCellHeights: [IndexPath: CGFloat] = [:]
    weak var owner: NumbrsTableViewOwner?

    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        self.delegate = self
        self.dataSource = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func register(configurator: AnyCellConfigurator) {
        configurators[configurator.reuseID] = configurator // check if already exists and throw erro
        self.register(configurator.cellClass, forCellReuseIdentifier: configurator.reuseID)
    }

    func objects(for indexPath: IndexPath) -> (item: Any, configurator: AnyCellConfigurator) {
        let item = sections[indexPath.section].item(at: indexPath.row)
        let thisType: Any.Type = type(of: item)
        let reuseID =  String(describing: thisType)
        let configurator = configurators[reuseID]! // no config, throw an error
        return (item, configurator)
    }
}

extension NumbrsTableView: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].numberOfItems
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let (item, configurator) = objects(for: indexPath)
        let cell = dequeueReusableCell(withIdentifier: configurator.reuseID)! // guard as well
        configurator.configureAnyCell(cell, item, indexPath)
        return cell
    }
}

extension NumbrsTableView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // add cachedCellHeights
        let (item, configurator) = objects(for: indexPath)
        return configurator.heightForAnyItem?(item) ?? 30 // add autoCalculationBlock
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        self.owner?.tableView?(self, willDisplayCell: cell, at: indexPath)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // maybe call automatically
        self.owner?.tableView?(self, didSelectRow: sections[indexPath.section].item(at: indexPath.row), at: indexPath)
    }
}

struct CellConfigurator<Cell: UITableViewCell, Item: Any> {
    var cellClass: AnyClass { return Cell.self }
    var reuseID: String { return String(describing: Item.self) }
    var heightForItem: ((Item) -> CGFloat)?
    let configureCell: (Cell, Item, IndexPath?) -> ()
}

extension CellConfigurator: AnyCellConfigurator {
    // do not call directly
    var configureAnyCell: (UITableViewCell, Any, IndexPath?) -> () {
        return { [configureCell] cell, item, indexPath in
            configureCell(cell as! Cell, item as! Item, indexPath)
        }
    }

    var heightForAnyItem: ((Any) -> CGFloat)? {
        return heightForItem.map { height in { item in height(item as! Item) } }
    }
}

protocol AnyCellConfigurator {
    var cellClass: AnyClass { get }
    var reuseID: String { get }
    var heightForAnyItem: ((Any) -> CGFloat)? { get }
    var configureAnyCell: (UITableViewCell, Any, IndexPath?) -> () { get }
}

@objc
protocol NumbrsTableViewOwner: AnyObject {
    @objc optional func tableView(_ tableView: NumbrsTableView, didSelectRow model: Any, at indexPath: IndexPath)
    @objc optional func tableView(_ tableView: NumbrsTableView, willDisplayCell cell: UITableViewCell, at indexPath: IndexPath)
}
