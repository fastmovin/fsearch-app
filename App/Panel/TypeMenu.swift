import AppKit
import FSearchKit

/// The type dropdown's menu (⌘P, or a click on the dropdown): All types, then each ``TypeFilter``.
///
/// A native menu, like ⌘K's, so ↑/↓, ↵, Esc and typing a name to jump come with it.
@MainActor
enum TypeMenu {
    /// Pops the menu up under the dropdown, whose frame is from the panel's top left.
    static func show(model: SearchModel, in view: NSView?, under button: CGRect) {
        guard let view else { return }
        popUp(build(model: model), PanelGeometry.viewPoint(CGPoint(x: button.minX, y: button.maxY), in: view), view)
    }

    /// Shows the menu (modal, on screen). Never in the unit-test host; tests may replace it.
    static var popUp: @MainActor (NSMenu, NSPoint, NSView) -> Void = { menu, at, view in
        guard !Presentation.inert else { return }
        menu.popUp(positioning: nil, at: at, in: view)
    }

    /// The menu; the current pick is ticked, and choosing an item sets ``SearchModel/typeFilter``.
    static func build(model: SearchModel) -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false
        for pick in [nil] + TypeFilter.allCases.map(Optional.some) {
            let item = NSMenuItem(title: pick?.title ?? "All types", action: #selector(ActionsMenu.Target.run(_:)), keyEquivalent: "")
            let t = ActionsMenu.Target { model.typeFilter = pick }
            item.target = t
            item.representedObject = t  // the item keeps its target alive
            item.state = pick == model.typeFilter ? .on : .off
            menu.addItem(item)
        }
        return menu
    }
}
