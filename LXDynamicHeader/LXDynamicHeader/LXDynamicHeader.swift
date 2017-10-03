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
        contentView.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
        contentView.contentSize = CGSize(width: frame.width * CGFloat(numberOfPages), height: frame.height)
        addSubview(contentView)
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

    func scrollViewDidScroll(_ scrollView: UIScrollView) {

    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {

    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {

    }

}
