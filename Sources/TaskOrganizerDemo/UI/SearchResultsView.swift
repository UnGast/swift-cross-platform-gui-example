import VertexGUI

public class SearchResultsView: ContentfulWidget {
  @Inject
  private var store: TodoStore

  @DirectContentBuilder override public var content: DirectContent {
    Container().with(classes: ["lists-container"]).withContent { [unowned self] in

      Dynamic(store.$state.searchResult.publisher) {

        (store.state.searchResult?.filteredLists ?? []).map { list in
          Container().with(classes: ["list"]).withContent {
            buildListHeader(list)

            list.items.map {
              buildSearchResult($0)
            }
          }
        }
      }
    }
  }

  func buildListHeader(_ list: TodoListProtocol) -> Widget {
    Text(list.name).with(classes: ["list-header"])
  }

  func buildSearchResult(_ todoItem: TodoItem) -> Widget {
    TodoListItemView(todoItem).with(classes: ["list-item"])
  }

  override public var style: Style {
    Style("&") {} nested: {
      Style(".lists-container", Container.self) {
        (\.$direction, .column)
        (\.$overflowY, .scroll)
        (\.$alignContent, .stretch)
      }

      Style(".list", Container.self) {
        (\.$direction, .column)
        (\.$margin, Insets(bottom: 64))
        (\.$alignContent, .stretch)
      }

      Style(".list-header") {
        (\.$margin, Insets(bottom: 32))
        (\.$fontWeight, .bold)
        (\.$fontSize, 36.0)
      }
    }
  }
}
