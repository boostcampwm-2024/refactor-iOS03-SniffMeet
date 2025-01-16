//
//  CacheManager.swift
//  SniffMeet
//
//  Created by 윤지성 on 12/4/24.
//

import Foundation

protocol ImageCacheable {
    func save(urlString: String, lastModified: String?, imageData: Data?) async
    func image(urlString: String) async -> CacheableImage?
}

actor DiskCacheManager {
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var usageOrder: [String] = []
    private let cacheLimit: Int = 50
    private let cacheDirectoryPath: URL

    init(cacheDirectoryPath: URL) {
        self.cacheDirectoryPath = cacheDirectoryPath
        if let content = try? FileManager.default.contentsOfDirectory(atPath: cacheDirectoryPath.path) {
            usageOrder = content
        }
    }

    func saveToDist(urlString: String, cacheableImage: CacheableImage) async throws {
        let data = try encoder.encode(cacheableImage)

        if !FileManager.default.fileExists(atPath: cacheDirectoryPath.path) {
            try FileManager.default.createDirectory(at: cacheDirectoryPath, withIntermediateDirectories: true, attributes: nil)
        }
        try data.write(to: cacheDirectoryPath.appendingPathComponent(urlString))
        await updateDiskUsageOrder(urlString: urlString)
        await removeOldestDiskImage()
        printDiskCacheDirectory()
    }

    func loadFromDist(urlString: String) async throws -> CacheableImage? {
        let filePath = cacheDirectoryPath.appendingPathComponent(urlString)
        guard FileManager.default.fileExists(atPath: filePath.path) else { return nil }

        let data = try Data(contentsOf: filePath)
        await updateDiskUsageOrder(urlString: urlString)
        return try decoder.decode(CacheableImage.self, from: data)
    }

    private func updateDiskUsageOrder(urlString: String) async {
        if let index = usageOrder.firstIndex(of: urlString) {
            usageOrder.remove(at: index)
        }
        usageOrder.append(urlString)
    }

    private func removeOldestDiskImage() async {
        SNMLogger.info("usageOrderCount: \(usageOrder.count)")
        while usageOrder.count > cacheLimit {
            guard let oldestKey = usageOrder.first else { return }
            usageOrder.removeFirst()

            let filePath = cacheDirectoryPath.appendingPathComponent(oldestKey)
            do {
                try FileManager.default.removeItem(at: filePath)
                SNMLogger.info("Removed disk image: \(oldestKey)")
            } catch {
                SNMLogger.error("Failed to remove disk image: \(oldestKey): \(error)")
            }
        }
    }

    private func printDiskCacheDirectory() {
        SNMLogger.info("Disk cache directory: \(cacheDirectoryPath.path)")

        if let contents = try? FileManager.default.contentsOfDirectory(atPath: cacheDirectoryPath.path) {
            SNMLogger.info("Disk cache contents: \(contents)")
        }
    }
}

final class ImageNSCacheManager {
    static let shared = ImageNSCacheManager()
    
    private let cache: NSCache<NSString, CacheableImage>
    private let diskCacheManager: DiskCacheManager

    private init(
        cache: NSCache<NSString, CacheableImage> = NSCache<NSString, CacheableImage>()
    ) {
        self.cache = cache
        let cachesURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let diskCacheURL = cachesURL.appendingPathComponent("DownloadedCache")
        self.diskCacheManager = DiskCacheManager(cacheDirectoryPath: diskCacheURL)

        cache.totalCostLimit = 5 * 1024 * 1024 // 5MB
    }
    
    func saveMemoryCache(urlString: String, cacheableImage: CacheableImage) {
        cache.setObject(cacheableImage, forKey: urlString as NSString)
    }
    
    func saveDiskCache(urlString: String, cacheableImage: CacheableImage) async {
        do {
            try await diskCacheManager.saveToDist(urlString: urlString, cacheableImage: cacheableImage)
        } catch {
            SNMLogger.error("CacheManager-saveDiskCache: \(error.localizedDescription) ")
        }
    }
    
    func imageFromMemoryCache(urlString: String) -> CacheableImage? {
        return cache.object(forKey: urlString as NSString)
    }
    
    func imageFromDiskCache(urlString: String) async -> CacheableImage? {
        do {
            return try await diskCacheManager.loadFromDist(urlString: urlString)
        } catch {
            SNMLogger.error("CacheManager-imageFromDiskCache: \(error.localizedDescription) ")
            return nil
        }
    }
}

extension ImageNSCacheManager: ImageCacheable {
    func save(urlString: String, lastModified: String?, imageData: Data?) async {
        guard let lastModified,
              let imageData else { return }
        let cacheableImage = CacheableImage(lastModified: lastModified, imageData: imageData)
        
        saveMemoryCache(urlString: urlString, cacheableImage: cacheableImage)
        await saveDiskCache(urlString: urlString, cacheableImage: cacheableImage)
    }
    
    func image(urlString: String) async -> CacheableImage? {
        if let image = imageFromMemoryCache(urlString: urlString) { // 메모리 캐시 hit
            SNMLogger.info("memory cache hit")
            return image
        }
        if let image = await imageFromDiskCache(urlString: urlString) { // 디스크 캐시 hit
            SNMLogger.info("disk cache hit")
            saveMemoryCache(urlString: urlString, cacheableImage: image)
            return image
        }
        // 모두 miss
        return nil
    }
}
