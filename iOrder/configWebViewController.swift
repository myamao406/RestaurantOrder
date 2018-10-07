//
//  configWebViewController.swift
//  iOrder2
//
//  Created by 山尾 守 on 2017/03/10.
//  Copyright © 2017年 山尾守. All rights reserved.
//

import UIKit
import FontAwesomeKit

class configWebViewController: UIViewController, UIWebViewDelegate{

    @IBOutlet weak var licenseWebView: UIWebView!
    
    @IBOutlet weak var closeButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()

        let iconImage = FAKFontAwesome.timesCircleOIcon(withSize: iconSize)
        iconImage?.addAttribute(NSForegroundColorAttributeName, value: UIColor.white)
        let Image = iconImage?.image(with: CGSize(width: iconSize, height: iconSize))
        closeButton.setImage(Image, for: UIControlState())

        
        licenseWebView.delegate = self
        licenseWebView.backgroundColor = UIColor.black
        
        loadRequest()        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func loadRequest() {
        let fileName: String = "license"
        let filePath: String = Bundle.main.path(forResource: fileName, ofType: "html")!
        let url = URL(string: filePath)!
        let urlRequest = URLRequest(url: url)
        licenseWebView.loadRequest(urlRequest)
    }

}
