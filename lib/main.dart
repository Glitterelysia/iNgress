import 'package:flutter/material.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:amap_flutter_location/amap_flutter_location.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Geo Game',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MenuScreen(),
    );
  }
}

class MenuScreen extends StatelessWidget {
  const MenuScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geo Game Menu'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MapScreen()),
            );
          },
          child: const Text('开始游戏'),
        ),
      ),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  AMapController? mapController;
  AMapFlutterLocation? location;
  LatLng? currentLocation;
  final LatLng targetLocation = const LatLng(39.909187, 116.397451);
  final double threshold = 0.0001;

  @override
  void initState() {
    super.initState();
    _requestPermissionAndStartLocation();
  }

  Future<void> _requestPermissionAndStartLocation() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      _setupLocationListener();
    } else {
      // 权限被拒绝，处理相应逻辑
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('位置权限被拒绝')),
      );
    }
  }

  void _setupLocationListener() {
    location = AMapFlutterLocation();
    location?.onLocationChanged().listen((Map<String, Object> result) {
      setState(() {
        currentLocation = LatLng(
          result['latitude'] as double,
          result['longitude'] as double,
        );
      });
    });
    _startLocationTracking();
  }

  void _startLocationTracking() {
    location?.startLocation();
  }

  void _stopLocationTracking() {
    location?.stopLocation();
  }

  bool _isNearTarget() {
    if (currentLocation == null) return false;
    return (currentLocation!.latitude - targetLocation.latitude).abs() < threshold &&
           (currentLocation!.longitude - targetLocation.longitude).abs() < threshold;
  }

  @override
  void dispose() {
    _stopLocationTracking();
    location?.destroy();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Geo Game')),
      body: Stack(
        children: [
          AMapWidget(
            apiKey: const AMapApiKey(
              androidKey: 'c2c04af14bce461bee9eef1d98edb327',
              iosKey: 'c2c04af14bce461bee9eef1d98edb327',
            ),
            initialCameraPosition: CameraPosition(
              target: targetLocation,
              zoom: 15,
            ),
            onMapCreated: (AMapController controller) {
              mapController = controller;
            },
          ),
          if (_isNearTarget())
            Center(
              child: Image.asset('assets/reward_image.png'),
            ),
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.white,
              child: Text(
                currentLocation != null
                    ? 'Lat: ${currentLocation!.latitude.toStringAsFixed(4)}, '
                        'Lng: ${currentLocation!.longitude.toStringAsFixed(4)}'
                    : 'Locating...',
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.my_location),
        onPressed: () {
          if (currentLocation != null) {
            mapController?.moveCamera(
              CameraUpdate.newLatLng(currentLocation!),
              animated: true,
            );
          }
        },
      ),
    );
  }
}
