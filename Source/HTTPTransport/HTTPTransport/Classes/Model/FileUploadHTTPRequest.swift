//
//  FileUploadHTTPRequest.swift
//  HTTPTransport
//
//  Created by Jeorge Taflanidi
//  Copyright © 2021 RedMadRobot LLC & Incetro Inc. All rights reserved.
//

import Alamofire

// MARK: - FileUploadHTTPRequest

/// File upload HTTP request
open class FileUploadHTTPRequest: HTTPRequest {

    // MARK: - Proterties

    /// File data and metadata
    public let fileMultipart: FileMultipart

    // MARK: - Initializers

    /// Convenience initializer
    /// - Parameters:
    ///   - httpMethod: HTTP verb; default is GET
    ///   - endpoint: URL endpoint; default is ""
    ///   - headers: map of HTTP headers; default is empty map
    ///   - parameters: request parameters; default is empty list
    ///   - requestInterceptors: request interceptors; default is empty array
    ///   - responseInterceptors: response interceptors; default is empty array
    ///   - session: `Session` for this particular URLRequest; default is `None`, transport-defined
    ///   - timeout: `URLRequest` timeout
    ///   - fileData: file data
    ///   - partName: multipart part name for file data
    ///   - fileName: file name
    ///   - mimeType: file MIME type
    ///   - base: base `HTTPRequest` to inherit parameters from; default is `None`
    public convenience init(
        httpMethod: HTTPMethod = .get,
        endpoint: String = "",
        headers: [String: String] = [:],
        parameters: [HTTPRequestParameters] = [],
        requestInterceptors: [HTTPRequestInterceptor] = [],
        responseInterceptors: [HTTPResponseInterceptor] = [],
        session: Session? = nil,
        timeout: TimeInterval? = nil,
        fileData: Data,
        partName: String,
        fileName: String,
        mimeType: MIMEType,
        base: HTTPRequest? = nil
    ) {
        self.init(
            httpMethod: httpMethod,
            endpoint: endpoint,
            headers: headers,
            parameters: parameters,
            requestInterceptors: requestInterceptors,
            responseInterceptors: responseInterceptors,
            session: session,
            timeout: timeout,
            file: FileMultipart(fileData: fileData, fileName: fileName, mimeType: mimeType, partName: partName),
            base: base
        )
    }

    /// Default initializer
    /// - Parameters:
    ///   - httpMethod: HTTP verb; default is GET
    ///   - endpoint: URL endpoint; default is ""
    ///   - headers: map of HTTP headers; default is empty map
    ///   - parameters: request parameters; default is empty list
    ///   - requestInterceptors: request interceptors; default is empty array
    ///   - responseInterceptors: response interceptors; default is empty array
    ///   - session: `Session` for this particular URLRequest; default is `None`, transport-defined
    ///   - timeout: `URLRequest` timeout
    ///   - file: file data and metadata
    ///   - partName: multipart part name for file data
    ///   - base: base `HTTPRequest` to inherit parameters from; default is `None`
    public init(
        httpMethod: HTTPMethod = HTTPMethod.get,
        endpoint: String = "",
        headers: [String: String] = [:],
        parameters: [HTTPRequestParameters] = [],
        requestInterceptors: [HTTPRequestInterceptor] = [],
        responseInterceptors: [HTTPResponseInterceptor] = [],
        session: Session? = nil,
        timeout: TimeInterval? = nil,
        file: FileMultipart,
        base: HTTPRequest? = nil
    ) {
        self.fileMultipart = file
        super.init(
            httpMethod: httpMethod,
            endpoint: endpoint,
            headers: headers,
            parameters: parameters,
            requestInterceptors: requestInterceptors,
            responseInterceptors: responseInterceptors,
            session: session,
            timeout: timeout,
            base: base
        )
    }
}
