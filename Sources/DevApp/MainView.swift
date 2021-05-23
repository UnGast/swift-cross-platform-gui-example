import VertexGUI
import Swim
import CXShim

public class MainView: ContentfulWidget, SlotAcceptingWidgetProtocol {
  @Inject
  var someInjectedData: String

  @State
  var myState: String = "This is a value from an @State property."
  @State
  var testBackgroundColor: VertexGUI.Color = .orange
  @State
  var testImage: Swim.Image<RGBA, UInt8>

  static let TestSlot1 = Slot(key: "testSlot1", data: Void.self)
  private let testSlot1 = SlotContentManager(MainView.TestSlot1)

  var stateSubscription: AnyCancellable?

  override public init() {
    self.testImage = Swim.Image(width: 800, height: 600, color: Swim.Color(r: 0, g: 0, b: 0, a: 255))
    super.init()
    stateSubscription = self.$myState.sink {
      print("MY STATEA CHANGED", $0)
    }
  }

  @DirectContentBuilder override public var content: DirectContent {
    Container().with(styleProperties: {
      (\.$background, .red)
      (\.$overflowY, .scroll)
    }).withContent { [unowned self] in
   
      Container().withContent {
        ImageView(image: $testImage.immutable).with(styleProperties: {
          (\.$width, 200)
        }).onClick {
          testImage = Swim.Image(width: 800, height: 600, color: Swim.Color(r: 100, g: 0, b: 0, a: 255))
        }

        Container().with(styleProperties: {
          (\.$width, 200)
          (\.$height, 150)
          (\.$background, .black)
        })

        Container().with(styleProperties: {
          (\.$background, .white)
          (\.$width, 150)
          (\.$maxHeight, 120)
          (\.$alignSelf, .stretch)
        }).onClick {
          print("WOW")
        }

        Container().with(styleProperties: {
          (\.$background, .blue)
          (\.$minWidth, 10)
          (\.$minHeight, 10)
          (\.$padding, Insets(all: 128))
          (\.$maxHeight, 30)
        })

        Container().with(styleProperties: {
          (\.$background, .orange)
          (\.$maxWidth, 200)
          (\.$minHeight, 40)
          (\.$grow, 1)
        })

        Container().with(styleProperties: {
          (\.$background, .white)
          (\.$minHeight, 120)
          (\.$minWidth, 10)
          (\.$padding, Insets(all: 128))
          (\.$shrink, 1)
        })
      }



      /*Container().with(styleProperties: {
        (\.$background, .blue)
        (\.$padding, Insets(all: 32))
        (\.$grow, 1)
      })

      Container().with(styleProperties: {
        (\.$background, .yellow)
        (\.$padding, Insets(all: 32))
        (\.$grow, $testGrow.immutable)
      })

      Container().with(classes: ["container-3"])*/

      /*Button().withContent {
        Text("ADD")
      }.onClick {
        items.append("NEW ITEM")
        myState = "The @State property changed!"
        testBackgroundColor = .white
      }

      /*Text(myState).with(styleProperties: {
        (\.$background, .black)
      })*/

      TestWidget(boundText: $myState.immutable).with(styleProperties: {
        (\.$background, $testBackgroundColor.immutable)
      })

      TextInput(mutableText: $text1)

      Container().with(styleProperties: {
        ($0.overflowY, Overflow.scroll)
        (SimpleLinearLayout.ChildKeys.shrink, 1.0)
      }).withContent {
        List($items).withContent {
          $0.itemSlot { item in
            Container().with(styleProperties: {
              ($0.padding, 32.0)
            }).withContent {
              Text(item).with()
            }
          }
        }.with(styleProperties: {
          (\.$background, Color.lightBlue)
          (\.$shrink, 1)
        })
      }*/
    }
  }

  override public var style: Style? {
    Style("&") {} nested: {
      Style(".container-3") {
        (\.$padding, Insets(all: 32))
        (\.$background, .white)
        (\.$grow, 1)
      }

      FlatTheme(primaryColor: .orange, secondaryColor: .blue, backgroundColor: Color(10, 30, 50, 255)).styles
    }
  }
}