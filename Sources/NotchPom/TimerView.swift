import SwiftUI

struct TimerView: View {
    @ObservedObject var model: TimerModel
    private var tint: Color { model.session.phase == .work ? .orange : .mint }

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Label("NotchPom", systemImage: "circle.lefthalf.filled")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Text("\(model.session.completed) done").font(.caption).foregroundStyle(.secondary)
            }
            VStack(spacing: 5) {
                Text(model.label.uppercased()).font(.system(size: 11, weight: .semibold, design: .rounded))
                    .tracking(3).foregroundStyle(tint)
                Text(model.time).font(.system(size: 58, weight: .light, design: .rounded))
                    .monospacedDigit()
                    .accessibilityLabel("\(model.label), \(model.time) remaining")
                Text(model.session.isRunning ? "One thing at a time." : "A little space to focus.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            ProgressView(value: model.progress).tint(tint)
            HStack(spacing: 10) {
                Button(action: model.reset) { Image(systemName: "arrow.counterclockwise").frame(width: 26, height: 24) }
                    .help("Reset this session").accessibilityLabel("Reset timer")
                Button(action: model.toggle) {
                    Label(model.session.isRunning ? "Pause" : "Start", systemImage: model.session.isRunning ? "pause.fill" : "play.fill")
                        .frame(maxWidth: .infinity).frame(height: 24)
                }.buttonStyle(.borderedProminent).tint(tint).keyboardShortcut(.space, modifiers: [])
                Button(action: model.skip) { Image(systemName: "forward.end.fill").frame(width: 26, height: 24) }
                    .help("Switch between focus and break").accessibilityLabel("Skip to next session")
            }
            Divider()
            HStack(spacing: 18) {
                durationControl("Focus", value: model.session.workMinutes) {
                    model.configure(work: $0, rest: model.session.breakMinutes)
                }
                durationControl("Break", value: model.session.breakMinutes) {
                    model.configure(work: model.session.workMinutes, rest: $0)
                }
            }.disabled(model.session.isRunning)
            Text("Minutes · changing a duration resets this session")
                .font(.system(size: 10)).foregroundStyle(.secondary)
            VStack(spacing: 10) {
                preference("Show beside notch", value: $model.showNotch)
                preference("Start next session automatically", value: $model.autoStart)
                preference("Sound when session ends", value: $model.sound)
            }.font(.system(size: 12)).toggleStyle(.switch).controlSize(.mini)
            HStack {
                Text("Click the notch timer to pause or resume.").font(.system(size: 10)).foregroundStyle(.secondary)
                Spacer()
                Button("Quit") { NSApplication.shared.terminate(nil) }
                    .font(.system(size: 11)).buttonStyle(.plain).foregroundStyle(.secondary)
            }
        }
        .padding(22).frame(width: 330)
        .modifier(TimerGlassBackground())
        .padding(6)
    }

    private func preference(_ title: String, value: Binding<Bool>) -> some View {
        HStack {
            Text(title)
            Spacer()
            Toggle(title, isOn: value).labelsHidden()
        }
    }

    private func durationControl(_ title: String, value: Int, set: @escaping (Int) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            HStack(spacing: 5) {
                TextField(title, value: Binding(get: { value }, set: set), format: .number)
                    .textFieldStyle(.roundedBorder).frame(width: 48)
                    .accessibilityLabel("\(title) duration in minutes")
                Stepper(title, value: Binding(get: { value }, set: set), in: 1...180)
                    .labelsHidden().accessibilityLabel("\(title) duration")
            }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct TimerGlassBackground: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            content.glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24))
        } else {
            content.background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
        }
    }
}

struct NotchView: View {
    @ObservedObject var model: TimerModel
    var body: some View {
        Button(action: model.toggle) {
            HStack(spacing: 7) {
                Circle().fill(model.session.phase == .work ? Color.orange : .mint).frame(width: 5, height: 5)
                Text(model.time).font(.system(size: 12, weight: .medium, design: .rounded)).monospacedDigit()
                Image(systemName: model.session.isRunning ? "pause.fill" : "play.fill").font(.system(size: 8))
            }.foregroundStyle(.white).frame(width: 108, height: 25)
                .background(.black, in: Capsule())
        }.buttonStyle(.plain)
            .accessibilityLabel("\(model.label), \(model.time), \(model.session.isRunning ? "pause" : "start")")
            .help("\(model.label) · Click to \(model.session.isRunning ? "pause" : "start")")
    }
}
