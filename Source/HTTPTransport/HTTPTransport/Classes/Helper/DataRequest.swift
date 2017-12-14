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
    
    static func httpResponseSerializer(interceptors: [HTTPResponseInterceptor] = []) -> DataResponseSerializer<HTTPResponse> {
        return DataResponseSerializer { (
            request: URLRequest?,
            response: HTTPURLResponse?,
            data: Data?,
            error: Error?
        ) -> Alamofire.Result<HTTPResponse> in
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
                return Alamofire.Result<HTTPResponse>.failure(error)
            }

            guard let response: HTTPURLResponse = refinedRawResponse.response
            else {
                // NETWORK FAILURE
                return Alamofire.Result<HTTPResponse>.failure(NSError.noHTTPResponse)
            }
            
            let httpResponse: HTTPResponse = HTTPResponse(
                httpStatus:  HTTPStatusCode(httpURLResponse: response),
                headers: response.allHeaderFields as? [String: String] ?? [:],
                body: refinedRawResponse.data ?? Data(),
                request: refinedRawResponse.request
            )

            return Alamofire.Result<HTTPResponse>.success(httpResponse)
        }
    }

    @discardableResult
    func responseHTTP(
        queue: DispatchQueue? = nil,
        interceptors: [HTTPResponseInterceptor] = [],
        completionHandler: @escaping (DataResponse<HTTPResponse>) -> Void
    ) -> Self {
        return response(
            queue: queue,
            responseSerializer: DataRequest.httpResponseSerializer(interceptors: interceptors),
            completionHandler: completionHandler
        )
    }
    
}
