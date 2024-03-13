import 'package:async/async.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' as io;
import 'package:path_provider/path_provider.dart';
import 'package:process_run/shell_run.dart';

class Content {
  String FileName;
  List paths;
  Content(this.FileName, this.paths);
}

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Questions',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyAppScreen(),
    );
  }
}

class MyAppScreen extends StatefulWidget {
  @override
  State createState() {
    return MyAppScreenState();
  }
}

class MyAppScreenState extends State {
  List<Content> contents = [];
// String dir1 = "/usr/share/flutter/app/3.16.7/release/data/flutter_assets/assets/";
  String dir = "assets/";
  Future<List<Content>> _loadQuestions() async {
    List localFile = [];
    localFile =
        io.Directory(dir).listSync(); //use your folder name insted of resume.
    List<Content> localContents = [];
    // Retrieve the questions (Processed in the background)
    for (var name in localFile) {
      if (name.path.contains(".txt")) {
        await rootBundle.loadString(name.path).then((q) {
          List localImages = [];
          for (String i in LineSplitter().convert(q)) {
            localImages.add(i);
          }
          String newStr = name.path.replaceAll(dir, "");
          localContents
              .add(Content(newStr.replaceAll(".txt", ""), localImages));
        });
      }
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
        title: const Text('Todos'),
      ),
      body: ListView.builder(
        itemCount: contents.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(contents[index].FileName),
            // When a user taps the ListTile, navigate to the DetailScreen.
            // Notice that you're not only creating a DetailScreen, you're
            // also passing the current todo through to it.
            onTap: () {
              if (contents[index].paths.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        imageSwitcherState(content: contents[index]),
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

class imageSwitcherState extends StatefulWidget {
  final Content content;
  const imageSwitcherState({Key? key, required this.content}) : super(key: key);
  @override
  _imageSwitcherStateState createState() => _imageSwitcherStateState();
}

class _imageSwitcherStateState extends State<imageSwitcherState> {
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
              duration: Duration(milliseconds: 1000),
              reverseDuration: Duration(milliseconds: 2000),
              transitionBuilder: (child, animation) => ScaleTransition(
                child: SizedBox.expand(child: child),
                scale: animation,
              ),
              // switchInCurve: Curves.bounceIn,
              // switchOutCurve: Curves.bounceOut,
              // switchInCurve: Curves.easeIn,
              // switchOutCurve: Curves.easeOut,
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
