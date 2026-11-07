import Foundation
import TimerCore

func XCTAssertEqual<T: Equatable>(_ actual: T, _ expected: T, file: StaticString = #filePath, line: UInt = #line) {
    precondition(actual == expected, "Expected \(expected), got \(actual)", file: file, line: line)
}
func XCTAssertTrue(_ value: Bool, file: StaticString = #filePath, line: UInt = #line) {
    precondition(value, "Expected true", file: file, line: line)
}
func XCTAssertFalse(_ value: Bool, file: StaticString = #filePath, line: UInt = #line) {
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
        XCTAssertEqual(timer.remaining, 89.5)
        XCTAssertFalse(timer.tick(at: now.addingTimeInterval(500)))
        timer.start(at: now.addingTimeInterval(600))
        XCTAssertFalse(timer.tick(at: now.addingTimeInterval(689)))
        XCTAssertEqual(timer.remaining, 0.5)
        XCTAssertTrue(timer.tick(at: now.addingTimeInterval(690)))
        XCTAssertEqual(timer.phase, .rest)
        XCTAssertFalse(timer.isRunning)
    }

    func testSleepingAdvancesOnlyOnePhase() {
        var timer = SessionTimer(workMinutes: 1, breakMinutes: 3)
        timer.start(at: now)
        XCTAssertTrue(timer.tick(at: now.addingTimeInterval(3600), autoStart: true))
        XCTAssertEqual(timer.phase, .rest)
        XCTAssertEqual(timer.remaining, 180)
        XCTAssertEqual(timer.completed, 1)
        XCTAssertTrue(timer.isRunning)
        XCTAssertFalse(timer.tick(at: now.addingTimeInterval(3601), autoStart: true))
        XCTAssertEqual(timer.remaining, 179)
    }

    func testBreakCompletionAndManualSkip() {
        var timer = SessionTimer(workMinutes: 7, breakMinutes: 1)
        timer.skip()
        XCTAssertEqual(timer.phase, .rest)
        XCTAssertEqual(timer.completed, 0)
        timer.start(at: now)
        XCTAssertTrue(timer.tick(at: now.addingTimeInterval(60)))
        XCTAssertEqual(timer.phase, .work)
        XCTAssertEqual(timer.remaining, 420)
        XCTAssertEqual(timer.completed, 0)
    }

    func testConfigurationClampsAndResets() {
        var timer = SessionTimer(workMinutes: -10, breakMinutes: 900)
        XCTAssertEqual(timer.workMinutes, 1)
        XCTAssertEqual(timer.breakMinutes, 180)
        timer.start(at: now)
        timer.configure(work: 40, rest: 8)
        XCTAssertFalse(timer.isRunning)
        XCTAssertEqual(timer.remaining, 2400)
        timer.skip()
        XCTAssertEqual(timer.remaining, 480)
        timer.start(at: now)
        timer.reset()
        XCTAssertEqual(timer.remaining, 480)
        XCTAssertFalse(timer.isRunning)
    }

    func testRepeatedStartDoesNotExtendDeadline() {
        var timer = SessionTimer(workMinutes: 1)
        timer.start(at: now)
        timer.start(at: now.addingTimeInterval(30))
        XCTAssertTrue(timer.tick(at: now.addingTimeInterval(60)))
    }
}
