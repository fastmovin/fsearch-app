const { section, row, col, note, option, compare, esc } = kit;
export const title = "FSearch type filter mockups";

const style = `<style>
.fs-panel{width:560px;border:1px solid #d0d0d6;border-radius:14px;background:#f6f6f8;font:13px -apple-system,system-ui,sans-serif;color:#1d1d1f;overflow:hidden;box-shadow:0 6px 24px rgba(0,0,0,.12);position:relative}
.fs-top{display:flex;align-items:center;gap:8px;padding:12px 14px;font-size:16px}
.fs-q{flex:1}.fs-q.ph{color:#9a9aa0}
.fs-chip{font-size:11px;padding:2px 8px;border-radius:6px;background:rgba(0,0,0,.07)}
.fs-chip.on{background:#0a66d8;color:#fff}
.fs-dd{font-size:12px;padding:3px 8px;border:1px solid #c9c9cf;border-radius:6px;background:#fff;white-space:nowrap}
.fs-dd.on{border-color:#0a66d8;color:#0a66d8}
.fs-tabs{display:flex;gap:4px;padding:0 12px 8px;font-size:12px}
.fs-tab{padding:3px 10px;border-radius:6px;color:#55555a}.fs-tab.on{background:#0a66d8;color:#fff}
.fs-hr{border-top:1px solid #e0e0e4}
.fs-sec{font-size:11px;color:#86868b;padding:8px 14px 2px}
.fs-row{display:flex;gap:8px;align-items:center;padding:5px 14px}
.fs-row.sel{background:#0a66d8;color:#fff;border-radius:6px;margin:0 6px;padding:5px 8px}
.fs-row .dir{color:#86868b;font-size:12px}.fs-row.sel .dir{color:#d6e6ff}
.fs-row .k{margin-left:auto;font-size:11px;color:#86868b}.fs-row.sel .k{color:#d6e6ff}
.fs-foot{display:flex;gap:12px;padding:7px 12px;font-size:11px;color:#86868b}
.fs-foot span:first-child{margin-right:auto}
.fs-pop{position:absolute;right:12px;top:44px;width:190px;background:#fff;border:1px solid #d0d0d6;border-radius:8px;box-shadow:0 8px 24px rgba(0,0,0,.18);padding:4px;font-size:12px;z-index:2}
.fs-pop div{padding:4px 8px;border-radius:5px;display:flex;justify-content:space-between}
.fs-pop div.on{background:#0a66d8;color:#fff}.fs-pop div i{color:#86868b;font-style:normal}.fs-pop div.on i{color:#d6e6ff}
.fs-pop.left{left:60px;right:auto;top:44px}
</style>`;

// One result or command row: [icon, name, folder, right-hand hint].
const r = ([icon, name, dir = "", k = ""], sel) =>
  `<div class="fs-row${sel ? " sel" : ""}"><span>${icon}</span><span>${esc(name)}</span><span class="dir">${esc(dir)}</span><span class="k">${esc(k)}</span></div>`;
const sec = (t) => `<div class="fs-sec">${esc(t)}</div>`;
const rows = (items, on = 0) => items.map((it, i) => r(it, i === on)).join("");
const foot = `<div class="fs-hr"></div><div class="fs-foot"><span>⚙</span><span>Open ↵</span><span>Reveal in Finder ⌘↵</span><span>Actions ⌘K</span></div>`;
const panel = ({ top, tabs = "", body, pop = "" }) =>
  `<div class="fs-panel">${pop}<div class="fs-top">🔍 ${top}</div>${tabs}<div class="fs-hr"></div>${body}${foot}</div>`;

const mixed = [
  ["📄", "invoice-2026-10.pdf", "~/Documents/Taxes"],
  ["📁", "Invoices", "~/Documents"],
  ["🖼", "invoice-scan.jpg", "~/Downloads"],
  ["📄", "invoice-template.docx", "~/Documents/Templates"],
];
const folders = [
  ["📁", "Invoices", "~/Documents"],
  ["📁", "invoices-archive", "~/Documents/Old"],
  ["📁", "Invoice Exports", "~/Library/Mobile Documents"],
];
const fallbacks = [
  ["📝", "Search inside files"],
  ["ƒ", "Find definitions"],
];
const typeList = [
  ["All types", "⌘0"], ["Folders", "⌘1"], ["Documents", "⌘2"], ["Images", "⌘3"], ["Code", "⌘4"],
  ["Video", ""], ["Audio", ""], ["Archives", ""], ["Fonts", ""], ["Apps", ""],
];
const popup = (on, cls = "") =>
  `<div class="fs-pop ${cls}">${typeList.map(([t, k], i) => `<div class="${i === on ? "on" : ""}">${t}<i>${k}</i></div>`).join("")}</div>`;
const q = (t) => `<span class="fs-q">${esc(t)}</span>`;

