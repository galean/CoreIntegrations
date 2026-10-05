
import Foundation

//protocol ConfigurationManagerDelegate: AnyObject {
//    func onConfigurationFinish() // att + amplitude
//    func onAttributionFinish() // server + af
//    func onAttributionUpdated() // amplitude update
//    func onAttributionTimeout()
//}

/// Main thread only. Results from other threads enter through `perform(in:_:)`,
/// `handleCompleted(event:error:generation:)` and the timeout timer, each tied to the generation
/// it was started in and dropped on main if `reset()` has started the next one since.
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
    
    private var isAttributionFinishHandled = false

    private(set) var attributionFinishHandled: Bool {
        get {
            assertMainThread()
            return isAttributionFinishHandled
        }
        set {
            isAttributionFinishHandled = newValue
        }
    }
    
    var configurationFinishHandled = false

    private var currentGeneration = 0

    // Advanced by every `reset()`; each finish callback is handed the generation it was signed in.
    private(set) var generation: Int {
        get {
            assertMainThread()
            return currentGeneration
        }
        set {
            currentGeneration = newValue
        }
    }

    var statusForAnalytics: [String: String] {
        assertMainThread()
        return model.statusDescription
    }
    
    private var isConfigurationFinished: Bool {
        return isTimerFinished || model.checkAllEventsFinished()
    }

    init(allConfigurationEvents: [any ConfigurationEvent], isFirstStart: Bool, timeout: Int = 6) {
        model = CoreConfigurationModel(allConfigurationEvents: allConfigurationEvents, isFirstStart: isFirstStart)
        self.timout = timeout
    }
    
    init(model: CoreConfigurationModel, timeout: Int = 6) {
        self.model = model
        self.timout = timeout
    }
    
    public func reset() {
        assertMainThread()
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
        generation += 1
    }
    
    public func startTimoutTimer() {
        assertMainThread()
        guard self.isConfigurationFinished == false else {
            return
        }
        
        guard isTimerStarted == false else {
            return
        }
        
        isTimerStarted = true
        
        let generation = self.generation
        DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(timout)) { [weak self] in
            guard let self else { return }
            // A timer of a reset generation must not finish the next one.
            guard self.generation == generation else {
                return
            }
            guard self.isConfigurationFinished == false else {
                return
            }
            
            self.isTimerFinished = true
            self.checkConfiguration()
        }
    }
    
    // Checks the generation once, on main, before `work` runs; an asynchronous step started
    // inside `work` needs its own check.
    func perform(in generation: Int, _ work: @escaping () -> Void) {
        MainQueueExecutor.perform { [weak self] in
            guard let self, self.generation == generation else { return }
            work()
        }
    }
    
    public func handleCompleted(event: any ConfigurationEvent, error: Error?) {
        assertMainThread()
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
    
    func handleCompleted(event: any ConfigurationEvent, error: Error?, generation: Int) {
        perform(in: generation) {
            self.handleCompleted(event: event, error: error)
        }
    }
    
    public func signForConfigurationEnd(_ callback: @escaping (ConfigurationResult, Int) -> Void) {
        assertMainThread()
        let generation = self.generation
        guard !isConfigurationFinished else {
            let configurationResult: ConfigurationResult = model.checkRequiredEventsFinished() ? .completed : .requiredFailed
            callback(configurationResult, generation)
            return
        }
        waitingCallbacks.append { configurationResult in
            callback(configurationResult, generation)
        }
    }
    
    // A finish signed in an earlier generation must not be reported once `reset()` has started
    // the next one; the guard stays as a safety net for such a finish.
    func isCurrent(generation: Int) -> Bool {
        assertMainThread()
        return self.generation == generation
    }
    
    public func signForAttAndConfigLoaded(_ callback: @escaping () -> Void) {
        assertMainThread()
        guard !configurationAttFinishHandled else {
            callback()
            return
        }
        configurationCallback = callback
    }
    
    public func signForAttributionFinished(_ callback: @escaping () -> Void) {
        assertMainThread()
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
        
        let generation = self.generation
        if attributionFinishHandled == false {
            attributionFinishHandled = true
            attributionCallback?()
        }
        // The attribution callback can reset (no-internet flow) and re-sign the next generation;
        // that generation finishes on its own events or timer, not with this one's result.
        guard generation == self.generation else {
            return
        }
        
        configurationFinishHandled = true
        
        let configurationResult: ConfigurationResult = model.checkRequiredEventsFinished() ? .completed : .requiredFailed
        waitingCallbacks.forEach { callback in
            callback(configurationResult)
        }
        waitingCallbacks.removeAll()
    }

    // Debug builds only: catches a caller that bypasses the hop to main.
    private func assertMainThread() {
        assert(Thread.isMainThread, "AppConfigurationManager is main-thread only")
    }
}
