//
//  ViewController.swift
//  ARKitPersistence
//
//  Created by Ananth Bhamidipati on 25/10/2018.
//  Copyright © 2018 YellowJersey. All rights reserved.
//

// ! SCALING DOES NOT PERSIST. I AM NOT SURE IF ANYTHING PERSISTS LMAO - cate

import UIKit
import SceneKit
import ARKit

class AdminViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var loadButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var touchLabel: UIButton!
    
    var anchors: [ARAnchor] = []
    
    var horizontalPlanes = [ARPlaneAnchor: SCNNode]()
    var verticalPlanes = [ARPlaneAnchor: SCNNode]()

    // Variables for storing current node's rotation around its Y-axis
    var currentNode: SCNNode? // Currently selected node

    var isRotating = false // ! Disabled
    var currentAngleY: Float = 0.0 // ! Disabled
    
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
        
        // Set lighting to the view
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
        
        setUpUI()
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
        configuration.planeDetection = [.horizontal, .vertical] // Tracks horizontal AND vertical planes
        let options: ARSession.RunOptions = [.resetTracking, .removeExistingAnchors]
        // Delete all nodes from hierarchy
        sceneView.scene.rootNode.enumerateChildNodes { (node, stop) in
            node.removeFromParentNode()
        }
        // Delete all nodes from our personal array of anchors
        anchors.removeAll()
        // Delete all plane anchors
        verticalPlanes.removeAll()
        horizontalPlanes.removeAll()

        sceneView.debugOptions = [.showFeaturePoints]
        sceneView.session.run(configuration, options: options)
        
        setUpLabelsAndButtons(text: "Move the camera around to detect surfaces", canShowSaveButton: false)
        
        // Reset selected node
        currentNode = nil
    }

    func generateTextNode(_ worldTransform: simd_float4x4) {
        let hitTestPosition = worldTransform.columns.3
        let position = SCNVector3(hitTestPosition.x, hitTestPosition.y, hitTestPosition.z)

        // Create alert to name label
        let alert = UIAlertController(title: "Label Maker", message: "Enter location name", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.text = ""
        }
        alert.addAction(UIAlertAction(title: "Add", style: .default, handler: { [weak alert] (_) in
            let userInput = alert?.textFields![0].text!
            
            // Check to verify inputted location is unique and non-nil
            if (self.sceneView.scene.rootNode.childNode(withName: userInput!, recursively: true)) != nil || userInput == "" {
                let errorAlert = UIAlertController(title: "Invalid Location Name", message: "Please make sure your location name is unique and non-empty.", preferredStyle: .alert)
                errorAlert.addAction(UIAlertAction(title: "Got it", style: .default, handler: {_ in
                    print("Adding location node cancelled.")
                }))
                self.present(errorAlert, animated: true, completion: nil)
            }
            
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

            print("Added anchor: \(anchor.identifier) ---> ", anchor.name!)

            // Scale text node
            textNode.scale = SCNVector3(0.05, 0.05 , 0.05)
            // Always make text face viewer
            textNode.constraints = [SCNBillboardConstraint()]
            // Add text node to the hierarchy and position it
            self.sceneView.scene.rootNode.addChildNode(textNode)
            textNode.position = position
            // Set text node as the currently selected node
            self.currentNode = textNode
            self.currentNode!.name = userInput // TODO: check for nil?
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: {_ in
            print("Cancelled.")
        }))
        
        self.present(alert, animated: true, completion: nil)
    }

    func addGestureRecognizers() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapGestureRecognized))
        self.sceneView.addGestureRecognizer(tapGesture)

        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPressGestureRecognized))
        self.sceneView.addGestureRecognizer(longPressGesture)

        let scaleGesture = UIPinchGestureRecognizer(target: self, action: #selector(scaleCurrentNode(_:)))
        self.sceneView.addGestureRecognizer(scaleGesture)

        // // Tap Gesture Recogizer for rotating TextNode
        // let rotateGesture = UIRotationGestureRecognizer(target: self, action: #selector(rotateNode(_:)))
        // self.sceneView.addGestureRecognizer(rotateGesture)
    }

    @objc func tapGestureRecognized(recognizer :UITapGestureRecognizer) {
        // Get current location of tap
        let touchLocation = recognizer.location(in: sceneView)
        if let planeHitTest = sceneView.hitTest(touchLocation, types: .existingPlaneUsingGeometry).first {
            print("User has tapped on an existing plane.")
            generateTextNode(planeHitTest.worldTransform)
            return
        }
    }

    // TODO: MAKE ANOTHER ALERT TO DECIDE IF YOU WANT TO RESCALE OR THROW AWAY NODE
    @objc func longPressGestureRecognized(recognizer :UITapGestureRecognizer) {
        let alert = UIAlertController(title: "Edit Text Node", message: "Enter node name:", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.text = ""
        }
        alert.addAction(UIAlertAction(title: "Rescale", style: .default, handler: { [weak alert] (_) in
            let selectedNode = alert?.textFields![0].text!
//            self.currentNode = self.sceneView.scene.rootNode.childNodes.filter({ $0.name == selectedNode}).first
            self.currentNode = self.sceneView.scene.rootNode.childNode(withName: selectedNode!, recursively: true) ?? self.currentNode
            print("Should rescale")
        }))
        alert.addAction(UIAlertAction(title: "Delete", style: .default, handler: { [weak alert] (_) in
            let selectedNode = alert?.textFields![0].text!
            if (self.anchors.count > 0 && self.currentNode!.name != selectedNode) { // ! Delete will fail if you try to delete with 0 anchors added, and nothing will happen if you try to delete the currently selected node.
                for index in 0...(self.anchors.count - 1) {
                    if (self.anchors[index].name == selectedNode) {
                        // Remove anchor from scene
                        self.sceneView.session.remove(anchor: self.anchors[index])
                        // Remove corresponding text node from hierarchy
                        self.sceneView.scene.rootNode.childNodes.filter({ $0.name == selectedNode}).forEach({ $0.removeFromParentNode() })
                        // Remove from our personal list of anchors
                        self.anchors.remove(at: index)
                    }
                }
            }
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    

    // Resize existing tapped-on node
    @objc func scaleCurrentNode(_ gesture: UIPinchGestureRecognizer) {
        if !isRotating, let selectedNode = currentNode {
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

    // TODO: Decide if we want to keep rotateNode or not
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
    
    func setUpUI() {
        setUpLabelsAndButtons(text: "Move the camera around to detect surfaces", canShowSaveButton: false)
        loadButton.layer.cornerRadius = 10
        saveButton.layer.cornerRadius = 10
        resetButton.layer.cornerRadius = 10
        // guard let pointOfView = self.sceneView.pointOfView else {return}
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
        // ? Should text nodes be children of their plane?
        guard let planeAnchor = anchor as? ARPlaneAnchor
        else { 
            print("Went here!")
            return
         }
        
        var horizontal = true

        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        let myPlane = SCNPlane(width: width, height: height)
        if planeAnchor.alignment == .horizontal {
            myPlane.materials.first?.diffuse.contents = UIColor.red.withAlphaComponent(0.8)
        }  else if planeAnchor.alignment == .vertical {
            horizontal = false
            myPlane.materials.first?.diffuse.contents = UIColor.cyan.withAlphaComponent(0.8)
        }

        let planeNode = SCNNode(geometry: myPlane)
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)

        planeNode.position = SCNVector3(x, y, z)
        planeNode.eulerAngles.x = -.pi / 2

        print("Did add Node on anchor: \(anchor.identifier)")
        node.addChildNode(planeNode)
        
        // TODO: Grab plane anchors from existing anchors as well
        // Add to plane arrays
        if (horizontal) {
            horizontalPlanes[planeAnchor] = planeNode
        }
        else {
            verticalPlanes[planeAnchor] = planeNode
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, willUpdate node: SCNNode, for anchor: ARAnchor) {
        // print("Will update Node on Anchor: \(anchor.identifier)")
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        // print("Did update Node on Anchor: \(anchor.identifier)")
        guard let planeAnchor = anchor as? ARPlaneAnchor,
              let planeNode = node.childNodes.first,
              let myPlane = planeNode.geometry as? SCNPlane
        else { return }

        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        myPlane.width = width
        myPlane.height = height

        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x, y, z)
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
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    if let touch = touches.first {
        let location = touch.location(in: self.view)
        print( location.x)
        print( location.y)
        let alert = UIAlertController(title: "My Title", message:"\(location.x)", preferredStyle: .alert)

        // add an action (button)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))

        // show the alert
        present(alert, animated: true, completion: nil)
      }
        
    }
    
    
    
    
    
}

