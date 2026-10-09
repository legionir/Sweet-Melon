# TCP Server Plugin

Multi-client TCP server with message routing.

## Plugin Name
`tcpServer`

## Methods

| Method | Args | Description |
|--------|------|-------------|
| `start` | `port?, host?, maxClients?, id?` | Start TCP server |
| `stop` | `id` | Stop server |
| `stopAll` | — | Stop all servers |
| `sendToClient` | `serverId, clientId, data` | Send to one client |
| `sendToAll` | `serverId, data, exclude?` | Broadcast to all clients |
| `disconnectClient` | `serverId, clientId` | Kick a client |
| `getClients` | `serverId` | List connected clients |
| `getServers` | — | List active servers |
| `getStats` | `id` | Server statistics |

## Events

| Event | Data |
|-------|------|
| `tcpServer.started` | `{ id, port, host, maxClients }` |
| `tcpServer.clientConnected` | `{ serverId, clientId, remoteAddress, remotePort }` |
| `tcpServer.data` | `{ serverId, clientId, data, bytes, messageNumber }` |
| `tcpServer.clientDisconnected` | `{ serverId, clientId, totalClients }` |
| `tcpServer.clientError` | `{ serverId, clientId, error }` |

## Usage

```javascript
// Chat server
const srv = await NativeSDK.tcpServer.start({ port: 9000, maxClients: 50 });
console.log('TCP server on port:', srv.port);

// Handle messages
NativeSDK.on('tcpServer.data', (msg) => {
  console.log(`[${msg.clientId}]: ${msg.data}`);
  
  // Broadcast to all except sender
  NativeSDK.tcpServer.sendToAll(msg.serverId, `${msg.clientId}: ${msg.data}`, msg.clientId);
});

// Welcome new clients
NativeSDK.on('tcpServer.clientConnected', (client) => {
  NativeSDK.tcpServer.sendToClient(client.serverId, client.clientId, 'Welcome!\n');
  NativeSDK.tcpServer.sendToAll(client.serverId, `${client.clientId} joined\n`, client.clientId);
});

// Handle disconnection
NativeSDK.on('tcpServer.clientDisconnected', (client) => {
  NativeSDK.tcpServer.sendToAll(client.serverId, `${client.clientId} left\n`);
});

// Admin kick
await NativeSDK.tcpServer.disconnectClient(srv.id, 'client_5');

// Stats
const stats = await NativeSDK.tcpServer.getStats(srv.id);
console.log('Clients:', stats.clients, 'Total bytes:', stats.totalReceivedBytes);
```
