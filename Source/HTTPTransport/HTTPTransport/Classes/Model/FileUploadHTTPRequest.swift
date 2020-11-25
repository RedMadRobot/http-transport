//
//  FileUploadHTTPRequest.swift
//  HTTPTransport
//
//  Created by Jeorge Taflanidi
//  Copyright © 2017 RedMadRobot LLC. All rights reserved.
//


import Alamofire
import Foundation


/**
 File upload HTTP request.
 */
open class FileUploadHTTPRequest: HTTPRequest {

    /**
     File data and metadata.
     */
    public let fileMultipart: FileMultipart

    /**
     Initializer.
     
     - parameter httpMethod: HTTP verb; default is GET;
     - parameter endpoint: URL endpoint; default is "";
     - parameter headers: map of HTTP headers; default is empty map;
     - parameter parameters: request parameters; default is empty list;
     - parameter interceptors: request interceptors; default is empty array;
     - parameter session: `Session` for this particular URLRequest; default is `None`, transport-defined;
     - parameter timeout: `URLRequest` timeout;
     - parameter fileData: file data;
     - parameter partName: multipart part name for file data;
     - parameter fileName: file name;
     - parameter mimeType: file MIME type;
     - parameter base: base `HTTPRequest` to inherit parameters from; default is `None`.
     */
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

    /**
     Initializer.
     
     - parameter httpMethod: HTTP verb; default is GET;
     - parameter endpoint: URL endpoint; default is "";
     - parameter headers: map of HTTP headers; default is empty map;
     - parameter parameters: request parameters; default is empty list;
     - parameter interceptors: request interceptors; default is empty array;
     - parameter session: `Session` for this particular URLRequest; default is `None`, transport-defined;
     - parameter timeout: `URLRequest` timeout;
     - parameter file: file data and metadata;
     - parameter base: base `HTTPRequest` to inherit parameters from; default is `None`.
     */
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
