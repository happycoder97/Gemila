import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

abstract class GeminiItem {
  Widget toWidget();
}

class GeminiH1 implements GeminiItem {
  String value;
  static GeminiH1 tryParse(String rawValue) {
    if (rawValue.startsWith("#")) {
      GeminiH1 h1 = GeminiH1();
      h1.value = rawValue.substring(1).trim();
      return h1;
    }
    return null;
  }

  Widget toWidget() {
    return Text(
      this.value,
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
    if (rawValue.startsWith("##")) {
      GeminiH2 h2 = GeminiH2();
      h2.value = rawValue.substring(2).trim();
      return h2;
    }
    return null;
  }

  Widget toWidget() {
    return Text(
      this.value,
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
    if (rawValue.startsWith("###")) {
      GeminiH3 h3 = GeminiH3();
      h3.value = rawValue.substring(3).trim();
      return h3;
    }
    return null;
  }

  Widget toWidget() {
    return Text(
      this.value,
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
    if (rawValue.startsWith("*")) {
      GeminiListItem g = GeminiListItem();
      g.value = rawValue.substring(1).trim();
      return g;
    }
    return null;
  }

  Widget toWidget() {
    return Text(
      "• " + this.value,
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
    if (rawValue.startsWith("=>")) {
      GeminiLink g = GeminiLink();
      g.handler = linkHandler;
      final value = rawValue.substring(2).trim();
      final spIdx = value.indexOf(RegExp(r"\s+"));
      if (spIdx >= 0) {
        g.link = value.substring(0, spIdx);
        g.text = value.substring(spIdx + 1).trim();
      } else {
        g.link = value;
        g.text = value;
      }
      return g;
    }
    return null;
  }

  Widget toWidget() {
    final recognizer = TapGestureRecognizer();
    recognizer.onTap = () {
      this.handler(this.link);
    };
    return RichText(
      text: TextSpan(
        text: this.text,
        style: TextStyle(
            color: Colors.black, decoration: TextDecoration.underline),
        recognizer: recognizer,
        children: [
          TextSpan(
            text: "\n" + this.link + "\n",
            style: TextStyle(color: Colors.grey, fontSize: 10),
          ),
        ],
      ),
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

  Widget toWidget() {
    return Text(
      this.value,
      style: TextStyle(color: Colors.black),
    );
  }
}

/// No tryParse() for this one because it is multiline
class GeminiPre implements GeminiItem {
  List<String> lines;
  GeminiPre(this.lines);

  static bool matchOpening(String line) => line.startsWith("```");

  static bool matchClosing(String line) => matchOpening(line);

  Widget toWidget() {
    // return Text(lines[0], style: TextStyle(color: Colors.red));
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines
            .map(
              (line) => Text(
                line,
                style: TextStyle(
                  color: Colors.black,
                  fontFamily: "monospace",
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class GeminiQuote implements GeminiItem {
  String value;
  static GeminiQuote tryParse(String rawValue) {
    if (rawValue.startsWith(">")) {
      GeminiQuote g = GeminiQuote();
      g.value = rawValue.substring(1).trim();
      return g;
    }
    return null;
  }

  Widget toWidget() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
      child: Container(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            this.value,
            style: TextStyle(
              color: Colors.black,
              // backgroundColor: Colors.grey[200],
            ),
          ),
        ),
        decoration: BoxDecoration(
            color: Colors.grey[200],
            border: Border(left: BorderSide(color: Colors.black87, width: 2))),
      ),
    );
  }
}
