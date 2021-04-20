import UIKit
import SceneKit
import ARKit
import CoreData

/*
? How to determine bounds of where user can go?
? Do we want every user to be able to add to the map? What if someone tries to mess it up?
    * Even just plane anchors could be added, but if they go out of bounds, that would be annoying to save
    * Users cannot add new location nodes
    * Automatically save new plane nodes on quit?
*/

class UserViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var loadButton: UIButton!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var logoutButton: UIButton!
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView! // Search results
    
    var container: NSPersistentContainer!
    
    var searchActive : Bool = false
    var filtered:[String] = []
    var locations: [String] = []
    
    var horizontalPlanes = [ARPlaneAnchor: SCNNode]()
    var verticalPlanes = [ARPlaneAnchor: SCNNode]()

    var anchors: [ARAnchor] = []

    var destNodeAnchor: ARAnchor?
    var destNode: SCNNode?
    
    var distanceToDest: Float = 0.0
  /// This fucntion will render the map to the device
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
        
        /// Set the view's delegate
        sceneView.delegate = self
        
        /// set session delegate
        self.sceneView.session.delegate = self
        
        /// Create a new scene
        let scene = SCNScene()
        
        /// Set the scene to the view
        sceneView.scene = scene
        
        /// Set lighting to the view
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
        
        setupUI()
}
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        /// Create a session configuration and run the view's session
        resetTrackingConfiguration()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        /// Pause the view's session
        sceneView.session.pause()
    }
    
    func resetTrackingConfiguration() {
        let configuration = ARWorldTrackingConfiguration()
        let options: ARSession.RunOptions = [.resetTracking, .removeExistingAnchors]
        /// Delete all nodes from hierarchy
        sceneView.scene.rootNode.enumerateChildNodes { (node, stop) in
            node.removeFromParentNode()
        }

        sceneView.session.run(configuration, options: options)
        
        setUpLabelsAndButtons(text: "Move the camera around to detect surfaces", distance: "Distance: N/A")
    }

    func setupUI() {
        setUpLabelsAndButtons(text: "Move the camera around to detect surfaces", distance: "Distance: N/A")
        loadButton.layer.cornerRadius = 10
        
        searchBar.placeholder = "Where do you want to go?"
        searchBar.isHidden = true
        tableView.isHidden = true
        searchBar.delegate = self
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    func setUpLabelsAndButtons(text: String, distance: String) {
        self.infoLabel.text = text
        self.distanceLabel.text = distance
    }
    
    ///Generates a text box to a node
    func generateTextNode(label: String, anchor: ARAnchor) {
        print("Generating text node for ", label)
        let textNode = SCNNode()
        textNode.name = label
        /// Create text geometry
        let textGeometry = SCNText(string: label , extrusionDepth: 1)
        /// Set text font and size, flatness (how smooth the text looks, and color)
        textGeometry.font = UIFont(name: "Optima", size: 1)
        textGeometry.flatness = 0
        textGeometry.firstMaterial?.diffuse.contents = UIColor.white
        textNode.geometry = textGeometry

        /// Set the pivot at the center (for rotation)
        let min = textNode.boundingBox.min
        let max = textNode.boundingBox.max
        textNode.pivot = SCNMatrix4MakeTranslation(
            min.x + (max.x - min.x)/2,
            min.y + (max.y - min.y)/2,
            min.z + (max.z - min.z)/2
        )
        /// Scale text node
        textNode.scale = SCNVector3(0.05, 0.05 , 0.05)
        /// Always make text face viewer
        textNode.constraints = [SCNBillboardConstraint()]
        /// Add text node to the hierarchy and position it
        self.sceneView.scene.rootNode.addChildNode(textNode)
        
        let position = anchor.transform.columns.3
        textNode.position = SCNVector3(position.x, position.y, position.z)
    }

     // * Should create fixed arrow, centered at bottom of the scene
    func generateArrowNode() -> SCNNode {
        /// Sourced from: https://stackoverflow.com/questions/47191068/how-to-draw-an-arrow-in-scenekit/47207312
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

        ///Assign the SCNGeometry to a SCNNode, for example:
        let arrowNode = SCNNode()
        arrowNode.geometry = geometry1
        arrowNode.name = "arrow"
        arrowNode.position = SCNVector3(x: 0, y: 0, z: -2)
        arrowNode.scale = SCNVector3(0.1, 0.1, 0.1)
   //     arrowNode.localRotate(by: SCNQuaternion(x: 1, y: 0, z: 0, w: 0.7071))
      //  arrowNode.rotation = SCNVector4Make(1, 1, 0, .pi / 2)
//        arrowNode.constraints = [SCNLookAtConstraint(target: destNode)]
   //     arrowNode.constraints = [SCNLookAtConstraint.init(target: destNode)]
        let lookAtConstraint = SCNLookAtConstraint(target: destNode)
        lookAtConstraint.localFront = SCNVector3Make(-1.5, -1, 0)
                arrowNode.constraints = [lookAtConstraint]
        return arrowNode
    }
    
    func showAlert(message: String) {
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    
    // MARK: - Button Actions
    @IBAction func loadButtonAction(_ sender: Any) {
        guard let mapData = try? Data(contentsOf: self.worldMapURL), let worldMap = ((try? NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: mapData)) as ARWorldMap??)
        else {
            fatalError("No ARWorldMap in archive.")
        }
        
        print("Printing anchors:")
        anchors = worldMap!.anchors
        for i in anchors {
            print(i)
        }
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        
        let options: ARSession.RunOptions = [.resetTracking, .removeExistingAnchors]
        if let worldMap = worldMap {
            configuration.initialWorldMap = worldMap
            showAlert(message: "Map Loaded")
        } else {
            setUpLabelsAndButtons(text: "Move the camera around to detect surfaces", distance: "Distance: N/A")
        }
        sceneView.debugOptions = [.showFeaturePoints]
        sceneView.session.run(configuration, options: options)
        
        print("Printing scene nodes:")
        sceneView.scene.rootNode.enumerateChildNodes { (node, stop) in
            print(node)
        }
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchActive = true;
    }

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchActive = false;
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false;
        self.dismiss(animated: true, completion: nil);
        searchBar.resignFirstResponder()
        searchBar.showsCancelButton = false
        searchBar.text = ""
        searchBar.isHidden = true
        tableView.isHidden = true
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false;
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchBar.showsCancelButton = true

        if (searchText == "") {
            filtered = locations
        } else {
            filtered = locations.filter({ (text) -> Bool in
                let tmp: NSString = text as NSString
                let range = tmp.range(of: searchText, options: NSString.CompareOptions.caseInsensitive)
                return range.location != NSNotFound
            })
        }
        
        if (filtered.count == 0){
            searchActive = false;
        } else {
            searchActive = true;
        }
        self.tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (searchActive) {
            return filtered.count
        }
        return locations.count;
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")! as UITableViewCell;
        if (searchActive) {
            print("index out of range checker: ", cell)
            cell.textLabel?.text = filtered[indexPath.row]
        } else {
            cell.textLabel?.text = locations[indexPath.row];
        }
        
        return cell;
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = filtered[indexPath.row]
        var locationExists = false
        for index in 0...(self.anchors.count - 1) {
            if self.anchors[index].name == cell {
                self.destNodeAnchor = self.anchors[index]
                self.destNode = self.sceneView.scene.rootNode.childNode(withName: cell, recursively: true)
                locationExists = true
            }
        }
        // I don't think this would ever be triggered
        if (!locationExists) {
            print("No anchor found with that matching destination")
            let alert = UIAlertController(title: "Location Not Found", message: "No location found with that name", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        self.dismiss(animated: true, completion: nil);
        searchBar.resignFirstResponder()
        searchBar.isHidden = true
        tableView.isHidden = true
    }
    
    /// Creates search bar for user to search building
    @IBAction func searchButtonAction(_ sender: Any) {
        searchBar.isHidden = false
        tableView.isHidden = false
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // ? Should text nodes be children of their plane?
        guard let planeAnchor = anchor as? ARPlaneAnchor
        else {
            // Rendering existing anchors
            // If location anchor doesn't have a name, it will have ??? by default
            generateTextNode(label: anchor.name ?? "???", anchor: anchor)
            locations.append(anchor.name!)
            return
         }
        
        // TODO: track planes??
    }
    // MARK: - ARSCNViewDelegate

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
        if destNodeAnchor != nil {
            let arrow = sceneView.scene.rootNode.childNode(withName: "arrow", recursively: true)
            /// Point arrow at destination
//            arrow?.constraints = [SCNLookAtConstraint(target: destNode)]
            
            /// Generate arrow
            if let pointOfView = sceneView.pointOfView {
                if arrow == nil {
                    let arrowNode = generateArrowNode()
                    DispatchQueue.main.async {
                        pointOfView.name = "camera"
                        self.sceneView.scene.rootNode.addChildNode(pointOfView)
                        self.sceneView.scene.rootNode.childNode(withName: "camera", recursively: true)!.addChildNode(arrowNode)
                    }
                } else {
                    /// Update arrow with fun colors (values just for testing)
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
    ///shows the current status of the world map.
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        /// Updates distance to selected node
        var distance = "Distance: N/A"
        if destNodeAnchor != nil {
            let userPosition = frame.camera.transform.columns.3
            let destPosition = destNodeAnchor!.transform.columns.3
            distanceToDest = length(userPosition - destPosition).rounded()
            distance = "You are " + String(distanceToDest) + "m away from " + destNodeAnchor!.name!
        }
        
        switch frame.worldMappingStatus {
            case .notAvailable:
                setUpLabelsAndButtons(text: "Map Status: Not available", distance: distance)
            case .limited:
                setUpLabelsAndButtons(text: "Map Status: Available but has Limited features", distance: distance)
            case .extending:
                setUpLabelsAndButtons(text: "Map Status: Actively extending the map", distance: distance)
            case .mapped:
                setUpLabelsAndButtons(text: "Map Status: Mapped the visible Area", distance: distance)
            @unknown default:
                setUpLabelsAndButtons(text: "Map Status: Not available", distance: distance)
        }
    }
    
    

    
    
    
}

