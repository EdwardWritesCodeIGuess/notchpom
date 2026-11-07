import Foundation

public struct SessionTimer {
    public enum Phase: String { case work, rest }
    public private(set) var phase: Phase = .work
    public private(set) var isRunning = false
    public private(set) var remaining: TimeInterval
    public private(set) var workMinutes: Int
    public private(set) var breakMinutes: Int
    public private(set) var completed = 0
    private var deadline: Date?

    public init(workMinutes: Int = 25, breakMinutes: Int = 5) {
        self.workMinutes = min(180, max(1, workMinutes))
        self.breakMinutes = min(180, max(1, breakMinutes))
        remaining = TimeInterval(self.workMinutes * 60)
    }

    public var duration: TimeInterval {
        TimeInterval((phase == .work ? workMinutes : breakMinutes) * 60)
    }

    public mutating func start(at now: Date) {
        guard !isRunning else { return }
        deadline = now.addingTimeInterval(remaining)
        isRunning = true
    }

    public mutating func pause(at now: Date) {
        guard isRunning, let deadline else { return }
        remaining = max(0, deadline.timeIntervalSince(now))
        isRunning = false
        self.deadline = nil
    }

    public mutating func reset() {
        isRunning = false
        deadline = nil
        remaining = duration
    }

    public mutating func skip() {
        phase = phase == .work ? .rest : .work
        reset()
    }

    public mutating func configure(work: Int, rest: Int) {
        workMinutes = min(180, max(1, work))
        breakMinutes = min(180, max(1, rest))
        reset()
    }

    /// Uses a wall-clock deadline so sleep and delayed UI updates do not cause drift.
    /// A late tick advances exactly one phase; sleeping never invents completed sessions.
    @discardableResult
    public mutating func tick(at now: Date, autoStart: Bool = false) -> Bool {
        guard isRunning, let deadline else { return false }
        remaining = max(0, deadline.timeIntervalSince(now))
        guard remaining == 0 else { return false }
        if phase == .work { completed += 1 }
        skip()
        if autoStart { start(at: now) }
        return true
    }
}
