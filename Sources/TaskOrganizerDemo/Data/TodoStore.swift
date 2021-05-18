import VertexGUI
import CXShim

public class TodoStore: Store<TodoStore.State, TodoStore.Mutation, TodoStore.Action> {
  var listsSubscription: AnyCancellable?

  public init() {
    super.init(initialState: State())

    listsSubscription = $state.lists.publisher.sink { [unowned self] _ in
      dispatch(.updateSearchResult(query: state.searchQuery))
    }
  }

  override public func perform(mutation: Mutation, state: SetterProxy) {
    switch mutation {
    case .addTodoList:
      state.lists.append(TodoList(id: state.nextListId, name: "new list", color: .lightBlue, items: []))
      state.nextListId += 1
    case let .updateTodoListName(listId, name):
      for (index, list) in state.lists.enumerated() {
        if list.id == listId {
          state.lists[index].name = name
          break
        }
      }
    case let .addTodoItem(listId):
      state.lists = state.lists.map { 
        if $0.id == listId {
          var updated = $0
          updated.items.append(TodoItem(listId: listId, description: "new item"))
          return updated 
        }
        return $0
      }
    case let .updateTodoItem(updatedItem):
      state.lists = state.lists.map {
        if $0.id == updatedItem.listId {
          var updated = $0
          updated.items = updated.items.map {
            if $0.id == updatedItem.id {
              return updatedItem
            }
            return $0
          }
          return updated
        } 
        return $0
      }
    case let .setSelectedTodoListId(id):
      state.selectedListId = id
    case let .setSearchQuery(query):
      state.searchQuery = query
    case let .setSearchResult(result):
      state.searchResult = result
    case let .setMainViewRoute(route):
      state.previousMainViewRoute = state.mainViewRoute
      state.mainViewRoute = route
    }
  }

  override public func perform(action: Action) -> Future<Void, Error> {
    switch action {
    case let .updateSearchResult(query):
      commit(.setSearchQuery(query))
      commit(.setSearchResult(TodoSearcher.search(query: query, lists: state.lists)))
    }

    return Future { resolve in
      resolve(.success(()))
    }
  }

  public struct State {
    public var mainViewRoute: MainViewRoute = .none
    public var previousMainViewRoute: MainViewRoute = .none

    public var nextListId = 0
    public var lists: [TodoList] = []

    public var selectedListId = -1

    public var searchQuery: String = ""
    public var searchResult: TodoSearchResult? = nil
  }

  public enum Mutation {
    case addTodoList
    case updateTodoListName(listId: Int, name: String)
    case addTodoItem(listId: Int)
    case updateTodoItem(updatedItem: TodoItem)
    case setSelectedTodoListId(Int)
    case setSearchQuery(String)
    case setSearchResult(TodoSearchResult)

    case setMainViewRoute(MainViewRoute)
  }

  public enum Action {
    case updateSearchResult(query: String)
  }
}