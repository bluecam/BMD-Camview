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
import CoreLocation

// Location Services
public protocol LocationServicesDelegate: AnyObject {
    func onLocationReceived(_ latitide: UInt64, _ longitude: UInt64)
    func onLocationFailed(_ error: Error)
}

public class LocationServices: NSObject, CLLocationManagerDelegate {
    let m_locationManager: CLLocationManager
    weak var m_delegate: LocationServicesDelegate?
    var m_authorizationStatus = CLAuthorizationStatus.notDetermined
    var m_requestLocationWhenAuthorized = false

    public override init() {
        m_locationManager = CLLocationManager()

        super.init()

        m_locationManager.delegate = self
        m_locationManager.desiredAccuracy = kCLLocationAccuracyBest
        m_locationManager.distanceFilter = 50
    }
	
	public func setDelegate(_ delegate: LocationServicesDelegate?) {
		m_delegate = delegate
	}

    @objc public func updateLocation() {
    #if os(iOS)
        if m_authorizationStatus != CLAuthorizationStatus.authorizedWhenInUse {
            m_locationManager.requestWhenInUseAuthorization()
            m_requestLocationWhenAuthorized = true
        } else {
            m_locationManager.requestLocation()
        }
    #elseif os(OSX)
        m_locationManager.startUpdatingLocation()
    #endif
    }

    public func locationManager(_: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        m_authorizationStatus = status

    #if os(iOS)
        let isAuthorized = status == CLAuthorizationStatus.authorizedWhenInUse
    #elseif os(OSX)
        let isAuthorized = status == CLAuthorizationStatus.authorized
    #endif

        if isAuthorized && m_requestLocationWhenAuthorized {
            updateLocation()
            m_requestLocationWhenAuthorized = false
        }
    }

    public func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for location in locations {
            let coordinates = location.coordinate
            let latitude: UInt64 = convertDoubleToBCDAngle(angle: coordinates.latitude)
            let longitude: UInt64 = convertDoubleToBCDAngle(angle: coordinates.longitude)
            m_delegate?.onLocationReceived(latitude, longitude)
        }

        Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(updateLocation), userInfo: nil, repeats: false)

    #if os(OSX)
        m_locationManager.stopUpdatingLocation()
    #endif
    }

    public func locationManager(_: CLLocationManager, didFailWithError error: Error) {
        // On macOS, a wi-fi connection needs to be active, or location discovery will fail.
        m_delegate?.onLocationFailed(error)
        Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(updateLocation), userInfo: nil, repeats: false)
    }

    // Assumption is that (-90° <= latitude <= 90°) && (-180° <= longitude <= 180°)
    func convertDoubleToBCDAngle(angle: Double) -> UInt64 {
        var angle = angle
        var nibbleCount: size_t = 15
        var angleBCD: UInt64 = 0

        // assign the sign, and convert it to a positive angle
        if angle < 0 {
            angleBCD = 0x8
            angle = -angle
        }

        var angleInt = UInt64(angle)

        // Remove the integer part of the angle
        angle -= Double(angleInt)

        // Assign the integer part
        var digits: UInt64 = 0
        var divider: UInt64 = 100
        while digits < 3 {
            angleBCD <<= 4
            nibbleCount -= 1
            angleBCD |= (angleInt / divider)
            angleInt = angleInt - (angleInt / divider) * divider

            digits += 1
            divider /= 10
        }

        // Convert the decimal part
        repeat {
            let bcdDigit = UInt64(angle * 10)
            angleBCD <<= 4
            nibbleCount -= 1
            angleBCD |= bcdDigit
            angle = (angle * 10.0) - Double(bcdDigit)
        } while (nibbleCount != 0)

        return angleBCD
    }
}