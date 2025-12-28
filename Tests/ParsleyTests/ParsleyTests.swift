import XCTest
@testable import Parsley

final class ParsleyTests: XCTestCase {
  func testBare() throws {
    let input = "Hello world"
    let expectedOutput = "<p>Hello world</p>"

    let markdown = try Parsley.parse(input)
    XCTAssertEqual(markdown.title, nil)
    XCTAssertEqual(markdown.body, expectedOutput)
    XCTAssertEqual(markdown.metadata, [:])
  }

  func testTitle() throws {
    let input = """
# Title
Body
Line Two
"""
    let expectedOutput = "<p>Body\nLine Two</p>"

    let markdown = try Parsley.parse(input)
    XCTAssertEqual(markdown.title, "Title")
    XCTAssertEqual(markdown.body, expectedOutput)
    XCTAssertEqual(markdown.metadata, [:])
  }

  func testNoneTitle() throws {
    let input = """
First line
# Title
Body
"""
    let expectedOutput = """
<p>First line</p>
<h1>Title</h1>
<p>Body</p>
"""

    let markdown = try Parsley.parse(input)
    XCTAssertEqual(markdown.title, nil)
    XCTAssertEqual(markdown.body, expectedOutput)
    XCTAssertEqual(markdown.metadata, [:])
  }

  func testTitleNewlines() throws {
    let input = """

# Title

Body
"""
    let expectedOutput = "<p>Body</p>"

    let markdown = try Parsley.parse(input)
    XCTAssertEqual(markdown.title, "Title")
    XCTAssertEqual(markdown.body, expectedOutput)
    XCTAssertEqual(markdown.metadata, [:])
  }

  func testMetadata() throws {
    let input = """
---
author: Kevin
tag: Swift
---
Body
"""
    let expectedOutput = "<p>Body</p>"

    let markdown = try Parsley.parse(input)
    XCTAssertEqual(markdown.title, nil)
    XCTAssertEqual(markdown.body, expectedOutput)
    XCTAssertEqual(markdown.metadata, ["author": "Kevin", "tag": "Swift"])
  }

  func testTitleAndMetadata() throws {
    let input = """
---
author: Kevin
tag: Swift
---
# Title
Body
"""
    let expectedOutput = "<p>Body</p>"

    let markdown = try Parsley.parse(input)
    XCTAssertEqual(markdown.title, "Title")
    XCTAssertEqual(markdown.body, expectedOutput)
    XCTAssertEqual(markdown.metadata, ["author": "Kevin", "tag": "Swift"])
  }

  func testTitleAndMetadataNewline() throws {
    let input = """
---
author: Kevin
tag: Swift
---

# Title
Body
"""
    let expectedOutput = "<p>Body</p>"

    let markdown = try Parsley.parse(input)
    XCTAssertEqual(markdown.title, "Title")
    XCTAssertEqual(markdown.body, expectedOutput)
    XCTAssertEqual(markdown.metadata, ["author": "Kevin", "tag": "Swift"])
  }

  func testOtherFeatures() throws {
    let input = """
Test ~~strike~~ www.example.com kevin@example.com
Newline!
- list
- item
"""
    let expectedOutput = """
<p>Test <del>strike</del> <a href="http://www.example.com">www.example.com</a> <a href="mailto:kevin@example.com">kevin@example.com</a><br />
Newline!</p>
<ul>
<li>list</li>
<li>item</li>
</ul>
"""

    let markdown = try Parsley.parse(input, options: [.safe, .hardBreaks])
    XCTAssertEqual(markdown.title, nil)
    XCTAssertEqual(markdown.body, expectedOutput)
    XCTAssertEqual(markdown.metadata, [:])
  }

