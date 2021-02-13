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


struct NamedGesture {
    let gestureName: String
    let gesture: Any
}

struct ContentView: View {
    @State var started: Bool = false
    @State var timeLeft: Float = 60.0
    @State var currentLock = 1
    @State var currentGesture: NamedGesture = NamedGesture(gestureName: "Tap", gesture: TapGesture())
    @State var currentGestureName: String = "Double Tap"
    @State var currentGestureDone = false
    var isAnimating = false
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
                //Text(currentGesture.gestureName).padding(.bottom).scaleEffect(2)
                Text(currentGestureName).padding(.bottom).scaleEffect(2)
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
        //self.currentGesture = chooseGesture()
        print("animating lock")
        // self.currentGestureDone = false
        return ImageAnimated(imageSize: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5), group: 1, lock: currentLock)
            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
            .onAppear(perform: {
                DispatchQueue.main.asyncAfter(deadline: .now()+0.7, execute: {self.currentLock = Int.random(in: 1...5); self.currentGestureDone = false})
            })
    }
    
    /*
    func showLock() -> some View {
        //self.currentLock = Int.random(in: 1...5)
        if self.currentGesture.gestureName.contains("Two") {
            let g = self.currentGesture.gesture as! SimultaneousGesture<TapGesture, TapGesture>
            return AnyView(Image("G1L\(self.currentLock)F1")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                .gesture(g))
        } else if self.currentGesture.gestureName.contains("Three") {
            let g = self.currentGesture.gesture as! SimultaneousGesture<SimultaneousGesture<TapGesture, TapGesture>, TapGesture>
            return AnyView(Image("G1L\(self.currentLock)F1")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                .gesture(g))
        } else if self.currentGesture.gestureName.contains("Tap") {
            let g = self.currentGesture.gesture as! TapGesture
            return AnyView(Image("G1L\(self.currentLock)F1")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                .gesture(g))
        } else if self.currentGesture.gestureName.contains("Pinch") {
            let g = self.currentGesture.gesture as! MagnificationGesture
            return AnyView(Image("G1L\(self.currentLock)F1")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                .gesture(g))
        } else {
            let g = self.currentGesture.gesture as! RotationGesture
            return AnyView(Image("G1L\(self.currentLock)F1")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                .gesture(g))
        }
    }
    */
    
    func createLock() -> some View {
        print("creating lock")
        let num = Int.random(in: 1...2)
        if num == 1 {
            print("chosen 2t")
            //self.currentGestureName = "Double Tap"
            return AnyView(Image("G1L\(self.currentLock)F1")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                            .gesture(TapGesture(count: 2).onEnded{self.currentGestureDone = true; print("2t")})
                            .onAppear(perform: {
                                self.currentGestureName = "Double Tap"
                            })
                            .animation(.easeInOut)
            )
        } else {
            print("chosen 3t")
            //self.currentGestureName = "Triple Tap"
            return AnyView(Image("G1L\(self.currentLock)F1")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                            .gesture(TapGesture(count: 3).onEnded{self.currentGestureDone = true; print("3t")})
                            .onAppear(perform: {
                                self.currentGestureName = "Triple Tap"
                            })
                            .animation(.easeInOut)
            )
        }
        
    }
    
    /*
    func chooseGesture() -> NamedGesture {
        let possibleGestures = [
            NamedGesture(gestureName: "Double Tap", gesture: TapGesture(count: 2).onEnded {self.currentGestureDone = true; print("2t")} ),
            NamedGesture(gestureName: "Rotate", gesture: RotationGesture().onEnded {_ in self.currentGestureDone = true; print("r")} ),
            NamedGesture(gestureName: "Pinch", gesture: MagnificationGesture().onEnded {_ in self.currentGestureDone = true; print("p")} ),
            NamedGesture(gestureName: "Triple Tap", gesture: TapGesture(count: 3).onEnded {self.currentGestureDone = true; print("3t")} ),
            NamedGesture(gestureName: "Two Finger Tap", gesture: SimultaneousGesture(TapGesture(count: 1), TapGesture(count: 1)).onEnded {_ in self.currentGestureDone = true; print("2ft")} ),
            NamedGesture(gestureName: "Three Finger Tap", gesture: SimultaneousGesture(SimultaneousGesture(TapGesture(count: 1), TapGesture(count: 1)), TapGesture(count: 1)).onEnded {_ in self.currentGestureDone = true; print("3ft")} )
        ]
        return possibleGestures[Int.random(in: 0...5)]
    }
    */
    
}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
