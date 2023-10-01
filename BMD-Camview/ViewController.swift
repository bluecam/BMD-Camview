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
import CameraControlInterface


class ViewController: BasicCameraControlViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    
    
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var ISOPicker: UIPickerView!
    
    @IBOutlet weak var powerButton: UIButton!
    @IBOutlet weak var timecodeLabel: UITextField!
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return isoValues.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return String(isoValues[row])
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Member variables
    weak var cciOut: OutgoingCameraControlFromUIDelegate?
    
    
    var isoValues = VideoConfig.kISOValues[CameraModel.Unknown]!
    
    var recording: Bool = false
    var powerOn: Bool = false
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let isoIndex: Int = pickerView.selectedRow(inComponent: 0)
        cciOut?.onISOChanged(isoIndex)
        // The parameter named row and component represents what was selected.
    }
    override func onCameraSpecificationReceived(_ cameraModel: CameraModel) {
        isoValues = VideoConfig.kISOValues[cameraModel] ?? VideoConfig.kISOValues[CameraModel.Unknown]!
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.ISOPicker.delegate = self
        self.ISOPicker.dataSource = self
        
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        cciOut = appDelegate.cameraControlInterface
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




