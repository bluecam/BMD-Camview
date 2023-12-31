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


public enum CameraModel: UInt8 {
	case Unknown = 0
	case CinemaCamera = 1
	case PocketCinemaCamera = 2
	case ProductionCamera4K = 3
	case StudioCamera = 4
	case StudioCamera4K = 5
	case URSA = 6
	case MicroCinemaCamera = 7
	case MicroStudioCamera = 8
	case URSAMini = 9
	case URSAMiniPro = 10
	case URSABroadcast = 11
	case URSAMiniProG2 = 12
	case PocketCinemaCamera4K = 13
	case PocketCinemaCamera6K = 14
	case PocketCinemaCamera6KPro = 15
	case URSAMiniPro12K = 16
	case URSABroadcastG2 = 17
	case StudioCamera4KPlus = 18
	case StudioCamera4KPro = 19
	case PocketCinemaCamera6KG2 = 20
	case StudioCamera4KExtreme = 21

	public static func from(value: CameraModel.RawValue) -> CameraModel {
		if let model = CameraModel.init(rawValue: value) {
			return model
		}

		return .Unknown
	}

	public static func from(name: String) -> CameraModel {
		if let model = nameToModel[name] {
			return model
		}

		return .Unknown
	}

	static let nameToModel: [String: CameraModel] = [
		"Cinema Camera": CameraModel.CinemaCamera,
		"Micro Cinema Camera": CameraModel.MicroCinemaCamera,
		"Micro Studio Camera": CameraModel.MicroStudioCamera,
		"Pocket Cinema Camera": CameraModel.PocketCinemaCamera,
		"Pocket Cinema Camera 4K": CameraModel.PocketCinemaCamera4K,
		"Pocket Cinema Camera 6K": CameraModel.PocketCinemaCamera6K,
		"Pocket Cinema Camera 6K G2": CameraModel.PocketCinemaCamera6KG2,
		"Pocket Cinema Camera 6K Pro": CameraModel.PocketCinemaCamera6KPro,
		"Production Camera 4K": CameraModel.ProductionCamera4K,
		"Studio Camera": CameraModel.StudioCamera,
		"Studio Camera 4K": CameraModel.StudioCamera4K,
		"Studio Camera 4K Extreme": CameraModel.StudioCamera4KExtreme,
		"Studio Camera 4K Plus": CameraModel.StudioCamera4KPlus,
		"Studio Camera 4K Pro": CameraModel.StudioCamera4KPro,
		"URSA": CameraModel.URSA,
		"URSA Broadcast": CameraModel.URSABroadcast,
		"URSA Broadcast G2": CameraModel.URSABroadcastG2,
		"URSA Mini": CameraModel.URSAMini,
		"URSA Mini Pro": CameraModel.URSAMiniPro,
		"URSA Mini Pro 12K": CameraModel.URSAMiniPro12K,
		"URSA Mini Pro G2": CameraModel.URSAMiniProG2,
	]

	public func isPocket() -> Bool {
		switch (self) {
		case .PocketCinemaCamera,
			 .PocketCinemaCamera4K,
			 .PocketCinemaCamera6K,
			 .PocketCinemaCamera6KG2,
			 .PocketCinemaCamera6KPro: return true
		default: return false
		}
	}
}
