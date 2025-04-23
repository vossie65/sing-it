import Foundation
import AVFoundation

/// AudioEngine handles playing musical notes, chords, and audio sequences
class AudioEngine {
    // MARK: - Singleton
    static let shared = AudioEngine()
    
    // MARK: - Audio Engine Properties
    private var audioEngine: AVAudioEngine
    private var sampler: AVAudioUnitSampler
    private var mixer: AVAudioMixerNode
    private var isInitialized = false
    
    // Tempo setting (beats per minute)
    private var tempo: Double = 60.0 // Default to 60 BPM
    
    // Note frequency mapping (in MIDI note numbers)
    private let noteMap: [String: UInt8] = [
        "C": 60,  // Middle C
        "C#": 61, "Db": 61,
        "D": 62,
        "D#": 63, "Eb": 63,
        "E": 64,
        "F": 65,
        "F#": 66, "Gb": 66,
        "G": 67,
        "G#": 68, "Ab": 68,
        "A": 69,  // A4 = 440Hz
        "A#": 70, "Bb": 70,
        "B": 71
    ]
    
    // Add a flag to track whether playback should be stopped
    private var shouldStopPlayback = false
    
    // Add properties for percussion sounds
    private var currentInstrument: UInt8 = 0 // Keep track of current instrument
    
    // MARK: - Initialization
    private init() {
        // Create audio engine components
        audioEngine = AVAudioEngine()
        sampler = AVAudioUnitSampler()
        mixer = AVAudioMixerNode()
        
        // Set up audio engine
        audioEngine.attach(sampler)
        audioEngine.attach(mixer)
        audioEngine.connect(sampler, to: mixer, format: nil)
        audioEngine.connect(mixer, to: audioEngine.mainMixerNode, format: nil)
        
        // Set SoundFont FluidR3_GM instrument 0 (piano) statt macOS-DLS
        setInstrument(0, waitForLoad: true)
    }
    
    // MARK: - Public Methods
    
    /// Start the audio engine
    func start() {
        if !isInitialized {
            do {
                try audioEngine.start()
                isInitialized = true
                print("Audio engine started successfully")
            } catch {
                print("Error starting audio engine: \(error.localizedDescription)")
            }
        }
    }
    
    /// Stop the audio engine
    func stop() {
        if isInitialized {
            audioEngine.stop()
            isInitialized = false
            print("Audio engine stopped")
        }
    }
    
    /// Stop any ongoing playback immediately
    func stopPlayback() {
        // Set flag to stop any ongoing playback
        shouldStopPlayback = true
        
        // Stop all notes on all channels
        for channel in 0..<16 {
            for note in 0..<128 {
                sampler.stopNote(UInt8(note), onChannel: UInt8(channel))
            }
        }
        
        // Print debug message
        print("Playback stopped")
    }
    
