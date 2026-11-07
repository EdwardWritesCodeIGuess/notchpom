import AppKit
import Combine
import TimerCore

@MainActor
final class TimerModel: ObservableObject {
    @Published private(set) var session: SessionTimer
    @Published var showNotch: Bool { didSet { defaults.set(showNotch, forKey: "showNotch") } }
    @Published var autoStart: Bool { didSet { defaults.set(autoStart, forKey: "autoStart") } }
    @Published var sound: Bool { didSet { defaults.set(sound, forKey: "sound") } }
    private let defaults: UserDefaults
    private var ticker: AnyCancellable?
    var onChange: (() -> Void)?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: ["work": 25, "rest": 5, "showNotch": true, "sound": true])
        session = SessionTimer(workMinutes: defaults.integer(forKey: "work"), breakMinutes: defaults.integer(forKey: "rest"))
        showNotch = defaults.bool(forKey: "showNotch")
        autoStart = defaults.bool(forKey: "autoStart")
        sound = defaults.bool(forKey: "sound")
        ticker = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    var label: String { session.phase == .work ? "Focus" : "Break" }
    var time: String {
        let seconds = Int(ceil(session.remaining))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
    var progress: Double { min(1, max(0, 1 - session.remaining / session.duration)) }

    func refresh() {
        let ended = session.tick(at: Date(), autoStart: autoStart)
        if ended && sound { NSSound(named: "Glass")?.play() }
        onChange?()
    }

    func toggle() {
        refresh()
        if session.isRunning { session.pause(at: Date()) }
        else { session.start(at: Date()) }
        onChange?()
    }

    func reset() { session.reset(); onChange?() }
    func skip() { session.skip(); onChange?() }
    func configure(work: Int, rest: Int) {
        session.configure(work: work, rest: rest)
        defaults.set(session.workMinutes, forKey: "work")
        defaults.set(session.breakMinutes, forKey: "rest")
        onChange?()
    }
}
