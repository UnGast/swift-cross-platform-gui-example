import GfxMath
import CXShim

public class SimpleLinearLayout: Layout {
  @LayoutProperty(\.$direction)
  var direction: Direction

  @LayoutProperty(\.$alignContent)
  var alignContent: Align

  @LayoutProperty(\.$justifyContent)
  var justifyContent: Justify

  var axisIndices: (primaryAxisIndex: Int, secondaryAxisIndex: Int) {
    switch direction {
    case .row:
      return (0, 1)
    case .column:
      return (1, 0)
    }
  }

  var childrenPropertySubscription: AnyCancellable?

  func invalidateLayout() {
    container.invalidateLayout()
  }

  override public func setupChildrenPropertySubscription() {
    childrenPropertySubscription = Publishers.MergeMany(widgets.flatMap {
      [
        $0.$shrink.publisher.map { $0 as Any }.eraseToAnyPublisher(),
        $0.$grow.publisher.map { $0 as Any }.eraseToAnyPublisher(),
        $0.$alignSelf.publisher.map { $0 as Any }.eraseToAnyPublisher()
      ]
    }).sink { [unowned self] _ in
      invalidateLayout()
    }
  }

  override public func layout(constraints: BoxConstraints) -> DSize2 {
    let (primaryAxisIndex, secondaryAxisIndex) = axisIndices

    var totalGrowWeight = 0.0
    var totalShrinkWeight = 0.0

    // first pass to get preferred sizes, total grow and shrink weights, determine max cross axis size
    var accumulatedSize = DSize2.zero
    for widget in widgets {
      totalGrowWeight += widget.grow
      totalShrinkWeight += widget.shrink

      var widgetConstraints = BoxConstraints(minSize: .zero, maxSize: .infinity)
      widgetConstraints.maxSize[secondaryAxisIndex] = constraints.maxSize[secondaryAxisIndex]
      widget.referenceConstraints = widgetConstraints
      widget.layout(constraints: widgetConstraints)

      var widgetPosition = DVec2.zero
      accumulatedSize[primaryAxisIndex] += getWidgetStartMargin(widget, primaryAxisIndex)
      widgetPosition[primaryAxisIndex] = accumulatedSize[primaryAxisIndex]
      widgetPosition[secondaryAxisIndex] = getWidgetStartMargin(widget, secondaryAxisIndex)
      widget.layoutedPosition = widgetPosition

      accumulatedSize[primaryAxisIndex] += widget.layoutedSize[primaryAxisIndex]
      accumulatedSize[primaryAxisIndex] += getWidgetEndMargin(widget, primaryAxisIndex)

      let widgetSecondaryAxisSpan =
        widget.layoutedPosition[secondaryAxisIndex] + widget.layoutedSize[secondaryAxisIndex]
        + getWidgetEndMargin(widget, secondaryAxisIndex)
      if widgetSecondaryAxisSpan > accumulatedSize[secondaryAxisIndex] {
        accumulatedSize[secondaryAxisIndex] = widgetSecondaryAxisSpan
      }
    }

    var constrainedAccumulatedSize = constraints.constrain(accumulatedSize)

    // resolve cross axis
    var currentPrimaryAxisPosition = 0.0
    for widget in widgets {
      currentPrimaryAxisPosition += getWidgetStartMargin(widget, primaryAxisIndex)
      widget.layoutedPosition[primaryAxisIndex] = currentPrimaryAxisPosition

      var needRelayout = false
      var widgetConstraints = BoxConstraints(minSize: .zero, maxSize: .infinity)
      widgetConstraints.maxSize[secondaryAxisIndex] = constraints.maxSize[secondaryAxisIndex]

      // TODO: implement property definitions forwarding to children!
      switch widget.alignSelf ?? alignContent {
      case .start:
        widget.layoutedPosition[secondaryAxisIndex] = getWidgetStartMargin(widget, secondaryAxisIndex)

      case .center:
        let centerArea =
          constrainedAccumulatedSize[secondaryAxisIndex]
          - getWidgetStartMargin(widget, secondaryAxisIndex)
          - getWidgetEndMargin(widget, secondaryAxisIndex)
        widget.layoutedPosition[secondaryAxisIndex] =
          centerArea / 2 - widget.layoutedSize[secondaryAxisIndex] / 2
          + getWidgetStartMargin(widget, secondaryAxisIndex)

      case .end:
        widget.layoutedPosition[secondaryAxisIndex] =
          constrainedAccumulatedSize[secondaryAxisIndex] - widget.layoutedSize[secondaryAxisIndex]
          - getWidgetEndMargin(widget, secondaryAxisIndex)

      case .stretch:
        needRelayout = true
        widgetConstraints.minSize[secondaryAxisIndex] =
          constrainedAccumulatedSize[secondaryAxisIndex]
        widgetConstraints.maxSize[primaryAxisIndex] = widget.layoutedSize[primaryAxisIndex]

        widget.referenceConstraints!.minSize[secondaryAxisIndex] = constrainedAccumulatedSize[secondaryAxisIndex]
      }

      if needRelayout {
        widget.layout(constraints: widgetConstraints)
      }

      currentPrimaryAxisPosition += widget.layoutedSize[primaryAxisIndex]
      currentPrimaryAxisPosition += getWidgetEndMargin(widget, primaryAxisIndex)
    }

    accumulatedSize[primaryAxisIndex] = currentPrimaryAxisPosition
    constrainedAccumulatedSize = constraints.constrain(accumulatedSize)
    var deltaAccumulatedSize = constrainedAccumulatedSize - accumulatedSize

    // resolve main axis
    currentPrimaryAxisPosition = 0
    for widget in widgets {
      currentPrimaryAxisPosition += getWidgetStartMargin(widget, primaryAxisIndex)
      widget.layoutedPosition[primaryAxisIndex] = currentPrimaryAxisPosition

      let growWeight = widget.grow
      if deltaAccumulatedSize[primaryAxisIndex] > 0 && growWeight > 0 {
        let relativeGrowWeight = growWeight / totalGrowWeight
        let primaryAxisGrowSpace = deltaAccumulatedSize[primaryAxisIndex] * relativeGrowWeight
        var targetSize = DSize2.zero
        targetSize[primaryAxisIndex] = widget.layoutedSize[primaryAxisIndex] + primaryAxisGrowSpace
        targetSize[secondaryAxisIndex] = widget.layoutedSize[secondaryAxisIndex]
        let widgetConstraints = BoxConstraints(size: targetSize)
        widget.layout(constraints: widgetConstraints)
      }

      let shrinkWeight = widget.shrink
      if deltaAccumulatedSize[primaryAxisIndex] < 0 && shrinkWeight > 0 {
        let relativeShrinkWeight = shrinkWeight / totalShrinkWeight
        let primaryAxisShrinkSpace = deltaAccumulatedSize[primaryAxisIndex] * relativeShrinkWeight
        var targetSize = DSize2.zero
        targetSize[primaryAxisIndex] = widget.layoutedSize[primaryAxisIndex] + primaryAxisShrinkSpace
        targetSize[secondaryAxisIndex] = widget.layoutedSize[secondaryAxisIndex]
        let widgetConstraints = BoxConstraints(size: targetSize)
        widget.layout(constraints: widgetConstraints)

        widget.referenceConstraints!.maxSize[primaryAxisIndex] = targetSize[primaryAxisIndex]
      }

      currentPrimaryAxisPosition += widget.layoutedSize[primaryAxisIndex]
      currentPrimaryAxisPosition += getWidgetEndMargin(widget, primaryAxisIndex)
    }

    accumulatedSize[primaryAxisIndex] = currentPrimaryAxisPosition
    constrainedAccumulatedSize = constraints.constrain(accumulatedSize)
    deltaAccumulatedSize = constrainedAccumulatedSize - accumulatedSize

    // apply justify content
    if deltaAccumulatedSize[primaryAxisIndex] > 0 {
      switch justifyContent {
      case .start:
        break
      case .center:
        let mainAxisStartEndSpace = deltaAccumulatedSize[primaryAxisIndex] / 2
        for widget in widgets {
          widget.layoutedPosition[primaryAxisIndex] += mainAxisStartEndSpace
        }
      case .end:
        for widget in widgets {
          widget.layoutedPosition[primaryAxisIndex] += deltaAccumulatedSize[primaryAxisIndex]
        }
      }
    }

    return accumulatedSize
  }

  func getWidgetStartMargin(_ widget: Widget, _ axis: Int) -> Double {
    if axis == 0 {
      return widget.margin.left
    } else {
      return widget.margin.top
    }
  }

  func getWidgetEndMargin(_ widget: Widget, _ axis: Int) -> Double {
    if axis == 0 {
      return widget.margin.right
    } else {
      return widget.margin.bottom
    }
  }

  public enum Direction {
    case row, column
  }

  public enum Align {
    case start, center, end, stretch
  }

  public enum Justify {
    case start, center, end
  }
}
