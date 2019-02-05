//
//  ViewController.swift
//  HoirzontalAttempt 2
//
//  Created by Omaha Project on 11/27/18.
//  Copyright © 2018 Omaha Project. All rights reserved.
//

/*
 Citations used for the coding portion of this project:
 
 1.) Brian Advent, https://www.youtube.com/watch?v=mkD5Jw-bLLs&list=PLY1P2_piiWEZFWsH507mBa5WGR7t6P4c_&index=4&t=126s
 
    We used the ideas from this video as well as code from the GitHub to learn how to use plane detection, placing an object on that plane, and utilizing light estimation to improve authenticity. 31 January 2019.
 
 2.) Jared Davidson, www.youtube.com/watch?v=bfAadJNX3Tc.
 
      Jared Davidson's content was used extensively in the beginning as a method of learning the basics of Swift, XCode, and ARKit.
 
 
 3.) Mark Dawson, https: //blog.markdaws.net/arkit-by-example-part-2-plane-detection-visualization-10f05876d53
 
    Mark Dawson's code was to used to further familiarize with plane detection, adding a plane, and updating it in real time.
 
 4.) N Javen, https://www.appcoda.com/arkit-horizontal-plane/
 
    N Javen's code was used to study an alternative method of adding a horizontal plane to a surface.
 
 */


import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    
    var planeGeometry: SCNPlane!
    let planeIdentifiers = [UUID]()
    var anchors = [ARAnchor]()
    var sceneLight: SCNLight!
    // Tracks if a map has been placed by a user.
    var mapPlaced = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        sceneView.autoenablesDefaultLighting = false
        
        let scene = SCNScene()
        
        sceneView.scene = scene
        
        // From Citation 1. This adds a node and attaches light to a node in a specific position.
        sceneLight = SCNLight()
        sceneLight.type = .omni
        
        
        let lightNode = SCNNode()
        lightNode.light = sceneLight
        lightNode.position = SCNVector3(x:0, y:10, z:2)
        
        sceneView.scene.rootNode.addChildNode(lightNode)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        // From Citations 1 and 4. Enables horizontal plane detection and light estimation.
        configuration.planeDetection = .horizontal
        configuration.isLightEstimationEnabled = true
        
        // run view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        let location = touch?.location(in: sceneView)
       
        addNodeAtLocation(location: location!)
    }
        override func didReceiveMemoryWarning() {
            super.didReceiveMemoryWarning()
            // Release any cached data, images, etc not in use
        }
    
    // From Citation 1. Creates and configures nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        var node: SCNNode?
        if mapPlaced == false{
            if let planeAnchor = anchor as? ARPlaneAnchor {
                node = SCNNode()
                planeGeometry = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
                // Gives plane a transparent white color
                planeGeometry.firstMaterial?.diffuse.contents = UIColor.white.withAlphaComponent(0.5)
                
                let planeNode = SCNNode(geometry: planeGeometry)
                planeNode.position = SCNVector3(x: planeAnchor.center.x, y:0, z: planeAnchor.center.z)
                //Rotate on x-axis
                planeNode.transform = SCNMatrix4MakeRotation(-Float.pi/2, 1, 0, 0)
                
                updateMaterial()
                
                node?.addChildNode(planeNode)
                anchors.append(planeAnchor)
            }
        
            return node
        }
        else{
            node = nil
            return node
        }
    }
    // From Citation 1
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if let estimate = self.sceneView.session.currentFrame?.lightEstimate {
            sceneLight.intensity = estimate.ambientIntensity
        }
        
    }
    // From Citation 1. Updates the plane as the camera detects more horizontal surfaces.
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if let planeAnchor = anchor as? ARPlaneAnchor {
            if anchors.contains(planeAnchor) {
                if node.childNodes.count > 0 {
                    let planeNode = node.childNodes.first!
                    planeNode.position = SCNVector3(x: planeAnchor.center.x, y:0, z: planeAnchor.center.z)
                    
                    if let plane = planeNode.geometry as? SCNPlane {
                        plane.width = CGFloat(planeAnchor.extent.x)
                        plane.height = CGFloat(planeAnchor.extent.z)
                        updateMaterial()
                    }
                }
            }
        }
    }
    // From Citation 1
    func updateMaterial() {
        let material = self.planeGeometry.materials.first!
        material.diffuse.contentsTransform = SCNMatrix4MakeScale(Float(self.planeGeometry.width), Float(self.planeGeometry.height), 1)
    }
    // From Citation 1. This detects a finger tap on an already established horizontal plane, and if there is a tap on the plane, this marks a new location where the map scene will be placed. Once the map is in the process of being placed, all visible planes will be removed after a brief black screen to both prevent users from overloading the application and maintain a clean look.
    func addNodeAtLocation (location:CGPoint) {
        guard anchors.count > 0 else {print("anchors not created yet"); return}
        
        let hitResults = sceneView.hitTest(location, types: .existingPlaneUsingExtent)
        
        if hitResults.count > 0 {
            let result = hitResults.first!
            let newLocation = SCNVector3(x: result.worldTransform.columns.3.x, y: result.worldTransform.columns.3.y + 0.15, z: result.worldTransform.columns.3.z)
            guard let mapScene = SCNScene(named: "art.scnassets/map2.scn"),
                let mapNode = mapScene.rootNode.childNodes.first
                else { return }
            mapNode.position = newLocation
            mapNode.simdScale = simd_float3(0.001,0.001,0.001)
            
            mapPlaced = true
            
            //sceneView =
            let blankScene = SCNScene()
            
            sceneView.scene = blankScene
            
            sceneView.scene.rootNode.addChildNode(mapNode)
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
    }
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform user that session has been interrupted
    }
}
