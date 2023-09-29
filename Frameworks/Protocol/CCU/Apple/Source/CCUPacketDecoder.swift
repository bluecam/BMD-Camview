/* -LICENSE-START-
 ** Copyright (c) 2018 Blackmagic Design
 **
 ** Permission is hereby granted, free of charge, to any person or organization
 ** obtaining a copy of the software and accompanying documentation covered by
 ** this license (the "Software") to use, reproduce, display, distribute,
 ** execute, and transmit the Software, and to prepare derivative works of the
 ** Software, and to permit third-parties to whom the Software is furnished to
 ** do so, all subject to the following:
 **
 ** The copyright notices in the Software and this entire statement, including
 ** the above license grant, this restriction and the following disclaimer,
 ** must be included in all copies of the Software, in whole or in part, and
 ** all derivative works of the Software, unless such copies or derivative
 ** works are solely in the form of machine-executable object code generated by
 ** a source language processor.
 **
 ** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 ** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 ** FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
 ** SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
 ** FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
 ** ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 ** DEALINGS IN THE SOFTWARE.
 ** -LICENSE-END-
 */

import Foundation
import Utility

public protocol CCUPacketDecoderDelegate: AnyObject {
    func onCameraSpecificationReceived(_ cameraModel: CameraModel)
    func onWhiteBalanceReceived(_ whiteBalance: Int16, _ tint: Int16)
    func onRecordingFormatReceived(_ recordingFormatData: CCUPacketTypes.RecordingFormatData)
	func onApertureFstopReceived(_ fstop: Float, _ stopUnits: LensConfig.ApertureUnits)
	func onApertureNormalisedReceived(_ apertureNormalised: Float)
	func onExposureReceived(_ exposure: Int32)
    func onShutterSpeedReceived(_ shutterSpeed: Int32)
	func onShutterAngleReceived(_ shutterAngleX100: Int32)
    func onISOReceived(_ iso: Int) -> Void
	func onGainReceived(_ gain: Decibels) -> Void
	func onNDFilterStopReceived(_ stop: Float, _ displayMode: VideoConfig.NDFilterDisplayMode)
	func onTransportInfoReceived(_ info: TransportInfo)
	func onAutoExposureModeReceived(_ autoExposureMode: CCUPacketTypes.AutoExposureMode)
    func onTimecodeReceived(_ timecode: String)
	func onMediaStatusReceived(_ statuses: [CCUPacketTypes.MediaStatus])
    func onRecordTimeRemainingReceived(_ remainingRecordTimes: [String], _ remainingRecordTimesInMinutes: [Int16])

	func onReelReceived(_ reelNumber: Int16, _ editable: Bool)
    func onSceneTagsReceived(_ sceneTag: CCUPacketTypes.MetadataSceneTag, _ locationTag: CCUPacketTypes.MetadataLocationTypeTag, _ dayOrNight: CCUPacketTypes.MetadataDayNightTag)
    func onSceneReceived(_ scene: String)
    func onTakeReceived(_ takeNumber: Int8, _ takeTag: CCUPacketTypes.MetadataTakeTag)
    func onGoodTakeReceived(_ goodTake: Bool)
    func onSlateForNameReceived(_ slateForName: String)
    func onSlateForTypeReceived(_ slateForType: CCUPacketTypes.MetadataSlateForType)

    func onTimecodeSourceReceived(_ source: CCUPacketTypes.DisplayTimecodeSource)
}

public class CCUPacketDecoder {
    weak var m_ccuPacketDecoderDelegate: CCUPacketDecoderDelegate?

	public init() {}
	
	public func setDelegate(_ delegate: CCUPacketDecoderDelegate) {
		m_ccuPacketDecoderDelegate = delegate
	}

    public func readCCUPacket(_ data: Data?) {
        if data != nil {
            do {
                if m_ccuPacketDecoderDelegate != nil {
                    try CCUDecodingFunctions.DecodeCCUPacket(data: data!, respondTo: m_ccuPacketDecoderDelegate!)
                }
            } catch {
                Logger.LogError("Failed to decode CCU packet: \(error)")
            }
        } else {
            Logger.LogNoPacketDataWarning(packetType: "CCU")
        }
    }

    public func readTimecodePacket(_ data: Data?) {
        if data != nil {
            let range: Range<Data.Index> = 8 ..< 12
            let timecodeData = data!.subdata(in: range)
            let castingClosure = {
                (bytes: UnsafePointer<UInt32>) -> UInt32 in
                bytes.pointee
            }
            let timecodeBytes = timecodeData.withUnsafeBytes(castingClosure)
            let timecode: String = CCUDecodingFunctions.TimecodeToString(timecode: timecodeBytes)
            m_ccuPacketDecoderDelegate?.onTimecodeReceived(timecode)
        } else {
            Logger.LogNoPacketDataWarning(packetType: "Timecode")
        }
    }

    public func readCameraStatus(_ data: Data?) -> UInt8 {
        return CameraStatus.GetCameraStatusFlags(data)
    }

    public func readCameraModelPacket(_ data: Data?) {
        if data != nil {
            let string: String? = String(data: data!, encoding: String.Encoding.ascii)
            if string != nil {
                Logger.Log("Camera Model: \(string!)")
            }
        }
    }
}