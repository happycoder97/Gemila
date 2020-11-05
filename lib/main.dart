import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(MyApp());
}

enum ItemType { H1, H2, Text, ListItem, Link }

abstract class GeminiItem {
  TextSpan toTextSpan();
}

class GeminiH1 implements GeminiItem {
  String value;
  static GeminiH1 tryParse(String rawValue) {
    if (rawValue.startsWith("# ")) {
      GeminiH1 h1 = GeminiH1();
      h1.value = rawValue.substring(1).trim();
      return h1;
    }
    return null;
  }

  TextSpan toTextSpan() {
    return TextSpan(
      text: this.value,
      style: TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
    );
  }
}

class GeminiH2 implements GeminiItem {
  String value;
  static GeminiH2 tryParse(String rawValue) {
    if (rawValue.startsWith("## ")) {
      GeminiH2 h2 = GeminiH2();
      h2.value = rawValue.substring(2).trim();
      return h2;
    }
    return null;
  }

  TextSpan toTextSpan() {
    return TextSpan(
      text: this.value,
      style: TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
    );
  }
}

class GeminiH3 implements GeminiItem {
  String value;
  static GeminiH3 tryParse(String rawValue) {
    if (rawValue.startsWith("### ")) {
      GeminiH3 h3 = GeminiH3();
      h3.value = rawValue.substring(3).trim();
      return h3;
    }
    return null;
  }

  TextSpan toTextSpan() {
    return TextSpan(
      text: this.value,
      style: TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    );
  }
}

class GeminiListItem implements GeminiItem {
  String value;
  static GeminiListItem tryParse(String rawValue) {
    if (rawValue.startsWith("* ")) {
      GeminiListItem g = GeminiListItem();
      g.value = rawValue.substring(1).trim();
      return g;
    }
    return null;
  }

  TextSpan toTextSpan() {
    return TextSpan(
      text: "• " + this.value,
      style: TextStyle(color: Colors.black),
    );
  }
}

class GeminiLink implements GeminiItem {
  String link;
  String text;
  void Function(String) handler;
  static GeminiLink tryParse(
      String rawValue, void Function(String link) linkHandler) {
    if (rawValue.startsWith("=> ")) {
      GeminiLink g = GeminiLink();
      g.handler = linkHandler;
      final value = rawValue.substring(2).trim();
      final spIdx = value.indexOf(RegExp(r"\s+"));
      if (spIdx >= 0) {
        g.link = value.substring(0, spIdx);
        g.text = value.substring(spIdx + 1);
      } else {
        g.link = value;
        g.text = value;
      }
      return g;
    }
    return null;
  }

  TextSpan toTextSpan() {
    final recognizer = TapGestureRecognizer();
    recognizer.onTap = () {
      this.handler(this.link);
    };
    return TextSpan(
      text: this.text,
      style:
          TextStyle(color: Colors.black, decoration: TextDecoration.underline),
      recognizer: recognizer,
      children: [
        TextSpan(
          text: "\n" + this.link + "\n",
          style: TextStyle(color: Colors.grey, fontSize: 10),
        ),
      ],
    );
  }
}

class GeminiText implements GeminiItem {
  String value;
  static GeminiText tryParse(String rawValue) {
    GeminiText g = GeminiText();
    g.value = rawValue;
    return g;
  }

  TextSpan toTextSpan() {
    return TextSpan(
      text: this.value,
      style: TextStyle(color: Colors.black),
    );
  }
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.green,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _state = "";
  String _respStatus = "";
  List<GeminiItem> _content;
  String _currentUrl;
  final urlController =
      TextEditingController(text: "gemini://gemini.circumlunar.space/");
  List<String> urlStack = [];
  bool isBackAction = false;

  void _load() async {
    setState(() {
      _state = "Connecting..";
    });
    final hostEndIdx = urlController.text.indexOf("/", "gemini://".length);
    final hostName =
        urlController.text.substring("gemini://".length, hostEndIdx);

    final socket = await SecureSocket.connect(
      hostName,
      1965,
      onBadCertificate: (cert) {
        return true;
      },
    );
    setState(() {
      _state = "Sending request..";
    });
    socket.write(urlController.text + "\r\n");

    setState(() {
      _state = "Receiving data..";
    });
    List<int> buffer = [];
    await for (var b in socket) {
      buffer.addAll(b);
    }
    setState(() {
      _state = "Decoding utf8..";
    });
    String s = utf8.decode(buffer, allowMalformed: true);
    setState(() {
      _state = "Rendering..";
    });
    setState(() {
      _content = [];
    });
    final lines = s.split("\n");
    final respStatus = lines.removeAt(0);
    if (respStatus.startsWith("3")) {
      _state = "Redirecting..";
      urlController.text = respStatus.split(r"\s+")[1];
      _load();
      return;
    }
    setState(() {
      _respStatus = respStatus;
      if (_currentUrl != null && !isBackAction) {
        urlStack.add(_currentUrl);
        isBackAction = false;
      }
      _currentUrl = urlController.text;
    });
    for (final line in lines) {
      GeminiItem item;

      item = GeminiH1.tryParse(line);
      if (item != null) {
        setState(() {
          _content.add(item);
        });
        continue;
      }

      item = GeminiH2.tryParse(line);
      if (item != null) {
        setState(() {
          _content.add(item);
        });
        continue;
      }

      item = GeminiH3.tryParse(line);
      if (item != null) {
        setState(() {
          _content.add(item);
        });
        continue;
      }

      item = GeminiListItem.tryParse(line);
      if (item != null) {
        setState(() {
          _content.add(item);
        });
        continue;
      }

      item = GeminiLink.tryParse(line, (link) {
        setState(() {
          if (link.startsWith("gemini://")) {
            urlController.text = link;
            return;
          }
          if (link.startsWith("/")) {
            final hostEndIdx = _currentUrl.indexOf("/", "gemini://".length);
            final base = _currentUrl.substring(0, hostEndIdx);
            print("Base: ");
            print(base);
            print("Link:");
            print(link);
            urlController.text = base + link;
          }
          if (link.startsWith(RegExp(r"[a-z]+://"))) {
            return;
          }

          if (urlController.text.endsWith("/")) {
            urlController.text += link;
          } else {
            urlController.text += "/" + link;
          }
        });
        _load();
      });
      if (item != null) {
        setState(() {
          _content.add(item);
        });
        continue;
      }

      item = GeminiText.tryParse(line);
      if (item != null) {
        setState(() {
          _content.add(item);
        });
        continue;
      }
    }
    setState(() {
      _state = "Loaded.";
    });
    socket.close();
  }

  Future<bool> _handleBackButton() async {
    if (urlStack.isEmpty) return true;
    urlController.text = urlStack.removeLast();
    isBackAction = true;
    _load();
    return false;
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called.
    List<Widget> geminiTexts;
    if (_content == null) {
      geminiTexts = [Text("No page loaded")];
    } else {
      geminiTexts = _content.map((geminiItem) {
        return RichText(
          text: geminiItem.toTextSpan(),
        );
      }).toList(growable: false);
    }

    return WillPopScope(
      onWillPop: _handleBackButton,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.all(5),
                child: Row(
                  children: [
                    Expanded(child: TextField(controller: urlController)),
                    Padding(
                      padding: EdgeInsets.only(left: 5),
                      child:
                          ElevatedButton(child: Text("Go"), onPressed: _load),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: geminiTexts,
                    ),
                  ),
                  scrollDirection: Axis.vertical,
                ),
              ),
              Padding(
                padding: EdgeInsets.all(5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [Text('$_state'), Text('$_respStatus')],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
