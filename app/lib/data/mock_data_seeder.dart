import 'dart:math';
import 'models/session.dart';
import 'repositories/session_repository.dart';

class MockDataSeeder {
  static Future<void> seedIfEmpty(SessionRepository repo) async {
    if (repo.getAll().isNotEmpty) return;

    final random = Random(42);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    const transcripts = [
      'Feeling a bit overwhelmed today with all the work piling up. Hard to stay focused and everything feels urgent at once. I managed to get through the most important tasks though and that feels good.',
      'Had a really good morning routine today. Went for a walk and had a proper breakfast. Feeling energized and ready for the day ahead. Things seem very manageable right now and I feel on top of it.',
      'Slept poorly last night and it is really showing today. Struggling to focus on anything and my mood is quite low. Hoping tomorrow will be better after some proper rest and recovery.',
      'Great session with my team today. We made real progress on the project and everyone was aligned and motivated. Feeling inspired and like we are actually moving forward together as a group.',
      'Anxious about next week and all the things coming up. Trying to take it one step at a time but my mind keeps jumping ahead to worst case scenarios. Need to practice some breathing exercises tonight.',
      'Went for a long walk this afternoon and it really helped clear my head. Nature has a way of putting everything in perspective. Feeling calmer and more grounded than I have all week.',
      'Today was just average. Nothing particularly good or bad happened. Getting through the day but feeling a bit flat and unmotivated. Things will pick up but right now I just feel neutral.',
      'Really struggling with motivation lately. Even small tasks feel like a lot of effort. I know I need to be patient with myself but it is hard not to feel like I am falling behind on everything.',
      'Wonderful day with family. Laughed a lot and felt truly connected to the people I love. These moments remind me what actually matters in life. Feeling grateful and content and at peace.',
      'Productive work day but I pushed myself too hard. Skipped lunch and barely moved from my desk. My body is exhausted now even though I got a lot done. I need to find better balance.',
      'Feeling more hopeful today. Had a good long conversation with a close friend that really lifted my spirits. It helped so much to just talk through some of the things I have been worried about.',
      'Difficult day. An unexpected problem came up and threw everything off course. I handled it as best I could but felt stressed and reactive rather than calm and thoughtful like I would have liked.',
    ];

    // Seed current week (last 7 days) with an intentional visible trend.
    // Pattern: starts low, dips further mid-week, then rises strongly toward end.
    const weekTrend = [-0.35, -0.55, -0.2, 0.15, 0.5, 0.3, 0.65];
    for (int i = 0; i < 7; i++) {
      final date = today.subtract(Duration(days: 6 - i));
      final mood = (weekTrend[i] + (random.nextDouble() - 0.5) * 0.12).clamp(-1.0, 1.0);
      await repo.upsert(_buildSession(date, mood, transcripts, random));
    }

    // Seed 30 weeks of historical data (older than current week).
    for (int daysAgo = 8; daysAgo <= 210; daysAgo++) {
      if (random.nextInt(10) >= 4) continue;

      final date = today.subtract(Duration(days: daysAgo));
      final weekNum = daysAgo ~/ 7;
      final baseMood = sin(weekNum * 0.55) * 0.4;
      final mood = (baseMood + (random.nextDouble() - 0.5) * 0.5).clamp(-1.0, 1.0);
      await repo.upsert(_buildSession(date, mood, transcripts, random));
    }
  }

  static Session _buildSession(
    DateTime date,
    double mood,
    List<String> transcripts,
    Random random,
  ) {
    final positivity = (mood + 1) / 2; // 0.0 → 1.0

    return Session(
      id: Session.dateKey(date),
      createdAt: date,
      transcript: transcripts[random.nextInt(transcripts.length)],
      evaluation: {
        'mood': mood,
        'emotions': {
          // Calm group (teal)
          'satisfied': (positivity * 0.8 + random.nextDouble() * 0.2).clamp(0.0, 1.0),
          'calm': (positivity * 0.75 + random.nextDouble() * 0.25).clamp(0.0, 1.0),
          // Positive group (mint)
          'happy': (positivity * 0.7 + random.nextDouble() * 0.3).clamp(0.0, 1.0),
          'proud': (positivity * 0.65 + random.nextDouble() * 0.35).clamp(0.0, 1.0),
          // Stress group (peach)
          'anxious': ((1 - positivity) * 0.65 + random.nextDouble() * 0.2).clamp(0.0, 1.0),
          'angry': ((1 - positivity) * 0.45 + random.nextDouble() * 0.2).clamp(0.0, 1.0),
          'sad': ((1 - positivity) * 0.5 + random.nextDouble() * 0.25).clamp(0.0, 1.0),
          'afraid': ((1 - positivity) * 0.35 + random.nextDouble() * 0.25).clamp(0.0, 1.0),
        },
      },
    );
  }
}
