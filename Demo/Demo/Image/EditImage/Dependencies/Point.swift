import Foundation

public struct Point {
    let currentPoint: CGPoint
    let lastPoint: CGPoint
    
    public init(currentPoint: CGPoint, lastPoint: CGPoint) {
        self.currentPoint = currentPoint
        self.lastPoint = lastPoint
    }
}
