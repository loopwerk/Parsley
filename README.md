<p align="center">
  <img src="logo.png" width="400" alt="tag-changelog" />
</p>

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


## Install
Parsley is available via Swift Package Manager and runs on macOS and Linux.

```
.package(url: "https://github.com/loopwerk/Parsley", from: "0.5.0"),
```


## Use as a reader in Saga
Parsley can be used as a reader in the static site generator [Saga](https://github.com/loopwerk/Saga), using [SagaParsleyMarkdownReader](https://github.com/loopwerk/SagaParsleyMarkdownReader).


## Code block titles
Parsley supports adding a title (typically a filename) to fenced code blocks using the `title="..."` syntax:

~~~markdown
```python title="views.py"
def hello():
    print("Hello, World!")
```
~~~

This generates HTML with a `data-title` attribute on the `<pre>` element:

```html
<pre data-title="views.py"><code class="language-python">def hello():
    print("Hello, World!")
</code></pre>
```

You can then use CSS to display the title, for example:

```css
pre[data-title]::before {
  content: attr(data-title);
  display: block;
  background: #1a1a1a;
  padding: 0.5em 1em;
  font-size: 0.85em;
  border-bottom: 1px solid #333;
}
```


## Modifying the generated HTML
Parsley doesn't come with a plugin system, it relies purely on `cmark-gfm` under the hood to render Markdown to HTML. If you want to modify the generated HTML, for example if you want to add `target="blank"` to all external links, [SwiftSoup](https://github.com/scinfu/SwiftSoup) is a great way to achieve this.

Adding a plugin system on top of `cmark` would mean that Parsley could no longer rely on the outstanding output of `cmark`; instead Parsley would have to parse its AST and generate HTML based on that itself, thus reinventing the (very complex) wheel.