/*
* Copyright (c) 2015 Razeware LLC
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*/

import UIKit
import UIKit.UIGestureRecognizerSubclass

class CircleGestureRecognizer: UIGestureRecognizer {

  private var touchedPoints = [CGPoint]() // point history
  var fitResult = CircleResult() // information about how circle-like is the path
  var tolerance: CGFloat = 0.2 // circle wiggle room
  var isCircle = false
  var path = CGMutablePath() // running CGPath - helps with drawing
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
    super.touchesBegan(touches, with: event)
    if touches.count != 1 {
      state = .failed
    }
    state = .began

    let window = view?.window
    if let loc = touches.first?.location(in: window) {
      path.move(to: .init(x: loc.x, y: loc.y))
    }
  }
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
    super.touchesEnded(touches, with: event)

    // now that the user has stopped touching, figure out if the path was a circle
    fitResult = fitCircle(points: touchedPoints)

    // make sure there are no points in the middle of the circle
    let hasInside = anyPointsInTheMiddle()

    let percentOverlap = calculateBoundingOverlap()
    isCircle = fitResult.error <= tolerance && !hasInside && percentOverlap > (1-tolerance)

    state = isCircle ? .ended : .failed
  }

  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
    super.touchesMoved(touches, with: event)
    
    // 1
    if state == .failed {
      return
    }

    // 2
    let window = view?.window
    if let  loc = touches.first?.location(in: window) {
      // 3
      touchedPoints.append(loc)
      path.addLine(to: .init(x: loc.x, y: loc.y))
      
      // 4
      state = .changed
    }
  }

  override func reset() {
    super.reset()
    touchedPoints.removeAll(keepingCapacity: true)
    path = CGMutablePath()
    isCircle = false
    state = .possible
  }

  private func anyPointsInTheMiddle() -> Bool {
    // 1
    let fitInnerRadius = fitResult.radius / sqrt(2) * tolerance
    // 2
    let innerBox = CGRect(
      x: fitResult.center.x - fitInnerRadius,
      y: fitResult.center.y - fitInnerRadius,
      width: 2 * fitInnerRadius,
      height: 2 * fitInnerRadius)

    // 3
    var hasInside = false
    for point in touchedPoints {
      if innerBox.contains(point) {
        hasInside = true
        break
      }
    }
    
    return hasInside
  }

  private func calculateBoundingOverlap() -> CGFloat {
    // 1
    let fitBoundingBox = CGRect(
      x: fitResult.center.x - fitResult.radius,
      y: fitResult.center.y - fitResult.radius,
      width: 2 * fitResult.radius,
      height: 2 * fitResult.radius)
    let pathBoundingBox = path.boundingBox

    // 2
    let overlapRect = fitBoundingBox.intersection(pathBoundingBox)
//    let overlapRect = fitBoundingBox.rectByIntersecting(pathBoundingBox)

    // 3
    let overlapRectArea = overlapRect.width * overlapRect.height
    let circleBoxArea = fitBoundingBox.height * fitBoundingBox.width

    let percentOverlap = overlapRectArea / circleBoxArea
    return percentOverlap
  }

  override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
    super.touchesCancelled(touches, with: event)
    state = .cancelled
  }

}

