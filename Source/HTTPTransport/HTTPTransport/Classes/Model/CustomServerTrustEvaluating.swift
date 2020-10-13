import Alamofire

enum CustomEvaluationError: Error {
    case invalidEvaluation
}

public final class CustomServerTrustEvaluating: ServerTrustEvaluating {
    
    let closure: ServerTrustCheckMethod
    
    init(closure: @escaping ServerTrustCheckMethod) {
        self.closure = closure
    }
    public func evaluate(_ trust: SecTrust, forHost host: String) throws {
        guard closure(trust,host) else {
            throw AFError.serverTrustEvaluationFailed(reason: AFError.ServerTrustFailureReason.customEvaluationFailed(error: CustomEvaluationError.invalidEvaluation))
        }
    }
}
