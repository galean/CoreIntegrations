import Foundation
import CryptoKit

/*
 Namespace DNS: 6ba7b810-9dad-11d1-80b4-00c04fd430c8
 Namespace URL: 6ba7b811-9dad-11d1-80b4-00c04fd430c8
 ->Namespace ISO OID: 6ba7b812-9dad-11d1-80b4-00c04fd430c8
 Namespace X.500 DN: 6ba7b814-9dad-11d1-80b4-00c04fd430c8
 */

enum UUID_Namespace: String {
    case dns = "6ba7b810-9dad-11d1-80b4-00c04fd430c8"
    case url = "6ba7b811-9dad-11d1-80b4-00c04fd430c8"
    case oid = "6ba7b812-9dad-11d1-80b4-00c04fd430c8"
    case x500 = "6ba7b814-9dad-11d1-80b4-00c04fd430c8"
}

// Extension to create a UUID v5 using SHA-1 hashing
extension UUID {
    static func uuidV5(namespace: UUID_Namespace, name: String) -> UUID? {
        let namespace_uuid = UUID(uuidString: namespace.rawValue)!
        // Convert namespace UUID to Data
        var namespaceBytes = namespace_uuid.uuid
        let namespaceData = Data(bytes: &namespaceBytes, count: 16)
        
        // Convert name to Data
        guard let nameData = name.data(using: .utf8) else {
            return nil
        }
        
        // Combine namespace and name data
        let combinedData = namespaceData + nameData
        
        // Hash the combined data using SHA-1
        let hash = Insecure.SHA1.hash(data: combinedData)
        
        // Take the first 16 bytes of the hash to create the UUID
        var uuidBytes = Array(hash.prefix(16))
        
        // Set the UUID version to 5
        uuidBytes[6] = (uuidBytes[6] & 0x0F) | 0x50
        // Set the variant to RFC 4122
        uuidBytes[8] = (uuidBytes[8] & 0x3F) | 0x80
        
        // Convert bytes to UUID
        let uuid = uuidBytes.withUnsafeBytes {
            $0.load(as: UUID.self)
        }
        
        return uuid
    }
}

// Usage
//let name = "domain.com"
//if let uuidV5 = UUID.uuidV5(namespace: .oid, name: name) {
//    print("UUID v5: \(uuidV5)")
//} else {
//    print("Failed to generate UUID v5")
//}
