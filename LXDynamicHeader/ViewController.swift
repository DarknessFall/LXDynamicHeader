//
//  ViewController.swift
//  LXDynamicHeader
//
//  Created by Bruce Jackson on 2017/9/23.
//  Copyright © 2017年 zysios. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet var scrollView: UIScrollView!
    var header: LXDynamicHeader!
    let colors: [UIColor] = [.red, .purple]

    override func viewDidLoad() {
        super.viewDidLoad()

        scrollView.contentSize = CGSize(width: UIScreen.main.bounds.width, height: 1000)
        
        header = LXDynamicHeader(frame: LXDynamicHeader.defaultFrame)
        header.dataSource = self
        header.delegate = self
        header.addToScrollView(scrollView)
    }
    
}

extension ViewController: LXDynamicHeaderDataSource {
    
    func numberOfPages() -> Int {
        return colors.count
    }
    
    func headerView(_ header: LXDynamicHeader, reusingForIndex index: Int) -> UIView {
        if let reusingView = header.reusingViewForIndex(index) {
            reusingView.backgroundColor = colors[index]

            return reusingView
        }
        
        let view = UIView()
        view.backgroundColor = colors[index]
        
        return view
    }
    
}

extension ViewController: LXDynamicHeaderDelegate {

}

