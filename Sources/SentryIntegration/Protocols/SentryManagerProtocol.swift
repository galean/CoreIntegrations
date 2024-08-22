
import Foundation

public protocol SentryManagerProtocol {
    func configure(_ data: SentryConfigData)
    func setUserID(_ userID: String)
    func log(_ error: Error)
    func log(_ exception: NSException)
    func log(_ message: String)
}
