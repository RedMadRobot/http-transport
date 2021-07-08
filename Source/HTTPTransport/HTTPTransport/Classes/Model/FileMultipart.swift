//
//  FileMultipart.swift
//  HTTPTransport
//
//  Created by Jeorge Taflanidi
//  Copyright © 2021 RedMadRobot LLC & Incetro Inc. All rights reserved.
//

// MARK: - FileMultipart

/// File data and metadata struct, helps multipart file serialization
public struct FileMultipart {

    // MARK: - Properties

    /// File data
    public let fileData: Data

    /// File name
    public let fileName: String

    /// File MIME type
    public let mimeType: MIMEType

    /// Part name for multipart file serialization
    public let partName: String

    // MARK: - Initializers

    /// Default initializer
    /// - Parameters:
    ///   - fileData: file data
    ///   - fileName: file name
    ///   - mimeType: file MIME type
    ///   - partName: part name of multipart file serialization
    public init(
        fileData: Data,
        fileName: String,
        mimeType: MIMEType,
        partName: String
    ) {
        self.fileData = fileData
        self.fileName = fileName
        self.mimeType = mimeType
        self.partName = partName
    }
}
