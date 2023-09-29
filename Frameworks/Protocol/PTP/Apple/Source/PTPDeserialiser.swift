/* -LICENSE-START-
** Copyright (c) 2020 Blackmagic Design
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

public typealias PTPStringLengthSize = UInt8
public typealias PTPArrayLengthSize = UInt32
public typealias PTPDataArrayLengthSize = UInt16

public class PTPDeserialiser {
	let m_payload: NSData
	let m_payloadLength: Int
	var m_bytesDeserialised: Int = 0

	public init(_ payload: NSData) {
		// Shallow copy
		m_payload = payload
		m_payloadLength = payload.count
	}
	
	// elemSize allows deserialising to an enum with a specific base type
	public func deserialise<T>(_ buffer: inout T, _ elemSize: Int = 0) throws {
		let nextSizeInBytes = elemSize == 0 ? MemoryLayout.size(ofValue: buffer) : elemSize
		if (m_payloadLength - m_bytesDeserialised < nextSizeInBytes) {
			throw PTPDecodingError.PacketDeserialisingFailed
		}

		m_payload.getBytes(&buffer, range: NSMakeRange(m_bytesDeserialised, nextSizeInBytes))
		m_bytesDeserialised += nextSizeInBytes
	}
	
	public func deserialise(_ elemSize: Int) throws -> Data {
		let nextSizeInBytes = elemSize
		if (m_payloadLength - m_bytesDeserialised < nextSizeInBytes) {
			throw PTPDecodingError.PacketDeserialisingFailed
		}

		let ret = m_payload.subdata(with: NSMakeRange(m_bytesDeserialised, nextSizeInBytes))
		m_bytesDeserialised += nextSizeInBytes
		return ret
	}
	
	public func deserialise(_ elemSize: Int) throws -> [Data] {
		var arrayLength: PTPDataArrayLengthSize = 0
		try	deserialise(&arrayLength)
        
        arrayLength += 2 // first two values of array are count and 0
		
		let bytesRequired: Int = Int(arrayLength) * elemSize
		if (m_payloadLength - m_bytesDeserialised < bytesRequired) {
			throw PTPDecodingError.PacketDeserialisingFailed
		}
		
		var retArray = [Data]()
		while (arrayLength > 0) {
			let item: Data = try deserialise(elemSize)
			retArray.append(item)
			arrayLength -= 1
		}
        retArray.removeFirst(2) // first two values of array are count and 0
        return retArray
	}
	
	public func deserialise() throws -> [String] {
		var arrayLength: PTPDataArrayLengthSize = 0
		try	deserialise(&arrayLength)
		
		var tempString: String = ""
		var retArray = [String]()
		while (arrayLength > 0) {
			try deserialise(&tempString)
			retArray.append(tempString)
			arrayLength -= 1
		}
		return retArray
	}
	
	public func deserialise(_ buffer: inout String) throws {
		var stringLength: PTPStringLengthSize = 0
		try	deserialise(&stringLength)

		let nextSizeInBytes: Int = Int(stringLength * 2)
		if (m_payloadLength - m_bytesDeserialised < nextSizeInBytes) {
			throw PTPDecodingError.PacketDeserialisingFailed
		}

		let data: Data = m_payload.subdata(with: NSMakeRange(m_bytesDeserialised, nextSizeInBytes))
		buffer = StringFunctions.UCS2ToUTF8(data)
		m_bytesDeserialised += nextSizeInBytes
	}
	
	// elemSize allows deserialising to an enum with a specific base type
	internal func deserialise<T>(_ buffer: inout [T], _ obj: inout T, _ elemSize: Int) throws  {
		if (Mirror(reflecting: obj).displayStyle == Mirror.DisplayStyle.enum) {
			Logger.LogError("Deserialiser does not support deserialising enums.")
			throw PTPDecodingError.PacketDeserialisingFailed
		}
		
		var arrayLength: PTPArrayLengthSize = 0
		try	deserialise(&arrayLength)
		
		let bytesRequired: Int = Int(arrayLength) * elemSize
		if (m_payloadLength - m_bytesDeserialised < bytesRequired) {
			throw PTPDecodingError.PacketDeserialisingFailed
		}
		
		while (arrayLength > 0) {
			try deserialise(&obj, elemSize)
			buffer.append(obj)
			arrayLength -= 1
		}
	}
	
	public func deserialise(_ buffer: inout OperationCode) throws {
		var raw: OperationCodeType = OperationCode.Undefined.rawValue
		try deserialise(&raw, MemoryLayout<OperationCodeType>.size)
		buffer = OperationCode(rawValue: raw) ?? OperationCode.Undefined
	}
	
	public func deserialise(_ buffer: inout EventCode) throws {
		var raw: EventCodeType = EventCode.Undefined.rawValue
		try deserialise(&raw, MemoryLayout<EventCodeType>.size)
		buffer = EventCode(rawValue: raw) ?? EventCode.Undefined
	}
	
	public func deserialise(_ buffer: inout DevicePropCode) throws {
		var raw: DevicePropCodeType = DevicePropCode.Undefined.rawValue
		try deserialise(&raw, MemoryLayout<DevicePropCodeType>.size)
		buffer = DevicePropCode(rawValue: raw) ?? DevicePropCode.Undefined
	}
	
	public func deserialise(_ buffer: inout DataTypeCode) throws {
		var raw: DataTypeCodeType = DataTypeCode.Undefined.rawValue
		try deserialise(&raw, MemoryLayout<DataTypeCodeType>.size)
		buffer = DataTypeCode(rawValue: raw) ?? DataTypeCode.Undefined
	}
	
	public func deserialise(_ buffer: inout DevicePropPermissions) throws {
		var raw: DevicePropPermissionsType = DevicePropPermissions.ReadOnly.rawValue
		try deserialise(&raw, MemoryLayout<DevicePropPermissionsType>.size)
		buffer = DevicePropPermissions(rawValue: raw) ?? DevicePropPermissions.ReadOnly
	}
	
	public func deserialise(_ buffer: inout DevicePropForm) throws {
		var raw: DevicePropFormType = DevicePropForm.None.rawValue
		try deserialise(&raw, MemoryLayout<DevicePropFormType>.size)
		buffer = DevicePropForm(rawValue: raw) ?? DevicePropForm.None
	}
	
	public func deserialise(_ buffer: inout [UInt32]) throws {
		var temp: UInt32 = 0
		try deserialise(&buffer, &temp, MemoryLayout<UInt32>.size)
	}
	
	public func deserialise(_ buffer: inout [UInt16]) throws {
		var temp: UInt16 = 0
		try deserialise(&buffer, &temp, MemoryLayout<UInt16>.size)
	}
	
	public func deserialise(_ buffer: inout [UInt8]) throws {
		var temp: UInt8 = 0
		try deserialise(&buffer, &temp, MemoryLayout<UInt8>.size)
	}
	
	public func deserialise(_ buffer: inout [OperationCode]) throws {
		var temp = [OperationCodeType]()
		try deserialise(&temp)
		for item in temp {
			buffer.append(OperationCode(rawValue: item) ?? OperationCode.Undefined)
		}
	}
	
	public func deserialise(_ buffer: inout [EventCode]) throws {
		var temp = [EventCodeType]()
		try deserialise(&temp)
		for item in temp {
			buffer.append(EventCode(rawValue: item) ?? EventCode.Undefined)
		}
	}
	
	public func deserialise(_ buffer: inout [DevicePropCode]) throws {
		var temp = [DevicePropCodeType]()
		try deserialise(&temp)
		for item in temp {
			buffer.append(DevicePropCode(rawValue: item) ?? DevicePropCode.Undefined)
		}
	}
}
