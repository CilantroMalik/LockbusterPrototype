//
//  ContentView.swift
//  LockbusterPrototype
//
//  Created by Rohan MALIK on 2/12/21.
//

import SwiftUI


enum GameMode {
    case Speedrun
    case Countdown
    case ChessClock
}

struct ImageAnimated: UIViewRepresentable {
    let imageSize: CGSize
    let group: Int
    let lock: Int
    let duration: Double = 0.45

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


struct TimerView: View {
    @State var timeLeft = 60.00
    let timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    
    var body: some View {
        Text(String(format: "%.2f seconds remaining", timeLeft))
            .onReceive(timer, perform: { _ in
                if timeLeft > 0 { timeLeft -= 0.01 }
            }).padding(.top)
    }
}

// Backlog:
// 1) test three-finger swipes to see if they are too clunky
// 2) implement logic for upgrading locks as the player progresses
// 3) in connection with 2, look into APIs for changing app icons at progression points
// 4) try to refactor createLock() to be more concise and less repetitive while preserving functionality

var gestureName = ""
var score = 0
var mode: GameMode = .Speedrun
// --- speedrun mode ---
var finalTime = ""
var prevBestTime = 0.0
// --- countdown mode ---
var prevBestScore = 0
// --- both ---
var startTime: TimeInterval = 0.0

struct ContentView: View {
    @State var started: Bool = false
    @State var currentLock = 1
    @State var currentGestureDone = false
    @State var timeUp = false
    
    var body: some View {
        return VStack {
            if !started {  // "welcome screen"
                Text("Welcome to Lockbuster!").padding(.bottom).font(.system(size: 33))
                Button("Speedrun Mode", action: {
                    startTime = Date.timeIntervalSinceReferenceDate
                    print("starting game at time \(startTime)")
                    print("current PB is \(UserDefaults.standard.double(forKey: "hundredGesturesTime"))")
                    prevBestTime = UserDefaults.standard.double(forKey: "hundredGesturesTime")
                    self.started = true
                }).padding(.top).padding(.bottom).font(.title2)
                Button("Countdown Mode", action: {
                    startTime = Date.timeIntervalSinceReferenceDate
                    print("starting game at time \(startTime)")
                    print("current highscore is \(UserDefaults.standard.integer(forKey: "oneMinuteScore"))")
                    prevBestScore = UserDefaults.standard.integer(forKey: "oneMinuteScore")
                    mode = .Countdown
                    _ = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: false, block: {_ in self.timeUp = true})
                    self.started = true
                }).padding(.top).font(.title2)
            } else {
                if mode == .Speedrun {
                    if finalTime == "" {
                        if currentGestureDone { animateLock() }
                        else { createLock() }
                        
                        Text("Score: \(score)")
                    } else {
                        Text("Finished!").animation(.easeInOut(duration: 1.5)).padding(.bottom).font(.system(size: 75))
                        Text("Time: \(finalTime)s").animation(.easeInOut(duration: 2.5)).padding(.top).font(.system(size: 38))
                        let currentBest = Double(finalTime)!
                        if currentBest < prevBestTime {
                            Text("New best time!").padding(.top).font(.system(size: 26))
                            Text(String(format: "(Improved by %.3fs)", prevBestTime-currentBest)).padding(.top)
                        } else {
                            Text(String(format: "Best time: %.3fs", prevBestTime)).padding(.top)
                        }
                    }
                } else if mode == .Countdown {
                    if !timeUp {
                        if currentGestureDone { animateLock() }
                        else { createLock() }
                        
                        TimerView()
                    } else {
                        Text("Finished!").animation(.easeInOut(duration: 1.5)).padding(.bottom).font(.system(size: 75))
                        Text("Score: \(score)").animation(.easeInOut(duration: 2.5)).padding(.top).font(.system(size: 38))
                        if score > prevBestScore {
                            Text("New highscore!").padding(.top).font(.system(size: 26))
                            Text("Improved by \(score-prevBestScore)").padding(.top)
                        } else {
                            Text("Highscore: \(prevBestScore)").padding(.top)
                        }
                    }
                }
            }
        }
    }
    
