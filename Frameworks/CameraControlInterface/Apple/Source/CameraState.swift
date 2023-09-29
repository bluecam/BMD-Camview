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
import BluetoothControl
import CCU

public struct SlotState {
	var status = CCUPacketTypes.MediaStatus.None
    var displayedRemainingRecordTime = String.Localized("Transport.NoCard")
    var remainingRecordTime = String.Localized("Transport.NoCard")
	var recordTimeWarning = RecordTimeWarning.NoWarning
	var remainingTimeInMinutes: Int16 = 0
}

public struct CameraState {
    var cameraModel: CameraModel
    var whiteBalance: Int16
    var tint: Int16
    var customWhiteBalance: Int16
    var customTint: Int16
    var autoWhiteBalancePacketsExpected: Int
	var fstop: Float
    var stopUnits: LensConfig.ApertureUnits
	var apertureNormalised: Float
    var shutterAngle: Double
    var ISO: Int
    var gain: Decibels
	var ndFilterStop: Float
	var ndFilterDisplayMode: VideoConfig.NDFilterDisplayMode
    var shutterSpeed: Int32
	var focusPosition: Int
    var recordingFormatData: CCUPacketTypes.RecordingFormatData
    var frameRateForShutterCalculations: Int16
	var slots: [SlotState]
    var hasRecordingError: Bool
    var anyMediaWithError: Bool
    var reel: Int
	var reelEditable: Bool
    var scene: String
    var sceneTag: CCUPacketTypes.MetadataSceneTag
    var locationTag: CCUPacketTypes.MetadataLocationTypeTag
    var timeTag: CCUPacketTypes.MetadataDayNightTag
    var goodTake: Bool
    var takeNumber: Int
    var takeTag: CCUPacketTypes.MetadataTakeTag
    var slateName: String
    var slateType: CCUPacketTypes.MetadataSlateForType
    var transportInfo: TransportInfo
    var autoExposureMode: CCUPacketTypes.AutoExposureMode
    var timecode: String
    var timecodeSource: CCUPacketTypes.DisplayTimecodeSource

    var expectedWhiteBalance = ExpectedValues<Int16>(errorTolerance: 0)
    var expectedTint = ExpectedValues<Int16>(errorTolerance: 0)
	var expectedApertureNormalisedx100 = ExpectedValues<Int8>(errorTolerance: 0)
	var expectedShutterSpeed = ExpectedValues<Int32>(errorTolerance: 1)
	var expectedShutterAngle = ExpectedValues<Int32>(errorTolerance: 0)
    var expectedOffSpeedFrameRate = ExpectedValues<Int16>(errorTolerance: 0)
	var expectedISOValue = ExpectedValues<Int32>(errorTolerance: 0)

    init() {
        cameraModel = CameraModel.Unknown
        whiteBalance = 2500
        tint = 0
        customWhiteBalance = 2500
        customTint = 0
        autoWhiteBalancePacketsExpected = 0
		fstop = 0.0
        stopUnits = LensConfig.ApertureUnits.Fstops
		apertureNormalised = 0.0
        shutterAngle = 180.0
        ISO = 200
		gain = -6
		ndFilterStop = 0.0
		ndFilterDisplayMode = VideoConfig.NDFilterDisplayMode.Stop
        shutterSpeed = 0
		focusPosition = 0
        recordingFormatData = CCUPacketTypes.RecordingFormatData()
        frameRateForShutterCalculations = 0
		slots = []
        hasRecordingError = false
        anyMediaWithError = false
        reel = 0
		reelEditable = false
        scene = ""
        sceneTag = CCUPacketTypes.MetadataSceneTag.None
        locationTag = CCUPacketTypes.MetadataLocationTypeTag.Exterior
        timeTag = CCUPacketTypes.MetadataDayNightTag.Night
        goodTake = false
        takeNumber = 0
        takeTag = CCUPacketTypes.MetadataTakeTag.None
        slateName = ""
        slateType = CCUPacketTypes.MetadataSlateForType.NextClip
        transportInfo = TransportInfo()
		autoExposureMode = CCUPacketTypes.AutoExposureMode.Manual
        timecode = "00:00:00:00"
        timecodeSource = CCUPacketTypes.DisplayTimecodeSource.Clip
    }

	public mutating func updateTransportInfo(_ info: TransportInfo) {
		let old = transportInfo
		let anySlotActive = info.slots.contains(where: { $0.active })
		let fromPreviewMode = (old.transportMode == CCUPacketTypes.MediaTransportMode.Preview) && (info.transportMode != CCUPacketTypes.MediaTransportMode.Preview)
		let slotMediumChanged = !old.slots.elementsEqual(info.slots, by: {old, new in old.medium == new.medium })
		anyMediaWithError = anyMediaWithError && anySlotActive && !fromPreviewMode && !slotMediumChanged
        hasRecordingError = (hasRecordingError || info.transportMode == CCUPacketTypes.MediaTransportMode.Record) ?  hasRecordingError :  anyMediaWithError;
		transportInfo = info
		if slots.count != info.slots.count {
			slots = [SlotState](repeating: SlotState(), count: info.slots.count)
		}
	}
}
