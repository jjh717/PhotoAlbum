//
//  UIView.swift
//  JDM
//
//  Created by Jang Dong Min on 2020/06/03.
//  Copyright © 2020 Infovine. All rights reserved.
//

import UIKit

@IBDesignable class CustomView: UIButton
{
    var circle = false

    @IBInspectable var circleV: Bool {
        get {
            return false
        }
        set {
            circle = newValue
            if newValue {
                let width = min(bounds.width, bounds.height)
                let path = UIBezierPath(arcCenter: CGPoint(x: bounds.midX, y: bounds.midY), radius: width / 2, startAngle: 0, endAngle: .pi * 2, clockwise: true)

                let mask = CAShapeLayer()
                mask.path = path.cgPath
                layer.mask = mask
                layer.masksToBounds = true
            } else {

            }

        }
    }
    
    @IBInspectable var cornerRadiusV: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            if !circle {
                layer.cornerRadius = newValue
                layer.masksToBounds = newValue > 0
            }
        }
    }

    @IBInspectable var borderWidthV: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }

    @IBInspectable var borderColorV: UIColor? {
        get {
            return UIColor(cgColor: layer.borderColor!)
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }
}

@IBDesignable class CustomImageView: UIImageView
{
    var circle = false

    @IBInspectable var circleV: Bool {
        get {
            return false
        }
        set {
            circle = newValue
            if newValue {
                let width = min(bounds.width, bounds.height)
                let path = UIBezierPath(arcCenter: CGPoint(x: bounds.midX, y: bounds.midY), radius: width / 2, startAngle: 0, endAngle: .pi * 2, clockwise: true)

                let mask = CAShapeLayer()
                mask.path = path.cgPath
                layer.mask = mask
                layer.masksToBounds = true
            } else {

            }

        }
    }
    
    @IBInspectable var cornerRadiusV: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            if !circle {
                layer.cornerRadius = newValue
                layer.masksToBounds = newValue > 0
            }
        }
    }

    @IBInspectable var borderWidthV: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }

    @IBInspectable var borderColorV: UIColor? {
        get {
            return UIColor(cgColor: layer.borderColor!)
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }
}
 

extension UIColor {
   convenience init(red: Int, green: Int, blue: Int) {
       assert(red >= 0 && red <= 255, "Invalid red component")
       assert(green >= 0 && green <= 255, "Invalid green component")
       assert(blue >= 0 && blue <= 255, "Invalid blue component")

       self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
   }

   convenience init(rgb: Int) {
       self.init(
           red: (rgb >> 16) & 0xFF,
           green: (rgb >> 8) & 0xFF,
           blue: rgb & 0xFF
       )
   }
}

extension String {
    var localized: String {
        return NSLocalizedString(self, tableName: "Localizable", value: self, comment: "")
    }
    
    func isValidEmail() -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"

        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: self)
    }
    
    func lengthCheck(min: Int, max: Int) -> Bool {
        if self.count >= min && self.count <= max {
            return true
        }
        return false
    }
    
    func passwordCheck() -> (Bool, Bool, Bool) {
        var range = self.range(of: "^[a-zA-Z]*$", options:.regularExpression)
        if range != nil {
            return (true, false, false)
        }
 
        range = self.range(of: "^[0-9]*$", options:.regularExpression)
        if range != nil {
            return (false, true, false)
        }

        range = self.range(of: "^[ `~!@#$%^&*()\\-_=+\\[{\\]}\\\\|;:'\",<.>/?//s]*$", options:.regularExpression)
        if range != nil {
            return (false, false, true)
        }

        range = self.range(of: "^[가-힣]*$", options:.regularExpression)
        if range != nil {
            return (false, false, false)
        }

        range = self.range(of: "^[a-zA-Z0-9]*$", options:.regularExpression)
        if range != nil {
            return (true, true, false)
       }
 
        range = self.range(of: "^[a-zA-Z `~!@#$%^&*()\\-_=+\\[{\\]}\\\\|;:'\",<.>/?//s]*$", options:.regularExpression)
        if range != nil {
            return (true, false, true)
        }

        range = self.range(of: "^[0-9 `~!@#$%^&*()\\-_=+\\[{\\]}\\\\|;:'\",<.>/?//s]*$", options:.regularExpression)
        if range != nil {
            return (false, true, true)
        }
 
        range = self.range(of: "^[a-zA-Z0-9 `~!@#$%^&*()\\-_=+\\[{\\]}\\\\|;:'\",<.>/?//s]*$", options:.regularExpression)
        if range != nil {

            return (true, true, true)

        }

        return (false, false, false)
    }
     
    
    func getYoutubeThumbnailString() -> String {
        return "https://img.youtube.com/vi/\(self)/mqdefault.jpg"
    }     
}

extension UIButton {
    func setGradientColor()  {
         var gradientLayer : CAGradientLayer!
           gradientLayer = CAGradientLayer()
           gradientLayer.frame = self.bounds
           gradientLayer.colors = [UIColor(red: 250.0 / 255.0 , green: 87.0 / 255.0 , blue: 119.0 / 255.0, alpha: 1.0).cgColor,
                                   UIColor(red: 255.0 / 255.0 , green: 41.0 / 255.0 , blue: 100.0 / 255.0, alpha: 1.0).cgColor,
                                   UIColor(red: 255.0 / 255.0 , green: 2.0 / 255.0 , blue: 120.0 / 255.0, alpha: 1.0).cgColor]
           self.layer.insertSublayer(gradientLayer, at: 0)
    }
}
 
