# SSH Server Plugin

Simple command execution server (sandbox-safe, not full SSH protocol).

## Plugin Name
`sshServer`

## Important Note
This is a simplified command server using plain TCP, NOT the real SSH protocol. It provides a shell-like interface with sandbox restrictions for safe command execution. For production SSH, use the `sshClient` plugin with a real SSH server.

## Methods

| Method | Args | Description |
|--------|------|-------------|
| `start` | `port?, host?, username?, password?` | Start server |
| `stop` | — | Stop server |
| `getClients` | — | Connected sessions |
| `getStats` | — | Statistics |
| `kickClient` | `sessionId` | Disconnect a session |
| `setAllowedCommands` | `commands[]` | Set sandbox whitelist |

## Events

| Event | Data |
|-------|------|
| `sshServer.started` | `{ port, host }` |
| `sshServer.clientConnected` | `{ sessionId, remoteAddress }` |
| `sshServer.clientDisconnected` | `{ sessionId }` |
| `sshServer.login` | `{ sessionId, username }` |
| `sshServer.command` | `{ sessionId, command, args, fullCommand }` |
| `sshServer.commandOutput` | `{ sessionId, command, exitCode, outputLength }` |

## Default Allowed Commands (Sandbox)
`ls`, `pwd`, `whoami`, `date`, `echo`, `cat`, `head`, `tail`, `wc`, `grep`, `uname`, `uptime`, `df`, `du`, `free`, `hostname`, `id`, `env`, `printenv`

## Usage

```javascript
// Start command server
const { port } = await NativeSDK.sshServer.start({
  port: 2222,
  username: 'admin',
  password: 'secret'
});

// Connect with: telnet <device_ip> 2222
// Or: nc <device_ip> 2222

// Monitor commands
NativeSDK.on('sshServer.command', (data) => {
  console.log(`[${data.sessionId}] ${data.fullCommand}`);
});

// Custom allowed commands
await NativeSDK.sshServer.setAllowedCommands([
  'ls', 'pwd', 'date', 'echo', 'cat', 'df'
]);

// Monitor logins
NativeSDK.on('sshServer.login', (data) => {
  NativeSDK.toast.show('Shell login: ' + data.username);
});

// Get active sessions
const { clients } = await NativeSDK.sshServer.getClients();
clients.forEach(c => {
  console.log(`${c.id}: ${c.username} from ${c.remoteAddress} (${c.commands} commands)`);
});

// Kick user
await NativeSDK.sshServer.kickClient('ssh_session_3');

// Stop
await NativeSDK.sshServer.stop();
```
