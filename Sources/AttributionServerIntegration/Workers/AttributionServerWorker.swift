//
//  TLMAttributionManagerServerWorker.swift.swift
//  
//
//  Created by Andrii Plotnikov on 22.12.2022.
//

import Foundation

public class AttributionServerWorker {
    let serverURLPath: String
    let installPath: String
    let purchasePath: String
    
    init(serverURLPath: String, installPath: String, purchasePath: String) {
        self.serverURLPath = serverURLPath
        self.installPath = installPath
        self.purchasePath = purchasePath
    }
    
    fileprivate var isSyncingInstall = false
    
    fileprivate var installURL: URL? {
        let urlPath = "\(serverURLPath)\(installPath)"
        let urlOrNil = URL(string: urlPath)
        return urlOrNil
    }
    
    fileprivate var subscribeURL: URL? {
        let urlPath = "\(serverURLPath)\(purchasePath)"
        let urlOrNil = URL(string: urlPath)
        return urlOrNil
    }
    
    fileprivate var session: URLSession {
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true
        config.timeoutIntervalForRequest = 30
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
                              completion: @escaping (([String: Any]?) -> Void)) {
        let jsonDataOrNil = try? JSONEncoder().encode(parameters)
        
        guard let url = installURL, let jsonData = jsonDataOrNil else {
            print("\n\n\nANALYTICS SEND ERROR\n\n\n")
            completion([:])
            return
        }
        
        let request = createRequest(url: url, body: jsonData, authToken: authToken)
        
        guard isSyncingInstall == false else {
            return
        }
        
        isSyncingInstall = true
        
        let task = session.dataTask(with: request) { (data, response, error) in
            defer {
                self.isSyncingInstall = false
            }
            if let error = error {
                self.handleServerError()
                completion([:])
                return
            }
            
            guard let data = data else{
                self.handleServerError()
                completion([:])
                return
            }
            let jsonResult = try? JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
            completion(jsonResult)
            
        }
        task.resume()
    }
    
    func sendPurchaseAnalytics(analytics: AttrubutionPurchaseRequestModel, userId: String,
                               authToken: String,
                               completion: @escaping ((Bool) -> Void)) {
        let jsonDataOrNil = try? JSONEncoder().encode(analytics)
        
        guard let url = subscribeURL, let jsonData = jsonDataOrNil else {
            print("\n\n\nANALYTICS SEND ERROR\n\n\n")
            completion(false)
            return
        }
        
        let request = createRequest(url: url, body: jsonData, authToken: authToken)
        
        let task = session.dataTask(with: request) { (data, response, error) in
            if let error = error {
                self.handleServerError()
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
