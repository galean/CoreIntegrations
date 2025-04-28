
import Foundation

struct CoreConfigurationModel {
    var allConfigurationEvents: [any ConfigurationEvent]
    var completedEvents = [any ConfigurationEvent]()
    var completionErrors = [String: Error]()
    
    var isFirstStart: Bool
    
    init(allConfigurationEvents: [any ConfigurationEvent], completedEvents: [any ConfigurationEvent] = [any ConfigurationEvent](), isFirstStart: Bool) {
        self.allConfigurationEvents = allConfigurationEvents
        self.completedEvents = completedEvents
        self.isFirstStart = isFirstStart
    }
    
    var statusDescription: [String: String] {
        var result = [String: String]()
        completedEvents.forEach { event in
            let error = completionErrors.first(where: { $0.key == event.key })?.value
            if let nserror = error as? NSError {
                result[event.key] = "error: \(nserror.code)"
            } else {
                result[event.key] = "finished"
            }
        }
        let notCompleted = allConfigurationEvents.filter { event in
            !completedEvents.contains { completedEvent in
                completedEvent.key == event.key
            }
        }
        notCompleted.forEach { event in
            result[event.key] = "not finished"
        }
        
        return result
    }
}
  
extension CoreConfigurationModel {
    func checkAllEventsFinished() -> Bool {
        guard checkCompletedWithErrors() == false else {
            return true
        }
        
        var allCompleted = true
        
        let verifingEvents = allConfigurationEvents.filter { event in
            guard isFirstStart else {
                return event.isFirstStartOnly == false
            }
            return true
        }
        
        verifingEvents.forEach { event in
            let eventCompleted = completedEvents.contains { completedEvent in
                completedEvent.key == event.key
            }
            if eventCompleted == false {
                allCompleted = false
            }
        }
        return allCompleted
    }
    
    func checkRequiredEventsFinished() -> Bool {
        guard checkCompletedWithErrors() == false else {
            return true
        }
        
        var allCompleted = true
        
        var verifingEvents = allConfigurationEvents.filter { event in
            guard isFirstStart else {
                return event.isFirstStartOnly == false
            }
            return true
        }
        
        verifingEvents = verifingEvents.filter { event in
            return event.isRequiredToContunue
        }
        
        verifingEvents.forEach { event in
            let eventCompleted = completedEvents.contains { completedEvent in
                completedEvent.key == event.key
            }
            if eventCompleted == false {
                allCompleted = false
            }
        }
        return allCompleted
    }
    
    func checkAttAndConfigFinished() -> Bool {
        var allCompleted = true
        let verifingEvents = [InternalConfigurationEvent.attConcentGiven, InternalConfigurationEvent.remoteConfigLoaded]
        
        verifingEvents.forEach { event in
            let eventCompleted = completedEvents.contains { completedEvent in
                completedEvent.key == event.key
            }
            if eventCompleted == false {
                allCompleted = false
            }
        }
        
        return allCompleted
    }
    
    func checkCompletedWithErrors() -> Bool {
        // verify no internet connection. We think we don't have internet connection when RemoteConfig service and attribution service returned errors. We don't look on Appsflyer, because it doesn't return errors when no internet :(
        var completedWithErrors = true
        let errorVerifingEvents: [InternalConfigurationEvent] = [.remoteConfigLoaded, .attributionServerHandled]
        errorVerifingEvents.forEach { event in
            let eventCompleted = completedEvents.contains { completedEvent in
                completedEvent.key == event.key
            }
            let eventCompletedWithError = completionErrors.contains { completedEvent in
                completedEvent.key == event.key
            }
            
            if eventCompleted == false {
                completedWithErrors = false
            }
            
            if eventCompletedWithError == false {
                completedWithErrors = false
            }
        }
        
        return completedWithErrors
    }
    
    func checkAttributionFinished() -> Bool {
        // Finish configuration if we see already that there's no internet
        guard checkCompletedWithErrors() == false else {
            return true
        }
        
        // But if both these services didn't return errors - then we wait for AF also, because it doesn't look like an internet error, maybe just one service internal error
        var allCompleted = true
        let verifingEvents: [InternalConfigurationEvent] = [.appsflyerWeb2AppHandled, .attributionServerHandled, .remoteConfigLoaded]
        verifingEvents.forEach { event in
            let eventCompleted = completedEvents.contains { completedEvent in
                completedEvent.key == event.key
            }
            if eventCompleted == false {
                allCompleted = false
            }
        }
        
        return allCompleted
    }
}
