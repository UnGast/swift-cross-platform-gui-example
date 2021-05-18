import VertexGUI
import Dispatch
import CXShim

public class TodoAppView: ContentfulWidget {
  public enum Mode {
    case SelectedList, Search
  }

  @Inject private var store: TodoStore
  @Reference private var activeViewTopSpace: Space

  @State private var searchQuery: String = ""
  private var searchQuerySubscription: AnyCancellable?
  private var storeSearchQuerySubscription: AnyCancellable?

  override public init() {
    super.init()
    _ = onDependenciesInjected { [unowned self] _ in
      storeSearchQuerySubscription = store.$state.searchQuery.publisher.sink {
        searchQuery = $0
      }

      searchQuerySubscription = $searchQuery.publisher
        .debounce(for: .seconds(0.5), scheduler: CXWrappers.DispatchQueue(wrapping: DispatchQueue.main))
        .removeDuplicates().sink {
          store.dispatch(.updateSearchResult(query: $0))
          if $0.isEmpty {
            switch store.state.mainViewRoute {
            case .searchResults:
              store.commit(.setMainViewRoute(store.state.previousMainViewRoute))
            default:
              break
            }
          } else {
            switch store.state.mainViewRoute {
            case .searchResults:
              break
            default:
              store.commit(.setMainViewRoute(.searchResults))
            }
          }
        }
    }
  }

  @DirectContentBuilder override public var content: DirectContent {
    Container().withContent { [unowned self] in
      buildMenu()
      buildActiveView()
    }
  }

  private func buildMenu() -> Widget {
    Container().with(classes: ["menu"]).withContent { [unowned self] in
      buildSearch()

      Container().with(classes: ["padded-container"]).withContent {
        Button().with(classes: ["button"]).withContent {
          Text("New List")
        }.onClick { [unowned self] in
          store.commit(.addTodoList)
        }
      }

      List(items: store.$state.lists.immutable).with(classes: ["menu-item-list"]).withContent {
        $0.itemSlot {
          buildMenuListItem(for: $0)
        }
      }
    }
  }

  private func buildSearch() -> Widget {
    Container().with(classes: ["padded-container", "search-container"]).withContent { [unowned self] in
      TextInput(text: $searchQuery.mutable, placeholder: "search").with(classes: ["search-input"])

      Button().onClick {
        store.commit(.setMainViewRoute(store.state.previousMainViewRoute))
      }.withContent {
        MaterialDesignIcon(.close)
      }
    }
  }

  private func buildMenuListItem(for list: TodoList) -> Widget {
    Container().with(classes: ["menu-item"]).withContent {
      Container().with(styleProperties: {
        (\.$background, list.color)
        (\.$padding, Insets(all: 8))
        (\.$alignSelf, .center)
      }).withContent {
        Space(.zero)
      }

      Text(list.name).with(classes: ["list-item-name"])
    }.onClick { [unowned self] in
      store.commit(.setSelectedTodoListId(list.id))
      if store.state.mainViewRoute != .selectedList {
        store.commit(.setMainViewRoute(.selectedList))
      }
    }
  }

  private func buildActiveView() -> Widget {
    return Container().with(classes: ["active-view-container"]).withContent { [unowned self] in
      Space(DSize2(0, 0)).connect(ref: $activeViewTopSpace)

      Dynamic(store.$state.mainViewRoute.publisher) {
        switch store.state.mainViewRoute {
        case .none:
          Text("no list selected").with(classes: ["no-active-view-label"])

        case let .selectedList:
          TodoListView(listId: store.$state.selectedListId.immutable).with(classes: ["active-view"])

        case .searchResults:
          SearchResultsView().with(classes: ["active-view"])
        }
      }
    }
  }

  override public var style: Style {
    Style("&") {
      (\.$background, AppTheme.backgroundColor)
    } nested: {
      FlatTheme(
        primaryColor: AppTheme.primaryColor, secondaryColor: AppTheme.primaryColor,
        backgroundColor: AppTheme.backgroundColor
      ).styles

      Style(".menu", Container.self) {
        (\.$alignSelf, .stretch)
        (\.$direction, .column)
        (\.$width, 250)
      }

      Style(".padded-container") {
        (\.$padding, Insets(all: 32))
      }

      Style(".search-container") {
        (\.$alignSelf, .stretch)
      }

      Style(".search-input") {
        (\.$shrink, 1.0)
        (\.$grow, 1.0)
        (\.$margin, Insets(right: 16))
      }

      Style(".menu-item-list") {
        (\.$overflowY, .scroll)
        (\.$alignSelf, .stretch)
        (\.$shrink, 1)
      }

      Style(".menu-item") {
        (\.$foreground, .white)
        (\.$background, .transparent)
        (\.$padding, Insets(top: 16, right: 24, bottom: 16, left: 24))
        (\.$borderWidth, BorderWidth(bottom: 1.0))
        (\.$borderColor, AppTheme.listItemDividerColor)
      }

      Style(".menu-item:hover") {
        (\.$background, AppTheme.primaryColor)
        (\.$foreground, .black)
      }

      Style(".list-item-name") {
        (\.$alignSelf, .center)
        (\.$padding, Insets(left: 8))
      }

      Style(".active-view-container", Container.self) {
        (\.$grow, 1)
        (\.$direction, .column)
        (\.$alignSelf, .stretch)
        (\.$justifyContent, .center)
      }

      Style(".active-view") {
        (\.$padding, Insets(top: 48, left: 48))
        (\.$alignSelf, .stretch)
        (\.$grow, 1)
        (\.$shrink, 1)
      }

      Style(".no-active-view-label") {
        (\.$foreground, .white)
        (\.$fontSize, 24)
        (\.$fontWeight, .bold)
        (\.$opacity, 0.5)
        (\.$alignSelf, .center)
      }
    }
  }
}
