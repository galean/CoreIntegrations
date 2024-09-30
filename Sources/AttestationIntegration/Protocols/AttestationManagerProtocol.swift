
public protocol AttestationManagerProtocol {
    var isSupported: Bool { get async }
    var attestKeyId: String? { get async }
    func generateKey() async throws -> AttestKeyGenerationResult
    func createAssertion() async throws -> AttestationManagerResult
    func validateStoredKey() async throws -> AttestValidationResult
    func bypass() async throws -> AttestBypassResult
}
