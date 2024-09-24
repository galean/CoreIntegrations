import Foundation
import CryptoKit
import DeviceCheck

protocol AttestationManagerProtocol {
    var isSupported: Bool { get async }
    var attestKeyId: String? { get async }
    func generateKey() async throws -> String
    func createAssertion() async throws -> String
}

public actor AttestationManager: AttestationManagerProtocol {
    static let shared = AttestationManager()
    
    private var endpoint = "https://backend-boilerplate-app-attest.fly.dev/api"
    private var attest_key_id = "CoreAttestationKeyId"
    
    public var isSupported: Bool {
        get async {
            DCAppAttestService.shared.isSupported
        }
    }
    
    var attestKeyId: String? {
        get async {
            UserDefaults.standard.string(forKey: attest_key_id)
        }
    }
    
    func generateKey() async throws -> String {
        let service = DCAppAttestService.shared
        if service.isSupported {
            let idfv = "idfv"
            let keyId = try await service.generateKey()
            let clientDataHash = Data(SHA256.hash(data: idfv.data(using: .utf8)!))
            let attestation = try await service.attestKey(keyId, clientDataHash: clientDataHash)
            
            var request = URLRequest(url: url("/app-attest/register-device"))
            request.httpMethod = "POST"
            request.httpBody = try JSONEncoder().encode(
                [
                    "keyId": keyId,
                    "challenge": idfv,
                    "idfv": idfv,
                    "attestation": attestation.base64EncodedString(),
                ]
            )
            
            request.setValue(
                "application/json",
                forHTTPHeaderField: "Content-Type"
            )
            
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
    
    func createAssertion(/*_ payload: Data*/) async throws -> String {
        var keyId = await attestKeyId
        let idfv = "idfv"
        
        if keyId == nil {
            keyId = try await generateKey()
        }
        
//        let hash = Data(SHA256.hash(data: payload))
//        let service = DCAppAttestService.shared
//        let assertion = try await service.generateAssertion(keyId!, clientDataHash: hash)
//        
//        return try JSONEncoder().encode([
//            "keyId": keyId,
//            "assertion": assertion.base64EncodedString(),
//        ]).base64EncodedString()
        
        return try JSONEncoder().encode([
            "keyId": keyId,
            "idfv": idfv,
        ]).base64EncodedString()
    }
    
    
    
    private func url(_ target: String) -> URL {
        return URL(string: "\(endpoint)\(target)")!
    }
}

enum AttestationError: Error {
    case attestVerificationFailed
    case attestNotSupported
    case assertionFailed
    
    case keyIdRequired
    case invalidAttestationOrBypassKey
    case unknownError
}

//test, to be deleted
public actor ApiManager {
    public func testCallToAPI() async throws {

        let idfv = "idfv"
        let payload = try JSONEncoder().encode([
            "some_payload" : "some_payload"
        ])
        
        let assertion = try await AttestationManager.shared.createAssertion()
        let keyId = await AttestationManager.shared.attestKeyId
        
        var request = URLRequest(url: url("/send-message"))
        request.httpMethod = "POST"
        
        request.httpBody = payload
        
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )
        
        request.setValue(
            assertion,
            forHTTPHeaderField: "x-app-attest-assertion"
        )
        
        request.setValue(
            keyId,
            forHTTPHeaderField: "xx-app-attest-key-id"
        )
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("DeviceCheck_message \(httpResponse)")
            if httpResponse.statusCode == 401 {
                //UserDefaults.standard.removeObject(forKey: attest_key_id)
                throw AttestationError.assertionFailed
            }
        }
    }
    
    private func url(_ target: String) -> URL {
        return URL(string: "https://werwer.com\(target)")!
    }
}
