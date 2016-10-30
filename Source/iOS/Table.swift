//
//  Table.swift
//  TemplateKit
//
//  Created by Matias Cudich on 10/29/16.
//  Copyright © 2016 Matias Cudich. All rights reserved.
//

import Foundation
import CSSLayout

public struct TableProperties: Properties {
  public var core = CoreProperties()

  weak public var tableViewDelegate: TableViewDelegate?
  weak public var tableViewDataSource: TableViewDataSource?
  weak public var eventTarget: Node?

  // This is used to know when the underlying table view should be reloaded. If the previous list
  // of item keys does not equal the new list, then the table is reloaded. This could be optimized
  // later to intelligently add/remove only the items that changed.
  public var itemKeys: [AnyHashable]?

  public var onEndReached: Selector?
  public var onEndReachedThreshold: CGFloat?

  public init() {}

  public init(_ properties: [String : Any]) {
    core = CoreProperties(properties)

    tableViewDelegate = properties["tableViewDelegate"] as? TableViewDelegate
    tableViewDataSource = properties["tableViewDataSource"] as? TableViewDataSource
    eventTarget = properties["eventTarget"] as? Node
    itemKeys = properties["itemKeys"] as? [AnyHashable]
    onEndReached = properties.cast("onEndReached")
    onEndReachedThreshold = properties.cast("onEndReachedThreshold")
  }

  public mutating func merge(_ other: TableProperties) {
    core.merge(other.core)

    merge(&tableViewDelegate, other.tableViewDelegate)
    merge(&tableViewDataSource, other.tableViewDataSource)
    merge(&eventTarget, other.eventTarget)
    merge(&itemKeys, other.itemKeys)
    merge(&onEndReached, other.onEndReached)
    merge(&onEndReachedThreshold, other.onEndReachedThreshold)
  }
}

public func ==(lhs: TableProperties, rhs: TableProperties) -> Bool {
  return lhs.tableViewDelegate === rhs.tableViewDelegate && lhs.tableViewDataSource === rhs.tableViewDataSource && lhs.eventTarget === rhs.eventTarget && lhs.itemKeys == rhs.itemKeys && lhs.onEndReached == rhs.onEndReached  && lhs.onEndReachedThreshold == rhs.onEndReachedThreshold && lhs.equals(otherProperties: rhs)
}

protocol ScrollProxyDelegate: class {
  func scrollViewDidScroll(_ scrollView: UIScrollView)
}

public class ScrollProxy: NSObject {
  weak var delegate: ScrollProxyDelegate?

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    delegate?.scrollViewDidScroll(scrollView)
  }
}

public class Table: PropertyNode {
  public weak var parent: Node?
  public weak var owner: Node?
  public var context: Context?

  public var properties: TableProperties {
    didSet {
      if let oldItemKeys = oldValue.itemKeys, let newItemKeys = properties.itemKeys, oldItemKeys != newItemKeys {
        DispatchQueue.main.async {
          self.tableView?.reloadData()
        }
      }
    }
  }
  public var children: [Node]?
  public var element: ElementData<TableProperties>
  public var cssNode: CSSNode?

  lazy public var view: View = {
    return TableView(frame: CGRect.zero, style: .plain, context: self.getContext())
  }()

  private var tableView: TableView? {
    return view as? TableView
  }

  private lazy var scrollProxy: ScrollProxy = {
    let proxy = ScrollProxy()
    proxy.delegate = self
    return proxy
  }()

  private var delegateProxy: DelegateProxy?
  fileprivate var lastReportedEndLength: CGFloat = 0

  public required init(element: ElementData<TableProperties>, children: [Node]? = nil, owner: Node? = nil, context: Context? = nil) {
    self.element = element
    self.properties = element.properties
    self.children = children
    self.owner = owner
    self.context = context

    updateParent()
  }

  public func build() -> View {
    delegateProxy = DelegateProxy(target: properties.tableViewDelegate, interceptor: scrollProxy)
    delegateProxy?.registerInterceptable(selector: #selector(UIScrollViewDelegate.scrollViewDidScroll(_:)))

    tableView?.tableViewDelegate = delegateProxy as? TableViewDelegate
    tableView?.tableViewDataSource = properties.tableViewDataSource
    tableView?.eventTarget = properties.eventTarget

    return view
  }
}

extension Table: ScrollProxyDelegate {
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    properties.tableViewDelegate?.scrollViewDidScroll?(scrollView)

    let threshold = properties.onEndReachedThreshold ?? 0
    if let onEndReached = properties.onEndReached, scrollView.contentSize.height != lastReportedEndLength, distanceFromEnd(of: scrollView) < threshold, let owner = owner {
      lastReportedEndLength = scrollView.contentSize.height
      _ = (owner as AnyObject).perform(onEndReached)
    }
  }

  private func distanceFromEnd(of scrollView: UIScrollView) -> CGFloat {
    return scrollView.contentSize.height - (scrollView.bounds.height + scrollView.contentOffset.y)
  }
}