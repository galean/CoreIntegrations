import Foundation
import CryptoKit
import DeviceCheck
import UIKit

public actor AttestationManager:AttestationManagerProtocol {
    static public let shared = AttestationManager()
        
    //to be replaced with UUID()
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
    
    public func attestKeyId(for serverURL: String) async -> String? {
        return UserDefaults.standard.string(forKey: serverURL)
    }
    
    public func generateKey(for serverURL: String) async throws -> AttestKeyGenerationResult {
        let service = DCAppAttestService.shared
        
        if service.isSupported {
            let keyId = try await service.generateKey()
            let clientDataHash = await Data(SHA256.hash(data: uuid.data(using: .utf8)!))
            let attestation = try await service.attestKey(keyId, clientDataHash: clientDataHash)
            let idfv = await uuid
            let challenge: String = idfv.base64Encoded() ?? idfv
            
            let data = try JSONEncoder().encode(
                [
                    "keyId": keyId,
                    "challenge": challenge,
                    "idfv": idfv,
                    "attestation": attestation.base64EncodedString(),
                ]
            )
            //endpoint: "/app-attest/register-device"
            let request = URLRequest.post(to: serverURL.url(), with: data)
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("DeviceCheck_attestKey \(httpResponse)")
                let attestWarning = httpResponse.value(forHTTPHeaderField: "x-app-attest-warning")
                let warningDict = attestWarning?.toDictionary()
                
                switch httpResponse.statusCode {
                case 200, 204:
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
    
    public func createAssertion(for serverURL: String) async throws -> AttestationManagerResult {
        var keyId = await attestKeyId(for: serverURL)
        var warning: [String: Any]?
        
        if keyId == nil {
            let result = try await generateKey(for: serverURL)
            keyId = result.key
            warning = result.warning
        }else{
            let validationResult = try await validateStoredKey(for: serverURL)
            if !validationResult.success {
                let result = try await generateKey(for: serverURL)
                keyId = result.key
                warning = result.warning
            }else{
                warning = validationResult.warning
            }
        }
        
        let assertion = try await JSONEncoder().encode(
            ["keyId": keyId, "idfv": uuid]
        ).base64EncodedString()
        
        return AttestationManagerResult(assertion: assertion, keyId: keyId, warning: warning)
    }
    
    public func validateStoredKey(for serverURL: String) async throws -> AttestValidationResult {
        let keyId = await attestKeyId(for: serverURL)
        let data = try await JSONEncoder().encode(
            ["keyId": keyId, "idfv": uuid]
        )
        //endpoint: "/app-attest/register-device"
        let request = URLRequest.post(to: serverURL.url(), with: data)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("DeviceCheck_validateStoredKey \(httpResponse)")
            let attestWarning = httpResponse.value(forHTTPHeaderField: "x-app-attest-warning")
            let warningDict = attestWarning?.toDictionary()
            
            switch httpResponse.statusCode {
            case 200, 204:
                return AttestValidationResult(success: true, warning: warningDict)
            default:
                UserDefaults.standard.removeObject(forKey: serverURL)
                return AttestValidationResult(success: false, warning: warningDict ?? ["error":"\(httpResponse)"])
            }
        }
        UserDefaults.standard.removeObject(forKey: serverURL)
        return AttestValidationResult(success: false,  warning: ["error":"\(response)"])
    }
    
    public func bypass(serverURL: String, key: String) async throws -> AttestBypassResult {
        let data = try await JSONEncoder().encode(
            ["idfv": uuid, "bypassKey" : key]
        )
        //endpoint: "/app-attest/verify"
        let request = URLRequest.post(to: serverURL.url(), with: data)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("DeviceCheck_bypass \(httpResponse)")
            let attestWarning = httpResponse.value(forHTTPHeaderField: "x-app-attest-warning")
            let warningDict = attestWarning?.toDictionary()
            
            switch httpResponse.statusCode {
            case 200, 204:
                return AttestBypassResult(success: true, warning: warningDict)
            default:
                return AttestBypassResult(success: false, warning: warningDict ?? ["error":"\(httpResponse)"])
            }
        }
        return AttestBypassResult(success: false, warning: ["error":"\(response)"])
    }
    
}
