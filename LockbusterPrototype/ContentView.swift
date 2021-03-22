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
// chess clock mode
var sequenceLength = 3
var roundNum = 1
var currentRound: [AnyView] = []
var sequenceText = ""
var chessClockTime = 10.00
var chessClockOver = false
var ccLockGroup = 1
var ccLockNum = 1
var ccPrevBest = 0


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
    // ----- chess clock mode -----
    @State var roundFinished = false
    @State var currentPosition = 0
    @StateObject var chessClockTimer = TimerProgress()
    
    /// contains all the visual elements that will be displayed at any point in the game
    var body: some View {
        // wrap all of our elements into a vertical stack on screen
        return VStack {
            if !started {  // display the welcome / mode select screen
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
                
                Text("— Chess Clock Mode —").padding(.top).padding(.bottom).font(.system(size: 27))
                Button("Begin", action: { startChessClock() } ).font(.system(size: 20, weight: .bold, design: .rounded))
            } else {  // main game screen
                if mode == .Speedrun {  // Speedrun Mode: slightly altered UI elements from Countdown, so has to be a separate set of code
                    if finalTime == "" {  // if the game is not over (this variable will take on a value once the target score is reached, so it serves as a proxy for a game over flag)
                        if currentGestureDone { animateLock() }  // if the current gesture has been finished, run this function, which creates & displays the opening lock
                        else { createLock() }  // if not, create a new lock (this runs in the immediate next view update cycle after the animated lock to create a new gesture & image)
                        
                        Text("Score: \(score)").padding(.bottom)  // display the player's score
                        SpeedrunClockView()  // so the player can keep track of their time during the game, display a clock view
                    } else {  // if the game is over: display the end screen and the player's final time
                        Text("Finished!").animation(.easeInOut(duration: 1.5)).padding(.bottom).font(.system(size: 75, weight: .black, design: .default))
                        Text("Time: \(finalTime)s").animation(.easeInOut(duration: 2.5)).padding(.top).font(.system(size: 38, weight: .bold, design: .default))
                        
                        let currentBest = Double(finalTime)!  // cast their time to a double so we can compare it to the previous best time and see if this is a new best
                        if currentBest < prevBestTime {  // if this is a new best, display this and show how much the player improved
                            Text("New best time!").padding(.top).font(.system(size: 26, weight: .semibold))
                            Text(String(format: "(Improved by %.3fs)", prevBestTime-currentBest)).padding(.top)
                        } else { Text(String(format: "Best time: %.3fs", prevBestTime)).padding(.top) }  // if not, show the player their best time as motivation
                        
                        Button("Back to Mode Select", action: {finalTime = ""; score = 0; lockGroup = 1; self.started = false}).padding(.top)  // reset the game state, re-toggle the welcome screen
                    }
                } else if mode == .Countdown {  // Countdown Mode: different UI and end screen (as well as logic) from Speedrun Mode
                    if !timeUp {  // game is not over: same idea as Speedrun Mode in this case
                        if currentGestureDone { animateLock() }
                        else { createLock() }
                        
                        Text("Score: \(score)").padding(.bottom)
                        CountdownTimerView()  // except use a CountdownTimerView instead of a SpeedrunClockView since this one has to count down instead of up and has slightly different text
                    } else {  // game is over: modified end screen — this time, report the user's score instead of time for this mode
                        Text("Finished!").animation(.easeInOut(duration: 1.5)).padding(.bottom).font(.system(size: 75, weight: .bold, design: .default))
                        Text("Score: \(score)").animation(.easeInOut(duration: 2.5)).padding(.top).font(.system(size: 38, weight: .semibold, design: .default))
                        // check whether their score this game was a highscore or not; if yes, display as such and show the amount of improvement
                        if score > prevBestScore {
                            Text("New highscore!").padding(.top).font(.system(size: 26))
                            Text("Improved by \(score-prevBestScore)").padding(.top)
                        } else { Text("Highscore: \(prevBestScore)").padding(.top) }  // if it was not a highscore, remind the player of their high score, similarly to Speedrun Mode
                        
                        Button("Back to Mode Select", action: {score = 0; self.timeUp = false; lockGroup = 1; self.started = false}).padding(.top)  // same logic as before
                    }
                } else if mode == .ChessClock {
                    if !chessClockTimer.chessClockTimeUp {
                        if roundFinished { animate() }
                        else {update()}
                        if sequenceLength < 6 { ChessClockTimerView(timeController: chessClockTimer) }
                        else { ChessClockTimerView(timeController: chessClockTimer).offset(y: -45) }
                    } else {
                        Text("Finished!")
                        Text("Survived for \(roundNum) rounds")
                        if roundNum > ccPrevBest {
                            Text("New Highscore!")
                            Text("Improved by \(roundNum-ccPrevBest) rounds")
                        } else {
                            Text("Highscore: \(ccPrevBest)")
                        }
                    }
                }
            }
        }
    }
    
    // function that handles game start tasks for Speedrun Mode
    func startSpeedrun() {
        startTime = Date.timeIntervalSinceReferenceDate  // set start time to the current time since the epoch
        prevBestTime = UserDefaults.standard.double(forKey: "speedrun\(scoreSelection)Time")  // retrieve the previous best time from UserDefaults and store it
        mode = .Speedrun  // set the game mode
        switch scoreSelection {  // decide the lock upgrade score thresholds based on the selected "category"
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
            default: break  // will never happen
        }
        self.started = true  // start the game; this is a state variable so this toggle triggers a view refresh which begins rendering locks
    }
    
    // function that handles game start tasks for Countdown Mode
    func startCountdown() {
        startTime = Date.timeIntervalSinceReferenceDate  // similar logic to above for start time and retrieving highscores
        prevBestScore = UserDefaults.standard.integer(forKey: "countdown\(timeSelection)Score")
        mode = .Countdown  // set the game mode
        switch timeSelection {  // decide the lock upgrade thresholds, this time based on the selected time category
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
            default: break  // same as the function above, will never happen
        }
        // create the timer with time interval decided by the selected category which, when completed, will trigger the end of the game
        _ = Timer.scheduledTimer(withTimeInterval: timeSelection, repeats: false, block: {_ in
            self.timeUp = true  // will immediately trigger a view refresh onto the end screen
            if score > prevBestScore { UserDefaults.standard.set(score, forKey: "countdown\(timeSelection)Score") }  // update the highscore if the user got one
        })
        self.started = true  // finally, after the setup, start the game
    }
    
    func startChessClock() {
        ccPrevBest = UserDefaults.standard.integer(forKey: "chessClock")
        mode = .ChessClock
        createSequence()
        self.started = true
    }
    
    // function that handles the animation of each lock after a gesture is completed and continues the game flow
    func animateLock() -> some View {
        return AnyView(
            VStack {
                Text("a").foregroundColor(.white).font(.system(size: 35))  // same size as the gesture name text to make sure the lock is in the same place in the view for a seamless transition
                // create an animated image with the same size as all our other lock images; set its group from the global variable (or one less if we have just crossed a threshold)
                AnimatedImage(imageSize: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5), group: (upgrades.contains(score) ? lockGroup-1 : lockGroup), lock: currentLock)
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center).aspectRatio(contentMode: .fill).scaleEffect(0.95)  // same as static image
                .onAppear(perform: {  // do not want to change state during view update, so we pass it off to onAppear
                    DispatchQueue.main.asyncAfter(deadline: .now()+0.5, execute: {  // after the animation is completed...
                        if mode == .Speedrun {  // check if the game is over if playing Speedrun Mode
                            if score >= scoreSelection {  // if the player has met the score goal they selected
                                finalTime = String(format: "%.3f", Date.timeIntervalSinceReferenceDate-startTime)  // record the player's final time (also triggers the end screen in the view)
                                if Double(finalTime)! < prevBestTime || prevBestTime == 0.0 {  // if they have a new best time (or if they have never had a time before)
                                    UserDefaults.standard.set(Double(finalTime)!, forKey: "speedrun\(scoreSelection)Time")  // set UserDefaults to reflect their new best
                                }
                            }
                        }
                        self.currentLock = Int.random(in: 1...5)  // choose a new randomly selected lock in the group for the next gesture
                        self.currentGestureDone = false  // re-toggle this flag to begin another gesture cycle
                    })
                })
            }
        )
    }
    
    // function that chooses a lock and returns a view containing that lock along with all necessary gesture recognizers and text
    func createLock() -> some View {
        let num = Int.random(in: 1...2)  // select a random gesture
        // for double/triple tap, pinch, and rotate, use vanilla SwiftUI gestures; when a gesture is completed, we call a small helper function (to avoid too much repetition)
        if num == 1 {
            gestureName = "Double Tap"
            return AnyView(
                VStack {
                    Text(gestureName).font(.system(size: 35))
                    Image("G\(lockGroup)L\(self.currentLock)F1").resizable().aspectRatio(contentMode: .fill).scaleEffect(0.95)
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                        .gesture(TapGesture(count: 2).onEnded{gestureDone()})
                }
            )
        } else if num == 2 {
            gestureName = "Triple Tap"
            return AnyView(
                VStack {
                    Text(gestureName).font(.system(size: 35))
                    Image("G\(lockGroup)L\(self.currentLock)F1").resizable().aspectRatio(contentMode: .fill).scaleEffect(0.95)
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                        .gesture(TapGesture(count: 3).onEnded{gestureDone()})
                }
            )
        } else if num == 3 {
            gestureName = "Rotate"
            return AnyView(
                VStack {
                    Text(gestureName).font(.system(size: 35))
                    Image("G\(lockGroup)L\(self.currentLock)F1").resizable().aspectRatio(contentMode: .fill).scaleEffect(0.95)
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                        .gesture(RotationGesture().onEnded{_ in gestureDone()})
                }
            )
        } else if num == 4 {
            gestureName = "Pinch"
            return AnyView(
                VStack {
                    Text(gestureName).font(.system(size: 35))
                    Image("G\(lockGroup)L\(self.currentLock)F1").resizable().aspectRatio(contentMode: .fill).scaleEffect(0.95)
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                        .gesture(MagnificationGesture().onEnded{_ in gestureDone()})
                }
            )
        // for all the rest of the gestures, create a LockView and pass it either a TappableView, DraggableView, LongPressableView, or PannableView with appropriate parameters for the gesture
        } else if num == 5 {
            gestureName = "Two Finger Tap"
            return AnyView(LockView(tap: TappableView(touches: 2, taps: 1, tappedCallback: {(_, _) in gestureDone()}), drag: nil, longPress: nil, currentLock: self.currentLock))
        } else if num == 6 {
            gestureName = "Three Finger Tap"
            return AnyView(LockView(tap: TappableView(touches: 3, taps: 1, tappedCallback: {(_, _) in gestureDone()}), drag: nil, longPress: nil, currentLock: self.currentLock))
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
            return AnyView(LockView(tap: nil, drag: nil, longPress: nil, pan: PannableView(edge: .right, pannedCallback: {(_, _) in gestureDone()}), currentLock: self.currentLock))
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
    
    // small helper function that handles tasks to do when the gesture is finished — we increment score, check whether to upgrade the lock, and set the done flag
    func gestureDone() {
        score += 1
        if upgrades.contains(score) { lockGroup += 1 }  // if we have reached a predefined score threshold
        self.currentGestureDone = true
    }
    
    // ------------ chess clock mode functions ------------
    
    // TODO for chess clock mode, in order of priority
    // 1. once migrated to glyphs, switch this mode over to that and make the gestures "light up" in sequence as they are completed
    // 2. add categories (e.g. smaller or larger time bonuses, faster ramping, etc)
    // 3. add special locks (e.g. time freeze/slow, time bonus, etc)
    
    func createSequence() {
        if Int.random(in: 1...4) == 1 && sequenceLength <= 10 { sequenceLength += 1 }
        
        var gestures: [Int] = []
        for _ in 1...sequenceLength {
            gestures.append(Int.random(in: 1...5))
        }
        var gestureViews: [AnyView] = []
        for id in gestures {
            switch id {
                case 1: gestureViews.append(AnyView(TappableView(touches: 1, taps: 2, tappedCallback: {(_, _) in advanceSequence()}))); sequenceText += "2t "; break;
                case 2: gestureViews.append(AnyView(TappableView(touches: 1, taps: 3, tappedCallback: {(_, _) in advanceSequence()}))); sequenceText += "3t "; break;
                case 3: gestureViews.append(AnyView(RotatableView(rotatedCallback: {(_, _) in advanceSequence()}))); sequenceText += "rot "; break;
                case 4: gestureViews.append(AnyView(PinchableView(pinchedCallback: {(_, _) in advanceSequence()}))); sequenceText += "mag "; break;
                case 5: gestureViews.append(AnyView(TappableView(touches: 2, taps: 1, tappedCallback: {(_, _) in advanceSequence()}))); sequenceText += "2ft "; break;
                case 6: gestureViews.append(AnyView(TappableView(touches: 3, taps: 1, tappedCallback: {(_, _) in advanceSequence()}))); sequenceText += "3ft "; break;
                case 7: gestureViews.append(AnyView(DraggableView(direction: .left, touches: 1, draggedCallback: {(_, _) in advanceSequence()}))); sequenceText += "ls "; break;
                case 8: gestureViews.append(AnyView(DraggableView(direction: .right, touches: 1, draggedCallback: {(_, _) in advanceSequence()}))); sequenceText += "rs "; break;
                case 9: gestureViews.append(AnyView(DraggableView(direction: .up, touches: 1, draggedCallback: {(_, _) in advanceSequence()}))); sequenceText += "us "; break;
                case 10: gestureViews.append(AnyView(DraggableView(direction: .down, touches: 1, draggedCallback: {(_, _) in advanceSequence()}))); sequenceText += "ds "; break;
                case 11: gestureViews.append(AnyView(DraggableView(direction: .left, touches: 2, draggedCallback: {(_, _) in advanceSequence()}))); sequenceText += "2ls "; break;
                case 12: gestureViews.append(AnyView(DraggableView(direction: .right, touches: 2, draggedCallback: {(_, _) in advanceSequence()}))); sequenceText += "2rs "; break;
                case 13: gestureViews.append(AnyView(DraggableView(direction: .up, touches: 2, draggedCallback: {(_, _) in advanceSequence()}))); sequenceText += "2us "; break;
                case 14: gestureViews.append(AnyView(DraggableView(direction: .down, touches: 2, draggedCallback: {(_, _) in advanceSequence()}))); sequenceText += "2ds "; break;
                case 15: gestureViews.append(AnyView(LongPressableView(touches: 1, pressedCallback: {(_, _) in advanceSequence()}))); sequenceText += "lp "; break;
                case 16: gestureViews.append(AnyView(LongPressableView(touches: 2, pressedCallback: {(_, _) in advanceSequence()}))); sequenceText += "2lp "; break;
                case 17: gestureViews.append(AnyView(LongPressableView(touches: 3, pressedCallback: {(_, _) in advanceSequence()}))); sequenceText += "3lp "; break;
                case 18: gestureViews.append(AnyView(PannableView(edge: .left, pannedCallback: {(_, _) in advanceSequence()}))); sequenceText += "lep "; break;
                case 19: gestureViews.append(AnyView(PannableView(edge: .right, pannedCallback: {(_, _) in advanceSequence()}))); sequenceText += "rep "; break;
                case 20: gestureViews.append(AnyView(DraggableView(direction: .left, touches: 3, draggedCallback: {(_, _) in advanceSequence()}))); sequenceText += "3ls "; break;
                case 21: gestureViews.append(AnyView(DraggableView(direction: .right, touches: 3, draggedCallback: {(_, _) in advanceSequence()}))); sequenceText += "3rs "; break;
                case 22: gestureViews.append(AnyView(DraggableView(direction: .up, touches: 3, draggedCallback: {(_, _) in advanceSequence()}))); sequenceText += "3us "; break;
                case 23: gestureViews.append(AnyView(DraggableView(direction: .down, touches: 3, draggedCallback: {(_, _) in advanceSequence()}))); sequenceText += "3ds "; break;
                default: break;
            }
        }
        currentRound = gestureViews
        sequenceText.removeLast()
    }
    
    func advanceSequence() {
        if currentPosition == sequenceLength-1 {
            roundNum += 1
            sequenceText = ""
            self.roundFinished = true
        }
        else {
            self.currentPosition += 1
        }
    }
    
    // TODO refactor this method to make it cleaner with an array of offsets
    func update() -> some View {
        let currGestureView = currentRound[currentPosition]
        let gestureSequence = sequenceText.split(separator: " ")
//        let currGestureName = gestureSequence[currentPosition]
        return AnyView(
            VStack {
//                Text(sequenceText)
//                Text(String(currentPosition) + " " + currGestureName)
                if gestureSequence.count < 6 {
                    HStack(spacing: 0) {
                        GestureImageView(active: currentPosition == 0, name: gestureSequence[0])
                        GestureImageView(active: currentPosition == 1, name: gestureSequence[1])
                        GestureImageView(active: currentPosition == 2, name: gestureSequence[2])
                        if gestureSequence.count > 3 {
                            GestureImageView(active: currentPosition == 3, name: gestureSequence[3])
                            if gestureSequence.count > 4 {
                                GestureImageView(active: currentPosition == 4, name: gestureSequence[4])
                            }
                        }
                    }.offset(y: 45).zIndex(5)
                    ZStack {
                        Image("G\(ccLockGroup)L\(ccLockNum)F1").resizable().aspectRatio(contentMode: .fill).scaleEffect(0.95)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                        currGestureView.aspectRatio(contentMode: .fill).scaleEffect(0.95).frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center).foregroundColor(.red)
                    }.offset(y: 30)
                    Text("Round \(roundNum)").offset(y: 10)
                }
                if gestureSequence.count > 5 {
                    HStack(spacing: 0) {
                        GestureImageView(active: currentPosition == 0, name: gestureSequence[0])
                        GestureImageView(active: currentPosition == 1, name: gestureSequence[1])
                        GestureImageView(active: currentPosition == 2, name: gestureSequence[2])
                        if gestureSequence.count > 3 {
                            GestureImageView(active: currentPosition == 3, name: gestureSequence[3])
                            if gestureSequence.count > 4 {
                                GestureImageView(active: currentPosition == 4, name: gestureSequence[4])
                            }
                        }
                    }.offset(y: 70).zIndex(5)
                    HStack(spacing: 0) {
                        GestureImageView(active: currentPosition == 5, name: gestureSequence[5])
                        if gestureSequence.count > 6 {
                            GestureImageView(active: currentPosition == 6, name: gestureSequence[6])
                            if gestureSequence.count > 7 {
                                GestureImageView(active: currentPosition == 7, name: gestureSequence[7])
                                if gestureSequence.count > 8 {
                                    GestureImageView(active: currentPosition == 8, name: gestureSequence[8])
                                    if gestureSequence.count > 9 {
                                        GestureImageView(active: currentPosition == 9, name: gestureSequence[9])
                                    }
                                }
                            }
                        }
                    }.offset(y: 70).zIndex(5)
                    ZStack {
                        Image("G\(ccLockGroup)L\(ccLockNum)F1").resizable().aspectRatio(contentMode: .fill).scaleEffect(0.95)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                        currGestureView.aspectRatio(contentMode: .fill).scaleEffect(0.95).frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center).foregroundColor(.red)
                    }.offset(y: -5)
                    Text("Round \(roundNum)").offset(y: -35)
                }
                
            }
        )
    }
    
    func animate() -> some View {
        var offsets: [CGFloat] = [70, -5, -35]
        if sequenceLength < 6 { offsets = [45, 30, 10] }
        return AnyView(
            VStack {
                GestureImageView(active: false, name: Substring("blank256")).offset(y: offsets[0]).zIndex(5)
                if sequenceLength > 5 { GestureImageView(active: false, name: Substring("blank256")).offset(y: offsets[0]).zIndex(5) }
                AnimatedImage(imageSize: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5), group: ccLockGroup, lock: ccLockNum)
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center).aspectRatio(contentMode: .fill).scaleEffect(0.95)
                .onAppear(perform: {
                    DispatchQueue.main.asyncAfter(deadline: .now()+0.5, execute: {
                        ccLockNum = Int.random(in: 1...5)
                        if [3, 8, 14, 21, 30, 37, 45, 56, 69].contains(roundNum) { ccLockGroup += 1 }
                        chessClockTime += 6.00
                        createSequence()
                        currentPosition = 0
                        roundFinished = false
                    })
                }).offset(y: offsets[1])
                Text("c").foregroundColor(.white).offset(y: offsets[2])
            }
        )
    }
    
    class TimerProgress: ObservableObject {
        @Published var chessClockTimeUp = false
    }
    
    struct ChessClockTimerView: View {
        @State var timeLeft = 10.00
        @ObservedObject var timeController: TimerProgress
        
        let timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
        
        var body: some View {
            Text(String(format: "%.2f seconds remaining", timeLeft))
                .onReceive(timer, perform: { _ in advanceTime() }).padding(.top).frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/8, alignment: .center)
        }
        
        func advanceTime() {
            if chessClockTime != timeLeft { timeLeft = chessClockTime }
            if timeLeft > 0.01 { timeLeft -= 0.01; chessClockTime -= 0.01 }
            else { chessClockOver = true; timeController.chessClockTimeUp = true; if roundNum > ccPrevBest {UserDefaults.standard.setValue(roundNum, forKey: "chessClock")} }
        }
    }
    
    struct GestureImageView: View {
        var active: Bool
        var name: Substring
        
        var body: some View {
            if active { Image("A-\(name)").resizable().aspectRatio(contentMode: .fill).frame(width: UIScreen.main.bounds.width/5, height: UIScreen.main.bounds.width/5, alignment: .center) }
            else { Image("\(name)").resizable().aspectRatio(contentMode: .fill).frame(width: UIScreen.main.bounds.width/5, height: UIScreen.main.bounds.width/5, alignment: .center) }
        }
    }
    
    // ------------ end chess clock mode functions ------------
    
    // Auxiliary view that stores the gesture label, lock image, and gesture recognizer for a single lock
    struct LockView: View {
        var tap: TappableView?  // if this lock has a TapGesture
        var drag: DraggableView?  // if this lock has a DragGesture
        var longPress: LongPressableView?  // if this lock has a LongPressGesture
        var pan: PannableView?  // if this lock has a ScreenEdgePanGesture
        var currentLock: Int  // have to abstract this out
        
        var body: some View {
            VStack {  // align the text and image vertically
                Text(gestureName).font(.system(size: 35))
                ZStack {  // the gesture recognizer is directly on top of the lock, so its entire area can receive gesture events
                    Image("G\(lockGroup)L\(self.currentLock)F1").resizable().aspectRatio(contentMode: .fill).scaleEffect(0.95)
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)  // create the same aspect ratio and frame for each element
                    if tap != nil { tap.aspectRatio(contentMode: .fill).frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center) }
                    else if drag != nil { drag.aspectRatio(contentMode: .fill).frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center) }
                    else if longPress != nil { longPress.aspectRatio(contentMode: .fill).frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center) }
                    else if pan != nil { pan.aspectRatio(contentMode: .fill).frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center) }
                }
            }
        }
    }
}

// debug purposes only
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
