//
//  TrustPolicyManager.swift
//  HTTPTransport
//
//  Created by Jeorge Taflanidi
//  Copyright © 28 Heisei RedMadRobot LLC. All rights reserved.
//


import Foundation
import Alamofire


/**
 Custom wrapper over Alamofire's `ServerTrustPolicyManager`.
 
 Simplifies SSL pinning policy configuration. Allows using host name patterns for chosing SSL certificate, see method 
 `serverTrustPolicy(forHost:)`.
 */
open class TrustPolicyManager: ServerTrustPolicyManager {

    /**
     Disables SSL pinning for all hosts with a dot "." in their host name.
     */
    open class var noEvaluation: ServerTrustPolicyManager {
        return TrustPolicyManager(certificates: [Certificate.wildcard])
    }

    /**
     Initializer.
     
     - parameter certificates: collection of `Certificate` objects (each is actually a pair "host: fingerprint").
     */
    public init(certificates: [Certificate]) {
        var policies: [String: ServerTrustPolicy] = [:]

        certificates.forEach { (certificate: Certificate) in
            policies[certificate.host] = certificate.asTrustPolicy
        }

        super.init(policies: policies)
    }

    override open func serverTrustPolicy(forHost host: String) -> ServerTrustPolicy? {
        for (hostName, policy) in self.policies {
            if host.contains(hostName) || hostName.contains(host) {
                return policy
            }
        }
        return nil
    }

    /**
     A pair of host name and corresponding SSL certificate fingerprint.
     */
    public struct Certificate {

        /**
         Host name.
         */
        public let host:        String

        /**
         Host's SSL certificate fingerprint, see `Certificate.Fingerprint`.
         */
        public let fingerprint: Fingerprint

        /**
         Initializer.
         
         - parameter host: host name, e.g. "google.com";
         - parameter fingerprint: host's SSL certificate fingerprint.
         */
        public init(host: String, fingerprint: Fingerprint) {
            self.host = host
            self.fingerprint = fingerprint
        }

        /**
         Allow all hosts with a dot "." in their names have SSL pinning disabled.
         */
        public static var wildcard: Certificate {
            return Certificate(host: ".", fingerprint: Fingerprint.disable)
        }

        /**
         Convert `Certificate` to Alamofire's `ServerTrustPolicy`.
         */
        public var asTrustPolicy: ServerTrustPolicy {
            switch self.fingerprint {
                case Certificate.Fingerprint.sha1(let fingerprint):
                    let closure = createServerTrustCheckMethod(certificateFingerprintSHA1: fingerprint)
                    return ServerTrustPolicy.customEvaluation(closure)

                case Certificate.Fingerprint.sha256(let fingerprint):
                    let closure = createServerTrustCheckMethod(certificateFingerprintSHA256: fingerprint)
                    return ServerTrustPolicy.customEvaluation(closure)

                case Certificate.Fingerprint.publicKey(let fingerprint):
                    let closure = createServerTrustCheckMethod(certificatePublicKeyFingerprint: fingerprint)
                    return ServerTrustPolicy.customEvaluation(closure)

                case Certificate.Fingerprint.debug:
                    let closure = createServerTrustDebugMethod()
                    return ServerTrustPolicy.customEvaluation(closure)

                case Certificate.Fingerprint.disable:
                    return ServerTrustPolicy.disableEvaluation
            }
        }

        /**
         Possible SSL certificate fingerprint's representations.
         */
        public enum Fingerprint {
            /**
             SHA1 fingerprint.
             */
            case sha1(fingerprint: String)

            /**
             SHA256 fingerprint.
             */
            case sha256(fingerprint: String)

            /**
             Public key fingerprint.
             */
            case publicKey(fingerprint: String)

            /**
             Print out host with its certificate SHA1, SHA256 and public key fingerprints.
             */
            case debug

            /**
             No fingerprint, no SSL pinning.
             */
            case disable
        }
    }

}
