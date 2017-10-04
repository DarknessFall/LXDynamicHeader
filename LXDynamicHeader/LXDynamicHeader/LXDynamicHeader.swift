//
// Created by Bruce Jackson on 2017/10/2.
// Copyright (c) 2017 zysios. All rights reserved.
//

import UIKit

protocol LXDynamicHeaderDataSource: NSObjectProtocol {

    func numberOfPages() -> Int
    func headerView(_ header: LXDynamicHeader, forIndex index: Int) -> UIView

}

@objc protocol LXDynamicHeaderDelegate: NSObjectProtocol {

    @objc optional func headerViewHeight(_ header: LXDynamicHeader, forIndex index: Int) -> CGFloat
    @objc optional func headerViewDidTapped(_ header: LXDynamicHeader, atIndex index: Int)
    @objc optional func headerViewDidScrolling(_ header: LXDynamicHeader)

}

extension LXDynamicHeaderDataSource {

    func numberOfPages() -> Int {
        return 0
    }

    func headerView(_ header: LXDynamicHeader, forIndex index: Int) -> UIView {
        return UIView()
    }
}

extension LXDynamicHeaderDelegate {

    func headerViewHeight(_ header: LXDynamicHeader, forIndex index: Int) -> CGFloat {
        return UIScreen.main.bounds.width
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

    weak var delegate: LXDynamicHeaderDelegate?
    weak var dataSource: LXDynamicHeaderDataSource?
    weak var scrollView: UIScrollView?

    private var contentView = UIScrollView()
    private var pageControl = UIPageControl()

    private var reusingViews = [UIView]()

    private(set) var currentPage: Int {
        didSet (newPage) {
            pageControl.currentPage = newPage
        }
    }

    private(set) var lastStopOriginX = 0

    ///MARK: Super Class
    override init(frame: CGRect) {
        super.init(frame: frame)

        clipsToBounds = true
        currentPage = 0
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    convenience init(frame: CGRect = defaultFrame, pages: Int, view: () -> UIView) {
        self.init(frame: CGRect(x: 0, y: 0, width: frame.width, height: frame.height))
    }

    ///MARK: Public Methods
    func addToScrollView(_ scrollView: UIScrollView) {
        self.scrollView = scrollView
        self.scrollView!.contentInset = UIEdgeInsets(top: frame.height, left: 0, bottom: 0, right: 0)
        self.scrollView!.setContentOffset(CGPoint(x: 0, y: -frame.height), animated: false)
        self.scrollView!.addSubview(self)
    }

    func reuseViewForIndex(_ index: Int) -> UIView? {
        ///TODO: 获取重用视图
        return nil
    }

    func scrollToPage(_ page: Int, animated: Bool = false) {
        currentPage = page
        let contentOffset = CGPoint(x: frame.width * CGFloat(page), y: 0)
        contentView.setContentOffset(contentOffset, animated: animated)
    }

    ///MARK: Private Methods
    private func setupContentView() {
        guard numberOfPages != 0 else {
            return
        }

        pageControl.currentPage = currentPage
        pageControl.numberOfPages = numberOfPages
        pageControl.isUserInteractionEnabled = false
        addSubview(pageControl)
        updatePageControlLocation()

        contentView.delegate = self
        contentView.isPagingEnabled = true
        contentView.bounces = false
        contentView.showsHorizontalScrollIndicator = false
        contentView.showsVerticalScrollIndicator = false
        contentView.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
        contentView.contentSize = CGSize(width: frame.width * CGFloat(numberOfPages), height: frame.height)
        addSubview(contentView)

        if numberOfPages == 1 {
            let view = dataSource?.headerView(self, forIndex: 0)
            view!.frame = contentView.bounds
            contentView.addSubview(view!)
        } else if numberOfPages > 1 {
            let view = dataSource?.headerView(self, forIndex: 0)
            view!.frame = contentView.bounds
            contentView.addSubview(view!)
            reusingViews.append(view!)
            let nextView = dataSource?.headerView(self, forIndex: 1)
            nextView!.frame = contentView.bounds
            contentView.addSubview(nextView!)
            reusingViews.append(nextView!)
        }
    }

    private func updatePageControlLocation() {
        let width = frame.width
        let height = frame.height

        pageControl.frame.origin.x = (width - pageControl.frame.width) / 2
        pageControl.frame.origin.y = height - pageControl.frame.height - 15
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
