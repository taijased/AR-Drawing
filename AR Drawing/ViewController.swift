//
//  ViewController.swift
//  AR Drawing
//
//  Created by Maxim Spiridonov on 10/07/2019.
//  Copyright © 2019 Rayan Slim. All rights reserved.
//

import UIKit
import ARKit
import ColorPickTip
import Photos


class ViewController: UIViewController, ARSCNViewDelegate {

    @IBAction func closeVC(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    @IBAction func saveSreenshot(_ sender: UIButton) {
        
        let renderedImage = sceneView.snapshot()

        let shareText = "Try augmented reality in your phone!"
        let activityViewController = UIActivityViewController(activityItems: [shareText, renderedImage], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceRect = CGRect(x: view.center.x, y: view.center.y, width: 0, height: 0)
        activityViewController.popoverPresentationController?.sourceView = view
        activityViewController.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
        
        activityViewController.completionWithItemsHandler = {(activityType: UIActivity.ActivityType?, completed:Bool, returnedItems:[Any]?, error: Error?) in if completed {
                // do something on completion if you want
            }
        }
        present(activityViewController, animated: true, completion: nil)
    }

    private var brushColor: UIColor = UIColor.red

    @IBOutlet weak var draw: UIButton!
    @IBOutlet weak var sceneView: ARSCNView!
    let configuration = ARWorldTrackingConfiguration()
    
    @IBAction func changeColor(_ sender: UIButton) {
        let paletteColors: [[UIColor?]] = [[.red, .green, .blue], [.white, .purple, .black]]
        
        let colorPickTipVC = ColorPickTipController(palette: paletteColors, options: nil)
        colorPickTipVC.popoverPresentationController?.delegate = colorPickTipVC
        colorPickTipVC.popoverPresentationController?.sourceView = sender  // some UIButton
        colorPickTipVC.popoverPresentationController?.sourceRect = sender.bounds
        colorPickTipVC.selected = { color, index in
            guard let color = color else { return }
            DispatchQueue.main.async {
                self.brushColor = color
            }
        }
        self.present(colorPickTipVC, animated: true, completion: nil)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sceneView.session.run(configuration)
        self.sceneView.delegate = self
        
        // Do any additional setup after loading the view, typically from a nib.
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
        guard let pointOfView = sceneView.pointOfView else {return}
        let transform = pointOfView.transform
        let orientation = SCNVector3(-transform.m31,-transform.m32,-transform.m33)
        let location = SCNVector3(transform.m41,transform.m42,transform.m43)
        let currentPositionOfCamera = orientation + location
        DispatchQueue.main.async {
            if self.draw.isHighlighted {
                let sphereNode = SCNNode(geometry: SCNSphere(radius: 0.02))
                sphereNode.position = currentPositionOfCamera
                self.sceneView.scene.rootNode.addChildNode(sphereNode)
                sphereNode.geometry?.firstMaterial?.diffuse.contents = self.brushColor
            }
            else {
                let pointer = SCNNode(geometry: SCNSphere(radius: 0.02))
                pointer.name = "pointer"
                pointer.position = currentPositionOfCamera
                self.sceneView.scene.rootNode.enumerateChildNodes({ (node, _) in
                    if node.name == "pointer" {
                    node.removeFromParentNode()
                    }
                })
                self.sceneView.scene.rootNode.addChildNode(pointer)
                pointer.geometry?.firstMaterial?.diffuse.contents = self.brushColor

            }
        }
    }
}

func +(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    
    return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
    
}

