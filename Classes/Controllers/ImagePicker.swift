//
//  ImagePicker.swift
//  UIKit-Plus
//
//  Created by Mihael Isaev on 01.11.2020.
//
#if !os(macOS)
import Foundation
import UIKit

private var _picker: ImagePicker?

open class ImagePicker: NSObject {
    public private(set) lazy var picker = UIImagePickerController()
    
    private var cancelHandler = {}
    private var doneHandler: (UIImage, Info)->() = { _,_ in }
    private var sourceType: UIImagePickerController.SourceType = .camera
    
    public struct Info {
        let original: [UIImagePickerController.InfoKey : Any]
        let mediaType: String
        let originalImage: UIImage
        let editedImage: UIImage?
        let cropRect: CGRect
        let mediaURL: URL?
        let mediaMetadata: NSDictionary
        
        init? (_ info: [UIImagePickerController.InfoKey : Any]) {
            original = info
            guard let mediaType = info[.mediaType] as? String else { return nil }
            guard let originalImage = info[.originalImage] as? UIImage else { return nil }
            guard let cropRect = info[.cropRect] as? CGRect else { return nil }
            guard let mediaMetadata = info[.mediaMetadata] as? NSDictionary else { return nil }
            self.mediaType = mediaType
            self.originalImage = originalImage
            self.cropRect = cropRect
            self.mediaURL = info[.mediaURL] as? URL
            self.mediaMetadata = mediaMetadata
            editedImage = info[.editedImage] as? UIImage
        }
    }
    
    @discardableResult
    public override init() {
        super.init()
        picker.delegate = self
    }
    
    @discardableResult
    public func configure(_ handler: (UIImagePickerController) -> Void) -> Self {
        handler(picker)
        return self
    }
    
    /// Use e.g. `kUTTypeImage`, you have to `import MobileCoreServices` for it
    @discardableResult
    public func mediaTypes(_ types: String...) -> Self {
        mediaTypes(types)
    }
    
    /// Use e.g. `kUTTypeImage`, you have to `import MobileCoreServices` for it
    @discardableResult
    public func mediaTypes(_ types: [String]) -> Self {
        picker.mediaTypes = types
        return self
    }
    
    // default value is 10 minutes.
    @discardableResult
    public func videoMaximumDuration(_ value: TimeInterval) -> Self {
        picker.videoMaximumDuration = value
        return self
    }
    
    /// default value is UIImagePickerControllerQualityTypeMedium.
    /// If the cameraDevice does not support the videoQuality, it will use the default value.
    @discardableResult
    public func videoQuality(_ value: UIImagePickerController.QualityType) -> Self {
        picker.videoQuality = value
        return self
    }
    
    /// set to NO to hide all standard camera UI. default is YES
    @discardableResult
    public func showsCameraControls(_ value: Bool) -> Self {
        picker.showsCameraControls = value
        return self
    }
    
    /// set a view to overlay the preview view.
    @discardableResult
    public func cameraOverlayView(_ value: UIView?) -> Self {
        picker.cameraOverlayView = value
        return self
    }
    
    /// set the transform of the preview view.
    @discardableResult
    public func cameraViewTransform(_ value: CGAffineTransform) -> Self {
        picker.cameraViewTransform = value
        return self
    }
    
    /// default is UIImagePickerControllerCameraCaptureModePhoto
    @discardableResult
    public func cameraCaptureMode(_ value: UIImagePickerController.CameraCaptureMode) -> Self {
        picker.cameraCaptureMode = value
        return self
    }
    
    /// default is UIImagePickerControllerCameraDeviceRear
    @discardableResult
    public func cameraDevice(_ value: UIImagePickerController.CameraDevice) -> Self {
        picker.cameraDevice = value
        return self
    }
    
    /// default is UIImagePickerControllerCameraFlashModeAuto.
    @discardableResult
    public func cameraFlashMode(_ value: UIImagePickerController.CameraFlashMode) -> Self {
        picker.cameraFlashMode = value
        return self
    }
    
    @discardableResult
    public func allowsEditing(_ value: Bool = true) -> Self {
        picker.allowsEditing = value
        return self
    }
    
    @discardableResult
    public func transitionStyle(_ style: UIModalTransitionStyle) -> Self {
        picker.modalTransitionStyle = style
        return self
    }
    
    @discardableResult
    public func sourceType(_ type: UIImagePickerController.SourceType) -> Self {
        picker.sourceType = type
        return self
    }
    
    @discardableResult
    public func onCancel(_ handler: @escaping () -> Void) -> Self {
        cancelHandler = handler
        return self
    }
    
    @discardableResult
    public func onDone(_ handler: @escaping (UIImage, Info) -> Void) -> Self {
        doneHandler = handler
        return self
    }
    
    @discardableResult
    public func onDone(_ handler: @escaping (UIImage) -> Void) -> Self {
        doneHandler = { image, info in
            handler(image)
        }
        return self
    }
    
    @discardableResult
    public func present(in vc: UIViewController, animated: Bool = true, completion: (() -> Void)? = nil) -> Self {
        _picker = self
        vc.present(picker, animated: animated, completion: completion)
        return self
    }
}

extension ImagePicker: UIImagePickerControllerDelegate {
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let info = Info(info) {
            doneHandler(info.editedImage ?? info.originalImage, info)
        }
        picker.dismiss(animated: true)
        _picker = nil
    }
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        cancelHandler()
        _picker = nil
    }
}

extension ImagePicker: UINavigationControllerDelegate {}
#endif
