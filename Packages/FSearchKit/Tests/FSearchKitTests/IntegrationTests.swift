import Foundation
import Testing

@testable import FSearchKit

@Suite(.enabled(if: RealDaemon.binary != nil, "run scripts/build-daemon.sh first"))
struct IntegrationTests {
    func waitReady(_ c: DaemonClient) async throws {
        for _ in 0..<200 {
            if let s = try? await c.status(), s.entries > 0 { return }
            try await Task.sleep(for: .milliseconds(100))
        }
        Issue.record("daemon never became ready")
    }

    @Test func searchesByNameAndContent() async throws {
        let d = try RealDaemon(files: ["proj/heronfile.txt": "one\n  a heron needle  \n", "🏡 notes/a b.md": "x"])
        // Keep the daemon alive until the test ends, not just its last use of `d`.
        defer { withExtendedLifetime(d) {} }
        let c = DaemonClient(socketPath: d.socketPath)
        try await waitReady(c)
        let names = try await c.search("heronfile", limit: 50)
        #expect(names.hits.first?.path.hasSuffix("/proj/heronfile.txt") == true)
        let emoji = try await c.search("a b", limit: 50)
        #expect(emoji.hits.contains { $0.path.hasSuffix("/🏡 notes/a b.md") })
        // Content search waits for the content index to catch up.
        var grep: GrepReply?
        for _ in 0..<100 {
            grep = try? await c.grep(q: "", pattern: "heron needle", mode: .literal)
            if grep?.files.isEmpty == false { break }
            try await Task.sleep(for: .milliseconds(100))
        }
        #expect(grep?.files.first?.matches.first?.line == 2)
    }

    /// The daemon accepts every token the type dropdown sends and narrows by it.
    @Test func typeDropdownTokensNarrowNames() async throws {
        let files = ["egretbills/x.txt", "egret.pdf", "egret.jpg", "egret.swift", "egret.zip", "egret.mp3", "egret.mov", "egret.ttf"]
        let d = try RealDaemon(files: Dictionary(uniqueKeysWithValues: files.map { ($0, "x") }))
        defer { withExtendedLifetime(d) {} }
        let c = DaemonClient(socketPath: d.socketPath)
        try await waitReady(c)
        func names(_ f: TypeFilter) async throws -> [String] {
            try await c.search(TypeFilter.query("egret", with: f), limit: 50).hits.map { ($0.path as NSString).lastPathComponent }
        }
        #expect(try await names(.folders) == ["egretbills"])
        #expect(try await names(.documents) == ["egret.pdf"])
        #expect(try await names(.images) == ["egret.jpg"])
        #expect(try await names(.code) == ["egret.swift"])
        #expect(try await names(.archives) == ["egret.zip"])
        #expect(try await names(.audio) == ["egret.mp3"])
        #expect(try await names(.video) == ["egret.mov"])
        #expect(try await names(.fonts) == ["egret.ttf"])
        for f in TypeFilter.allCases { _ = try await names(f) }  // no token is rejected (apps has no fixture)
    }
}
