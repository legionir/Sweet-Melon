# File System Plugin

Sandboxed file system access with path traversal protection.

## Plugin Name
`fileSystem`

## Base Directories
| Name | Description |
|------|-------------|
| `documents` | App documents (default) |
| `cache` | App cache |
| `support` | App support |
| `temporary` | Temporary files |

## Methods

### `getDirectories`
**Returns:** paths for all base directories

### `writeFile`
| Param | Type | Required | Default |
|-------|------|----------|---------|
| `path` | `string` | ✅ | — |
| `content` | `string` | ✅ | — |
| `baseDir` | `string` | — | `documents` |
| `encoding` | `string` | — | `utf8` |
| `append` | `bool` | — | `false` |

### `readFile`
| Param | Type | Required | Default |
|-------|------|----------|---------|
| `path` | `string` | ✅ | — |
| `baseDir` | `string` | — | `documents` |
| `encoding` | `string` | — | `utf8` |

### `deleteFile`, `fileExists`, `stat`
All require `path` and optional `baseDir`.

### `listFiles`
| Param | Type | Required | Default |
|-------|------|----------|---------|
| `path` | `string` | — | `""` (root) |
| `baseDir` | `string` | — | `documents` |
| `recursive` | `bool` | — | `false` |

### `createDirectory`, `deleteDirectory`
Require `path`, optional `baseDir` and `recursive`.

### `getInfo`

**Returns:** `{ name, version, supportedBaseDirs, encodings }`

## Usage
```javascript
await NativeSDK.fileSystem.writeFile('logs/app.log', 'Hello World');
const { content } = await NativeSDK.fileSystem.readFile('logs/app.log');
const { items } = await NativeSDK.fileSystem.listFiles('logs', { recursive: true });
```

## Security
- Path traversal (`..`) is blocked
- All paths are sandboxed to base directories
