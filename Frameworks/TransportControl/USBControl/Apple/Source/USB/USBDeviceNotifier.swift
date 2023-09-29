//
//  USBDeviceNotifier.swift
//  USBControl
//

import Cocoa

public extension Notification.Name {
	static let USBDeviceConnected = Notification.Name("USBDeviceConnected")
	static let USBDeviceDisconnected = Notification.Name("USBDeviceDisconnected")
}

open class USBDeviceNotifier {
	// Filter options
	var vendorId: UInt16?
	var productId: UInt16?
	var interfaceClass: UInt16 = UInt16(kIOUSBFindInterfaceDontCare)
	var interfaceSubClass: UInt16 = UInt16(kIOUSBFindInterfaceDontCare)
	var interfaceProtocol: UInt16 = UInt16(kIOUSBFindInterfaceDontCare)
	var interfaceAlternateSetting: UInt16 = UInt16(kIOUSBFindInterfaceDontCare)

	//Create filter for USBDeviceNotifier
	public init() {}
	
	public func addFilterVendorId(_ vendorId: UInt16) {
		self.vendorId = vendorId
	}
	
	public func addFilterProductId(_ productId: UInt16) {
		self.productId = productId
	}
	
	public func addFilterInterface(interfaceClass: UInt16,
								   interfaceSubClass: UInt16 = UInt16(kIOUSBFindInterfaceDontCare),
								   interfaceProtocol: UInt16 = UInt16(kIOUSBFindInterfaceDontCare),
								   interfaceAlternateSetting: UInt16 = UInt16(kIOUSBFindInterfaceDontCare)) {
		self.interfaceClass = interfaceClass
		self.interfaceSubClass = interfaceSubClass
		self.interfaceProtocol = interfaceProtocol
		self.interfaceAlternateSetting = interfaceAlternateSetting
	}

	// Start Blackmagic Design USB device monitoring
    @objc open func start() {
		var matchedIterator:io_iterator_t = 0
		var removalIterator:io_iterator_t = 0
		let notifyPort:IONotificationPortRef = IONotificationPortCreate(kIOMasterPortDefault)
		IONotificationPortSetDispatchQueue(notifyPort, DispatchQueue(label: "IODetector"))
		let matchingDict = IOServiceMatching(kIOUSBDeviceClassName) as NSMutableDictionary
		matchingDict[kUSBVendorID] = self.vendorId ?? "*"
		matchingDict[kUSBProductID] = self.productId ?? "*"

		let matchingCallback:IOServiceMatchingCallback = { (userData, iterator) in
			// Convert self to a void pointer, store that in the context, and convert it
			let this = Unmanaged<USBDeviceNotifier>.fromOpaque(userData!).takeUnretainedValue()
			this.rawDeviceAdded(iterator: iterator)
		}
		
		let removalCallback: IOServiceMatchingCallback = {
			(userData, iterator) in
			let this = Unmanaged<USBDeviceNotifier>.fromOpaque(userData!).takeUnretainedValue()
			this.rawDeviceRemoved(iterator: iterator)
		}
		
		let selfPtr = Unmanaged.passUnretained(self).toOpaque()
		
		IOServiceAddMatchingNotification(notifyPort, kIOFirstMatchNotification, matchingDict, matchingCallback, selfPtr, &matchedIterator)
		IOServiceAddMatchingNotification(notifyPort, kIOTerminatedNotification, matchingDict, removalCallback, selfPtr, &removalIterator)
		
		self.rawDeviceAdded(iterator: matchedIterator)
		self.rawDeviceRemoved(iterator: removalIterator)
    }

