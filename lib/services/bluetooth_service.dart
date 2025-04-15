import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothService with ChangeNotifier {
  BluetoothConnection? _connection;
  bool isConnected = false;
  String incomingRFID = "";

  final Map<String, int> _productCounts = {}; // local cache
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  BluetoothService() {
    _init();
  }

  void _init() async {
    await _requestBluetoothPermissions();
    _connectToBluetooth();
  }

  Map<String, int> get productCounts => _productCounts;

  /// 🔌 Connect to HC-06
  void _connectToBluetooth() async {
    const String targetAddress = "00:23:09:01:80:E8"; // Your HC-06 MAC

    try {
      _connection = await BluetoothConnection.toAddress(targetAddress);
      isConnected = true;
      print('✅ Connected to Bluetooth device at $targetAddress');

      _connection!.input!.listen(
        _onDataReceived,
        onDone: _onDisconnected,
        onError: (error) {
          print('❌ Bluetooth Error: $error');
          _handleDisconnection();
        },
      );
    } catch (e) {
      print('❌ Failed to connect: $e');
      _handleDisconnection();
    }

    notifyListeners();
  }

  /// 🔐 Bluetooth & Location permissions
  Future<void> _requestBluetoothPermissions() async {
    final statuses = await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
    ].request();

    if (statuses.values.any((status) => status.isDenied)) {
      print("⚠️ Some permissions denied. Bluetooth might not work.");
    }
  }

  /// 📥 Clean + extract RFID tag
  void _onDataReceived(Uint8List data) {
    final rawString = utf8.decode(data).trim();
    print("📥 Raw Data: $rawString");

    final cleanedRFID = _extractRFID(rawString);
    print("📥 Cleaned RFID: $cleanedRFID");

    if (cleanedRFID.isNotEmpty) {
      incomingRFID = cleanedRFID;
      _updateProductCount(cleanedRFID);
      notifyListeners();
    } else {
      print("⚠️ Could not extract a valid RFID tag.");
    }
  }

  /// 🔍 Extract tag using regex: e.g. "14 B1 CE 72"
  String _extractRFID(String input) {
    final match = RegExp(r'([0-9A-Fa-f]{2}(?: [0-9A-Fa-f]{2}){3,})').firstMatch(input);
    return match?.group(0)?.trim() ?? '';
  }

  /// 🔁 Update product count in Firestore
  /// 🔁 Update product count in Firestore and local cache
Future<void> _updateProductCount(String tag) async {
  try {
    print("🧪 Looking for product with RFID Tag ID: [$tag]");

    final snapshot = await _firestore
        .collection('products')
        .where('RFID Tag ID', isEqualTo: tag) // Search by RFID Tag ID
        .get();

    if (snapshot.docs.isNotEmpty) {
      // Get the first document matching the RFID tag
      final docRef = snapshot.docs.first.reference;
      final currentCount = snapshot.docs.first.data()['count'] ?? 0;

      // Update the count in Firestore
      await docRef.update({'count': currentCount + 1});
      print("🛒 Updated count for $tag → ${currentCount + 1}");

      // Update the local cache
      _productCounts[tag] = currentCount + 1;

      // Notify listeners to update the UI
      notifyListeners();
    } else {
      print("🚨 No product found with RFID Tag ID [$tag]!");
      // Optionally avoid creating a new document or handle it in some other way
    }
  } catch (e) {
    print("❌ Firestore update error: $e");
  }

  notifyListeners();
}


  /// 🔌 Handle disconnect
  void _onDisconnected() {
    print('🔌 Disconnected from device');
    _handleDisconnection();
  }

  void _handleDisconnection() {
    isConnected = false;
    _connection = null;
    notifyListeners();
  }

  /// 👋 Manual disconnect
  void disconnect() {
    _connection?.dispose();
    _connection = null;
    isConnected = false;
    notifyListeners();
    print('👋 Manually disconnected');
  }
}
