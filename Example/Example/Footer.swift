//
//  Footer.swift
//  Example
//
//  Created by Matias Cudich on 9/22/16.
//  Copyright © 2016 Matias Cudich. All rights reserved.
//

import Foundation
import TemplateKit

struct FooterProperties: ViewProperties {
  var key: String?
  var layout = LayoutProperties()
  var style = StyleProperties()
  var gestures = GestureProperties()

  var count = 0
  var completedCount = 0
  var onClearCompleted: Selector?
  var onUpdateFilter: Selector?
  var nowShowing: Filter?

  public init() {}

  public init(_ properties: [String : Any]) {
    applyProperties(properties)

    count = properties.cast("count") ?? 0
    completedCount = properties.cast("completedCount") ?? 0
    onClearCompleted = properties.cast("onClearCompleted")
    nowShowing = properties.get("nowShowing")
    onUpdateFilter = properties.cast("onUpdateFilter")
  }
}

func ==(lhs: FooterProperties, rhs: FooterProperties) -> Bool {
  return lhs.count == rhs.count && lhs.completedCount == rhs.completedCount && lhs.onClearCompleted == rhs.onClearCompleted && lhs.nowShowing == rhs.nowShowing && lhs.onUpdateFilter == rhs.onUpdateFilter
}

class Footer: CompositeComponent<EmptyState, FooterProperties, UIView> {
  @objc func handleSelectAll() {
    performSelector(properties.onUpdateFilter, with: Filter.all.rawValue)
  }

  @objc func handleSelectActive() {
    performSelector(properties.onUpdateFilter, with: Filter.active.rawValue)
  }

  @objc func handleSelectCompleted() {
    performSelector(properties.onUpdateFilter, with: Filter.completed.rawValue)
  }

  @objc func handleClearCompleted() {
    performSelector(properties.onClearCompleted)
  }

  override func render() -> Element {
    return render(withLocation: Bundle.main.url(forResource: "Footer", withExtension: "xml")!)
  }
}
