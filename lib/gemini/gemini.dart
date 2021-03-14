abstract class GeminiItem {}

class GeminiH1 implements GeminiItem {
  String value;

  GeminiH1(this.value);

  static GeminiH1? tryParse(String rawValue) {
    if (rawValue.startsWith("#")) {
      String value = rawValue.substring(1).trim();
      GeminiH1 h1 = GeminiH1(value);
      return h1;
    }
    return null;
  }
}

class GeminiH2 implements GeminiItem {
  String value;

  GeminiH2(this.value);

  static GeminiH2? tryParse(String rawValue) {
    if (rawValue.startsWith("##")) {
      String value = rawValue.substring(2).trim();
      GeminiH2 h2 = GeminiH2(value);
      return h2;
    }
    return null;
  }
}

class GeminiH3 implements GeminiItem {
  String value;

  GeminiH3(this.value);

  static GeminiH3? tryParse(String rawValue) {
    if (rawValue.startsWith("###")) {
      String value = rawValue.substring(3).trim();
      GeminiH3 h3 = GeminiH3(value);
      return h3;
    }
    return null;
  }
}

class GeminiListItem implements GeminiItem {
  String value;

  GeminiListItem(this.value);

  static GeminiListItem? tryParse(String rawValue) {
    if (rawValue.startsWith("* ")) {
      String value = rawValue.substring(1).trim();
      GeminiListItem g = GeminiListItem(value);
      return g;
    }
    return null;
  }
}

class GeminiLink implements GeminiItem {
  String link;
  String text;
  void Function(String) handler;

  GeminiLink(this.link, this.text, this.handler);

  static GeminiLink? tryParse(
      String rawValue, void Function(String link) linkHandler) {
    if (rawValue.startsWith("=>")) {
      final value = rawValue.substring(2).trim();
      final spIdx = value.indexOf(RegExp(r"\s+"));
      String link;
      String text;
      if (spIdx >= 0) {
        link = value.substring(0, spIdx);
        text = value.substring(spIdx + 1).trim();
      } else {
        link = value;
        text = value;
      }

      GeminiLink g = GeminiLink(link, text, linkHandler);
      return g;
    }
    return null;
  }
}

class GeminiText implements GeminiItem {
  String value;

  GeminiText(this.value);

  static GeminiText tryParse(String rawValue) {
    GeminiText g = GeminiText(rawValue);
    return g;
  }
}

/// No tryParse() for this one because it is multiline
class GeminiPre implements GeminiItem {
  List<String> lines;
  GeminiPre(this.lines);

  static bool matchOpening(String line) => line.startsWith("```");

  static bool matchClosing(String line) => matchOpening(line);
}

class GeminiQuote implements GeminiItem {
  String value;
  GeminiQuote(this.value);

  static GeminiQuote? tryParse(String rawValue) {
    if (rawValue.startsWith(">")) {
      String value = rawValue.substring(1).trim();
      GeminiQuote g = GeminiQuote(value);
      return g;
    }
    return null;
  }

  bool tryParseAndAppend(String rawValue) {
    if (rawValue.startsWith(">")) {
      this.value += "\n" + rawValue.substring(1).trim();
      return true;
    }
    return false;
  }
}
