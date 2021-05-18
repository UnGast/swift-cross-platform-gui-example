import GfxMath

public protocol ApplicationBackend {
  func setup()

  func processEvents() throws
  func processEvents(timeout: Double) throws

  func exit()
}