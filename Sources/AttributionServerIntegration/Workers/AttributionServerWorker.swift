import Foundation
import LoggingIntegration

public class AttributionServerWorker {
    let installServerURLPath: String
    let purchaseServerURLPath: String
    let installPath: String
    let purchasePath: String
	let appTransactionPath: String
    let tokensPath: String
    let externalAuthPath: String

    init(installServerURLPath: String, purchaseServerURLPath: String, installPath: String, purchasePath: String, appTransactionPath: String, externalAuthPath: String, tokensPath: String) {
        self.installServerURLPath = installServerURLPath
        self.purchaseServerURLPath = purchaseServerURLPath
        self.installPath = installPath
        self.purchasePath = purchasePath
		self.appTransactionPath = appTransactionPath
        self.tokensPath = tokensPath
        self.externalAuthPath = externalAuthPath
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

    fileprivate var appTransactionURL: URL? {
        let urlPath = "\(installServerURLPath)\(appTransactionPath)"
        let urlOrNil = URL(string: urlPath)
        return urlOrNil
    }
    
    fileprivate var tokensURL: URL? {
        let urlPath = "\(installServerURLPath)\(tokensPath)"
        let urlOrNil = URL(string: urlPath)
        return urlOrNil
    }
    
    fileprivate var externalAuthURL: URL? {
        let trimInstallServerURLPath = installServerURLPath.replacingOccurrences(of: "/attribute", with: "")
        let urlPath = "\(trimInstallServerURLPath)\(externalAuthPath)"
        let urlOrNil = URL(string: urlPath)
        return urlOrNil
    }
    
    fileprivate var consentURL: URL? {
        let urlPath = "\(installServerURLPath)/consent"
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
    
    fileprivate var longerSession: URLSession {
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = false
        config.timeoutIntervalForRequest = 60 // the same as default
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
        DebugLogger.log("""
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
            DebugLogger.log("\n\n\nANALYTICS SEND ERROR\n\n\n")
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
            if let _ = error {
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
            DebugLogger.log("\n\n\nANALYTICS SEND ERROR\n\n\n")
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
            if let _ = error {
                self.handleServerError()
                
                if taskSession.configuration.waitsForConnectivity == false {
                    self.sendPurchaseAnalytics(analytics: analytics, userId: userId, authToken: authToken,
                                               isBackgroundSession: true, completion: completion)
                }
                
                completion(false)
                return
            }
            
            guard let _ = data else{
                completion(false)
                return
            }
            
            completion(true)
        }
        task.resume()
    }
    
    func sendExternalAuthorization(parameters: AttributionExternalAuthRequestModel,
                                   authToken: String,
                                   completion: @escaping ((Bool) -> Void)) {
        let jsonDataOrNil = try? JSONEncoder().encode(parameters)
        
        guard let url = externalAuthURL, let jsonData = jsonDataOrNil else {
            DebugLogger.log("\n\n\nEXTERNAL AUTH SEND ERROR\n\n\n")
            completion(false)
            return
        }
        
        let request = createRequest(url: url, body: jsonData, authToken: authToken)
        
        let task = session.dataTask(with: request) { (data, response, error) in
            if let _ = error {
                self.handleServerError()
                completion(false)
                return
            }
            
            guard let _ = data else{
                completion(false)
                return
            }
            
            completion(true)
        }
        task.resume()
    }
    
    func sendConsent(parameters: AttributionConsentRequestModel,
                     authToken: AttributionServerToken,
                     completion: @escaping ((Bool) -> Void)) {
        let jsonDataOrNil = try? JSONEncoder().encode(parameters)
        
        guard let url = consentURL, let jsonData = jsonDataOrNil else {
            DebugLogger.log("\n\n\nCONSENT SEND ERROR\n\n\n")
            completion(false)
            return
        }
        
        let request = createRequest(url: url, body: jsonData, authToken: authToken)
        
        let task = waitingSession.dataTask(with: request) { (data, response, error) in
            if let _ = error {
                self.handleServerError()
                completion(false)
                return
            }
            
            guard let response = response as? HTTPURLResponse else {
                completion(false)
                return
            }
            
            let isSuccess = (200..<300).contains(response.statusCode)
            completion(isSuccess)
        }
        task.resume()
    }
    
    func sendFCMToken(parameters: AttributionTokenRequestModel, authToken: String,
                      isBackgroundSession: Bool = false,
                      completion: @escaping ((Bool) -> Void)) {
        let jsonDataOrNil = try? JSONEncoder().encode(parameters)
        
        guard let url = tokensURL, let jsonData = jsonDataOrNil else {
            DebugLogger.log("\n\n\nFCM TOKEN SEND ERROR\n\n\n")
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
            if let _ = error {
                self.handleServerError()
                
                if taskSession.configuration.waitsForConnectivity == false {
                    self.sendFCMToken(parameters: parameters, authToken: authToken,
                                     isBackgroundSession: true, completion: completion)
                }
                
                completion(false)
                return
            }
            
            guard let _ = data else {
                completion(false)
                return
            }
            
            completion(true)
        }
        task.resume()
    }

    func sendAppTransaction(parameters: AttributionAppTransactionRequestModel,
                            authToken: AttributionServerToken,
                            isBackgroundSession: Bool = false,
                            completion: @escaping ((Bool) -> Void)) {
        let jsonDataOrNil = try? JSONEncoder().encode(parameters)

        guard let url = appTransactionURL, let jsonData = jsonDataOrNil else {
            DebugLogger.log("\n\n\nANALYTICS SEND ERROR\n\n\n")
            completion(false)
            return
        }

        let request = createRequest(url: url, body: jsonData, authToken: authToken)

        let taskSession: URLSession
        if isBackgroundSession {
            taskSession = waitingSession
        } else {
            taskSession = longerSession
        }

        let task = taskSession.dataTask(with: request) { (data, response, error) in
            if let error = error {
                self.handleServerError()

                if taskSession.configuration.waitsForConnectivity == false {
                    self.sendAppTransaction(parameters: parameters, authToken: authToken,
                                            isBackgroundSession: true, completion: completion)
                }

                completion(false)
                return
            }

            guard data != nil else {
                completion(false)
                return
            }

            completion(true)
        }
        task.resume()
    }
}
