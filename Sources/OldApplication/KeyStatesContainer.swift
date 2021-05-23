public struct KeyStatesContainer {
    private var states: [Key: Bool] = Key.allCases.reduce(into: [Key: Bool]()) {
        $0[$1] = false
    }

    public init() {}

    public subscript(_ key: Key) -> Bool {
        get {
            return states[key]!
        }
        set {
            states[key] = newValue
        }
    }
}