/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Main view controller for the AR experience.
*/

import ARKit
import SceneKit
import UIKit
import Alamofire

class ViewController: UIViewController {
    
    // MARK: IBOutlets
    
    @IBOutlet var sceneView: VirtualObjectARView!
    
    @IBOutlet weak var addObjectButton: UIButton!
    
    @IBOutlet weak var blurView: UIVisualEffectView!
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    // MARK: - UI Elements
    
    var focusSquare = FocusSquare()
    
    var uploadedImageNode = SCNNode();
    //var uploadedImage = UIImage();
    var hasUploadedImage:Bool = false;
    var uploadedImageURL:String = "";
    
    var lastWorldTransform:simd_float4x4 = simd_float4x4();
    var imageInFocus:Bool = false;
    
    // var imageDictionary: [String:Data] = [String:Data](); // ImageDictionary = ImageDictionary();
    //var imageDictionaryLoaded:Bool = false;
    
    @IBOutlet weak var SavedPreviewWindow: UIImageView!;
    /// The view controller that displays the status and "restart experience" UI.
    @IBOutlet weak var SaveExperienceButton: UIButton!;
    
    @IBOutlet weak var LoadExperienceButton: UIButton!;
    
    @IBOutlet weak var StatusLabel: UILabel!
    
    // MARK: - Persistence: Saving and Loading
    lazy var mapSaveURL: URL = {
        do {
            return try FileManager.default
                .url(for: .documentDirectory,
                     in: .userDomainMask,
                     appropriateFor: nil,
                     create: true)
                .appendingPathComponent("map.arexperience")
        } catch {
            fatalError("Can't get file map save URL: \(error.localizedDescription)")
        }
    }()
    lazy var imageSaveURL: URL = {
        do {
            return try FileManager.default
                .url(for: .documentDirectory,
                     in: .userDomainMask,
                     appropriateFor: nil,
                     create: true)
                .appendingPathComponent("imageDictionary.arexperience")
        } catch {
            fatalError("Can't get file image save URL: \(error.localizedDescription)")
        }
    }()
    // Called opportunistically to verify that map data can be loaded from filesystem.
    var mapDataFromFile: Data? {
        return try? Data(contentsOf: mapSaveURL)
    }
    var imageDataFromFile: Data? {
        return try? Data(contentsOf: imageSaveURL)
    }
    var defaultConfiguration: ARWorldTrackingConfiguration {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.environmentTexturing = .automatic
        return configuration
    }
    var isRelocalizingMap = false;
    var virtualObjectAnchor: ARAnchor?;
    
