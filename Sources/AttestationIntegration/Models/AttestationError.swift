
enum AttestationError: Error {
    case attestVerificationFailed(_ warning: [String: Any]?)
    case attestNotSupported(_ warning: [String: Any]?)
    case assertionFailed(_ warning: [String: Any]?)
    
    case keyIdRequired(_ warning: [String: Any]?)
    case invalidAttestationOrBypassKey(_ warning: [String: Any]?)
    case unknownError(_ warning: [String: Any]?)
    
    case unenforcedBypass(_ warning: [String: Any]?)
    case bypassError(_ warning: [String: Any]?)
}
