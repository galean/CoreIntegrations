import Network

extension NWInterface.InterfaceType: @retroactive CaseIterable {
    public static var allCases: [NWInterface.InterfaceType] = [
        .other,
        .wifi,
        .cellular,
        .loopback,
        .wiredEthernet
    ]
}

extension NWInterface.InterfaceType: @retroactive CustomStringConvertible {
    public var description: String {
        switch self {
        case .other:
            return "other"
        case .wifi:
            return "wifi"
        case .cellular:
            return "cellular"
        case .loopback:
            return "loopback"
        case .wiredEthernet:
            return "wiredEthernet"
        @unknown default:
            return "unexpected"
        }
    }
}

final class NetworkManager {
    private let queue = DispatchQueue(label: "CoreNetworkConnectivityMonitor")
    private let monitor: NWPathMonitor

    private(set) var isConnected = false
    private(set) var currentConnectionType: NWInterface.InterfaceType?
    
    var internetHandlers: [(Bool) -> Void] = []

    init() {
        monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            self?.isConnected = path.status != .unsatisfied
            self?.currentConnectionType = NWInterface.InterfaceType.allCases.filter { path.usesInterfaceType($0) }.first
            self?.internetHandlers.forEach { handler in
                handler(self?.isConnected ?? false)
            }
        }
    }

    func startMonitoring() {
        isConnected = monitor.currentPath.status != .unsatisfied
        monitor.start(queue: queue)
    }

    func stopMonitoring() {
        internetHandlers.removeAll()
        monitor.cancel()
    }
    
    func monitorInternetChanges(_ completion: @escaping (Bool) -> Void) {
        internetHandlers.append(completion)
        completion(isConnected)
    }
}
