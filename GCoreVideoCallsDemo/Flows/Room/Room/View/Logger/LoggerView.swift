//
//  LoggerView.swift
//  GCoreVideoCallsDemo
//
//  Created by Pavel Volobuev on 18.08.2021.
//  Copyright © 2021 G-Core Lab. All rights reserved.
//

import UIKit
import PinLayout

class LoggerView: UIView {
    private let textView: UITextView = {
        let tv = UITextView()
        tv.isEditable = false
        return tv
    }()
    private let autoscrollButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Autoscroll: On", for: .normal)
        return b
    }()
    
    private var autoscrollEnabled = true
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initUI()
    }

    required init() {
        super.init(frame: .zero)
        initUI()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initUI()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        textView.pin
            .all()
        
        autoscrollButton.pin
            .sizeToFit()
            .bottomRight(8)
    }
    
    func append(_ text: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:sss"
        let date = formatter.string(from: Date())
        textView.text.append("\(date): \(text)\n")
        
        if autoscrollEnabled {
            scrollTextViewToBottom(textView: textView)
        }
    }
}

private
extension LoggerView {
    func initUI() {
        layer.borderWidth = 1.0
        layer.borderColor = UIColor.gray.cgColor
        
        addSubview(textView)
        addSubview(autoscrollButton)
        
        autoscrollButton.addTarget(self, action: #selector(onAutoscroll), for: .touchUpInside)
        
        setNeedsLayout()
    }
    
    func scrollTextViewToBottom(textView: UITextView) {
        if textView.text.count > 0 {
            let location = textView.text.count - 1
            let bottom = NSMakeRange(location, 1)
            textView.scrollRangeToVisible(bottom)
        }
    }
    
    @objc func onAutoscroll() {
        autoscrollEnabled = !autoscrollEnabled
        
        autoscrollButton.setTitle(
            "Autoscroll: \(autoscrollEnabled ? "On" : "Off")",
            for: .normal
        )
        
        if autoscrollEnabled {
            scrollTextViewToBottom(textView: textView)
        }
        
        setNeedsLayout()
    }
}
