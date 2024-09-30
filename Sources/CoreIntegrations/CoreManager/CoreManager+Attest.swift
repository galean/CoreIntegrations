
import Foundation
#if !COCOAPODS
import AttestationIntegration
#endif

extension CoreManager {
    
    public var attest_isSupported: Bool {
        get async {
            await AttestationManager.shared.isSupported
        }
    }
    
    public var attest_KeyId: String? {
        get async {
            await AttestationManager.shared.attestKeyId
        }
    }
 
    public func attest_generateKey() async throws -> AttestKeyGenerationResult {
       return try await AttestationManager.shared.generateKey()
    }
    
    public func attest_createAssertion() async throws -> AttestationManagerResult {
        return try await AttestationManager.shared.createAssertion()
    }
    
    public func attest_validateStoredKey() async throws -> AttestValidationResult {
        return try await AttestationManager.shared.validateStoredKey()
    }
    
    public func attest_bypass() async throws -> AttestBypassResult {
        return try await AttestationManager.shared.bypass()
    }
    
}