    /// - Tag: GetWorldMap
    @IBAction func SaveExperiencePressed(_ button: UIButton) {
        self.sceneView.session.getCurrentWorldMap { worldMap, error in
            guard let map = worldMap
                else {
                    //self.showAlert(title: "Can't get current world map", message: error!.localizedDescription);
                    return;
                }
            
            // Add a snapshot image indicating where the map was captured.
            guard let snapshotAnchor = SnapshotAnchor(capturing: self.sceneView)
                else { fatalError("Can't take snapshot"); }
            map.anchors.append(snapshotAnchor);
            
            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true);
                try data.write(to: self.mapSaveURL, options: [.atomic]);
                DispatchQueue.main.async {
                    self.LoadExperienceButton.isHidden = false;
                    self.LoadExperienceButton.isEnabled = true;
                }
            } catch {
                fatalError("Can't save map: \(error.localizedDescription)");
            }
        }
    }
    
    func downloadImage(
        url: String,
        parentNode: SCNNode,
        completion: @escaping(SCNNode?) -> ())
    {
        print("Info: Download Started")
        getData(from: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Info: " + error.debugDescription);
                return;
            }
            print("Info: Download Finished");
            DispatchQueue.main.async() {
                guard let image = UIImage(data: data) else {
                    return;
                }
                self.SavedPreviewWindow.image = image;
                let imageNode = self.createImageNode(image: image, parentNode: parentNode);
                completion(imageNode);
            }
        }
    }
    func getData(
        from url: String,
        completion: @escaping (Data?, HTTPURLResponse?, Error?) -> ()) {
        Alamofire.request(url).response {
            response in
            completion(response.data, response.response, response.error);
        }
    }
    
    /// - Tag: RunWithWorldMap
    @IBAction func LoadExperiencePressed(_ sender: Any) {
        /// - Tag: ReadWorldMap
        let worldMap: ARWorldMap = {
            guard let data = mapDataFromFile
                else { fatalError("Map data should already be verified to exist before Load button is enabled.") }
            do {
                guard let worldMap = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data)
                    else { fatalError("No ARWorldMap in archive.") }
                return worldMap;
            } catch {
                fatalError("Can't unarchive ARWorldMap from file data: \(error)")
            }
        }()
        
        // Display the snapshot image stored in the world map to aid user in relocalizing.
        if let snapshotData = worldMap.snapshotAnchor?.imageData,
            let snapshot = UIImage(data: snapshotData) {
            self.SavedPreviewWindow.image = snapshot;
        } else {
            print("Info: No snapshot image in world map");
        }
        // Remove the snapshot anchor from the world map since we do not need it in the scene.
        worldMap.anchors.removeAll(where: { $0 is SnapshotAnchor });
        
        let configuration = self.defaultConfiguration; // this app's standard world tracking settings
        configuration.initialWorldMap = worldMap;
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors]);
        
        isRelocalizingMap = true;
        virtualObjectAnchor = nil;
    }
    
    lazy var statusViewController: StatusViewController = {
        return childViewControllers.lazy.compactMap({ $0 as? StatusViewController }).first!
    }()
    
    /// The view controller that displays the virtual object selection menu.
    var objectsViewController: VirtualObjectSelectionViewController?
    
    // MARK: - ARKit Configuration Properties
    
    /// A type which manages gesture manipulation of virtual content in the scene.
    lazy var virtualObjectInteraction = VirtualObjectInteraction(sceneView: sceneView)
    
    /// Coordinates the loading and unloading of reference nodes for virtual objects.
    let virtualObjectLoader = VirtualObjectLoader()
    
    /// Marks if the AR experience is available for restart.
    var isRestartAvailable = true
    
    /// A serial queue used to coordinate adding or removing nodes from the scene.
    let updateQueue = DispatchQueue(label: "com.example.apple-samplecode.arkitexample.serialSceneKitQueue")
    
    var screenCenter: CGPoint {
        let bounds = sceneView.bounds
        return CGPoint(x: bounds.midX, y: bounds.midY)
    }
    
    /// Convenience accessor for the session owned by ARSCNView.
    var session: ARSession {
        
        return sceneView.session
    }
    
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Enable Save button only when the mapping status is good and an object has been placed
        switch frame.worldMappingStatus {
            case .extending, .mapped:
                let enableSave = self.hasUploadedImage && !self.imageInFocus;
                if (enableSave) {
                    self.SaveExperienceButton.isEnabled = true;
                } else {
                    self.SaveExperienceButton.isEnabled = false;
                }
            default:
                self.SaveExperienceButton.isEnabled = false
        }
        self.StatusLabel.text = """
        Mapping: \(frame.worldMappingStatus.description)
        Tracking: \(frame.camera.trackingState.description)
        """;
        //updateSessionInfoLabel(for: frame, trackingState: frame.camera.trackingState)
        
    }
    
    // MARK: - View Controller Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.session.delegate = self

        // Set up scene content.
        setupCamera()
        sceneView.scene.rootNode.addChildNode(focusSquare)
        
        sceneView.showsStatistics = true;
        sceneView.debugOptions = [
            ARSCNDebugOptions.showWorldOrigin,
            ARSCNDebugOptions.showFeaturePoints];
        
        sceneView.setupDirectionalLighting(queue: updateQueue)

        // Hook up status view controller callback(s).
        statusViewController.restartExperienceHandler = { [unowned self] in
            self.restartExperience();
        }
        
        statusViewController.urlEnteredHandler = {
            [unowned self] (url:String) -> Void in
            guard let downloadURL = URL(string: url) else {
                // TODO: Show this to the user
                print("Info: URL is malformatted");
                return;
            }
            
            let focusSquareNode = self.focusSquare as SCNNode;
            for child in focusSquareNode.childNodes {
                child.removeFromParentNode();
            }
            self.downloadImage(url: url, parentNode: focusSquareNode, completion:
            { imageNode in
                guard let finalNode = imageNode else {return;}
                self.uploadedImageNode = finalNode;
                self.hasUploadedImage = true;
                self.imageInFocus = true;
                self.uploadedImageURL = url;
            });
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleScreenTapped))
        // Set the delegate to ensure this gesture is only used when there are no virtual objects in the scene.
        tapGesture.delegate = self
        self.sceneView.addGestureRecognizer(tapGesture)
        
        // Read in any already saved map to see if we can load one.
        if self.mapDataFromFile != nil {
            self.LoadExperienceButton.isHidden = false;
        }
    }
    
    func createImageNode(image:UIImage, parentNode:SCNNode) -> SCNNode {
        let plane = SCNPlane(width: 0.1, height: 0.1);
        
        let material = SCNMaterial();
        material.diffuse.contents = image;
        material.isDoubleSided = true;
        plane.materials = [material];
        
        let uploadedImageNode = SCNNode(geometry:plane);
        uploadedImageNode.eulerAngles.x = 3 * .pi / 2
        
        parentNode.addChildNode(uploadedImageNode);
        uploadedImageNode.simdWorldOrientation = simd_quatf();
        
        return uploadedImageNode;
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Prevent the screen from being dimmed to avoid interuppting the AR experience.
        UIApplication.shared.isIdleTimerDisabled = true

        // Start the `ARSession`.
        resetTracking()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        session.pause()
    }

    // MARK: - Scene content setup

    func setupCamera() {
        guard let camera = sceneView.pointOfView?.camera else {
            fatalError("Expected a valid `pointOfView` from the scene.")
        }

        /*
         Enable HDR camera settings for the most realistic appearance
         with environmental lighting and physically based materials.
         */
        camera.wantsHDR = true
        camera.exposureOffset = -1
        camera.minimumExposure = -1
        camera.maximumExposure = 3
    }

    // MARK: - Session management
    
    /// Creates a new AR configuration to run on the `session`.
    func resetTracking() {
        virtualObjectInteraction.selectedObject = nil
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        if #available(iOS 12.0, *) {
            configuration.environmentTexturing = .automatic
        }
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])

        statusViewController.scheduleMessage("FIND A SURFACE TO PLACE AN OBJECT", inSeconds: 7.5, messageType: .planeEstimation)
    }

    // MARK: - Focus Square

    func updateFocusSquare(isObjectVisible: Bool) {
        if isObjectVisible {
            focusSquare.hide()
        } else {
            focusSquare.unhide()
            statusViewController.scheduleMessage("TRY MOVING LEFT OR RIGHT", inSeconds: 5.0, messageType: .focusSquare)
        }
        
        // Perform hit testing only when ARKit tracking is in a good state.
        if let camera = session.currentFrame?.camera, case .normal = camera.trackingState,
            let result = self.sceneView.smartHitTest(screenCenter)
        {
            updateQueue.async {
                self.sceneView.scene.rootNode.addChildNode(self.focusSquare)
                self.focusSquare.state = .detecting(hitTestResult: result, camera: camera)
            }
            addObjectButton.isHidden = false
            statusViewController.cancelScheduledMessage(for: .focusSquare)
        } else {
            updateQueue.async {
                self.focusSquare.state = .initializing
                self.sceneView.pointOfView?.addChildNode(self.focusSquare)
            }
            addObjectButton.isHidden = true
        }
    }
    
    // MARK: - Error handling
    
    func displayErrorMessage(title: String, message: String) {
        // Blur the background.
        blurView.isHidden = false
        
        // Present an alert informing about the error that has occurred.
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let restartAction = UIAlertAction(title: "Restart Session", style: .default) { _ in
            alertController.dismiss(animated: true, completion: nil)
            self.blurView.isHidden = true
            self.resetTracking()
        }
        alertController.addAction(restartAction)
        present(alertController, animated: true, completion: nil)
    }

}
