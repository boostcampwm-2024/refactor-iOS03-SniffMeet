//
//  Extension + CGImage.swift
//  SniffMeet
//
//  Created by Kelly Chui on 1/17/25.
//

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

struct CGImageCoder {
    func decode(from data: Data) -> CGImage? {
        let options: [CFString: Any] = [kCGImageSourceShouldCache: false]
        guard let imageSource = CGImageSourceCreateWithData(
            data as CFData,
            options as CFDictionary
        ) else {
            return nil
        }
        return CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
    }
    
    func encode(from cgImage: CGImage, as format: UTType) -> Data? {
        guard let mutableData = CFDataCreateMutable(nil, 0),
              let destination = CGImageDestinationCreateWithData(
                mutableData, format.identifier as CFString, 1, nil
              ) else {
            return nil
        }
        CGImageDestinationAddImage(destination, cgImage, nil)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return mutableData as Data
    }
}
