# Mutt quick reference

Most-used/relevant keybinds for this setup. Anything not listed here is
stock mutt default (press `?` in any menu to see the full live list).

## Navigation (index & pager)

| Key          | Action                                   |
|--------------|-------------------------------------------|
| `j` / `k`    | next / previous message                   |
| `=` or Home  | jump to newest message (first-entry)      |
| `*` or End   | jump to oldest message (last-entry)       |
| `Ctrl-D`     | pager: scroll down half a page            |
| `Ctrl-D`     | index: delete-thread (whole thread!)      |
| `Ctrl-U`     | pager: scroll up half a page              |
| `Ctrl-U`     | index: undelete-thread                    |
| `Enter`      | open message                              |
| `q`          | leave current menu / mailbox              |
| `?`          | list all keybinds for current menu        |

Mailboxes always open on the newest message (folder-hook forces
`<first-entry>` on open — mutt's own default is "first *unread* message",
which can land on old unread mail instead of the top of the inbox).

## Delete / undelete

| Key    | Action                                          |
|--------|---------------------------------------------------|
| `d`    | delete message under cursor (not gone till sync) |
| `u`    | undelete message under cursor                    |
| `U`    | undelete messages matching a pattern             |

## Multi-select (tag) and bulk actions

| Key          | Action                                              |
|--------------|-------------------------------------------------------|
| `t`          | tag/untag message under cursor (moves to next)       |
| `T`          | tag by pattern, e.g. `T~N<enter>` tags all new mail  |
| `;<cmd>`     | apply next command to every tagged message           |
| `;d`         | delete all tagged messages                            |
| `;;s<mbox>`  | move all tagged messages to a mailbox                 |

Tag what you want with `t`/`T`, then `;` + the normal single-message key.

## Reply / compose

| Key  | Action           |
|------|------------------|
| `m`  | compose new mail |
| `r`  | reply            |
| `g`  | group-reply (reply-all) |
| `f`  | forward message  |

## Switch account/mailbox

| Key   | Account       |
|-------|----------------|
| `F2`  | gmail example |
| `F3`  | generic example |

Add one `F<n>` macro per `account.<name>` file for your own accounts.
Each syncs and saves the current mailbox before switching.

## Misc

| Key       | Action                                       |
|-----------|-----------------------------------------------|
| `Ctrl-R`  | mark all messages as read                     |
| `C`       | copy message to another mailbox               |
| `M`       | move message to another mailbox               |
| `Ctrl-B`  | extract URLs from message with urlview        |
