//
//  Session.swift
//  HTTPTransport
//
//  Created by Jeorge Taflanidi
//  Copyright © 2017 RedMadRobot LLC. All rights reserved.
//


import Alamofire
import Foundation


/**
 TCP/HTTP session between client and server.
 
 Includes security settings (see `Security`) and request retry strategy (see `HTTPTransportRetrier`).
 */
open class Session {

    /**
     `Session` stands for URLSession reusage.
     
     Includes security settings and request retry strategy.
     */
    public let manager: Alamofire.Session

    /**
     Initializer.
     
     - parameter manager: Alamofire's `Session`.
     */
    public init(
        manager: Alamofire.Session
    ) {
        self.manager = manager
    }

    /**
     Default initializer with zero no-evaluation security preset.
     */
    public convenience init() {
        self.init(security: Security.noEvaluation)
    }

    /**
     Initializer for cases, if `Session` couldn't be reused.
     
     - parameter Security: SSL pinning policy;
     - parameter retrier: HTTP request retry policy.
     */
    public init(
        security: Security,
        retrier: HTTPTransportRetrier? = nil
    ) {
        self.manager = Alamofire.Session(startRequestsImmediately: true,
                                         interceptor: retrier,
                                         serverTrustManager: security.trustPolicyManager)
    }

}
