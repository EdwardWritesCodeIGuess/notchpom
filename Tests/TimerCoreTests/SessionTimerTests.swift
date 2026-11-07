import Foundation
import TimerCore

func expectEqual<T: Equatable>(_ actual: T, _ expected: T, file: StaticString = #file, line: UInt = #line) {
    precondition(actual == expected, "Expected \(expected), got \(actual)", file: file, line: line)
}
func expectTrue(_ value: Bool, file: StaticString = #file, line: UInt = #line) {
    precondition(value, "Expected true", file: file, line: line)
}
func expectFalse(_ value: Bool, file: StaticString = #file, line: UInt = #line) {
    precondition(!value, "Expected false", file: file, line: line)
}

@main
struct SessionTimerTests {
    static func main() {
        let checks = SessionTimerTests()
        checks.testPauseAndResumeKeepsExactRemainder()
        checks.testSleepingAdvancesOnlyOnePhase()
        checks.testBreakCompletionAndManualSkip()
        checks.testConfigurationClampsAndResets()
        checks.testRepeatedStartDoesNotExtendDeadline()
        print("PASS: all 5 timer behavior checks")
    }
    let now = Date(timeIntervalSince1970: 1000)

    func testPauseAndResumeKeepsExactRemainder() {
        var timer = SessionTimer(workMinutes: 2)
        timer.start(at: now)
        timer.pause(at: now.addingTimeInterval(30.5))
        expectEqual(timer.remaining, 89.5)
        expectFalse(timer.tick(at: now.addingTimeInterval(500)))
        timer.start(at: now.addingTimeInterval(600))
        expectFalse(timer.tick(at: now.addingTimeInterval(689)))
        expectEqual(timer.remaining, 0.5)
        expectTrue(timer.tick(at: now.addingTimeInterval(690)))
        expectEqual(timer.phase, .rest)
        expectFalse(timer.isRunning)
    }

    func testSleepingAdvancesOnlyOnePhase() {
        var timer = SessionTimer(workMinutes: 1, breakMinutes: 3)
        timer.start(at: now)
        expectTrue(timer.tick(at: now.addingTimeInterval(3600), autoStart: true))
        expectEqual(timer.phase, .rest)
        expectEqual(timer.remaining, 180)
        expectEqual(timer.completed, 1)
        expectTrue(timer.isRunning)
        expectFalse(timer.tick(at: now.addingTimeInterval(3601), autoStart: true))
        expectEqual(timer.remaining, 179)
    }

    func testBreakCompletionAndManualSkip() {
        var timer = SessionTimer(workMinutes: 7, breakMinutes: 1)
        timer.skip()
        expectEqual(timer.phase, .rest)
        expectEqual(timer.completed, 0)
        timer.start(at: now)
        expectTrue(timer.tick(at: now.addingTimeInterval(60)))
        expectEqual(timer.phase, .work)
        expectEqual(timer.remaining, 420)
        expectEqual(timer.completed, 0)
    }

    func testConfigurationClampsAndResets() {
        var timer = SessionTimer(workMinutes: -10, breakMinutes: 900)
        expectEqual(timer.workMinutes, 1)
        expectEqual(timer.breakMinutes, 180)
        timer.start(at: now)
        timer.configure(work: 40, rest: 8)
        expectFalse(timer.isRunning)
        expectEqual(timer.remaining, 2400)
        timer.skip()
        expectEqual(timer.remaining, 480)
        timer.start(at: now)
        timer.reset()
        expectEqual(timer.remaining, 480)
        expectFalse(timer.isRunning)
    }

    func testRepeatedStartDoesNotExtendDeadline() {
        var timer = SessionTimer(workMinutes: 1)
        timer.start(at: now)
        timer.start(at: now.addingTimeInterval(30))
        expectTrue(timer.tick(at: now.addingTimeInterval(60)))
    }
}
