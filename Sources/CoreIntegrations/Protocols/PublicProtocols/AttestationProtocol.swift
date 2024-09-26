
public protocol AttestationProtocol: RawRepresentable where RawValue == String {
    static var attest_server_path: Self { get }
    static var bypass_key: Self { get }
}
