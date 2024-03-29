//
//  RulerViewController.swift
//  AR Drawing
//
//  Created by Maxim Spiridonov on 15/07/2019.
//  Copyright © 2019 Rayan Slim. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class RulerViewController: UIViewController, ARSCNViewDelegate {

    var center : CGPoint!
    
    @IBOutlet weak var distLbl: UILabel!
    @IBAction func closeSceneView(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    @IBOutlet weak var sceneView: ARSCNView!
    let arrow = SCNScene(named: "assets.scnassets/pointer.scn")!.rootNode
    var positions = [SCNVector3]()
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        let hitTest = sceneView.hitTest(center, types: .featurePoint)
        let result = hitTest.last
        guard let transform = result?.worldTransform else {return}
        let thirdColumn = transform.columns.3
        let position = SCNVector3Make(thirdColumn.x, thirdColumn.y, thirdColumn.z)
        positions.append(position)
        let lastTenPositions = positions.suffix(10)
        arrow.position = getAveragePosition(from: lastTenPositions)
    }
    
    func getAveragePosition(from positions : ArraySlice<SCNVector3>) -> SCNVector3 {
        var averageX : Float = 0
        var averageY : Float = 0
        var averageZ : Float = 0
        
        for position in positions {
            averageX += position.x
            averageY += position.y
            averageZ += position.z
        }
        let count = Float(positions.count)
        return SCNVector3Make(averageX / count , averageY / count, averageZ / count)
    }
    
    var isFirstPoint = true
    var points = [SCNNode]()
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        let sphereGeometry = SCNSphere(radius: 0.005)
        let sphereNode = SCNNode(geometry: sphereGeometry)
        sphereNode.position = arrow.position
        sceneView.scene.rootNode.addChildNode(sphereNode)
        points.append(sphereNode)
        
        if isFirstPoint {
            isFirstPoint = false
        } else {
            //calculate the distance
            let pointA = points[points.count - 2]
            guard let pointB = points.last else {return}
            
            let d = distance(float3(pointA.position), float3(pointB.position))
            
            // add line
            let line = SCNGeometry.line(from: pointA.position, to: pointB.position)
            print(d.description)
            let lineNode = SCNNode(geometry: line)
            sceneView.scene.rootNode.addChildNode(lineNode)
            
            // add midPoint
            let midPoint = (float3(pointA.position) + float3(pointB.position)) / 2
            let midPointGeometry = SCNSphere(radius: 0.003)
            midPointGeometry.firstMaterial?.diffuse.contents = UIColor.red
            let midPointNode = SCNNode(geometry: midPointGeometry)
            midPointNode.position = SCNVector3Make(midPoint.x, midPoint.y, midPoint.z)
            sceneView.scene.rootNode.addChildNode(midPointNode)
            
            // add text
            distLbl.text = String(format: "%.0f", d * 100) + "cm"
            let textGeometry = SCNText(string: String(format: "%.0f", d * 100) + "cm" , extrusionDepth: 1)
            let textNode = SCNNode(geometry: textGeometry)
            textNode.scale = SCNVector3Make(0.005, 0.005, 0.01)
            textGeometry.flatness = 0.2
            midPointNode.addChildNode(textNode)
            
            
            // Billboard contraints
            let contraints = SCNBillboardConstraint()
            contraints.freeAxes = .all
            midPointNode.constraints = [contraints]
            
            
            isFirstPoint = true
        }
        
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
        center = view.center
        sceneView.scene.rootNode.addChildNode(arrow)
        sceneView.autoenablesDefaultLighting = true
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        center = view.center
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
}

extension SCNGeometry {
    class func line(from vectorA : SCNVector3, to vectorB : SCNVector3) -> SCNGeometry {
        let indices : [Int32] = [0,1]
        let source = SCNGeometrySource(vertices: [vectorA, vectorB])
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)
        return SCNGeometry(sources: [source], elements: [element])
    }
}


