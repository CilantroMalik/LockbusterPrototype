//
//  ContentView.swift
//  LockbusterPrototype
//
//  Created by Rohan MALIK on 2/12/21.
//

import SwiftUI

// --- enums ---
/// GameMode: keeps track of the game mode for readability and transparency
enum GameMode {
    case Speedrun
    case Countdown
    case ChessClock
}

// --- auxiliary views ---
/// AnimatedImage: stores an animated image composed of a number of individual frames (using UIImageView, which has this functionality built in)
/// Essentially a UIView wrapped in UIViewRepresentable so it can be compatible with SwiftUI. Has a set duration and extracts the frames of animation from the assets.
struct AnimatedImage: UIViewRepresentable {
    // take in image size as a parameter, as well as identifiers for the lock we want to animate
    let imageSize: CGSize
    let group: Int
    let lock: Int
    let duration: Double = 0.45

    func makeUIView(context: Self.Context) -> UIView {
        let imageNames = (1...13).map { "G\(group)L\(lock)F\($0)" }  // use image name file format to generate from parameters
        
        // create the larger UIView that will be returned as well as the ImageView that stores our animation
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height))

        let animationImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height))

        // set properties of the animation view
        animationImageView.clipsToBounds = true
        animationImageView.layer.cornerRadius = 5
        animationImageView.autoresizesSubviews = true
        animationImageView.contentMode = UIView.ContentMode.scaleAspectFill

        // use the list of image names generated above to make a list of the actual image objects for the animation
        var images = [UIImage]()
        imageNames.forEach { imageName in
            if let img = UIImage(named: imageName) { images.append(img) }
        }
        
        // then add these to the animation view and set properties of the animation
        animationImageView.animationImages = images
        animationImageView.animationDuration = duration
        animationImageView.animationRepeatCount = 1
        animationImageView.startAnimating()

        // add the ImageView to our main view and return it
        containerView.addSubview(animationImageView)
        return containerView
    }

    // needs to be here for conformance to UIViewRepresentable, but we do not need it for this use case
    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<AnimatedImage>) { }
}

/// CountdownTimerView: stores a self-updating timer that counts down from the user's selected time limit
/// (which will be stored as a global variable when this view is instantiated) in increments of 0.01 second, using a publisher.
/// Simply store this in a single text box that updates when it receives an event from the timer publisher.
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

/// SpeedrunClockView: analog to the CountdownTimerView that counts up instead of down, indefinitely until the user reaches the desired score
/// (since this is Speedrun mode and does not have a time target). Also counts in increments of 0.01 second and will reside as a subview of the main view.
struct SpeedrunClockView: View {
    @State var timeElapsed = 0.00
    let timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    
    var body: some View {
        Text(String(format: "%.2f seconds elapsed", timeElapsed)).padding(.top)
            .onReceive(timer, perform: { _ in timeElapsed += 0.01 })
    }
}

// =============================================
// Backlog:
// 1) begin prototyping for "chess clock" mode
// 2) create pictographic glyphs for gestures to eliminate the need for text (possibly animated)
// =============================================

// --- game state variables ---
var gestureName = ""  /// the name of the current gesture
var score = 0  /// the player's current score
var lockGroup = 1  /// the lock upgrade level the player has reached in the current game
var mode: GameMode = .Speedrun  /// the game mode the player is currently playing
var upgrades: [Int] = []  /// the score thresholds at which the lock is upgraded
// speedrun mode
var finalTime = ""  /// the player's time upon reaching the desired score
var prevBestTime = 0.0  /// the player's previous best time in Speedrun Mode (fetched at startup from UserDefaults)
var scoreSelection = 100  /// the Speedrun Mode "category" that the user has selected, defining the game's target score
// countdown mode
var prevBestScore = 0  /// the player's previous best score in Countdown Mode (fetched at startup from UserDefaults)
var timeSelection = 60.0  /// the Countdown Mode "category" that the user has selected, defining the game's time limit
// both
var startTime: TimeInterval = 0.0  /// the absolute time since the epoch at which the player starts the game


// --- main view ---
/// ContentView: the main game view that encapsulates the state and behavior of the game
struct ContentView: View {
    /// toggles whether to show the welcome/mode select screen; starts false, becomes true when user selects a mode and false again when they finish a game
    @State var started: Bool = false
    /// keeps track of the lock number within the current group (randomly assigned for each new lock
    @State var currentLock = 1
    /// triggers the selection of a new gesture; this variable is toggled every time a gesture recognizer receives its gesture
    @State var currentGestureDone = false
    /// toggled when the timer runs out (only in Countdown Mode) to force trigger the end screen
    @State var timeUp = false
    
