//
//  MKRateButton.swift
//  MKPlayer
//
//  Created by Zhibin on 2021/11/8.
//

import UIKit

internal class BMRateButton: UIView {
    
    let titleLabel = UILabel()
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isUserInteractionEnabled = true
        titleLabel.font = .systemFont(ofSize: 14)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .right
        
        addSubview(titleLabel)
    }
    
    func updateUI(rate: Float) {
        titleLabel.text = rate == 1 ? "倍速" : BMRateMaskView.rateTitle(rate)
        setNeedsLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        titleLabel.sizeToFit()
        titleLabel.frame = CGRect(x: self.bounds.width - titleLabel.frame.width,
                                  y: (self.bounds.height - titleLabel.frame.height) / 2,
                                  width: titleLabel.frame.width,
                                  height: titleLabel.frame.height)
    }
}
