//
//  AddCookieInterceptor
//  HTTPTransport
//
//  Created by Jeorge Taflanidi
//  Copyright (c) 2017 RedMadRobot LLC. All rights reserved.
//


import Foundation


/**
 Attach cookies to HTTP requests.
 */
open class AddCookieInterceptor: HTTPRequestInterceptor {

    /**
     Cookie storage to get cookies from.
     */
    open let cookieProvider: CookieProviding

    public init(
        cookieProvider: CookieProviding
    ) {
        self.cookieProvider = cookieProvider
    }

    open override func intercept(request: URLRequest) -> URLRequest {
        let cookies: [HTTPCookie] = self.getCookies(fromRequest: request)

        var mutableRequest: URLRequest       = request
        var mutableHeaders: [String: String] = mutableRequest.allHTTPHeaderFields ?? [:]

        var newCookieString: String = ""
        for cookie in (cookies + self.cookieProvider.getStoredCookies()) {
            newCookieString += cookie.name + "=" + cookie.value + "; "
        }

        mutableHeaders["Cookie"] = newCookieString
        mutableRequest.allHTTPHeaderFields = mutableHeaders
        return mutableRequest
    }

}

// TODO: put into AddCookieInterceptor scope, when Swift will support nested protocols

/**
 The place from where to get cookies.
 */
public protocol CookieProviding {

    /**
     Cookies! OM NOM NOM
     */
    func getStoredCookies() -> [HTTPCookie]

}


private extension AddCookieInterceptor {

    func getCookies(fromRequest request: URLRequest) -> [HTTPCookie] {
        guard
            let headers: [String: String] = request.allHTTPHeaderFields,
            let rawCookiesString: String = headers["Cookie"]
        else { return [] }

        let rawCookies: [String: String] = rawCookiesString
            .components(separatedBy: ";")
            .map { (component: String) -> String in
                return component.trimmingCharacters(in: CharacterSet.whitespaces)
            }
            .reduce([:]) { (result: [String: String], component: String) -> [String: String] in
                let nameValue: [String] = component.components(separatedBy: "=")
                guard
                    nameValue.count == 2,
                    let name: String = nameValue.first,
                    let value: String = nameValue.last
                else { return result }

                var result: [String: String] = result
                result[name] = value

                return result
            }

        return rawCookies.keys
            .flatMap { (name: String) -> HTTPCookie? in
                let value: String = rawCookies[name]!
                return HTTPCookie(name: name, value: value)
            }
    }

}
