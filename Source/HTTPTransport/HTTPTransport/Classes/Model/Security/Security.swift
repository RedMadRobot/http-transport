//
//  Security.swift
//  HTTPTransport
//
//  Created by Jeorge Taflanidi
//  Copyright © 2017 RedMadRobot LLC. All rights reserved.
//


import Alamofire
import Foundation


/**
 SSL pinning policy.
 */
open class Security {

    /**
     Alamofire's `ServerTrustPolicyManager`.
     */
    public let trustPolicyManager: ServerTrustPolicyManager

    /**
     Default SSL pinning policy: disabled.
     */
    open class var noEvaluation: Security {
        return Security(trustPolicyManager: TrustPolicyManager.noEvaluation)
    }

    /**
     Initializer.
     
     - parameter trustPolicyManager: Alamofire's `ServerTrustPolicyManager`.
     */
    public init(trustPolicyManager: ServerTrustPolicyManager) {
        self.trustPolicyManager = trustPolicyManager
    }

    /**
     Convinience initializer for cases, when you'd like to ommit importing Alamofire.
     
     - parameter certificates: collection of `TrustPolicyManager.Certificate` objects 
     (each is actually a pair "host: fingerprint").
     */
    public convenience init(certificates: [TrustPolicyManager.Certificate]) {
        self.init(trustPolicyManager: TrustPolicyManager(certificates: certificates))
    }

}
