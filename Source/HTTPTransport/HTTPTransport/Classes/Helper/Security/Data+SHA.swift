//
//  Data+SHA.swift
//  HTTPTransport
//
//  Created by Mikhail Konovalov on 20.06.17.
//  Copyright © 2017 RedMadRobot. All rights reserved.
//

import Foundation
import CommonCryptoWrapper

/** 
 Calculating SHA1 and SHA256 digest.
 */
internal extension Data {
    /**
     Calculate SHA1 Digest for Data.
     */
    var sha1: Data {
        let digestLength = Int(ccSha1DigestLenght())
        var digest = [UInt8](repeating: 0, count: digestLength)
        
        self.withUnsafeBytes {
            _ = ccSha1($0, UInt32(self.count), &digest)
        }
        
        return Data(bytes: digest)
    }
    
    /**
     Calculate SHA256 Digest for Data.
     */
    var sha256: Data {
        let digestLength = Int(ccSha256DigestLenght())
        var digest = [UInt8](repeating: 0, count: digestLength)
        
        self.withUnsafeBytes {
            _ = ccSha256($0, UInt32(self.count), &digest)
        }
        
        return Data(bytes: digest)
    }
}
