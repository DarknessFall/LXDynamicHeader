//
// Created by Bruce Jackson on 2017/10/2.
// Copyright (c) 2017 zysios. All rights reserved.
//

import UIKit

protocol LXDynamicHeaderDataSource: NSObjectProtocol {

    func numberOfPages() -> Int

    func headerView(_ header: LXDynamicHeader, reusingForIndex index: Int) -> UIView

}

protocol LXDynamicHeaderDelegate: NSObjectProtocol {

    func headerViewHeight(_ header: LXDynamicHeader, forIndex index: Int) -> CGFloat

    func headerViewDidTapped(_ header: LXDynamicHeader, atIndex index: Int)

    func headerViewDidScrolling(_ header: LXDynamicHeader)

}

extension LXDynamicHeaderDelegate {

    func headerViewHeight(_ header: LXDynamicHeader, forIndex index: Int) -> CGFloat {
        return LXDynamicHeader.defaultFrame.height
    }

    func headerViewDidTapped(_ header: LXDynamicHeader, atIndex index: Int) {
        print("\(index) page is tapped")
    }

    func headerViewDidScrolling(_ header: LXDynamicHeader) {

    }

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
    
    var currentHeight: CGFloat {
        var height = LXDynamicHeader.defaultFrame.width
        if let theHeight = delegate?.headerViewHeight(self, forIndex: currentPage) {
            height = theHeight
        }

        return height
    }
    
    var pageControlHidden: Bool {
        set {
            pageControl.isHidden = newValue
        }
        
        get {
            return pageControl.isHidden
        }
    }
    
    var autoZoom = true

    weak var delegate: LXDynamicHeaderDelegate?
    weak var dataSource: LXDynamicHeaderDataSource?
    weak var scrollView: UIScrollView?
    
    private(set) var currentPage = 0

    private var contentView = UIScrollView()
    private var pageControl = UIPageControl()

    private var reusingViews = [UIView]()
    
    private var lastTouchedContentOffsetX: CGFloat = 0.0
    private var lastContentOffsetX: CGFloat = 0.0

    private var tempPage = 0 {
        didSet(newValue) {
            pageControl.currentPage = newValue
        }
    }

    ///MARK: Super Class
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        clipsToBounds = true
        addSubview(contentView)
        addSubview(pageControl)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        clipsToBounds = true
    }

    convenience init(pages: Int, view: () -> UIView) {
        self.init(frame: .zero)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard scrollView != nil else {
            return
        }
        
        if #available(iOS 11, *) {
            if scrollView!.adjustedContentInset.top != 0 {
                frame.origin.y = -scrollView!.adjustedContentInset.top
            }
        } else {
            frame.origin.y = -scrollView!.contentInset.top
        }
    }
    
    deinit {
        scrollView?.removeObserver(self, forKeyPath: "contentOffset")
    }

    ///MARK: Public Methods
    func addToScrollView(_ scrollView: UIScrollView) {
        guard self.scrollView == nil else {
            return
        }
        
        scrollView.addSubview(self)
        scrollView.addObserver(self, forKeyPath: "contentOffset", options: .new, context: nil)
        contentView.frame.size.height = currentHeight
        self.scrollView = scrollView
        
        updateSuperScrollViewContentInsetWithDynamicHeight(currentHeight)
        setupContentView()
    }

    func reusingViewForIndex(_ index: Int) -> UIView? {
        guard reusingViews.count != 0 else {
            return nil
        }

        if (reusingViews.count < 3) {
            return reusingViews[index]
        }

        return reusingViews[index % 3]
    }

    func scrollToPage(_ page: Int, animated: Bool = false) {
        currentPage = page
        let contentOffset = CGPoint(x: frame.width * CGFloat(page), y: 0)
        contentView.setContentOffset(contentOffset, animated: animated)
    }
    
    func reloadData() {
        guard scrollView != nil else {
            return
        }
        
        for subView in scrollView!.subviews {
            subView.removeFromSuperview()
        }
        
        setupContentView()
    }

}

///MARK: UIScrollViewDelegate Methods
extension LXDynamicHeader: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateReusingViewLocationWhenScrolling(contentOffsetX: scrollView.contentOffset.x)
        updateHeightWhenScrolling(contentOffsetX: scrollView.contentOffset.x)
        
        delegate?.headerViewDidScrolling(self)
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        scrollView.setContentOffset(scrollView.contentOffset, animated: false)
        lastContentOffsetX = scrollView.contentOffset.x
        currentPage = calculateTouchedPage()
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        lastContentOffsetX = scrollView.contentOffset.x
        lastTouchedContentOffsetX = scrollView.contentOffset.x
        currentPage = Int(lastContentOffsetX / frame.width)
        
        print(self.scrollView!.contentInset)
        print(self.scrollView!.adjustedContentInset)
    }

}

///MARK: KVO
extension LXDynamicHeader {

    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        guard object is UIScrollView else {
            return
        }

        //let scrollView = self.scrollView!

