//
//  MGPanController.swift
//  MGPanController
//
//  Created by Marco Guerrieri on 13/06/18.
//  Copyright © 2018 Marco Guerrieri. All rights reserved.
//

import AudioToolbox
import UIKit


@objc public protocol MGPanControllerDelegate {
    @objc optional func didTapController(controllerStatus: MGPanController.ControllerStatus)
    @objc optional func didTapOnSubControllerAt(index: Int, sender: UIButton?)
    @objc optional func didTapOnTabBarAt(index: Int, sender: UIButton?)
    @objc optional func didPerformSwipeAction(direction: MGPanController.Direction)
    @objc optional func isPanningIn(direction: MGPanController.Direction)
    @objc optional func didOpenSubController()
    @objc optional func didCloseSubController()
    @objc optional func willOpenSubController()
    @objc optional func willCloseSubController()
}

@IBDesignable
@objc open class MGPanController: UIView {
    
    @objc public enum Direction : Int {
        case noDirection = -1
        case bottomDirection = 0
        case topDirection = 1
        case leftDirection = 2
        case rightDirection = 3
    }
    
    private enum ControllerMovement : Int {
        case noMovement
        case vertical
        case horizontal
    }
    
    @objc public enum ControllerStatus : Int {
        case play = 1
        case pause = 0
    }

    @IBOutlet var containerView: UIView!
    @IBOutlet weak var fullContainerView: UIView!
    @IBOutlet weak var tabBarView: UIView!
    @IBOutlet weak var horizontalActionView: UIView!
    @IBOutlet weak var subControllerView: UIView!
    @IBOutlet weak var controllerView: UIView!
    
    @IBOutlet weak var controllerBckgImg: UIImageView!
    @IBOutlet weak var controllerCentralImg: UIImageView!
    @IBOutlet weak var horizontalActionLeftImage: UIImageView!
    @IBOutlet weak var horizontalActionRightImage: UIImageView!
    
    @IBOutlet weak var horizontalActionLeftCnstr: NSLayoutConstraint!
    @IBOutlet weak var horizontalActionRightCnstr: NSLayoutConstraint!
    @IBOutlet weak var subcontrollerHeightCnstr: NSLayoutConstraint!
    @IBOutlet weak var controllerVertCenterCnstr: NSLayoutConstraint!
    @IBOutlet weak var controllerHoriCenterCnstr: NSLayoutConstraint!

    @IBOutlet weak var firstSubControllerBnt: UIButton!
    @IBOutlet weak var secondSubControllerBnt: UIButton!
    @IBOutlet weak var thirdSubControllerBnt: UIButton!
    @IBOutlet weak var fourthSubControllerBnt: UIButton!
    
    @IBOutlet weak var firstTabBarBnt: UIButton!
    @IBOutlet weak var secondTabBarBnt: UIButton!
    @IBOutlet weak var thirdTabBarBnt: UIButton!
    @IBOutlet weak var fourthTabBarBnt: UIButton!
    

    private var actionDirection : Direction = .noDirection
    private var controllerMovement : ControllerMovement = .noMovement
    private var controllerStatus : ControllerStatus = .pause
    private var panGesture : UIPanGestureRecognizer?
    private var maxHorizontalMovement : CGFloat = 0
    private var maxVerticalMovement : CGFloat = 0
    private let horizontalTriggerPoint : CGFloat = 50
    private let verticalTriggerPoint : CGFloat = 50
    
    private var closedSubcontrollerHeight : CGFloat = 0
    private var openedSubcontrollerHeight : CGFloat = 80
    
    public private(set) var controllerImageForStatus : [ControllerStatus:UIImage] = [:]
    public private(set) var canVibrate : Bool = true
    public private(set) var vibrationType : UIImpactFeedbackStyle = .light
    
    public var delegate: MGPanControllerDelegate?

