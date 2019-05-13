import Foundation
import UIKit

extension UIView {
    @discardableResult
    func pinToSuperview(_ insets: UIEdgeInsets = UIEdgeInsets.zero, excludingEdges: Set<NSLayoutConstraint.Attribute>? = nil) -> [NSLayoutConstraint] {
        guard let superview = self.superview else {
            fatalError("Superview is required before pinning to it")
        }

        self.translatesAutoresizingMaskIntoConstraints = false

        var constraints: [NSLayoutConstraint] = [
            NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: superview, attribute: .leading, multiplier: 1.0, constant: insets.left),
            NSLayoutConstraint(item: superview, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1.0, constant: insets.right),
            NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: superview, attribute: .top, multiplier: 1.0, constant: insets.top),
            NSLayoutConstraint(item: superview, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: insets.bottom),
        ]
        if let excludingEdges = excludingEdges { constraints.removeAll { excludingEdges.contains($0.firstAttribute) } }
        superview.addConstraints(constraints)

        return constraints
    }

    @discardableResult
    func pinHeight(_ height: CGFloat) -> NSLayoutConstraint {
        let heightConstraint = NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: height)
        self.addConstraint(heightConstraint)
        return heightConstraint
    }

    @discardableResult
    func pinWidth(_ width: CGFloat) -> NSLayoutConstraint {
        let widthConstraint = NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: width)
        self.addConstraint(widthConstraint)
        return widthConstraint
    }

    @discardableResult
    func pinSize(_ size: CGSize) -> [NSLayoutConstraint] {
        return [self.pinWidth(size.width), self.pinHeight(size.height)]
    }
}

extension UIEdgeInsets {
    /// Creates an `UIEdgeInsets` with the inset value applied to all (top, bottom, right, left)
    /// - Parameter inset: Inset to be applied in all the edges.
    public init(inset: CGFloat) {
        self.init(top: inset, left: inset, bottom: inset, right: inset)
    }

    /// Creates an `UIEdgeInsets` with the vertical value applied to top and bottom, horizontal value applied to left and right
    /// - Parameter vertical: vertical value to be applied to top and bottom
    /// - Parameter horizontal: horizontal value to be applied to left and right
    public init(vertical: CGFloat = 0, horizontal: CGFloat = 0) {
        self.init(top: vertical, left: horizontal, bottom: vertical, right: horizontal)
    }
}

typealias VoidFunc = () -> Void
