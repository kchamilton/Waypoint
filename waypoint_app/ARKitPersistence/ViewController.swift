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

// ! Arrow pointing leaves something to be desired... - Cate

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var loadButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    
    // * I think there's an actual anchors array held in session. Maybe not.
    var anchors: [ARAnchor] = []
    
    var horizontalPlanes = [ARPlaneAnchor: SCNNode]()
    var verticalPlanes = [ARPlaneAnchor: SCNNode]()

    // Variables for storing current node's rotation around its Y-axis
    var currentNode: SCNNode? // Currently selected node
    var currentNodeAnchor: ARAnchor?

    var isRotating = false // ! Disabled
    var currentAngleY: Float = 0.0 // ! Disabled
    
    // Distance from user to destination in meters
    var distanceToDest: Float = 0.0
    
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
        
        setUpLabelsAndButtons(text: "Move the camera around to detect surfaces", canShowSaveButton: false, distance: "Distance: N/A")
        
        // Reset selected node
        currentNode = nil
        currentNodeAnchor = nil
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
            textNode.scale = SCNVector3(0.005, 0.005 , 0.005)
            // Always make text face viewer
            textNode.constraints = [SCNBillboardConstraint()]
            // Add text node to the hierarchy and position it
            self.sceneView.scene.rootNode.addChildNode(textNode)
            textNode.position = position
            // Set text node as the currently selected node
            self.currentNode = textNode
            self.currentNode!.name = userInput // TODO: check for nil?
            self.currentNodeAnchor = anchor
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
            self.currentNode = self.sceneView.scene.rootNode.childNode(withName: selectedNode!, recursively: true)!
            self.currentNodeAnchor = self.anchors.filter({ $0.name == selectedNode}).first
            print("Should rescale")
        }))
        alert.addAction(UIAlertAction(title: "Delete", style: .default, handler: { [weak alert] (_) in
            let selectedNode = alert?.textFields![0].text!
            if (self.anchors.count > 0 && self.currentNodeAnchor!.name != selectedNode) { // ! Delete will fail if you try to delete with 0 anchors added, and nothing will happen if you try to delete the currently selected node.
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
    
    func setupUI() {
        setUpLabelsAndButtons(text: "Move the camera around to detect surfaces", canShowSaveButton: false, distance: "Distance: N/A")
        loadButton.layer.cornerRadius = 10
        saveButton.layer.cornerRadius = 10
        resetButton.layer.cornerRadius = 10
        // guard let pointOfView = self.sceneView.pointOfView else {return}
    }
    
    func setUpLabelsAndButtons(text: String, canShowSaveButton: Bool, distance: String) {
        self.infoLabel.text = text
        self.saveButton.isEnabled = canShowSaveButton
        self.distanceLabel.text = distance
    }

//     // * Should create fixed arrow, centered at bottom of the scene
    func generateArrowNode() -> SCNNode {
        // Sourced from: https://stackoverflow.com/questions/47191068/how-to-draw-an-arrow-in-scenekit/47207312
        let vertcount = 48;
                let verts: [Float] = [ -1.4923, 1.1824, 2.5000, -6.4923, 0.000, 0.000, -1.4923, -1.1824, 2.5000, 4.6077, -0.5812, 1.6800, 4.6077, -0.5812, -1.6800, 4.6077, 0.5812, -1.6800, 4.6077, 0.5812, 1.6800, -1.4923, -1.1824, -2.5000, -1.4923, 1.1824, -2.5000, -1.4923, 0.4974, -0.9969, -1.4923, 0.4974, 0.9969, -1.4923, -0.4974, 0.9969, -1.4923, -0.4974, -0.9969 ];

                let facecount = 13;
                let faces: [CInt] = [  3, 4, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 0, 1, 2, 3, 4, 5, 6, 7, 1, 8, 8, 1, 0, 2, 1, 7, 9, 8, 0, 10, 10, 0, 2, 11, 11, 2, 7, 12, 12, 7, 8, 9, 9, 5, 4, 12, 10, 6, 5, 9, 11, 3, 6, 10, 12, 4, 3, 11 ];

                let vertsData  = NSData(
                    bytes: verts,
                    length: MemoryLayout<Float>.size * vertcount
                )

                let vertexSource = SCNGeometrySource(data: vertsData as Data,
                                                     semantic: .vertex,
                                                     vectorCount: vertcount,
                                                     usesFloatComponents: true,
                                                     componentsPerVector: 3,
                                                     bytesPerComponent: MemoryLayout<Float>.size,
                                                     dataOffset: 0,
                                                     dataStride: MemoryLayout<Float>.size * 3)

                let polyIndexCount = 61;
                let indexPolyData  = NSData( bytes: faces, length: MemoryLayout<CInt>.size * polyIndexCount )

                let element1 = SCNGeometryElement(data: indexPolyData as Data,
                                                  primitiveType: .polygon,
                                                  primitiveCount: facecount,
                                                  bytesPerIndex: MemoryLayout<CInt>.size)

                let geometry1 = SCNGeometry(sources: [vertexSource], elements: [element1])

                let material1 = geometry1.firstMaterial!

                material1.diffuse.contents = UIColor(red: 0.14, green: 0.82, blue: 0.95, alpha: 1.0)
                material1.lightingModel = .lambert
                material1.transparency = 1.00
                material1.transparencyMode = .dualLayer
                material1.fresnelExponent = 1.00
                material1.reflective.contents = UIColor(white:0.00, alpha:1.0)
                material1.specular.contents = UIColor(white:0.00, alpha:1.0)
                material1.shininess = 1.00

                //Assign the SCNGeometry to a SCNNode, for example:
                let arrowNode = SCNNode()
                arrowNode.geometry = geometry1
                arrowNode.name = "arrow"
                arrowNode.position = SCNVector3(x: 0, y: 0, z: -2)
                arrowNode.scale = SCNVector3(0.1, 0.1, 0.1)
                arrowNode.constraints = [SCNLookAtConstraint.init(target: currentNode)]
                return arrowNode
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
            setUpLabelsAndButtons(text: "Move the camera around to detect surfaces", canShowSaveButton: false, distance: "Distance: N/A")
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
                self.setUpLabelsAndButtons(text: "Can't get current world map", canShowSaveButton: false, distance: "Distance: N/A")
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

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if currentNode != nil {
            let arrow = sceneView.scene.rootNode.childNode(withName: "arrow", recursively: true)
            // Point arrow at destination
            arrow?.constraints = [SCNLookAtConstraint.init(target: currentNode)]
            
            // Generate arrow
            if let pointOfView = sceneView.pointOfView {
                if arrow == nil {
                    let arrowNode = generateArrowNode()
                    DispatchQueue.main.async {
                        pointOfView.name = "camera"
                        self.sceneView.scene.rootNode.addChildNode(pointOfView)
                        self.sceneView.scene.rootNode.childNode(withName: "camera", recursively: true)!.addChildNode(arrowNode)
                    }
                } else {
                    // Update arrow with fun colors (values just for testing)
                    let materials = arrow!.geometry?.materials
                    let material = materials![0]
                    if distanceToDest <= 5.0 {
                        material.diffuse.contents = UIColor.systemGreen
                    } else if distanceToDest <= 10.0 && distanceToDest > 5.0 {
                        material.diffuse.contents = UIColor.systemYellow
                    } else {
                        material.diffuse.contents = UIColor.systemRed
                    }
                }
            }
        }
//        sceneView.scene.rootNode.enumerateChildNodes { (node, stop) in
//            print(node)
//        }
    }
    
    // MARK: - ARSessionDelegate
    //shows the current status of the world map.
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Updates distance to selected node
        var distance = "Distance: N/A"
        if currentNodeAnchor != nil {
            let userPosition = frame.camera.transform.columns.3
            let destPosition = currentNodeAnchor!.transform.columns.3
            distanceToDest = length(userPosition - destPosition).rounded()
            distance = "You are " + String(distanceToDest) + "m away from " + currentNodeAnchor!.name!
        }
        
        switch frame.worldMappingStatus {
            case .notAvailable:
                setUpLabelsAndButtons(text: "Map Status: Not available", canShowSaveButton: false, distance: distance)
            case .limited:
                setUpLabelsAndButtons(text: "Map Status: Available but has Limited features", canShowSaveButton: false, distance: distance)
            case .extending:
                setUpLabelsAndButtons(text: "Map Status: Actively extending the map", canShowSaveButton: false, distance: distance)
            case .mapped:
                setUpLabelsAndButtons(text: "Map Status: Mapped the visible Area", canShowSaveButton: true, distance: distance)
            @unknown default:
                setUpLabelsAndButtons(text: "Map Status: Not available", canShowSaveButton: false, distance: distance)
        }
    }
}
