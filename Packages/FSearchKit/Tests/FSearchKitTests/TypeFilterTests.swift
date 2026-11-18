import Testing

@testable import FSearchKit

@Suite struct TypeFilterTests {
    @Test func tokens() {
        #expect(TypeFilter.folders.token == "kind:dir")
        #expect(TypeFilter.documents.token == "type:doc")
        #expect(TypeFilter.archives.token == "type:archive")
        #expect(TypeFilter.apps.token == "type:app")
        #expect(TypeFilter.allCases.map(\.title) == ["Folders", "Documents", "Images", "Code", "Video", "Audio", "Archives", "Fonts", "Apps"])
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
