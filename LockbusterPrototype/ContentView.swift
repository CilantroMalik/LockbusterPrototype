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

enum CCDifficulty {
    case Standard
    case Hard
    case Expert
}

// --- auxiliary views ---
/// AnimatedImage: stores an animated image composed of a number of individual frames (using UIImageView, which has this functionality built in)
/// Essentially a UIView wrapped in UIViewRepresentable so it can be compatible with SwiftUI. Has a set duration and extracts the frames of animation from the assets.
struct AnimatedImage: UIViewRepresentable {
    // take in image size as a parameter, as well as identifiers for the lock we want to animate
    let imageSize: CGSize
    let group: Int
    let lock: Int
    let duration: Double

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
                if timeLeft > 0 && !isFrozen { timeLeft -= 0.01 }
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
var difficulty: CCDifficulty = .Standard
var increment = 6.00
var rampingChance = 0.25
var isFrozen: Bool = false
var frozenDuration = 5.00
var timeFrozen = 0.00
var isFreezeRound = false

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
    @ObservedObject var chessClockTimer = TimerProgress()
    
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
                Text("Select a difficulty:").padding(.bottom)
                HStack {
                    Button("Standard", action: { difficulty = .Standard; startChessClock() } ).font(.system(size: 20, weight: .bold, design: .rounded)).padding(.trailing)
                    Button("Hard", action: { difficulty = .Hard; startChessClock() } ).font(.system(size: 20, weight: .bold, design: .rounded)).padding(.leading).padding(.trailing)
                    Button("Expert", action: { difficulty = .Expert; startChessClock() } ).font(.system(size: 20, weight: .bold, design: .rounded)).padding(.leading)
                }
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
                        Text("Finished!").animation(.easeInOut(duration: 1.5)).padding(.bottom).font(.system(size: 75, weight: .bold, design: .default))
                        Text("Survived until round \(roundNum)").animation(.easeInOut(duration: 2.5)).padding(.top).font(.system(size: 33, weight: .semibold, design: .default))
                        if roundNum > ccPrevBest {
                            Text("New highscore!").padding(.top).font(.system(size: 26))
                            Text("Improved by \(roundNum-ccPrevBest)").padding(.top)
                        } else { Text("Highest round: \(ccPrevBest)").padding(.top) }
                        
                        Button("Back to Mode Select", action: {sequenceLength = 3; roundNum = 1; currentRound = []; sequenceText = ""; chessClockTime = 10.00; ccLockGroup = 1; chessClockTimer.chessClockTimeUp.toggle(); self.started = false}).padding(.top)
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
    
    // function that handles game start tasks for Chess Clock Mode
    func startChessClock() {
        switch difficulty {  // change various game parameters according to difficulty setting: currently, time gained upon completing a lock, chance of increasing gesture count per lock, and duration of freeze lock
            // also retrieve the relevant highscore from disk
            case .Standard: increment = 6; rampingChance = 0.25; frozenDuration = 5.00; ccPrevBest = UserDefaults.standard.integer(forKey: "chessClockStandard"); break
            case .Hard: increment = 5.5; rampingChance = 0.3; frozenDuration = 4.50; ccPrevBest = UserDefaults.standard.integer(forKey: "chessClockHard"); break
            case .Expert: increment = 4.75; rampingChance = 0.37; frozenDuration = 3.75; ccPrevBest = UserDefaults.standard.integer(forKey: "chessClockExpert"); break
        }
        mode = .ChessClock  // set the game mode
        createSequence()  // create the first gesture sequence and initialize the list of gestures in preparation for starting the game
        self.started = true  // trigger the game to start and the view to refresh
    }
    
