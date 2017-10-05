//
// Created by Bruce Jackson on 2017/10/2.
// Copyright (c) 2017 zysios. All rights reserved.
//

import UIKit

protocol LXDynamicHeaderDataSource: NSObjectProtocol {

    func numberOfPages() -> Int

    func headerView(_ header: LXDynamicHeader, reusingForIndex index: Int) -> UIView

}

@objc protocol LXDynamicHeaderDelegate: NSObjectProtocol {

    @objc optional func headerViewHeight(_ header: LXDynamicHeader, forIndex index: Int) -> CGFloat

    @objc optional func headerViewDidTapped(_ header: LXDynamicHeader, atIndex index: Int)

    @objc optional func headerViewDidScrolling(_ header: LXDynamicHeader)

}

class LXDynamicHeader: UIView {

    static let defaultFrame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)

    var contentOffset: CGPoint {
        return contentView.contentOffset
    }

    var numberOfPages: Int {
        if let i = dataSource?.numberOfPages() {
            return i
        }

        return 0
    }
    
    var currentPage: Int {
        return pageControl.currentPage
    }
    
    var currentHeight: CGFloat {
        var height = LXDynamicHeader.defaultFrame.width
        if let theHeight = delegate?.headerViewHeight?(self, forIndex: currentPage) {
            height = theHeight
        }
        
        return height
    }
    
    var pageControlHidden = false {
        didSet (hidden) {
            pageControl.isHidden = hidden
        }
    }

    weak var delegate: LXDynamicHeaderDelegate?
    weak var dataSource: LXDynamicHeaderDataSource?
    weak var scrollView: UIScrollView?

    private var contentView = UIScrollView()
    private var pageControl = UIPageControl()

    private var reusingViews = [UIView]()

    private(set) var lastStopOriginX = 0

    ///MARK: Super Class
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        clipsToBounds = true
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        clipsToBounds = true
    }

    convenience init(pages: Int, view: () -> UIView) {
        self.init(frame: .zero)
    }
    
    deinit {
        scrollView?.removeObserver(self, forKeyPath: "contentOffset")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard scrollView != nil else {
            return
        }
        
        if #available(iOS 11, *) {
            frame.origin.y = -scrollView!.adjustedContentInset.top
        }
    }

    ///MARK: Public Methods
    func addToScrollView(_ scrollView: UIScrollView) {
        let topInset = currentHeight
        scrollView.contentInset = UIEdgeInsets(top: topInset, left: 0, bottom: 0, right: 0)
        scrollView.setContentOffset(CGPoint(x: 0, y: -topInset), animated: false)
        scrollView.addSubview(self)
        
        scrollView.addObserver(self, forKeyPath: "contentOffset", options: .new, context: nil)

        frame.origin.y = -topInset
        self.scrollView = scrollView

        setupContentView()
    }

    func reusingViewForIndex(_ index: Int) -> UIView? {
        guard reusingViews.count != 0 else {
            return nil
        }

        if (reusingViews.count == 1) {
            return reusingViews[0]
        }

        return reusingViews[index % 2 == 0 ? 0 : 1]
    }

    func scrollToPage(_ page: Int, animated: Bool = false) {
        pageControl.currentPage = page
        let contentOffset = CGPoint(x: frame.width * CGFloat(page), y: 0)
        contentView.setContentOffset(contentOffset, animated: animated)
    }
    
    func reloadData() {

    }

    ///MARK: Private Methods
    private func setupContentView() {
        guard numberOfPages != 0 else {
            return
        }

        contentView.delegate = self
        contentView.isPagingEnabled = true
        contentView.bounces = false
        contentView.showsHorizontalScrollIndicator = false
        contentView.showsVerticalScrollIndicator = false
        contentView.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
        contentView.contentSize = CGSize(width: frame.width * CGFloat(numberOfPages), height: frame.height)
        addSubview(contentView)
        
        pageControl.currentPage = 0
        pageControl.numberOfPages = numberOfPages
        pageControl.isUserInteractionEnabled = false
        addSubview(pageControl)
        updatePageControlLocation()

        var currentHeight = LXDynamicHeader.defaultFrame.height
        if let height = delegate?.headerViewHeight?(self, forIndex: 0) {
            currentHeight = height
        }

        let view = dataSource!.headerView(self, reusingForIndex: 0)
        view.frame = CGRect(x: 0, y: 0, width: frame.width, height: currentHeight)
        contentView.addSubview(view)

        if numberOfPages > 1 {
            let nextView = dataSource!.headerView(self, reusingForIndex: 1)
            nextView.frame = CGRect(x: frame.width, y: 0, width: frame.width, height: currentHeight)
            contentView.addSubview(nextView)
            reusingViews.append(view)
            reusingViews.append(nextView)
        } else {
            reusingViews.append(view)
        }
    }

    private func updatePageControlLocation() {
        let width = frame.width
        let height = frame.height

        pageControl.frame.origin.x = (width - pageControl.frame.width) / 2
        pageControl.frame.origin.y = height - pageControl.frame.height - 15.0
    }

}

///MARK: UIScrollViewDelegate Methods
extension LXDynamicHeader: UIScrollViewDelegate {

    internal func scrollViewDidScroll(_ scrollView: UIScrollView) {

    }

    internal func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {

    }

    internal func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {

    }

}

///MARK: KVO
extension LXDynamicHeader {
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard object is UIScrollView else {
            return
        }
        
        if keyPath == "contentOffset" {
            print(scrollView!.contentOffset)
        }
    }
    
}
