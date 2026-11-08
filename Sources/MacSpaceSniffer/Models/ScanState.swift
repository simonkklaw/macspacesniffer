enum ScanState {
    case idle
    case scanning(ScanProgress)
    case done
    case error(String)
}
