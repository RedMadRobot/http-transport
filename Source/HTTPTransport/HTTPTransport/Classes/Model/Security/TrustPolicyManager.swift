//
//  TrustPolicyManager.swift
//  HTTPTransport
//
//  Created by Jeorge Taflanidi
//  Copyright © 2021 RedMadRobot LLC & Incetro Inc. All rights reserved.
//

import Alamofire

// MARK: - TrustPolicyManager

/// Custom wrapper over Alamofire's `ServerTrustPolicyManager`
/// Simplifies SSL pinning policy configuration. Allows using host name patterns for chosing SSL certificate,
///  see method `serverTrustPolicy(forHost:)`
open class TrustPolicyManager: ServerTrustManager {

    // MARK: - Properties

    /// Disables SSL pinning for all hosts with a dot "." in their host name
    open class var noEvaluation: ServerTrustManager {
        TrustPolicyManager(certificates: [Certificate.wildcard])
    }

    // MARK: - Initializers

    /// Default initializer
    /// - Parameter certificates: collection of `Certificate` objects (each is actually a pair "host: fingerprint")
    public init(certificates: [Certificate]) {
        var evaluators: [String: ServerTrustEvaluating] = [:]
        certificates.forEach { (certificate: Certificate) in
            evaluators[certificate.host] = certificate.asTrustPolicy
        }
        super.init(evaluators: evaluators)
    }

    // MARK: - Overrides

    override open func serverTrustEvaluator(forHost host: String) -> ServerTrustEvaluating? {
        for (hostName, policy) in self.evaluators {
            if host.contains(hostName) || hostName.contains(host) {
                return policy
            }
        }
        return nil
    }

    // MARK: - Certificate

    /// A pair of host name and corresponding SSL certificate fingerprint
    public struct Certificate {

        // MARK: - Properties

        /// Host name
        public let host: String

        /// Host's SSL certificate fingerprint, see `Certificate.Fingerprint`
        public let fingerprint: Fingerprint

        /// Allow all hosts with a dot "." in their names have SSL pinning disabled
        public static var wildcard: Certificate {
            Certificate(host: ".", fingerprint: Fingerprint.disable)
        }

        /// Convert `Certificate` to Alamofire's `ServerTrustPolicy`
        public var asTrustPolicy: ServerTrustEvaluating {
            switch fingerprint {
                case Certificate.Fingerprint.sha1(let fingerprint):
                    let closure = createServerTrustCheckMethod(certificateFingerprintSHA1: fingerprint)
                    return ClosureServerTrustEvaluating(closure: closure)
                case Certificate.Fingerprint.sha256(let fingerprint):
                    let closure = createServerTrustCheckMethod(certificateFingerprintSHA256: fingerprint)
                    return ClosureServerTrustEvaluating(closure: closure)
                case Certificate.Fingerprint.publicKey(let fingerprint):
                    let closure = createServerTrustCheckMethod(certificatePublicKeyFingerprint: fingerprint)
                    return ClosureServerTrustEvaluating(closure: closure)
                case Certificate.Fingerprint.debug:
                    let closure = createServerTrustDebugMethod()
                    return ClosureServerTrustEvaluating(closure: closure)
                case Certificate.Fingerprint.disable:
                    return DisabledTrustEvaluator()
            }
        }

        // MARK: - Initializers

        /// Default initializer
        /// - Parameters:
        ///   - host: host name, e.g. "google.com"
        ///   - fingerprint: fingerprint: host's SSL certificate fingerprint
        public init(host: String, fingerprint: Fingerprint) {
            self.host = host
            self.fingerprint = fingerprint
        }

        // MARK: - Fingerprint

        /// Possible SSL certificate fingerprint's representations
        public enum Fingerprint {

            // MARK: - Cases

            /// SHA1 fingerprint
            case sha1(fingerprint: String)

            /// SHA256 fingerprint
            case sha256(fingerprint: String)

            /// Public key fingerprint
            case publicKey(fingerprint: String)

            /// Print out host with its certificate SHA1, SHA256 and public key fingerprints
            case debug

            /// No fingerprint, no SSL pinning
            case disable
        }
    }
}
