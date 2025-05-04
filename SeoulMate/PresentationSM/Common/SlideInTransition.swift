//
//  SlideInTransition.swift
//  SeoulMate
//
//  Created by 박성근 on 5/3/25.
//

import UIKit

// SlideInTransition.swift - 수정된 버전
final class SlideInTransition: NSObject, UIViewControllerAnimatedTransitioning {
    
    let isPresenting: Bool
    let duration: TimeInterval
    
    init(isPresenting: Bool, duration: TimeInterval = 0.3) {
        self.isPresenting = isPresenting
        self.duration = duration
        super.init()
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        
        guard let fromVC = transitionContext.viewController(forKey: .from),
              let toVC = transitionContext.viewController(forKey: .to) else {
            transitionContext.completeTransition(false)
            return
        }
        
        let fromView = fromVC.view!
        let toView = toVC.view!
        
        let width = containerView.frame.width
        
        if isPresenting {
            // 새로운 뷰를 컨테이너의 오른쪽에 위치시킴
            toView.frame = containerView.bounds
            toView.frame.origin.x = width
            containerView.addSubview(toView)
            
            // 그림자 효과 추가 (선택적)
            toView.layer.shadowColor = UIColor.black.cgColor
            toView.layer.shadowOpacity = 0.2
            toView.layer.shadowOffset = CGSize(width: -3, height: 0)
            toView.layer.shadowRadius = 5
            
            // 애니메이션
            UIView.animate(withDuration: duration,
                          delay: 0,
                          options: [.curveEaseInOut],
                          animations: {
                toView.frame.origin.x = 0
                fromView.frame.origin.x = -width * 0.3
                fromView.alpha = 0.8 // 약간 어둡게
            }, completion: { finished in
                fromView.alpha = 1.0
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            })
        } else {
            // dismiss할 때 toView를 미리 추가
            containerView.insertSubview(toView, belowSubview: fromView)
            toView.frame = containerView.bounds
            toView.frame.origin.x = -width * 0.3
            toView.alpha = 0.8
            
            // 애니메이션
            UIView.animate(withDuration: duration,
                          delay: 0,
                          options: [.curveEaseInOut],
                          animations: {
                fromView.frame.origin.x = width
                toView.frame.origin.x = 0
                toView.alpha = 1.0
            }, completion: { finished in
                fromView.removeFromSuperview()
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            })
        }
    }
}

// SlideTransitioningDelegate.swift - interactive transition 추가
final class SlideTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    
    var interactionController: UIPercentDrivenInteractiveTransition?
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return SlideInTransition(isPresenting: true)
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return SlideInTransition(isPresenting: false)
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactionController
    }
}
