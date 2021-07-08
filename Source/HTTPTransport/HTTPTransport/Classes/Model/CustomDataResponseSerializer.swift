//
//  CustomDataResponseSerializer.swift
//  HTTPTransport
//
//  Created by Alexander Lezya on 07.07.2021.
//  Copyright © 2021 RedMadRobot LLC & Incetro Inc. All rights reserved.
//

import Alamofire

// MARK: - CustomDataResponseSerializer

public final class CustomDataResponseSerializer<Value>: DataResponseSerializerProtocol {

    // MARK: - Aliases
    
    public typealias SerializedObject = Value

    // MARK: - Properties
    
    public var serializeResponse: (URLRequest?, HTTPURLResponse?, Data?, Error?) throws -> Value

    // MARK: - Initialazers

    /// Default initializer
    /// - Parameter serializeResponse: serialize response
    public init(
        serializeResponse: @escaping (URLRequest?, HTTPURLResponse?, Data?, Error?) throws -> Value
    ) {
        self.serializeResponse = serializeResponse
    }

    // MARK: - Useful
    
    public func serialize(
        request: URLRequest?,
        response: HTTPURLResponse?,
        data: Data?,
        error: Error?
    ) throws -> Value {
        try serializeResponse(request, response, data, error)
    }
}
