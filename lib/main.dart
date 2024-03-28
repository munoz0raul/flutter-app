import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io' as io;
import 'package:logger/logger.dart';
import "package:yaml/yaml.dart";

var logger = Logger(printer: SimplePrinter(), level: Level.debug);

class Content {
  String title;
  List<String> paths;
  final List<Widget> _slideList = [];

  Content(this.title, this.paths) {
    for (var i = 0; i < paths.length; i++) {
      if (io.File(paths[i]).existsSync()) {
        logger.d("add slide: ${paths[i]}");
        _slideList.add(Image.asset((paths[i]),
            fit: BoxFit.cover,
            key: Key("$title-$i")));
      } else {
        logger.e("ERROR: Can't find ${paths[i]}");
      }
    }
  }

  operator [](int i) => _slideList[i];

  int length() {
    return _slideList.length;
  }
}

class ContentList with ChangeNotifier {
  String hash = "";
  // TODO: read from persistent setting
  int lastModule = 0;
  int moduleIndex = 0;
  int slideIndex = 0;
  final List<Content> _contentList = [];

  static const int _slideTimeout = 90;
  late Timer _timer;

  ContentList() {
    _timer = Timer(const Duration(seconds: _slideTimeout), timerHandler);
    _timer.cancel();
  }

  void timerHandler() {
    logger.d("** Slide Timer: TRIGGER **");
    slideIndex = 0;
    notify();
  }

  void startTimer() {
    _timer = Timer(const Duration(seconds: _slideTimeout), timerHandler);
  }

  void cancelTimer() {
    if (_timer.isActive) {
      _timer.cancel();
    }
  }

  operator [](int i) => _contentList[i];

  void clear() {
    moduleIndex = lastModule;
    slideIndex = 0;
    _contentList.clear();
    cancelTimer();
  }

  void add(Content content) {
    _contentList.add(content);
  }

  void notify() {
    notifyListeners();
  }

  int length() {
    return _contentList.length;
  }

  Content activeModule() => _contentList[moduleIndex];
  Widget activeSlide() => _contentList[moduleIndex][slideIndex];
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  static bool locked = false;
  static ContentList contents = ContentList();
  // Read env for assets location
  static String dir = const String.fromEnvironment("ASSETS_DIR", defaultValue: "/saved/assets");

  void loadModules() async {
    dynamic mapData;

    // watcher generates 2 changed events: stop double handling 
    if (MyAppState.locked) return;

    MyAppState.locked = true;
    logger.i("reading: $dir/config.yaml");
    try {
      final data = await rootBundle.loadString("$dir/config.yaml", cache: false);
      mapData = loadYaml(data);
    } on Exception {
      return;
    }

    contents.clear();
    for (var m in mapData["modules"]) {
      List<String> slideList = [];
      for (var image in m["slides"]) {
            logger.d("add slide: $dir/$image");
            slideList.add("$dir/$image");
      }
      logger.d("add module: ${m["name"]}");
      contents.add(Content(m["name"], slideList));
    }
    contents.notify();
    MyAppState.locked = false;
  }

  @override
  void initState() {
    super.initState();

    logger.i("assets dir: $dir");

    // Notify the UI and display the questions
    setState(() {
      loadModules();
    });

    // Watch hash file for changes
    logger.i("watching: $dir/");
    io.File("$dir/").watch().listen((event) {
      if (event.path.endsWith("/hash")) {
        loadModules();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Modules',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Modules'),
        ),
        body: ListenableBuilder(
          listenable: contents,
          builder: (BuildContext context, Widget? child) {
            return ListView.builder(
              itemCount: contents.length(),
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(contents[index].title),
                  // When a user taps the ListTile, navigate to the DetailScreen.
                  // Notice that you're not only creating a DetailScreen, you're
                  // also passing the current todo through to it.
                  onTap: () {
                    if (contents[index].length() > 0) {
                      // save manual selection
                      contents.lastModule = index;
                      contents.moduleIndex = index;
                      contents.slideIndex = 0;
                      logger.d("select module: ${contents.activeModule().title}");
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ImageSwitcher(contents: contents),
                        ),
                      );
                    }
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}


class ImageSwitcher extends StatefulWidget {
  final ContentList contents;
  const ImageSwitcher({Key? key, required this.contents}) : super(key: key);
  @override
  ImageSwitcherState createState() => ImageSwitcherState();
}

class ImageSwitcherState extends State<ImageSwitcher> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: ListenableBuilder(
          listenable: widget.contents,
          builder: (BuildContext context, Widget? child) {
            return MouseRegion(
              cursor: SystemMouseCursors.none,
              child: GestureDetector(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  reverseDuration: const Duration(milliseconds: 2000),
                  /* transitionBuilder: (child, animation) => ScaleTransition(
                    scale: animation,
                    child: SizedBox.expand(child: child),
                  ), */
                  child: widget.contents.activeSlide(),
                ),
                onLongPress: () {
                  logger.d("[lpress] list");
                  Navigator.pop(context);
                  widget.contents.cancelTimer();
                },
                onDoubleTap: () {
                  setState(() {
                    widget.contents.slideIndex = 0;
                    logger.d("[dtap] slide: module: ${widget.contents.activeModule().title}, slide:${widget.contents.slideIndex}");
                  });
                },
                onTap: () {
                  setState(() {
                    final isLastIndex = widget.contents.slideIndex == widget.contents.activeModule().length() - 1;
                    widget.contents.slideIndex = isLastIndex ? 0 : widget.contents.slideIndex + 1;
                    logger.d("[tap] slide: module: ${widget.contents.activeModule().title}, slide:${widget.contents.slideIndex}");
                    if (widget.contents.slideIndex > 0) {
                      widget.contents.startTimer();
                    }
                  });
                },
              ),
            );
          },
        ),
      );
  }
}
