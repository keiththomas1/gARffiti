/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 A custom anchor for saving a snapshot image in an ARWorldMap.
 */

import ARKit

/// - Tag: ImageArAnchor
class GraffitiImageAnchor: ARAnchor {
    
    let imageHash: String;
    var rotation: simd_quatf = simd_quatf();
    
    /*convenience init?(transform: float4x4, imageHash: String) {
        self.init(transform: transform, imageHash: imageHash);
    }*/
    
    init(transform: float4x4, imageHash: String) {
        self.imageHash = imageHash;
        self.rotation = transform.orientation;
        super.init(transform: transform);
    }
    
    required init(anchor: ARAnchor) {
        self.imageHash = (anchor as! GraffitiImageAnchor).imageHash

        super.init(anchor: anchor);
    }

    override class var supportsSecureCoding: Bool {
        return true
    }
    
    required init?(coder aDecoder: NSCoder) {
        if let imageHash = aDecoder.decodeObject(forKey: "imageAR") as? String {
            self.imageHash = imageHash
        } else {
            return nil
        }
        
        super.init(coder: aDecoder)
    }
    
    override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(imageHash, forKey: "imageAR")
    }
    
}
