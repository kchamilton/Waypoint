//
//  ViewController.swift
//  ARKitPersistence
//
//  Created by Ananth Bhamidipati on 25/10/2018.
//  Copyright © 2018 YellowJersey. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var loadButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    
    var anchors: [ARAnchor] = []
    
    // Variables for storing current node's rotation aroun dits Y-axis
    var currentNode: SCNNode?
    var isRotating = false
    var currentAngleY: Float = 0.0
    
    var worldMapURL: URL = {
        do {
            return try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("worldMapURL")
        } catch {
            fatalError("Error getting world map URL from document directory.")
        }
    }()
    
    override func viewDidLoad() {
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
        
        setupUI()
        addGestureRecognizers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration and run the view's session
        resetTrackingConfiguration()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    func resetTrackingConfiguration() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        let options: ARSession.RunOptions = [.resetTracking, .removeExistingAnchors]
        sceneView.debugOptions = [.showFeaturePoints]
        sceneView.session.run(configuration, options: options)
        
        setUpLabelsAndButtons(text: "Move the camera around to detect surfaces", canShowSaveButton: false)
    }

    func generateTextNode(_ worldTransform: simd_float4x4) {
        let hitTestPosition = worldTransform.columns.3
        let position = SCNVector3(hitTestPosition.x, hitTestPosition.y, hitTestPosition.z)

        // Create alert to name label
        let alert = UIAlertController(title: "Label Maker", message: "Enter location name", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.text = ""
        }
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            let userInput = alert?.textFields![0].text!
            let textNode = SCNNode()
            // Create text geometry
            let textGeometry = SCNText(string: userInput , extrusionDepth: 1)
            // Set text font and size, flatness (how smooth the text looks, and color)
            textGeometry.font = UIFont(name: "Optima", size: 1)
            textGeometry.flatness = 0
            textGeometry.firstMaterial?.diffuse.contents = UIColor.white
            textNode.geometry = textGeometry

            // Set the pivot at the center (for rotation)
            let min = textNode.boundingBox.min
            let max = textNode.boundingBox.max
            textNode.pivot = SCNMatrix4MakeTranslation(
                min.x + (max.x - min.x)/2,
                min.y + (max.y - min.y)/2,
                min.z + (max.z - min.z)/2
            )
            // Create AR anchor for text label
            let anchor = ARAnchor(name: userInput!, transform: worldTransform)
            self.sceneView.session.add(anchor: anchor)
            self.anchors.append(anchor)
            
            for anchor in self.anchors {
                print(anchor.name!)
            }

            // Scale text node
            textNode.scale = SCNVector3(0.005, 0.005 , 0.005)
            // Always make text face viewer
            textNode.constraints = [SCNBillboardConstraint()]
            // Add text node to the hierarchy and position it
            self.sceneView.scene.rootNode.addChildNode(textNode)
            textNode.position = position
            // Set text node as the currently selected noed
            self.currentNode = textNode

        }))
        
        self.present(alert, animated: true, completion: nil)
    }

    func addGestureRecognizers() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapGestureRecognized))
        self.sceneView.addGestureRecognizer(tapGesture)

        let scaleGesture = UIPinchGestureRecognizer(target: self, action: #selector(scaleCurrentNode(_:)))
        self.sceneView.addGestureRecognizer(scaleGesture)

        // // Tap Gesture Recogizer for rotating TextNode
        // let rotateGesture = UIRotationGestureRecognizer(target: self, action: #selector(rotateNode(_:)))
        // self.sceneView.addGestureRecognizer(rotateGesture)
    }

    @objc func tapGestureRecognized(recognizer :UITapGestureRecognizer) {
        // Get current location of tap
        let touchLocation = recognizer.location(in: sceneView)
        // If you hit a SCNNode, set it as the current node so you can interact with it
        if let hitTestResult = sceneView.hitTest(touchLocation, options: nil).first?.node {
            currentNode = hitTestResult
            return
        }
        // Otherwise, do an ARHitTest for feature points so you can place a new SCNNode
        if let hitTest = sceneView.hitTest(touchLocation, types: .featurePoint).first {
            generateTextNode(hitTest.worldTransform)
            return
        }
    }

    // Resize existing tapped-on node
    @objc func scaleCurrentNode(_ gesture: UIPinchGestureRecognizer) {
        if !isRotating, let selectedNode = currentNode{
            if gesture.state == .changed {
                let pinchScaleX: CGFloat = gesture.scale * CGFloat((selectedNode.scale.x))
                let pinchScaleY: CGFloat = gesture.scale * CGFloat((selectedNode.scale.y))
                let pinchScaleZ: CGFloat = gesture.scale * CGFloat((selectedNode.scale.z))
                selectedNode.scale = SCNVector3Make(Float(pinchScaleX), Float(pinchScaleY), Float(pinchScaleZ))
                gesture.scale = 1
            }
            if gesture.state == .ended {}
        }
    }

    // @objc func rotateNode(_ gesture: UIRotationGestureRecognizer){
    //     if let selectedNode = currentNode{
    //         // Get current rotation
    //         let rotation = Float(gesture.rotation)
    //         // If gesture state has changed, set the node's EulerAngles.y
    //         if gesture.state == .changed{
    //             isRotating = true
    //             selectedNode.eulerAngles.y = currentAngleY + rotation
    //         }
    //         // If the gesture has ended, store the last angle of the current node
    //         if (gesture.state == .ended) {
    //             currentAngleY = selectedNode.eulerAngles.y
    //             isRotating = false
    //         }
    //     }
    // }
    
    func setupUI() {
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
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    
    // MARK: - Button Actions
    
    @IBAction func loadButtonAction(_ sender: Any) {
        guard let mapData = try? Data(contentsOf: self.worldMapURL), let worldMap = ((try? NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: mapData)) as ARWorldMap??) else {
            fatalError("No ARWorldMap in archive.")
        }
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        
        let options: ARSession.RunOptions = [.resetTracking, .removeExistingAnchors]
        if let worldMap = worldMap {
            configuration.initialWorldMap = worldMap
            showAlert(message: "Map Loaded")
        } else {
            setUpLabelsAndButtons(text: "Move the camera around to detect surfaces", canShowSaveButton: false)
        }
        sceneView.debugOptions = [.showFeaturePoints]
        sceneView.session.run(configuration, options: options)
    }
    
    @IBAction func resetButtonAction(_ sender: Any) {
        resetTrackingConfiguration()
    }
    
    @IBAction func saveButtonAction(_ sender: Any) {
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
        guard !(anchor is ARPlaneAnchor) else { return }
        print("Added anchor: ", anchor.name!)
    }

    func renderer(_ renderer: SCNSceneRenderer, willUpdate node: SCNNode, for anchor: ARAnchor) {
        print("Will updated Node on Anchor: \(anchor.identifier)")
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        print("Did updated Node on Anchor: \(anchor.identifier)")
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        print("Removed Node on Anchor: \(anchor.identifier)")
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
                setUpLabelsAndButtons(text: "Map Status: Not available", canShowSaveButton: false)
        }
    }
}
