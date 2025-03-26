
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

    var statusForAnalytics: [String: String] {
        return model.statusDescription
    }
    
    private var isConfigurationFinished: Bool {
        return isTimerFinished || model.checkAllEventsFinished()
    }

    init(allConfigurationEvents: [any ConfigurationEvent], isFirstStart: Bool, timeout: Int = 6) {
        model = CoreConfigurationModel(allConfigurationEvents: allConfigurationEvents, isFirstStart: isFirstStart)
        self.timout = timeout
    }
    
    public func reset() {
        model.completedEvents.removeAll()
        model.completionErrors.removeAll()
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
    
    public func handleCompleted(event: any ConfigurationEvent, error: Error?) {
        if !model.completedEvents.contains(where: { $0.key == event.key }) {
            model.completedEvents.append(event)
        }
        if let error {
            model.completionErrors[event.key] = error
        } else {
            model.completionErrors.removeValue(forKey: event.key)
        }
        checkConfiguration()
        checkATTConfiguration()
        checkAttributionFinished()
    }
    
    public func signForConfigurationEnd(_ callback: @escaping (ConfigurationResult) -> Void) {
        guard !isConfigurationFinished else {
            let configurationResult: ConfigurationResult = model.checkRequiredEventsFinished() ? .completed : .requiredFailed
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
        guard !model.checkAttributionFinished() else {
            callback()
            return
        }
        attributionCallback = callback
    }
    
    private func checkATTConfiguration() {
        guard model.checkAttAndConfigFinished() else {
            return
        }
        
        guard configurationAttFinishHandled == false else {
            return
        }
        
        configurationAttFinishHandled = true
        configurationCallback?()
    }
    
    private func checkAttributionFinished() {
        guard model.checkAttributionFinished() else {
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
        
        let configurationResult: ConfigurationResult = model.checkRequiredEventsFinished() ? .completed : .requiredFailed
        waitingCallbacks.forEach { callback in
            callback(configurationResult)
        }
        waitingCallbacks.removeAll()
    }
}
