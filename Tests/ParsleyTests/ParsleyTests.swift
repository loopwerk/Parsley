@testable import Parsley
import XCTest

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

  func testFencedCodeBlockWithTitleContainingDashes() throws {
    let input = """
    ```nginx title="/etc/nginx/sites-enabled/deploy.example.com"
    server {
        listen 80;
    }
    ```
    """
    let expectedOutput = """
    <pre data-title="/etc/nginx/sites-enabled/deploy.example.com"><code class="language-nginx">server {
        listen 80;
    }
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

  // MARK: - Markdown Attributes

  func testCodeFenceWithAttributes() throws {
    let input = """
    ```python {title="views.py"}
    def test():
        pass
    ```
    """
    let expectedOutput = """
    <pre title="views.py"><code class="language-python">def test():
        pass
    </code></pre>
    """

    let markdown = try Parsley.parse(input)
    XCTAssertEqual(markdown.body, expectedOutput)
  }

  func testCodeFenceWithClassAttribute() throws {
    let input = """
    ```python {.highlight}
    def test():
        pass
    ```
    """
    let expectedOutput = """
    <pre class="highlight"><code class="language-python">def test():
        pass
    </code></pre>
    """

    let markdown = try Parsley.parse(input)
    XCTAssertEqual(markdown.body, expectedOutput)
  }

  func testCodeFenceWithMultipleAttributes() throws {
    let input = """
    ```python {.highlight #example title="views.py"}
    def test():
        pass
    ```
    """
    let expectedOutput = """
    <pre class="highlight" id="example" title="views.py"><code class="language-python">def test():
        pass
    </code></pre>
    """

    let markdown = try Parsley.parse(input)
    XCTAssertEqual(markdown.body, expectedOutput)
  }

  func testHeadingWithClass() throws {
    let input = "## Title {.special}"
    let expectedOutput = "<h2 class=\"special\">Title</h2>"

    let result = try Parsley.html(input, options: [.markdownAttributes])
    XCTAssertEqual(result.trimmingCharacters(in: .newlines), expectedOutput)
  }

  func testHeadingWithIdAndClass() throws {
    let input = "## Title {.special #my-heading}"
    let expectedOutput = "<h2 class=\"special\" id=\"my-heading\">Title</h2>"

    let result = try Parsley.html(input, options: [.markdownAttributes])
    XCTAssertEqual(result.trimmingCharacters(in: .newlines), expectedOutput)
  }

  func testHeadingWithKeyValue() throws {
    let input = "## Title {data-section=\"intro\"}"
    let expectedOutput = "<h2 data-section=\"intro\">Title</h2>"

    let result = try Parsley.html(input, options: [.markdownAttributes])
    XCTAssertEqual(result.trimmingCharacters(in: .newlines), expectedOutput)
  }

  func testInlineAttributesNotProcessed() throws {
    let input = "Some text {.highlight}"
    let expectedOutput = "<p>Some text {.highlight}</p>"

    let result = try Parsley.html(input, options: [.markdownAttributes])
    XCTAssertEqual(result.trimmingCharacters(in: .newlines), expectedOutput)
  }

  func testParagraphWithAttributesNextLine() throws {
    let input = "Some text\n{.highlight}"
    let expectedOutput = "<p class=\"highlight\">Some text</p>"

    let result = try Parsley.html(input, options: [.markdownAttributes])
    XCTAssertEqual(result.trimmingCharacters(in: .newlines), expectedOutput)
  }

  func testStandaloneAttributesParagraph() throws {
    let input = "Some text\n\n{.highlight}"
    let expectedOutput = "<p class=\"highlight\">Some text</p>"

    let result = try Parsley.html(input, options: [.markdownAttributes])
    XCTAssertEqual(result.trimmingCharacters(in: .newlines), expectedOutput)
  }

  func testAttributesInsideCodeBlockNotProcessed() throws {
    let input = """
    ```python
    {.foo}
    ```
    """
    let expectedOutput = """
    <pre><code class="language-python">{.foo}
    </code></pre>
    """

    let markdown = try Parsley.parse(input)
    XCTAssertEqual(markdown.body, expectedOutput)
  }

  func testMultipleClassesOnHeading() throws {
    let input = "## Title {.foo .bar}"
    let expectedOutput = "<h2 class=\"foo bar\">Title</h2>"

    let result = try Parsley.html(input, options: [.markdownAttributes])
    XCTAssertEqual(result.trimmingCharacters(in: .newlines), expectedOutput)
  }

  func testHeadingWithoutAttributesBeforeHeadingWithAttributes() throws {
    let input = "## First\n## Second {.foo}"
    let expectedOutput = "<h2>First</h2>\n<h2 class=\"foo\">Second</h2>"

    let result = try Parsley.html(input, options: [.markdownAttributes])
    XCTAssertEqual(result.trimmingCharacters(in: .newlines), expectedOutput)
  }

  func testCodeFenceWithoutAttributesBeforeCodeFenceWithAttributes() throws {
    let input = """
    ```python
    first()
    ```

    ```python {.highlight}
    second()
    ```
    """
    let expectedOutput = """
    <pre><code class="language-python">first()
    </code></pre>
    <pre class="highlight"><code class="language-python">second()
    </code></pre>
    """

    let markdown = try Parsley.parse(input)
    XCTAssertEqual(markdown.body, expectedOutput)
  }

  func testBlockAttributeWithMultipleParagraphs() throws {
    let input = "First paragraph\n\nSecond paragraph\n{.highlight}"
    let expectedOutput = "<p>First paragraph</p>\n<p class=\"highlight\">Second paragraph</p>"

    let result = try Parsley.html(input, options: [.markdownAttributes])
    XCTAssertEqual(result.trimmingCharacters(in: .newlines), expectedOutput)
  }

  func testHeadingInsideBlockquote() throws {
    let input = "> ## Quoted {.foo}\n\n## Normal {.bar}"
    let expectedOutput = "<blockquote>\n<h2 class=\"foo\">Quoted</h2>\n</blockquote>\n<h2 class=\"bar\">Normal</h2>"

    let result = try Parsley.html(input, options: [.markdownAttributes])
    XCTAssertEqual(result.trimmingCharacters(in: .newlines), expectedOutput)
  }

  func testHeadingInsideBlockquote2() throws {
    let input = "## Normal {.foo}\nParagraph\n\n> ## Quoted {.bar}\n> Paragraph\n\n## Normal {.baz}"
    let expectedOutput = "<h2 class=\"foo\">Normal</h2>\n<p>Paragraph</p>\n<blockquote>\n<h2 class=\"bar\">Quoted</h2>\n<p>Paragraph</p>\n</blockquote>\n<h2 class=\"baz\">Normal</h2>"

    let result = try Parsley.html(input, options: [.markdownAttributes])
    XCTAssertEqual(result.trimmingCharacters(in: .newlines), expectedOutput)
  }

  func testAttributesAfterBlockquote() throws {
    let input = "> ## Quoted {.foo}\n{.bar}"
    let expectedOutput = "<blockquote class=\"bar\">\n<h2 class=\"foo\">Quoted</h2>\n</blockquote>"

    let result = try Parsley.html(input, options: [.markdownAttributes])
    XCTAssertEqual(result.trimmingCharacters(in: .newlines), expectedOutput)
  }

  func testAttributesAfterRawH2() throws {
    let input = "<h2>Foo</h2>\n\n## Bar {.bar}"
    let expectedOutput = "<h2>Foo</h2>\n<h2 class=\"bar\">Bar</h2>"

    let result = try Parsley.html(input, options: [.unsafe, .markdownAttributes])
    XCTAssertEqual(result.trimmingCharacters(in: .newlines), expectedOutput)
  }

  func testAttributesAfterRawH3() throws {
    let input = "<h3 class=\"foo\">Foo</h3>\n\n### Bar {.bar}"
    let expectedOutput = "<h3 class=\"foo\">Foo</h3>\n<h3 class=\"bar\">Bar</h3>"

    let result = try Parsley.html(input, options: [.unsafe, .markdownAttributes])
    XCTAssertEqual(result.trimmingCharacters(in: .newlines), expectedOutput)
  }

  func testClassShorthandMergesWithClassAttribute() throws {
    let input = "## Title {.foo class=\"bar baz\"}"
    let expectedOutput = "<h2 class=\"foo bar baz\">Title</h2>"

    let result = try Parsley.html(input, options: [.markdownAttributes])
    XCTAssertEqual(result.trimmingCharacters(in: .newlines), expectedOutput)
  }

  func testUnquotedKeyValue() throws {
    let input = "## Title {data-section=intro}"
    let expectedOutput = "<h2 data-section=\"intro\">Title</h2>"

    let result = try Parsley.html(input, options: [.markdownAttributes])
    XCTAssertEqual(result.trimmingCharacters(in: .newlines), expectedOutput)
  }

  func testEscapedQuotesInAttributeValue() throws {
    let input = #"## Title {data-attr="value \"7"}"#
    let expectedOutput = "<h2 data-attr=\"value &quot;7\">Title</h2>"

    let result = try Parsley.html(input, options: [.markdownAttributes])
    XCTAssertEqual(result.trimmingCharacters(in: .newlines), expectedOutput)
  }

  func testIdWithColonsAndPeriods() throws {
    let input = "## Title {#my-id:foo.bar}"
    let expectedOutput = "<h2 id=\"my-id:foo.bar\">Title</h2>"

    let result = try Parsley.html(input, options: [.markdownAttributes])
    XCTAssertEqual(result.trimmingCharacters(in: .newlines), expectedOutput)
  }

  func testAttributesAfterRawP() throws {
    let input = "<p>Foo</p>\n\nBar\n{.bar}"
    let expectedOutput = "<p>Foo</p>\n<p class=\"bar\">Bar</p>"

    let result = try Parsley.html(input, options: [.unsafe, .markdownAttributes])
    XCTAssertEqual(result.trimmingCharacters(in: .newlines), expectedOutput)
  }

  func testAttributesAfterList() throws {
    let input = "* Foo\n{.foo}"
    let expectedOutput = "<ul class=\"foo\">\n<li>Foo</li>\n</ul>"

    let result = try Parsley.html(input, options: [.markdownAttributes])
    XCTAssertEqual(result.trimmingCharacters(in: .newlines), expectedOutput)
  }

  func testAttributesAfterListFollowedByParagraph() throws {
    let input = "* Foo\n{.foo}\n\nSome paragraph"
    let expectedOutput = "<ul class=\"foo\">\n<li>Foo</li>\n</ul>\n<p>Some paragraph</p>"

    let result = try Parsley.html(input, options: [.markdownAttributes])
    XCTAssertEqual(result.trimmingCharacters(in: .newlines), expectedOutput)
  }

  func testAttributesAfterHorizontalRule() throws {
    let input = "Some text\n\n---\n{.divider}"
    let expectedOutput = "<p>Some text</p>\n<hr class=\"divider\" />"

    let result = try Parsley.html(input, options: [.markdownAttributes])
    XCTAssertEqual(result.trimmingCharacters(in: .newlines), expectedOutput)
  }

  func testAttributesAfterImage() throws {
    let input = "![Alt text](image.png)\n{.hero}"
    let expectedOutput = "<p><img src=\"image.png\" alt=\"Alt text\" class=\"hero\" /></p>"

    let result = try Parsley.html(input, options: [.markdownAttributes])
    XCTAssertEqual(result.trimmingCharacters(in: .newlines), expectedOutput)
  }

  func testAttributesAfterImageWithinParagraph() throws {
    let input = "Some text ![Alt text](image.png)\n{.highlight}"
    let expectedOutput = "<p class=\"highlight\">Some text <img src=\"image.png\" alt=\"Alt text\" /></p>"

    let result = try Parsley.html(input, options: [.markdownAttributes])
    XCTAssertEqual(result.trimmingCharacters(in: .newlines), expectedOutput)
  }
  
  func testAttributesImageInRawParagraph() throws {
    let input = "<p class=\"foo\"><img src=\"bar.jpg\" /></p>"
    let expectedOutput = "<p class=\"foo\"><img src=\"bar.jpg\" /></p>"
    
    let result = try Parsley.html(input, options: .unsafe)
    XCTAssertEqual(result.trimmingCharacters(in: .newlines), expectedOutput)
  }
}
