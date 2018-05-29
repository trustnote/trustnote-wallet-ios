//
//  TNMyPairingCodeView.swift
//  TrustNote
//
//  Created by zenghailong on 2018/5/27.
//  Copyright © 2018年 org.trustnote. All rights reserved.
//

import UIKit

class TNMyPairingCodeView: UIView, TNNibLoadable {
   
    var dimissBlock: ClickedDismissButtonBlock?
    
    var pairingCode: String = ""
    
    @IBOutlet weak var copyBtn: UIButton!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var pubkeyLabel: UILabel!
    @IBOutlet weak var descLabel: UILabel!
    @IBOutlet weak var titlelabel: UILabel!
    @IBOutlet weak var codeImageView: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        titlelabel.text = NSLocalizedString("My pairing code", comment: "")
        descLabel.text = NSLocalizedString("PairngCode.desc", comment: "")
        copyBtn.setTitle(NSLocalizedString("Copy paire code", comment: ""), for: .normal)
        setupRadiusCorner(radius: kCornerRadius * 2)
        copyBtn.setupRadiusCorner(radius: kCornerRadius)
        containerView.layer.borderColor = UIColor.hexColor(rgbValue: 0xF2F2F2).cgColor
        containerView.layer.borderWidth = 4.0
        pubkeyLabel.text = TNGlobalHelper.shared.ecdsaPubkey
    }
    
}

extension TNMyPairingCodeView {
    
    @IBAction func dismiss(_ sender: Any) {
        dimissBlock?()
    }
    
    @IBAction func copyCode(_ sender: Any) {
        guard !pairingCode.isEmpty else {
            return
        }
        UIPasteboard.general.string = pairingCode
        let customView = UIImageView(image: UIImage(named: "profile_success"))
        MBProgress_TNExtension.showAlertMessage(alertMessage: NSLocalizedString("Copy success", comment: ""), customView: customView)
    }
}

extension TNMyPairingCodeView {
    
    public func generateQRcode(completionHandle: @escaping () -> Swift.Void) {
        TNEvaluateScriptManager.sharedInstance.generateRandomBytes(num: 9) {[unowned self] (randomBytes) in
            let config = TNConfigFileManager.sharedInstance.readConfigFile()
            let hub = config["hub"] as! String
            let inputMsg = TNGlobalHelper.shared.ecdsaPubkey + "@" + hub + "#" + randomBytes
            self.pairingCode = inputMsg
            self.codeImageView.image = UIImage.createHDQRImage(input: inputMsg, imgSize: self.codeImageView.size)
            completionHandle()
        }
    }
}