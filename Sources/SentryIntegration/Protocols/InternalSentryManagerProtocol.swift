
import Foundation

public protocol InternalSentryManagerProtocol {
    func configure(_ data: SentryConfigData)
    func setUserID(_ userID: String)
    func log(_ error: Error)
    func log(_ exception: NSException)
    func log(_ message: String)
    func pauseAppHangTracking()
    func resumeAppHangTracking()
}

public protocol PublicSentryManagerProtocol {
    func log(_ error: Error)
    func log(_ exception: NSException)
    func log(_ message: String)
    func pauseAppHangTracking()
    func resumeAppHangTracking()
}
