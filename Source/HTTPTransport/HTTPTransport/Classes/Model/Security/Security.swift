//
//  Security.swift
//  HTTPTransport
//
//  Created by Jeorge Taflanidi
//  Copyright © 2021 RedMadRobot LLC & Incetro Inc. All rights reserved.
//

import Alamofire

// MARK: - Security

/// SSL pinning policy
open class Security {

    // MARK: - Properties

    /// Alamofire's `ServerTrustPolicyManager`
    public let trustPolicyManager: ServerTrustManager

    /// Default SSL pinning policy: disabled
    open class var noEvaluation: Security {
        Security(trustPolicyManager: TrustPolicyManager.noEvaluation)
    }

    // MARK: - Initializers

    /// Default initializer
    /// - Parameter trustPolicyManager: Alamofire's `ServerTrustPolicyManager`
    public init(trustPolicyManager: ServerTrustManager) {
        self.trustPolicyManager = trustPolicyManager
    }

    /// Convinience initializer for cases, when you'd like to ommit importing Alamofire
    /// - Parameter certificates: collection of `TrustPolicyManager.Certificate` objects
    ///   - (each is actually a pair "host: fingerprint")
    public convenience init(certificates: [TrustPolicyManager.Certificate]) {
        self.init(trustPolicyManager: TrustPolicyManager(certificates: certificates))
    }
}