    func animateLock() -> some View {
        print("animating lock")
        return AnyView(
            VStack {
                Text("a").foregroundColor(.white).font(.system(size: 35))
                ImageAnimated(imageSize: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5), group: 1, lock: currentLock)
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                .aspectRatio(contentMode: .fill)
                .onAppear(perform: {
                    print("finished animating");
                    DispatchQueue.main.asyncAfter(deadline: .now()+0.5, execute: {
                        print("dispatch running")
                        if mode == .Speedrun {
                            if score >= 5 {  // change for easier testing; revert to 100 for production
                                finalTime = String(format: "%.3f", Date.timeIntervalSinceReferenceDate-startTime)
                                if Double(finalTime)! < prevBestTime || prevBestTime == 0.0 {
                                    print("setting \(Double(finalTime)!); previous value \(prevBestTime)")
                                    UserDefaults.standard.set(Double(finalTime)!, forKey: "hundredGesturesTime")
                                }
                            }
                        }
                        self.currentLock = Int.random(in: 1...5)
                        self.currentGestureDone = false
                    })
                })
            }
        )
    }
    
    func createLock() -> some View {
        print("creating lock")
        let num = Int.random(in: 1...5) // change for simulator testing; revert to 23 for production
        if num == 1 {
            print("chosen 2t")
            gestureName = "Double Tap"
            return AnyView(
                VStack {
                    Text(gestureName).font(.system(size: 35))
                    Image("G1L\(self.currentLock)F1")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                        .gesture(TapGesture(count: 2).onEnded{score += 1; self.currentGestureDone = true; print("2t")})
                        .onAppear(perform: { print("2t name changed") })
                }
            )
        } else if num == 2 {
            print("chosen 3t")
            gestureName = "Triple Tap"
            return AnyView(
                VStack {
                    Text(gestureName).font(.system(size: 35))
                    Image("G1L\(self.currentLock)F1")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                        .gesture(TapGesture(count: 3).onEnded{score += 1; self.currentGestureDone = true; print("3t")})
                        .onAppear(perform: { print("3t name changed") })
                }
            )
        } else if num == 3 {
            print("chosen rot")
            gestureName = "Rotate"
            return AnyView(
                VStack {
                    Text(gestureName).font(.system(size: 35))
                    Image("G1L\(self.currentLock)F1")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                        .gesture(RotationGesture().onEnded{_ in score += 1; self.currentGestureDone = true; print("rot")})
                        .onAppear(perform: { print("rot name changed") })
                }
            )
        } else if num == 4 {
            print("chosen mag")
            gestureName = "Pinch"
            return AnyView(
                VStack {
                    Text(gestureName).font(.system(size: 35))
                    Image("G1L\(self.currentLock)F1")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                        .gesture(MagnificationGesture().onEnded{_ in score += 1; self.currentGestureDone = true; print("mag")})
                        .onAppear(perform: { print("mag name changed") })
                }
            )
        } else if num == 5 {
            print("chosen 2ft")
            gestureName = "Two Finger Tap"
            return AnyView(
                VStack {
                    Text(gestureName).font(.system(size: 35))
                    ZStack {
                        Image("G1L\(self.currentLock)F1")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                            .onAppear(perform: { print("2ft name changed") })
                        TappableView(touches: 2, tappedCallback: {(_, _) in score += 1; self.currentGestureDone = true; print("2ft")})
                            .aspectRatio(contentMode: .fill)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                    }
                }
            )
        } else if num == 6 {
            print("chosen 3ft")
            gestureName = "Three Finger Tap"
            return AnyView(
                VStack {
                    Text(gestureName).font(.system(size: 35))
                    ZStack {
                        Image("G1L\(self.currentLock)F1")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                            .onAppear(perform: { print("3ft name changed") })
                        TappableView(touches: 3, tappedCallback: {(_, _) in score += 1; self.currentGestureDone = true; print("3ft")})
                            .aspectRatio(contentMode: .fill)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                    }
                }
            )
        } else if num == 7 {
            print("chosen ls")
            gestureName = "Left Swipe"
            return AnyView(
                VStack {
                    Text(gestureName).font(.system(size: 35))
                    ZStack {
                        Image("G1L\(self.currentLock)F1")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                            .onAppear(perform: { print("ls name changed") })
                        DraggableView(direction: .left, touches: 1, draggedCallback:{(_, _) in score += 1; self.currentGestureDone = true; print("ls")})
                            .aspectRatio(contentMode: .fill)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                    }
                }
            )
        } else if num == 8 {
            print("chosen rs")
            gestureName = "Right Swipe"
            return AnyView(
                VStack {
                    Text(gestureName).font(.system(size: 35))
                    ZStack {
                        Image("G1L\(self.currentLock)F1")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                            .onAppear(perform: { print("rs name changed") })
                        DraggableView(direction: .right, touches: 1, draggedCallback:{(_, _) in score += 1; self.currentGestureDone = true; print("rs")})
                            .aspectRatio(contentMode: .fill)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                    }
                }
            )
        } else if num == 9 {
            print("chosen us")
            gestureName = "Up Swipe"
            return AnyView(
                VStack {
                    Text(gestureName).font(.system(size: 35))
                    ZStack {
                        Image("G1L\(self.currentLock)F1")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                            .onAppear(perform: { print("us name changed") })
                        DraggableView(direction: .up, touches: 1, draggedCallback:{(_, _) in score += 1; self.currentGestureDone = true; print("us")})
                            .aspectRatio(contentMode: .fill)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                    }
                }
            )
        } else if num == 10 {
            print("chosen ds")
            gestureName = "Down Swipe"
            return AnyView(
                VStack {
                    Text(gestureName).font(.system(size: 35))
                    ZStack {
                        Image("G1L\(self.currentLock)F1")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                            .onAppear(perform: { print("ds name changed") })
                        DraggableView(direction: .down, touches: 1, draggedCallback:{(_, _) in score += 1; self.currentGestureDone = true; print("ds")})
                            .aspectRatio(contentMode: .fill)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                    }
                }
            )
        } else if num == 11 {
            print("chosen 2fls")
            gestureName = "Two Finger Left Swipe"
            return AnyView(
                VStack {
                    Text(gestureName).font(.system(size: 35))
                    ZStack {
                        Image("G1L\(self.currentLock)F1")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                            .onAppear(perform: { print("2fls name changed") })
                        DraggableView(direction: .left, touches: 2, draggedCallback:{(_, _) in score += 1; self.currentGestureDone = true; print("2fls")})
                            .aspectRatio(contentMode: .fill)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                    }
                }
            )
        } else if num == 12 {
            print("chosen 2frs")
            gestureName = "Two Finger Right Swipe"
            return AnyView(
                VStack {
                    Text(gestureName).font(.system(size: 35))
                    ZStack {
                        Image("G1L\(self.currentLock)F1")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                            .onAppear(perform: { print("2frs name changed") })
                        DraggableView(direction: .right, touches: 2, draggedCallback:{(_, _) in score += 1; self.currentGestureDone = true; print("2frs")})
                            .aspectRatio(contentMode: .fill)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                    }
                }
            )
        } else if num == 13 {
            print("chosen 2fus")
            gestureName = "Two Finger Up Swipe"
            return AnyView(
                VStack {
                    Text(gestureName).font(.system(size: 35))
                    ZStack {
                        Image("G1L\(self.currentLock)F1")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                            .onAppear(perform: { print("2fus name changed") })
                        DraggableView(direction: .up, touches: 2, draggedCallback:{(_, _) in score += 1; self.currentGestureDone = true; print("2fus")})
                            .aspectRatio(contentMode: .fill)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                    }
                }
            )
        } else if num == 14 {
            print("chosen 2fds")
            gestureName = "Two Finger Down Swipe"
            return AnyView(
                VStack {
                    Text(gestureName).font(.system(size: 35))
                    ZStack {
                        Image("G1L\(self.currentLock)F1")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                            .onAppear(perform: { print("2fds name changed") })
                        DraggableView(direction: .down, touches: 2, draggedCallback:{(_, _) in score += 1; self.currentGestureDone = true; print("2fds")})
                            .aspectRatio(contentMode: .fill)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                    }
                }
            )
        } else if num == 15 {
            print("chosen lp")
            gestureName = "Long Press"
            return AnyView(
                VStack {
                    Text(gestureName).font(.system(size: 35))
                    ZStack {
                        Image("G1L\(self.currentLock)F1")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                            .onAppear(perform: { print("lp name changed") })
                            .gesture(LongPressGesture(minimumDuration: 0.4).onEnded({_ in self.currentGestureDone = true; print("lp")}))
                    }
                }
            )
        } else if num == 16 {
            print("chosen 2flp")
            gestureName = "Two Finger Long Press"
            return AnyView(
                VStack {
                    Text(gestureName).font(.system(size: 35))
                    ZStack {
                        Image("G1L\(self.currentLock)F1")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                            .onAppear(perform: { print("2flp name changed") })
                        LongPressableView(touches: 2, pressedCallback:{(_, _) in score += 1; self.currentGestureDone = true; print("2flp")})
                            .aspectRatio(contentMode: .fill)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                    }
                }
            )
        } else if num == 17 {
            print("chosen 3flp")
            gestureName = "Three Finger Long Press"
            return AnyView(
                VStack {
                    Text(gestureName).font(.system(size: 35))
                    ZStack {
                        Image("G1L\(self.currentLock)F1")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                            .onAppear(perform: { print("3flp name changed") })
                        LongPressableView(touches: 3, pressedCallback:{(_, _) in score += 1; self.currentGestureDone = true; print("2flp")})
                            .aspectRatio(contentMode: .fill)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                    }
                }
            )
        } else if num == 18 {
            print("chosen lep")
            gestureName = "Left Edge Pan"
            return AnyView(
                VStack {
                    Text(gestureName).font(.system(size: 35))
                    ZStack {
                        Image("G1L\(self.currentLock)F1")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                            .onAppear(perform: { print("lep name changed") })
                        PannableView(edge: .left, pannedCallback:{(_, _) in score += 1; self.currentGestureDone = true; print("lep")})
                            .aspectRatio(contentMode: .fill)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                    }
                }
            )
        } else if num == 19 {
            print("chosen rep")
            gestureName = "Right Edge Pan"
            return AnyView(
                VStack {
                    Text(gestureName).font(.system(size: 35))
                    ZStack {
                        Image("G1L\(self.currentLock)F1")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                            .onAppear(perform: { print("rep name changed") })
                        PannableView(edge: .right, pannedCallback:{(_, _) in score += 1; self.currentGestureDone = true; print("rep")})
                            .aspectRatio(contentMode: .fill)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                    }
                }
            )
        } else if num == 20 {
            print("chosen 3fls")
            gestureName = "Three Finger Left Swipe"
            return AnyView(
                VStack {
                    Text(gestureName).font(.system(size: 35))
                    ZStack {
                        Image("G1L\(self.currentLock)F1")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                            .onAppear(perform: { print("2fus name changed") })
                        DraggableView(direction: .left, touches: 3, draggedCallback:{(_, _) in score += 1; self.currentGestureDone = true; print("2fus")})
                            .aspectRatio(contentMode: .fill)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                    }
                }
            )
        } else if num == 21 {
            print("chosen 3frs")
            gestureName = "Three Finger Right Swipe"
            return AnyView(
                VStack {
                    Text(gestureName).font(.system(size: 35))
                    ZStack {
                        Image("G1L\(self.currentLock)F1")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                            .onAppear(perform: { print("2fus name changed") })
                        DraggableView(direction: .right, touches: 3, draggedCallback:{(_, _) in score += 1; self.currentGestureDone = true; print("2fus")})
                            .aspectRatio(contentMode: .fill)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                    }
                }
            )
        } else if num == 22 {
            print("chosen 3fus")
            gestureName = "Three Finger Up Swipe"
            return AnyView(
                VStack {
                    Text(gestureName).font(.system(size: 35))
                    ZStack {
                        Image("G1L\(self.currentLock)F1")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                            .onAppear(perform: { print("2fus name changed") })
                        DraggableView(direction: .up, touches: 3, draggedCallback:{(_, _) in score += 1; self.currentGestureDone = true; print("2fus")})
                            .aspectRatio(contentMode: .fill)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                    }
                }
            )
        } else {
            print("chosen 3fds")
            gestureName = "Three Finger Down Swipe"
            return AnyView(
                VStack {
                    Text(gestureName).font(.system(size: 35))
                    ZStack {
                        Image("G1L\(self.currentLock)F1")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                            .onAppear(perform: { print("2fus name changed") })
                        DraggableView(direction: .down, touches: 3, draggedCallback:{(_, _) in score += 1; self.currentGestureDone = true; print("2fus")})
                            .aspectRatio(contentMode: .fill)
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
