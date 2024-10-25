
public protocol AttestationManagerProtocol {
    var isSupported: Bool { get async }
    func attestKeyId(for serverURL: String) async -> String?
    func generateKey(for serverURL: String) async throws -> AttestKeyGenerationResult
    func createAssertion(for serverURL: String) async throws -> AttestationManagerResult
    func validateStoredKey(for serverURL: String) async throws -> AttestValidationResult
    func bypass(serverURL: String, key: String) async throws -> AttestBypassResult
}
