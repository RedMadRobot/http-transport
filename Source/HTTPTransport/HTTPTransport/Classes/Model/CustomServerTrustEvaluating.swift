//
//  ClosureServerTrustEvaluating.swift
//  HTTPTransport
//
//  Created by Alexander Lezya on 07.07.2021.
//  Copyright © 2021 RedMadRobot LLC & Incetro Inc. All rights reserved.
//

import Alamofire

// MARK: - ClosureServerTrustEvaluating

public final class ClosureServerTrustEvaluating {

    // MARK: - CustomEvaluationError
    
    enum CustomEvaluationError: Error {

        // MARK: - Cases

        case conditionNotPassed
    }

    // MARK: - Properties
    
    let closure: ServerTrustCheckMethod

    // MARK: - Initializers

    /// Default initializer
    /// - Parameter closure: closure
    init(closure: @escaping ServerTrustCheckMethod) {
        self.closure = closure
    }
}

// MARK: - ServerTrustEvaluating

extension ClosureServerTrustEvaluating: ServerTrustEvaluating {

    public func evaluate(_ trust: SecTrust, forHost host: String) throws {
        guard closure(trust, host) else {
            throw AFError.serverTrustEvaluationFailed(
                reason: AFError.ServerTrustFailureReason.customEvaluationFailed(
                    error: CustomEvaluationError.conditionNotPassed
                )
            )
        }
    }
}
