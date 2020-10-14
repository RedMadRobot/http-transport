import Alamofire

public final class ClosureServerTrustEvaluating: ServerTrustEvaluating {
    
    enum CustomEvaluationError: Error {
        case conditionNotPassed
    }
    
    let closure: ServerTrustCheckMethod
    
    init(closure: @escaping ServerTrustCheckMethod) {
        self.closure = closure
    }
    public func evaluate(_ trust: SecTrust, forHost host: String) throws {
        guard closure(trust,host) else {
            throw AFError.serverTrustEvaluationFailed(reason: AFError.ServerTrustFailureReason.customEvaluationFailed(error: CustomEvaluationError.conditionNotPassed))
        }
    }
}
