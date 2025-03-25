
import Foundation

//protocol ConfigurationManagerDelegate: AnyObject {
//    func onConfigurationFinish() // att + amplitude
//    func onAttributionFinish() // server + af
//    func onAttributionUpdated() // amplitude update
//    func onAttributionTimeout()
//}

class AppConfigurationManager {
    public static var shared: AppConfigurationManager?
//    public var delegate: ConfigurationManagerDelegate?
    
    private var model: CoreConfigurationModel
    private var isFirstStart: Bool
    
    private var completedEvents = [any ConfigurationEvent]()
    private var timout: Int = 6
    private var currentSecond = 0
    private var waitingCallbacks = [(ConfigurationResult) -> Void]()
    private var isTimerStarted = false
    private var isTimerFinished = false
    
    private var configurationCallback: (() -> Void)?
    private var configurationAttFinishHandled = false
    
    private var attributionCallback: (() -> Void)?
    
    var attributionFinishHandled = false
    
    var configurationFinishHandled = false

    
    private var configurationCompletelyFinished: Bool {
        return model.checkAllEventsFinished(completedEvents: completedEvents, isFirstStart: isFirstStart)
    }
    
    private var configurationRequiredFinished: Bool {
        return model.checkRequiredEventsFinished(completedEvents: completedEvents, isFirstStart: isFirstStart)
    }
    
    private var configurationAttAndConfigFinished: Bool {
        return model.checkAttAndConfigFinished(completedEvents: completedEvents, isFirstStart: isFirstStart)
    }
    
    private var attributionFinished: Bool {
        return model.checkAttributionFinished(completedEvents: completedEvents)
    }
    
    private var isConfigurationFinished: Bool {
        return isTimerFinished || configurationCompletelyFinished
    }
    
    init(model: CoreConfigurationModel, isFirstStart: Bool, timeout: Int = 6) {
        self.model = model
        self.isFirstStart = isFirstStart
        self.timout = timeout
    }
    
    public func reset() {
        completedEvents.removeAll()
        isTimerFinished = false
        configurationFinishHandled = false
        configurationAttFinishHandled = false
        configurationCallback = nil
        waitingCallbacks.removeAll()
        attributionCallback = nil
        attributionFinishHandled = false
        currentSecond = 0
        isTimerStarted = false
    }
    
    public func startTimoutTimer() {
        guard self.isConfigurationFinished == false else {
            return
        }
        
        guard isTimerStarted == false else {
            return
        }
        
        isTimerStarted = true
        
        DispatchQueue.global().asyncAfter(deadline: .now() + TimeInterval(timout)) {
            guard self.isConfigurationFinished == false else {
                return
            }
            
            self.isTimerFinished = true
            self.checkConfiguration()
        }
    }
    
    public func handleCompleted(event: any ConfigurationEvent) {
        completedEvents.append(event)
        checkConfiguration()
        checkATTConfiguration()
        checkAttributionFinished()
    }
    
    public func signForConfigurationEnd(_ callback: @escaping (ConfigurationResult) -> Void) {
        guard !isConfigurationFinished else {
            let configurationResult: ConfigurationResult = configurationRequiredFinished ? .completed : .requiredFailed
            callback(configurationResult)
            return
        }
        waitingCallbacks.append(callback)
    }
    
    public func signForAttAndConfigLoaded(_ callback: @escaping () -> Void) {
        guard !configurationAttFinishHandled else {
            callback()
            return
        }
        configurationCallback = callback
    }
    
    public func signForAttributionFinished(_ callback: @escaping () -> Void) {
        guard !attributionFinished else {
            callback()
            return
        }
        attributionCallback = callback
    }
    
    private func checkATTConfiguration() {
        guard configurationAttAndConfigFinished else {
            return
        }
        
        guard configurationAttFinishHandled == false else {
            return
        }
        
        configurationAttFinishHandled = true
        configurationCallback?()
    }
    
    private func checkAttributionFinished() {
        guard attributionFinished else {
            return
        }
        
        guard attributionFinishHandled == false else {
            return
        }
        attributionFinishHandled = true
        attributionCallback?()
    }
    
    private func checkConfiguration() {
        guard isConfigurationFinished else {
            return
        }
        
        guard configurationFinishHandled == false else {
            return
        }
        
        if attributionFinishHandled == false {
            attributionFinishHandled = true
            attributionCallback?()
        }
        
        configurationFinishHandled = true
        
        let configurationResult: ConfigurationResult = configurationRequiredFinished ? .completed : .requiredFailed
        waitingCallbacks.forEach { callback in
            callback(configurationResult)
        }
        waitingCallbacks.removeAll()
    }
}
