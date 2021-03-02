import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:arkit_plugin/arkit_plugin.dart';
// import 'package:vector_math/vector_math_64.dart' as vector;

class MapPage extends StatefulWidget {
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  static const methodChannel = MethodChannel('waypoint_app.flutter.io/mapping');

  Future<void> _goToMap() async {
    print('_goToMap() in map.dart');
    try {
      await methodChannel.invokeMethod('goToMap');
    } on PlatformException catch (e) {
      print("Failed: '${e.message}'.");
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Waypoint"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Click to view the map:',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _goToMap,
        child: Icon(Icons.explore),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}