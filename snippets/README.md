# Personal snippets

Blink loads this folder automatically through `snippets/package.json`.

- Add snippets: run `:SnippetEdit` in a file, or `:SnippetEdit lua` for a specific filetype.
- Remove snippets: delete that snippet object from the matching JSON file.
- Override snippets: use the same `prefix` in your personal file; personal snippets are loaded before `friendly-snippets`.
- Check if a prefix exists in your personal snippets: `:SnippetCheck rafc`.
- Edit the language index: `:SnippetPackage`.

Snippet shape:

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

After editing snippets, restart Neovim or run `:Lazy reload blink.cmp`.
