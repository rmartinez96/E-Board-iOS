//
//  SerialViewController.swift
//  HM10 Serial
//
//  Created by Alex on 10-08-15.
//  Copyright (c) 2015 Balancing Rock. All rights reserved.
//
//  Edited by Raul Martinez for Senior Project

import UIKit
import CoreBluetooth
import QuartzCore

import CoreLocation

/// The option to add a \n or \r or \r\n to the end of the send message
enum MessageOption: Int
{
    case noLineEnding,
    newline,
    carriageReturn,
    carriageReturnAndNewline
}

// Global variables
var counter = 0
var timer = Timer()

// The option to add a \n to the end of the received message (to make it more readable)
enum ReceivedMessageOption: Int {
    case none,
    newline
}

// The main window controller
final class SerialViewController: UIViewController, UITextFieldDelegate, CLLocationManagerDelegate, BluetoothSerialDelegate {
    
    // IBOutlets
    
    @IBOutlet weak var mainTextView: UITextView!
    @IBOutlet weak var navItem: UINavigationItem!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var plusButton: UIButton!
    @IBOutlet weak var minusButton: UIButton!
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var currSpeedLabel: UILabel!
    
    let locationManager = CLLocationManager()
    
    // Functions
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        // init serial
        serial = BluetoothSerial(delegate: self)
        
        // Setting up UI
        stopButton.backgroundColor = .clear
        stopButton.layer.borderWidth = 1
        stopButton.layer.borderColor = UIColor.white.cgColor
        stopButton.layer.cornerRadius = 0.1 * stopButton.bounds.size.width
        stopButton.clipsToBounds = true
        
        plusButton.backgroundColor = .clear
        plusButton.layer.borderWidth = 1
        plusButton.layer.borderColor = UIColor.white.cgColor
        plusButton.layer.cornerRadius = 0.1 * plusButton.bounds.size.width
        plusButton.clipsToBounds = true
        
        minusButton.backgroundColor = .clear
        minusButton.layer.borderWidth = 1
        minusButton.layer.borderColor = UIColor.white.cgColor
        minusButton.layer.cornerRadius = 0.1 * minusButton.bounds.size.width
        minusButton.clipsToBounds = true
        
        connectButton.backgroundColor = .clear
        connectButton.layer.borderWidth = 1
        connectButton.layer.borderColor = UIColor.white.cgColor
        connectButton.layer.cornerRadius = 0.1 * connectButton.bounds.size.width
        connectButton.clipsToBounds = true
        
        mainTextView.backgroundColor = .clear
        mainTextView.layer.borderWidth = 1
        mainTextView.layer.borderColor = UIColor.white.cgColor
        mainTextView.layer.cornerRadius = 0.01 * mainTextView.bounds.size.width
        
        mainTextView.text = ""
        reloadView()
        
