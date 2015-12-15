//
//  ViewController.swift
//  BTCheck
//
//  Created by Kilian Költzsch on 15/12/15.
//  Copyright © 2015 Kilian Költzsch. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
	
	@IBOutlet weak var addressLabel: UILabel!
	
	var captureSession: AVCaptureSession!
	var previewLayer: AVCaptureVideoPreviewLayer!
	var qrCodeFrameView: UIView!
	
	var lastCode: String?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		view.backgroundColor = UIColor.blackColor()
		captureSession = AVCaptureSession()
		
		let videoCaptureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
		let videoInput: AVCaptureDeviceInput
		
		do {
			videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
		} catch {
			return
		}
		
		if captureSession.canAddInput(videoInput) {
			captureSession.addInput(videoInput)
		} else {
			failed()
			return
		}
		
		let metadataOutput = AVCaptureMetadataOutput()
		
		if (captureSession.canAddOutput(metadataOutput)) {
			captureSession.addOutput(metadataOutput)
			
			metadataOutput.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())
			metadataOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
		} else {
			failed()
			return
		}
		
		previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
		previewLayer.frame = view.layer.bounds
		previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
		view.layer.addSublayer(previewLayer)
		
		view.bringSubviewToFront(addressLabel)
		
		qrCodeFrameView = UIView()
		qrCodeFrameView?.layer.borderColor = UIColor.greenColor().CGColor
		qrCodeFrameView?.layer.borderWidth = 2
		view.addSubview(qrCodeFrameView!)
		view.bringSubviewToFront(qrCodeFrameView!)
		
		captureSession.startRunning()
		
		NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationDidEnterBackgroundNotification, object: nil, queue: nil) { [unowned self] notification in
			self.lastCode = nil
			self.addressLabel.text = "Scan a QR code to check its balance."
		}
	}
	
	func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
//		captureSession.stopRunning()
		
		if let metadataObject = metadataObjects.first {
			let readableObject = metadataObject as! AVMetadataMachineReadableCodeObject

			qrCodeFrameView?.frame = readableObject.bounds
			foundCode(readableObject.stringValue)
		}
		
		dismissViewControllerAnimated(true, completion: nil)
	}
	
	func foundCode(code: String) {
		let sanitizedCode = sanitizeCode(code)
		
		if let lastCode = lastCode where lastCode == sanitizedCode {
			return
		} else {
			lastCode = sanitizedCode
		}
		
		AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
		print(sanitizedCode)
		
		addressLabel.text = "Checking balance..."
		
		Coinbase.lookupValueFor(sanitizedCode, currency: "EUR") { (value, error) -> Void in
			dispatch_async(dispatch_get_main_queue(), { [unowned self] in
				self.addressLabel.text = "\(value!)€"
			})
		}
	}
	
	func failed() {
		let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .Alert)
		ac.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
		presentViewController(ac, animated: true, completion: nil)
		captureSession = nil
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		
		if (captureSession?.running == false) {
			captureSession.startRunning()
		}
	}
	
	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)
		
		if (captureSession?.running == true) {
			captureSession.stopRunning()
		}
	}
	
	override func prefersStatusBarHidden() -> Bool {
		return true
	}
	
	override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
		return .Portrait
	}
	
	func sanitizeCode(code: String) -> String {
		return code
			.stringByReplacingOccurrencesOfString("bitcoin:", withString: "")
			.stringByReplacingOccurrencesOfString("btc:", withString: "")
			.stringByReplacingOccurrencesOfString(" ", withString: "")
	}
}

