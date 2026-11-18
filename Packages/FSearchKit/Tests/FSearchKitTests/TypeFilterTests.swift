import Foundation
import Testing

@testable import FSearchKit

@Suite struct TypeFilterTests {
    @Test func tokens() {
        #expect(TypeFilter.folders.token == "kind:dir")
        #expect(TypeFilter.documents.token == "type:doc")
        #expect(TypeFilter.archives.token == "type:archive")
        #expect(TypeFilter.apps.token == "type:app")
        #expect(
            TypeFilter.allCases.map(\.title) == ["Folders", "Documents", "Images", "Code", "Video", "Audio", "Archives", "Fonts", "Apps"])
    }

    @Test func tokenIsAppended() {
        #expect(TypeFilter.query("invoice", with: .images) == "invoice type:image")
        #expect(TypeFilter.query("invoice", with: nil) == "invoice")
        #expect(TypeFilter.query("", with: .folders) == "kind:dir")
    }

    @Test func typedFilterWins() {
        #expect(TypeFilter.query("a kind:dir", with: .folders) == "a kind:dir")
        #expect(TypeFilter.query("a type:code", with: .images) == "a type:code")
        // The daemon unquotes in name search, so a quoted filter is still a filter.
        #expect(TypeFilter.typedFilter(in: "\"type:code\""))
        // A key with no value is not a filter yet.
        #expect(!TypeFilter.typedFilter(in: "type:"))
        #expect(!TypeFilter.typedFilter(in: "kinds of things"))
    }

    @Test func recentsMatch() {
        #expect(TypeFilter.folders.matches(path: "/a/b", isDirectory: true))
        #expect(!TypeFilter.folders.matches(path: "/a/b.txt", isDirectory: false))
        #expect(TypeFilter.images.matches(path: "/x.jpg", isDirectory: false))
        #expect(TypeFilter.images.matches(path: "/x.HEIC", isDirectory: false))
        #expect(TypeFilter.code.matches(path: "/x.swift", isDirectory: false))
        #expect(TypeFilter.documents.matches(path: "/x.pdf", isDirectory: false))
        #expect(TypeFilter.documents.matches(path: "/x.docx", isDirectory: false))
        #expect(TypeFilter.documents.matches(path: "/x.txt", isDirectory: false))
        #expect(!TypeFilter.documents.matches(path: "/x.swift", isDirectory: false))
        #expect(TypeFilter.video.matches(path: "/x.mov", isDirectory: false))
        #expect(TypeFilter.audio.matches(path: "/x.mp3", isDirectory: false))
        #expect(TypeFilter.archives.matches(path: "/x.zip", isDirectory: false))
        #expect(TypeFilter.fonts.matches(path: "/x.ttf", isDirectory: false))
        #expect(TypeFilter.apps.matches(path: "/A/Safari.app", isDirectory: true))
        #expect(!TypeFilter.images.matches(path: "/noext", isDirectory: false))
    }
}

@MainActor @Suite struct TypeFilterModelTests {
    @Test func namesSearchCarriesTheToken() async {
        let names = RecordingBackend(), content = RecordingBackend()
        let m = SearchModel(names: names, content: content)
        m.query = "invoice"
        m.typeFilter = .folders
        await m.refresh()
        #expect(names.calls == ["search invoice kind:dir"])
        m.query = "invoice kind:file"
        await m.refresh()
        #expect(names.calls.last == "search invoice kind:file", "a typed filter wins")
    }

    @Test func contentSearchesNeverCarryIt() async {
        let names = RecordingBackend(), content = RecordingBackend()
        let m = SearchModel(names: names, content: content)
        m.typeFilter = .images
        m.mode = .content
        m.query = "TODO"
        await m.refresh()
        m.mode = .names
        m.query = "main grep:x"
        await m.refresh()
        #expect(content.calls == ["grep |TODO|literal", "grep main|x|literal"])
    }

    @Test func aNewPickMakesTheRowsStale() async {
        let m = SearchModel(names: RecordingBackend(), content: RecordingBackend())
        m.query = "invoice"
        await m.refresh()
        #expect(m.resultsAreCurrent)
        m.typeFilter = .code
        #expect(!m.resultsAreCurrent)
        await m.refresh()
        #expect(m.resultsAreCurrent && m.answeredType == .code)
    }

    @Test func aNewPickOverAHalfTypedFilterStillRefreshes() async {
        let names = RecordingBackend()
        let m = SearchModel(names: names, content: RecordingBackend())
        m.query = "foo"
        await m.refresh()
        m.query = "foo ext:"
        await m.refresh()
        #expect(m.phase == .results, "the rows for foo stay while ext: is typed")
        m.typeFilter = .code
        await m.refresh()
        #expect(m.items.isEmpty && m.phase == .idle && m.answeredType == .code, "rows for the old pick go")
        m.query = "foo ext:md"
        await m.refresh()
        #expect(names.calls.last == "search foo ext:md type:code")
    }

    @Test func keyAndSession() {
        #expect(PanelKey.commandLetter("p", shift: false) == .typeMenu)
        #expect(PanelKey.commandLetter("з", shift: false, keyCode: 0x23) == .typeMenu)
        #expect(!PanelKey.typeMenu.actsOnResults)
        var s = PanelState(query: "a", selection: 2, count: 5, typeFilter: .images)
        let before = s
        #expect(s.reduce(.typeMenu) == .none && s == before)
        var session = PanelSession()
        session.hidden(s, at: Date(timeIntervalSince1970: 0))
        #expect(session.opened(at: Date(timeIntervalSince1970: 30)).typeFilter == .images)
        #expect(session.opened(at: Date(timeIntervalSince1970: 61)).typeFilter == nil)
    }
}
