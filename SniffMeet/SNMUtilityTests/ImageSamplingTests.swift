//
//  UtilityTest.swift
//  UtilityTest
//
//  Created by Kelly Chui on 1/16/25.
//

import CoreGraphics
import Foundation
import ImageIO
import XCTest

final class ImageSamplingTests: XCTestCase {
    private var imageSampler: (any ImageSampleable)!
    
    override func setUp() {
        super.setUp()
        self.imageSampler = ImageSampler()
    }
    
    func test_입력으로_들어온_가로가_더_긴_이미지를_프로필에_맞게_다운스케일링_한다() async {
        if let testImage = makeTestImage(width: 6000, height: 2000)?.jpgData,
           let downscaledImage = try? await imageSampler.downscaleImage(
            from: testImage,
            targetSize: ImageConstants.profileTargetSize,
            croppingTo: nil
           ) {
            XCTAssertEqual(
                CGImage.createFromData(data: downscaledImage)?.height,
                Int(ImageConstants.profileTargetSize.height),
                "세로 크기가 목표 크기와 같아야 한다."
            )
        } else {
            XCTFail("이미지 생성 실패")
        }
    }
    
    func test_입력으로_들어온_세로가_더_긴_이미지를_프로필에_맞게_다운스케일링_한다() async {
        if let testImage = makeTestImage(width: 2000, height: 6000)?.jpgData,
           let downscaledImage = try? await imageSampler.downscaleImage(
            from: testImage,
            targetSize: ImageConstants.profileTargetSize,
            croppingTo: nil
           ) {
            XCTAssertEqual(
                CGImage.createFromData(data: downscaledImage)?.width,
                Int(ImageConstants.profileTargetSize.width),
                "가로 크기가 목표 크기와 같아야 한다."
            )
        } else {
            XCTFail("이미지 생성 실패")
        }
    }
    
    func test_썸네일_이미지_크기에_맞게_다운샘플링_한다() async {
        if let testImage = makeTestImage(width: 2000, height: 6000)?.jpgData,
           let downscaledImage = try? await imageSampler.downscaleImage(
            from: testImage,
            targetSize: ImageConstants.thumbnailSize,
            croppingTo: ImageConstants.thumbnailSize
           ),
           let cgImage = CGImage.createFromData(data: downscaledImage) {
            XCTAssertEqual(
                cgImage.height,
                Int(ImageConstants.thumbnailSize.height),
                "100 * 100 사이즈 이미지이어야 한다."
            )
            XCTAssertEqual(
                cgImage.width,
                Int(ImageConstants.thumbnailSize.width),
                "100 * 100 사이즈 이미지이어야 한다."
            )
        } else {
            XCTFail("이미지 생성 실패")
        }
    }
    
    func makeTestImage(width: CGFloat, height: CGFloat) -> CGImage? {
        let size = CGSize(width: width, height: height)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }
        context.setFillColor(UIColor.white.cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        return context.makeImage()
    }
    
    private enum ImageConstants {
        static let profileTargetSize = CGSize(width: 392, height: 591)
        static let thumbnailSize = CGSize(width: 100, height: 100)
    }
}