const optA = section("a", "A. Type dropdown in the search bar (recommended)", [
  note("A dropdown sits at the right of the search field, the way Raycast's file search does it. ⌘P opens it, ↑/↓ and ↵ pick. ⌘1 to ⌘4 jump straight to the common ones. When a type is picked, the dropdown turns blue and the results narrow. Backspace in an empty field does not clear it; ⌘0 or picking All types does."),
  row(
    col(`<b>1. Closed, nothing picked</b>`, panel({ top: q("invoice") + `<span class="fs-dd">All types ▾</span>`, body: sec("Files") + rows(mixed) + sec("Use “invoice” with…") + rows(fallbacks, -1) })),
    col(`<b>2. Open with ⌘P</b>`, panel({ top: q("invoice") + `<span class="fs-dd on">All types ▾</span>`, body: sec("Files") + rows(mixed) + sec("Use “invoice” with…") + rows(fallbacks, -1), pop: popup(1) })),
  ),
  row(
    col(`<b>3. Folders picked</b>`, panel({ top: q("invoice") + `<span class="fs-dd on">📁 Folders ▾</span>`, body: sec("Folders") + rows(folders) + sec("Use “invoice” with…") + rows(fallbacks, -1) })),
    col(`<b>4. Folders picked, empty query: recent folders only</b>`, panel({ top: `<span class="fs-q ph">Search folders</span><span class="fs-dd on">📁 Folders ▾</span>`, body: sec("Recent") + rows([["📁", "fsearch-app", "~/projects"], ["📁", "Taxes", "~/Documents"], ["📁", "Downloads", "~"]]) })),
  ),
]);

const optB = section("b", "B. Suggestion rows and completion", [
  note("No new control. The \"Use … with…\" section gets type rows next to the two that exist today. Picking one adds the matching text (kind:dir, type:image) to the query, so you learn the syntax as you go. Typing type: or kind: pops up the allowed values."),
  row(
    col(`<b>1. Type rows under the results</b>`, panel({ top: q("invoice"), body: sec("Files") + rows(mixed.slice(0, 2)) + sec("Use “invoice” with…") + rows([...fallbacks, ["📁", "Only folders", "", "kind:dir"], ["📄", "Only documents", "", "type:doc"], ["🖼", "Only images", "", "type:image"]], 2) })),
    col(`<b>2. Picked: the filter is written into the query</b>`, panel({ top: q("invoice kind:dir"), body: sec("Files") + rows(folders) + sec("Use “invoice kind:dir” with…") + rows(fallbacks, -1) })),
  ),
  row(
    col(`<b>3. Typing type: shows the values</b>`, panel({
      top: q("invoice type:"),
      body: sec("Files") + rows(mixed.slice(0, 3)),
      pop: `<div class="fs-pop left">${["code", "doc", "image", "video", "audio", "archive", "font", "app"].map((t, i) => `<div class="${i === 1 ? "on" : ""}">${t}</div>`).join("")}</div>`,
    })),
  ),
]);

const tabsRow = (on) =>
  `<div class="fs-tabs">${["All", "Folders", "Documents", "Images", "Code", "More ▾"].map((t, i) => `<span class="fs-tab${i === on ? " on" : ""}">${t}</span>`).join("")}</div>`;
const optC = section("c", "C. Tabs above the results", [
  note("A row of tabs under the search field. ⌃Tab or ⌘1 to ⌘5 move between them; More ▾ holds Video, Audio, Archives, Fonts and Apps. Costs one row of height in a panel that is a fixed 460 points tall."),
  row(
    col(`<b>1. All</b>`, panel({ top: q("invoice"), tabs: tabsRow(0), body: sec("Files") + rows(mixed) })),
    col(`<b>2. Folders</b>`, panel({ top: q("invoice"), tabs: tabsRow(1), body: sec("Folders") + rows(folders) })),
  ),
]);

const cmp = section("cmp", "Side by side", [
  compare(
    ["", "A. Dropdown", "B. Suggestion rows", "C. Tabs"],
    [
      ["Can you see the filter is on?", "Yes, blue dropdown", "Only as text in the query", "Yes, highlighted tab"],
      ["Works with an empty query", "Yes, filters recents", "No, rows need a query", "Yes"],
      ["Teaches the typed syntax", "No", "Yes", "No"],
      ["Panel space used", "None", "A few rows", "One row"],
      ["Work to build", "Most: new key handling and tests", "Least", "Middle"],
      ["Fits the planned big window later", "Yes, same control", "Partly", "Yes"],
    ],
  ),
  option("A", "Dropdown in the search bar", "It shows the filter clearly, costs no space and works before you type. It's the most work, mostly in the panel's keyboard handling.", { rec: true }),
  note("Open questions for any option: if you pick Folders and also type type:image, which wins? (My call: the typed one, and the dropdown shows Custom.) Should the choice stick when you reopen the panel later? (My call: only within the 60-second resume window, like the query.)"),
]);

export default [style, optA, optB, optC, cmp];
