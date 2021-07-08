//
//  TrustPolicy.swift
//  HTTPTransport
//
//  Created by Jeorge Taflanidi
//  Copyright © 2021 RedMadRobot LLC & Incetro Inc. All rights reserved.
//

import Alamofire

// MARK: - Aliases

public typealias ServerTrustCheckMethod = (_ serverTrust: SecTrust, _ host: String) -> (Bool)

// MARK: - Useful

public func createServerTrustCheckMethod(certificateFingerprintSHA1: String) -> ServerTrustCheckMethod {
    { (serverTrust: SecTrust, host: String) -> (Bool) in
        if !checkDomainName(serverTrust, host: host) {
            return false
        }
        // "Fingerprint" check:
        let serverCertificate = SecTrustGetCertificateAtIndex(serverTrust, 0);
        guard let certificate = serverCertificate
        else {
            return false
        }
        let certificateSha1 = hexadecimalString(certificateSHA1(certificate))
        return certificateSha1.lowercased() == certificateFingerprintSHA1.lowercased()
    }
}

public func createServerTrustCheckMethod(certificateFingerprintSHA256: String) -> ServerTrustCheckMethod {
    { (serverTrust: SecTrust, host: String) -> (Bool) in
        if !checkDomainName(serverTrust, host: host) {
            return false
        }
        // "Fingerprint" check:
        let serverCertificate = SecTrustGetCertificateAtIndex(serverTrust, 0);
        guard let certificate = serverCertificate
        else {
            return false
        }
        let certificateSha256 = hexadecimalString(certificateSHA256(certificate))
        return certificateSha256.lowercased() == certificateFingerprintSHA256.lowercased()
    }
}

public func createServerTrustCheckMethod(certificatePublicKeyFingerprint: String) -> ServerTrustCheckMethod {
    { (serverTrust: SecTrust, host: String) -> (Bool) in
        if !checkDomainName(serverTrust, host: host) {
            return false
        }
        // Retrieve public key:
        let serverCertificatePublicKeyRef = SecTrustCopyPublicKey(serverTrust)
        guard let serverCertificatePublicKey = serverCertificatePublicKeyRef
        else {
            return false
        }
        let publicKeyDataRef: Data?
        if #available(iOS 10.0, *) {
            publicKeyDataRef = SecKeyCopyExternalRepresentation(serverCertificatePublicKey, nil) as Data?
        } else {
            publicKeyDataRef = copyExternalRepresentation_legacy(serverCertificatePublicKey)
        }
        guard let publicKeyData = publicKeyDataRef
        else {
            return false
        }
        let publicKeyDataString = hexadecimalString(publicKeyData)
        return publicKeyDataString.lowercased() == certificatePublicKeyFingerprint.lowercased()
    }
}

public func createServerTrustDebugMethod() -> ServerTrustCheckMethod {
    { (serverTrust: SecTrust, host: String) -> (Bool) in
        let publicKeyDataString: String
        let certificateSha1: String
        let certificateSha256: String
        // Retrieve public key:
        let serverCertificatePublicKeyRef = SecTrustCopyPublicKey(serverTrust)
        if let serverCertificatePublicKey = serverCertificatePublicKeyRef {
            let publicKeyDataRef: Data?
            if #available(iOS 10.0, *) {
                publicKeyDataRef = SecKeyCopyExternalRepresentation(serverCertificatePublicKey, nil) as Data?
            } else {
                publicKeyDataRef = copyExternalRepresentation_legacy(serverCertificatePublicKey)
            }
            if let publicKeyData = publicKeyDataRef {
                publicKeyDataString = hexadecimalString(publicKeyData)
            } else {
                publicKeyDataString = "PUBLIC KEY NOT EXTRACTED: could not convert SecKey to Data"
            }
        } else {
            publicKeyDataString = "PUBLIC KEY NOT EXTRACTED: SecTrustCopyPublicKey() method failure)"
        }
        // Retrieve certificate
        let serverCertificate = SecTrustGetCertificateAtIndex(serverTrust, 0);
        if let certificate = serverCertificate {
            certificateSha1 = hexadecimalString(certificateSHA1(certificate))
            certificateSha256 = hexadecimalString(certificateSHA256(certificate))
        } else {
            certificateSha1 = "CERTIFICATE NOT EXTRACTED: SecTrustGetCertificateAtIndex() method failure"
            certificateSha256 = certificateSha1
        }
        print("*** SERVER TRUST DEBUG\n  HOST: \(host)\n  CERTIFICATE PUBLIC KEY:\n\(publicKeyDataString)\n  CERTIFICATE SHA1 HASH: \(certificateSha1)\n  CERTIFICATE SHA256 HASH: \(certificateSha256)\n*** END")
        return true
    }
}

public func checkDomainName(_ serverTrust: SecTrust, host: String) -> Bool {
    let policies = [SecPolicyCreateSSL(true, host as CFString?)]
    SecTrustSetPolicies(serverTrust, policies as CFTypeRef);
    var isValid = false
    var result = SecTrustResultType.invalid
    let status = SecTrustEvaluate(serverTrust, &result)
    if status == errSecSuccess {
        let unspecified = SecTrustResultType.unspecified
        let proceed     = SecTrustResultType.proceed
        isValid = result == unspecified || result == proceed
    }
    return isValid
}

public func hexadecimalString(_ data: Data) -> String {
    let buffer = (data as NSData).bytes.bindMemory(to: UInt8.self, capacity: data.count)
    var hexadecimalString = ""
    for i in 0..<data.count {
        hexadecimalString += String(format: "%02x", buffer.advanced(by: i).pointee)
    }
    return hexadecimalString
}

public func certificateSHA1(_ certificate: SecCertificate) -> Data {
    let data = SecCertificateCopyData(certificate)
    let inData = Data(bytes: UnsafePointer<UInt8>(CFDataGetBytePtr(data)), count: CFDataGetLength(data))
    let outData = inData.algoWith(algoType: .sha1)
    return outData
}

public func certificateSHA256(_ certificate: SecCertificate) -> Data {
    let data = SecCertificateCopyData(certificate)
    let inData = Data(bytes: UnsafePointer<UInt8>(CFDataGetBytePtr(data)), count: CFDataGetLength(data))
    let outData = inData.algoWith(algoType: .sha256)
    return outData
}

// TODO: Retain workaround below until iOS9 is deprecated
func copyExternalRepresentation_legacy(_ publicKey: SecKey) -> Data? {
    let keychainTag: NSString = "X509_TAG"
    var publicKeyData: AnyObject?
    // Params for putting the key first
    var putKeyParams: [String: AnyObject] = [:]
    putKeyParams[kSecClass as String] = kSecClassKey
    putKeyParams[kSecAttrApplicationTag as String] = keychainTag
    putKeyParams[kSecValueRef as String] = publicKey
    putKeyParams[kSecReturnData as String] = kCFBooleanTrue // Request the key's data to be returned too
    // Params for deleting the data
    var delKeyParams: [String: AnyObject] = [:]
    delKeyParams[kSecClass as String] = kSecClassKey
    delKeyParams[kSecAttrApplicationTag as String] = keychainTag
    delKeyParams[kSecReturnData as String] = kCFBooleanTrue
    // Put the key
    _ = SecItemAdd(putKeyParams as CFDictionary, &publicKeyData)
    // Delete the key
    _ = SecItemDelete(delKeyParams as CFDictionary)
    if let publicKeyData: Data = publicKeyData as? Data {
        return publicKeyData
    } else {
        return nil
    }
}
