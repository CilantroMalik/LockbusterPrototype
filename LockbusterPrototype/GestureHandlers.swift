//
//  GestureHandlers.swift
//  LockbusterPrototype
//
//  Created by Rohan Malik on 2/19/21.
//

import Foundation
import SwiftUI

struct TappableView: UIViewRepresentable {
    var touches: Int
    var tappedCallback: ((CGPoint, Int) -> Void)
    
    func makeUIView(context: UIViewRepresentableContext<TappableView>) -> UIView {
        let v = UIView(frame: .zero)
        let gesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.tapped))
        gesture.numberOfTapsRequired = 1
        gesture.numberOfTouchesRequired = touches
        v.addGestureRecognizer(gesture)
        return v
    }
    
    class Coordinator: NSObject {
        var tappedCallback: ((CGPoint, Int) -> Void)
        init(tappedCallback: @escaping ((CGPoint, Int) -> Void)) {
            self.tappedCallback = tappedCallback
        }
        @objc func tapped(gesture:UITapGestureRecognizer) {
            let point = gesture.location(in: gesture.view)
            self.tappedCallback(point, 1)
        }
    }
    
    func makeCoordinator() -> TappableView.Coordinator {
        return Coordinator(tappedCallback:self.tappedCallback)
    }
    
    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<TappableView>) { }
    
}

struct DraggableView: UIViewRepresentable {
    var direction: UISwipeGestureRecognizer.Direction
    var touches: Int
    var draggedCallback: ((CGPoint, Int) -> Void)
    
    func makeUIView(context: UIViewRepresentableContext<DraggableView>) -> UIView {
        let v = UIView(frame: .zero)
        let gesture = UISwipeGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.dragged))
        gesture.direction = direction
        gesture.numberOfTouchesRequired = touches
        v.addGestureRecognizer(gesture)
        return v
    }
    
    class Coordinator: NSObject {
        var draggedCallback: ((CGPoint, Int) -> Void)
        init(draggedCallback: @escaping ((CGPoint, Int) -> Void)) {
            self.draggedCallback = draggedCallback
        }
        @objc func dragged(gesture: UISwipeGestureRecognizer) {
            let point = gesture.location(in: gesture.view)
            self.draggedCallback(point, 1)
        }
    }
    
    func makeCoordinator() -> DraggableView.Coordinator {
        return Coordinator(draggedCallback:self.draggedCallback)
    }
    
    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<DraggableView>) { }
}

struct LongPressableView: UIViewRepresentable {
    var touches: Int
    var pressedCallback: ((CGPoint, Int) -> Void)
    
    func makeUIView(context: UIViewRepresentableContext<LongPressableView>) -> UIView {
        let v = UIView(frame: .zero)
        let gesture = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.pressed))
        gesture.minimumPressDuration = 0.4
        gesture.numberOfTouchesRequired = touches
        v.addGestureRecognizer(gesture)
        return v
    }
    
    class Coordinator: NSObject {
        var pressedCallback: ((CGPoint, Int) -> Void)
        init(pressedCallback: @escaping ((CGPoint, Int) -> Void)) {
            self.pressedCallback = pressedCallback
        }
        @objc func pressed(gesture: UILongPressGestureRecognizer) {
            let point = gesture.location(in: gesture.view)
            self.pressedCallback(point, 1)
        }
    }
    
    func makeCoordinator() -> LongPressableView.Coordinator {
        return Coordinator(pressedCallback: self.pressedCallback)
    }
    
    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<LongPressableView>) { }
}

struct PannableView: UIViewRepresentable {
    var edge: UIRectEdge
    var pannedCallback: ((CGPoint, Int) -> Void)
    
    func makeUIView(context: UIViewRepresentableContext<PannableView>) -> UIView {
        let v = UIView(frame: .zero)
        let gesture = UIScreenEdgePanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.panned))
        gesture.edges = edge
        v.addGestureRecognizer(gesture)
        return v
    }
    
    class Coordinator: NSObject {
        var pannedCallback: ((CGPoint, Int) -> Void)
        init(pannedCallback: @escaping ((CGPoint, Int) -> Void)) {
            self.pannedCallback = pannedCallback
        }
        @objc func panned(gesture: UILongPressGestureRecognizer) {
            let point = gesture.location(in: gesture.view)
            self.pannedCallback(point, 1)
        }
    }
    
    func makeCoordinator() -> PannableView.Coordinator {
        return Coordinator(pannedCallback: self.pannedCallback)
    }
    
    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<PannableView>) { }
}
