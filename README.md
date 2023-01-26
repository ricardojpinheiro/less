# less
All of my painful attempts to develop a pager for MSX, like Unix's less.

## Command-line parameters
 - /d<fg>,<bg>    - Define foreground and background colors.
 - ~~/n             - Use line numbers.~~ (not yet).
 - /h             - Show this help text and exit.
 - /v             - Output version information and exit.

## Keystrokes already created
 - e, j, Ctrl-E, Ctrl-J, ENTER, Down   - Forward  one line (or N lines).
 - d, y, Ctrl-D, Ctrl-Y, Ctrl-P, Up    - Backward one line (or N lines).
 - f, Ctrl-F, Ctrl-V, SPACE, SELECT+Up - Forward  one window.
 - b, Ctrl-B, SELECT+Down              - Backward one window.
 - g, INSERT, SELECT+INSERT            - Begin of the file.
 - i, DELETE, SELECT+DELETE            - End of the file.
 - /pattern                            - Search forward for matching line.
 - ?pattern                            - Search backward for matching line.
 - ~~&pattern                            - Display only matching lines.~~ (not yet).
 - n                                   - Repeat previous search.
 - m                                   - Repeat previous search (reverse).
 - h                                   - Show help.
 - p                                   - Repaint screen.
 - ~~s                                   - Edit the current file with EDITOR.~~ (not yet).
 - v                                   - Print version number of less.
 - q                                   - Exit.

