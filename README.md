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

let document = try Parsley.parse(input)
print(document.title) // Hello World
print(document.body) // <p>This is the body</p>
print(document.metadata) // ["author": "Kevin", "tags": "Swift, Parsley"]
```


## Use as a reader in Saga
Parsley can be used as a reader in the static site generator [Saga](https://github.com/loopwerk/Saga), using [SagaParsleyMarkdownReader](https://github.com/loopwerk/SagaParsleyMarkdownReader).


## Modifying the generated HTML
Parsley doesn't come with a plugin system, it relies purely on `cmark-gfm` under the hood to render Markdown to HTML. If you want to modify the generated HTML, for example if you want to add `target="blank"` to all external links, [SwiftSoup](https://github.com/scinfu/SwiftSoup) is a great way to achieve this.

Adding a plugin system on top of `cmark` would mean that Parsley could no longer rely on the outstanding output of `cmark`; instead Parsley would have to parse its AST and generate HTML based on that itself, thus reinventing the (very complex) wheel.