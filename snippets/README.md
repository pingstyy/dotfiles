# Personal snippets

Blink loads only this folder (`friendly-snippets` is disabled).

- Add snippets: `:SnippetEdit` in a file, or `:SnippetEdit lua` for a filetype.
- Remove snippets: delete that object from the matching JSON file.
- Check a prefix: `:SnippetCheck init`
- Edit the language index: `:SnippetPackage`

## Python dunders (clean)

Type the short prefix (or partial `__name`) — no args/kwargs/super boilerplate:

| prefix | expands to |
|--------|------------|
| `init` | `def __init__(self):` |
| `call` | `def __call__(self):` |
| `len` | `def __len__(self):` |
| `repr` / `str` | `__repr__` / `__str__` |
| `enter` / `exit` | context manager pair |
| `iter` / `next` | iterator pair |
| `getitem` / `setitem` / `delitem` | indexing |
| `contains` / `eq` / `hash` | containers / equality |
| `new` / `postinit` / `slots` | less common |

Also: `main`, `def`, `defs`, `class` — all minimal bodies.

## Snippet shape

```json
{
  "display name": {
    "prefix": "trigger",
    "description": "what it inserts",
    "body": [
      "line ${1:first jump}",
      "last cursor goes here ${0}"
    ]
  }
}
```

`prefix` can be a string or a list (`["init", "__init"]`).

After editing snippets, restart Neovim or run `:Lazy reload blink.cmp`.
