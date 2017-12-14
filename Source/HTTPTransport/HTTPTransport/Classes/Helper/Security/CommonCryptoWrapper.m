//
//  CommonCryptoWrapper.m
//  Transport
//
//  Created by Mikhail Konovalov on 21/06/2017.
//  Copyright © 2017 RedMadRobot LLC. All rights reserved.
//

#import "CommonCryptoWrapper.h"
#import <CommonCrypto/CommonCrypto.h>

// MARK: - CommonCrypto constants

int ccSha1DigestLenght() {
    return CC_SHA1_DIGEST_LENGTH;
}

int ccSha256DigestLenght() {
    return CC_SHA256_DIGEST_LENGTH;
}

// MARK: - CommonCrypto SHA-calculating

unsigned char *ccSha1(const void *data, uint32_t len, unsigned char *md) {
    return CC_SHA1(data, len, md);
}

unsigned char *ccSha256(const void *data, uint32_t len, unsigned char *md) {
    return CC_SHA256(data, len, md);
}
