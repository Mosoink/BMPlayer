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
        let position = CGPoint(x: 2, y: (bounds.size.height - trackHeight) / 2)
        let customBounds = CGRect(origin: position, size: CGSize(width: bounds.size.width, height: trackHeight))
        super.trackRect(forBounds: customBounds)
        return customBounds
    }
    
    override open func thumbRect(forBounds bounds: CGRect, trackRect rect: CGRect, value: Float) -> CGRect {
        let rect = super.thumbRect(forBounds: bounds, trackRect: rect, value: value)
        let newx = rect.origin.x + CGFloat((value - 1.0) * 5.0)
        let newRect = CGRect(x: newx, y: 0, width: 30, height: 30)
        return newRect
    }
}
