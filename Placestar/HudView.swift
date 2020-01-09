//
//  HudView.swift
//  Placestar
//
//  Created by Felix Lösing on 03.07.15.
//  Copyright (c) 2020 Felix Lösing. All rights reserved.
//

import UIKit

class HudView: UIView {

    var text = ""
    
    //convenience construct
    class func hudInView(_ view: UIView, animated: Bool) -> HudView {
        let hudView = HudView(frame: view.bounds)
        
        view.addSubview(hudView)
        view.isUserInteractionEnabled = false
        
        hudView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0)
        
        hudView.showAnimated(animated)
        
        return hudView
    }
    
    override func draw(_ rect: CGRect) {
        
        //create black, transparent box
        let boxWidth: CGFloat = 96
        let boxHeight: CGFloat = 96
        
        let boxRect = CGRect(x: round((bounds.size.width - boxWidth) / 2), y: round((bounds.size.height - boxHeight) / 2), width: boxWidth, height: boxHeight)
        
        let roundedRect = UIBezierPath(roundedRect: boxRect, cornerRadius: 12)
        UIColor(white: 0.3, alpha: 0.8).setFill()
        roundedRect.fill()
        
        //draw checkmark icon
        if let image = UIImage(named: "Checkmark") {
            let imagePoint = CGPoint(x: center.x - round(image.size.width / 2), y: center.y - round(image.size.height / 2) - boxHeight / 8)
            
            image.draw(at: imagePoint)
        }
        
        //draw text
        let attribs = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16), NSAttributedString.Key.foregroundColor: UIColor.white]
        
        //calc size of String
        let textSize = text.size(withAttributes: attribs)
        
        //position text
        let textPoint = CGPoint(x: center.x - round(textSize.width / 2), y: center.y - round(textSize.height / 2) + boxHeight / 4)
        text.draw(at: textPoint, withAttributes: attribs)
        
    }
    
    func showAnimated(_ animated: Bool) {
        if animated {
            alpha = 0
            transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
            
            //spring animation
            UIView.animate(withDuration: 0.8, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.6, options: UIView.AnimationOptions(rawValue: 0), animations: { () -> Void in
                self.alpha = 1
                self.transform = CGAffineTransform.identity
            }, completion: nil)
        }
    }
}
