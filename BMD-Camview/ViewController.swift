//
//  ViewController.swift
//  BMPCC
//  BlackmagicDesigns Note should be here...
//  Created by John Sherman on 9/27/23.
//

import UIKit
import Utility
import CCU
import BluetoothControl


class ViewController: BasicCameraControlViewController {

    @IBOutlet weak var recordButton: UIButton!
    
    @IBOutlet weak var powerButton: UIButton!
    @IBOutlet weak var timecodeLabel: UITextField!
    
    var recording: Bool = false
    var powerOn: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    //=======================================================
    // @IBAction methods
    //=======================================================
    @IBAction func onPowerButtonClicked(_ sender: Any) {
        // Send a power command, on or off.
        sendPowerCommand(powerOn: !powerOn)
    }
    
    @IBAction func onRecordButtonClicked(_ sender: Any) {
        // Create a TransportInfo instance, and set transportMode to Record or Preview (also supports Play).
        var transportInfo = TransportInfo()
        transportInfo.transportMode = recording ? CCUPacketTypes.MediaTransportMode.Preview : CCUPacketTypes.MediaTransportMode.Record
        
        // Create a TransportInfo Command
        if let command: CCUPacketTypes.Command = CCUEncodingFunctions.CreateTransportInfoCommand(info: transportInfo) {
            // Send the command
            sendCCUCommand(data: command.serialize())
        }
    }
    
    //=======================================================
    // BasicCameraControlViewController methods
    //=======================================================
    override func updateDiscoveredPeripheralList(_ discoveredPeripheralList: [DiscoveredPeripheral]) {
        if canConnect() {
            // Connect to the first camera discovered.
            if discoveredPeripheralList.count > 0 {
                let peripheral = discoveredPeripheralList[0].peripheral
                connect(to: peripheral)
            }
        
            // Or connect to a specific camera by name (corresponds to the name
            // displayed in your camera's Bluetooth setup menu).
            /*
            for peripheral in discoveredPeripheralList {
                if peripheral.name.contains("A:2E8945C9") {
                    connect(to: peripheral.peripheral)
                    break
                }
            }
            */
        }
    }
    
    override func onCameraReady() {
        // We are connected and the camera is ready to receive commands.
        // Enable the input so we can send commands.
        recordButton.isEnabled = true
        powerButton.isEnabled = true
    }

    // The following methods notify us when we receive a command from the camera.
    // For more commands/methods to override, see the list in BasicCameraControlViewController.swift
    // beneath the label 'PacketDecodedDelegate methods'.

    override func onTransportInfoReceived(_ transportInfo: TransportInfo) {
        recording = (transportInfo.transportMode == CCUPacketTypes.MediaTransportMode.Record)
        recordButton.setTitle("Record", for: .normal)
    }
    
    override func onPowerMessageReceived(powerOn: Bool) {
        self.powerOn = powerOn
        powerButton.setTitle("Power", for: .normal)
    }
    
    override func onTimecodeMessageReceived(timecode: Timecode) {
        timecodeLabel.text = timecode.stringValue
    }
}

