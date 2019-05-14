import Foundation
import UIKit

@objc class ModelChange: NSObject {
    // add description
    enum Category {
        case insert
        case delete
//        case update
//        case move
//        case insertSection
//        case deleteSection
//        case moveSection
    }
    let indexPath: IndexPath?
    let newIndexPath: IndexPath?
    let category: Category
    init(category: Category, indexPath: IndexPath?, newIndexPath: IndexPath?) {
        self.category = category
        self.indexPath = indexPath
        self.newIndexPath = newIndexPath
    }

    static func deleteItem(_ indexPath: IndexPath) -> ModelChange {
        return ModelChange(category: .delete, indexPath: indexPath, newIndexPath: nil)
    }

    static func insertItem(_ indexPath: IndexPath) -> ModelChange {
        return ModelChange(category: .insert, indexPath: nil, newIndexPath: indexPath)
    }
}

@objc
protocol SectionModelProtocol {
    func item(at index: Int) -> Any // change to AnyObject
    var numberOfItems: Int { get }
    var didChangeContent: (([ModelChange]) -> Void)? { get set } // new protocol?
}

class MutableSectionModel<T: Equatable>: SectionModelProtocol {

    var items: [T] {
        didSet {
            self.update(old: oldValue, new: items)
        }
    }
    var numberOfItems: Int { return items.count }
    init(items: [T]) {
        self.items = items
    }

    func item(at index: Int) -> Any { // change to AnyObject
        return items[index]
    }

    var didChangeContent: (([ModelChange]) -> Void)?

    private func update(old: [T], new: [T]) {
        // change to https://github.com/lxcid/ListDiff/blob/master/Sources/ListDiff.swift
        let diff = old.diff(new)
        let deletions = diff.deletions.map { ModelChange.deleteItem(IndexPath(row: $0.idx, section: 0)) }
        let insertions = diff.insertions.map { ModelChange.insertItem(IndexPath(row: $0.idx, section: 0)) } // section 0?
        let changes = [deletions, insertions].flatMap { $0 }
        self.didChangeContent?(changes)
    }
}

class NumbrsTableView: UITableView {
    // : UITableViewController
    var sections: [SectionModelProtocol] = [] {
        didSet {
            self.reloadData()
            //proper cell updates
            sections.forEach { section in
                section.didChangeContent = { [weak self] changes in self?.updateTable(with: changes) }
            }
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

    func updateTable(with changes: [ModelChange]) {
        self.performBatchUpdates({
            changes.forEach { change in
                switch change.category {
                case .insert: self.insertRows(at: [change.newIndexPath!], with: .automatic)
                case .delete: self.deleteRows(at: [change.indexPath!], with: .automatic)
                }
            }
        })
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
