// services/accuracy_validator_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models.dart';
import '../firebase_service.dart';

class AccuracyValidatorService {
  static const String _baseUrl = 'YOUR_COLAB_URL_HERE';

  // Check accuracy for a single question
  static Future<Map<String, dynamic>> checkAccuracy({
    required Question question,
    required String studentId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/check-accuracy'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'question_text': question.questionText,
          'options': question.options,
          'correct_answer_index': question.correctAnswerIndex,
          'subject': question.subject,
          'topic': question.topic,
          'difficulty': question.difficulty,
        }),
      );

      if (response.statusCode == 200) {
        final accuracyResult = json.decode(response.body);

        // Store the accuracy result in Firebase
        await FirebaseService().storeAccuracyResult(
          studentId: studentId,
          questionId:
              question.id ?? 'temp_${DateTime.now().millisecondsSinceEpoch}',
          accuracyScore: (accuracyResult['accuracy_score'] ?? 0.0).toDouble(),
          confidenceLevel:
              (accuracyResult['confidence_level'] ?? 'unknown').toString(),
          validationData: accuracyResult,
          subject: question.subject,
          topic: question.topic,
        );

        return accuracyResult;
      } else {
        return {
          'accuracy_score': 0.0,
          'confidence_level': 'low',
          'error': 'Server error: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {
        'accuracy_score': 0.0,
        'confidence_level': 'low',
        'error': 'Validation service unavailable: $e'
      };
    }
  }

  // NEW: Check accuracy for ALL questions in a test
  static Future<Map<String, dynamic>> checkTestAccuracy({
    required List<Question> questions,
    required String studentId,
    required String testId,
  }) async {
    try {
      print(
          '🎯 Starting accuracy validation for ${questions.length} questions...');

      final List<Map<String, dynamic>> questionResults = [];
      double totalAccuracy = 0.0;
      int validResults = 0;

      // Validate each question
      for (int i = 0; i < questions.length; i++) {
        final question = questions[i];
        print(
            '🔍 Validating question ${i + 1}/${questions.length}: ${question.topic}');

        final result = await checkAccuracy(
          question: question,
          studentId: studentId,
        );

        questionResults.add({
          'question_index': i,
          'question_id': question.id,
          'question_text': question.questionText,
          'subject': question.subject,
          'topic': question.topic,
          'difficulty': question.difficulty,
          'accuracy_result': result,
        });

        // Calculate overall accuracy
        if (result['accuracy_score'] != null) {
          totalAccuracy += (result['accuracy_score'] as double);
          validResults++;
        }

        // Small delay to avoid overwhelming the API
        await Future.delayed(Duration(milliseconds: 500));
      }

      // Calculate overall test accuracy
      final double overallAccuracy =
          validResults > 0 ? totalAccuracy / validResults : 0.0;

      // Generate test-level insights
      final testInsights =
          _generateTestInsights(questionResults, overallAccuracy);

      // Store comprehensive test accuracy report
      await _storeTestAccuracyReport(
        studentId: studentId,
        testId: testId,
        questionResults: questionResults,
        overallAccuracy: overallAccuracy,
        testInsights: testInsights,
      );

      print(
          '✅ Test accuracy validation completed. Overall: ${(overallAccuracy * 100).toStringAsFixed(1)}%');

      return {
        'overall_accuracy': overallAccuracy,
        'total_questions': questions.length,
        'validated_questions': validResults,
        'question_results': questionResults,
        'test_insights': testInsights,
        'confidence_level': _getOverallConfidenceLevel(overallAccuracy),
      };
    } catch (e) {
      print('❌ Error in test accuracy validation: $e');
      return {
        'overall_accuracy': 0.0,
        'total_questions': questions.length,
        'validated_questions': 0,
        'question_results': [],
        'test_insights': {},
        'error': 'Test accuracy validation failed: $e',
      };
    }
  }

  // Generate insights from all question results
  static Map<String, dynamic> _generateTestInsights(
      List<Map<String, dynamic>> questionResults, double overallAccuracy) {
    final Map<String, List<double>> subjectAccuracies = {};
    final Map<String, List<double>> topicAccuracies = {};
    final Map<String, int> difficultyCount = {
      'Easy': 0,
      'Medium': 0,
      'Hard': 0
    };

    int lowAccuracyCount = 0;
    int highAccuracyCount = 0;

    for (var result in questionResults) {
      final accuracy =
          (result['accuracy_result']['accuracy_score'] ?? 0.0).toDouble();
      final subject = result['subject'] ?? 'Unknown';
      final topic = result['topic'] ?? 'Unknown';
      final difficulty = result['difficulty'] ?? 'Medium';

      // Group by subject
      if (!subjectAccuracies.containsKey(subject)) {
        subjectAccuracies[subject] = [];
      }
      subjectAccuracies[subject]!.add(accuracy);

      // Group by topic
      if (!topicAccuracies.containsKey(topic)) {
        topicAccuracies[topic] = [];
      }
      topicAccuracies[topic]!.add(accuracy);

      // Count by difficulty
      difficultyCount[difficulty] = (difficultyCount[difficulty] ?? 0) + 1;

      // Count accuracy levels
      if (accuracy < 0.6) lowAccuracyCount++;
      if (accuracy >= 0.8) highAccuracyCount++;
    }

    // Calculate averages
    final Map<String, double> subjectAverages = {};
    subjectAccuracies.forEach((subject, accuracies) {
      subjectAverages[subject] =
          accuracies.reduce((a, b) => a + b) / accuracies.length;
    });

    final Map<String, double> topicAverages = {};
    topicAccuracies.forEach((topic, accuracies) {
      topicAverages[topic] =
          accuracies.reduce((a, b) => a + b) / accuracies.length;
    });

    // Find weakest and strongest areas
    final weakAreas = _findWeakAreas(topicAverages);
    final strongAreas = _findStrongAreas(topicAverages);

    return {
      'overall_accuracy': overallAccuracy,
      'subject_breakdown': subjectAverages,
      'topic_breakdown': topicAverages,
      'difficulty_distribution': difficultyCount,
      'weak_areas': weakAreas,
      'strong_areas': strongAreas,
      'low_accuracy_questions': lowAccuracyCount,
      'high_accuracy_questions': highAccuracyCount,
      'quality_assessment': _assessTestQuality(
          overallAccuracy, lowAccuracyCount, questionResults.length),
    };
  }

  static List<Map<String, dynamic>> _findWeakAreas(
      Map<String, double> topicAverages) {
    final weakAreas = topicAverages.entries
        .where((entry) => entry.value < 0.7)
        .map((entry) => {'topic': entry.key, 'accuracy': entry.value})
        .toList();

    weakAreas.sort(
        (a, b) => (a['accuracy'] as double).compareTo(b['accuracy'] as double));
    return weakAreas.take(5).toList();
  }

  static List<Map<String, dynamic>> _findStrongAreas(
      Map<String, double> topicAverages) {
    final strongAreas = topicAverages.entries
        .where((entry) => entry.value >= 0.8)
        .map((entry) => {'topic': entry.key, 'accuracy': entry.value})
        .toList();

    strongAreas.sort(
        (a, b) => (b['accuracy'] as double).compareTo(a['accuracy'] as double));
    return strongAreas.take(5).toList();
  }

  static String _assessTestQuality(
      double overallAccuracy, int lowAccuracyCount, int totalQuestions) {
    if (overallAccuracy >= 0.8 && lowAccuracyCount == 0) {
      return 'Excellent';
    } else if (overallAccuracy >= 0.7 &&
        lowAccuracyCount <= totalQuestions * 0.2) {
      return 'Good';
    } else if (overallAccuracy >= 0.6 &&
        lowAccuracyCount <= totalQuestions * 0.3) {
      return 'Fair';
    } else {
      return 'Needs Improvement';
    }
  }

  static String _getOverallConfidenceLevel(double accuracy) {
    if (accuracy >= 0.8) return 'high';
    if (accuracy >= 0.6) return 'medium';
    return 'low';
  }

  static Future<void> _storeTestAccuracyReport({
    required String studentId,
    required String testId,
    required List<Map<String, dynamic>> questionResults,
    required double overallAccuracy,
    required Map<String, dynamic> testInsights,
  }) async {
    try {
      await FirebaseService().storeTestAccuracyReport(
        studentId: studentId,
        testId: testId,
        overallAccuracy: overallAccuracy,
        questionResults: questionResults,
        testInsights: testInsights,
      );
      print('✅ Test accuracy report stored for test: $testId');
    } catch (e) {
      print('❌ Error storing test accuracy report: $e');
    }
  }

  // Get test accuracy history
  static Future<List<Map<String, dynamic>>> getTestAccuracyHistory(
      String studentId) async {
    return await FirebaseService().getTestAccuracyHistory(studentId);
  }

  // Get accuracy report for a specific test
  static Future<Map<String, dynamic>?> getTestAccuracyReport(
      String studentId, String testId) async {
    return await FirebaseService().getTestAccuracyReport(studentId, testId);
  }

  // Existing methods...
  static Future<List<Map<String, dynamic>>> getAccuracyHistory(
      String studentId) async {
    return await FirebaseService().getAccuracyHistory(studentId);
  }

  static Future<Map<String, double>> getAverageAccuracyBySubject(
      String studentId) async {
    return await FirebaseService().getAverageAccuracyBySubject(studentId);
  }

  static Future<bool> isServiceAvailable() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/health'),
          )
          .timeout(Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
