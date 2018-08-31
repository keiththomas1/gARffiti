/*
See LICENSE folder for this sample’s licensing information.

Abstract:
UI Actions for the main view controller.
*/

import UIKit
import SceneKit

extension ViewController: UIGestureRecognizerDelegate {
    
    enum SegueIdentifier: String {
        case showObjects
    }
    
    // MARK: - Interface Actions
    
    /// Displays the `VirtualObjectSelectionViewController` from the `addObjectButton` or in response to a tap gesture in the `sceneView`.
    @IBAction func handleScreenTapped() {
        if (self.imageInFocus) {
            
            // TODO: Ensure that the cursor is on a surface, or else it will
            //      be possible to place something anywhere in the world.
            
            guard let currentUploadedImage = self.uploadedImageNodes.last else {
                return;
            }
            self.lastWorldTransform = currentUploadedImage.simdWorldTransform;
            
            let imageHash = self.getRandomHash(hashLength: 15);
            
            do {
                if (!self.imageDictionaryLoaded) {
                    self.LoadImageDictionary();
                }
                self.imageDictionary.images[imageHash] = self.uploadedImage;
                let imageData = try NSKeyedArchiver.archivedData(withRootObject: self.imageDictionary, requiringSecureCoding: true);
                try imageData.write(to: self.imageSaveURL, options: [.atomic]);
            }
            catch {
                fatalError("Can't save image: \(error.localizedDescription)");
            }
            // Create a new anchor with the object's current transform and add it to the session
            let newAnchor = GraffitiImageAnchor(transform: currentUploadedImage.simdWorldTransform, imageHash: imageHash);
            self.sceneView.addImageAnchor(anchor: newAnchor);
            
            currentUploadedImage.removeFromParentNode();
            self.imageInFocus = false;
        }
        /*else {
            statusViewController.cancelScheduledMessage(for: .contentPlacement)
            performSegue(withIdentifier: SegueIdentifier.showObjects.rawValue, sender: addObjectButton)
        }*/
    }
    
    /// Determines if the tap gesture for presenting the `VirtualObjectSelectionViewController` should be used.
    func gestureRecognizerShouldBegin(_: UIGestureRecognizer) -> Bool {
        return virtualObjectLoader.loadedObjects.isEmpty
    }
    
    func gestureRecognizer(_: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith _: UIGestureRecognizer) -> Bool {
        return true
    }
    
    /// - Tag: restartExperience
    func restartExperience() {
        guard isRestartAvailable, !virtualObjectLoader.isLoading else { return }
        isRestartAvailable = false

        statusViewController.cancelAllScheduledMessages()

        virtualObjectLoader.removeAllVirtualObjects()
        addObjectButton.setImage(#imageLiteral(resourceName: "add"), for: [])
        addObjectButton.setImage(#imageLiteral(resourceName: "addPressed"), for: [.highlighted])

        resetTracking()

        // Disable restart for a while in order to give the session time to restart.
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.isRestartAvailable = true
        }
    }
}

extension ViewController: UIPopoverPresentationControllerDelegate {
    
    // MARK: - UIPopoverPresentationControllerDelegate

    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // All menus should be popovers (even on iPhone).
        if let popoverController = segue.destination.popoverPresentationController, let button = sender as? UIButton {
            popoverController.delegate = self
            popoverController.sourceView = button
            popoverController.sourceRect = button.bounds
        }
        
        guard let identifier = segue.identifier,
              let segueIdentifer = SegueIdentifier(rawValue: identifier),
              segueIdentifer == .showObjects else { return }
        
        let objectsViewController = segue.destination as! VirtualObjectSelectionViewController
        objectsViewController.virtualObjects = VirtualObject.availableObjects
        objectsViewController.delegate = self
        self.objectsViewController = objectsViewController
        
        // Set all rows of currently placed objects to selected.
        for object in virtualObjectLoader.loadedObjects {
            guard let index = VirtualObject.availableObjects.index(of: object) else { continue }
            objectsViewController.selectedVirtualObjectRows.insert(index)
        }
    }
    
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        objectsViewController = nil
    }
}
