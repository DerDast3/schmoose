# Schmoose — User Guide

How to use Schmoose day to day. For signing in (password, SSO, QR pairing,
login file) see **[HOW-TO-LOGIN.md](HOW-TO-LOGIN.md)**.

## Chats

- The **sidebar** lists all your chats. Public chats can be browsed and
  joined via the **+** tile; direct chats start from the **people search**.
- The header **star** cycles three states: favorite (rises under
  Favorites), normal, and **muted** (bell-off — no badge, doesn't rise,
  excluded from the unread filter).
- Group chats can have a **description** (visible via the chat header /
  manage dialog).
- Quiet **direct chats** disappear from the sidebar after ~30 days of
  silence (operator-configurable). Nothing is deleted — find them again
  via search.
- **Pinned threads** appear as indented sub-items under their chat in the
  sidebar (personal `↳`, global 📌 — details in "Pinned threads" below).
- Unread chats rise dynamically under Favorites until read; the
  **unread filter** (Ctrl+Shift+U) hides everything else.

- **Pinned threads in the rail** — two kinds:

  - **Personal pin (for me):** hit the pin in the thread bar (or a
    message's action bar), give the thread a name, and it appears as an
    indented sub `↳` under its chat — only for you. Every device you sign
    in with sees your pins.
  - **Global pin (for everyone):** the same dialog offers **"For
    everyone"** where allowed. The sub (📌) then appears in the rail of
    **every member** of the chat, live, with the same name for all.
    Rights: in public groups any member may pin and remove; in private
    groups only owners; direct chats have no global pins. A chat carries
    at most 10 global pins.
  - **A thread can carry both.** If a global pin exists, the rail shows
    only it — your personal pin is kept (hidden, not deleted) and comes
    back as soon as somebody removes the global one. Removing a global
    pin never touches other people's personal pins.
  - **Pins fade after 7 days of thread silence** — they are shortcuts,
    not archives; just re-pin after activity. Threads silent longer than
    that can't be pinned until somebody writes in them again.
  - The little **dot** on a sub means "new messages since you last looked"
    (personal, regardless of pin kind). Global pins can also be managed in
    the chat's manage dialog ("Pinned threads (for everyone)").

## Messages

- Type **Markdown** — `**bold**`, `` `code` ``, ``` code blocks (with
  syntax highlighting and a copy button), lists, links (open in a new
  tab). `:shortcode:` emoji work (`:tada:` → 🎉).
- **Attachments**: attach via the paperclip (or drag & drop). They become
  numbered drafts next to your message; you can rename each one before
  sending. Attachment-only messages are fine.
- **Edit** your message (✎): the markdown re-renders, `(edited)` marks it.
  **Delete** removes the message; replies to it survive as normal chat
  messages.
- **Reactions**: hover a message (long-press on mobile) and pick 👍 ❌ 🅰️
  🤩 or open the full emoji picker (🤩). Click a chip to toggle your own.
- **@mentions**: type `@` to open the people picker. Mentioning someone in
  a public chat adds them and starts their unread counter at the mention.
- **Replies & threads**: ↩ on a message quotes it as a reply; the `N ↩`
  badge on the root opens the **thread lens** — a filtered view of root +
  replies. Replies are normal messages; several threads can run in
  parallel. Esc steps out of the lens.
- **Triggers** (if the operator enabled integrations): a message starting
  with `/mail:code` or `/post:code` triggers an outbound mail/HTTP call.
  The chip under the message shows ⏳ pending → 👍 delivered / 👎 failed
  (edit + resend retries a failed one). Unknown codes send as plain text.

## Search

The **binoculars** in the menu band opens full-text search (Ctrl+F inside
a chat, or globally from the rail):

- Plain words search the message text; results group by chat, newest
  first, with clickable **jump-to-message**.
- Qualifiers narrow it down: `user:john`, `chat:"IT security"`,
  `from:2026-08-01`, `to:…`, `has:file` / `file:report`.
- `?` shows the cheat sheet; Esc or "← Back to results" returns to the
  hit list after a jump.

## Composer keys

- **Enter** sends, **Shift+Enter** is a newline.
- Markdown wraps: **Ctrl+B** (bold), **Ctrl+I** (italic), **Ctrl+Alt+K**
  (inline code), **Ctrl+U** (upload), **Ctrl+Shift+\\** (👍 last).
- **Ctrl+↑/↓** reprints one of your recent messages into the composer
  (falls back to the draft).
- **Ctrl+K** chat switcher, **Alt+Shift+↑/↓** walk unread chats.
- **Ctrl+/** shows all shortcuts.

## Profile & settings

Open via the menu band (top right) → **Profile & security**:

- **Display name** (empty = sign-in name) and an **about** text.
- **Session info**: which session you are in, how old it is, and when you
  last signed in (any method) — shown right under the dialog title.
- **Avatar**: upload a picture; removing it falls back to your
  sign-in picture (from SSO) or the letter chip.
- **Text size** (compact/normal/large) via the menu band menu.
- **Themes** (10 color schemes) via the menu band menu.
- **Devices**: everything signed in via QR, one-tap or login file — with
  platform info and first-connected date. Remove = revoke.
- **Login files**: create/revoke the portable login file for computers
  without a camera (see HOW-TO-LOGIN).
- **Password & 2FA**: only in password sessions (device/SSO sessions
  hide these — sign in with your password to manage them).

## Mobile

- Install as an app (**Install app** on the login screen / menu) — runs
  standalone, with safe-area support on iOS.
- Long-press a message for the action bar; hover actions exist on desktop.
- The layout switches between list and chat pane automatically; the
  back gesture returns from a chat.

## Keyboard reset

Ctrl+Z undoes composer edits natively (wraps included). Ctrl+F in an open
chat focuses its search field.
