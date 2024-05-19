//
//  Timestamp.swift
//  Chat
//
//  Created by Jacob Ilin on 4/9/23.
//

import Foundation

class Timestamp: Comparable {
    private let seconds: Int
    private let nanoseconds: Int

    init(seconds: Int, nanoseconds: Int) {
        self.seconds = seconds
        self.nanoseconds = nanoseconds
        Timestamp.validateRange(seconds: seconds, nanoseconds: nanoseconds)
    }

    convenience init(millisecondsSinceEpoch: Int) {
        let seconds = millisecondsSinceEpoch / 1000
        let nanoseconds = (millisecondsSinceEpoch - seconds * 1000) * 1000000
        self.init(seconds: seconds, nanoseconds: nanoseconds)
    }

    convenience init(microsecondsSinceEpoch: Int) {
        let seconds = microsecondsSinceEpoch / 1000000
        let nanoseconds = (microsecondsSinceEpoch - seconds * 1000000) * 1000
        self.init(seconds: seconds, nanoseconds: nanoseconds)
    }

    convenience init(date: Date) {
        let microsecondsSinceEpoch = Int(date.timeIntervalSince1970 * 1_000_000)
        self.init(microsecondsSinceEpoch: microsecondsSinceEpoch)
    }

    class func now() -> Timestamp {
        return Timestamp(date: Date())
    }

    var millisecondsSinceEpoch: Int {
        return seconds * 1000 + nanoseconds / 1000000
    }

    var microsecondsSinceEpoch: Int {
        return seconds * 1000000 + nanoseconds / 1000
    }

    func toDate() -> Date {
        return Date(timeIntervalSince1970: TimeInterval(microsecondsSinceEpoch) / 1_000_000)
    }

    static func < (lhs: Timestamp, rhs: Timestamp) -> Bool {
        if lhs.seconds == rhs.seconds {
            return lhs.nanoseconds < rhs.nanoseconds
        }
        return lhs.seconds < rhs.seconds
    }

    static func == (lhs: Timestamp, rhs: Timestamp) -> Bool {
        return lhs.seconds == rhs.seconds && lhs.nanoseconds == rhs.nanoseconds
    }

    private static func validateRange(seconds: Int, nanoseconds: Int) {
        let billion = 1_000_000_000
        let startOfTime = -62_135_596_800
        let endOfTime = 253_402_300_800

        assert(nanoseconds >= 0, "Timestamp nanoseconds out of range: \(nanoseconds)")
        assert(nanoseconds < billion, "Timestamp nanoseconds out of range: \(nanoseconds)")
        assert(seconds >= startOfTime, "Timestamp seconds out of range: \(seconds)")
        assert(seconds < endOfTime, "Timestamp seconds out of range: \(seconds)")
    }
}