  func testFencedCodeBlock() throws {
    let input = """
``` swift
let markdown = try Parsley.parse(input)
```
"""
    let expectedOutput = """
<pre><code class="language-swift">let markdown = try Parsley.parse(input)
</code></pre>
"""

    let markdown = try Parsley.parse(input)
    XCTAssertEqual(markdown.title, nil)
    XCTAssertEqual(markdown.body, expectedOutput)
    XCTAssertEqual(markdown.metadata, [:])
  }

  func testFencedCodeBlockWithTitle() throws {
    let input = """
```python title="views.py"
def test():
    pass
```
"""
    let expectedOutput = """
<pre data-title="views.py"><code class="language-python">def test():
    pass
</code></pre>
"""

    let markdown = try Parsley.parse(input)
    XCTAssertEqual(markdown.body, expectedOutput)
  }

  func testFencedCodeBlockWithTitleAndPath() throws {
    let input = """
```ts title="lib/store.js"
function test() {}
```
"""
    let expectedOutput = """
<pre data-title="lib/store.js"><code class="language-ts">function test() {}
</code></pre>
"""

    let markdown = try Parsley.parse(input)
    XCTAssertEqual(markdown.body, expectedOutput)
  }

  func testFencedCodeBlockWithoutTitle() throws {
    let input = """
```python
def test():
    pass
```
"""
    let expectedOutput = """
<pre><code class="language-python">def test():
    pass
</code></pre>
"""

    let markdown = try Parsley.parse(input)
    XCTAssertEqual(markdown.body, expectedOutput)
  }

  func testSmartQuotesOff() throws {
    let input = """
"test"
"""
    let expectedOutput = "<p>&quot;test&quot;</p>"

    let markdown = try Parsley.parse(input)
    XCTAssertEqual(markdown.title, nil)
    XCTAssertEqual(markdown.body, expectedOutput)
    XCTAssertEqual(markdown.metadata, [:])
  }

  func testSmartQuotesOn() throws {
    let input = """
"test"
"""
    let expectedOutput = "<p>“test”</p>"

    let markdown = try Parsley.parse(input, options: [.smartQuotes])
    XCTAssertEqual(markdown.title, nil)
    XCTAssertEqual(markdown.body, expectedOutput)
    XCTAssertEqual(markdown.metadata, [:])
  }

  func testSafe() throws {
    let input = "<div>Test</div>"
    let expectedOutput = "<!-- raw HTML omitted -->"

    let markdown = try Parsley.parse(input, options: [.safe])
    XCTAssertEqual(markdown.title, nil)
    XCTAssertEqual(markdown.body, expectedOutput)
    XCTAssertEqual(markdown.metadata, [:])
  }

  func testUnsafe() throws {
    let input = "<div>Test</div>"
    let expectedOutput = "<div>Test</div>"

    let markdown = try Parsley.parse(input, options: [.unsafe])
    XCTAssertEqual(markdown.title, nil)
    XCTAssertEqual(markdown.body, expectedOutput)
    XCTAssertEqual(markdown.metadata, [:])
  }

  static var allTests = [
    ("testBare", testBare),
    ("testTitle", testTitle),
    ("testNoneTitle", testNoneTitle),
    ("testTitleNewlines", testTitleNewlines),
    ("testMetadata", testMetadata),
    ("testTitleAndMetadata", testTitleAndMetadata),
    ("testTitleAndMetadataNewline", testTitleAndMetadataNewline),
    ("testOtherFeatures", testOtherFeatures),
    ("testFencedCodeBlock", testFencedCodeBlock),
    ("testFencedCodeBlockWithTitle", testFencedCodeBlockWithTitle),
    ("testFencedCodeBlockWithTitleAndPath", testFencedCodeBlockWithTitleAndPath),
    ("testFencedCodeBlockWithoutTitle", testFencedCodeBlockWithoutTitle),
    ("testSmartQuotesOff", testSmartQuotesOff),
    ("testSmartQuotesOn", testSmartQuotesOn),
    ("testSafe", testSafe),
    ("testUnsafe", testUnsafe),
  ]
}
