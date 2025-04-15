import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothScreen extends StatefulWidget {
  const BluetoothScreen({super.key});

  @override
  State<BluetoothScreen> createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  BluetoothConnection? _connection;
  bool _isConnecting = false;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _initBluetooth();
  }

  Future<void> _initBluetooth() async {
    await _requestPermissions();
    await _getBondedDevices();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
  }

  Future<void> _getBondedDevices() async {
    final bluetooth = FlutterBluetoothSerial.instance;

    bool isEnabled = await bluetooth.isEnabled ?? false;
    if (!isEnabled) {
      await bluetooth.requestEnable();
    }

    List<BluetoothDevice> bondedDevices = await bluetooth.getBondedDevices();
    setState(() {
      _devices = bondedDevices;
    });
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() {
      _isConnecting = true;
      _selectedDevice = device;
    });

    try {
      BluetoothConnection connection =
          await BluetoothConnection.toAddress(device.address);
      print('✅ Connected to ${device.name}');
      setState(() {
        _connection = connection;
        _isConnected = true;
      });

      connection.input!.listen((data) {
        print('📨 Data received: ${String.fromCharCodes(data)}');
      }).onDone(() {
        print('🔌 Disconnected by remote device');
        setState(() {
          _isConnected = false;
        });
      });
    } catch (e) {
      print('❌ Cannot connect, exception occurred: $e');
    }

    setState(() {
      _isConnecting = false;
    });
  }

  @override
  void dispose() {
    _connection?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Connection'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _getBondedDevices,
          )
        ],
      ),
      body: Column(
        children: [
          if (_isConnected && _selectedDevice != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '✅ Connected to ${_selectedDevice!.name}',
                style: const TextStyle(fontSize: 18, color: Colors.green),
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: _devices.length,
              itemBuilder: (context, index) {
                final device = _devices[index];
                return ListTile(
                  title: Text(device.name ?? "Unknown"),
                  subtitle: Text(device.address),
                  trailing: _selectedDevice == device && _isConnected
                      ? const Icon(Icons.bluetooth_connected, color: Colors.green)
                      : const Icon(Icons.bluetooth),
                  onTap: () => _connectToDevice(device),
                );
              },
            ),
          ),
          if (_isConnecting)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
