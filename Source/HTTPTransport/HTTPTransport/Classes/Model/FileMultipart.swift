//
//  FileMultipart.swift
//  HTTPTransport
//
//  Created by Jeorge Taflanidi
//  Copyright © 28 Heisei RedMadRobot LLC. All rights reserved.
//


import Foundation


/**
 File data and metadata struct, helps multipart file serialization.
 */
public struct FileMultipart {

    /**
     File data.
     */
    public let fileData: Data

    /**
     File name.
     */
    public let fileName: String

    /**
     File MIME type.
     */
    public let mimeType: MIMEType

    /**
     Part name for multipart file serialization.
     */
    public let partName: String

    /**
     Initializer.
     */
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
