
public protocol AttestationManagerProtocol {
    var isSupported: Bool { get async }
    var attestKeyId: String? { get async }
    func generateKey() async throws -> String
    func createAssertion() async throws -> AttestationManagerResult
    func validateStoredKey() async throws -> Bool
    func bypass() async throws -> Bool
}