        NotificationCenter.default.addObserver(self, selector: #selector(SerialViewController.reloadView), name: NSNotification.Name(rawValue: "reloadStartViewController"), object: nil)
        
        // Setting up location services for GPS
        locationManager.delegate = self
        if NSString(string:UIDevice.current.systemVersion).doubleValue > 8
        {
            locationManager.requestAlwaysAuthorization()
        }
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    // Timer for speedometer
    func scheduledTimerWithTimeInterval()
    {
        timer.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.updateCounting), userInfo: nil, repeats: true)
    }
    
    // Updates the speedometer
    func updateCounting()
    {
        //NSLog("running..")
        var speed: CLLocationSpeed = CLLocationSpeed()
        speed = (locationManager.location?.speed)!
        speed = speed * 2.236936284
        currSpeedLabel.text = String(format: "%.1f", speed) + " MPH"
    }
    
    // ??
    deinit
    {
        NotificationCenter.default.removeObserver(self)
    }
    
    // Reloads the main window
    func reloadView() {
        // in case we're the visible view again
        serial.delegate = self
        
        if serial.isReady
        {
            navItem.title = "Status: " + serial.connectedPeripheral!.name! + " Connected"
            connectButton.setTitle("Disconnect", for: .normal)
            connectButton.backgroundColor = UIColor.white
            connectButton.setTitleColor(.black, for: .normal)
            connectButton.isEnabled = true
            counter = 0
            serial.sendMessageToDevice(String(counter))
            locationManager.startUpdatingLocation()
            scheduledTimerWithTimeInterval()
            
        }
        else if serial.centralManager.state == .poweredOn
        {
            navItem.title = "Status: Not Connected"
            connectButton.setTitle("Connect", for: .normal)
            connectButton.backgroundColor = UIColor.clear
            connectButton.setTitleColor(.white, for: .normal)
            connectButton.isEnabled = true
            speedLabel.text = "-----"
            counter = 0
            serial.sendMessageToDevice(String(counter))
            timer.invalidate()
            locationManager.stopUpdatingLocation()
            currSpeedLabel.text = "-----"
            
        }
        else
        {
            navItem.title = "Status: Not Connected"
            connectButton.setTitle("Connect", for: .normal)
            connectButton.backgroundColor = UIColor.clear
            connectButton.setTitleColor(.white, for: .normal)
            connectButton.isEnabled = true
            speedLabel.text = "-----"
            counter = 0
            serial.sendMessageToDevice(String(counter))
            timer.invalidate()
            locationManager.stopUpdatingLocation()
            currSpeedLabel.text = "-----"
        }
    }
    
    // Text scroll for the Arduino log
    func textViewScrollToBottom()
    {
        let range = NSMakeRange(NSString(string: mainTextView.text).length - 1, 1)
        mainTextView.scrollRangeToVisible(range)
    }
    
    
    // BluetoothSerialDelegate
    
    // The bluetooth reciever
    func serialDidReceiveString(_ message: String)
    {
        mainTextView.text! += message
        
        let pref = UserDefaults.standard.integer(forKey: ReceivedMessageOptionKey)
        if pref == ReceivedMessageOption.newline.rawValue
        {
            mainTextView.text! += "\n"
        }
        
        textViewScrollToBottom()
        
        if message.range(of:"SP0") != nil {
            speedLabel.text = "OFF"
        }
        
        if message.range(of:"SP1") != nil {
            speedLabel.text = "SP 1"
        }
        
        if message.range(of:"SP2") != nil {
            speedLabel.text = "SP 2"
        }
        
        if message.range(of:"SP3") != nil {
            speedLabel.text = "SP 3"
        }
        
        if message.range(of:"SP4") != nil {
            speedLabel.text = "SP 4"
        }
        
        if message.range(of:"SP5") != nil {
            speedLabel.text = "MAX"
        }
    }
    
    // Bluetooth disconnected
    func serialDidDisconnect(_ peripheral: CBPeripheral, error: NSError?)
    {
        reloadView()
        navItem.title = "Status: Disconnected"
    }
    
    // Bluetooth changed state
    func serialDidChangeState()
    {
        reloadView()
        if serial.centralManager.state != .poweredOn
        {
            navItem.title = "Status: Bluetooth Turned Off"
        }
    }
    
    // IBActions
    
    // Stop button in UI
    @IBAction func stopB(_ stopButton: UIButton)
    {
        if !serial.isReady
        {
            let alert = UIAlertController(title: "Not Connected", message: "Please connect bluetooth skateboard.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: { action -> Void in self.dismiss(animated: true, completion: nil) }))
            present(alert, animated: true, completion: nil)
            return
        }
        counter = 0
        serial.sendMessageToDevice(String(counter))
    }
    
    // Plus button in UI
    @IBAction func increaseSpeed(_ plusButton: UIButton)
    {
        
        if !serial.isReady
        {
            let alert = UIAlertController(title: "Not Connected", message: "Please connect bluetooth skateboard.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: { action -> Void in self.dismiss(animated: true, completion: nil) }))
            present(alert, animated: true, completion: nil)
            return
        }
        
        if (counter < 5)
        {
            counter = counter + 1
            serial.sendMessageToDevice(String(counter))
        }
    }
    
    // Minus button in UI
    @IBAction func decreaseSpeed(_ minusButton: UIButton)
    {
        if !serial.isReady
        {
            let alert = UIAlertController(title: "Not Connected", message: "Please connect bluetooth skateboard.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: { action -> Void in self.dismiss(animated: true, completion: nil) }))
            present(alert, animated: true, completion: nil)
            return
        }
        
        if (counter > 0)
        {
            counter = counter - 1
            serial.sendMessageToDevice(String(counter))
        }
    }
    
    // Connect / Disconnect button in UI
    @IBAction func connectBT(_ connectButton: AnyObject)
    {
        if serial.connectedPeripheral == nil
        {
            performSegue(withIdentifier: "ShowScanner", sender: self)
        }
        else
        {
            serial.disconnect()
            reloadView()
        }
    }
}
