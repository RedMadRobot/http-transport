//
//  DataRequest.swift
//  HTTPTransport
//
//  Created by Jeorge Taflanidi
//  Copyright © 2021 RedMadRobot LLC & Incetro Inc. All rights reserved.
//

import Alamofire

// MARK: - DataRequest

/// Alamofire monkey patch
/// Allows intercepting HTTP responses & process response data.
extension DataRequest {
    
    static func httpResponseSerializer(
        interceptors: [HTTPResponseInterceptor] = []
    ) -> CustomDataResponseSerializer<HTTPResponse> {
        return CustomDataResponseSerializer { (
            request: URLRequest?,
            response: HTTPURLResponse?,
            data: Data?,
            error: Error?
        ) throws -> HTTPResponse in
            // COMPOSE A SINGLE RAW RESPONSE OBJECT
            let rawResponse = RawResponse(
                request: request,
                response: response,
                data: data,
                error: error
            )
            // REFINE RAW RESPONSE THROUGH INTERCEPTORS
            let refinedRawResponse = interceptors.reduce(rawResponse) { (
                currentRawResponse: RawResponse,
                interceptor: HTTPResponseInterceptor
            ) -> RawResponse in
                return interceptor.intercept(response: currentRawResponse)
            }
            if let error = refinedRawResponse.error {
                // GENERAL FAILURE
                throw error
            }
            guard let response: HTTPURLResponse = refinedRawResponse.response
            else {
                // NETWORK FAILURE
                throw NSError.noHTTPResponse
            }
            let httpResponse: HTTPResponse = HTTPResponse(
                httpStatus:  HTTPStatusCode(httpURLResponse: response),
                headers: response.allHeaderFields as? [String: String] ?? [:],
                body: refinedRawResponse.data ?? Data(),
                request: refinedRawResponse.request
            )
            return httpResponse
        }
    }

    @discardableResult func responseHTTP(
        queue: DispatchQueue = .main,
        interceptors: [HTTPResponseInterceptor] = [],
        completionHandler: @escaping (AFDataResponse<HTTPResponse>) -> Void
    ) -> Self {
        let responseSerializer = DataRequest.httpResponseSerializer(interceptors: interceptors)
        return response(
            queue: queue,
            responseSerializer: responseSerializer,
            completionHandler: completionHandler
        )
    }
}
