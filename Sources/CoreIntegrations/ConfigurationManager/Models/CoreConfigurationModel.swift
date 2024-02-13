//
//  CoreConfigurationModel.swift
//  
//
//  Created by Andrii Plotnikov on 16.10.2023.
//

import Foundation

struct CoreConfigurationModel {
    var allConfigurationEvents: [any ConfigurationEvent]
}
  
extension CoreConfigurationModel {
    func checkAllEventsFinished(completedEvents: [any ConfigurationEvent], isFirstStart: Bool) -> Bool {
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
    
    func checkRequiredEventsFinished(completedEvents: [any ConfigurationEvent], isFirstStart: Bool) -> Bool {
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
    
    func checkAttAndConfigFinished(completedEvents: [any ConfigurationEvent], isFirstStart: Bool) -> Bool {
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
    
}
