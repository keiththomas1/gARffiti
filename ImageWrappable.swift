//
//  ImageWrappable.swift
//  ARKitInteraction
//
//  Created by Keith Thomas on 9/4/18.
//  Copyright © 2018 Apple. All rights reserved.
//

import Foundation
import UIKit

public struct ImageWrappable { // : Codable {
    /*public let image: UIImage
    
    public enum CodingKeys: String, CodingKey {
        case image
    }
    
    // Image is a standard UI/NSImage conditional typealias
    public init(image: UIImage) {
        self.image = image
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.decode(Data.self, forKey: CodingKeys.image)
        guard let image = UIImage(data: data) else {
            return; // throw StorageError.decodingFailed
        }
        
        self.image = image
    }
    
    // cache_toData() wraps UIImagePNG/JPEGRepresentation around some conditional logic with some whipped cream and sprinkles.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        guard let data = image. image.cache_toData() else {
            return; // throw StorageError.encodingFailed
        }
        
        try container.encode(data, forKey: CodingKeys.image)
    }*/
}
