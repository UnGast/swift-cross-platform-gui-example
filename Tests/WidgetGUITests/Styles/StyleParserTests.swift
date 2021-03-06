import XCTest
@testable import WidgetGUI

class StyleParserTests: XCTestCase {
  func testSingleBlockParsing() {
    let parser = StyleParser()
    let styles: [Style]? = try? parser.parse("""
    .testClass1 {
      testProperty1: 2.0
    }
    """)
    XCTAssertNotNil(styles)
    XCTAssertEqual(styles!.count, 1)
    XCTAssertEqual(styles![0].properties.count, 1)
    XCTAssertEqual(styles![0].selector, StyleSelector(".testClass1"))
  }

  static var allTests = [
    ("testSingleBlockParsing", testSingleBlockParsing)
  ]
}