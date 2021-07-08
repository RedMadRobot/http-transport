//
//  RawResponse.swift
//  HTTPTransport
//
//  Created by Alexander Lezya on 07.07.2021.
//  Copyright © 2021 RedMadRobot LLC & Incetro Inc. All rights reserved.
//

// MARK: - RawResponse

/// Model for raw HTTP response with or without incoming error and data
public struct RawResponse {

    // MARK: - Properties

    public let request:  URLRequest?
    public let response: HTTPURLResponse?
    public let data:     Data?
    public let error:    Error?

    /// Default initializer
    /// - Parameters:
    ///   - request: url request
    ///   - response: http url response
    ///   - data: some data
    ///   - error: some error
    public init(
        request: URLRequest?,
        response: HTTPURLResponse?,
        data: Data?,
        error: Error?
    ) {
        self.request = request
        self.response = response
        self.data = data
        self.error = error
    }
}
