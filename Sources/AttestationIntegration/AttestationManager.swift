import Foundation
import CryptoKit
import DeviceCheck
import UIKit

public actor AttestationManager:AttestationManagerProtocol {
    static public let shared = AttestationManager()
        
    public var isSupported: Bool {
        get async {
            DCAppAttestService.shared.isSupported
        }
    }
    
    public func attestKeyId(for serverURL: String) async -> String? {
        return UserDefaults.standard.string(forKey: serverURL)
    }
    
    public func generateKey(for serverURL: String, uuid: String) async throws -> AttestKeyGenerationResult {
        let service = DCAppAttestService.shared
        
        if service.isSupported {
            let keyId = try await service.generateKey()
            let clientDataHash =  Data(SHA256.hash(data: uuid.data(using: .utf8)!))
            let attestation = try await service.attestKey(keyId, clientDataHash: clientDataHash)
            let challenge: String = uuid.base64Encoded() ?? uuid
            
            let data = try JSONEncoder().encode(
                [
                    "keyId": keyId,
                    "challenge": challenge,
                    "token": uuid,
                    "attestation": attestation.base64EncodedString(),
                ]
            )

            var request = URLRequest.post(to: serverURL.url(), with: data)
            request.addValue(uuid, forHTTPHeaderField: "tag")
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                let attestWarning = httpResponse.value(forHTTPHeaderField: "x-app-attest-warning")
                let warningDict = attestWarning?.toDictionary()
                
                switch httpResponse.statusCode {
                    
                case 200, 201, 204:
                    UserDefaults.standard.set(keyId, forKey: serverURL)
                    return AttestKeyGenerationResult(key: keyId, warning: warningDict)
                case 400:
                    throw AttestationError.keyIdRequired(warningDict)
                case 401:
                    throw AttestationError.invalidAttestationOrBypassKey(warningDict)
                case 500:
                    throw AttestationError.unknownError(warningDict)
                default:
                    throw AttestationError.unknownError(warningDict)
                }
            }
            
            throw AttestationError.attestVerificationFailed(nil)
        }else{
            throw AttestationError.attestNotSupported(["error":"Attestation is not supported on this device. Please call the *bypass(serverURL: String, key: String)* function."])
        }
    }
    
    public func createAssertion(for serverURL: String, uuid: String, payload: Data?) async throws -> AttestationManagerResult {
        let service = DCAppAttestService.shared
        var keyId = await attestKeyId(for: serverURL)
        var warning: [String: Any]?
        
        if keyId == nil {
            let result = try await generateKey(for: serverURL, uuid: uuid)
            keyId = result.key
            warning = result.warning
        }
        
        let clientDataHash = Data(SHA256.hash(data: payload ?? Data()))
        
        let assertion = try await service.generateAssertion(keyId!, clientDataHash: clientDataHash).base64EncodedString()
        
        return AttestationManagerResult(assertion: assertion, keyId: keyId, warning: warning)
    }
    
    public func validateStoredKey(for serverURL: String, uuid: String) async throws -> AttestValidationResult {
        let keyId = await attestKeyId(for: serverURL)
        let data = try JSONEncoder().encode(
            ["keyId": keyId, "token": uuid]
        )

        var request = URLRequest.post(to: serverURL.url(), with: data)
        request.addValue(uuid, forHTTPHeaderField: "tag")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            let attestWarning = httpResponse.value(forHTTPHeaderField: "x-app-attest-warning")
            let warningDict = attestWarning?.toDictionary()
            
            switch httpResponse.statusCode {
            case 200, 201, 204:
                return AttestValidationResult(success: true, warning: warningDict)
            default:
                UserDefaults.standard.removeObject(forKey: serverURL)
                return AttestValidationResult(success: false, warning: warningDict ?? ["error":"\(httpResponse)"])
            }
        }
        UserDefaults.standard.removeObject(forKey: serverURL)
        return AttestValidationResult(success: false,  warning: ["error":"\(response)"])
    }
    
    public func bypass(serverURL: String, key: String, uuid: String) async throws -> AttestBypassResult {
        let data = try JSONEncoder().encode(
            ["token": uuid, "bypassKey" : key]
        )

        var request = URLRequest.post(to: serverURL.url(), with: data)
        request.addValue(uuid, forHTTPHeaderField: "tag")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            let attestWarning = httpResponse.value(forHTTPHeaderField: "x-app-attest-warning")
            let warningDict = attestWarning?.toDictionary()
            
            switch httpResponse.statusCode {
            case 200, 201, 204:
                return AttestBypassResult(success: true, warning: warningDict)
            default:
                return AttestBypassResult(success: false, warning: warningDict ?? ["error":"\(httpResponse)"])
            }
        }
        return AttestBypassResult(success: false, warning: ["error":"\(response)"])
    }
    
}
