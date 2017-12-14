//
//  CommonCryptoWrapper.h
//  Transport
//
//  Created by Mikhail Konovalov on 21/06/2017.
//  Copyright © 2017 RedMadRobot LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 SHA1 Digest lenght
 */
extern int ccSha1DigestLenght();

/**
 SHA256 Digest lenght
 */
extern int ccSha256DigestLenght();

/**
 Calculate SHA1 Digest.
 */
extern unsigned char *ccSha1(const void *data, uint32_t len, unsigned char *md);

/**
 Calculate SHA256 Digest.
 */
extern unsigned char *ccSha256(const void *data, uint32_t len, unsigned char *md);



