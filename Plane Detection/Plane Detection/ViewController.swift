//
//  ViewController.swift
//  HoirzontalAttempt 2
//
//  Created by Omaha Project on 11/27/18.
//  Copyright © 2018 Omaha Project. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    
    var planeGeometry: SCNPlane!
    let planeIdentifiers = [UUID]()
    var anchors = [ARAnchor]()
    var sceneLight: SCNLight!
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
    
    //either generates a plane or returns nothing if a map has already been placed
    
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
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if let estimate = self.sceneView.session.currentFrame?.lightEstimate {
            sceneLight.intensity = estimate.ambientIntensity
        }
        
    }
    
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
    
    func updateMaterial() {
        let material = self.planeGeometry.materials.first!
        material.diffuse.contentsTransform = SCNMatrix4MakeScale(Float(self.planeGeometry.width), Float(self.planeGeometry.height), 1)
    }
    
    func addNodeAtLocation (location:CGPoint) {
        guard anchors.count > 0 else {print("anchors not created yet"); return}
        
        let hitResults = sceneView.hitTest(location, types: .existingPlaneUsingExtent)
        
        if hitResults.count > 0 {
            let result = hitResults.first!
            let newLocation = SCNVector3(x: result.worldTransform.columns.3.x, y: result.worldTransform.columns.3.y + 0.15, z: result.worldTransform.columns.3.z)
            guard let mapScene = SCNScene(named: "art.scnassets/map.scn"),
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
