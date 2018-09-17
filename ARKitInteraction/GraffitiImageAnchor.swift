/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 A custom anchor for saving a snapshot image in an ARWorldMap.
 */

import ARKit

/// - Tag: ImageArAnchor
class GraffitiImageAnchor: ARAnchor {
    
    let imageURL: String;
    var rotation: simd_quatf = simd_quatf();
    
    /*convenience init?(transform: float4x4, imageHash: String) {
        self.init(transform: transform, imageHash: imageHash);
    }*/
    
    init(transform: float4x4, imageURL: String) {
        self.imageURL = imageURL;
        self.rotation = transform.orientation;
        super.init(transform: transform);
    }
    
    required init(anchor: ARAnchor) {
        self.imageURL = (anchor as! GraffitiImageAnchor).imageURL

        super.init(anchor: anchor);
    }

    override class var supportsSecureCoding: Bool {
        return true
    }
    
    required init?(coder aDecoder: NSCoder) {
        if let imageURL = aDecoder.decodeObject(forKey: "imageAR") as? String {
            self.imageURL = imageURL
        } else {
            return nil
        }
        
        super.init(coder: aDecoder)
    }
    
    override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(imageURL, forKey: "imageAR")
    }
    
}
