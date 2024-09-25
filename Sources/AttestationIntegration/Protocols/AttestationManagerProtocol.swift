
protocol AttestationManagerProtocol {
    var isSupported: Bool { get async }
    var attestKeyId: String? { get async }
    func generateKey() async throws -> String
    func createAssertion() async throws -> AttestationManagerResult
}
