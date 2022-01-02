import UIKit
import SnapKit

struct ProgressViewConfig {
    let darkColor: UIColor
    let midColor: UIColor
    let lightColor: UIColor
    /** This will be used for the background stroke */
    let backgoundColor: UIColor
    let strokeWidth: CGFloat
    /** = <percentage_value> / 100 */
    let progress: CGFloat
}

class ProgressView: UIView {
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    let config: ProgressViewConfig
    
    init(config: ProgressViewConfig) {
        self.config = config
        super.init(frame: CGRect.zero)
        setupView()
    }
    
    private let backgroundView = UIView()
    private let strokeView = UIView()
    private let endPoint = UIView()
    /** CAGradientLayer that translates from DarkColor to MidColor */
    private let firstGradient = CAGradientLayer()
    /** CAGradientLayer that translates from MidColor to LightColor */
    private let secondGradient = CAGradientLayer()
    private let maskLayer = CAShapeLayer()
    
    func setupView() {
        let darkColor = config.darkColor.cgColor
        let midColor = config.midColor.cgColor
        let lightColor = config.lightColor.cgColor
        
        backgroundView.layer.borderColor = config.backgoundColor.cgColor
        backgroundView.layer.borderWidth = config.strokeWidth
        
        firstGradient.colors = [darkColor, midColor]
        secondGradient.colors = [midColor, lightColor]
        secondGradient.startPoint = CGPoint(x: 0, y: 1)
        secondGradient.endPoint = CGPoint(x: 0, y: 0)
        
        maskLayer.lineWidth = config.strokeWidth
        maskLayer.lineCap = .round
        // You could assign any color to this property, but you must set one to show the stroke
        maskLayer.strokeColor = lightColor
        maskLayer.fillColor = nil
        
        setupUI()
    }
    
    func setupUI() {
        // Use SnapKit for AutoLayout
        addSubview(backgroundView)
        backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        insertSubview(strokeView, aboveSubview: backgroundView)
        strokeView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        strokeView.layer.addSublayer(firstGradient)
        strokeView.layer.addSublayer(secondGradient)
        
        insertSubview(endPoint, aboveSubview: strokeView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let frame = self.bounds
        let width = frame.size.width
        let halfWidth = width / 2
        let strokeWidth = config.strokeWidth
        let arcRadius = halfWidth - strokeWidth / 2
        
        backgroundView.layer.cornerRadius = halfWidth
        endPoint.layer.cornerRadius = strokeWidth / 2
        
        firstGradient.frame = CGRect(x: halfWidth, y: 0, width: halfWidth, height: width)
        secondGradient.frame = CGRect(x: 0, y: 0, width: halfWidth, height: width)
        maskLayer.frame = strokeView.bounds
        
        if (config.progress < 1) {
            let bezierPath = UIBezierPath(
                arcCenter: strokeView.center,
                radius: arcRadius,
                startAngle: 1.5 * Double.pi,
                endAngle: 1.5 * Double.pi + config.progress * 2 * Double.pi,
                clockwise: true
            )
            maskLayer.path = bezierPath.cgPath
            strokeView.layer.mask = maskLayer
            
            endPoint.backgroundColor = config.darkColor
            endPoint.frame = CGRect(x: arcRadius, y: 0, width: strokeWidth, height: strokeWidth)
        } else {
            let percent = config.progress.truncatingRemainder(dividingBy: 1)
            let bezierPath = UIBezierPath(
                arcCenter: strokeView.center,
                radius: arcRadius,
                startAngle: 1.5 * Double.pi,
                endAngle: 3.5 * Double.pi,
                clockwise: true
            )
            maskLayer.path = bezierPath.cgPath
            strokeView.layer.mask = maskLayer
            
            strokeView.layer.transform = CATransform3DRotate(
                strokeView.layer.transform, percent * Double.pi, 0, 0, 1
            )
            
            endPoint.backgroundColor = config.lightColor
            let position = getEndPointPosition(forPercent: percent, radius: arcRadius)
            endPoint.frame = CGRect(x: position.x, y: position.y, width: strokeWidth, height: strokeWidth)
        }
    }
    
    /**
     Calculates and returns the position for the endpoint. Used when percent value exceeeds one.
     
     If you feel confused about the logic, perhaps you could draw a graph as a help ;)
     */
    func getEndPointPosition(forPercent percent: CGFloat, radius: CGFloat) -> CGPoint {
        let angleFromAxisY = percent * 2 * Double.pi
        let quadrant = angleFromAxisY * 2 / Double.pi
        let angleToUse = angleFromAxisY - quadrant * Double.pi / 2
        var x = 0.0, y = 0.0
        switch (quadrant) {
        case 0:
            x = radius + sin(angleToUse) * radius
            y = radius - cos(angleToUse) * radius
            break
        case 1:
            x = radius + cos(angleToUse) * radius
            y = radius + sin(angleToUse) * radius
            break
        case 2:
            x = radius - sin(angleToUse) * radius
            y = radius + cos(angleToUse) * radius
            break
        case 3:
            x = radius - cos(angleToUse) * radius
            y = radius - sin(angleToUse) * radius
            break
        default:
            break
        }
        return CGPoint(x: x, y: y)
    }
}

