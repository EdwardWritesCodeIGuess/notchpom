import SwiftUI

private enum TimerPalette {
    static let focus = Color(red: 0.49, green: 0.40, blue: 0.88)
    static let rest = Color(red: 0.12, green: 0.65, blue: 0.60)
}

struct TimerView: View {
    @ObservedObject var model: TimerModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var tint: Color { model.session.phase == .work ? TimerPalette.focus : TimerPalette.rest }
    private var motion: Animation? { reduceMotion ? nil : .spring(response: 0.36, dampingFraction: 0.78) }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.bottom, 24)

            VStack(spacing: 9) {
                HStack(spacing: 6) {
                    Circle().fill(tint).frame(width: 6, height: 6)
                    Text(model.label.uppercased())
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(2)
                }
                .foregroundStyle(tint)

                Text(model.time)
                    .font(.system(size: 62, weight: .light, design: .rounded))
                    .monospacedDigit()
                    .tracking(-2)
                    .contentTransition(.numericText())
                    .accessibilityLabel("\(model.label), \(model.time) remaining")

                Text(model.session.isRunning ? "One thing at a time." : "A little space to focus.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .contentTransition(.opacity)
            }
            .frame(maxWidth: .infinity)

            progressBar
                .padding(.top, 23)
                .padding(.bottom, 19)

            HStack(spacing: 9) {
                Button(action: { animate(model.reset) }) {
                    Image(systemName: "arrow.counterclockwise")
                        .frame(width: 38, height: 36)
                }
                .buttonStyle(GlassControlStyle())
                .help("Reset this session")
                .accessibilityLabel("Reset timer")

                Button(action: { animate(model.toggle) }) {
                    Label(model.session.isRunning ? "Pause" : "Start", systemImage: model.session.isRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(maxWidth: .infinity).frame(height: 36)
                        .contentTransition(.opacity)
                }
                .buttonStyle(PrimaryControlStyle(tint: tint))
                .keyboardShortcut(.space, modifiers: [])

                Button(action: { animate(model.skip) }) {
                    Image(systemName: "forward.end.fill")
                        .frame(width: 38, height: 36)
                }
                .buttonStyle(GlassControlStyle())
                .help("Switch between focus and break")
                .accessibilityLabel("Skip to next session")
            }

            sectionDivider.padding(.vertical, 21)

            HStack(alignment: .top, spacing: 12) {
                durationControl("Focus", value: model.session.workMinutes) {
                    model.configure(work: $0, rest: model.session.breakMinutes)
                }
                durationControl("Break", value: model.session.breakMinutes) {
                    model.configure(work: model.session.workMinutes, rest: $0)
                }
            }
            .disabled(model.session.isRunning)
            .opacity(model.session.isRunning ? 0.55 : 1)

            Text("Minutes · changing a duration resets this session")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 9)

            sectionDivider.padding(.vertical, 19)

            VStack(spacing: 12) {
                preference("Show beside notch", value: $model.showNotch)
                preference("Start next session automatically", value: $model.autoStart)
                preference("Sound when session ends", value: $model.sound)
            }
            .font(.system(size: 12))
            .toggleStyle(.switch).controlSize(.mini)
            .tint(tint)

            HStack {
                Text("Click the notch timer to pause or resume.")
                    .font(.system(size: 10)).foregroundStyle(.secondary)
                Spacer(minLength: 4)
                Button("Quit") { NSApplication.shared.terminate(nil) }
                    .font(.system(size: 11, weight: .medium))
                    .buttonStyle(.plain).foregroundStyle(.secondary)
            }
            .padding(.top, 21)
        }
        .padding(23)
        .frame(width: 340)
        .modifier(TimerGlassBackground(tint: tint))
        .padding(6)
        .animation(motion, value: model.session.phase)
        .animation(motion, value: model.session.isRunning)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.3), value: model.progress)
    }

    private var header: some View {
        HStack(spacing: 9) {
            Image(systemName: "circle.lefthalf.filled")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 29, height: 29)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
            Text("NotchPom")
                .font(.system(size: 13, weight: .bold, design: .rounded))
            Spacer()
            Text("\(model.session.completed) done")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 9).padding(.vertical, 5)
                .background(.primary.opacity(0.06), in: Capsule())
        }
    }

    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(.primary.opacity(0.08))
                Capsule().fill(tint.gradient)
                    .frame(width: max(0, geometry.size.width * model.progress))
            }
        }
        .frame(height: 5)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Session progress")
        .accessibilityValue("\(Int(model.progress * 100)) percent")
    }

    private var sectionDivider: some View {
        Rectangle().fill(.primary.opacity(0.08)).frame(height: 1)
    }

    private func animate(_ action: () -> Void) {
        withAnimation(motion) { action() }
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
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(1).foregroundStyle(.secondary)
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

private struct GlassControlStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.primary)
            .background(.primary.opacity(configuration.isPressed ? 0.14 : 0.07), in: RoundedRectangle(cornerRadius: 12))
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.93 : 1)
            .animation(reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

private struct PrimaryControlStyle: ButtonStyle {
    let tint: Color
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .background(tint.gradient, in: RoundedRectangle(cornerRadius: 12))
            .shadow(color: tint.opacity(configuration.isPressed ? 0.12 : 0.25), radius: 8, y: 4)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .animation(reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

private struct TimerGlassBackground: ViewModifier {
    let tint: Color
    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: 24, style: .continuous)
        if #available(macOS 26.0, *) {
            content
                .background(tint.opacity(0.05), in: shape)
                .glassEffect(.regular, in: shape)
        } else {
            content
                .background(.regularMaterial, in: shape)
                .background(tint.opacity(0.05), in: shape)
                .overlay(shape.strokeBorder(.white.opacity(0.18), lineWidth: 0.5))
        }
    }
}

struct NotchView: View {
    @ObservedObject var model: TimerModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        Button(action: { withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.8)) { model.toggle() } }) {
            HStack(spacing: 7) {
                Circle().fill(model.session.phase == .work ? TimerPalette.focus : TimerPalette.rest).frame(width: 5, height: 5)
                Text(model.time).font(.system(size: 12, weight: .medium, design: .rounded)).monospacedDigit()
                Image(systemName: model.session.isRunning ? "pause.fill" : "play.fill").font(.system(size: 8))
            }.foregroundStyle(.white).frame(width: 108, height: 25)
                .background(.black, in: Capsule())
        }.buttonStyle(NotchControlStyle())
            .accessibilityLabel("\(model.label), \(model.time), \(model.session.isRunning ? "pause" : "start")")
            .help("\(model.label) · Click to \(model.session.isRunning ? "pause" : "start")")
    }
}

private struct NotchControlStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.94 : 1)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
