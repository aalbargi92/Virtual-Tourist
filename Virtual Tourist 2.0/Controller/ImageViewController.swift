//
//  ImageViewController.swift
//  Virtual Tourist 2.0
//
//  Created by Abdullah AlBargi on 02/11/2019.
//  Copyright © 2019 Abdullah AlBargi. All rights reserved.
//

import UIKit

class ImageViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    
    var url: URL!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        imageView.kf.setImage(with: url, placeholder: UIImage(named: "placeHolder"))
    }
}
