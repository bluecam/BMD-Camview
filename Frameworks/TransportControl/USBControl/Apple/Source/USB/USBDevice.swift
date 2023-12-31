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

import Cocoa
import IOKit
import IOKit.usb
import IOKit.usb.IOUSBLib

// From IOUSBLib.h, required to get USB device interface
public let kIOUSBDeviceUserClientTypeID = CFUUIDGetConstantUUIDWithBytes(kCFAllocatorDefault,
																		 0x9d, 0xc7, 0xb7, 0x80, 0x9e, 0xc0, 0x11, 0xD4,
																		 0xa5, 0x4f, 0x00, 0x0a, 0x27, 0x05, 0x28, 0x61)
// From IOUSBLib.h, using kIOUSBDeviceInterfaceID100
public let kIOUSBDeviceInterfaceID = CFUUIDGetConstantUUIDWithBytes(kCFAllocatorDefault,
                                                             		0x5c, 0x81, 0x87, 0xd0, 0x9e, 0xf3, 0x11, 0xD4,
                                                             		0x8b, 0x45, 0x00, 0x0a, 0x27, 0x05, 0x28, 0x61)
// From IOUSBLib.h, required to get USB interface interface
public let kIOUSBInterfaceUserClientTypeID = CFUUIDGetConstantUUIDWithBytes(kCFAllocatorDefault,
																			0x2d, 0x97, 0x86, 0xc6, 0x9e, 0xf3, 0x11, 0xD4,
																			0xad, 0x51, 0x00, 0x0a, 0x27, 0x05, 0x28, 0x61)
// From IOUSBLib.h, using kIOUSBInterfaceInterfaceID550 / 942
public let kIOUSBInterfaceInterfaceID = CFUUIDGetConstantUUIDWithBytes(kCFAllocatorDefault,
																	   0x73, 0xc9, 0x7a, 0xe8, 0x9e, 0xf3, 0x11, 0xD4,
																	   0xb1, 0xd0, 0x00, 0x0a, 0x27, 0x05, 0x28, 0x61)
// From IOCFPlugin.h, required to create interface iterators
public let kIOCFPlugInInterfaceID = CFUUIDGetConstantUUIDWithBytes(kCFAllocatorDefault,
																   0xC2, 0x44, 0xE8, 0x58, 0x10, 0x9C, 0x11, 0xD4,
																   0x91, 0xD4, 0x00, 0x50, 0xE4, 0xC6, 0x42, 0x6F)

// The following are commonly used errors copied from IOKit.usb.USB.h for use in Swift
public func iokit_usb_err(_ value: Int) -> IOReturn
{
	return IOReturn(Int32(bitPattern: 0xe0004000) | Int32(value))
}
public let kIOUSBUnknownPipeErr = iokit_usb_err(0x61)
public let kIOUSBTooManyPipesErr = iokit_usb_err(0x60)
public let kIOUSBTransactionTimeout = iokit_usb_err(0x51)
public let kIOUSBPipeStalled = iokit_usb_err(0x4f)
public let kIOUSBTooManyTransactionsPending = iokit_usb_err(0x42)


// Selected minumum USB library versions to work with
public typealias DeviceInterfacePtrPtr = UnsafeMutablePointer<UnsafeMutablePointer<IOUSBDeviceInterface>?>
public typealias PlugInInterfacePtrPtr = UnsafeMutablePointer<UnsafeMutablePointer<IOCFPlugInInterface>?>
public typealias InterfaceInterfacePtrPtr = UnsafeMutablePointer<UnsafeMutablePointer<IOUSBInterfaceInterface550>?>

public func USBEncodeRequest(request: Int, direction:Int, type:Int, recipient:Int) -> UInt16 {
	return UInt16(request << 8) +
		UInt16(recipient) +
		UInt16((direction & kUSBRqDirnMask) << kUSBRqDirnShift) +
		UInt16((type & kUSBRqTypeMask) << kUSBRqTypeShift)
}

open class USBDevice : Equatable {
    var m_deviceId: UInt64
    var m_vendorId: UInt16
    var m_productId: UInt16
    var m_deviceName: String
    var m_deviceInterfacePtrPtr: DeviceInterfacePtrPtr?
    
    public init(_ id: UInt64,
                _ vendorId: UInt16,
                _ productId: UInt16,
                _ name: String,
                _ deviceInterfacePtrPtr: DeviceInterfacePtrPtr?) {
        self.m_deviceId = id
        self.m_vendorId = vendorId
        self.m_productId = productId
        self.m_deviceName = name
        self.m_deviceInterfacePtrPtr = deviceInterfacePtrPtr
    }
	
	public static func ==(lhs: USBDevice, rhs: USBDevice) -> Bool {
		return lhs.m_deviceId == rhs.m_deviceId &&
				lhs.m_vendorId == rhs.m_vendorId &&
				lhs.m_productId == rhs.m_productId
	}
	
	public func getName() -> String { return m_deviceName }
	public func getId() -> UInt64 { return m_deviceId }
}
