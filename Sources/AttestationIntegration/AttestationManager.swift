import Foundation
import CryptoKit
import DeviceCheck
import UIKit

public actor AttestationManager: AttestationManagerProtocol {
    public static let shared = AttestationManager()
    
    private var endpoint = "https://backend-boilerplate-app-attest.fly.dev/api"
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
    
    public func generateKey() async throws -> String {
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
                
                switch httpResponse.statusCode {
                case 200, 204:
                    UserDefaults.standard.set(keyId, forKey: attest_key_id)
                    return keyId
                case 400:
                    throw AttestationError.keyIdRequired
                case 401:
                    throw AttestationError.invalidAttestationOrBypassKey
                case 500:
                    throw AttestationError.unknownError
                default:
                    throw AttestationError.unknownError
                }
            }
            
            throw AttestationError.attestVerificationFailed
        }
        throw AttestationError.attestNotSupported
    }
    
    public func createAssertion() async throws -> AttestationManagerResult {
        var keyId = await attestKeyId
        
        if keyId == nil {
            keyId = try await generateKey()
        }else{
            let isValidKey = try await validateStoredKey()
            if !isValidKey {
                keyId = try await generateKey()
            }
        }
        
        let assertion = try await JSONEncoder().encode(
            ["keyId": keyId, "idfv": uuid]
        ).base64EncodedString()
        
        return AttestationManagerResult(assertion: assertion, keyId: keyId)
    }
    
    public func validateStoredKey() async throws -> Bool {
        let keyId = await attestKeyId
        let data = try await JSONEncoder().encode(
            ["keyId": keyId, "idfv": uuid]
        )
        let request = URLRequest.post(to: url("/app-attest/register-device"), with: data)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("DeviceCheck_validateStoredKey \(httpResponse)")
            
            switch httpResponse.statusCode {
            case 200, 204:
                return true
            default:
                UserDefaults.standard.removeObject(forKey: attest_key_id)
                return false
            }
        }
        UserDefaults.standard.removeObject(forKey: attest_key_id)
        return false
    }
    
    public func bypass(_ bypassKey: String) async throws -> Bool {
        let data = try await JSONEncoder().encode(
            ["idfv": uuid, "bypassKey" : bypassKey]
        )
        let request = URLRequest.post(to: url("/app-attest/verify"), with: data)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("DeviceCheck_bypass \(httpResponse)")
            
            switch httpResponse.statusCode {
            case 200, 204:
                return true
            default:
                return false
            }
        }
        return false
    }
    
    private func url(_ target: String) -> URL {
        return URL(string: "\(endpoint)\(target)")!
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
