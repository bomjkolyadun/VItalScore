import Foundation
import HealthKit

/// Base protocol for all health metric fetchers
protocol HealthMetricFetcherProtocol {
    /// Fetches health metrics and returns them via a completion handler
    func fetchMetrics(completion: @escaping ([HealthMetric]) -> Void)
}
