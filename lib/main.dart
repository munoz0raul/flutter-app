import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' as io;
import "package:yaml/yaml.dart";

class Content {
  String fileName;
  List paths;
  Content(this.fileName, this.paths);
}

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Questions',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyAppScreen(),
    );
  }
}

class MyAppScreen extends StatefulWidget {
  const MyAppScreen({super.key});
  @override
  State createState() {
    return MyAppScreenState();
  }
}

class MyAppScreenState extends State {
  List<Content> contents = [];
  String dir = "assets";

  Future<List<Content>> _loadQuestions() async {
    List<Content> localContents = [];
    dynamic mapData;
    try {
      final data = await rootBundle.loadString("$dir/config.yaml");
      mapData = loadYaml(data);
    } on Exception {
      return localContents;
    }

    for (var m in mapData["modules"]) {
      List localImages = [];
      for (var image in m["slides"]) {
            localImages.add("assets/$image");
      }
      localContents.add(Content(m["name"], localImages));
    }

    return localContents;
  }

  @override
  void initState() {
    super.initState();
    _setup();
  }

  _setup() async {
    var returnContents = await _loadQuestions();
    // Notify the UI and display the questions
    setState(() {
      contents.addAll(returnContents);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modules'),
      ),
      body: ListView.builder(
        itemCount: contents.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(contents[index].fileName),
            // When a user taps the ListTile, navigate to the DetailScreen.
            // Notice that you're not only creating a DetailScreen, you're
            // also passing the current todo through to it.
            onTap: () {
              if (contents[index].paths.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ImageSwitcherState(content: contents[index]),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}

class ImageSwitcherState extends StatefulWidget {
  final Content content;
  const ImageSwitcherState({Key? key, required this.content}) : super(key: key);
  @override
  ImageSwitcherStateState createState() => ImageSwitcherStateState();
}

class ImageSwitcherStateState extends State<ImageSwitcherState> {
  int index = 0;
  List<Widget> widgets = [];

  @override
  void initState() {
    super.initState();
    _setup();
  }

  _setup() async {
    for (var i = 0; i < widget.content.paths.length; i++) {
      widgets.add(Image.asset((widget.content.paths[i]),
          fit: BoxFit.cover, key: Key(i.toString())));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: GestureDetector(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 1000),
              reverseDuration: const Duration(milliseconds: 2000),
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: animation,
                child: SizedBox.expand(child: child),
              ),
              child: widgets[index],
            ),
            onLongPress: () {
              Navigator.pop(context);
            },
            onTap: () {
              setState(() {
                final isLastIndex = index == widgets.length - 1;
                setState(() => index = isLastIndex ? 0 : index + 1);
              });
            }),
        );
}
