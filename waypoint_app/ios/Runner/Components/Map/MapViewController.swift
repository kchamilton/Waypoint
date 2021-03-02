//  Referenced from Ananth Bhamidipati on 25/10/2018.
// https://github.com/YellowJerseyBE/ARKitPersistence/blob/master/ARKitPersistence/ViewController.swift

/*
    ! Current Issues
    - UI elements are not updated on run (label)
    - Buttons do not seem to respond to touch (load, save, reset)
    
    * Once room has been scanned enough, you can place nodes on the screen (Add print statement back)

*/


import UIKit
import SceneKit
import ARKit

class MapViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var loadButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    
    var worldMapURL: URL = {
        do {
            return try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("worldMapURL")
        } catch {
            fatalError("Error getting world map URL from document directory.")
        }
    }()

    var coordinatorDelegate: MapCoordinatorDelegate?
    
    override func viewDidLoad() {
        print("THREAD: ", Thread.isMainThread)
        print("viewDidLoad()")

        super.viewDidLoad()
                
        // Set the view's delegate
        sceneView.delegate = self
        
        // set session delegate
        self.sceneView.session.delegate = self
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        
        //Set lighting to the view
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true

        setUpUI()
        addTapGestureRecognizer()
    }
    
    @IBAction func goToFlutter(_ sender: Any) {
        coordinatorDelegate?.navigateToFlutter()
    }

    override func viewWillAppear(_ animated: Bool) {
        print("viewWillAppear()")
        super.viewWillAppear(animated)
        
        // Create a session configuration and run the view's session
        resetTrackingConfiguration()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        print("viewWillDisappear()")
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    func resetTrackingConfiguration() {
        print("ResettingTrackingConfiguration()")
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        let options: ARSession.RunOptions = [.resetTracking, .removeExistingAnchors]
        sceneView.debugOptions = [.showFeaturePoints]
        sceneView.session.run(configuration, options: options)
        
        setUpLabelsAndButtons(text: "Move the camera around to detect surfaces", canShowSaveButton: false)
    }
    
    func generateSphereNode() -> SCNNode {
        print("generateSphereNode()")
        print("Generated node!")
        let sphere = SCNSphere(radius: 0.05)
        let sphereNode = SCNNode()
        sphereNode.geometry = sphere
        return sphereNode
    }
    
    func addTapGestureRecognizer() {
        print("addTapGestureRecognizer()")
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapGestureRecognized))
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc func tapGestureRecognized(recognizer :UITapGestureRecognizer) {
        print("tapGestureRecognized()")
        let touchLocation = recognizer.location(in: sceneView)
        guard let hitTestResult = sceneView.hitTest(touchLocation, types: .existingPlane).first
            else { return }
        let anchor = ARAnchor(transform: hitTestResult.worldTransform)
        sceneView.session.add(anchor: anchor)
    }
    
    func setUpUI() {
        print("setUpUI()")
        setUpLabelsAndButtons(text: "Move the camera around to detect surfaces", canShowSaveButton: false)
        loadButton.layer.cornerRadius = 10
        saveButton.layer.cornerRadius = 10
        resetButton.layer.cornerRadius = 10
    }
    
    func setUpLabelsAndButtons(text: String, canShowSaveButton: Bool) {
        self.infoLabel.text = text
        self.saveButton.isEnabled = canShowSaveButton
    }
    
    func showAlert(message: String) {
        print("showAlert")
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    } 
    
    // MARK: - Button Actions
    
    @IBAction func loadButtonAction(_ sender: Any) {
        print("loadButtonAction()")
        guard let mapData = try? Data(contentsOf: self.worldMapURL), let worldMap = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: mapData) else {
            fatalError("No ARWorldMap in archive.")
        }
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        
        let options: ARSession.RunOptions = [.resetTracking, .removeExistingAnchors]
        configuration.initialWorldMap = worldMap
        showAlert(message: "Map Loaded")
        print("Map loaded!")
        sceneView.debugOptions = [.showFeaturePoints]
        sceneView.session.run(configuration, options: options)
    }
    
    @IBAction func resetButtonAction(_ sender: Any) {
        print("resetButtonAction()")
        resetTrackingConfiguration()
    }
    
    @IBAction func saveButtonAction(_ sender: Any) {
        print("saveButtonAction()")
        print("Map saved!")
        sceneView.session.getCurrentWorldMap { (worldMap, error) in
            guard let worldMap = worldMap else {
                self.setUpLabelsAndButtons(text: "Can't get current world map", canShowSaveButton: false)
                self.showAlert(message: error!.localizedDescription)
                return
            }
            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: worldMap, requiringSecureCoding: true)
                try data.write(to: self.worldMapURL, options: [.atomic])
                self.showAlert(message: "Map Saved")
            } catch {
                fatalError("Can't save map: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        print("renderer")
        guard !(anchor is ARPlaneAnchor) else { return }
        let sphereNode = generateSphereNode()
        DispatchQueue.main.async {
            node.addChildNode(sphereNode)
        }
    }
    
    // MARK: - ARSessionDelegate
    //shows the current status of the world map.
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        switch frame.worldMappingStatus {
        case .notAvailable:
            setUpLabelsAndButtons(text: "Map Status: Not available", canShowSaveButton: false)
        case .limited:
            setUpLabelsAndButtons(text: "Map Status: Available but has Limited features", canShowSaveButton: false)
        case .extending:
            setUpLabelsAndButtons(text: "Map Status: Actively extending the map", canShowSaveButton: false)
        case .mapped:
            setUpLabelsAndButtons(text: "Map Status: Mapped the visible Area", canShowSaveButton: true)
        @unknown default:
            setUpLabelsAndButtons(text: "Map Status: Not availble", canShowSaveButton: false)
        }
    }

}
