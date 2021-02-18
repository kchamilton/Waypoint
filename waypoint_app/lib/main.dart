import 'package:flutter/material.dart';
// import 'package:arkit_plugin/arkit_plugin.dart';
// import 'package:vector_math/vector_math_64.dart';

import 'screens/hello_world.dart';

void main() => runApp(MaterialApp(home: MyApp()));

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final samples = [
      Sample(
        'Hello World',
        'The simplest scene with all gemetries.',
        Icons.home,
        () => Navigator .of(context)
            .push<void>(MaterialPageRoute(builder: (c) => HelloWorldPage())),
      )
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Waypoint ARKit Demo'),
      ),
      body:
        ListView(children: samples.map((s) => SampleItem(item: s)).toList()),
    );
  }
}

class SampleItem extends StatelessWidget {
  const SampleItem({Key key, this.item}) : super(key: key);
  final Sample item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => item.onTap(),
        child: ListTile(
          leading: Icon(item.icon),
          title: Text(
            item.title,
            style: Theme.of(context).textTheme.subtitle1,
          ),
          subtitle: Text(
            item.description,
            style: Theme.of(context).textTheme.subtitle2,
          ),
        ),
      ),
    );
  }
}

class Sample {
  const Sample(this.title, this.description, this.icon, this.onTap);
  final String title;
  final String description;
  final IconData icon;
  final Function onTap;
}


/* WORKING CODE */
// class MyApp extends StatefulWidget {
//   @override
//   _MyAppState createState() => _MyAppState();
// }

// class _MyAppState extends State<MyApp> {
//   ARKitController arkitController;

//   @override
//   void dispose() {
//     arkitController?.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) => Scaffold(
//       appBar: AppBar(title: const Text('ARKit in Flutter')),
//       body: ARKitSceneView(onARKitViewCreated: onARKitViewCreated));

//   void onARKitViewCreated(ARKitController arkitController) {
//     this.arkitController = arkitController;
//     final node = ARKitNode(
//         geometry: ARKitSphere(radius: 0.1), position: Vector3(0, 0, -0.5));
//     this.arkitController.add(node);
//   }
// }