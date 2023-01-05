//
//  MKRateMaskView.swift
//  MKPlayer
//
//  Created by Zhibin on 2021/11/8.
//

import UIKit

internal class BMRateMaskView: UIView {
    
    fileprivate var changed: ((Float) -> Void)?
    
    private let rates:[Float] = [1.0, 1.25, 1.5, 2.0];
    
    private var buttons = [UIButton]()
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isUserInteractionEnabled = true
        self.clipsToBounds = true
        self.backgroundColor = .black.withAlphaComponent(0.4)
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismiss)))
        
        for rate in rates {
            let b = UIButton(type: .custom)
            b.titleLabel?.font = .systemFont(ofSize: 16)
            b.setTitleColor(.white, for: .normal)
            b.setTitleColor(UIColor(hex: 0x00bbdd), for: .selected)
            b.setTitle(BMRateMaskView.rateTitle(Float(rate)), for: .normal)
            b.addTarget(self, action: #selector(buttonsClick), for: .touchUpInside)
            addSubview(b)
            buttons.append(b)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if (self.bounds.width < self.bounds.height) {
            let w = self.bounds.width / CGFloat(buttons.count);
            var safeMargin: CGFloat = 0
            if #available(iOS 11.0, *) {
                safeMargin = self.safeAreaInsets.bottom
            }
            for i in 0..<buttons.count {
                buttons[i].frame = CGRect(x: w * CGFloat(i),
                                          y: self.bounds.height - 50 - 40 - safeMargin,
                                          width: w,
                                          height: 40)
            }
        } else {
            let h = CGFloat(buttons.count * 30) + CGFloat((buttons.count - 1) * 24)
            let top = (self.bounds.height - h) / 2;
            var safeMargin: CGFloat = 0
            if #available(iOS 11.0, *) {
                safeMargin = self.safeAreaInsets.right
            }
            
            for i in 0..<buttons.count {
                let idx = buttons.count - 1 - i;
                buttons[idx].frame = CGRect(x: self.bounds.width - 40 - 45 - safeMargin,
                                            y: top + CGFloat(i * (30 + 24)),
                                            width: 45,
                                            height: 30)
            }
        }
    }
    
    func update(_ rate: Float) {
        var j: Int = -1;
        var min: Float = 0.5;
        for i in 0..<rates.count {
            let a = fabsf(rates[i] - rate);
            if (a < min) {
                min = a;
                j = i;
            }
        }
        let _b = j >= 0 && j < buttons.count ? buttons[j] : nil;
        for b in buttons {
            b.isSelected = b == _b;
        }
    }
    
    @objc func buttonsClick(_ sender: UIButton) {
        guard let idx = buttons.firstIndex(of: sender) else { return }
        changed?(rates[idx])
        dismiss()
    }
    
    @objc func dismiss() {
        self.isHidden = true
        
        self.removeFromSuperview()
    }
    
    static func present(_ rate: Float, changed: @escaping (Float) -> Void) {
        guard let window = UIApplication.shared.delegate?.window else {
            return
        }
        let mask = BMRateMaskView()
        mask.changed = changed
        mask.update(rate)
        mask.isHidden = true
        
        window!.addSubview(mask)
        mask.snp.makeConstraints { make in
            make.edges.equalTo(window!)
        }
        mask.setNeedsLayout()
        mask.layoutIfNeeded()
        mask.isHidden = false
    }
    
    static func rateTitle(_ rate: Float) -> String {
        let f = NumberFormatter()
        f.minimumIntegerDigits = 1;
        f.minimumFractionDigits = 1;
        f.maximumFractionDigits = 2;
        guard let str = f.string(from: NSNumber(value: rate)) else { return "" }
        return "\(str)X"
    }
}
