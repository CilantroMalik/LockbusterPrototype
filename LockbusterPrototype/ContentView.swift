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

// Notes for next time:
// duplicate gesture bug was caused by updating gesture name in the onAppear of the lock views in createLock, which would trigger a refresh of the view and therefore might create another lock.
// figure out a way to still update the lock name but not in that specific way

struct ContentView: View {
    @State var started: Bool = false
    @State var currentLock = 1
    @State var currentGesture: NamedGesture = NamedGesture(gestureName: "Tap", gesture: TapGesture())
    @State var currentGestureName: String = "Double Tap"
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
                print("finished animating");
                DispatchQueue.main.asyncAfter(deadline: .now()+0.6, execute: {print("dispatch running"); self.currentLock = Int.random(in: 1...5); self.currentGestureDone = false})
            })
    }
    
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
                                print("2t name changed")
                            })
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
                                print("3t name changed")
                            })
            )
        }
        
    }
    
}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
