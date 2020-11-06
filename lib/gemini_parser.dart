import 'gemini.dart';

class GeminiParser {
  void parse(
    List<String> lines,
    void Function(GeminiItem item) itemCallback,
    void Function(String link) linkHandler,
  ) {
    GeminiItem item;
    for (final line in lines) {
      if (!(item is GeminiPre) && GeminiPre.matchOpening(line)) {
        print("Start pre: $line");
        item = GeminiPre([]);
        continue;
      }
      if (item is GeminiPre) {
        if (GeminiPre.matchClosing(line)) {
          print("End pre: $line");
          itemCallback(item);
          item = null;
          continue;
        }
        (item as GeminiPre).lines.add(line);
        continue;
      }

      item = GeminiH1.tryParse(line);
      if (item != null) {
        itemCallback(item);
        continue;
      }

      item = GeminiH2.tryParse(line);
      if (item != null) {
        itemCallback(item);
        continue;
      }

      item = GeminiH3.tryParse(line);
      if (item != null) {
        itemCallback(item);
        continue;
      }

      item = GeminiListItem.tryParse(line);
      if (item != null) {
        itemCallback(item);
        continue;
      }

      item = GeminiLink.tryParse(line, linkHandler);
      if (item != null) {
        itemCallback(item);
        continue;
      }

      item = GeminiQuote.tryParse(line);
      if (item != null) {
        itemCallback(item);
        continue;
      }

      item = GeminiText.tryParse(line);
      if (item != null) {
        itemCallback(item);
        continue;
      }
    }
  }
}
