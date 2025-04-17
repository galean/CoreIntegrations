
import Foundation

public class AttributionServerWorker {
    let installServerURLPath: String
    let purchaseServerURLPath: String
    let installPath: String
    let purchasePath: String
    
    init(installServerURLPath: String, purchaseServerURLPath: String, installPath: String, purchasePath: String) {
        self.installServerURLPath = installServerURLPath
        self.purchaseServerURLPath = purchaseServerURLPath
        self.installPath = installPath
        self.purchasePath = purchasePath
    }
    
    fileprivate var isSyncingInstall = false
    
    fileprivate var installURL: URL? {
        let urlPath = "\(installServerURLPath)\(installPath)"
        let urlOrNil = URL(string: urlPath)
        return urlOrNil
    }
    
    fileprivate var subscribeURL: URL? {
        let urlPath = "\(purchaseServerURLPath)\(purchasePath)"
        let urlOrNil = URL(string: urlPath)
        return urlOrNil
    }
    
    fileprivate var session: URLSession {
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = false
        config.timeoutIntervalForRequest = 5
        let session = URLSession(configuration: config)
        return session
    }
    
    fileprivate var waitingSession: URLSession {
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true
        let session = URLSession(configuration: config)
        return session
    }
    
    fileprivate func createRequest(url: URL, body: Data, authToken: String) -> URLRequest {
        var request = URLRequest(url: url)
        
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("ios", forHTTPHeaderField: "platform")
        request.addValue(authToken, forHTTPHeaderField: "authorization")
        request.httpBody = body
        
        return request
    }
    
    fileprivate func handleServerError() {
        print("""
            \n\n\n
            ==========================
            ANALYTICS SERVER DOWN
            ==========================
            \n\n\n
            """)
    }
}

extension AttributionServerWorker: AttributionServerWorkerProtocol {
    func sendInstallAnalytics(parameters: AttributionInstallRequestModel, authToken: String,
                              isBackgroundSession: Bool = false,
                              completion: @escaping (([String: String]?, Error?) -> Void)) {
        let jsonDataOrNil = try? JSONEncoder().encode(parameters)
        
        guard let url = installURL, let jsonData = jsonDataOrNil else {
            print("\n\n\nANALYTICS SEND ERROR\n\n\n")
            completion([:], NSError(domain: "coreintegration.attribution.internal", code: 400))
            return
        }
        
        let request = createRequest(url: url, body: jsonData, authToken: authToken)
        
        guard isSyncingInstall == false else {
            return
        }
        
        isSyncingInstall = true
        
        let taskSession: URLSession
        if isBackgroundSession {
            taskSession = waitingSession
        } else {
            taskSession = session
        }
        
        let task = taskSession.dataTask(with: request) { (data, response, error) in
            defer {
                self.isSyncingInstall = false
            }
            if let error = error {
                self.handleServerError()
                
                if taskSession.configuration.waitsForConnectivity == false {
                    self.sendInstallAnalytics(parameters: parameters, authToken: authToken, isBackgroundSession: true, completion: completion)
                }
                
                completion([:], error)
                return
            }
            
            guard let data = data else{
                self.handleServerError()
                completion([:], NSError(domain: "coreintegration.attribution.internal", code: 400))
                return
            }
            let jsonResult = try? JSONSerialization.jsonObject(with: data) as? [String: NSObject] ?? [:]
            let result = jsonResult?.reduce(into: [String:String]()) {
                partialResult, result in
                partialResult[result.key] = "\(result.value)"
            }
            completion(result, nil)
            
        }
        task.resume()
    }
    
    func sendPurchaseAnalytics(analytics: AttrubutionPurchaseRequestModel, userId: String,
                               authToken: String, isBackgroundSession: Bool = false,
                               completion: @escaping ((Bool) -> Void)) {
        let jsonDataOrNil = try? JSONEncoder().encode(analytics)
        
        guard let url = subscribeURL, let jsonData = jsonDataOrNil else {
            print("\n\n\nANALYTICS SEND ERROR\n\n\n")
            completion(false)
            return
        }
        
        let request = createRequest(url: url, body: jsonData, authToken: authToken)
        
        let taskSession: URLSession
        if isBackgroundSession {
            taskSession = waitingSession
        } else {
            taskSession = session
        }
        
        let task = taskSession.dataTask(with: request) { (data, response, error) in
            if let error = error {
                self.handleServerError()
                
                if taskSession.configuration.waitsForConnectivity == false {
                    self.sendPurchaseAnalytics(analytics: analytics, userId: userId, authToken: authToken,
                                               isBackgroundSession: true, completion: completion)
                }
                
                completion(false)
                return
            }
            
            guard let responseData = data else{
                completion(false)
                return
            }
            
            completion(true)
        }
        task.resume()
    }
}
