# UDP Server Plugin

Receive UDP datagrams and respond or broadcast.

## Plugin Name
`udpServer`

## Methods

| Method | Args | Description |
|--------|------|-------------|
| `start` | `port?, host?, broadcast?, id?` | Bind UDP server |
| `stop` | `id` | Stop specific server |
| `stopAll` | — | Stop all servers |
| `sendTo` | `serverId, data, host, port` | Send to specific address |
| `broadcast` | `serverId, data, port, broadcastAddress?` | Broadcast to network |
| `getServers` | — | List active servers |
| `getStats` | `id` | Server statistics |

## Events

| Event | Data |
|-------|------|
| `udpServer.started` | `{ id, port, host }` |
| `udpServer.data` | `{ serverId, data, senderAddress, senderPort, bytes }` |

## Usage

```javascript
// Start UDP server
const { id, port } = await NativeSDK.udpServer.start({ port: 5000 });
console.log('UDP listening on port:', port);

// Receive data
NativeSDK.on('udpServer.data', (msg) => {
  console.log(`From ${msg.senderAddress}:${msg.senderPort} → ${msg.data}`);
  
  // Echo back
  NativeSDK.udpServer.sendTo(msg.serverId, 'ACK: ' + msg.data, msg.senderAddress, msg.senderPort);
});

// Broadcast discovery
await NativeSDK.udpServer.broadcast(id, 'DISCOVER', 5001);

// Device discovery pattern
const discoveryServer = await NativeSDK.udpServer.start({ port: 5001, broadcast: true });

NativeSDK.on('udpServer.data', (msg) => {
  if (msg.data === 'DISCOVER') {
    const myInfo = JSON.stringify({ name: 'MyDevice', ip: myIp });
    NativeSDK.udpServer.sendTo(discoveryServer.id, myInfo, msg.senderAddress, msg.senderPort);
  }
});

// Stats
const stats = await NativeSDK.udpServer.getStats(id);
console.log('Received:', stats.receivedCount, 'packets');

// Cleanup
await NativeSDK.udpServer.stopAll();
```
