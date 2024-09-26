
enum AttestationError: Error {
    case attestVerificationFailed
    case attestNotSupported
    case assertionFailed
    
    case keyIdRequired
    case invalidAttestationOrBypassKey
    case unknownError
    
    case unenforcedBypass
    case bypassError
}
