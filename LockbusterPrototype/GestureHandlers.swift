//
//  GestureHandlers.swift
//  LockbusterPrototype
//
//  Created by Rohan Malik on 2/19/21.
//

import Foundation
import SwiftUI

/// GestureHandlers
/// File that contains various auxiliary views that function as UIKit gesture recognizers, for those gestures that UIKit supported but that do not have direct analogs in SwiftUI yet.
/// Includes multi-finger taps, ssignle- or multi-finger directional swipes, multi-finger long presses, and screen edge pans.


/// TappableView: UIView wrapper that contains a UIKit Tap Gesture Recognizer (they have much more customization than SwiftUI gestures)
struct TappableView: UIViewRepresentable {
    var touches: Int  // how many touches (two or three)
    var tappedCallback: ((CGPoint, Int) -> Void)  // what to do when tapped
    
    // main function that renders our view
    func makeUIView(context: UIViewRepresentableContext<TappableView>) -> UIView {
        let v = UIView(frame: .zero)
        let gesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.tapped))  // create our gesture
        gesture.numberOfTapsRequired = 1  // configure the gesture
        gesture.numberOfTouchesRequired = touches
        v.addGestureRecognizer(gesture)  // then add it to the containe view and return it
        return v
    }
    
    class Coordinator: NSObject { // internal class that handles the callback for the gesture
        var tappedCallback: ((CGPoint, Int) -> Void)
        init(tappedCallback: @escaping ((CGPoint, Int) -> Void)) {
            self.tappedCallback = tappedCallback
        }
        @objc func tapped(gesture:UITapGestureRecognizer) {
            let point = gesture.location(in: gesture.view)
            self.tappedCallback(point, 1)
        }
    }
    
    func makeCoordinator() -> TappableView.Coordinator {  // helper function that handles the Coordinator
        return Coordinator(tappedCallback:self.tappedCallback)
    }
    
    // required for conformance to the UIViewRepresentable protocol but not needed here
    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<TappableView>) { }
    
}

/// DraggableView: UIView wrapper that contains a UIKit Swipe Gesture Recognizer (most of these do not yet have analogs in SwiftUI)
struct DraggableView: UIViewRepresentable {
    var direction: UISwipeGestureRecognizer.Direction  // which direction to recognize the swipe
    var touches: Int  // number of fingers for the swipe
    var draggedCallback: ((CGPoint, Int) -> Void)  // what to do when the gesture is recognized
    
    // similar to above, this is the main function that handles rendering of the view
    func makeUIView(context: UIViewRepresentableContext<DraggableView>) -> UIView {
        let v = UIView(frame: .zero)
        // same procedure as TappableView: create the gesture, bind it to the coordinator, and configure its parameters, then add it to the container view
        let gesture = UISwipeGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.dragged))
        gesture.direction = direction
        gesture.numberOfTouchesRequired = touches
        v.addGestureRecognizer(gesture)
        return v
    }
    
    // Coordinator and makeCoordinator are identical to TappableView except for the name changes
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

/// LongPressableView: UIView wrapper that contains a UIKit Long Press Gesture Recognizer (much of the functionality has been ported to SwiftUI, but some is not fully present there yet)
struct LongPressableView: UIViewRepresentable {
    var touches: Int  // how many fingers to register the press
    var pressedCallback: ((CGPoint, Int) -> Void)  // what happens when it is pressed
    
    // The implementation of makeUIView, Coordinator, and makeCoordinator are all analogous or identical to Tappable/DraggableView
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

/// PannableView: UIView wrapper that contains a UIKit Screen Edge Pan Gesture Recognizer (which has not at all been implemented into SwiftUI yet)
struct PannableView: UIViewRepresentable {
    var edge: UIRectEdge  // edge from which to recognize a pan
    var pannedCallback: ((CGPoint, Int) -> Void)  // what to do when the pan is registered
    
    // Again, these implementations are similar to the other gesture handler views, slightly different only because of the type of gesture being configured
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
