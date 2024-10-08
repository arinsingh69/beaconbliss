import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart'; // Import permission handler

void main() {
  runApp(BeaconDetectorApp());
}

class BeaconDetectorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bluetooth Beacon Detector',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: BeaconListScreen(),
    );
  }
}

class BeaconListScreen extends StatefulWidget {
  @override
  _BeaconListScreenState createState() => _BeaconListScreenState();
}

class _BeaconListScreenState extends State<BeaconListScreen> {
  List<ScanResult> devicesList = [];
  StreamSubscription? scanSubscription;

  @override
  void initState() {
    super.initState();
    startScan();
  }

  @override
  void dispose() {
    scanSubscription?.cancel();
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  void startScan() async {
    // Request permission
    if (await Permission.location.request().isGranted) {
      devicesList.clear();
      scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (var result in results) {
          if (!devicesList.contains(result)) {
            setState(() {
              devicesList.add(result);
            });
          }
        }
      });

      try {
        await FlutterBluePlus.startScan(timeout: Duration(seconds: 4));
      } catch (e) {
        print('Error starting scan: $e');
      }
    } else {
      // Show an alert if the location permission is denied
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Location Permission Required'),
          content: Text('Please enable location services to scan for Bluetooth devices.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Detected Beacons')),
      body: devicesList.isNotEmpty
          ? ListView.builder(
        itemCount: devicesList.length,
        itemBuilder: (context, index) {
          ScanResult result = devicesList[index];
          return ListTile(
            title: Text(result.device.name.isEmpty ? "Unknown Device" : result.device.name),
            subtitle: Text(result.device.id.toString()),
          );
        },
      )
          : Center(child: Text('No devices found')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            devicesList.clear();
            startScan();
          });
        },
        child: Icon(Icons.refresh),
      ),
    );
  }
}