    /// Play a single note
    /// - Parameters:
    ///   - note: The note name (e.g., "C", "F#", "Bb")
    ///   - octave: The octave number (default is 4 for middle-C octave)
    ///   - velocity: The velocity/volume (0-127)
    ///   - duration: How long to play the note in seconds
    func playNote(note: String, octave: Int = 4, velocity: UInt8 = 80, duration: TimeInterval = 1.0) {
        guard isInitialized else {
            start()
            return // Added return statement to properly exit the guard scope
        }
        
        guard let baseNote = noteMap[note] else {
            print("Invalid note: \(note)")
            return
        }
        
        // Calculate correct MIDI note with octave adjustment
        let octaveOffset = (octave - 4) * 12 // Middle C is in octave 4
        let midiNote = min(127, max(0, Int(baseNote) + octaveOffset))
        
        // Play note
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.sampler.startNote(UInt8(midiNote), withVelocity: velocity, onChannel: 0)
            
            Thread.sleep(forTimeInterval: duration)
            
            self?.sampler.stopNote(UInt8(midiNote), onChannel: 0)
        }
    }
    
    /// Play a chord (multiple notes simultaneously)
    /// - Parameters:
    ///   - chordName: The name of the chord (e.g., "C", "G7", "Dm")
    ///   - octave: The octave for the root note (default is 4)
    ///   - velocity: The velocity/volume (0-127)
    ///   - duration: How long to play the chord in seconds
    func playChord(chordName: String, octave: Int = 4, velocity: UInt8 = 80, duration: TimeInterval = 1.0) {
        guard isInitialized else {
            start()
            return // Added return statement to properly exit the guard scope
        }
        
        // Parse the chord name to get root note and chord type
        let (rootNote, chordType) = parseChordName(chordName)
        
        if let notes = getChordNotes(rootNote: rootNote, chordType: chordType) {
            // Play all notes in the chord
            let midiNotes = notes.map { noteToMidi(note: $0, octaveOffset: octave - 4) }
            
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                // Play all notes simultaneously
                for midiNote in midiNotes {
                    self?.sampler.startNote(UInt8(midiNote), withVelocity: velocity, onChannel: 0)
                }
                
                Thread.sleep(forTimeInterval: duration)
                
                // Stop all notes
                for midiNote in midiNotes {
                    self?.sampler.stopNote(UInt8(midiNote), onChannel: 0)
                }
            }
        } else {
            print("Unknown chord: \(chordName)")
        }
    }
    
    /// Play a sequence of chords parsed from a chord string
    /// - Parameters:
    ///   - chordString: A string with space-separated chords (e.g., "C G Am F" or "C . . . G . . .")
    ///   - octave: The octave for the root notes
    ///   - duration: Optional duration for each chord. 
    ///              If nil, uses tempo-based timing with 1 beat per chord.
    ///              If a value is provided:
    ///                 - Values < 1.0: Interpreted as a fraction of a beat (0.5 = half beat)
    ///                 - Values >= 1.0: Interpreted as multiple beats (2.0 = two beats)
    ///   - withCountIn: If true, plays four metronome ticks before starting the chord progression
    func playChordProgression(chordString: String, octave: Int = 4, duration: TimeInterval? = nil, withCountIn: Bool = false) {
        // Reset stop flag at the start of playback
        shouldStopPlayback = false
        
        // Debugging: Print raw input
        print("Raw chord input: '\(chordString)'")
        
        // 1) Tokenize the string into chords and dots
        let tokens = tokenizeChordString(chordString)
        print("Tokenized: \(tokens)")
        
        // 2) Process tokens by replacing dots with the chord before them
        let processedChords = processChordTokens(tokens)
        print("Final processed chord progression: \(processedChords.joined(separator: " "))")
        
        // Calculate chord duration based on tempo and optional duration value
        let chordDuration: TimeInterval
        if let beatValue = duration {
            // Convert beat value to seconds based on current tempo
            chordDuration = beatsToSeconds(beatValue)
            print("Using specific duration: \(beatValue) beats = \(chordDuration) seconds at \(tempo) BPM")
        } else {
            // Default to one full beat per chord
            chordDuration = beatsToSeconds(1.0)
            print("Using default duration of 1 beat = \(chordDuration) seconds at \(tempo) BPM")
        }
        
        // Save the current instrument to restore it after count-in
        let savedInstrument = currentInstrument
        
        // Pre-load the piano instrument up front if we're using count-in
        // This will help avoid the delay when switching back
        if withCountIn {
            // First, pre-load the piano instrument that we'll need later
            setInstrument(savedInstrument, waitForLoad: true)
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // Play count-in beats if requested
            if withCountIn {
                // Switch to woodblock for count-in
                self.setInstrument(115, waitForLoad: true)
                self.playCountInBeats(count: 4)
                
                // Switch back to the saved instrument with additional delay for loading
                self.setInstrument(savedInstrument, waitForLoad: true)
                
                // Add a small additional delay after instrument change to ensure it's fully loaded
                Thread.sleep(forTimeInterval: 0.02)
            }
            
            // Play the actual chord progression
            for chord in processedChords {
                // Check if playback should stop before playing next chord
                if self.shouldStopPlayback {
                    break
                }
                
                print("Playing chord: \(chord) for \(chordDuration) seconds")
                
                // Play each chord synchronously to maintain precise timing
                self.playChordSynchronously(chordName: chord, octave: octave, duration: chordDuration)
                
                // Don't add gap after the last chord
                if chord != processedChords.last && !self.shouldStopPlayback {
                    // Small gap between chords (5% of beat duration)
                    let gapTime = chordDuration * 0.05
                    Thread.sleep(forTimeInterval: gapTime)
                }
            }
            
            // Reset stop flag after playback completes or is stopped
            self.shouldStopPlayback = false
        }
    }
    
    /// Play count-in beats (metronome ticks) at the current tempo
    /// - Parameter count: Number of beats to play (default is 4)
    func playCountInBeats(count: Int = 4) {
        print("Playing \(count) count-in beats at \(tempo) BPM")
        
        // Use percussion instrument for the click sound with delay to ensure loading
        setInstrument(115, waitForLoad: true) // Woodblock or similar percussion sound
        
        let beatDuration = beatsToSeconds(1.0)
        
        // Determine platform-specific timing parameters
        let lastTickDurationFactor: Double
        let platformDescription: String
        
        #if targetEnvironment(simulator)
            #if os(iOS)
                // iOS Simulator (iPad or iPhone simulator on macOS)
                lastTickDurationFactor = 0.10 // 10% of beat duration for iOS simulator
                platformDescription = "iOS Simulator"
            #else
                // Other simulator (should not happen, but fallback just in case)
                lastTickDurationFactor = 0.10
                platformDescription = "Unknown Simulator"
            #endif
        #else
            #if os(iOS)
                // Physical iOS device (iPad or iPhone)
                lastTickDurationFactor = 0.80 // 80% of beat duration for real iOS devices
                platformDescription = "iOS Device (iPhone/iPad)"
            #else
                // macOS native app
                lastTickDurationFactor = 0.10 // 10% of beat duration for macOS native
                platformDescription = "macOS Native"
            #endif
        #endif
        
        print("Running on \(platformDescription) - using \(lastTickDurationFactor * 100)% beat duration for last count-in tick")
        
        for i in 1...count {
            // Check if playback should stop
            if shouldStopPlayback {
                break
            }
            
            // Use high note for first beat in bar, lower note for other beats
            let isFirstBeat = (i == 1)
            let tickNote = isFirstBeat ? "A" : "E"
            let octave = isFirstBeat ? 5 : 5
            let velocity: UInt8 = isFirstBeat ? 100 : 80
            
            // Play the click sound
            sampler.startNote(UInt8(noteToMidi(note: tickNote, octaveOffset: octave - 4)), 
                             withVelocity: velocity, 
                             onChannel: 9) // Use percussion channel
            
            // Short duration for the tick sound
            Thread.sleep(forTimeInterval: 0.05)
            
            // Stop the note
            sampler.stopNote(UInt8(noteToMidi(note: tickNote, octaveOffset: octave - 4)), onChannel: 9)
            
            if i == count {
                // Last tick - play shorter duration based on platform
                Thread.sleep(forTimeInterval: beatDuration * lastTickDurationFactor)
                print("Last count-in beat shortened to \(lastTickDurationFactor * 100)% to prepare instrument switch")
            } else {
                // All other ticks: normal full beat duration after the tick sound
                let remainingBeat = beatDuration - 0.05
                Thread.sleep(forTimeInterval: remainingBeat)
            }
        }
    }
    
    /// Play a chord synchronously (for internal use in chord progressions)
    /// - Parameters:
    ///   - chordName: The name of the chord (e.g., "C", "G7", "Dm")
    ///   - octave: The octave for the root note
    ///   - velocity: The velocity/volume (0-127)
    ///   - duration: How long to play the chord in seconds
    private func playChordSynchronously(chordName: String, octave: Int = 4, velocity: UInt8 = 80, duration: TimeInterval = 1.0) {
        guard isInitialized else {
            start()
            return
        }
        
        // Parse the chord name to get root note and chord type
        let (rootNote, chordType) = parseChordName(chordName)
        
        if let notes = getChordNotes(rootNote: rootNote, chordType: chordType) {
            // Play all notes in the chord
            let midiNotes = notes.map { noteToMidi(note: $0, octaveOffset: octave - 4) }
            
            // Play all notes simultaneously
            for midiNote in midiNotes {
                self.sampler.startNote(UInt8(midiNote), withVelocity: velocity, onChannel: 0)
            }
            
            // Wait for the specified duration
            Thread.sleep(forTimeInterval: duration)
            
            // Stop all notes
            for midiNote in midiNotes {
                self.sampler.stopNote(UInt8(midiNote), onChannel: 0)
            }
        } else {
            print("Unknown chord: \(chordName)")
        }
    }
    
    /// Change the instrument sound
    /// - Parameter instrument: MIDI program number (0-127)
    /// - Parameter waitForLoad: Whether to wait for the instrument to load (default: true)
    func setInstrument(_ instrument: UInt8, waitForLoad: Bool = true) {
        currentInstrument = instrument // Store the current instrument

        // 🔍 Debug: Prüfen, ob die SoundFont gefunden wird
        if let soundFontURL = Bundle.main.url(forResource: "FluidR3_GM", withExtension: "sf2") {
            print("✅ SoundFont gefunden: \(soundFontURL)")
            
            try? sampler.loadSoundBankInstrument(
                at: soundFontURL,
                program: instrument,
                bankMSB: 0x79,
                bankLSB: 0x00
            )
        } else {
            print("❌ SoundFont NICHT gefunden!")
        }

        // Add a small delay to ensure the instrument is loaded
        if waitForLoad {
            Thread.sleep(forTimeInterval: 0.02)
        }
    }
    
    /// Set the tempo for chord progressions (in beats per minute)
    /// - Parameter bpm: Beats per minute (default is 60)
    func setTempo(_ bpm: Double) {
        tempo = max(20, min(bpm, 240)) // Clamp between 20-240 BPM
        print("Tempo set to \(tempo) BPM")
    }
    
    /// Get current tempo in beats per minute
    func getTempo() -> Double {
        return tempo
    }
    
    /// Convert beats to seconds based on current tempo
    /// - Parameter beats: Number of beats
    /// - Returns: Duration in seconds
    private func beatsToSeconds(_ beats: Double = 1.0) -> TimeInterval {
        return 60.0 / tempo * beats
    }
    
    // MARK: - Private Helper Methods
    
    private func noteToMidi(note: String, octaveOffset: Int = 0) -> Int {
        guard let baseNote = noteMap[note] else {
            return 60 // Default to middle C
        }
        
        return min(127, max(0, Int(baseNote) + (octaveOffset * 12)))
    }
    
    private func parseChordName(_ chordName: String) -> (String, String) {
        // Check for chords with sharps/flats first to avoid incorrect parsing
        if chordName.count >= 2 && (chordName[chordName.index(chordName.startIndex, offsetBy: 1)] == "#" || 
                                    chordName[chordName.index(chordName.startIndex, offsetBy: 1)] == "b") {
            if chordName.count > 2 {
                let rootNote = String(chordName.prefix(2))
                let chordType = String(chordName.dropFirst(2))
                return (rootNote, chordType)
            } else {
                return (chordName, "")  // Just a root note with sharp/flat
            }
        } else {
            if chordName.count > 1 {
                let rootNote = String(chordName.prefix(1))
                let chordType = String(chordName.dropFirst(1))
                return (rootNote, chordType)
            } else {
                return (chordName, "")  // Just a root note
            }
        }
    }
    
    private func getChordNotes(rootNote: String, chordType: String) -> [String]? {
        var notes: [String]?
        
        switch chordType.lowercased() {
        case "":  // Major chord
            notes = [rootNote, transposeNote(rootNote, semitones: 4), transposeNote(rootNote, semitones: 7)]
        case "m", "min", "minor":  // Minor chord
            notes = [rootNote, transposeNote(rootNote, semitones: 3), transposeNote(rootNote, semitones: 7)]
        case "7":  // Dominant 7th
            notes = [rootNote, transposeNote(rootNote, semitones: 4), transposeNote(rootNote, semitones: 7), 
                    transposeNote(rootNote, semitones: 10)]
        case "maj7", "major7":  // Major 7th
            notes = [rootNote, transposeNote(rootNote, semitones: 4), transposeNote(rootNote, semitones: 7), 
                    transposeNote(rootNote, semitones: 11)]
        case "m7", "min7", "minor7":  // Minor 7th
            notes = [rootNote, transposeNote(rootNote, semitones: 3), transposeNote(rootNote, semitones: 7), 
                    transposeNote(rootNote, semitones: 10)]
        case "dim", "diminished":  // Diminished
            notes = [rootNote, transposeNote(rootNote, semitones: 3), transposeNote(rootNote, semitones: 6)]
        case "aug", "augmented":  // Augmented
            notes = [rootNote, transposeNote(rootNote, semitones: 4), transposeNote(rootNote, semitones: 8)]
        case "sus2":  // Suspended 2nd
            notes = [rootNote, transposeNote(rootNote, semitones: 2), transposeNote(rootNote, semitones: 7)]
        case "sus4", "sus":  // Suspended 4th
            notes = [rootNote, transposeNote(rootNote, semitones: 5), transposeNote(rootNote, semitones: 7)]
        default:
            // Default to major chord if type not recognized
            notes = [rootNote, transposeNote(rootNote, semitones: 4), transposeNote(rootNote, semitones: 7)]
        }
        
        return notes
    }
    
    private func transposeNote(_ note: String, semitones: Int) -> String {
        // Get MIDI note number for the base note
        guard let baseNoteMidi = noteMap[note] else {
            return note
        }
        
        // Calculate the new MIDI note number
        let newMidiNote = (Int(baseNoteMidi) + semitones) % 12 + 60
        
        // Convert back to a note name
        for (noteName, midiValue) in noteMap {
            if midiValue == UInt8(newMidiNote) {
                return noteName
            }
        }
        
        return note
    }
    
    /// Extracts a chord name and the number of dots from a token like "C..." or "Am.."
    /// - Parameter token: The chord token that may include dots
    /// - Returns: A tuple containing the chord name and the count of dots
    private func extractChordAndDots(from token: String) -> (chord: String, dotCount: Int) {
        var dotCount = 0
        var chord = token
        
        // Count trailing dots (dots that directly follow the chord without spaces)
        while chord.hasSuffix(".") {
            dotCount += 1
            chord = String(chord.dropLast())
        }
        
        // Handle case where the token is only dots (like "..." or "..")
        if chord.isEmpty && dotCount > 0 {
            return ("", dotCount)
        }
        
        // Return the chord name without dots and the dot count
        return (chord, dotCount)
    }
    
    /// Tokenizes a chord string into an array of chord tokens and dot tokens
    /// - Parameter chordString: The raw chord string input
    /// - Returns: Array of tokens, where each token is either a chord or a dot
    private func tokenizeChordString(_ chordString: String) -> [String] {
        // 1. Remove whitespaces, line changes, and other non-chord symbols
        let validChordChars = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "#b"))
        let dotCharSet = CharacterSet(charactersIn: ".")
        
        var tokens: [String] = []
        var currentChord = ""
        
        // Scan through each character
        for char in chordString {
            let charString = String(char)
            
            // Check if it's a dot
            if charString == "." {
                // If we were building a chord, finish it
                if !currentChord.isEmpty {
                    tokens.append(currentChord)
                    currentChord = ""
                }
                // Add the dot as a separate token
                tokens.append(".")
            }
            // Check if it's a valid chord character
            else if CharacterSet(charactersIn: charString).isSubset(of: validChordChars) {
                // Add to current chord
                currentChord.append(char)
            }
            // Ignore everything else (spaces, line breaks, bar symbols, etc.)
            else {
                // If we were building a chord, finish it
                if !currentChord.isEmpty {
                    tokens.append(currentChord)
                    currentChord = ""
                }
            }
        }
        
        // Add the last chord if there is one
        if !currentChord.isEmpty {
            tokens.append(currentChord)
        }
        
        return tokens
    }
    
    /// Processes tokenized chord input by replacing dots with the previous chord
    /// - Parameter tokens: Array of chord and dot tokens
    /// - Returns: Array of processed chord tokens with dots replaced
    private func processChordTokens(_ tokens: [String]) -> [String] {
        var processedChords: [String] = []
        var previousChord = ""
        
        for token in tokens {
            if token == "." {
                // Replace dot token with the previous chord
                if !previousChord.isEmpty {
                    processedChords.append(previousChord)
                }
            } else {
                // It's a chord token
                processedChords.append(token)
                previousChord = token
            }
        }
        
        return processedChords
    }
}
