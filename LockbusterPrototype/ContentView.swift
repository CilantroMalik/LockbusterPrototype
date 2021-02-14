//
//  ContentView.swift
//  LockbusterPrototype
//
//  Created by Rohan MALIK on 2/12/21.
//

import SwiftUI

struct ImageAnimated: UIViewRepresentable {
    let imageSize: CGSize
    let group: Int
    let lock: Int
    let duration: Double = 0.6

    func makeUIView(context: Self.Context) -> UIView {
        let imageNames = (1...13).map { "G\(group)L\(lock)F\($0)" }
        
        let containerView = UIView(frame: CGRect(x: 0, y: 0
            , width: imageSize.width, height: imageSize.height))

        let animationImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height))

        animationImageView.clipsToBounds = true
        animationImageView.layer.cornerRadius = 5
        animationImageView.autoresizesSubviews = true
        animationImageView.contentMode = UIView.ContentMode.scaleAspectFill

        var images = [UIImage]()
        imageNames.forEach { imageName in
            if let img = UIImage(named: imageName) {
                images.append(img)
            }
        }

        animationImageView.animationImages = images
        animationImageView.animationDuration = duration
        animationImageView.animationRepeatCount = 1
        animationImageView.startAnimating()

        containerView.addSubview(animationImageView)
        return containerView
    }

    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<ImageAnimated>) {

    }
}

struct TappableView:UIViewRepresentable {
    var tappedCallback: ((CGPoint, Int) -> Void)
    
    func makeUIView(context: UIViewRepresentableContext<TappableView>) -> UIView {
        let v = UIView(frame: .zero)
        let gesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.tapped))
        gesture.numberOfTapsRequired = 1
        gesture.numberOfTouchesRequired = 2
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
    
    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<TappableView>) {
    }
    
}

// Notes for next session:
// move into directional gestures (single- and multi-finger swipes)

var gestureName = ""


struct ContentView: View {
    @State var started: Bool = true
    @State var currentLock = 1
    @State var currentGestureDone = false
    
    var body: some View {
        return VStack {
            if !started {  // "welcome screen"
                Text("Welcome to Lockbuster!")
                Button("Start Game", action: {
                    print("starting game")
                    self.started = true
                })
            }
            else {
                if currentGestureDone {
                    animateLock()
                }
                else {
                    createLock()
                }
            }
        }
    }
    
    func animateLock() -> some View {
        print("animating lock")
        return AnyView(
            VStack {
                Text("a").scaleEffect(2).foregroundColor(.white)
                ImageAnimated(imageSize: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5), group: 1, lock: currentLock)
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                .aspectRatio(contentMode: .fill)
                .onAppear(perform: {
                    print("finished animating");
                    DispatchQueue.main.asyncAfter(deadline: .now()+0.6, execute: {print("dispatch running"); self.currentLock = Int.random(in: 1...5); self.currentGestureDone = false})
                })
            }
        )
    }
    
    func createLock() -> some View {
        print("creating lock")
        let num = Int.random(in: 1...5)
        if num == 1 {
            print("chosen 2t")
            gestureName = "Double Tap"
            return AnyView(
                VStack {
                    Text(gestureName).scaleEffect(2)
                    Image("G1L\(self.currentLock)F1")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                        .gesture(TapGesture(count: 2).onEnded{self.currentGestureDone = true; print("2t")})
                        .onAppear(perform: { print("2t name changed") })
                }
            )
        } else if num == 2 {
            print("chosen 3t")
            gestureName = "Triple Tap"
            return AnyView(
                VStack {
                    Text(gestureName).scaleEffect(2)
                    Image("G1L\(self.currentLock)F1")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                        .gesture(TapGesture(count: 3).onEnded{self.currentGestureDone = true; print("3t")})
                        .onAppear(perform: { print("3t name changed") })
                }
            )
        } else if num == 3 {
            print("chosen rot")
            gestureName = "Rotate"
            return AnyView(
                VStack {
                    Text(gestureName).scaleEffect(2)
                    Image("G1L\(self.currentLock)F1")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                        .gesture(RotationGesture().onEnded{_ in self.currentGestureDone = true; print("rot")})
                        .onAppear(perform: { print("rot name changed") })
                }
            )
        } else if num == 4 {
            print("chosen mag")
            gestureName = "Pinch"
            return AnyView(
                VStack {
                    Text(gestureName).scaleEffect(2)
                    Image("G1L\(self.currentLock)F1")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                        .gesture(MagnificationGesture().onEnded{_ in self.currentGestureDone = true; print("mag")})
                        .onAppear(perform: { print("mag name changed") })
                }
            )
        } else {
            print("chosen 2ft")
            gestureName = "Two Finger Tap"
            return AnyView(
                VStack {
                    Text(gestureName).scaleEffect(2)
                    ZStack {
                        Image("G1L\(self.currentLock)F1")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                            .onAppear(perform: { print("2ft name changed") })
                        TappableView {
                            (location, taps) in self.currentGestureDone = true; print("2ft")
                        }.aspectRatio(contentMode: .fill)
                         .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                    }
                }
            )
        }
    }
}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
