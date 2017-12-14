//
//  HTTPCookie.swift
//  HTTPTransport
//
//  Created by Jeorge Taflanidi
//  Copyright © 29 Heisei RedMadRobot LLC. All rights reserved.
//


import Foundation


/**
 Convenience initializer for Foundation HTTPCookie.
 */
public extension HTTPCookie {

    private static let stubURLAddress: String = "http://localhost"
    private static let stubPath:       String = "/"

    public convenience init(
        name: String,
        value: String
    ) {
        let cookieProperties: [HTTPCookiePropertyKey: String] = [
            HTTPCookiePropertyKey.name: name,
            HTTPCookiePropertyKey.value: value,
            HTTPCookiePropertyKey.path: HTTPCookie.stubPath,
            HTTPCookiePropertyKey.originURL: HTTPCookie.stubURLAddress,
        ]

        self.init(properties: cookieProperties)!
    }

}
