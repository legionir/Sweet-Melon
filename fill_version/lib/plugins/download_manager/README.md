# Download Manager Plugin

Download files with real-time progress events.

## Plugin Name
`downloadManager`

## Methods

### `download`
| Param | Type | Required | Default |
|-------|------|----------|---------|
| `url` | `string` | ✅ | — |
| `fileName` | `string` | — | from URL |
| `baseDir` | `string` | — | `documents` |
| `path` | `string` | — | `downloads/` |
| `taskId` | `string` | — | auto |
| `overwrite` | `bool` | — | `true` |

### `cancel` — cancel by taskId
### `cancelAll`
### `getActive`

## Events
- `download.progress` — `{ taskId, percent, receivedBytes, totalBytes }`
- `download.complete` — `{ taskId, path, size, mimeType }`
- `download.error` — `{ taskId, error }`

## Usage
```javascript
NativeSDK.on('download.progress', (data) => {
  progressBar.style.width = data.percent + '%';
});

const result = await NativeSDK.downloadManager.download({
  url: 'https://example.com/large-file.zip',
  fileName: 'archive.zip'
});
```
