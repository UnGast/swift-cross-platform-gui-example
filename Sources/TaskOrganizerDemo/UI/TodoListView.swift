import VertexGUI
import CXShim

public class TodoListView: ContentfulWidget {
  @Inject private var store: TodoStore

  @ImmutableBinding private var listId: Int

  @State private var list: TodoList?

  var listIdSubscription: AnyCancellable?
  var storeListsSubscription: AnyCancellable?

  @State private var editable: Bool
  private var checkable: Bool

  @State private var editingName: Bool = false
  @State private var updatedNameBuffer: String = ""

  public init(listId immutableListId: ImmutableBinding<Int>, editable: Bool = true, checkable: Bool = true) {
    self._listId = immutableListId
    self.editable = editable
    self.checkable = checkable
    super.init()

    _ = onDependenciesInjected { [unowned self] in
      listIdSubscription = $listId.publisher.sink { _ in
        resolveList()
      }

      storeListsSubscription = store.$state.lists.publisher.sink { _ in
        resolveList()
      }
    }
  }

  func resolveList() {
    list = store.state.lists.first { $0.id == listId }
    editingName = false 
  }

  @DirectContentBuilder override public var content: DirectContent {
    Container().with(styleProperties: {
      (\.$direction, .column)
    }).withContent { [unowned self] in

      Container().with(classes: ["header"]).withContent {
        
        Dynamic($editingName.publisher) {
          if editingName {
            TextInput(text: $updatedNameBuffer.mutable, placeholder: "list name").with(classes: ["list-name", "list-name-input"]).with { widget in
              _ = widget.onMounted {
                widget.requestFocus()
              }

              widget.onKeyUp {
                if $0.key == .Return {
                  store.commit(.updateTodoListName(listId: list?.id ?? -1, name: updatedNameBuffer))
                  editingName = false
                }
              }
            }
          } else {
            Text(list?.name ?? "").with(classes: ["list-name"]).onClick {
              if editable {
                editingName = true
                updatedNameBuffer = list?.name ?? ""
              }
            }
          }
        }

        Dynamic($editable.publisher) {
          if editable {
            Button().withContent {
              Text("add todo")
            }.onClick {
              store.commit(.addTodoItem(listId: list!.id))
            }
          }
        }
      }

      List(items: ImmutableBinding($list.immutable, get: { $0?.items ?? [] })).with(classes: ["todo-item-list"]).withContent {
        $0.itemSlot {
          build(todo: $0)
        }
      }
    }
  }

  func build(todo: TodoItem) -> Widget {
    TodoListItemView(todo, editable: editable, checkable: checkable)
  }

  override public var style: Style {
    Style("&") {} nested: {
      Style(".header", Container.self) {
        (\.$alignContent, .center)
        (\.$margin, Insets(bottom: 48))
      }

      Style(".list-name") {
        (\.$foreground, .white)
        (\.$fontWeight, .bold)
        (\.$fontSize, 36)
        (\.$margin, Insets(right: 24))
      }

      Style(".list-name-input") {
        (\.$width, 200)
      }

      Style(".todo-item-list") {
        (\.$alignSelf, .stretch)
        (\.$shrink, 1)
        (\.$overflowY, .scroll)
      }
    }
  }
}
