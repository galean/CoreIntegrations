import Foundation

public protocol AttestationManagerProtocol {
    var isSupported: Bool { get async }
    func attestKeyId(for serverURL: String) async -> String?
    func generateKey(for serverURL: String, uuid: String) async throws -> AttestKeyGenerationResult
    func createAssertion(for serverURL: String, uuid: String, payload: Data?) async throws -> AttestationManagerResult
    func validateStoredKey(for serverURL: String, uuid: String) async throws -> AttestValidationResult
    func bypass(serverURL: String, key: String, uuid: String) async throws -> AttestBypassResult
}
