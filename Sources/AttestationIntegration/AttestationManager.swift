import Foundation
import CryptoKit
import DeviceCheck
import UIKit

public actor AttestationManager:AttestationManagerProtocol {
    static public let shared = AttestationManager()
    
    public var endpoint: String = ""
    public var bypassKey: String = ""
    
    private var attest_key_id = "CoreAttestationKeyId"
    
    @MainActor
    private var uuid: String {
        let idfv = UIDevice.current.identifierForVendor?.uuidString ?? ""
        let range = idfv.index(idfv.startIndex, offsetBy: 14)
        return idfv.replacingCharacters(in: range...range, with: "F")
    }
    
    public var isSupported: Bool {
        get async {
            DCAppAttestService.shared.isSupported
        }
    }
    
    public var attestKeyId: String? {
        get async {
            UserDefaults.standard.string(forKey: attest_key_id)
        }
    }
    
    public func configure(endpoint: String, bypassKey: String) {
        self.endpoint = endpoint
        self.bypassKey = bypassKey
    }
    
    public func generateKey() async throws -> AttestKeyGenerationResult {
        let service = DCAppAttestService.shared
        
        if service.isSupported {
            let keyId = try await service.generateKey()
            let clientDataHash = await Data(SHA256.hash(data: uuid.data(using: .utf8)!))
            let attestation = try await service.attestKey(keyId, clientDataHash: clientDataHash)
            let data = try await JSONEncoder().encode(
                [
                    "keyId": keyId,
                    "challenge": uuid,
                    "idfv": uuid,
                    "attestation": attestation.base64EncodedString(),
                ]
            )
            
            let request = URLRequest.post(to: url("/app-attest/register-device"), with: data)
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("DeviceCheck_attestKey \(httpResponse)")
                let attestWarning = httpResponse.value(forHTTPHeaderField: "x-app-attest-warning")
                let warningDict = convertToDict(attestWarning)
                
                switch httpResponse.statusCode {
                case 200, 204:
                    UserDefaults.standard.set(keyId, forKey: attest_key_id)
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
            let bypass = try await bypass()
            if bypass.success {
                throw AttestationError.unenforcedBypass(bypass.warning)
            }else{
                throw AttestationError.bypassError(bypass.warning)
            }
        }
    }
    
    public func createAssertion() async throws -> AttestationManagerResult {
        var keyId = await attestKeyId
        var warning: [String: Any]?
        
        if keyId == nil {
            let result = try await generateKey()
            keyId = result.key
            warning = result.warning
        }else{
            let validationResult = try await validateStoredKey()
            if !validationResult.success {
                let result = try await generateKey()
                keyId = result.key
                warning = result.warning
            }
        }
        
        let assertion = try await JSONEncoder().encode(
            ["keyId": keyId, "idfv": uuid]
        ).base64EncodedString()
        
        return AttestationManagerResult(assertion: assertion, keyId: keyId, warning: warning)
    }
    
    public func validateStoredKey() async throws -> AttestValidationResult {
        let keyId = await attestKeyId
        let data = try await JSONEncoder().encode(
            ["keyId": keyId, "idfv": uuid]
        )
        let request = URLRequest.post(to: url("/app-attest/register-device"), with: data)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("DeviceCheck_validateStoredKey \(httpResponse)")
            let attestWarning = httpResponse.value(forHTTPHeaderField: "x-app-attest-warning")
            let warningDict = convertToDict(attestWarning)
            
            switch httpResponse.statusCode {
            case 200, 204:
                return AttestValidationResult(success: true, warning: warningDict)
            default:
                UserDefaults.standard.removeObject(forKey: attest_key_id)
                return AttestValidationResult(success: false, warning: warningDict)
            }
        }
        UserDefaults.standard.removeObject(forKey: attest_key_id)
        return AttestValidationResult(success: true)
    }
    
    public func bypass() async throws -> AttestBypassResult {
        let data = try await JSONEncoder().encode(
            ["idfv": uuid, "bypassKey" : bypassKey]
        )
        let request = URLRequest.post(to: url("/app-attest/verify"), with: data)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("DeviceCheck_bypass \(httpResponse)")
            let attestWarning = httpResponse.value(forHTTPHeaderField: "x-app-attest-warning")
            let warningDict = convertToDict(attestWarning)
            
            switch httpResponse.statusCode {
            case 200, 204:
                return AttestBypassResult(success: true, warning: warningDict)
            default:
                return AttestBypassResult(success: false, warning: warningDict)
            }
        }
        return AttestBypassResult(success: false)
    }
    
    private func url(_ target: String) -> URL {
        return URL(string: "\(endpoint)\(target)")!
    }
    
    private func convertToDict( _ string: String?) -> [String: Any]? {
        if let data = string?.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
}

extension URLRequest {
    static func post(to url: URL, with body: Data) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )
        return request
    }
}