    /// contains all the visual elements that will be displayed at any point in the game
    var body: some View {
        // wrap all of our elements into a vertical stack on screen
        return VStack {
            if !started {  // display the "welcome screen"
                Text("Welcome to Lockbuster!").padding(.bottom).font(.system(size: 33))
                
                Text("— Speedrun Mode —").padding(.top).padding(.bottom).font(.system(size: 27))
                Text("Select a target score:").padding(.bottom)
                HStack {  // provide category selection options; each one sets the score selection global variable to the appropriate amount and triggers a function to start the game
                    Button("25", action: { scoreSelection = 25; startSpeedrun() }).padding(.trailing).font(.system(size: 20, weight: .bold, design: .rounded))
                    Button("50", action: { scoreSelection = 50; startSpeedrun() }).padding(.trailing).padding(.leading).font(.system(size: 20, weight: .bold, design: .rounded))
                    Button("60", action: { scoreSelection = 60; startSpeedrun() }).padding(.trailing).padding(.leading).font(.system(size: 20, weight: .bold, design: .rounded))
                    Button("80", action: { scoreSelection = 80; startSpeedrun() }).padding(.trailing).padding(.leading).font(.system(size: 20, weight: .bold, design: .rounded))
                    Button("100", action: { scoreSelection = 100; startSpeedrun() }).padding(.leading).font(.system(size: 20, weight: .bold, design: .rounded))
                }
                
                Text("— Countdown Mode —").padding(.top).padding(.bottom).font(.system(size: 27))
                Text("Select a time limit:").padding(.bottom)
                HStack {  // similar to the previous, let the user select a time limit, store it in the global, and trigger the start function
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
                        } else { Text(String(format: "Best time: %.3fs", prevBestTime)).padding(.top) }
                        
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
                        } else { Text("Highscore: \(prevBestScore)").padding(.top) }
                        
                        Button("Back to Mode Select", action: {score = 0; self.timeUp = false; lockGroup = 1; self.started = false}).padding(.top)
                    }
                }
            }
        }
    }
    
    func startSpeedrun() {
        startTime = Date.timeIntervalSinceReferenceDate
        prevBestTime = UserDefaults.standard.double(forKey: "hundredGesturesTime")
        mode = .Speedrun
        switch scoreSelection {
            case 25:
                upgrades = [7, 14, 21]; break
            case 50:
                upgrades = [9, 20, 32, 45]; break
            case 60:
                upgrades = [11, 22, 33, 44, 55]; break
            case 80:
                upgrades = [13, 27, 40, 53, 66, 80]; break
            case 100:
                upgrades = [15, 30, 45, 60, 75, 90, 99]; break
            default: break
        }
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
                AnimatedImage(imageSize: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5), group: (upgrades.contains(score) ? lockGroup-1 : lockGroup), lock: currentLock)
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center).aspectRatio(contentMode: .fill).scaleEffect(0.95)
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
                    Image("G\(lockGroup)L\(self.currentLock)F1").resizable().aspectRatio(contentMode: .fill).scaleEffect(0.95)
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                        .gesture(TapGesture(count: 2).onEnded{score += 1; if upgrades.contains(score) {lockGroup += 1}; self.currentGestureDone = true})
                }
            )
        } else if num == 2 {
            gestureName = "Triple Tap"
            return AnyView(
                VStack {
                    Text(gestureName).font(.system(size: 35))
                    Image("G\(lockGroup)L\(self.currentLock)F1").resizable().aspectRatio(contentMode: .fill).scaleEffect(0.95)
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                        .gesture(TapGesture(count: 3).onEnded{score += 1; if upgrades.contains(score) {lockGroup += 1}; self.currentGestureDone = true})
                }
            )
        } else if num == 3 {
            gestureName = "Rotate"
            return AnyView(
                VStack {
                    Text(gestureName).font(.system(size: 35))
                    Image("G\(lockGroup)L\(self.currentLock)F1").resizable().aspectRatio(contentMode: .fill).scaleEffect(0.95)
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                        .gesture(RotationGesture().onEnded{_ in score += 1; if upgrades.contains(score) {lockGroup += 1}; self.currentGestureDone = true})
                }
            )
        } else if num == 4 {
            gestureName = "Pinch"
            return AnyView(
                VStack {
                    Text(gestureName).font(.system(size: 35))
                    Image("G\(lockGroup)L\(self.currentLock)F1").resizable().aspectRatio(contentMode: .fill).scaleEffect(0.95)
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