    open func rawDeviceAdded(iterator: io_iterator_t) {
        while case let usbDevice = IOIteratorNext(iterator), usbDevice != 0 {
            var score:Int32 = 0
            var kr:Int32 = 0
            var did:UInt64 = 0
            var vid:UInt16 = 0
            var pid:UInt16 = 0
			var deviceInterfaceIterator:io_iterator_t = 0
			var findInterfaceRequest:IOUSBFindInterfaceRequest = IOUSBFindInterfaceRequest(
				bInterfaceClass : self.interfaceClass,
				bInterfaceSubClass : self.interfaceSubClass,
				bInterfaceProtocol : self.interfaceProtocol,
				bAlternateSetting : self.interfaceAlternateSetting)

            var deviceInterfacePtrPtr: DeviceInterfacePtrPtr?
            var plugInInterfacePtrPtr: PlugInInterfacePtrPtr?
			var interfaceInterfacePtrPtr: InterfaceInterfacePtrPtr?

            kr = IORegistryEntryGetRegistryEntryID(usbDevice, &did)
            
            if(kr != kIOReturnSuccess) {
                print("Error getting device id")
            }
            
            // io_name_t imports to swift as a tuple (Int8, ..., Int8) 128 ints
            // although in device_types.h it's defined:
            // typedef	char io_name_t[128];
            var deviceNameCString:[CChar] = [CChar](repeating: 0, count: 128)
            kr = IORegistryEntryGetName(usbDevice, &deviceNameCString)
            
            if(kr != kIOReturnSuccess) {
                print("Error getting device name")
            }
            
            let name = String.init(cString: &deviceNameCString)
            
            // Get plugInInterface for current USB device
            kr = IOCreatePlugInInterfaceForService(
                usbDevice,
                kIOUSBDeviceUserClientTypeID,
                kIOCFPlugInInterfaceID,
                &plugInInterfacePtrPtr,
                &score)
            
            // USB device object is no longer needed.
			defer { IOObjectRelease(usbDevice) }
            
            // Dereference pointer for the plug-in interface
            if (kr != kIOReturnSuccess) {
                continue
            }
            
            guard let plugInInterfaceGetDeviceInterface = plugInInterfacePtrPtr?.pointee?.pointee else {
                print("Unable to get Plug-In Interface")
                continue
            }
			
			defer { IODestroyPlugInInterface(plugInInterfacePtrPtr) }
            
            // Use plug in interface to get a device interface
            kr = withUnsafeMutablePointer(to: &deviceInterfacePtrPtr) {
                $0.withMemoryRebound(to: Optional<LPVOID>.self, capacity: 1) {
                    plugInInterfaceGetDeviceInterface.QueryInterface(
                        plugInInterfacePtrPtr,
                        CFUUIDGetUUIDBytes(kIOUSBDeviceInterfaceID),
                        $0)
                }
            }
			
            // dereference pointer for the device interface
            if (kr != kIOReturnSuccess) {
                continue
            }

            guard let deviceInterface = deviceInterfacePtrPtr?.pointee?.pointee else {
                print("Unable to get Device Interface")
                continue
            }
            
            kr = deviceInterface.USBDeviceOpen(deviceInterfacePtrPtr)
			
            // kIOReturnExclusiveAccess is not a problem as we can still do some things
            if (kr != kIOReturnSuccess && kr != kIOReturnExclusiveAccess) {
                print("Could not open device (error: \(kr))")
                continue
            }
			
            kr = deviceInterface.GetDeviceVendor(deviceInterfacePtrPtr, &vid)
            if (kr != kIOReturnSuccess) {
                continue
            }
            
            kr = deviceInterface.GetDeviceProduct(deviceInterfacePtrPtr, &pid)
            if (kr != kIOReturnSuccess) {
                continue
            }
			
			kr = deviceInterface.CreateInterfaceIterator(deviceInterfacePtrPtr, &findInterfaceRequest, &deviceInterfaceIterator)
			if (kr != kIOReturnSuccess) {
				continue
			}
			
			// Filter only cameras with PTP support
			let interface = IOIteratorNext(deviceInterfaceIterator)
			if (interface == 0) {
				print("Cannot find interface matching the FindInterfaceRequest")
				continue
			}
			
			// Get plugInInterface for current USB interface
			kr = IOCreatePlugInInterfaceForService(
					interface,
					kIOUSBInterfaceUserClientTypeID,
					kIOCFPlugInInterfaceID,
					&plugInInterfacePtrPtr,
					&score)
			
			// USB device object is no longer needed.
			defer { IOObjectRelease(interface) }
			
			// Dereference pointer for the plug-in interface
			if (kr != kIOReturnSuccess) {
				continue
			}
			
			guard let plugInInterfaceGetInterfaceInterface = plugInInterfacePtrPtr?.pointee?.pointee else {
				print("Unable to get Plug-In Interface")
				continue
			}
			
			// Use plug in interface to get the interface interface
			kr = withUnsafeMutablePointer(to: &interfaceInterfacePtrPtr) {
				$0.withMemoryRebound(to: Optional<LPVOID>.self, capacity: 1) {
					plugInInterfaceGetInterfaceInterface.QueryInterface(
						plugInInterfacePtrPtr,
						CFUUIDGetUUIDBytes(kIOUSBInterfaceInterfaceID),
						$0)
				}
			}
			
			// Deereference pointer for the interface interface
			if (kr != kIOReturnSuccess) {
				continue
			}
			
			let device = USBBulkDevice(
				id: did,
				vendorId: vid,
				productId: pid,
				name: name,
				deviceInterfacePtrPtr: deviceInterfacePtrPtr,
				interfaceInterfacePtrPtr: interfaceInterfacePtrPtr
			)
			
			NotificationCenter.default.post(name: .USBDeviceConnected, object: nil, userInfo: ["device": device])
        }
    }
    
    open func rawDeviceRemoved(iterator: io_iterator_t) {
        while case let usbDevice = IOIteratorNext(iterator), usbDevice != 0 {
            var kr:Int32 = 0
            var did:UInt64 = 0
			
            kr = IORegistryEntryGetRegistryEntryID(usbDevice, &did)
			
            if(kr != kIOReturnSuccess) {
                print("Error getting device id")
            }
            
            // USB device object is no longer needed.
            kr = IOObjectRelease(usbDevice)
            
            if (kr != kIOReturnSuccess)
            {
                print("Couldn’t release raw device object (error: \(kr))")
                continue
            }
            
			NotificationCenter.default.post(name: .USBDeviceDisconnected, object: nil, userInfo: ["id": did])
        }
    }
}

