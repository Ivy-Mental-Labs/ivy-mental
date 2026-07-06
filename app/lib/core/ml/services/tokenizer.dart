import 'dart:convert';

class BertTokenizer {
  static const int padId = 0;
  static const int unkId = 100;
  static const int clsId = 101;
  static const int sepId = 102;

  static const String padToken = '[PAD]';
  static const String unkToken = '[UNK]';
  static const String clsToken = '[CLS]';
  static const String sepToken = '[SEP]';

  static const String continuingSubwordPrefix = '##';

  final int maxLength;
  final bool doLowerCase;
  late final Map<String, int> _vocab;

  BertTokenizer({this.maxLength = 128, this.doLowerCase = true});

  void loadFromString(String vocabContent) {
    _vocab = {};
    final lines = const LineSplitter().convert(vocabContent);
    for (var i = 0; i < lines.length; i++) {
      final token = lines[i].trim();
      if (token.isNotEmpty) {
        _vocab[token] = i;
      }
    }
  }

  int _tokenToId(String token) => _vocab[token] ?? unkId;

  bool _inVocab(String token) => _vocab.containsKey(token);

  String _normalize(String text) {
    var result = doLowerCase ? text.toLowerCase() : text;
    result = result.replaceAll('\n', ' ');
    result = result.replaceAll('\r', ' ');
    result = result.replaceAll('\t', ' ');
    result = result.replaceAll('\u00a0', ' ');
    result = result.replaceAll('\u200b', '');
    result = result.replaceAll(RegExp(r'\s+'), ' ');
    return result.trim();
  }

  List<String> _preTokenize(String text) {
    final words = text.split(' ').where((w) => w.isNotEmpty).toList();
    final tokens = <String>[];
    for (final word in words) {
      var current = '';
      String? punctuationType;

      for (var i = 0; i < word.length; i++) {
        final char = word[i];
        final isPunct = _isPunctuation(char);
        final type = isPunct ? 'punct' : 'word';

        if (punctuationType == null) {
          punctuationType = type;
          current = char;
        } else if (type == punctuationType) {
          current += char;
        } else {
          tokens.add(current);
          current = char;
          punctuationType = type;
        }
      }

      if (current.isNotEmpty) {
        tokens.add(current);
      }
    }
    return tokens;
  }

  bool _isPunctuation(String char) {
    final code = char.codeUnitAt(0);
    if (code >= 33 && code <= 47) return true;
    if (code >= 58 && code <= 64) return true;
    if (code >= 91 && code <= 96) return true;
    if (code >= 123 && code <= 126) return true;
    return false;
  }

  List<int> _wordPiece(List<String> words) {
    final tokens = <int>[];
    for (final word in words) {
      if (_inVocab(word)) {
        tokens.add(_tokenToId(word));
        continue;
      }

      var remaining = word;
      var isFirst = true;

      while (remaining.isNotEmpty) {
        String? bestMatch;
        var bestLen = 0;

        for (var i = remaining.length; i > 0; i--) {
          final candidate = isFirst
              ? remaining.substring(0, i)
              : '$continuingSubwordPrefix${remaining.substring(0, i)}';
          if (_inVocab(candidate)) {
            bestMatch = candidate;
            bestLen = i;
            break;
          }
        }

        if (bestMatch != null) {
          tokens.add(_vocab[bestMatch]!);
          remaining = remaining.substring(bestLen);
          isFirst = false;
        } else {
          tokens.add(unkId);
          break;
        }
      }
    }
    return tokens;
  }

  BertTokenizerOutput tokenize(String text) {
    final normalized = _normalize(text);
    final preTokens = _preTokenize(normalized);
    final wordPieceIds = _wordPiece(preTokens);

    var ids = [clsId, ...wordPieceIds, sepId];

    if (ids.length > maxLength) {
      ids = ids.sublist(0, maxLength);
      ids[ids.length - 1] = sepId;
    }

    final mask = List.filled(ids.length, 1, growable: true);
    while (ids.length < maxLength) {
      ids.add(padId);
      mask.add(0);
    }

    return BertTokenizerOutput(
      inputIds: ids,
      attentionMask: mask,
    );
  }
}

class BertTokenizerOutput {
  final List<int> inputIds;
  final List<int> attentionMask;

  const BertTokenizerOutput({
    required this.inputIds,
    required this.attentionMask,
  });
}
