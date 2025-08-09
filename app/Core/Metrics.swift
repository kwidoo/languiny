import Foundation

/// Records the last N timing samples and computes averages.
final class RollingMetrics {
    private var samples: [Double] = []
    private let capacity: Int
    init(capacity: Int) { self.capacity = capacity }

    /// Add a new measurement in milliseconds.
    func record(_ value: Double) {
        samples.append(value)
        if samples.count > capacity { samples.removeFirst(samples.count - capacity) }
    }

    /// Compute the average of recorded samples.
    func average() -> Double {
        guard !samples.isEmpty else { return 0 }
        return samples.reduce(0, +) / Double(samples.count)
    }
}
