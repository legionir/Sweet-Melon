# Audio Plugin

Record audio and play audio files/URLs.

## Plugin Name
`audio`

## Recorder Methods

| Method | Args | Returns |
|--------|------|---------|
| `startRecording` | `fileName?, encoder?, bitRate?, sampleRate?` | `{ path }` |
| `stopRecording` | — | `{ path, size }` |
| `isRecording` | — | `{ recording: bool }` |

Encoders: `aacLc`, `aacEld`, `aacHe`, `opus`, `wav`, `flac`

## Player Methods

| Method | Args | Returns |
|--------|------|---------|
| `play` | `path or url` | `{ playing: true }` |
| `pause` | — | `{ paused }` |
| `resume` | — | `{ resumed }` |
| `stop` | — | `{ stopped }` |
| `seek` | `positionMs` | `{ seeked }` |
| `setVolume` | `volume (0-1)` | `{ volume }` |
| `getDuration` | — | `{ durationMs }` |
| `getPosition` | — | `{ positionMs }` |

## Events
- `audio.playerState` — `{ state, isPlaying }`
- `audio.position` — `{ positionMs, positionSec }`

## Usage
```javascript
// Record
await NativeSDK.audio.startRecording({ encoder: 'aacLc' });
// ... user speaks ...
const rec = await NativeSDK.audio.stopRecording();

// Play back
await NativeSDK.audio.play({ path: rec.path });
```
