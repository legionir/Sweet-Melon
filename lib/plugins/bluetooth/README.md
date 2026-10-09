# Bluetooth BLE Plugin

Scan, connect, read/write BLE characteristics.

## Plugin Name
`bluetooth`

## Methods

| Method | Description |
|--------|-------------|
| `isAvailable` | Check BLE support |
| `isOn` | Check if Bluetooth is enabled |
| `startScan` | Start BLE scan |
| `stopScan` | Stop scanning |
| `connect` | Connect to device by ID |
| `disconnect` | Disconnect from device |
| `discoverServices` | List services & characteristics |
| `readCharacteristic` | Read value |
| `writeCharacteristic` | Write value (base64) |
| `getConnectedDevices` | List connected devices |

## Events
- `bluetooth.deviceFound` — `{ deviceId, name, rssi }`
- `bluetooth.connectionState` — `{ deviceId, state, connected }`

## Usage
```javascript
await NativeSDK.bluetooth.startScan({ timeoutSeconds: 10 });
NativeSDK.on('bluetooth.deviceFound', async (device) => {
  if (device.name === 'MySensor') {
    await NativeSDK.bluetooth.connect(device.deviceId);
    const services = await NativeSDK.bluetooth.discoverServices(device.deviceId);
    const value = await NativeSDK.bluetooth.readCharacteristic({
      deviceId: device.deviceId,
      serviceUuid: '180d',
      characteristicUuid: '2a37'
    });
  }
});
```
