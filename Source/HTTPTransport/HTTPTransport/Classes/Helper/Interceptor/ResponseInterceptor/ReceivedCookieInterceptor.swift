//
//  ReceivedCookieInterceptor
//  HTTPTransport
//
//  Created by Jeorge Taflanidi
//  Copyright (c) 2017 RedMadRobot LLC. All rights reserved.
//


import Foundation


/**
 Intercept HTTP Set-Cookie headers and store received cookies.
 */
open class ReceivedCookieInterceptor: HTTPResponseInterceptor {

    /**
     Cookie storage to save cookies.
     */
    open let cookieStorage: CookieStoring

    public init(
        cookieStorage: CookieStoring
    ) {
        self.cookieStorage = cookieStorage
    }

    open override func intercept(
        response: HTTPResponseInterceptor.RawResponse
    ) -> HTTPResponseInterceptor.RawResponse {
        guard let cookies: [HTTPCookie] = self.getCookies(fromRawResponse: response)
        else { return response }

        self.cookieStorage.store(cookies: cookies)
        return response
    }

}

// TODO: put into ReceivedCookieInterceptor scope, when Swift will support nested protocols

/**
 The place where to store cookies.
 */
public protocol CookieStoring {

    /**
     Store Cookies!
     */
    func store(cookies: [HTTPCookie])

}


private extension ReceivedCookieInterceptor {

    func getCookies(
        fromRawResponse rawResponse: RawResponse
    ) -> [HTTPCookie]? {
        guard
            let headers: [String: String] = rawResponse.response?.allHeaderFields as? [String: String],
            let url: URL = rawResponse.response?.url,
            nil != headers["Set-Cookie"]
        else { return nil }

        return HTTPCookie.cookies(
            withResponseHeaderFields: headers,
            for: url
        )
    }

}
