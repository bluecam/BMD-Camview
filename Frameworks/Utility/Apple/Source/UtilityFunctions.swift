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

public struct UtilityFunctions {
    typealias Byte = UInt8

    public static func ToByteArray<T>(_ value: T) -> [UInt8] {
        var byteArray: [Byte]!
        var value = value
        withUnsafePointer(to: &value) {
            $0.withMemoryRebound(to: Byte.self, capacity: MemoryLayout<T>.size) {
                byteArray = Array(UnsafeBufferPointer(start: $0, count: MemoryLayout<T>.size))
            }
        }

        return byteArray
    }

	public static func FromByteArray<T: UnsignedInteger>(_ array: [UInt8]) -> T {
		array.withUnsafeBufferPointer {
			$0.baseAddress!.withMemoryRebound(to: T.self, capacity: 1) {
				return $0.pointee
			}
		}
	}

    public static func ToByteArrayFromArray<T>(_ array: [T]) -> [UInt8] {
        var data: Data!
        array.withUnsafeBufferPointer {
            let unsafeBufferPointer = UnsafeBufferPointer(start: UnsafePointer($0.baseAddress), count: $0.count)
            data = Data(buffer: unsafeBufferPointer)
        }

        var byteArray: [Byte]!
        byteArray = [Byte](data)

        return byteArray
    }
}
