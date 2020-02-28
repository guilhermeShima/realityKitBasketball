//
//  ViewController.swift
//  ARProject
//
//  Created by Guilherme Tavares Shimamoto on 18/02/20.
//  Copyright © 2020 Guilherme Shimamoto. All rights reserved.
//

import UIKit
import ARKit
import RealityKit
import Combine
import simd

protocol ViewDelegate: class {
    func addAnchor(for anchor: Basketball.Game)
    func updatedPointsLabel(with points: Int)
}

class ViewController: UIViewController {
    
    @IBOutlet var arView: ARView!
    
    @IBOutlet weak var touchView: UIView! {
        didSet {
            touchView.isHidden = true
        }
    }
    
    @IBOutlet weak var coachingView: ARCoachingOverlayView! {
        didSet {
            coachingView.activatesAutomatically = false
            coachingView.setActive(false, animated: true)
        }
    }
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var startButton: UIButton!
    
    @IBOutlet weak var pointsLabel: UILabel! {
        didSet {
            pointsLabel.isHidden = true
        }
    }
    
    @IBOutlet weak var repositionButton: UIButton! {
        didSet {
            repositionButton.isHidden = true
        }
    }
    
    var gameController: GameController?
    
    var collisionEventStreams = [AnyCancellable]()
    
    var longPressBeginTime: TimeInterval?
    
    var longPressDuration: TimeInterval?
    
    var intensityView: UIView = UIView()
    
    var intensity: Int = 1
    
    var timer: Timer?
    
    deinit {
        collisionEventStreams.removeAll()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.isLightEstimationEnabled = true
        
        // Run the view's session
        arView.session.run(configuration)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        gameController = GameController(viewDelegate: self)
        addGesture()
        presentCoachingOverlay()
    }
    
    func presentCoachingOverlay() {
        coachingView.session = arView.session
        coachingView.delegate = self
        coachingView.goal = .horizontalPlane
    }
    
    func addGesture() {
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(longPress(_:)))
        gesture.minimumPressDuration = 0.2
        
        self.touchView.addGestureRecognizer(gesture)
    }
    
    @objc func longPress(_ longPress: UIGestureRecognizer) {
        let state = longPress.state
        
        switch state {
        case .began:
            //Adding intensity view
            let location = longPress.location(in: touchView)
            intensityView = UIView(frame: CGRect(x: location.x - 25, y: location.y - 25, width: 50, height: 50))
            intensityView.clipsToBounds = true
            intensityView.layer.masksToBounds = true
            intensityView.layer.cornerRadius = intensityView.bounds.size.width/2
            intensityView.backgroundColor = UIColor(displayP3Red: 0, green: 0, blue: 0, alpha: 0.4)
            touchView.addSubview(intensityView)
            
            intensity = 1
            longPressBeginTime = NSDate.timeIntervalSinceReferenceDate
            timer = Timer.scheduledTimer(timeInterval: 1.0,
                                         target: self,
                                         selector: #selector(touchTimer),
                                         userInfo: nil,
                                         repeats: true)
        case .ended:
            intensityView.removeFromSuperview()
            timer?.invalidate()
            gameController?.throwBall(for: intensity)
        default:
            return
        }
    }
    
    @objc func touchTimer() {
        var duration = NSDate.timeIntervalSinceReferenceDate - (longPressBeginTime ?? 0)
        duration = duration > 5 ? 4 : duration
        longPressDuration = duration
        
        intensity = (Int(duration) % 6) + 1
        
        DispatchQueue.main.async {
            //Increasing intensity view size
            UIView.animate(withDuration: 0.3) {
                self.intensityView.transform = CGAffineTransform(scaleX: CGFloat(self.intensity),
                                                                 y: CGFloat(self.intensity))
            }
            
            //Sending feedback
            let notificationFeedbackGenerator = UINotificationFeedbackGenerator()
            notificationFeedbackGenerator.prepare()
            notificationFeedbackGenerator.notificationOccurred(.success)
        }
    }
    
    @IBAction func didTapStart(_ sender: Any) {
        titleLabel.isHidden = true
        startButton.isHidden = true
        
        coachingView.setActive(true, animated: true)
        coachingView.activatesAutomatically = true
        presentCoachingOverlay()
    }
    
    @IBAction func didTapReposition(_ sender: Any) {
        gameController?.game.notifications.reposition.post()
    }
}

extension ViewController: ARCoachingOverlayViewDelegate {
    func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) {
        coachingView.removeFromSuperview()
        gameController?.startGame()
        
        //Adding collision Event
        arView.scene.subscribe(to: CollisionEvents.Ended.self) { event in
            self.gameController?.treatCollision(entityA: event.entityA, entityB: event.entityB)
        }.store(in: &collisionEventStreams)
    }
}

extension ViewController: ViewDelegate {    
    func addAnchor(for anchor: Basketball.Game) {
        arView.scene.anchors.append(anchor)
        
        pointsLabel.isHidden = false
        repositionButton.isHidden = false
        touchView.isHidden = false
    }
    
    func updatedPointsLabel(with points: Int) {
        pointsLabel.text = "\(points) points"
    }
}
