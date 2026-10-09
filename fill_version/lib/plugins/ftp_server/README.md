# FTP Server Plugin

Simple FTP server for sharing files from device.

## Plugin Name
`ftpServer`

## Methods

| Method | Args | Description |
|--------|------|-------------|
| `start` | `rootDir, port?, username?, password?` | Start FTP server |
| `stop` | — | Stop server |
| `getClients` | — | Connected clients |
| `getStats` | — | Server statistics |
| `kickClient` | `sessionId` | Disconnect a client |

## Events

| Event | Data |
|-------|------|
| `ftpServer.started` | `{ port, rootDir }` |
| `ftpServer.clientConnected` | `{ sessionId, remoteAddress }` |
| `ftpServer.clientDisconnected` | `{ sessionId }` |
| `ftpServer.login` | `{ sessionId, username }` |
| `ftpServer.fileUploaded` | `{ sessionId, file }` |
| `ftpServer.fileDownloaded` | `{ sessionId, file }` |

## Supported FTP Commands
USER, PASS, PWD, CWD, LIST, RETR, STOR, DELE, MKD, RMD, SIZE, PASV, TYPE, SYST, FEAT, QUIT, NOOP

## Usage

```javascript
// Start FTP server
const dirs = await NativeSDK.fileSystem.getDirectories();
const { port, url } = await NativeSDK.ftpServer.start({
  rootDir: dirs.documents,
  port: 2121,
  username: 'user',
  password: 'pass123'
});
console.log('FTP server:', url);  // ftp://0.0.0.0:2121

// Show connection info
const { ip } = await NativeSDK.networkInfo.getLocalIp();
await NativeSDK.dialog.alert({
  title: 'FTP Server Running',
  message: `Connect with any FTP client:\n\nHost: ${ip}\nPort: ${port}\nUser: user\nPass: pass123`
});

// Monitor uploads
NativeSDK.on('ftpServer.fileUploaded', (data) => {
  NativeSDK.toast.show('File received: ' + data.file);
});

// Monitor activity
NativeSDK.on('ftpServer.clientConnected', (data) => {
  console.log('FTP client connected:', data.remoteAddress);
});

// Get stats
const stats = await NativeSDK.ftpServer.getStats();
console.log('Active clients:', stats.activeClients);

// Stop
await NativeSDK.ftpServer.stop();
```
