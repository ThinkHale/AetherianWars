import AVFoundation
import FightCore

enum SoundEffect: String, CaseIterable {
    case hitLight = "sfx-hit-light", hitMedium = "sfx-hit-medium", hitHeavy = "sfx-hit-heavy", hitCrushing = "sfx-hit-crushing"
    case block = "sfx-block", armor = "sfx-armor", counter = "sfx-counter"
    case whooshLight = "sfx-whoosh-light", whooshHeavy = "sfx-whoosh-heavy"
    case bow = "sfx-bow", crossbow = "sfx-crossbow", orb = "sfx-orb", seal = "sfx-seal", dust = "sfx-dust", gallop = "sfx-gallop"
    case jump = "sfx-jump", land = "sfx-land", dash = "sfx-dash", grab = "sfx-grab"
    case gong = "sfx-gong", horn = "sfx-horn", ko = "sfx-ko", superFlash = "sfx-super", heal = "sfx-heal", victory = "sfx-victory"
    case tap = "ui-tap", select = "ui-empire-chosen", reward = "ui-reward", error = "ui-error"

    static func hit(_ impact: Impact) -> SoundEffect {
        switch impact {
        case .light: .hitLight
        case .medium: .hitMedium
        case .heavy: .hitHeavy
        case .crushing: .hitCrushing
        }
    }
}

enum MusicTrack: String {
    case title = "music-title"
    case select = "music-march"
    case rome = "music-kingdom-rome", egypt = "music-kingdom-egypt", persia = "music-kingdom-persia", han = "music-kingdom-han"

    static func stage(_ stage: StageID) -> MusicTrack {
        switch stage.empire {
        case .rome: .rome
        case .egypt: .egypt
        case .persia: .persia
        case .han: .han
        case nil: .select
        }
    }
}

/// Music and sound effects. Effects are decoded once into memory and played
/// on a small pool of voices so a flurry of blows never stutters; music
/// crossfades between tracks. Plays alongside other apps' audio and respects
/// the silent switch.
@MainActor
final class AudioManager {
    static let shared = AudioManager()

    private let engine = AVAudioEngine()
    private var voices: [AVAudioPlayerNode] = []
    private var nextVoice = 0
    private var buffers: [SoundEffect: AVAudioPCMBuffer] = [:]
    private var lastPlayed: [SoundEffect: TimeInterval] = [:]
    private var music: AVAudioPlayer?
    private var fadingOut: AVAudioPlayer?
    private(set) var currentTrack: MusicTrack?
    private var started = false

    var musicVolume: Float = 0.7 { didSet { music?.volume = musicVolume * 0.6 } }
    var effectsVolume: Float = 0.9 { didSet { engine.mainMixerNode.outputVolume = effectsVolume } }

    private init() {}

    func start() {
        guard !started else { return }
        started = true
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 2)!
        for _ in 0..<12 {
            let voice = AVAudioPlayerNode()
            engine.attach(voice)
            engine.connect(voice, to: engine.mainMixerNode, format: format)
            voices.append(voice)
        }
        for effect in SoundEffect.allCases { buffers[effect] = load(effect.rawValue, format: format) }
        engine.mainMixerNode.outputVolume = effectsVolume
        startEngine()
        NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] note in
            guard let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                  AVAudioSession.InterruptionType(rawValue: raw) == .ended else { return }
            Task { @MainActor in self?.resume() }
        }
        NotificationCenter.default.addObserver(forName: .AVAudioEngineConfigurationChange, object: engine, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.startEngine() }
        }
    }

    private func startEngine() {
        guard !engine.isRunning else { return }
        engine.prepare()
        try? engine.start()
        for voice in voices where !voice.isPlaying { voice.play() }
    }

    func resume() {
        try? AVAudioSession.sharedInstance().setActive(true)
        startEngine()
        music?.play()
    }

    /// Reads a bundled sound (WAV or AAC) into a buffer in the engine's format.
    private func load(_ name: String, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let url = ["wav", "m4a", "caf"].lazy.compactMap { Bundle.main.url(forResource: name, withExtension: $0) }.first
        guard let url, let file = try? AVAudioFile(forReading: url) else { return nil }
        guard let source = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length)),
              (try? file.read(into: source)) != nil else { return nil }
        if source.format == format { return source }
        guard let converter = AVAudioConverter(from: source.format, to: format) else { return nil }
        let ratio = format.sampleRate / source.format.sampleRate
        guard let output = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(Double(source.frameLength) * ratio) + 1024) else { return nil }
        var fed = false
        var error: NSError?
        converter.convert(to: output, error: &error) { _, status in
            if fed { status.pointee = .endOfStream; return nil }
            fed = true
            status.pointee = .haveData
            return source
        }
        return error == nil ? output : nil
    }

    /// Plays an effect. The same effect is not stacked within 30 ms, and a
    /// small pitch-free variation in volume keeps repeats from sounding canned.
    func play(_ effect: SoundEffect, volume: Float = 1) {
        guard started, let buffer = buffers[effect], effectsVolume > 0 else { return }
        let now = ProcessInfo.processInfo.systemUptime
        if let last = lastPlayed[effect], now - last < 0.03 { return }
        lastPlayed[effect] = now
        if !engine.isRunning { startEngine() }
        let voice = voices[nextVoice]
        nextVoice = (nextVoice + 1) % voices.count
        voice.volume = volume * Float.random(in: 0.88...1)
        voice.scheduleBuffer(buffer, at: nil, options: .interrupts)
        if !voice.isPlaying { voice.play() }
    }

    func playMusic(_ track: MusicTrack?) {
        guard track != currentTrack else { return }
        currentTrack = track
        fadingOut?.stop()
        if let old = music {
            old.setVolume(0, fadeDuration: 0.8)
            fadingOut = old
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { [weak old] in old?.stop() }
        }
        music = nil
        guard let track, let url = Bundle.main.url(forResource: track.rawValue, withExtension: "m4a"),
              let player = try? AVAudioPlayer(contentsOf: url) else { return }
        player.numberOfLoops = -1
        player.volume = 0
        player.prepareToPlay()
        player.play()
        player.setVolume(musicVolume * 0.6, fadeDuration: 1.0)
        music = player
    }

    func duckMusic(_ ducked: Bool) {
        music?.setVolume(musicVolume * (ducked ? 0.2 : 0.6), fadeDuration: 0.3)
    }
}
