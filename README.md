# Parsley

A Markdown parser for Swift Package Manager, using [Github Flavored Markdown](https://github.github.com/gfm/). As such it comes with a bunch of Markdown extensions such as fenced code blocks, tables, strikethrough, hard line breaks and auto links.

Additionally Parsley supports embedded metadata in Markdown documents, and it splits the document title out from the document body.

``` swift
let input = """
---
author: Kevin
tags: Swift, Parsley
---

# Hello World
This is the body
"""

let markdown = try Parsley.parse(input)
print(markdown.title) // Hello World
print(markdown.body) // <p>This is the body</p>
print(markdown.metadata) // ["author": "Kevin", "tags": "Swift, Parsley"]
```
