//
//  AddCookieInterceptor
//  HTTPTransport
//
//  Created by Jeorge Taflanidi
//  Copyright (c) 2021 RedMadRobot LLC & Incetro Inc. All rights reserved.
//

// MARK: - AddCookieInterceptor

/// Attach cookies to HTTP requests
open class AddCookieInterceptor {

    // MARK: - Properties

    /// Cookie storage to get cookies from
    public let cookieProvider: CookieProviding

    // MARK: - Initializers

    /// Default initializers
    /// - Parameter cookieProvider: cookie storage
    public init(cookieProvider: CookieProviding) {
        self.cookieProvider = cookieProvider
    }
}

// MARK: - HTTPRequestInterceptor

extension AddCookieInterceptor: HTTPRequestInterceptor {

    open func intercept(request: URLRequest) -> URLRequest {
        let cookies = getCookies(fromRequest: request)
        var mutableRequest = request
        var mutableHeaders = mutableRequest.allHTTPHeaderFields ?? [:]
        var newCookieString = ""
        for cookie in (cookies + cookieProvider.getStoredCookies()) {
            newCookieString += cookie.name + "=" + cookie.value + "; "
        }
        mutableHeaders["Cookie"] = newCookieString
        mutableRequest.allHTTPHeaderFields = mutableHeaders
        return mutableRequest
    }
}

// MARK: - Private

private extension AddCookieInterceptor {

    func getCookies(fromRequest request: URLRequest) -> [HTTPCookie] {
        guard
            let headers = request.allHTTPHeaderFields,
            let rawCookiesString = headers["Cookie"]
        else { return [] }
        let rawCookies = rawCookiesString
            .components(separatedBy: ";")
            .map { (component: String) -> String in
                component.trimmingCharacters(in: CharacterSet.whitespaces)
            }
            .reduce([:]) { (result: [String: String], component: String) -> [String: String] in
                let nameValue = component.components(separatedBy: "=")
                guard
                    nameValue.count == 2,
                    let name = nameValue.first,
                    let value = nameValue.last
                else { return result }
                var result = result
                result[name] = value
                return result
            }
        return rawCookies.keys
            .compactMap { (name: String) -> HTTPCookie? in
                let value = rawCookies[name]!
                return HTTPCookie(name: name, value: value)
            }
    }
}