    // function that handles the animation of each lock after a gesture is completed and continues the game flow
    func animateLock() -> some View {
        return AnyView(
            VStack {
                Text("a").foregroundColor(.white).font(.system(size: 35))  // same size as the gesture name text to make sure the lock is in the same place in the view for a seamless transition
                // create an animated image with the same size as all our other lock images; set its group from the global variable (or one less if we have just crossed a threshold)
                AnimatedImage(imageSize: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5), group: gestureName == "Freeze Lock!" ? 11 : (upgrades.contains(score) ? lockGroup-1 : lockGroup), lock: gestureName == "Freeze Lock!" ? 1 : currentLock, duration: 0.45)
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
        if mode == .Countdown && Int.random(in: 1...2) == 1 {
            gestureName = "Freeze Lock!"
            startTime += 5.00
            return AnyView(
                VStack {
                    Text(gestureName).font(.system(size: 35))
                    Image("G11L1F1").resizable().aspectRatio(contentMode: .fill).scaleEffect(0.95)
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                        .gesture(TapGesture(count: 5).onEnded{ isFrozen = true; DispatchQueue.main.asyncAfter(deadline: .now()+5, execute: {isFrozen = false}); gestureDone() })
                }
            )
        }
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
    // 1. add tooltips in menu screen to explain the modes & categories
    
    // function that chooses a sequence of gestures for one round of chess clock mode and adds the relevant gesture views to a central array
    func createSequence() {
        if Int.random(in: 1...2) == 1 {  // if some random chance is hit, override the current round with a single freeze lock
            currentRound = [AnyView(TappableView(touches: 1, taps: 5, tappedCallback: {(_, taps) in advanceFrozen(numTaps: taps)}))]
            sequenceText = "frz"  // reflect this in the sequence text
            isFreezeRound = true  // set the relevant flag
            return  // we do not want to go through the normal round creation process
        }
        
        if Double.random(in: 0..<1) <= rampingChance && sequenceLength < 10 { sequenceLength += 1 }  // roll a random chance for the predetermined probability and if it hits, increase the round length
        
        var gestures: [Int] = []
        for _ in 1...sequenceLength {
            gestures.append(Int.random(in: 1...3))  // create an array of random numbers in the range of the number of gestures, which will be used to select the gestures
        }
        var gestureViews: [AnyView] = []
        for id in gestures {
            switch id {  // large switch statement that appends the relevant gesture for each randomly selected number
                // each gesture calls the relevant callback function and adds to the sequence text which will eventually be used to generate the glyphs
                case 1: gestureViews.append(AnyView(TappableView(touches: 1, taps: 2, tappedCallback: {(_, taps) in advanceFrozen(numTaps: taps)}))); sequenceText += "2t "; break;
                case 2: gestureViews.append(AnyView(TappableView(touches: 1, taps: 3, tappedCallback: {(_, taps) in advanceFrozen(numTaps: taps)}))); sequenceText += "3t "; break;
                case 3: gestureViews.append(AnyView(RotatableView(rotatedCallback: {(_, _) in advanceSequence()}))); sequenceText += "rot "; break;
                case 4: gestureViews.append(AnyView(PinchableView(pinchedCallback: {(_, _) in advanceSequence()}))); sequenceText += "mag "; break;
                case 5: gestureViews.append(AnyView(TappableView(touches: 2, taps: 1, tappedCallback: {(_, _) in advanceSequence()}))); sequenceText += "2ft "; break;
                case 6: gestureViews.append(AnyView(TappableView(touches: 3, taps: 1, tappedCallback: {(_, _) in advanceSequence()}))); sequenceText += "3ft "; break;
                case 7: gestureViews.append(AnyView(DraggableView(direction: .left, touches: 1, draggedCallback: {(_, _) in advanceSequence()}))); sequenceText += "ls "; break;
                case 8: gestureViews.append(AnyView(DraggableView(direction: .right, touches: 1, draggedCallback: {(_, _) in advanceSequence()}))); sequenceText += "rs "; break;
                case 9: gestureViews.append(AnyView(DraggableView(direction: .up, touches: 1, draggedCallback: {(_, _) in advanceSequence()}))); sequenceText += "us "; break;
                case 10: gestureViews.append(AnyView(DraggableView(direction: .down, touches: 1, draggedCallback: {(_, _) in advanceSequence()}))); sequenceText += "ds "; break;
                case 11: gestureViews.append(AnyView(DraggableView(direction: .left, touches: 2, draggedCallback: {(_, _) in advanceSequence()}))); sequenceText += "2fls "; break;
                case 12: gestureViews.append(AnyView(DraggableView(direction: .right, touches: 2, draggedCallback: {(_, _) in advanceSequence()}))); sequenceText += "2frs "; break;
                case 13: gestureViews.append(AnyView(DraggableView(direction: .up, touches: 2, draggedCallback: {(_, _) in advanceSequence()}))); sequenceText += "2fus "; break;
                case 14: gestureViews.append(AnyView(DraggableView(direction: .down, touches: 2, draggedCallback: {(_, _) in advanceSequence()}))); sequenceText += "2fds "; break;
                case 15: gestureViews.append(AnyView(LongPressableView(touches: 1, pressedCallback: {(_, _) in advanceSequence()}))); sequenceText += "lp "; break;
                case 16: gestureViews.append(AnyView(LongPressableView(touches: 2, pressedCallback: {(_, _) in advanceSequence()}))); sequenceText += "2flp "; break;
                case 17: gestureViews.append(AnyView(LongPressableView(touches: 3, pressedCallback: {(_, _) in advanceSequence()}))); sequenceText += "3flp "; break;
                case 18: gestureViews.append(AnyView(PannableView(edge: .left, pannedCallback: {(_, _) in advanceSequence()}))); sequenceText += "lep "; break;
                case 19: gestureViews.append(AnyView(PannableView(edge: .right, pannedCallback: {(_, _) in advanceSequence()}))); sequenceText += "rep "; break;
                case 20: gestureViews.append(AnyView(DraggableView(direction: .left, touches: 3, draggedCallback: {(_, _) in advanceSequence()}))); sequenceText += "3fls "; break;
                case 21: gestureViews.append(AnyView(DraggableView(direction: .right, touches: 3, draggedCallback: {(_, _) in advanceSequence()}))); sequenceText += "3frs "; break;
                case 22: gestureViews.append(AnyView(DraggableView(direction: .up, touches: 3, draggedCallback: {(_, _) in advanceSequence()}))); sequenceText += "3fus "; break;
                case 23: gestureViews.append(AnyView(DraggableView(direction: .down, touches: 3, draggedCallback: {(_, _) in advanceSequence()}))); sequenceText += "3fds "; break;
                default: break;  // will never occur
            }
        }
        currentRound = gestureViews  // set the global variable so other areas of the program can access it
        sequenceText.removeLast()  // remove trailing space from sequence text
    }
    
    // function that handles tasks to be done in betwen gestures in a single sequence; used as the callback for the gesture handlers
    func advanceSequence() {
        if isFreezeRound {  // if this is a freeze lock, the round length is 1 no matter what the sequenceLength variable says, so just end the round now
            roundFinished = true
            return
        }
        if currentPosition == sequenceLength-1 {  // if we have reached the end of a normal round, move onto the next one
            roundNum += 1  // increment the round counter
            sequenceText = ""  // clear the gesture sequence
            self.roundFinished = true  // and set the flag that will trigger a view refresh and thereby a new call to createSequence()
        }
        else {
            self.currentPosition += 1  // if it isn't the end of a round, just advance the current position (this triggers a view update as well to show the next gesture)
        }
    }
    
    // function that acts as a callback for the tap gestures only and is a wrapper to the above
    func advanceFrozen(numTaps: Int) {
        if numTaps == 5 { timeFrozen = 0.00; isFrozen = true }  // for tap gestures, we need to do an additional check to see if it was a freeze lock, and if so we activate the "frozen" state
        advanceSequence()  // if not, just proceed as normal with other tasks
    }
    
    // function that handles updating of the view with the currently displaying lock and gesture sequence
    func update() -> some View {
        var offsets: [CGFloat] = [70, -5, -35]  // position offsets for the UI elements
        if sequenceLength < 6 { offsets = [45, 30, 10] }  // will change if there are only one row of gestures (5 or less)
        let currGestureView = currentRound[currentPosition]  // get the gesture that should currently be active
        let gestureSequence = sequenceText.split(separator: " ")  // split the sequence text that we built up while creating a sequence into its individual gesture codes
        return AnyView(
            VStack {  // vertically align all the UI elements
                HStack(spacing: 1) {  // first row of gestures
                    GestureImageView(active: currentPosition == 0, name: gestureSequence[0])  // check if the current position equals each gesture's position, and if so, make it active (blue)
                    if gestureSequence.count > 1 {  // for every successive gesture, check if we should even display that gesture, based on the sequence length
                        GestureImageView(active: currentPosition == 1, name: gestureSequence[1])
                        if gestureSequence.count > 2 {
                            GestureImageView(active: currentPosition == 2, name: gestureSequence[2])
                            if gestureSequence.count > 3 {
                                GestureImageView(active: currentPosition == 3, name: gestureSequence[3])
                                if gestureSequence.count > 4 {
                                    GestureImageView(active: currentPosition == 4, name: gestureSequence[4])
                                }
                            }
                        }
                    }
                }.offset(y: offsets[0]).zIndex(5)  // offset by the specified amount and make sure the gestures display highest on the Z-axis so they do not get overlapped
                if gestureSequence.count > 5 {  // if there is a second row of gestures, just make the same HStack but now for gestures 6-10
                    HStack(spacing: 1) {
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
                    }.offset(y: offsets[0]).zIndex(5)
                }
                ZStack {  // show the lock image itself
                    // for every image, show group 11 lock 1 for freeze otherwise the current group and lock from the global variables. set aspect ratio so it looks normal on the screen
                    Image("G\(sequenceText.contains("frz") ? 11 : ccLockGroup)L\(sequenceText.contains("frz") ? 1 : ccLockNum)F1").resizable().aspectRatio(contentMode: .fill).scaleEffect(0.95)
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                    // show the gesture view in the exact same place as the image, with the same resizing parameters and frame
                    currGestureView.aspectRatio(contentMode: .fill).scaleEffect(0.95).frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center)
                }.offset(y: offsets[1])  // offset this by the second of the specified offsets
                Text("Round \(roundNum)").offset(y: offsets[2])  // finally, display the round number and offset it by the last value in the offsets array
            }
        )
    }
    
    // function that handles the animation of a lock once a gesture sequence is complete, and the creation of a new round and new lock
    func animate() -> some View {
        let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)  // give haptic feedback upon completing a round
        impactHeavy.impactOccurred()
        impactHeavy.impactOccurred()
        var offsets: [CGFloat] = [70, -5, -35]  // exact same offset scheme as above to create a seamless switching between views
        if sequenceLength < 6 { offsets = [45, 30, 10] }
        return AnyView(
            VStack {  // same layout but with many placeholders
                GestureImageView(active: false, name: Substring("blank256")).offset(y: offsets[0]).zIndex(5)  // put a dummy gesture view to stand in place of the first row of gestures
                if sequenceLength > 5 { GestureImageView(active: false, name: Substring("blank256")).offset(y: offsets[0]).zIndex(5) }  // if the second row of gestures exists, draw another one
                AnimatedImage(imageSize: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5), group: sequenceText.contains("frz") ? 11 : ccLockGroup, lock: sequenceText.contains("frz") ? 1 : ccLockNum, duration: 0.4)  // draw the animated lock with the same lock group and number as the one that was just on the screen
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/1.5, alignment: .center).aspectRatio(contentMode: .fill).scaleEffect(0.95)  // same layout as well
                .onAppear(perform: {  // we do all the state updating in onAppear so the view does not update state while refreshing itself
                    DispatchQueue.main.asyncAfter(deadline: .now()+0.43, execute: {  // slight delay after the animation is complete
                        sequenceText = ""  // reset sequence text
                        isFreezeRound = false  // reset this flag in case it was changed
                        ccLockNum = Int.random(in: 1...5)  // choose a random new lock
                        if [3, 8, 14, 21, 30, 37, 45, 56, 69].contains(roundNum) { ccLockGroup += 1 }  // if we have reached one of the upgrade points, increase the lock group as well
                        chessClockTime += increment  // add the specified increment to the timer since the round is done
                        createSequence()  // begin the creation of a new round
                        currentPosition = 0  // reset the position to the first gesture for the new round
                        self.roundFinished = false  // finally, mark the relevant flag; this triggers a view update that will reflect all the new changes
                    })
                }).offset(y: offsets[1])  // use the relevant offset
                Text("c").foregroundColor(.white).offset(y: offsets[2])  // same as before, make placeholder text with the same offset as in the update() view to preserve layout consistency
            }
        )
    }
    
    /// TimerProgress: class that keeps track of when the chess clock timer has run out
    class TimerProgress: ObservableObject {
        @Published var chessClockTimeUp = false
    }
    
    /// ChessClockTimerView: struct that defines a view that holds the timer for chess clock mode
    struct ChessClockTimerView: View {
        @State var timeLeft = 10.00  /// Stores how much time is left on the clock
        @ObservedObject var timeController: TimerProgress  /// Stores a TimerProgress instance that prescribes when the time is up
        
        let timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()  // every 0.01s, update the timer
        
        var body: some View {
            if isFrozen {  // for a freeze lock, we want to show the time in blue to give a visual cue that the clock is frozen
                Text(String(format: "%.2f seconds remaining", timeLeft))
                    .onReceive(timer, perform: { _ in advanceTime() }).padding(.top).frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/8, alignment: .center).foregroundColor(.blue)
            } else {  // for normal lock, just display the text normally, and when we receive an event from the timer, advance the time
                Text(String(format: "%.2f seconds remaining", timeLeft))
                    .onReceive(timer, perform: { _ in advanceTime() }).padding(.top).frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/8, alignment: .center)
            }
        }
        
        // function that handles tasks to advance the timer
        func advanceTime() {
            if chessClockTime != timeLeft { timeLeft = chessClockTime }  // if the times get out of sync (this happens after an increment) correct this struct's internal variable with the global variable's value
            // if there is time left, decrement the timer (both the instance and global variables); if we are frozen, increment the time frozen and if we are done with the frozen period, set the flag as such and resume decrementing the timer as normal
            if timeLeft > 0.01 { if !isFrozen { timeLeft -= 0.01; chessClockTime -= 0.01 } else { timeFrozen += 0.01; if timeFrozen >= frozenDuration { isFrozen = false } } }
            // if time is up, set the relevant flags (the TimerProgress instance will publish the change to the view and trigger an update) and then handle highscore setting for the appropriate difficulty if a highscore was achieved
            else { chessClockOver = true; timeController.chessClockTimeUp = true; if roundNum > ccPrevBest { UserDefaults.standard.setValue(roundNum, forKey: difficulty == .Standard ? "chessClockStandard" : (difficulty == .Hard ? "chessClockHard" : "chessClockExpert")) } }
        }
    }
    
    /// GestureImageView: struct that defines a view that holds a gesture glyph
    struct GestureImageView: View {
        var active: Bool  /// is this glyph currently active?
        var name: Substring  /// the short name for this glyph; will be spliced from sequenceText so it is stored as a Substring to avoid having to make a type conversion
        
        var body: some View {
            // if the glyph is active, pick the active version of the glyph corresponding to the gesture codename and align it in all the standard ways
            if active { Image("A-\(name)").resizable().aspectRatio(contentMode: .fill).frame(width: UIScreen.main.bounds.width/5.25, height: UIScreen.main.bounds.width/5.25, alignment: .center) }
            // if it is not active, do the same thing but instead choose the non-active version
            else { Image("\(name)").resizable().aspectRatio(contentMode: .fill).frame(width: UIScreen.main.bounds.width/5.25, height: UIScreen.main.bounds.width/5.25, alignment: .center) }
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
