import Foundation

enum ByteFormatter {
    static func string(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB, .useKB, .useBytes]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(min(bytes, UInt64(Int64.max))))
    }
}
