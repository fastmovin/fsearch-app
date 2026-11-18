import AppKit
import FSearchKit
import SwiftUI
import Testing

@testable import FSearch

extension AppTests {
    @Suite @MainActor
    struct TypeMenuTests {
        @Test func itemsTickTheCurrentPickAndSetIt() {
            let env = TestEnv()
            defer { env.tearDown() }
            let model = env.app.search
            model.typeFilter = .images
            let menu = TypeMenu.build(model: model)
            #expect(
                menu.items.map(\.title) == [
                    "All types", "Folders", "Documents", "Images", "Code", "Video", "Audio", "Archives", "Fonts", "Apps",
                ])
            #expect(menu.items.filter { $0.state == .on }.map(\.title) == ["Images"])
            (menu.items[1].representedObject as? ActionsMenu.Target)?.run(nil)
            #expect(model.typeFilter == .folders)
            (menu.items[0].representedObject as? ActionsMenu.Target)?.run(nil)
            #expect(model.typeFilter == nil)
        }

        @Test func showPopsUpUnderTheButton() {
            let env = TestEnv()
            defer { env.tearDown() }
            var shown: (NSMenu, NSPoint)?
            let saved = TypeMenu.popUp
            TypeMenu.popUp = { menu, at, _ in shown = (menu, at) }
            defer { TypeMenu.popUp = saved }
            let view = NSView(frame: NSRect(x: 0, y: 0, width: 680, height: 460))
            TypeMenu.show(model: env.app.search, in: view, under: CGRect(x: 500, y: 10, width: 100, height: 20))
            #expect(shown?.1 == NSPoint(x: 500, y: 430))
            #expect(shown?.0.items.count == 10)
            shown = nil
            TypeMenu.show(model: env.app.search, in: nil, under: .zero)
            #expect(shown == nil, "no panel, no menu")
        }

        @Test func commandPIsTheTypeMenu() {
            typealias P = PanelInput.Press
            #expect(PanelInput.key(for: P(key: "p", characters: "p", command: true), queryIsEmpty: false) == .typeMenu)
            #expect(PanelInput.key(for: P(key: "P", characters: "P", command: true), queryIsEmpty: true) == .typeMenu)
            #expect(PanelInput.key(for: P(key: "p", command: true, control: true), queryIsEmpty: false) == nil)
        }

        /// A new pick over a half-typed filter: the rows answer the old pick, so ↵ waits.
        @Test func aNewPickMakesHalfTypedRowsStale() async {
            let env = TestEnv()
            defer { env.tearDown() }
            let model = env.app.search
            env.daemon.onSearch = { q in SearchReply(tookUs: 1, hits: [Wire.hit("/p/\(q).txt")]) }
            model.query = "foo"
            await model.refresh()
            model.query = "foo ext:"
            #expect(PanelInput.rowsAreCurrent(model))
            model.typeFilter = .code
            #expect(!PanelInput.rowsAreCurrent(model))
            var held = HeldKey()
            #expect(PanelInput.gate(.enter, held: &held, model: model) == nil)
        }
    }
}
