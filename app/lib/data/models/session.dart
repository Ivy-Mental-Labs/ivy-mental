import 'dart:convert';

enum SessionStatus { transcribing, transcribed, complete }

class Session {
  final String id; // "yyyy-MM-dd"
  final DateTime createdAt;
  final String? transcript;
  final Map<String, dynamic>? evaluation;

  const Session({
    required this.id,
    required this.createdAt,
    this.transcript,
    this.evaluation,
  });

  SessionStatus get status {
    if (evaluation != null) return SessionStatus.complete;
    if (transcript != null) return SessionStatus.transcribed;
    return SessionStatus.transcribing;
  }

  static String dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Session withTranscript(String value) => Session(
        id: id,
        createdAt: createdAt,
        transcript: value,
        evaluation: evaluation,
      );

  Session withEvaluation(Map<String, dynamic> value) {
    assert(transcript != null, 'withEvaluation called before transcript is set');
    return Session(
      id: id,
      createdAt: createdAt,
      transcript: transcript,
      evaluation: value,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'transcript': transcript,
        'evaluation': evaluation,
      };

  factory Session.fromJson(Map<String, dynamic> json) => Session(
        id: json['id'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        transcript: json['transcript'] as String?,
        evaluation: json['evaluation'] as Map<String, dynamic>?,
      );

  String toJsonString() => jsonEncode(toJson());

  factory Session.fromJsonString(String source) =>
      Session.fromJson(jsonDecode(source) as Map<String, dynamic>);
}
