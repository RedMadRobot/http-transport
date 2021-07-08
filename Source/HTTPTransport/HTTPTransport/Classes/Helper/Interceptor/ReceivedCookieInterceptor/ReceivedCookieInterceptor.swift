//
//  ReceivedCookieInterceptor
//  HTTPTransport
//
//  Created by Jeorge Taflanidi
//  Copyright (c) 2021 RedMadRobot LLC & Incetro Inc. All rights reserved.
//

// MARK: - ReceivedCookieInterceptor

/// Intercept HTTP Set-Cookie headers and store received cookies
open class ReceivedCookieInterceptor {

    // MARK: - Properties

    /// Cookie storage to save cookies
    public let cookieStorage: CookieStoring

    // MARK: - Initializers

    /// Default initializer
    /// - Parameter cookieStorage: cookie storage
    public init(cookieStorage: CookieStoring) {
        self.cookieStorage = cookieStorage
    }
}

// MARK: - HTTPResponseInterceptor

extension ReceivedCookieInterceptor: HTTPResponseInterceptor {

    open func intercept(response: RawResponse) -> RawResponse {
        guard let cookies = getCookies(fromRawResponse: response) else { return response }
        cookieStorage.store(cookies: cookies)
        return response
    }
}

// MARK: - Private

private extension ReceivedCookieInterceptor {

    func getCookies(fromRawResponse rawResponse: RawResponse) -> [HTTPCookie]? {
        guard
            let headers = rawResponse.response?.allHeaderFields as? [String: String],
            let url = rawResponse.response?.url,
            headers["Set-Cookie"] != nil
        else { return nil }
        return HTTPCookie.cookies(
            withResponseHeaderFields: headers,
            for: url
        )
    }
}
