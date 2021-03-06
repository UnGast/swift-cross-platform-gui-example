extension Widget {

    public final func findParent(_ condition: (_ parent: Parent) throws -> Bool) rethrows -> Parent? {
        var parent: Parent? = self.parent

        while parent != nil {
            if try condition(parent!) {
                return parent
            }

            if let currentParent = parent as? Widget {
                parent = currentParent.parent
            }
        } 

        return nil
    }

    public final func getParent<T>(ofType type: T.Type) -> T? {
        let parents = getParents(ofType: type)
        return parents.count > 0 ? parents[0] : nil
    }

    /// - Returns: all parents of given type, sorted from nearest to farthest
    public final func getParents<T>(ofType type: T.Type) -> [T] {
        var selectedParents = [T]()
        var currentParent: Parent? = self.parent

        while currentParent != nil {
            if let parent = currentParent as? T {
                selectedParents.append(parent)
            }
            
            if let childParent = currentParent! as? Child {
                currentParent = childParent.parent

            } else {
                break
            }
        }

        return selectedParents
    }

    // TODO: might need possibility to return all of type + a method that only returns first + in what order depth first / breadth first
    public final func getChild<W: Widget>(ofType type: W.Type) -> W? {
        for child in children {
            if let child = child as? W {
                return child
            }
        }
        
        for child in children {
            if let result = child.getChild(ofType: type) {
                return result
            }
        }

        return nil
    }

    /**
    Get a child at any depth where the given condition is true. Depth first.
    */
    public final func getChild(where condition: (_ child: Widget) -> Bool) -> Widget? {
        for child in children {
            if condition(child) {
                return child
            } else if let result = child.getChild(where: condition) {
                return result
            }
        }

        return nil
    }
}
