//
//  BMTimeSlider.swift
//  Pods
//
//  Created by BrikerMan on 2017/4/2.
//
//

import UIKit

public class BMTimeSlider: UISlider {
    override open func trackRect(forBounds bounds: CGRect) -> CGRect {
        let trackHeight: CGFloat = 2
        let position = CGPoint(x: 0, y: 14)
        let customBounds = CGRect(origin: position, size: CGSize(width: bounds.size.width, height: trackHeight))
        super.trackRect(forBounds: customBounds)
        return customBounds
    }
    
    override open func thumbRect(forBounds bounds: CGRect, trackRect rect: CGRect, value: Float) -> CGRect {
        let rect = super.thumbRect(forBounds: bounds, trackRect: rect, value: value)
        let newRect: CGRect
        if #available(iOS 26.0, *) {
            newRect = CGRect(x: rect.origin.x, y: rect.origin.y, width: 30, height: 30)
        } else {
            let newx = rect.origin.x - 10
            newRect = CGRect(x: newx, y: 0, width: 30, height: 30)
        }
        return newRect
    }
}
