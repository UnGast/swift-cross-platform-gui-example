import XCTest
@testable import WidgetGUI
@testable 
class BuildTests: XCTestCase {
  func testInvalidationWithMutableProperty() {
    let property = MutableProperty<String>()
    let widget = Build(property) {
      if property.hasValue {
        MockLeafWidget()
      } else {
        MockLeafWidget()
      }
    }
    let root = MockRoot(rootWidget: widget)
    var onBuildInvalidatedCallCount = 0 
    _ = widget.onBuildInvalidated {
      onBuildInvalidatedCallCount += 1
    }
    property.value = "test1"
    XCTAssertEqual(onBuildInvalidatedCallCount, 1)
    root.tick()
    property.value = "test2"
    XCTAssertEqual(onBuildInvalidatedCallCount, 2)
  }

  static var allTests = [
    ("testInvalidationWithMutableProperty", testInvalidationWithMutableProperty)
  ]
}