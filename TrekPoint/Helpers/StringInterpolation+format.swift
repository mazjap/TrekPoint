import struct Foundation.Date

extension String.StringInterpolation {
    mutating func appendInterpolation(_ date: Date, format: Date.FormatStyle) {
        appendLiteral(format.format(date))
    }
}
