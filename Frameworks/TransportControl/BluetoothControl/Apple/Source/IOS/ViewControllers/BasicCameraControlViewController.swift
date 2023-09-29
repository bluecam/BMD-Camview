//
//  BasicCameraControlViewController.swift
//  BluetoothControl-iOS
//
//  Created by John Sherman on 9/5/23.
//  Copyright © 2023 Blackmagic Design Pty Ltd. All rights reserved.
//

import Foundation
import UIKit
import CoreBluetooth
import CCU
import Utility

open class BasicCameraControlViewController: UIViewController, BluetoothConnectionManagerDelegate, PacketReceivedDelegate, CCUPacketDecoderDelegate {
    
    // Member variables
    enum ConnectionStatus {
        case NoConnection
        case Connecting
        case Connected
    }
    var connectionStatus = ConnectionStatus.NoConnection
    
    var connectionManager: BluetoothConnectionManager? = nil
    var peripheralInterface: PeripheralInterface? = nil
    
    //================================================
    // NSViewController methods
    //================================================
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        connectionManager = BluetoothConnectionManager()
        connectionManager?.m_connectionManagerDelegate = self
    }
    
    public func connect(to peripheral: CBPeripheral) {
        connectionManager?.attemptConnection(to: peripheral.getPeripheralIdentifier())
        connectionStatus = ConnectionStatus.Connecting
    }
    
    public func disconnect(from peripheral: CBPeripheral) {
        connectionManager?.disconnect(from: peripheral)
        connectionStatus = ConnectionStatus.NoConnection
    }
    
    public func sendCCUCommand(data: Data) {
        peripheralInterface?.sendCCUPacket(data)
    }
    
    public func sendPowerCommand(powerOn: Bool) {
        peripheralInterface?.sendPowerPacket(powerOn ? CameraStatus.kPowerOn : CameraStatus.kPowerOff)
    }
    
    public func canConnect() -> Bool {
        return connectionStatus == ConnectionStatus.NoConnection
    }
    
    public func isConnected() -> Bool {
        return connectionStatus == ConnectionStatus.Connected
    }
    
    //================================================
    // PacketReceivedDelegate methods
    //================================================
    public func onTimecodePacketReceived(_ data: Data?) {
        // We received a timecode packet from the camera.
        if let data = data {
            let range: Range<Data.Index> = 8 ..< 12
            let timecodeData = data.subdata(in: range)
            let castingClosure = {
                (bytes: UnsafePointer<UInt32>) -> UInt32 in
                bytes.pointee
            }
            let timecodeBytes = timecodeData.withUnsafeBytes(castingClosure)
            let stringValue: String = CCUDecodingFunctions.TimecodeToString(timecode: timecodeBytes)
            var timecode = Timecode()
            timecode.stringValue = stringValue
            onTimecodeMessageReceived(timecode: timecode)
        }
    }
    
    public func onCameraStatusPacketReceived(_ data: Data?) {
        // We received a CameraStatus notification from the camera.
        
        // Unpack camera status from data received.
        var cameraStatus: UInt8 = 0
        if let data = data {
            let byteArray = [UInt8](data)
            if byteArray.count > 0 {
                cameraStatus = byteArray[0]
            }
        }

        // Determine power status (on or off)
        let powerOn = cameraStatus & CameraStatus.Flags.CameraPowerFlag != 0
        onPowerMessageReceived(powerOn: powerOn)

        // Determine camera ready status (ready or not)
        let cameraReady = cameraStatus & CameraStatus.Flags.CameraReadyFlag != 0
        if cameraReady {
            onCameraReady()
        }
    }
    
    public func onCCUPacketReceived(_ data: Data?) {
        // We received a CCU command from the camera.
        if let data = data {
            do {
                try CCUDecodingFunctions.DecodeCCUPacket(data: data, respondTo: self)
            } catch {
                // Failed to decode ccu message
            }
        }
    }
    
    // All the methods below can be overridden and implemented in a derived ViewController.
    // If the method is not empty, be sure to call the 'super' method from your
    // implementation (eg. 'super.connectedToPeripheral(peripheral)' )
    
    //================================================
    // ConnectionManagerDelegate methods
    //================================================
    open func updateDiscoveredPeripheralList(_ discoveredPeripheralList: [DiscoveredPeripheral]) {}
    
    open func connectedToPeripheral(_ peripheral: CBPeripheral) {
        peripheralInterface = PeripheralInterface(peripheral: peripheral)
        peripheralInterface?.m_packetReceivedDelegate = self
    }
    
    open func onConnectionLost() {
        connectionStatus = ConnectionStatus.NoConnection
    }
    
    open func onConnectionFailed(with error: Error?) {
        connectionStatus = ConnectionStatus.NoConnection
    }
    
    open func onDisconnected(with error: Error?) {
        connectionStatus = ConnectionStatus.NoConnection
    }
    
    open func onReconnection() {
        connectionStatus = ConnectionStatus.Connected
    }
    
    //================================================
    // PacketDecodedDelegate methods
    //================================================
    open func onCameraSpecificationReceived(_ cameraModel: CameraModel) {}
    open func onWhiteBalanceReceived(_ whiteBalance: Int16, _ tint: Int16) {}
    open func onRecordingFormatReceived(_ recordingFormatData: CCUPacketTypes.RecordingFormatData) {}
    open func onApertureFstopReceived(_ fstop: Float, _ stopUnits: LensConfig.ApertureUnits) {}
    open func onApertureNormalisedReceived(_ apertureNormalised: Float) {}
    open func onExposureReceived(_ exposure: Int32) {}
    open func onShutterSpeedReceived(_ shutterSpeed: Int32) {}
    open func onShutterAngleReceived(_ shutterAngleX100: Int32) {}
    open func onISOReceived(_ iso: Int) {}
    open func onGainReceived(_ sensorGain: Int) {}
    open func onNDFilterStopReceived(_ stop: Float, _ displayMode: VideoConfig.NDFilterDisplayMode) {}
    open func onTransportInfoReceived(_ info: TransportInfo) {}
    open func onAutoExposureModeReceived(_ autoExposureMode: CCUPacketTypes.AutoExposureMode) {}
    open func onTimecodeReceived(_ timecode: String) {}
    open func onMediaStatusReceived(_ statuses: [CCUPacketTypes.MediaStatus]) {}
    open func onRecordTimeRemainingReceived(_ remainingRecordTimes: [String], _ remainingRecordTimesInMinutes: [Int16]) {}
    open func onReelReceived(_ reelNumber: Int16, _ editable: Bool) {}
    open func onSceneTagsReceived(_ sceneTag: CCUPacketTypes.MetadataSceneTag, _ locationTag: CCUPacketTypes.MetadataLocationTypeTag, _ dayOrNight: CCUPacketTypes.MetadataDayNightTag) {}
    open func onSceneReceived(_ scene: String) {}
    open func onTakeReceived(_ takeNumber: Int8, _ takeTag: CCUPacketTypes.MetadataTakeTag) {}
    open func onGoodTakeReceived(_ goodTake: Bool) {}
    open func onSlateForNameReceived(_ slateForName: String) {}
    open func onSlateForTypeReceived(_ slateForType: CCUPacketTypes.MetadataSlateForType) {}
    open func onTimecodeSourceReceived(_ source: CCUPacketTypes.DisplayTimecodeSource) {}
    
    //================================================
    open func onPowerMessageReceived(powerOn: Bool) {}
    open func onCameraReady() {}
    open func onTimecodeMessageReceived(timecode: Timecode) {}
}

