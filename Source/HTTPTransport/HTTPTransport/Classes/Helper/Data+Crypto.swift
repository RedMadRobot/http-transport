import CommonCrypto

typealias AlgoClosure = (_ data: UnsafeRawPointer?, _ len: CC_LONG, _ md: UnsafeMutablePointer<UInt8>?) -> UnsafeMutablePointer<UInt8>?

extension Data {
    
    enum CryptoAlgo {
        case sha1
        case sha256
        
        var length: Int32 {
            switch self {
            case .sha1:
                return CC_SHA1_DIGEST_LENGTH
            case .sha256:
                return CC_SHA256_DIGEST_LENGTH
            }
        }
        
        var algo: AlgoClosure {
            switch self {
            case .sha1:
                return CC_SHA1
            case .sha256:
            return CC_SHA256
            }
        }
    }
    
    func algoWith(algoType: CryptoAlgo) -> Data {
        var digest = Data(count: Int(algoType.length))
        _ = digest.withUnsafeMutableBytes{ mutableBytes in
            withUnsafeBytes{ messageBytes in
                algoType.algo(messageBytes.baseAddress, CC_LONG(count), mutableBytes.bindMemory(to: UInt8.self).baseAddress);
            }
        }
        return digest;
    }
}
