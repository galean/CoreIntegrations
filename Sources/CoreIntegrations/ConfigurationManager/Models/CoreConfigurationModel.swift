
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
    
    func checkAttributionFinished() -> Bool {
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
