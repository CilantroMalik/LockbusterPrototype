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
        
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height))

        let animationImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height))

        animationImageView.clipsToBounds = true
        animationImageView.layer.cornerRadius = 5
        animationImageView.autoresizesSubviews = true
        animationImageView.contentMode = UIView.ContentMode.scaleAspectFill

        var images = [UIImage]()
        imageNames.forEach { imageName in
            if let img = UIImage(named: imageName) { images.append(img) }
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


struct CountdownTimerView: View {
    @State var timeLeft = timeSelection
    let timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    
    var body: some View {
        Text(String(format: "%.2f seconds remaining", timeLeft))
            .onReceive(timer, perform: { _ in
                if timeLeft > 0 { timeLeft -= 0.01 }
            }).padding(.top)
    }
}

struct SpeedrunClockView: View {
    @State var timeElapsed = 0.00
    let timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    
    var body: some View {
        Text(String(format: "%.2f seconds elapsed", timeElapsed)).padding(.top)
            .onReceive(timer, perform: { _ in timeElapsed += 0.01 })
    }
}

// Backlog:
// 1) begin prototyping for "chess clock" mode
// 2) create pictographic glyphs for gestures to eliminate the need for text (possibly animated)

// --- game state variables ---
var gestureName = ""
var score = 0
var lockGroup = 1
var mode: GameMode = .Speedrun
var upgrades: [Int] = []
// --- speedrun mode ---
var finalTime = ""
var prevBestTime = 0.0
var scoreSelection = 100
// --- countdown mode ---
var prevBestScore = 0
var timeSelection = 60.0
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
                
                Text("— Speedrun Mode —").padding(.top).padding(.bottom).font(.system(size: 27))
                Text("Select a target score:").padding(.bottom)
                HStack {
                    Button("25", action: { scoreSelection = 25; startSpeedrun() }).padding(.trailing).font(.system(size: 20, weight: .bold, design: .rounded))
                    Button("50", action: { scoreSelection = 50; startSpeedrun() }).padding(.trailing).padding(.leading).font(.system(size: 20, weight: .bold, design: .rounded))
                    Button("60", action: { scoreSelection = 60; startSpeedrun() }).padding(.trailing).padding(.leading).font(.system(size: 20, weight: .bold, design: .rounded))
                    Button("80", action: { scoreSelection = 80; startSpeedrun() }).padding(.trailing).padding(.leading).font(.system(size: 20, weight: .bold, design: .rounded))
                    Button("100", action: { scoreSelection = 100; startSpeedrun() }).padding(.leading).font(.system(size: 20, weight: .bold, design: .rounded))
                }
                
                Text("— Countdown Mode —").padding(.top).padding(.bottom).font(.system(size: 27))
                Text("Select a time limit:").padding(.bottom)
                HStack {
                    Button("30s", action: { timeSelection = 30.0; startCountdown() }).padding(.trailing).font(.system(size: 20, weight: .bold, design: .rounded))
                    Button("1m", action: { timeSelection = 60.0; startCountdown() }).padding(.trailing).padding(.leading).font(.system(size: 20, weight: .bold, design: .rounded))
                    Button("2m", action: { timeSelection = 120.0; startCountdown() }).padding(.trailing).padding(.leading).font(.system(size: 20, weight: .bold, design: .rounded))
                    Button("3m", action: { timeSelection = 180.0; startCountdown() }).padding(.trailing).padding(.leading).font(.system(size: 20, weight: .bold, design: .rounded))
                    Button("5m", action: { timeSelection = 300.0; startCountdown() }).padding(.leading).font(.system(size: 20, weight: .bold, design: .rounded))
                }
            } else {
                if mode == .Speedrun {
                    if finalTime == "" {
                        if currentGestureDone { animateLock() }
                        else { createLock() }
                        
                        Text("Score: \(score)").padding(.bottom)
                        SpeedrunClockView()
                    } else {
                        Text("Finished!").animation(.easeInOut(duration: 1.5)).padding(.bottom).font(.system(size: 75, weight: .black, design: .default))
                        Text("Time: \(finalTime)s").animation(.easeInOut(duration: 2.5)).padding(.top).font(.system(size: 38, weight: .bold, design: .default))
                        let currentBest = Double(finalTime)!
                        if currentBest < prevBestTime {
                            Text("New best time!").padding(.top).font(.system(size: 26, weight: .semibold))
                            Text(String(format: "(Improved by %.3fs)", prevBestTime-currentBest)).padding(.top)
                        } else {
                            Text(String(format: "Best time: %.3fs", prevBestTime)).padding(.top)
                        }
                        Button("Back to Mode Select", action: {finalTime = ""; score = 0; lockGroup = 1; self.started = false}).padding(.top)
                    }
                } else if mode == .Countdown {
                    if !timeUp {
                        if currentGestureDone { animateLock() }
                        else { createLock() }
                        
                        Text("Score: \(score)").padding(.bottom)
                        CountdownTimerView()
                    } else {
                        Text("Finished!").animation(.easeInOut(duration: 1.5)).padding(.bottom).font(.system(size: 75, weight: .bold, design: .default))
                        Text("Score: \(score)").animation(.easeInOut(duration: 2.5)).padding(.top).font(.system(size: 38, weight: .semibold, design: .default))
                        if score > prevBestScore {
                            Text("New highscore!").padding(.top).font(.system(size: 26))
                            Text("Improved by \(score-prevBestScore)").padding(.top)
                        } else {
                            Text("Highscore: \(prevBestScore)").padding(.top)
                        }
                        Button("Back to Mode Select", action: {score = 0; self.timeUp = false; lockGroup = 1; self.started = false}).padding(.top)
                    }
                }
            }
        }
    }
    
    func startSpeedrun() {
        startTime = Date.timeIntervalSinceReferenceDate
        prevBestTime = UserDefaults.standard.double(forKey: "hundredGesturesTime")
        // possibly change behavior to not be completely the same for all score categories (i.e. switch statement)
        upgrades = [Int(scoreSelection/5), Int(2*scoreSelection/5), Int(3*scoreSelection/5), Int(4*scoreSelection/5)]
        mode = .Speedrun
        self.started = true
    }
    
    func startCountdown() {
        startTime = Date.timeIntervalSinceReferenceDate
        prevBestScore = UserDefaults.standard.integer(forKey: "oneMinuteScore")
        mode = .Countdown
        switch timeSelection {
            case 30.0:
                upgrades = [6, 12, 18, 24, 30]; break
            case 60.0:
                upgrades = [9, 18, 27, 36, 45]; break
            case 120.0:
                upgrades = [15, 27, 41, 55, 70]; break
            case 180.0:
                upgrades = [20, 37, 55, 72, 90, 108]; break
            case 300.0:
                upgrades = [25, 50, 75, 100, 125, 150, 175, 200]; break
            default: break
        }
        _ = Timer.scheduledTimer(withTimeInterval: timeSelection, repeats: false, block: {_ in
            self.timeUp = true
            if score > prevBestScore { UserDefaults.standard.set(score, forKey: "oneMinuteScore") }
        })
        self.started = true
    }
    
    func animateLock() -> some View {
        return AnyView(
            VStack {
                Text("a").foregroundColor(.white).font(.system(size: 35))
                ImageAnimated(imageSize: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5), group: (upgrades.contains(score) ? lockGroup-1 : lockGroup), lock: currentLock)
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                    .aspectRatio(contentMode: .fill).scaleEffect(0.95)
                .onAppear(perform: {
                    DispatchQueue.main.asyncAfter(deadline: .now()+0.5, execute: {
                        if mode == .Speedrun {
                            if score >= scoreSelection {  // change for easier testing; revert to `scoreSelection` for production
                                finalTime = String(format: "%.3f", Date.timeIntervalSinceReferenceDate-startTime)
                                if Double(finalTime)! < prevBestTime || prevBestTime == 0.0 {
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
        let num = Int.random(in: 1...2) // change for simulator testing; revert to 23 for production
        if num == 1 {
            gestureName = "Double Tap"
            return AnyView(
                VStack {
                    Text(gestureName).font(.system(size: 35))
                    Image("G\(lockGroup)L\(self.currentLock)F1")
                        .resizable()
                        .aspectRatio(contentMode: .fill).scaleEffect(0.95)
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                        .gesture(TapGesture(count: 2).onEnded{score += 1; if upgrades.contains(score) {lockGroup += 1}; self.currentGestureDone = true})
                }
            )
        } else if num == 2 {
            gestureName = "Triple Tap"
            return AnyView(
                VStack {
                    Text(gestureName).font(.system(size: 35))
                    Image("G\(lockGroup)L\(self.currentLock)F1")
                        .resizable()
                        .aspectRatio(contentMode: .fill).scaleEffect(0.95)
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                        .gesture(TapGesture(count: 3).onEnded{score += 1; if upgrades.contains(score) {lockGroup += 1}; self.currentGestureDone = true})
                }
            )
        } else if num == 3 {
            gestureName = "Rotate"
            return AnyView(
                VStack {
                    Text(gestureName).font(.system(size: 35))
                    Image("G\(lockGroup)L\(self.currentLock)F1")
                        .resizable()
                        .aspectRatio(contentMode: .fill).scaleEffect(0.95)
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                        .gesture(RotationGesture().onEnded{_ in score += 1; if upgrades.contains(score) {lockGroup += 1}; self.currentGestureDone = true})
                }
            )
        } else if num == 4 {
            gestureName = "Pinch"
            return AnyView(
                VStack {
                    Text(gestureName).font(.system(size: 35))
                    Image("G\(lockGroup)L\(self.currentLock)F1")
                        .resizable()
                        .aspectRatio(contentMode: .fill).scaleEffect(0.95)
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                        .gesture(MagnificationGesture().onEnded{_ in score += 1; if upgrades.contains(score) {lockGroup += 1}; self.currentGestureDone = true})
                }
            )
        } else if num == 5 {
            gestureName = "Two Finger Tap"
            return AnyView(LockView(tap: TappableView(touches: 2, tappedCallback: {(_, _) in gestureDone()}), drag: nil, longPress: nil, currentLock: self.currentLock))
        } else if num == 6 {
            gestureName = "Three Finger Tap"
            return AnyView(LockView(tap: TappableView(touches: 3, tappedCallback: {(_, _) in gestureDone()}), drag: nil, longPress: nil, currentLock: self.currentLock))
        } else if num == 7 {
            gestureName = "Left Swipe"
            return AnyView(LockView(tap: nil, drag: DraggableView(direction: .left, touches: 1, draggedCallback: {(_, _) in gestureDone()}), longPress: nil, pan: nil, currentLock: self.currentLock))
        } else if num == 8 {
            gestureName = "Right Swipe"
            return AnyView(LockView(tap: nil, drag: DraggableView(direction: .right, touches: 1, draggedCallback: {(_, _) in gestureDone()}), longPress: nil, pan: nil, currentLock: self.currentLock))
        } else if num == 9 {
            gestureName = "Up Swipe"
            return AnyView(LockView(tap: nil, drag: DraggableView(direction: .up, touches: 1, draggedCallback: {(_, _) in gestureDone()}), longPress: nil, pan: nil, currentLock: self.currentLock))
        } else if num == 10 {
            gestureName = "Down Swipe"
            return AnyView(LockView(tap: nil, drag: DraggableView(direction: .down, touches: 1, draggedCallback: {(_, _) in gestureDone()}), longPress: nil, pan: nil, currentLock: self.currentLock))
        } else if num == 11 {
            gestureName = "Two Finger Left Swipe"
            return AnyView(LockView(tap: nil, drag: DraggableView(direction: .left, touches: 2, draggedCallback: {(_, _) in gestureDone()}), longPress: nil, pan: nil, currentLock: self.currentLock))
        } else if num == 12 {
            gestureName = "Two Finger Right Swipe"
            return AnyView(LockView(tap: nil, drag: DraggableView(direction: .right, touches: 2, draggedCallback: {(_, _) in gestureDone()}), longPress: nil, pan: nil, currentLock: self.currentLock))
        } else if num == 13 {
            gestureName = "Two Finger Up Swipe"
            return AnyView(LockView(tap: nil, drag: DraggableView(direction: .up, touches: 2, draggedCallback: {(_, _) in gestureDone()}), longPress: nil, pan: nil, currentLock: self.currentLock))
        } else if num == 14 {
            gestureName = "Two Finger Down Swipe"
            return AnyView(LockView(tap: nil, drag: DraggableView(direction: .down, touches: 2, draggedCallback: {(_, _) in gestureDone()}), longPress: nil, pan: nil, currentLock: self.currentLock))
        } else if num == 15 {
            gestureName = "Long Press"
            return AnyView(LockView(tap: nil, drag: nil, longPress: LongPressableView(touches: 1, pressedCallback: {(_, _) in gestureDone()}), currentLock: self.currentLock))
        } else if num == 16 {
            gestureName = "Two Finger Long Press"
            return AnyView(LockView(tap: nil, drag: nil, longPress: LongPressableView(touches: 2, pressedCallback: {(_, _) in gestureDone()}), currentLock: self.currentLock))
        } else if num == 17 {
            gestureName = "Three Finger Long Press"
            return AnyView(LockView(tap: nil, drag: nil, longPress: LongPressableView(touches: 3, pressedCallback: {(_, _) in gestureDone()}), currentLock: self.currentLock))
        } else if num == 18 {
            gestureName = "Left Edge Pan"
            return AnyView(LockView(tap: nil, drag: nil, longPress: nil, pan: PannableView(edge: .left, pannedCallback: {(_, _) in gestureDone()}), currentLock: self.currentLock))
        } else if num == 19 {
            gestureName = "Right Edge Pan"
            return AnyView(LockView(tap: nil, drag: nil, longPress: nil, pan: PannableView(edge: .left, pannedCallback: {(_, _) in gestureDone()}), currentLock: self.currentLock))
        } else if num == 20 {
            gestureName = "Three Finger Left Swipe"
            return AnyView(LockView(tap: nil, drag: DraggableView(direction: .left, touches: 3, draggedCallback: {(_, _) in gestureDone()}), longPress: nil, pan: nil, currentLock: self.currentLock))
        } else if num == 21 {
            gestureName = "Three Finger Right Swipe"
            return AnyView(LockView(tap: nil, drag: DraggableView(direction: .right, touches: 3, draggedCallback: {(_, _) in gestureDone()}), longPress: nil, pan: nil, currentLock: self.currentLock))
        } else if num == 22 {
            gestureName = "Three Finger Up Swipe"
            return AnyView(LockView(tap: nil, drag: DraggableView(direction: .up, touches: 3, draggedCallback: {(_, _) in gestureDone()}), longPress: nil, pan: nil, currentLock: self.currentLock))
        } else {
            gestureName = "Three Finger Down Swipe"
            return AnyView(LockView(tap: nil, drag: DraggableView(direction: .down, touches: 3, draggedCallback: {(_, _) in gestureDone()}), longPress: nil, pan: nil, currentLock: self.currentLock))
        }
    }
    
    func gestureDone() {
        score += 1
        if upgrades.contains(score) { lockGroup += 1 }
        self.currentGestureDone = true
    }
    
    struct LockView: View {
        var tap: TappableView?
        var drag: DraggableView?
        var longPress: LongPressableView?
        var pan: PannableView?
        var currentLock: Int
        
        var body: some View {
            VStack {
                Text(gestureName).font(.system(size: 35))
                ZStack {
                    Image("G\(lockGroup)L\(self.currentLock)F1").resizable().aspectRatio(contentMode: .fill).scaleEffect(0.95)
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                    if tap != nil { tap.aspectRatio(contentMode: .fill).frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center) }
                    else if drag != nil { drag.aspectRatio(contentMode: .fill).frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center) }
                    else if longPress != nil { longPress.aspectRatio(contentMode: .fill).frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center) }
                    else if pan != nil { pan.aspectRatio(contentMode: .fill).frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center) }
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