        if keyPath == UIScrollView.contentOffsetKey {
            //print(scrollView.contentOffset)
        }
    }

}

///MARK: Private Methods
private extension LXDynamicHeader {

    func setupContentView() {
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
        contentView.setContentOffset(CGPoint(x: lastContentOffsetX, y: 0), animated: false)

        pageControl.currentPage = currentPage
        pageControl.numberOfPages = numberOfPages
        pageControl.isUserInteractionEnabled = false

        var views = [UIView]()
        for i in 0..<(numberOfPages >= 3 ? 3 : numberOfPages) {
            let view = dataSource!.headerView(self, reusingForIndex: i)
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(viewDidTapped(_:)))
            view.addGestureRecognizer(tapGestureRecognizer)
            view.frame = CGRect(x: frame.width * CGFloat(i), y: 0, width: frame.width, height: currentHeight)
            contentView.addSubview(view)
            views.append(view)
        }
        reusingViews = views

        updatePageControlLocationWithDynamicHeight(currentHeight)
    }
    
    func calculateTouchedPage() -> Int {
        let numberHandler = NSDecimalNumberHandler(roundingMode: .bankers,
                                                   scale: 0,
                                                   raiseOnExactness: false,
                                                   raiseOnOverflow: false,
                                                   raiseOnUnderflow: false,
                                                   raiseOnDivideByZero: false)
        let number = NSDecimalNumber(string: String(describing: lastTouchedContentOffsetX / frame.width))
        
        return number.rounding(accordingToBehavior: numberHandler).intValue
    }
    
    func updateSuperScrollViewContentInsetWithDynamicHeight(_ dynamicHeight: CGFloat) {
        guard scrollView != nil else {
            return
        }
        
        let topInset = dynamicHeight
        frame.origin.y = -topInset
        
        if #available(iOS 11, *) {
            if scrollView!.adjustedContentInset.top != 0 {
                scrollView!.contentInset = UIEdgeInsets(top: topInset - 44.0, left: 0, bottom: 0, right: 0)
            }
        } else {
            scrollView!.contentInset = UIEdgeInsets(top: topInset, left: 0, bottom: 0, right: 0)
        }
        
        scrollView!.setContentOffset(CGPoint(x: 0, y: -topInset), animated: false)
    }

    func updatePageControlLocationWithDynamicHeight(_ dynamicHeight: CGFloat) {
        pageControl.frame.origin.x = (frame.width - pageControl.frame.width) / 2
        pageControl.frame.origin.y = dynamicHeight - pageControl.frame.height - 15.0
    }

    func updateReusingViewLocationWhenScrolling(contentOffsetX: CGFloat) {
        let right = contentOffsetX < lastContentOffsetX
        let previousPage = tempPage
        lastTouchedContentOffsetX = contentOffsetX
        tempPage = calculateTouchedPage()
        let shouldCheck = previousPage != tempPage
        
        guard numberOfPages > 3 && shouldCheck else {
            return
        }
        
        if !right && tempPage != numberOfPages - 1 {
            let view = dataSource!.headerView(self, reusingForIndex: tempPage + 1)
            view.frame.origin.x = frame.width * CGFloat(tempPage + 1)
        } else if right && tempPage != 0 {
            let view = dataSource!.headerView(self, reusingForIndex: tempPage - 1)
            view.frame.origin.x = frame.width * CGFloat(tempPage - 1)
        }
    }
    
    func updateHeightWhenScrolling(contentOffsetX: CGFloat) {
        guard delegate != nil else {
            return
        }

        let right = contentOffsetX < lastContentOffsetX

        if !right && currentPage == numberOfPages - 1 {
            return
        }

        if right && currentPage == 0 {
            return
        }

        let nextPage = currentPage + (right ? -1 : 1)
        let newHeight = delegate!.headerViewHeight(self, forIndex: nextPage)

        let rate = fabs(contentOffsetX - lastContentOffsetX) / frame.width
        print(rate)
        let dynamicHeight = currentHeight + (newHeight - currentHeight) * rate
        let currentView = reusingViewForIndex(currentPage)
        let nextView = reusingViewForIndex(nextPage)
        currentView?.frame.size.height = dynamicHeight
        nextView?.frame.size.height = dynamicHeight
        contentView.frame.size.height = dynamicHeight
        frame.size.height = dynamicHeight

        updatePageControlLocationWithDynamicHeight(dynamicHeight)
        updateSuperScrollViewContentInsetWithDynamicHeight(dynamicHeight)
        
        print(frame)
        print(scrollView!.adjustedContentInset)
    }

    @objc func viewDidTapped(_ sender: UIGestureRecognizer) {
        let currentView = sender.view!
        let tappedPage = Int(currentView.frame.origin.x / frame.width)

        delegate?.headerViewDidTapped(self, atIndex: tappedPage)
    }

}

///MARK: UIScrollView KVO Keys
private extension UIScrollView {

    static let contentOffsetKey = "contentOffset"
    static let contentInsetKey = "contentInsetKey"

}
