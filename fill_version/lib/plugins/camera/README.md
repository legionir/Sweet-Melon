# Camera Plugin

Take photos and pick images from gallery.

## Plugin Name
`camera`

## Methods

### `takePhoto`
| Param | Type | Default |
|-------|------|---------|
| `quality` | `number (0-100)` | `80` |
| `maxWidth` | `number` | — |
| `maxHeight` | `number` | — |

**Returns:**
```json
{ "path": "/...", "name": "image.jpg", "size": 123456, "mimeType": "image/jpeg" }
```

### `pickFromGallery`
| Param | Type | Default |
|-------|------|---------|
| `multiple` | `bool` | `false` |

### `getInfo`
Returns plugin info.

## Usage
```javascript
const photo = await NativeSDK.camera.takePhoto({ quality: 90 });
console.log('Photo saved at:', photo.path);

const gallery = await NativeSDK.camera.pickFromGallery({ multiple: true });
```