    // MARK: LAYOUT INITIALIZATION
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        let customViewNib = loadFromNib()
        customViewNib.frame = bounds
        customViewNib.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
        addSubview(customViewNib)
    }
    
    func loadFromNib() -> UIView {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: String(describing: type(of: self)), bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil).first as! UIView
        return view
    }
    
    override open func awakeFromNib() {
        super.awakeFromNib()
        xibSetup()
    }
    
    private func xibSetup(){
        self.subControllerView.alpha = 0
        self.controllerView.isUserInteractionEnabled = true
        self.controllerBckgImg.isUserInteractionEnabled = true
        self.openedSubcontrollerHeight = self.subcontrollerHeightCnstr.constant
        self.panGesture = UIPanGestureRecognizer.init(target: self, action: #selector(pan(recognizer:)))
        self.controllerView.addGestureRecognizer(panGesture!)
        self.controllerBckgImg.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(tap(recognizer:))))
        self.controllerBckgImg.addGestureRecognizer(UILongPressGestureRecognizer.init(target: self, action: #selector(longPress(recognizer:))))
        self.resetController()
        self.subControllerView.mgpcCornerRadius = self.controllerView.frame.size.height / 2
        self.subcontrollerHeightCnstr.constant = self.closedSubcontrollerHeight
        self.controllerCentralImg.image = self.controllerImageForStatus[self.controllerStatus] ?? nil
    }

    override open func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        fullContainerView?.prepareForInterfaceBuilder()
        tabBarView?.prepareForInterfaceBuilder()
        horizontalActionView?.prepareForInterfaceBuilder()
        subControllerView?.prepareForInterfaceBuilder()
        controllerView?.prepareForInterfaceBuilder()
        controllerBckgImg?.prepareForInterfaceBuilder()
        controllerCentralImg?.prepareForInterfaceBuilder()
        horizontalActionLeftImage?.prepareForInterfaceBuilder()
        horizontalActionRightImage?.prepareForInterfaceBuilder()
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        self.maxHorizontalMovement = self.controllerView.frame.origin.x
        self.maxVerticalMovement = self.controllerView.frame.origin.y
    }

    
    // MARK: CALLABLE FUNCTIONS
    public func changeVibration(active: Bool, type: UIImpactFeedbackStyle? = nil){
        self.canVibrate = active
        self.vibrationType = type ?? .light
    }
    
    public func setControllerImage(_ image: UIImage?, forStatus status: ControllerStatus) {
        self.controllerImageForStatus[status] = image
        self.controllerCentralImg.image = self.controllerImageForStatus[self.controllerStatus] ?? nil
    }
    
    public func setControllerBackgroundImage(_ image: UIImage?) {
        self.controllerBckgImg.image = image
    }
    
    // MARK: PRIVATE METHODS (ALMOST)
    private func toggleSubcontroller(forceOpen: Bool = false) {
        if self.subcontrollerHeightCnstr.constant == self.closedSubcontrollerHeight || forceOpen {
            // OPEN
            self.delegate?.willOpenSubController?()
            openSubController(animated: true)
        }
        else {
            // CLOSE
            self.delegate?.willCloseSubController?()
            closeSubController(animated: true)
        }
    }

    private func openSubController(animated: Bool){
        self.subControllerView.isHidden = false
        UIView.animate(withDuration: animated ? 0.25 : 0.0,
                       delay: 0,
                       usingSpringWithDamping: 0.35,
                       initialSpringVelocity: 0.35,
                       options: UIViewAnimationOptions.curveEaseIn,
                       animations: {
                        self.subControllerView.mgpcCornerRadius = (self.controllerView.frame.size.height / 2 + self.openedSubcontrollerHeight / 2)
                        self.subcontrollerHeightCnstr.constant = self.openedSubcontrollerHeight
                        self.fullContainerView.layoutSubviews()
                        
        }, completion: { (value: Bool) in
            self.delegate?.didOpenSubController?()
        })
    }

    private func closeSubController(animated: Bool){
        UIView.animate(withDuration: animated ? 0.055 : 0.0, animations: {
            self.subControllerView.mgpcCornerRadius = self.controllerView.frame.size.height / 2
            self.subcontrollerHeightCnstr.constant = self.closedSubcontrollerHeight
            self.fullContainerView.layoutSubviews()
        }) { (success) in
            self.subControllerView.isHidden = true
            self.delegate?.didCloseSubController?()
        }
    }

    @objc private func tap(recognizer: UIPanGestureRecognizer) {
        if controllerStatus == .pause {
            controllerStatus = .play
            controllerCentralImg.image = UIImage.init(named: "play_icon.png")
        }
        else {
            controllerStatus = .pause
            controllerCentralImg.image = UIImage.init(named: "pause_icon.png")
        }
        self.delegate?.didTapController?(controllerStatus: controllerStatus)
    }


    @objc private func longPress(recognizer: UIPanGestureRecognizer) {
        if recognizer.state == .began {
            self.vibrate()
            toggleSubcontroller()
        }
    }

    @objc public func resetController(animated: Bool = true) {
        UIView.animate(withDuration: animated ? 0.3 : 0,
                       delay: 0,
                       usingSpringWithDamping: 0.4,
                       initialSpringVelocity: 1,
                       options: UIViewAnimationOptions.curveEaseIn,
                       animations: {
                        self.controllerVertCenterCnstr.constant = 0
                        self.controllerHoriCenterCnstr.constant = 0
                        self.fullContainerView.layoutSubviews()
        }, completion: {
            //Code to run after animating
            (value: Bool) in
        })
        self.horizontalActionRightCnstr.constant = -self.controllerView.frame.size.width / 2
        self.horizontalActionLeftCnstr.constant = self.controllerView.frame.size.width / 2
        self.horizontalActionView.alpha = 0
        self.subControllerView.alpha = 0.8
        self.controllerView.alpha = 1
        self.controllerMovement = .noMovement
        self.actionDirection = .noDirection
        self.panGesture!.isEnabled = true
    }


    @objc private func pan(recognizer: UIPanGestureRecognizer) {
        let yMove = recognizer.translation(in: self).y
        let xMove = recognizer.translation(in: self).x
        if recognizer.state == UIGestureRecognizerState.changed {
            if self.controllerMovement == .noMovement {
                if abs(yMove) > abs(xMove) {
                    self.controllerMovement = .vertical
                }
                else if abs(yMove) < abs(xMove) {
                    self.controllerMovement = .horizontal
                }
                else {
                    return
                }
            }
//            if abs(yMove) <= 16
//            && abs(xMove) <= 16 {
//                self.controllerHoriCenterCnstr.constant = 0
//                self.controllerVertCenterCnstr.constant = 0
//                self.controllerMovement = .noMovement
//            }
//            else{
//                self.vibrate()
//            }
            
            
            if self.subcontrollerHeightCnstr.constant > 0 && self.controllerMovement == .horizontal {
                self.controllerMovement = .noMovement
                return
            }
            
            switch self.controllerMovement{
            case .horizontal:
                self.controllerVertCenterCnstr.constant = 0
                self.controllerHoriCenterCnstr.constant = (-maxHorizontalMovement ... maxHorizontalMovement).clamp(xMove)
                if xMove > 0 {
                    if self.actionDirection != .rightDirection && xMove > horizontalTriggerPoint {
                        self.actionDirection = .rightDirection
                        self.vibrate()
                    }
                    else if self.actionDirection == .rightDirection && xMove < horizontalTriggerPoint{
                        self.actionDirection = .noDirection
                    }
                    self.isPanningIn(direction: .rightDirection)
                }
                else {
                    if self.actionDirection != .leftDirection && xMove < -horizontalTriggerPoint {
                        self.actionDirection = .leftDirection
                        self.vibrate()
                    }
                    else if self.actionDirection == .leftDirection && xMove > -horizontalTriggerPoint {
                        self.actionDirection = .noDirection
                    }
                    self.isPanningIn(direction: .leftDirection)
                }
                break
                
            case .vertical:
                self.controllerHoriCenterCnstr.constant = 0
                self.controllerVertCenterCnstr.constant = (-maxVerticalMovement ... maxVerticalMovement).clamp(yMove)
                if yMove > 0 {
                    if self.actionDirection != .topDirection && abs(yMove) > verticalTriggerPoint {
                        self.actionDirection = .topDirection
                        self.vibrate()
                    }
                    else if self.actionDirection == .topDirection && abs(yMove) < verticalTriggerPoint {
                        self.actionDirection = .noDirection
                    }
                    self.isPanningIn(direction: .topDirection)
                }
                else {
                    if self.actionDirection != .bottomDirection && yMove < -verticalTriggerPoint {
                        self.actionDirection = .bottomDirection
                        self.vibrate()
                    }
                    else if self.actionDirection == .bottomDirection && yMove > -verticalTriggerPoint {
                        self.actionDirection = .noDirection
                    }
                    self.isPanningIn(direction: .bottomDirection)
                }
                break
                
            default:
                break
            }
        }
        else if recognizer.state == UIGestureRecognizerState.ended {
            self.controllerDidEndMove()
        }
        
    }

    private func controllerDidEndMove() {
        self.panGesture!.isEnabled = false
        self.vibrate()
        switch self.actionDirection{
        case .bottomDirection:
            self.bottomActionTriggered()
            break
            
        case .topDirection:
            self.topActionTriggered()
            break
            
        case .leftDirection:
            self.leftActionTriggered()
            break
            
        case .rightDirection:
            self.rightActionTriggered()
            break
            
        default:
            break
        }
        self.resetController()
    }

    private func vibrate() {
        if canVibrate {
            let generator = UIImpactFeedbackGenerator(style: vibrationType)
            generator.impactOccurred()
        }
    }

    private func leftActionTriggered() {
        self.delegate?.didPerformSwipeAction?(direction: .leftDirection)
    }

    private func rightActionTriggered() {
        self.delegate?.didPerformSwipeAction?(direction: .rightDirection)
    }

    private func topActionTriggered() {
        self.delegate?.didPerformSwipeAction?(direction: .topDirection)
    }

    private func bottomActionTriggered() {
        self.delegate?.didPerformSwipeAction?(direction: .bottomDirection)
    }
    
    private func isPanningIn(direction: MGPanController.Direction) {
        self.delegate?.isPanningIn?(direction: direction)
    }
    
    
    
    @IBAction func firstTabBarPressed(_ sender: Any) {
        self.delegate?.didTapOnTabBarAt?(index: 0, sender: sender as? UIButton)
    }

    @IBAction func secondTabBarPressed(_ sender: Any) {
        self.delegate?.didTapOnTabBarAt?(index: 1, sender: sender as? UIButton)
    }

    @IBAction func thirdTabBarPressed(_ sender: Any) {
        self.delegate?.didTapOnTabBarAt?(index: 2, sender: sender as? UIButton)
    }

    @IBAction func fourthTabBarPressed(_ sender: Any) {
        self.delegate?.didTapOnTabBarAt?(index: 3, sender: sender as? UIButton)
    }

    @IBAction func firstSubControlPressed(_ sender: Any) {
        self.delegate?.didTapOnSubControllerAt?(index: 0, sender: sender as? UIButton)
    }

    @IBAction func secondSubControlPressed(_ sender: Any) {
        self.delegate?.didTapOnSubControllerAt?(index: 1, sender: sender as? UIButton)
    }

    @IBAction func thirdSubControlPressed(_ sender: Any) {
        self.delegate?.didTapOnSubControllerAt?(index: 2, sender: sender as? UIButton)
    }

    @IBAction func fourthSubControlPressed(_ sender: Any) {
        self.delegate?.didTapOnSubControllerAt?(index: 3, sender: sender as? UIButton)
    }
    
}


fileprivate extension UIView {
    
    var mgpcCornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }

    var mgpcRoundView: Bool {
        get {
            return self.mgpcRoundView
        }
        set {
            layer.cornerRadius = self.frame.height/2
            layer.masksToBounds = true
        }
    }
    
}

@IBDesignable
class MGPanControllerRoundView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override open func awakeFromNib() {
        super.awakeFromNib()
        self.mgpcCornerRadius = self.frame.width / 2
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.mgpcCornerRadius = self.frame.width / 2
    }
    
    override open func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        self.mgpcCornerRadius = self.frame.width / 2
    }
    
}

@IBDesignable
class MGRoundImageView: UIImageView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override open func awakeFromNib() {
        super.awakeFromNib()
        self.mgpcCornerRadius = self.frame.width / 2
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.mgpcCornerRadius = self.frame.width / 2
    }
    
    override open func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        self.mgpcCornerRadius = self.frame.width / 2
    }
    
}

extension ClosedRange {
    func clamp(_ value : Bound) -> Bound {
        return self.lowerBound > value ? self.lowerBound
            : self.upperBound < value ? self.upperBound
            : value
    }
}
