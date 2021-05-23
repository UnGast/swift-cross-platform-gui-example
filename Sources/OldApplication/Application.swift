open class Application {
  public let backend: ApplicationBackend

  public init(backend: ApplicationBackend) {
    self.backend = backend
  }
}