//
//  ImageTouchViewModel.swift
//  Feel Your Photo (iOS)
//
//  Created by Alice Yoon on 09/02/22.
//

import SwiftUI
import PhotosUI
import CoreImage
import CoreImage.CIFilterBuiltins
import CoreML
import Vision

class ImageTouchViewModel: NSObject, ObservableObject, PHPhotoLibraryChangeObserver {
    //@Published var fetchedImages: [ImageAsset] = []
    @Published var selectedImages: [ImageAsset] = []
    @Published var displayImage = UIImage(imageLiteralResourceName: "InstructionPage")
    @Published var filteredImage = UIImage(imageLiteralResourceName: "InstructionPage")
    @Published var currentImage = UIImage(imageLiteralResourceName: "InstructionPage")
    @Published var currentImageIndex = -1
    private var toggleImageIndex = 0
    private var introImage: Bool = true
    private var requests:[VNRequest] = []
    private let confidenceThreshold:Float = 0.8
    private let edgeIgnore: Int = 1 // Ignore edge of an image
    private var imageCollection: PHFetchResult<PHAsset>?
    private var currentImageAsset: ImageAsset?
    private var currentImageLabel: String? = nil
    
    private let session = URLSession.shared
    private let googleURL = URL(string: "https://vision.googleapis.com/v1/images:annotate?key=AIzaSyAJ7uSPxjfUMmX8SF-eSvHd0do0NkehTcA")
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    private var enableiOSML: Bool = false
    
    private lazy var classificationRequest: VNCoreMLRequest = {
        do {
            var config = MLModelConfiguration()
            let model = try VNCoreMLModel(for: MobileNetV2(configuration: config).model)
            let request = VNCoreMLRequest(model: model) { request, _ in
                if let classifications =
                    request.results as? [VNClassificationObservation] {
                    let labels: String = classifications[0].identifier + "," + classifications[1].identifier
                    self.speak(labels, false)
                    print("Classification results:", labels)
                }
            }
            request.imageCropAndScaleOption = .centerCrop
            return request
        } catch {
            fatalError("Failed to load Vision ML model: \(error)")
        }
    }()
    
