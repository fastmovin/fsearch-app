import Foundation
import UniformTypeIdentifiers

/// The panel's type dropdown: a kind of file a name search is narrowed to.
///
/// The pick becomes one daemon filter word (``token``) added to the query sent,
/// unless the query already has a typed `type:` or `kind:`.
public enum TypeFilter: String, CaseIterable, Sendable {
    case folders, documents, images, code, video, audio, archives, fonts, apps

    /// The name in the dropdown.
    public var title: String { rawValue.prefix(1).uppercased() + rawValue.dropFirst() }

    /// The daemon filter word for this pick.
    public var token: String {
        switch self {
        case .folders: "kind:dir"
        case .documents: "type:doc"
        case .images: "type:image"
        case .code: "type:code"
        case .video: "type:video"
        case .audio: "type:audio"
        case .archives: "type:archive"
        case .fonts: "type:font"
        case .apps: "type:app"
        }
    }

    /// The name query to send: the pick's token, then `q`, unless `q` has a typed type filter.
    /// The token goes first so a quote still open at the end of `q` can't swallow it.
    public static func query(_ q: String, with f: TypeFilter?) -> String {
        guard let f, !typedFilter(in: q) else { return q }
        return q.isEmpty ? f.token : f.token + " " + q
    }

    /// True if the query has a `type:` or `kind:` word with a value; the daemon unquotes, so quotes don't hide one.
    public static func typedFilter(in q: String) -> Bool {
        QuerySplit.words(q).map(QuerySplit.unquoted).contains { w in
            ["type:", "kind:"].contains { w.hasPrefix($0) && w.count > $0.count }
        }
    }

    /// Whether a recent file belongs to this pick.
    ///
    /// shortcut: judged by UTType, which can disagree with the daemon's own extension lists at the edges;
    /// only recents use it. Mirror the daemon's lists if that ever matters.
    public func matches(path: String, isDirectory: Bool) -> Bool {
        let ext = (path as NSString).pathExtension
        if self == .folders { return isDirectory && ext.lowercased() != "app" }
        guard let t = UTType(filenameExtension: ext) else { return false }
        switch self {
        case .folders: return false
        case .documents:
            return !t.conforms(to: .sourceCode)
                && ([.pdf, .text, .rtf, .presentation, .spreadsheet] as [UTType]).contains { t.conforms(to: $0) }
                || Self.officeDocs.contains(ext.lowercased())
        case .images: return t.conforms(to: .image)
        case .code: return t.conforms(to: .sourceCode)
        case .video: return t.conforms(to: .movie)
        case .audio: return t.conforms(to: .audio)
        case .archives: return t.conforms(to: .archive)
        case .fonts: return t.conforms(to: .font)
        case .apps: return t.conforms(to: .application)
        }
    }

    /// Word processing files whose UTTypes conform to no generic document type.
    private static let officeDocs: Set<String> = ["doc", "docx", "odt", "pages", "key", "numbers"]
}
