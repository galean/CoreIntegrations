
public protocol AttestationDataSource {
    associatedtype AttestationData: AttestationProtocol
}
extension AttestationDataSource {
    var serverPath: String {
        return AttestationData.attest_server_path.rawValue
    }
    var bypassKey: String {
        return AttestationData.bypass_key.rawValue
    }
}
