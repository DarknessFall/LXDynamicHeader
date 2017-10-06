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

    var currentPage: Int {
        set {
            pageControl.currentPage = newValue
        }
        
        get {
            return pageControl.currentPage
        }
    }
    
    var pageControlHidden: Bool {
        set {
            pageControl.isHidden = newValue
        }
        
        get {
            return pageControl.isHidden
        }
    }

    weak var delegate: LXDynamicHeaderDelegate?
    weak var dataSource: LXDynamicHeaderDataSource?
    weak var scrollView: UIScrollView?

    private var contentView = UIScrollView()
    private var pageControl = UIPageControl()

    private var reusingViews = [UIView]()

    private(set) var lastContentOffsetX: CGFloat = 0.0

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

    }

}

///MARK: UIScrollViewDelegate Methods
extension LXDynamicHeader: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateReusingViewLocationWhenScrolling(contentOffsetX: scrollView.contentOffset.x)
        
        delegate?.headerViewDidScrolling(self)
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        
    }
    
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        lastContentOffsetX = scrollView.contentOffset.x
        currentPage = Int(lastContentOffsetX / frame.width)
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

        let scrollView = self.scrollView!

        if keyPath == UIScrollView.contentOffsetKey {
            print(scrollView.contentOffset)
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
        addSubview(contentView)

        pageControl.currentPage = 0
        pageControl.numberOfPages = numberOfPages
        pageControl.isUserInteractionEnabled = false
        addSubview(pageControl)

        var currentHeight = LXDynamicHeader.defaultFrame.height
        if let height = delegate?.headerViewHeight(self, forIndex: 0) {
            currentHeight = height
        }

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

    func updatePageControlLocationWithDynamicHeight(_ dynamicHeight: CGFloat) {
        let width = frame.width

        pageControl.frame.origin.x = (width - pageControl.frame.width) / 2
        pageControl.frame.origin.y = dynamicHeight - pageControl.frame.height - 15.0
    }

    func calculateTouchedPage() -> Int {
        let numberHandler = NSDecimalNumberHandler(roundingMode: .bankers,
                                                   scale: 0,
                                                   raiseOnExactness: false,
                                                   raiseOnOverflow: false,
                                                   raiseOnUnderflow: false,
                                                   raiseOnDivideByZero: false)
        let number = NSDecimalNumber(string: String(describing: lastContentOffsetX / frame.width))

        return number.rounding(accordingToBehavior: numberHandler).intValue
    }

    func updateReusingViewLocationWhenScrolling(contentOffsetX: CGFloat) {
        let right = contentOffsetX > lastContentOffsetX
        let lastPage = currentPage
        lastContentOffsetX = contentOffsetX
        currentPage = calculateTouchedPage()
        let shouldCheck = lastPage != currentPage
        if numberOfPages > 3 && shouldCheck {
            if right && currentPage != numberOfPages - 1 {
                let view = dataSource!.headerView(self, reusingForIndex: currentPage + 1)
                view.frame.origin.x = frame.width * CGFloat(currentPage + 1)
            } else if !right && currentPage != 0 {
                let view = dataSource!.headerView(self, reusingForIndex: currentPage - 1)
                view.frame.origin.x = frame.width * CGFloat(currentPage - 1)
            }
        }
    }

    @objc func viewDidTapped(_ sender: UIGestureRecognizer) {
        let currentView = sender.view!
        let tappedPage = Int(currentView.frame.origin.x / frame.width)

        delegate?.headerViewDidTapped(self, atIndex: tappedPage)
    }

}

//MARK: UIScrollView KVO Keys
private extension UIScrollView {

    static let contentOffsetKey = "contentOffset"
    static let contentInsetKey = "contentInsetKey"

}
