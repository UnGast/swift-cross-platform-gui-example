import GfxMath
import VisualAppBase
import Drawing

extension DeveloperTools {
  public class WidgetPropertiesView: ContentfulWidget {
    @Inject
    var store: DeveloperTools.Store

    @DirectContentBuilder override public var content: DirectContent {
      Container().withContent { [unowned self] in

        Dynamic(store.$state.inspectedWidget.publisher) {

          if let inspectedWidget = store.state.inspectedWidget {

            Container().with(styleProperties: {
              (\.$grow, 1.0)
              (\.$direction, SimpleLinearLayout.Direction.column)
            }).withContent {

              Text(inspectedWidget.name).with(classes: ["widget-name"])

              Container().with(classes: ["section"]).withContent {
                Text("tree path").with(classes: ["section-heading"])
                Text(String(describing: inspectedWidget.treePath))
              }

              buildStyleProperties(for: inspectedWidget)
              buildMatchedStyles(for: inspectedWidget)
            }
          } else {
            Space(.zero)
          }
        }
      }
    }

    func buildStyleProperties(for widget: Widget) -> Widget {
      var propertyRepresentations = [Widget]()

      let mirror = Mirror(reflecting: widget)
      for child in mirror.allChildren {
        if type(of: child.value) is AnyStylePropertyProtocol.Type, let property = child.value as? AnyStylePropertyProtocol {
          propertyRepresentations.append(buildStyleProperty(child.label ?? "", property))
        }
      }

      return Container().with(classes: ["section"]).with(styleProperties: {
        (\.$direction, .column)
      }).withContent {
        Text("style properties").with(classes: ["section-heading"])

        propertyRepresentations
      }
    }

    func buildStyleProperty(_ name: String, _ property: AnyStylePropertyProtocol) -> Widget {
      Text(name).with(classes: ["key"])
    }

    func buildMatchedStyles(for widget: Widget) -> Widget {
      Container().with(classes: ["section"]).withContent {
        Text("matched styles").with(classes: ["section-heading"])

        widget.matchedStyles.map {
          buildStyleInfo($0)
        }
      }
    }

    func buildStyleInfo(_ style: Style) -> Widget {
      Container().with(classes: ["style-info"]).withContent {
        Text("style: \(style.selector)").with(classes: ["style-identifier"])

        Container().with(classes: ["key-value-item"]).withContent {
          Text("tree path").with(classes: ["key"])
          Text("\(style.treePath)")
        }

        style.propertyValueDefinitions.map { definition in
          Container().with(classes: ["key-value-item"]).withContent {
            Text("\(definition.keyPath)").with(classes: ["key"])
            Text("\(String(describing: definition.value))")
          }
        }
      }
    }

    override public var style: Style {
      Style("&") {
        (\.$background, .white)
        (\.$foreground, .black)
        (\.$padding, Insets(all: 16))
      } nested: {
        Style(".widget-name") {
          (\.$fontSize, 20.0)
          (\.$fontWeight, .bold)
          (\.$margin, Insets(bottom: 16))
        }

        Style(".section", Container.self) {
          (\.$margin, Insets(bottom: 16))
          (\.$direction, .column)
        }

        Style(".section-heading") {
          (\.$fontSize, 16.0)
          (\.$fontWeight, FontWeight.bold)
          (\.$margin, Insets(bottom: 8))
        }

        Style(".key-value-item", Container.self) {
          (\.$margin, Insets(bottom: 8))
          (\.$direction, .row)
        }

        Style(".key") {
          (\.$fontWeight, .bold)
        }

        Style(".style-info", Container.self) {
          (\.$direction, .column)
          (\.$margin, Insets(bottom: 16))
        }

        Style(".style-identifier") {
          (\.$fontWeight, .bold)
          (\.$fontSize, 16.0)
          (\.$margin, Insets(bottom: 8))
        }
      }
    }
  }
}