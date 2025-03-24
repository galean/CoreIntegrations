import UIKit

extension String {
    
    func base64Encoded() -> String? {
        data(using: .utf8)?.base64EncodedString()
    }
    
    func base64Decoded() -> String? {
        guard let data = Data(base64Encoded: self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    func toDictionary() -> [String: Any]? {
        if let data = self.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
    
    func url(endpoint: String) -> URL {
        return URL(string: "\(self)\(endpoint)")!
    }
    
    func url() -> URL {
        return URL(string: self)!
    }
    
}
