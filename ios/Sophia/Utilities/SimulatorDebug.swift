import Foundation

/// Debug affordances that must never ship on a real device or a Release build.
///
/// Both gates are compile-time:
/// - `DEBUG` is false in App Store / TestFlight Release, so the true branch is stripped.
/// - `targetEnvironment(simulator)` is false on any physical iPhone, Debug included.
enum SimulatorDebug {
    static var allowsLoginBypass: Bool {
        #if DEBUG && targetEnvironment(simulator)
        true
        #else
        false
        #endif
    }
}
