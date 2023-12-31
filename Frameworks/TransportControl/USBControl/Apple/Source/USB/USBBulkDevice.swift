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
import PTP

#if os(iOS)
import UIKit
#elseif os(macOS)
import IOKit
import IOKit.usb
import IOKit.usb.USB
import IOKit.usb.IOUSBLib
#endif

public class USBBulkDevice : USBDevice {
	var m_interfaceInterfacePtrPtr: InterfaceInterfacePtrPtr?
	var m_pipeBulkOutRef: UInt8 = 0
	var m_pipeBulkInRef: UInt8 = 0
	var m_pipeInterruptInRef: UInt8 = 0
	var m_interfaceOpened: Bool = false
	
    public init(id: UInt64,
                vendorId: UInt16,
                productId: UInt16,
                name: String,
                deviceInterfacePtrPtr: DeviceInterfacePtrPtr?,
                interfaceInterfacePtrPtr: InterfaceInterfacePtrPtr?) {
		super.init(id, vendorId, productId, name, deviceInterfacePtrPtr)
        self.m_interfaceInterfacePtrPtr = interfaceInterfacePtrPtr
    }
	
	public func open() -> Bool {
		var kr:Int32 = 0

		guard let ptpInterface = m_interfaceInterfacePtrPtr?.pointee?.pointee else {
			Logger.LogError("Unable to get USB Interface type PTP")
			return false
		}

		kr = ptpInterface.USBInterfaceOpen(m_interfaceInterfacePtrPtr)
		if (kr != kIOReturnSuccess) {
			return false
		}

		var numEndpoints: UInt8 = 0
		kr = ptpInterface.GetNumEndpoints(m_interfaceInterfacePtrPtr, &numEndpoints)
		if (kr != kIOReturnSuccess) {
			return false
		}

		for pipeRef in 1...numEndpoints {
			var direction: UInt8 = 0
			var number: UInt8 = 0
			var transferType: UInt8 = 0
			var maxPacketSize: UInt16 = 0
			var interval: UInt8 = 0
			kr = ptpInterface.GetPipeProperties(m_interfaceInterfacePtrPtr,
												pipeRef,
												&direction,
												&number,
												&transferType,
												&maxPacketSize,
												&interval)
			if (kr != kIOReturnSuccess) {
				continue
			}
			
			if (direction == kUSBOut && transferType == kUSBBulk) {
				print("Bulk Out pipe ref = \(pipeRef), max packet size = \(maxPacketSize)");
				m_pipeBulkOutRef = pipeRef
			}
			else if (direction == kUSBIn && transferType == kUSBBulk) {
				print("Bulk In pipe ref = \(pipeRef), max packet size = \(maxPacketSize)");
				m_pipeBulkInRef = pipeRef
			}
			else if (transferType == kUSBInterrupt) {
				print("Bulk interrupt pipe ref = \(pipeRef)");
				m_pipeInterruptInRef = pipeRef
			}
		}

		m_interfaceOpened = true
		return true
	}
	
	public func close() {
		if let ptpInterface = m_interfaceInterfacePtrPtr?.pointee?.pointee {
			_ = ptpInterface.USBInterfaceClose(m_interfaceInterfacePtrPtr)
		}
		
		if let deviceInterface = m_deviceInterfacePtrPtr?.pointee?.pointee {
			_ = deviceInterface.USBDeviceClose(m_deviceInterfacePtrPtr)
		}
		m_interfaceOpened = false
	}
	
	func clearPipeStall() {
		if let deviceInterface = m_deviceInterfacePtrPtr?.pointee?.pointee {
			let result = deviceInterface.ResetDevice(m_deviceInterfacePtrPtr)
			print("\(result)")
		}
	}
	
	func writePipe(_ buffer: [UInt8]) -> Bool {
		guard let ptpInterface = m_interfaceInterfacePtrPtr?.pointee?.pointee else {
			Logger.LogError("Unable to get USB Interface type PTP")
			return false
		}
		
		if m_pipeBulkOutRef == 0 {
			Logger.LogError("USB interface does not have a bulk OUT pipe")
			return false
		}
		
		var result: Int32 = 0
		let packetSize = Int(buffer.count)
		let packetPtr = UnsafeMutableRawPointer.allocate(byteCount: packetSize, alignment: 4)
		defer { packetPtr.deallocate() }
		packetPtr.copyMemory(from: buffer, byteCount: buffer.count)
		
		result = ptpInterface.WritePipeTO(m_interfaceInterfacePtrPtr,
										m_pipeBulkOutRef,
										packetPtr,
										UInt32(packetSize),
										500,
										500)
		
		if (result == kIOReturnSuccess) {
			return true
		}
		else if (result == kIOUSBTransactionTimeout) {
			clearPipeStall()
			return false
		}
		else {
			return false
		}
	}
	
	func readPipe(_ buffer: inout [UInt8]) -> UInt32 {
		guard let ptpInterface = m_interfaceInterfacePtrPtr?.pointee?.pointee else {
			Logger.LogError("Unable to get USB Interface type PTP")
			return 0
		}

		if m_pipeBulkInRef == 0 {
			Logger.LogError("USB interface does not have a bulk IN pipe")
			return 0;
		}
		
		var result: Int32 = 0
		var bufferCount: UInt32 = UInt32(buffer.count)
		result = ptpInterface.ReadPipeTO(m_interfaceInterfacePtrPtr,
										m_pipeBulkInRef,
										&buffer,
										&bufferCount,
										500,
										500)

		if (result != kIOReturnSuccess) {
			Logger.LogError("Failed to read pipe")
			return 0
		}

		return bufferCount
	}
	
	func readInterruptPipe(_ buffer: inout [UInt8]) -> UInt32 {
		guard let ptpInterface = m_interfaceInterfacePtrPtr?.pointee?.pointee else {
			Logger.LogError("Unable to get USB Interface type PTP")
			return 0
		}
		
		if m_pipeInterruptInRef == 0 {
			Logger.LogError("USB interface does not have a bulk INTERRUPT pipe")
			return 0;
		}
		
		var result: Int32 = 0
		var bufferCount: UInt32 = UInt32(buffer.count)
		result = ptpInterface.ReadPipe(m_interfaceInterfacePtrPtr,
									   m_pipeInterruptInRef,
									   &buffer,
									   &bufferCount)
		
		if (result != kIOReturnSuccess) {
			Logger.LogError("Failed to read interrupt pipe")
			return 0
		}
		
		return bufferCount
	}
}
