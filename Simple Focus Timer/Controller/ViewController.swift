//
//  ViewController.swift
//  Simple Focus Timer
//
//  Created by Daniel Husiuk on 11.07.2024.
//

import UIKit
import AVFoundation
import UserNotifications

class ViewController: UIViewController {
    
    @IBOutlet weak var TimeLabelOutlet: UILabel!
    @IBOutlet weak var LetsLabelOutlet: UILabel!
    @IBOutlet weak var ProgressBarOutlet: ProgressBar!
    
    @IBOutlet weak var StartButtonOutlet: UIButton!
    @IBOutlet weak var PauseButtonOutlet: UIButton!
    @IBOutlet weak var StopButtonOutlet: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        removeTextButtons()
        configureNotification()
        
        remainingSeconds = totalSeconds["Work"]!
        updateTimerLabel()
        
        self.PauseButtonOutlet.alpha = 0.0
        self.StopButtonOutlet.alpha = 0.0
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    
    
    // MARK: - Notifications Permission
    
    func configureNotification() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("Notification permission granted.")
            } else {
                print("Notification permission denied.")
            }
        }
    }
    
    func workNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Focus time is done!"
        content.body = "Time to have a rest"
        content.sound = UNNotificationSound.default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    func breakNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Rest time is done!"
        content.body = "Let's get back to focus"
        content.sound = UNNotificationSound.default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    
    
    // MARK: - Alert Notification
    
    func alertNotification() {
        let refreshAlert = UIAlertController(title: "Reset timer?", message: "Confirm resetting the timer", preferredStyle: UIAlertController.Style.alert)

        refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action: UIAlertAction!) in
              
        }))

        refreshAlert.addAction(UIAlertAction(title: "Reset", style: .destructive, handler: { (action: UIAlertAction!) in
            self.stopTimer()
        }))

        present(refreshAlert, animated: true, completion: nil)
    }
    
    
    
    // MARK: - Sound Logic
    
    var player: AVAudioPlayer?

    func playSound() {
        guard let path = Bundle.main.path(forResource: "done_sound", ofType:"wav") else {
            return }
        let url = URL(fileURLWithPath: path)

        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.play()
            
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    
    
    // MARK: - Vibration Logic
    
    func playVibration() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    
    
    // MARK: - Background Logic
    
    var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    
    func startBackgroundTask() {
        backgroundTaskID = UIApplication.shared.beginBackgroundTask {
            self.endBackgroundTask()
        }
    }
    
    func endBackgroundTask() {
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        startBackgroundTask()
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        endBackgroundTask()
    }
    
    
    
    // MARK: - Timer Logic
    
    var timer: Timer?
    let totalSeconds = ["Work":25 * 60, "Break":5 * 60]
    var remainingSeconds: Int = 0
    var isTimerRunning = false
    var isTimerPaused = false
    var currentState: timerState = .works
    
    enum timerState {
        case works
        case breaks
    }
    
    func startTimer() {
        isTimerRunning = true
        isTimerPaused = false
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in self.updateTimer() }
        startBackgroundTask()
    }
    
    func pauseTimer() {
        isTimerPaused = true
        timer?.invalidate()
        timer = nil
        endBackgroundTask()
    }
    
    func resumeTimer() {
        isTimerPaused = false
        startTimer()
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
        isTimerRunning = false
        isTimerPaused = false
        remainingSeconds = totalSeconds["Work"]!
        updateTimerLabel()
        updateProgressBar()
        endBackgroundTask()
        
        ProgressBarOutlet.setProgress(progress: 0.001)
        self.StartButtonOutlet.isHidden = false
        self.StartButtonOutlet.alpha = 0.0
        UIView.animate(withDuration: 0.3, animations: {
            self.StartButtonOutlet.alpha = 1.0
            self.PauseButtonOutlet.alpha = 0.0
            self.StopButtonOutlet.alpha = 0.0
        })
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.PauseButtonOutlet.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        }

    }
    
    func updateTimer() {
        remainingSeconds -= 1
        updateTimerLabel()
        updateProgressBar()
        
        if remainingSeconds <= 0 {
            timer?.invalidate()
            timer = nil
            isTimerRunning = false
            isTimerPaused = false
            
            switch currentState {
            case .works:
                currentState = .breaks
                remainingSeconds = totalSeconds["Break"]!
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    UIView.transition(with: self.LetsLabelOutlet, duration: 0.3, options: .transitionCrossDissolve, animations: {
                        self.LetsLabelOutlet.text = "Let's rest!"
                    }, completion: nil)
                    self.playSound()
                    self.playVibration()
                }
                workNotification()
                
            case .breaks:
                currentState = .works
                remainingSeconds = totalSeconds["Work"]!
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    UIView.transition(with: self.LetsLabelOutlet, duration: 0.3, options: .transitionCrossDissolve, animations: {
                        self.LetsLabelOutlet.text = "Let's focus!"
                    }, completion: nil)
                    self.playSound()
                    self.playVibration()
                }
                breakNotification()
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.updateTimerLabel()
                self.ProgressBarOutlet.setProgress(progress: 0.001)
                
                self.StartButtonOutlet.isHidden = false
                self.StartButtonOutlet.alpha = 0.0
                
                UIView.animate(withDuration: 0.3, animations: {
                    self.StartButtonOutlet.alpha = 1.0
                    self.PauseButtonOutlet.alpha = 0.0
                    self.StopButtonOutlet.alpha = 0.0
                })
            }
            
            endBackgroundTask()
        }
    }
    
    func updateTimerLabel() {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        TimeLabelOutlet.text = String(format: "%02d:%02d", minutes, seconds)
    }
    
    
    
    // MARK: - Buttons Logic
    
    func removeTextButtons() {
        StartButtonOutlet.setTitle("", for: .normal)
        PauseButtonOutlet.setTitle("", for: .normal)
        StopButtonOutlet.setTitle("", for: .normal)
    }
    
    @IBAction func StartButtonPressed(_ sender: UIButton) {
        if isTimerRunning && !isTimerPaused {
            return
        }
        if isTimerPaused {
            resumeTimer()
        } else {
            switch currentState {
            case .works:
                remainingSeconds = totalSeconds["Work"]!
                startTimer()
            case .breaks:
                remainingSeconds = totalSeconds["Break"]!
                startTimer()
            }
        }
        
        UIView.animate(withDuration: 0.3, animations: {
            self.StartButtonOutlet.alpha = 0.0
        }) { _ in
            self.StartButtonOutlet.isHidden = true
        }
        
        UIView.animate(withDuration: 0.3, animations: {
            self.PauseButtonOutlet.alpha = 1.0
            self.StopButtonOutlet.alpha = 1.0
        })
    }
    
    @IBAction func PauseButtonPressed(_ sender: UIButton) {
        if isTimerPaused {
            resumeTimer()
            UIView.transition(with: PauseButtonOutlet, duration: 0.2, options: .transitionCrossDissolve, animations: {
                self.PauseButtonOutlet.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            }, completion: nil)
        } else {
            pauseTimer()
            UIView.transition(with: PauseButtonOutlet, duration: 0.2, options: .transitionCrossDissolve, animations: {
                self.PauseButtonOutlet.setImage(UIImage(systemName: "play.fill"), for: .normal)
            }, completion: nil)
        }
    }
    
    @IBAction func StopButtonPressed(_ sender: UIButton) {
        alertNotification()
    }
    
    
    
    // MARK: - Progress Bar Logic

    func updateProgressBar() {
        let progress: CGFloat
        switch currentState {
        case .works:
            progress = CGFloat(totalSeconds["Work"]! - remainingSeconds) / CGFloat(totalSeconds["Work"]!)
        case .breaks:
            progress = CGFloat(totalSeconds["Break"]! - remainingSeconds) / CGFloat(totalSeconds["Break"]!)
        }
        ProgressBarOutlet.setProgress(progress: progress, animated: true)
    }
    
}
