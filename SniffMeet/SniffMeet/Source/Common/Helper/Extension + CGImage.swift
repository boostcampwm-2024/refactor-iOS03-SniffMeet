//
//  Extension + CGImage.swift
//  SniffMeet
//
//  Created by Kelly Chui on 1/17/25.
//

import CoreGraphics
import Foundation
import ImageIO

extension CGImage {
    static func createFromData(data: Data) -> CGImage? {
        let options: [CFString: Any] = [kCGImageSourceShouldCache: false]
        guard let imageSource = CGImageSourceCreateWithData(
            data as CFData,
            options as CFDictionary
        ) else {
            return nil
        }
        return CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
    }
    
    var jpgData: Data? {
        guard let mutableData = CFDataCreateMutable(nil, 0),
              let destination = CGImageDestinationCreateWithData(
                mutableData,
                "public.jpeg" as CFString,
                1,
                nil
              ) else {
            return nil
        }
        CGImageDestinationAddImage(destination, self, nil)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return mutableData as Data
    }
}
