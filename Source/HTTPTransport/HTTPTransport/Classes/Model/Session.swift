//
//  Session.swift
//  HTTPTransport
//
//  Created by Jeorge Taflanidi
//  Copyright © 2021 RedMadRobot LLC & Incetro Inc. All rights reserved.
//

import Alamofire

// MARK: - Session

/// TCP/HTTP session between client and server
/// Includes security settings (see `Security`) and request retry strategy (see `HTTPTransportRetrier`)
open class Session {

    // MARK: - Properties

    /// `Session` stands for URLSession reusage
    /// Includes security settings and request retry strategy
    public let manager: Alamofire.Session

    // MARK: - Initializers

    /// Default initializer
    /// - Parameter manager: Alamofire's `Session`
    public init(manager: Alamofire.Session) {
        self.manager = manager
    }

    /// Default initializer with zero no-evaluation security preset
    public convenience init() {
        self.init(security: Security.noEvaluation)
    }

    /// Initializer for cases, if `Session` couldn't be reused
    /// - Parameters:
    ///   - security: Security: SSL pinning policy
    ///   - retrier: HTTP request retry policy
    public init(
        security: Security,
        retrier: HTTPTransportRetrier? = nil
    ) {
        self.manager = Alamofire.Session(
            startRequestsImmediately: true,
            interceptor: retrier,
            serverTrustManager: security.trustPolicyManager
        )
    }
}
