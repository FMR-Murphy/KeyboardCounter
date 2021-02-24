//
//  FApplicationModel.swift
//  KeyboardCounter
//
//  Created by Fang on 2021/2/24.
//

import Cocoa

class FApplicationModel: NSObject, NSCoding, NSSecureCoding {
    static var supportsSecureCoding: Bool = true
    
    var bundleIdentifier: String?
    var localizedName: String?
    
    private var iconData: Data?
    
    var icon: NSImage? {
        get {
            guard iconData != nil else {
                return nil
            }
            let image = NSImage.init(data: iconData!)
            image?.size = NSMakeSize(25, 25)
            return image
        }
    }
    
    override init() {
        super.init()
    }
    
    required init?(coder: NSCoder) {
        self.bundleIdentifier = coder.decodeObject(forKey: "bundleIdentifier") as? String
        self.localizedName = coder.decodeObject(forKey: "localizedName") as? String
        self.iconData = coder.decodeObject(forKey: "iconData") as? Data
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.bundleIdentifier, forKey: "bundleIdentifier")
        coder.encode(self.localizedName, forKey: "localizedName")
        coder.encode(self.iconData, forKey: "iconData")
    }
    
    class func model(withApp app: NSRunningApplication) -> FApplicationModel {
        let model = FApplicationModel()
        model.bundleIdentifier = app.bundleIdentifier
        model.localizedName = app.localizedName
        
        let image = NSImage.resizeImage(source: app.icon!, size: NSMakeSize(100, 100))
        model.iconData = NSImage.compressedImageData(withImage: image, rate: 0.1)
        return model
    }
}

extension NSImage {
    //rate 压缩比0.1～1.0之间
    class func compressedImageData(withImage image:NSImage?, rate: Float) -> Data? {
        guard let imgData = image?.tiffRepresentation else {
            return nil
        }
        let imageRep = NSBitmapImageRep.init(data: imgData)
        
        let resultData = imageRep?.representation(using: .png, properties: [.compressionFactor: rate])
        return resultData
    }
    
    class func resizeImage(source: NSImage, size: NSSize) -> NSImage {
        let rect = NSMakeRect(0, 0, size.width, size.height)
        
        let sourceImageRep = source.bestRepresentation(for: rect, context: nil, hints: nil)
        let image = NSImage.init(size: size)
        
        image.lockFocus()
        sourceImageRep?.draw(in: rect)
        image.unlockFocus()
        return image
    }
}
