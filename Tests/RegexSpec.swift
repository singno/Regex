final class RegexSpec: QuickSpec {
  override func spec() {

    describe("Regex") {
      it("is string literal convertible") {
        let regex: Regex = "foo"
        expect(regex).notTo(beNil())
      }

      it("matches with no capture groups") {
        let regex = Regex("now you're matching with regex")
        expect(regex).to(match("now you're matching with regex"))
      }

      it("matches a single capture group") {
        let regex = Regex("foo (bar|baz)")
        expect(regex).to(capture("bar", from: "foo bar"))
      }

      it("matches multiple capture groups") {
        let regex = Regex("foo (bar|baz) (123|456)")
        expect(regex).to(capture("baz", "456", from: "foo baz 456"))
      }

      it("doesn't include the entire match in the list of captures") {
        let regex = Regex("foo (bar|baz)")
        expect(regex).notTo(capture("foo bar", from: "foo bar"))
      }

      it("provides access to the entire matched string") {
        let regex = Regex("foo (bar|baz)")
        expect(regex.match("foo bar")?.matchedString).to(equal("foo bar"))
      }

      it("can match a regex multiple times in the same string") {
        let regex = Regex("(foo)")
        expect(regex.allMatches("foo foo foo").flatMap { $0.captures }.flatMap { $0 }).to(equal(["foo", "foo", "foo"]))
      }

      it("supports the match operator") {
        let matched: Bool

        switch "eat some food" {
        case Regex("foo"):
          matched = true
        default:
          matched = false
        }

        expect(matched).to(beTrue())
      }

      it("supports the match operator in reverse") {
        let matched: Bool

        switch Regex("foo") {
        case "fool me twice":
          matched = true
        default:
          matched = false
        }

        expect(matched).to(beTrue())
      }
    }

    describe("optional capture groups") {
      let regex = Regex("(a)?(b)")

      it("maintains the position of captures regardless of optionality") {
        expect(regex.match("ab")?.captures[1]).to(equal("b"))
        expect(regex.match("b")?.captures[1]).to(equal("b"))
      }

      it("returns nil for an unmatched capture") {
        expect(regex.match("b")?.captures[0]).to(beNil())
      }
    }

    describe("capture ranges") {
      it("correctly converts from the underlying index type") {
        // U+0061 LATIN SMALL LETTER A
        // U+0065 LATIN SMALL LETTER E
        // U+0301 COMBINING ACUTE ACCENT
        // U+221E INFINITY
        // U+1D11E MUSICAL SYMBOL G CLEF
        let string = "\u{61}\u{65}\u{301}\u{221E}\u{1D11E}"
        let infinity = Regex("(\u{221E})").match(string)!.captures[0]!
        let rangeOfInfinity = string.rangeOfString(infinity)!
        let location = string.startIndex.distanceTo(rangeOfInfinity.startIndex)
        let length = rangeOfInfinity.count
        expect(location).to(equal(2))
        expect(length).to(equal(1))
      }
    }

    describe("matching at line anchors") {
      it("can anchor matches to the start of each line") {
        let regex = Regex("(?m)^foo")
        let multilineString = "foo\nbar\nfoo\nbaz"
        expect(regex.allMatches(multilineString).count).to(equal(2))
      }

      it("validates that the example in the README is correct") {
        let totallyUniqueExamples = Regex("^(hello|foo).*$", options: [.IgnoreCase, .AnchorsMatchLines])
        let multilineText = "hello world\ngoodbye world\nFOOBAR\n"
        let matchingLines = totallyUniqueExamples.allMatches(multilineText).map { $0.matchedString }
        expect(matchingLines).to(equal(["hello world", "FOOBAR"]))
      }
    }

  }
}

private func match(string: String) -> NonNilMatcherFunc<Regex> {
  return NonNilMatcherFunc { actual, failureMessage in
    let regex: Regex! = try! actual.evaluate()
    failureMessage.stringValue = "expected <\(regex)> to match <\(string)>"
    return regex.matches(string)
  }
}

private func capture(captures: String..., from string: String) -> NonNilMatcherFunc<Regex> {
  return NonNilMatcherFunc { actual, failureMessage in
    let regex: Regex! = try! actual.evaluate()

    failureMessage.stringValue = "expected <\(regex)> to capture <\(captures)> from <\(string)>"

    for expected in captures {
      guard let match = regex.match(string) where match.captures.contains({ $0 == expected })
      else { return false }
    }

    return true
  }
}

import Quick
import Nimble
import Regex
