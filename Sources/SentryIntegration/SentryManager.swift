
import Foundation
import Sentry

public class SentryManager: InternalSentryManagerProtocol, PublicSentryManagerProtocol {
    
    public static var shared = SentryManager()
    
    public func configure(_ data: SentryConfigData) {
        SentrySDK.start { options in
            options.dsn = data.dsn
            options.debug = data.debug
            
#if DEBUG
            options.environment = "debug"
#else
            options.environment = "production"
#endif
            
            options.beforeSend = { [weak self] event in
                if let url = event.request?.url, url.contains("appsflyersdk.com") {
                    event.exceptions?.last?.type = "Appsflyer_http_error"
                    event.tags?["source"] = "Appsflyer"
                    if let description = self?.makeErrorDescription(event.breadcrumbs, domain: "appsflyersdk.com") {
                        event.exceptions?.last?.value = description
                    }
                }
                if let url = event.request?.url, url.contains("amplitude.com") {
                    event.exceptions?.last?.type = "Amplitude_http_error"
                    event.tags?["source"] = "Amplitude"
                    if let description = self?.makeErrorDescription(event.breadcrumbs, domain: "amplitude.com") {
                        event.exceptions?.last?.value = description
                    }
                }
                if let url = event.request?.url, url.contains("apitlm-protected.com") {
                    event.exceptions?.last?.type = "Attribution_http_error"
                    event.tags?["source"] = "AttributionServer"
                    if let description = self?.makeErrorDescription(event.breadcrumbs, domain: "apitlm-protected.com") {
                        event.exceptions?.last?.value = description
                    }
                }
                                
                return event
            }
            
            // Set tracesSampleRate to 1.0 to capture 100% of transactions for tracing.
            // We recommend adjusting this value in production.
            options.tracesSampleRate = NSNumber(value: data.tracesSampleRate)
            
            // Sample rate for profiling, applied on top of TracesSampleRate.
            // We recommend adjusting this value in production.
            options.profilesSampleRate = NSNumber(value: data.profilesSampleRate)
            
            options.enableCaptureFailedRequests = data.shouldCaptureHttpRequests
            
            let httpStatusCodeRange = HttpStatusCodeRange(min: data.httpCodesRange.lowerBound, max: data.httpCodesRange.length)
            options.failedRequestStatusCodes = [ httpStatusCodeRange ]
            
            options.failedRequestTargets = [
                "apitlm-protected.com",
                "amplitude.com",
                "appsflyersdk.com",
            ]
            
            if let domains = data.handledDomains {
                options.failedRequestTargets.append(contentsOf: domains)
            }
        }
    }
    
    public func setUserID(_ userID: String) {
        SentrySDK.configureScope { scope in
            let user = User()
            user.userId = userID
            scope.setUser(user)
        }
    }
    
    public func log(_ error: Error) {
        SentrySDK.capture(error: error)
    }
    
    public func log(_ exception: NSException) {
        SentrySDK.capture(exception: exception)
    }
    
    public func log(_ message: String) {
        SentrySDK.capture(message: message)
    }
    
    private func makeErrorDescription(_ breadcrumbs: [Breadcrumb]?, domain: String) -> String? {
        
        let filtered = breadcrumbs?.filter({$0.category == "http"})
        
        if let breadcrumb = filtered?.last(where: {
            let url = $0.data?["url"] as? String ?? ""
            let status: Int = $0.data?["status_code"] as? Int ?? 0
            return url.contains(domain) && status != 200
        }) {
            let method: String = breadcrumb.data?["method"] as? String ?? "-"
            let reason = breadcrumb.data?["reason"] as? String ?? "-"
            let status: Int = breadcrumb.data?["status_code"] as? Int ?? 0
            let url = breadcrumb.data?["url"] as? String ?? ""
            
            let description: String = "method: \(method),\nstatus_code: \(status),\nurl: \(url),\nreason: \(reason)"
            return description
        } else {
            return nil
        }

    }
    
}
