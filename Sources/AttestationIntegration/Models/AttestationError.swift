
enum AttestationError: Error {
    case attestVerificationFailed(_ warning: String?)
    case attestNotSupported(_ warning: String?)
    case assertionFailed(_ warning: String?)
    
    case keyIdRequired(_ warning: String?)
    case invalidAttestationOrBypassKey(_ warning: String?)
    case unknownError(_ warning: String?)
    
    case unenforcedBypass(_ warning: String?)
    case bypassError(_ warning: String?)
}
