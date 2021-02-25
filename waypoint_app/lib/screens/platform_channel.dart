import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:arkit_plugin/arkit_plugin.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

class PlatformChannelPage extends StatefulWidget {
  @override
  _PlatformChannelPageState createState() => _PlatformChannelPageState();
}

class _PlatformChannelPageState extends State<PlatformChannelPage> {
  static const MethodChannel methodChannel = MethodChannel('waypoint_app.flutter.io/cate');

  String _greeting = 'No one has said hello.';

  Future<void> _getGreeting() async {
    print('_getGreeting() in platform_channel.dart');
    String greeting;
    try {
      final String result = await methodChannel.invokeMethod('getGreeting');
      greeting = result;
    } on PlatformException {
      greeting = 'Failed to receive the greeting';
    }
    setState(() {
      _greeting = greeting;
    });
  }


  @override
  void initState() {
    super.initState();
    _getGreeting();
  }
  
  ARKitController arkitController;

  @override
  void dispose() {
    arkitController?.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: const Text('Testing Platform Channel'),
      ),
      body: Container(
        child: ARKitSceneView(onARKitViewCreated: onARKitViewCreated),
      ));
  
  ARKitNode _createText() {
    final text = ARKitText(
      text: _greeting,
      extrusionDepth: 1,
      materials: [
        ARKitMaterial(
          diffuse: ARKitMaterialProperty(color: Colors.orange),
        )
      ],
    );
    return ARKitNode(
      geometry: text,
      position: vector.Vector3(-0.3, 0.3, -1.4),
      scale: vector.Vector3(0.02, 0.02, 0.02),
    );
  }
  
  void onARKitViewCreated(ARKitController arkitController) {
  this.arkitController = arkitController;

  this.arkitController.add(_createText());
}
}