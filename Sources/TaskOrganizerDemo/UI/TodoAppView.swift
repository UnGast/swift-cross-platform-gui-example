import ReactiveProperties
import SwiftGUI

public class TodoAppView: ComposedWidget {
  public enum Mode {
    case SelectedList, Search
  }

  @Inject
  private var todoStore: TodoStore

  @Inject
  private var searchStore: SearchStore

  @Inject
  private var navigationStore: NavigationStore

  /*private var todoLists: [TodoList] {
    store.state.lists
  }*/

  @Reference
  private var activeViewTopSpace: Space

  /*@MutableProperty
  private var mode: Mode = .SelectedList*/

  @MutableComputedProperty
  private var mainViewRoute: MainViewRoute

  @MutableComputedProperty
  private var searchQuery: String

  override public init() {
    super.init()
    _ = onDependenciesInjected { [unowned self] _ in
      _mainViewRoute.reinit(
        compute: {
          navigationStore.state.mainViewRoute
        },
        apply: {
          navigationStore.commit(.updateMainViewRoute($0))
        }, dependencies: [navigationStore.$state])

      _searchQuery.reinit(
        compute: {
          searchStore.state.searchQuery
        },
        apply: {
          print("APPLY SEARCH QUERY", $0)
          searchStore.dispatch(.updateResults($0))
        }, dependencies: [searchStore.$state])

      _ = _searchQuery.onChanged { _ in
        if searchQuery.isEmpty {
          switch mainViewRoute {
          case .searchResults:
            mainViewRoute = navigationStore.state.previousMainViewRoute ?? .none 
          default:
            break
          }
        } else {
          switch mainViewRoute {
          case .searchResults:
            break
          default:
            mainViewRoute = .searchResults
          }
        }
      }
    }
  }

  override public func performBuild() {
    rootChild = Container().with(styleProperties: {
      ($0.background, AppTheme.backgroundColor)
    }).withContent { [unowned self] in
      buildMenu()
      buildActiveView()
    }
  }

  private func buildMenu() -> Widget {
    Container().with(styleProperties: {
      ($0.layout, SimpleLinearLayout.self)
      ($0.width, 250)
      (SimpleLinearLayout.ChildKeys.alignSelf, SimpleLinearLayout.Align.stretch)
      (SimpleLinearLayout.ParentKeys.direction, SimpleLinearLayout.Direction.column)
    }).withContent { [unowned self] in
      buildSearch()

      Container().with(styleProperties: {
        ($0.padding, 32)
      }).withContent {
        Button().with(classes: ["button"]).withContent {
          Text("New List")
        }.onClick { [unowned self] in
          handleNewListClick()
        }
      }

      List(
        ComputedProperty(
          compute: {
            todoStore.state.lists
          }, dependencies: [todoStore.$state])
      ).with(styleProperties: {
        ($0.overflowY, Overflow.scroll)
        (SimpleLinearLayout.ChildKeys.alignSelf, SimpleLinearLayout.Align.stretch)
        (SimpleLinearLayout.ChildKeys.shrink, 1.0)
        ($0.foreground, Color.white)
      }).withContent {
        $0.itemSlot {
          buildMenuListItem(for: $0)
        }
      }
    }
  }

  private func buildSearch() -> Widget {
    Container().with(styleProperties: {
      ($0.padding, Insets(all: 32))
      (SimpleLinearLayout.ChildKeys.alignSelf, SimpleLinearLayout.Align.stretch)
    }).withContent { [unowned self] in

      TextInput(mutableText: $searchQuery, placeholder: "search").with(styleProperties: { _ in
        (SimpleLinearLayout.ChildKeys.shrink, 1.0)
        (SimpleLinearLayout.ChildKeys.grow, 1.0)
        (SimpleLinearLayout.ChildKeys.margin, Insets(right: 16))
      })

      Button().onClick {
        searchStore.dispatch(.updateResults(""))
      }.withContent {
        MaterialDesignIcon(.close)
      }
    }
  }

  private func buildMenuListItem(for list: TodoList) -> Widget {
    Container().with(
      classes: ["menu-item"],
      styleProperties: {
        ($0.padding, Insets(top: 16, right: 24, bottom: 16, left: 24))
        ($0.borderWidth, BorderWidth(bottom: 1.0))
        ($0.borderColor, AppTheme.listItemDividerColor)
      }
    ).withContent {
      Container().with(styleProperties: {
        ($0.background, list.color)
        ($0.padding, Insets(all: 8))
        (SimpleLinearLayout.ChildKeys.alignSelf, SimpleLinearLayout.Align.center)
      }).withContent {
        Space(.zero)
        //MaterialIcon(.formatListBulletedSquare, color: .white)
      }

      Text(
        styleProperties: {
          (SimpleLinearLayout.ChildKeys.alignSelf, SimpleLinearLayout.Align.center)
          ($0.padding, Insets(left: 8))
        }, list.name
      ).with(classes: ["list-item-name"])
    }.onClick { [unowned self] in
      navigationStore.commit(.updateMainViewRoute(.selectedList(list.id)))
    }
  }

  private func buildActiveView() -> Widget {
    return Container().with(styleProperties: { _ in
      (SimpleLinearLayout.ChildKeys.grow, 1.0)
      (SimpleLinearLayout.ParentKeys.direction, SimpleLinearLayout.Direction.column)
      (SimpleLinearLayout.ChildKeys.alignSelf, SimpleLinearLayout.Align.stretch)
      (SimpleLinearLayout.ParentKeys.justifyContent, SimpleLinearLayout.Justify.center)
    }).withContent { [unowned self] in
      Space(DSize2(0, 0)).connect(ref: $activeViewTopSpace)

      Dynamic($mainViewRoute) {
        switch mainViewRoute {
        case .none:
          Text(
            styleProperties: {
              ($0.foreground, Color.white)
              ($0.fontSize, 24)
              ($0.fontWeight, FontWeight.bold)
              ($0.opacity, 0.5)
              (SimpleLinearLayout.ChildKeys.alignSelf, SimpleLinearLayout.Align.center)
            }, "no list selected")

        case let .selectedList(id):
          TodoListView(listId: StaticProperty(id)).with(styleProperties: {
            ($0.padding, Insets(top: 48, left: 48))
            (SimpleLinearLayout.ChildKeys.alignSelf, SimpleLinearLayout.Align.stretch)
            (SimpleLinearLayout.ChildKeys.grow, 1.0)
            (SimpleLinearLayout.ChildKeys.shrink, 1.0)
          })

        case .searchResults:
          SearchResultsView().with(styleProperties: {
            ($0.padding, Insets(top: 48, left: 48))
            (SimpleLinearLayout.ChildKeys.alignSelf, SimpleLinearLayout.Align.stretch)
            (SimpleLinearLayout.ChildKeys.grow, 1.0)
            (SimpleLinearLayout.ChildKeys.shrink, 1.0)
          })
        }
      }
    }
  }

  private func handleNewListClick() {
    todoStore.commit(.AddList)
  }

  override public var style: Style {
    Style("&") {
      FlatTheme(
        primaryColor: AppTheme.primaryColor, secondaryColor: AppTheme.primaryColor,
        backgroundColor: AppTheme.backgroundColor
      ).styles

      Style(".menu-item") {
        ($0.foreground, Color.white)
        ($0.background, Color.transparent)
      }

      Style(".menu-item:hover") {
        ($0.background, AppTheme.primaryColor)
        ($0.foreground, Color.black)
      }
    }
  }
}
