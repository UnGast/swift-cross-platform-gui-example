import GfxMath

public protocol WindowInputEvent {
}

public struct WindowMouseMoveEvent: WindowInputEvent {
  public var position: DVec2
  public var positionDelta: DVec2
  
  public init(position: DVec2, positionDelta: DVec2) {
    self.position = position
    self.positionDelta = positionDelta
  }
}

public struct WindowMouseButtonDownEvent: WindowInputEvent {
  public var button: MouseButton

  public init(button: MouseButton) {
    self.button = button
  }
}

public struct WindowMouseButtonUpEvent: WindowInputEvent {
  public var button: MouseButton

  public init(button: MouseButton) {
    self.button = button
  }
}

public struct WindowKeyDownEvent: WindowInputEvent {
  public var key: Key
  public var keyStates: KeyStatesContainer
  public var repetition: Bool

  public init(key: Key, keyStates: KeyStatesContainer, repetition: Bool) {
    self.key = key
    self.keyStates = keyStates
    self.repetition = repetition
  }
}

public struct WindowKeyUpEvent: WindowInputEvent {
  public var key: Key
  public var keyStates: KeyStatesContainer

  public init(key: Key, keyStates: KeyStatesContainer) {
    self.key = key
    self.keyStates = keyStates
  }
}

public struct WindowTextInputEvent: WindowInputEvent {
  public var text: String

  public init(text: String) {
    self.text = text
  }
}