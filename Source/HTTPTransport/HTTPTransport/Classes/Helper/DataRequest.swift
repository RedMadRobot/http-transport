//
//  DataRequest.swift
//  HTTPTransport
//
//  Created by Jeorge Taflanidi
//  Copyright © 2017 RedMadRobot LLC. All rights reserved.
//


import Alamofire
import Foundation


/**
 Alamofire monkey patch.
 
 Allows intercepting HTTP responses & process response data.
 */
extension DataRequest {
    
    static func httpResponseSerializer(interceptors: [HTTPResponseInterceptor] = []) -> CustomDataResponseSerializerProtocol<HTTPResponse> {
        return CustomDataResponseSerializerProtocol { (
            request: URLRequest?,
            response: HTTPURLResponse?,
            data: Data?,
            error: Error?
        ) throws -> HTTPResponse in
            // COMPOSE A SINGLE RAW RESPONSE OBJECT
            let rawResponse: HTTPResponseInterceptor.RawResponse =
                HTTPResponseInterceptor.RawResponse(request: request, response: response, data: data, error: error)

            // REFINE RAW RESPONSE THROUGH INTERCEPTORS
            let refinedRawResponse = interceptors.reduce(rawResponse) { (
                currentRawResponse: HTTPResponseInterceptor.RawResponse,
                interceptor: HTTPResponseInterceptor
            ) -> HTTPResponseInterceptor.RawResponse in
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

    @discardableResult
    func responseHTTP(
        queue: DispatchQueue = .main,
        interceptors: [HTTPResponseInterceptor] = [],
        completionHandler: @escaping (AFDataResponse<HTTPResponse>) -> Void
    ) -> Self {
        let responseSerializer = DataRequest.httpResponseSerializer(interceptors: interceptors)
        return response(queue: queue,
                        responseSerializer: responseSerializer,
                        completionHandler: completionHandler)
    }
    
}
