
public protocol AttestationManagerProtocol {
    var isSupported: Bool { get async }
    var attestKeyId: String? { get async }
    func generateKey() async throws -> String
    func createAssertion() async throws -> AttestationManagerResult
    func validateStoredKey() async throws -> (result: Bool, warning: String?)
    func bypass() async throws -> (result: Bool, warning: String?)
}
