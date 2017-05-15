//
//  NotificationView.swift
//  Larry
//
//  Created by Inderpal Singh on 3/5/17.
//  Copyright © 2017 Layer. All rights reserved.
//

import UIKit

open class NotificationView: UIToolbar {
    
    // MARK: - Properties
    
    open static var sharedNotification = NotificationView()
    
    
    open var duration: TimeInterval = 3
    
    open fileprivate(set) var isAnimating = false
    open fileprivate(set) var isDragging = false
    
    fileprivate var dismissTimer: Timer? {
        didSet {
            if oldValue?.isValid == true {
                oldValue?.invalidate()
            }
        }
    }
    
    fileprivate var tapAction: (() -> ())?
    
    
    /// Views
    
    fileprivate lazy var messageLabel: UILabel = { [unowned self] in
        let subtitleLabel = UILabel()
        subtitleLabel.backgroundColor = UIColor.clear
        subtitleLabel.textAlignment = .left
        subtitleLabel.numberOfLines = 2
        subtitleLabel.font = UIFont.systemFont(ofSize: 13)
        subtitleLabel.textColor = Colors.darkGray
        return subtitleLabel
        }()
    
    fileprivate lazy var messageImage: UIImageView = { [unowned self] in
        let messageImage = UIImageView(image: #imageLiteral(resourceName: "messages"))
        return messageImage
        }()
    
    fileprivate var textPointX: CGFloat {
        return  NotificationLayout.textBorder
    }
    
    fileprivate var messageLabelFrame: CGRect {
        let y: CGFloat = 15
        let x: CGFloat = 42
        return CGRect(x: x, y: y, width: NotificationLayout.width - (x+5), height: NotificationLayout.height - (2*y))
    }
    
    fileprivate var messageImageFrame: CGRect {
        let height: CGFloat = 18
        let x: CGFloat = 10
        return CGRect(x: x, y: ((NotificationLayout.height - height)/2), width: 22, height: height)
    }
    
    // MARK: - Initialization
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    public init() {
        super.init(frame: CGRect(x: 0, y: 0, width: NotificationLayout.width, height: NotificationLayout.height))
        
        startNotificationObservers()
        setupUI()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: - Override Toolbar
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        setupFrames()
    }
    
    open override var intrinsicContentSize : CGSize {
        return CGSize(width: UIViewNoIntrinsicMetric, height: NotificationLayout.height)
    }
    
    
    // MARK: - Observers
    
    fileprivate func startNotificationObservers() {
        /// Enable orientation tracking
        if !UIDevice.current.isGeneratingDeviceOrientationNotifications {
            UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        }
        
        /// Add Orientation notification
        NotificationCenter.default.addObserver(self, selector: #selector(NotificationView.orientationStatusDidChange(_:)), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        
    }
    
    
    // MARK: - Orientation Observer
    
    @objc fileprivate func orientationStatusDidChange(_ notification: Foundation.Notification) {
        setupUI()
    }
    
    
    // MARK: - Setups
    
    // TODO: - Use autolayout
    fileprivate func setupFrames() {
        
        var frame = self.frame
        frame.size.width = NotificationLayout.width
        self.frame = frame
        
        self.messageLabel.frame = self.messageLabelFrame
        self.messageImage.frame = self.messageImageFrame
        
        fixLabelMessageSize()
    }
    
    fileprivate func setupUI() {
        
        translatesAutoresizingMaskIntoConstraints = false
        
        // Bar style
        self.barTintColor = nil
        self.isTranslucent = true
        self.barStyle = UIBarStyle.default
        
        self.tintColor = UIColor(red: 5, green: 31, blue: 75, alpha: 1)
        
        self.layer.zPosition = CGFloat.greatestFiniteMagnitude - 1
        self.backgroundColor = UIColor.clear
        self.isMultipleTouchEnabled = false
        self.isExclusiveTouch = true
        
        self.frame = CGRect(x: 0, y: 0, width: NotificationLayout.width, height: NotificationLayout.height)
        self.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleTopMargin, UIViewAutoresizing.flexibleRightMargin, UIViewAutoresizing.flexibleLeftMargin]
        
        // Add subviews
        self.addSubview(self.messageImage)
        self.addSubview(self.messageLabel)
        
        
        // Gestures
        let tap = UITapGestureRecognizer(target: self, action: #selector(NotificationView.didTap(_:)))
        self.addGestureRecognizer(tap)
        let pan = UIPanGestureRecognizer(target: self, action: #selector(NotificationView.didPan(_:)))
        self.addGestureRecognizer(pan)
        
        // Setup frames
        self.setupFrames()
    }
    
    
    // MARK: - Helper
    
    fileprivate func fixLabelMessageSize() {
        let size = self.messageLabel.sizeThatFits(CGSize(width: NotificationLayout.width - self.textPointX, height: CGFloat.greatestFiniteMagnitude))
        var frame = self.messageLabel.frame
        frame.size.height = size.height > NotificationLayout.labelMessageHeight ? NotificationLayout.labelMessageHeight : size.height
        self.messageLabel.frame = frame;
    }
    
    
    // MARK: - Actions
    
    @objc fileprivate func scheduledDismiss() {
        self.hide(completion: nil)
    }
    
    
    // MARK: - Tap gestures
    
    @objc fileprivate func didTap(_ gesture: UIGestureRecognizer) {
        self.isUserInteractionEnabled = false
        self.tapAction?()
        self.hide(completion: nil)
    }
    
    @objc fileprivate func didPan(_ gesture: UIPanGestureRecognizer) {
        
        switch gesture.state {
        case .ended:
            self.isDragging = false
            if frame.origin.y < 0 || self.duration <= 0 {
                self.hide(completion: nil)
            }
            break
            
        case .began:
            self.isDragging = true
            break
            
        case .changed:
            
            guard let superview = self.superview else {
                return
            }
            
            guard let gestureView = gesture.view else {
                return
            }
            
            let translation = gesture.translation(in: superview)
            // Figure out where the user is trying to drag the view.
            let newCenter = CGPoint(x: superview.bounds.size.width / 2,
                                    y: gestureView.center.y + translation.y)
            
            // See if the new position is in bounds.
            if (newCenter.y >= (-1 * NotificationLayout.height / 2) && newCenter.y <= NotificationLayout.height / 2) {
                gestureView.center = newCenter
                gesture.setTranslation(CGPoint.zero, in: superview)
            }
            
            break
            
        default:
            break
        }
        
    }
}



public extension NotificationView {
    
    // MARK: - Public Methods
    
    public func show(message: String?, duration: TimeInterval = 3, onTap: (() -> ())?) {
        
        /// Add to window
        if let window = UIApplication.shared.delegate?.window {
//            if let mainTabBarController = window?.rootViewController as? MainTabBarController {
//                if(mainTabBarController.selectedViewController is MessagesNavigationController){
//                    return
//                }
//            }
            
            window?.windowLevel = UIWindowLevelStatusBar
            window?.addSubview(self)
        }
        
        /// Invalidate dismissTimer
        self.dismissTimer = nil
        
        self.tapAction = onTap
        self.duration = duration
        
        /// Content
        self.messageLabel.text = message
        
        
        /// Prepare frame
        var frame = self.frame
        frame.origin.y = -frame.size.height
        self.frame = frame
        
        self.setupFrames()
        
        self.isUserInteractionEnabled = true
        self.isAnimating = true
        
        /// Show animation
        UIView.animate(withDuration: 0.3, delay: 0, options: UIViewAnimationOptions.curveEaseOut, animations: {
            
            var frame = self.frame
            frame.origin.y += frame.size.height
            self.frame = frame
            
        }) { (finished) in
            self.isAnimating = false
        }
        
        // Schedule to hide
        if self.duration > 0 {
            let time = self.duration + 0.3
            self.dismissTimer = Timer.scheduledTimer(timeInterval: time, target: self, selector: #selector(NotificationView.scheduledDismiss), userInfo: nil, repeats: false)
        }
        
    }
    
    public func hide(completion: (() -> ())?) {
        
        guard !self.isDragging else {
            self.dismissTimer = nil
            return
        }
        
        if self.superview == nil {
            isAnimating = false
            return
        }
        
        // Case are in animation of the hide
        if (isAnimating) {
            return
        }
        isAnimating = true
        
        // Invalidate timer auto close
        self.dismissTimer = nil
        
        /// Show animation
        UIView.animate(withDuration: 0.3, delay: 0, options: UIViewAnimationOptions.curveEaseOut, animations: {
            
            var frame = self.frame
            frame.origin.y -= frame.size.height
            self.frame = frame
            
        }) { (finished) in
            
            self.removeFromSuperview()
            UIApplication.shared.delegate?.window??.windowLevel = UIWindowLevelNormal
            
            self.isAnimating = false
            
            completion?()
            
        }
    }
    
    
    // MARK: - Helpers
    
    public static func show(message: String?, duration: TimeInterval = 3, onTap: (() -> ())? = nil) {
        self.sharedNotification.show(message: message, duration: duration, onTap: onTap)
    }
    
    public static func hide(completion: (() -> ())? = nil) {
        self.sharedNotification.hide(completion: completion)
    }
    
}

internal let UILayoutPriorityNotificationPadding: Float = 999

internal struct NotificationLayout {
    static let height: CGFloat = 64.0
    static var width: CGFloat { return UIScreen.main.bounds.size.width }
    
    static var labelMessageHeight: CGFloat = 35
    static var dragViewHeight: CGFloat = 3
    
    static let textBorder: CGFloat = 10
}
