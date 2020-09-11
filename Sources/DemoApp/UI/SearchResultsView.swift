import WidgetGUI
import VisualAppBase

public class SearchResultsView: SingleChildWidget {

    @Observable private var query: String

    @Inject private var todoLists: [TodoList]

    public var filteredLists: [TodoList] {

        get {

            todoLists.compactMap {

                let filteredList = $0.filtered(by: query)

                if filteredList.items.count > 0 {

                    return filteredList

                } else {

                    return nil
                }
            }
        }
    }

    public init(query observableQuery: Observable<String>) {
        
        // TODO: this would allow modifying the thing passed as argument from here, maybe better do a one way binding instead
        self._query = observableQuery

        super.init()

        _ = self._query.onChanged { [unowned self] _ in

            invalidateChild()
        }
    }

    override public func buildChild() -> Widget {

        Column(spacing: 48) {

            Text("Results for \"\(query)\"", fontSize: 48, fontWeight: .Bold)

            for list in filteredLists {

                TodoListView(list)
            }
        }
    }
}