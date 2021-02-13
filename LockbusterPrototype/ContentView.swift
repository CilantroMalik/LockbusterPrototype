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
    let duration: Double = 0.7

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

func chooseGesture() -> String {
    let gestures: [String] = ["Tap", "Left Swipe", "Up Swipe", "Down Swipe", "Right Swipe", "Rotate", "Pinch", "Expand"]
    return gestures[Int.random(in: 0...7)] // change upper bound depending on number of gestures
}

// TODO: figure out directional gestures; investigate multi-finger tap or drag; implement varied gestures in recognizer and main state updater

struct ContentView: View {
    @State var started: Bool = true
    @State var timeLeft: Float = 60.0
    @State var currentGestureDone = false
    var body: some View {
        VStack {
            if !started {  // welcome text
                Text("Welcome to Lockbuster!")
                Button("Start Game", action: {self.started = true})
            }
            else {
                Text("Tap")
                    .padding(.bottom)
                    .scaleEffect(2)
                if currentGestureDone {
                    ImageAnimated(imageSize: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5), group: 1, lock: 1)
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                }
                else {
                    Image("G1L1F1")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                        .gesture(
                            TapGesture(count: 2)
                                .onEnded { _ in
                                    currentGestureDone = true
                                }
                        )
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