    override init() {
        super.init()
        PHPhotoLibrary.shared().register(self)
        fetchImages()
        
        // Enable audio navigation while silence is on
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        } catch let error {
            print("This error message from SpeechSynthesizer \(error.localizedDescription)")
        }
    }
    
    // MARK: Fetching Images
    func fetchImages() {
        /*PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            if status == .authorized {
                return
            }
        }*/
        let options = PHFetchOptions()
        
        //var imageCount = 0
        //fetchedImages.removeAll()

        // Fetch whole images which are permitted
        // If you want to contol # of images fetched, it can be managed in the permission control.
        options.includeHiddenAssets = false
        options.includeAssetSourceTypes = [.typeUserLibrary]
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        imageCollection = PHAsset.fetchAssets(with: .image, options: options)
        /*
        PHAsset.fetchAssets(with: .image, options: options).enumerateObjects { asset, _, _ in
            let imageAsset: ImageAsset = .init(asset: asset)
            self.fetchedImages.append(imageAsset)
            print("***imageCount", imageCount)
            imageCount += 1
        }*/

        /* Alice: Fetch "Touch" albmum
        options.predicate = NSPredicate(format: "title = %@", "Touch")
        
        let collection: PHFetchResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: options)
        var assetCollection = PHAssetCollection()
        if let _:AnyObject = collection.firstObject {
            // Found the album
            assetCollection = collection.firstObject!
        } else {
            print("Album not found")
            return
        }

        PHAsset.fetchAssets(in: assetCollection, options: nil).enumerateObjects { asset, _, _ in
            let imageAsset: ImageAsset = .init(asset: asset)
            self.fetchedImages.append(imageAsset)
            print("***imageCount", imageCount)
            imageCount += 1
        }*/
    }
    
    func prevImage() {
        /*
        if (self.fetchedImages.count == 0) { return }
        self.currentImageIndex -= 1
        if (self.currentImageIndex < 0) { self.currentImageIndex = self.fetchedImages.count-1 }
        */
        currentImageLabel = nil
        if (self.imageCollection!.count == 0) { return }
        self.currentImageIndex -= 1
        if (self.currentImageIndex < 0) { self.currentImageIndex = self.imageCollection!.count-1 }
        
        currentImageAsset = .init(asset: imageCollection!.object(at: self.currentImageIndex))

        let manager = PHCachingImageManager.default()
        let imageRequestOptions = PHImageRequestOptions()
        imageRequestOptions.isSynchronous = true
        
        //manager.requestImage(for: self.fetchedImages[self.currentImageIndex].asset, targetSize: .init(), contentMode: .default, options: imageRequestOptions) { [self] image, _ in
        manager.requestImage(for: currentImageAsset!.asset, targetSize: .init(), contentMode: .default, options: imageRequestOptions) { [self] image, _ in
            DispatchQueue.main.async {
                if (image != nil) {
                    self.speak("Previous Photo", true)
                    self.currentImage = image!
                    self.filteredImage = self.filterImage(self.currentImage)
                    self.setDisplayImage()
                    print("prevImage()", self.currentImageIndex)
                }
                self.objectWillChange.send()
                self.introImage = false
            }
        }
    }
    
    func nextImage() {
        /*
        if (self.fetchedImages.count == 0) { return }
        self.currentImageIndex += 1
        if (self.currentImageIndex >= self.fetchedImages.count) { self.currentImageIndex = 0 }
        */
        currentImageLabel = nil
        if (self.imageCollection!.count == 0) { return }
        self.currentImageIndex += 1
        if (self.currentImageIndex >= self.imageCollection!.count) { self.currentImageIndex = 0 }
        
        currentImageAsset = .init(asset: imageCollection!.object(at: self.currentImageIndex))
        
        let manager = PHCachingImageManager.default()
        let imageRequestOptions = PHImageRequestOptions()
        imageRequestOptions.isSynchronous = true
        
        //manager.requestImage(for: self.fetchedImages[self.currentImageIndex].asset, targetSize: .init(), contentMode: .default, options: imageRequestOptions) { [self] image, _ in
        manager.requestImage(for: currentImageAsset!.asset, targetSize: .init(), contentMode: .default, options: imageRequestOptions) { [self] image, _ in    DispatchQueue.main.async {
                if (image != nil) {
                    self.speak("Next Photo", true)
                    self.currentImage = image!
                    self.filteredImage = self.filterImage(self.currentImage)
                    self.setDisplayImage()
                    print("nextImage()", self.currentImageIndex)
                }
                self.objectWillChange.send()
                self.introImage = false
            }
        }
    }
    
    func imageInfo() {
        if introImage { return }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        self.speak(formatter.string(from: self.currentImageAsset!.asset.creationDate!), true)
        
        if (self.enableiOSML) {
            // iOS MobileNetV2: No network access
            classifyImage(self.currentImage)
        } else {
            // Google Cloud Vision API, which costs
            let binaryImageData = base64EncodeImage(self.currentImage)
            createRequest(with: binaryImageData)
        }
    }
    
    func filterImage(_ inputImage: UIImage) -> UIImage{
        let CiImage = CIImage(image: inputImage)
        
        let monoFilter = CIFilter.photoEffectMono()
        let edgesFilter = CIFilter.edges()
        let thresholdFilter = CIFilter.colorThreshold()
        thresholdFilter.threshold = 0.01
        monoFilter.setValue(CiImage!, forKey: kCIInputImageKey)
        edgesFilter.setValue(monoFilter.outputImage!, forKey: kCIInputImageKey)
        thresholdFilter.setValue(edgesFilter.outputImage!, forKey: kCIInputImageKey)
        // Crop the last white lines at bottom and right
        let CiImageOutput = thresholdFilter.outputImage?.cropped(to: CGRect(x: 0, y: edgeIgnore, width: Int(inputImage.size.width)-edgeIgnore, height: Int(inputImage.size.height)-edgeIgnore))
        
        let context:CIContext = CIContext.init(options: nil)
        let cgImage:CGImage = context.createCGImage(CiImageOutput!, from: CiImageOutput!.extent)!
        filteredImage = UIImage.init(cgImage: cgImage)
        return filteredImage
    }
    
    func toggleImage() {
        if introImage { return }
        
        toggleImageIndex += 1
        print ("toggleImage() to ", toggleImageIndex)
        if toggleImageIndex > 2 { toggleImageIndex = 0 }
        switch toggleImageIndex {
        case 1:
            displayImage = filteredImage
            speak("Edge View", true)
        case 2: // TODO: change to '?' image
            displayImage = UIImage(imageLiteralResourceName: "questionmark")
            speak("Game Mode", true)
        default:
            displayImage = currentImage
            speak("Original Photo", true)
        }
        objectWillChange.send()
    }
    
    func setDisplayImage() {
        switch toggleImageIndex {
        case 1:
            displayImage = filteredImage
        case 2:
            displayImage = UIImage(imageLiteralResourceName: "questionmark")
        default:
            displayImage = currentImage
        }
    }
    
    func getRGBColorOfThePixel(at: CGPoint, within: CGSize, radius: Int) -> CGFloat {
        if introImage { return 0 }
        
        let cgImage = filteredImage.cgImage
        let pixelData = cgImage?.dataProvider?.data
        var inPoint = CGPoint(x: 0, y: 0)
        
        if ((within.height / within.width) > (CGFloat(cgImage!.height) / CGFloat(cgImage!.width))) {
            // Image fits screen width
            inPoint.x = CGFloat(cgImage!.width) * at.x / within.width
            if (inPoint.x < 0) {inPoint.x = 0}
            let yOffset = (within.height - (within.width * CGFloat(cgImage!.height) / CGFloat(cgImage!.width)))/2
            inPoint.y = CGFloat(cgImage!.height) * (at.y-yOffset) / (within.height - 2*yOffset)
            if ((inPoint.y < 0) || (inPoint.y > CGFloat(cgImage!.height))) {
                // Requested location is outside of the image.
                return 0
            }
        } else {
            // Image fits screen height
            inPoint.y = CGFloat(cgImage!.height) * at.y / within.height
            if (inPoint.y < 0) {inPoint.y = 0}
            let xOffset = (within.width - (within.height * CGFloat(cgImage!.width) / CGFloat(cgImage!.height)))/2
            inPoint.x = CGFloat(cgImage!.width) * (at.x-xOffset) / (within.width - 2*xOffset)
            if ((inPoint.x < 0) || (inPoint.x > CGFloat(cgImage!.width))) {
                // Requested location is outside of the image.
                return 0
            }
        }
        
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        
        var radiusAdjusted = Int(CGFloat (radius) * (CGFloat(cgImage!.width) / within.width)) // Calculate normalized radius
        if (radiusAdjusted < 1) {radiusAdjusted = 1}
        //print ("radiusAdjusted", radiusAdjusted)
        
        var startX = Int(inPoint.x) - radiusAdjusted
        if (startX < edgeIgnore) { startX = edgeIgnore }
        var startY = Int(inPoint.y) - radiusAdjusted
        if (startY < edgeIgnore) { startY = edgeIgnore }
        var endX = Int(inPoint.x) + radiusAdjusted
        if (endX >= cgImage!.width-edgeIgnore) { endX = cgImage!.width-edgeIgnore }
        var endY = Int(inPoint.y) + radiusAdjusted
        if (endY >= cgImage!.height-edgeIgnore) { endY = cgImage!.height-edgeIgnore }
        if (startX > endX) { startX = endX }
        if (startY > endY) { startY = endY }
        
        var r = CGFloat(0)
        var g = CGFloat(0)
        var b = CGFloat(0)
        var a = CGFloat(0)
        
        let centerX = (startX + endX) / 2
        let centerY = (startY + endY) / 2
        
        //print("X Y",startX, centerX, endX, startY, centerY, endY)
        for x in startX...endX {
            for y in startY...endY {
                if (((x-centerX)*(x-centerX) + (y-centerY)*(y-centerY)) <= radiusAdjusted*radiusAdjusted) {
                    let bytesPerPixel = (cgImage!.bitsPerPixel + 7) / 8
                    let pixelByteOffset: Int = (cgImage!.bytesPerRow * y) + (x * bytesPerPixel)
                    let divisor = CGFloat(255.0)
                    r += CGFloat(data[pixelByteOffset]) / divisor
                    g += CGFloat(data[pixelByteOffset + 1]) / divisor
                    b += CGFloat(data[pixelByteOffset + 2]) / divisor
                    a += CGFloat(data[pixelByteOffset + 3]) / divisor
                }
            }
        }
        
        return (r+g+b)/3/CGFloat(radiusAdjusted)
    }
    
    func classifyImage(_ image: UIImage) {
        guard let orientation = CGImagePropertyOrientation(
            rawValue: UInt32(image.imageOrientation.rawValue)) else {
            return
        }
        guard let ciImage = CIImage(image: image) else {
            fatalError("Unable to create \(CIImage.self) from \(image).")
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let handler =
            VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
            do {
                try handler.perform([self.classificationRequest])
            } catch {
                print("Failed to perform classification.\n\(error.localizedDescription)")
            }
        }
    }
    
    func resizeImage(_ imageSize: CGSize, image: UIImage) -> Data {
        UIGraphicsBeginImageContext(imageSize)
        image.draw(in: CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        let resizedImage = newImage!.pngData()
        UIGraphicsEndImageContext()
        return resizedImage!
    }
    
    func base64EncodeImage(_ image: UIImage) -> String {
        var imagedata = image.pngData()
        
        // Melody: Resize the image if it exceeds 1MB. 2MB is API limit but 1MB is used to consider network delay
        if (imagedata!.count > 1024*1024) { // 2097152) {
            let oldSize: CGSize = image.size
            let newSize: CGSize = CGSize(width: 600, height: oldSize.height / oldSize.width * 600)
            imagedata = resizeImage(newSize, image: image)
        }
        
        return imagedata!.base64EncodedString(options: .endLineWithCarriageReturn)
    }
    
    func createRequest(with imageBase64: String) {
        // Create our request URL
        if (self.currentImageLabel != nil) {
            print("Stored: ", self.currentImageLabel!)
            speak(self.currentImageLabel!, false)
            return
        }
        var request = URLRequest(url: googleURL!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(Bundle.main.bundleIdentifier ?? "", forHTTPHeaderField: "X-Ios-Bundle-Identifier")
        
        // Build our API request
        let jsonRequest = [
            "requests": [
                "image": [
                    "content": imageBase64
                ],
                "features": [
                    [
                        "type": "LABEL_DETECTION",
                        "maxResults": 5
                    ],
                    // Melody: Face detection is not enabled for implementation
                    /*[
                     "type": "FACE_DETECTION",
                     "maxResults": 10
                     ]*/
                ]
            ]
        ]
        
        let data = try? JSONSerialization.data(
            withJSONObject: jsonRequest,
            options: []
        )
        
        request.httpBody = data
        
        // Run the request on a background thread
        DispatchQueue.global().async { self.runRequestOnBackgroundThread(request) }
    }
    
    func runRequestOnBackgroundThread(_ request: URLRequest) {
        let task: URLSessionDataTask = session.dataTask(with: request) { (data, response, error) in
            guard let data = data, error == nil else {
                self.speak("Network error", false)
                print(error?.localizedDescription ?? "")
                return
            }
            
            self.currentImageLabel = String.init()
            let jsonOutput = try? JSONSerialization.jsonObject(with: data, options: [])
            if let jsonUnwrapped = jsonOutput { // Remove the first 'Optional' type
                if let jsonUnwrapped2 = jsonUnwrapped as? [String: [[String: [[String:Any]]]]] {
                    jsonUnwrapped2["responses"]?.first!["labelAnnotations"]?.forEach { jsonEntry in
                        if let jsonString = jsonEntry["description"] as? String {
                            self.currentImageLabel = self.currentImageLabel! + jsonString + ","
                        }
                    }
                    print("Received: ", self.currentImageLabel!)
                    self.speak(self.currentImageLabel!, false)
                }
            }
        }
        
        task.resume()
    }
    
    func speak (_ string: String, _ stop: Bool) {
        if (stop) { self.speechSynthesizer.stopSpeaking(at: .immediate) }
        let utterance = AVSpeechUtterance(string: string)
        utterance.pitchMultiplier = 1.0
        utterance.rate = 0.5
        utterance.volume = 0.5
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        self.speechSynthesizer.speak(utterance)
    }
    
    func stopSpeak () {
        self.speechSynthesizer.stopSpeaking(at: .immediate)
    }
    
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        DispatchQueue.main.async {
            self.fetchImages()
            print("photoLibraryDidChange")
        }
    }
}
