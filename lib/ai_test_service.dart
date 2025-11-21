import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'dart:async';
import 'models.dart';
import 'question_bank.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_service.dart';
import 'auth_service.dart';

class AITestService with ChangeNotifier {
  final List<Test> _generatedTests = [];
  final List<TestResult> _testResults = [];
  Test? _currentTest;
  final FirebaseService _firebaseService = FirebaseService();

  List<Test> get generatedTests => _generatedTests;
  List<TestResult> get testResults => _testResults;
  Test? get currentTest => _currentTest;

  final Random _random = Random();

  String getSubjectFromTopic(String topic) {
    if (topic.contains('Calculus') ||
        topic.contains('Geometry') ||
        topic.contains('Functions') ||
        topic.contains('Numbers') ||
        topic.contains('Matrices') ||
        topic.contains('Permutations') ||
        topic.contains('Binomial') ||
        topic.contains('Sequence') ||
        topic.contains('Limit') ||
        topic.contains('Differential') ||
        topic.contains('Vector') ||
        topic.contains('Statistics') ||
        topic.contains('Trigonometry')) return 'Mathematics';
    if (topic.contains('Units') ||
        topic.contains('Kinematics') ||
        topic.contains('Laws') ||
        topic.contains('Work') ||
        topic.contains('Rotational') ||
        topic.contains('Gravitation') ||
        topic.contains('Properties') ||
        topic.contains('Thermodynamics') ||
        topic.contains('Kinetic') ||
        topic.contains('Oscillations') ||
        topic.contains('Electrostatics') ||
        topic.contains('Current') ||
        topic.contains('Magnetic') ||
        topic.contains('Electromagnetic') ||
        topic.contains('Optics') ||
        topic.contains('Dual') ||
        topic.contains('Atoms') ||
        topic.contains('Electronic') ||
        topic.contains('Experimental')) return 'Physics';
    return 'Chemistry';
  }

  // Use the question bank from the separate file
  List<Question> get _questionBank => QuestionBank.questions;

  // NEW: Get complete test details
  Future<Map<String, dynamic>?> getCompleteTestDetails(
      String studentId, String testId) async {
    return await _firebaseService.getCompleteTestDetails(studentId, testId);
  }

  // New method for focused weak area test - ONLY from weak areas
  Future<Test> generateWeakAreaFocusedTest({
    required Student student,
    required int numberOfQuestions,
  }) async {
    await Future.delayed(const Duration(seconds: 2));

    final selectedQuestions = <Question>[];
    final weakAreas = student.weakAreas;

    if (weakAreas.isEmpty) {
      throw Exception(
          'No weak areas identified. Please update your weak areas first.');
    }

    // Get all questions from weak areas only
    final weakAreaQuestions =
        _questionBank.where((q) => weakAreas.contains(q.topic)).toList();

    if (weakAreaQuestions.isEmpty) {
      throw Exception(
          'No questions available in your weak areas. Please update your weak areas or contact support.');
    }

    // Shuffle and take the specified number of questions
    weakAreaQuestions.shuffle();

    if (weakAreaQuestions.length >= numberOfQuestions) {
      selectedQuestions.addAll(weakAreaQuestions.take(numberOfQuestions));
    } else {
      // If not enough questions in weak areas, use all available
      selectedQuestions.addAll(weakAreaQuestions);
    }

    final topicDistribution = <String, int>{};
    for (var question in selectedQuestions) {
      topicDistribution[question.topic] =
          (topicDistribution[question.topic] ?? 0) + 1;
    }

    final test = Test(
      testId: 'WEAK_AREA_${DateTime.now().millisecondsSinceEpoch}',
      questions: selectedQuestions,
      createdAt: DateTime.now(),
      duration: _calculateTestDuration(selectedQuestions),
      testType: 'Weak Area Focus',
      topicDistribution: topicDistribution,
    );

    _currentTest = test;
    _generatedTests.add(test);

    notifyListeners();
    return test;
  }

  Future<Test> generateAIPersonalizedTest({
    required Student student,
    required List<String> focusTopics,
    required String testType,
    required int numberOfQuestions,
  }) async {
    await Future.delayed(const Duration(seconds: 2));

    // Filter questions to only include selected focus topics
    final availableQuestions =
        _questionBank.where((q) => focusTopics.contains(q.topic)).toList();

    if (availableQuestions.isEmpty) {
      throw Exception(
          'No questions available in selected topics. Please select different topics.');
    }

    final selectedQuestions = _selectQuestionsUsingAI(
      student: student,
      focusTopics: focusTopics,
      numberOfQuestions: numberOfQuestions,
      availableQuestions: availableQuestions,
    );

    final topicDistribution = <String, int>{};
    for (var question in selectedQuestions) {
      topicDistribution[question.topic] =
          (topicDistribution[question.topic] ?? 0) + 1;
    }

    final test = Test(
      testId: 'AI_TEST_${DateTime.now().millisecondsSinceEpoch}',
      questions: selectedQuestions,
      createdAt: DateTime.now(),
      duration: _calculateTestDuration(selectedQuestions),
      testType: testType,
      topicDistribution: topicDistribution,
    );

    _currentTest = test;
    _generatedTests.add(test);

    notifyListeners();
    return test;
  }

  List<Question> _selectQuestionsUsingAI({
    required Student student,
    required List<String> focusTopics,
    required int numberOfQuestions,
    required List<Question> availableQuestions,
  }) {
    final selectedQuestions = <Question>[];
    final questionScores = <Question, double>{};

    for (var question in availableQuestions) {
      double score = _calculateQuestionScore(question, student, focusTopics);
      questionScores[question] = score;
    }

    final sortedQuestions = questionScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final selectedTopics = <String>{};
    for (var entry in sortedQuestions) {
      if (selectedQuestions.length >= numberOfQuestions) break;

      final question = entry.key;
      if (selectedTopics.length < focusTopics.length ||
          selectedTopics.contains(question.topic)) {
        selectedQuestions.add(question);
        selectedTopics.add(question.topic);
      }
    }

    // If we still don't have enough questions, add remaining ones
    if (selectedQuestions.length < numberOfQuestions) {
      for (var entry in sortedQuestions) {
        if (selectedQuestions.length >= numberOfQuestions) break;
        if (!selectedQuestions.contains(entry.key)) {
          selectedQuestions.add(entry.key);
        }
      }
    }

    // If still not enough, use random questions from available pool
    if (selectedQuestions.length < numberOfQuestions) {
      final remainingNeeded = numberOfQuestions - selectedQuestions.length;
      final remainingQuestions = availableQuestions
          .where((q) => !selectedQuestions.contains(q))
          .toList()
        ..shuffle();

      selectedQuestions.addAll(remainingQuestions.take(remainingNeeded));
    }

    return selectedQuestions;
  }

  double _calculateQuestionScore(
    Question question,
    Student student,
    List<String> focusTopics,
  ) {
    double score = 0.0;

    if (focusTopics.contains(question.topic)) {
      score += 0.4;
    }

    final proficiency = student.topicProficiency[question.topic] ?? 0.5;
    final difficultyWeight = _mapDifficultyToWeight(question.difficulty);
    final proficiencyMatch = 1.0 - (proficiency - difficultyWeight).abs();
    score += 0.3 * proficiencyMatch;

    if (student.weakAreas.contains(question.topic)) {
      score += 0.2;
    }

    if (question.difficulty == 'Medium' && proficiency > 0.6) {
      score += 0.1;
    } else if (question.difficulty == 'Easy' && proficiency < 0.4) {
      score += 0.1;
    }

    // Add variety by including different question types
    if ((question.questionType == 'theory' ||
            question.questionType == 'assertion-reason') &&
        _random.nextDouble() > 0.7) {
      score += 0.1;
    }

    return score;
  }

  double _mapDifficultyToWeight(String difficulty) {
    switch (difficulty) {
      case 'Easy':
        return 0.3;
      case 'Medium':
        return 0.6;
      case 'Hard':
        return 0.9;
      default:
        return 0.5;
    }
  }

  int _calculateTestDuration(List<Question> questions) {
    int totalTime = 0;
    for (var question in questions) {
      totalTime += question.timeRequired;
    }
    return (totalTime / 60).ceil();
  }

  Future<TestResult> analyzePerformanceWithAI(
    String studentId,
    String testId,
    Map<String, int> submittedAnswers,
    int timeTaken,
    BuildContext context, {
    Map<String, String> numericalAnswers = const {},
    bool validateAccuracy = true,
  }) async {
    await Future.delayed(const Duration(seconds: 2));

    final test = _generatedTests.firstWhere((t) => t.testId == testId);

    if (!context.mounted) {
      throw Exception('Context not available');
    }

    final authService = Provider.of<AuthService>(context, listen: false);

    // Count correct answers and calculate exact marks
    int correctCount = 0;
    int incorrectCount = 0;
    int unattemptedCount = 0;

    Map<String, int> subjectCorrectCount = {
      'Mathematics': 0,
      'Physics': 0,
      'Chemistry': 0,
    };
    Map<String, int> subjectTotalCount = {
      'Mathematics': 0,
      'Physics': 0,
      'Chemistry': 0,
    };

    // Track topic performance
    Map<String, int> topicCorrectCount = {};
    Map<String, int> topicIncorrectCount = {};
    Map<String, int> topicUnattemptedCount = {};
    Map<String, int> topicTotalCount = {};

    // Track individual question performance
    Map<String, bool> questionCorrectness = {};
    List<String> correctTopics = [];
    List<String> incorrectTopics = [];
    List<String> unattemptedTopics = [];

    for (var question in test.questions) {
      final userAnswer = submittedAnswers[question.id];
      subjectTotalCount[question.subject] =
          (subjectTotalCount[question.subject] ?? 0) + 1;

      // Initialize topic tracking
      topicTotalCount[question.topic] =
          (topicTotalCount[question.topic] ?? 0) + 1;

      if (userAnswer == null) {
        // Unattempted question
        unattemptedCount++;
        topicUnattemptedCount[question.topic] =
            (topicUnattemptedCount[question.topic] ?? 0) + 1;
        unattemptedTopics.add(question.topic);
        questionCorrectness[question.id] = false;
      } else if (userAnswer == question.correctAnswerIndex) {
        // Correct answer
        correctCount++;
        subjectCorrectCount[question.subject] =
            (subjectCorrectCount[question.subject] ?? 0) + 1;
        topicCorrectCount[question.topic] =
            (topicCorrectCount[question.topic] ?? 0) + 1;
        correctTopics.add(question.topic);
        questionCorrectness[question.id] = true;
      } else {
        // Incorrect answer
        incorrectCount++;
        topicIncorrectCount[question.topic] =
            (topicIncorrectCount[question.topic] ?? 0) + 1;
        incorrectTopics.add(question.topic);
        questionCorrectness[question.id] = false;
      }
    }

    // Calculate exact marks (4 marks per correct answer)
    double totalMarks = test.questions.length * 4.0;
    double score = correctCount * 4.0;

    // Calculate subject-wise scores
    Map<String, double> subjectWiseScores = {};
    subjectCorrectCount.forEach((subject, correct) {
      subjectWiseScores[subject] = correct * 4.0;
    });

    // FIX 2: Remove duplicate declarations and fix accuracy validation
    double? calculatedAccuracyScore;
    String? calculatedConfidenceLevel;
    Map<String, dynamic>? testAccuracyReportData;

    // Calculate topic accuracy and identify strong/weak topics
    Map<String, double> topicAccuracy = {};
    List<String> strongTopics = [];
    List<String> weakTopics = [];

    // Identify strong topics (100% accuracy with at least 1 question)
    topicTotalCount.forEach((topic, total) {
      final correct = topicCorrectCount[topic] ?? 0;
      final accuracy = total > 0 ? correct / total : 0.0;
      topicAccuracy[topic] = accuracy;

      // Strong topics: 100% accuracy with at least 1 question attempted
      if (accuracy == 1.0 && total >= 1) {
        strongTopics.add(topic);
      }
    });

    // Identify weak topics (incorrect or unattempted)
    final allWeakTopics = {...incorrectTopics, ...unattemptedTopics};
    weakTopics.addAll(allWeakTopics);
    weakTopics.removeWhere((topic) => strongTopics.contains(topic));
    weakTopics = weakTopics.toSet().toList();

    // AUTOMATICALLY UPDATE WEAK AREAS
    if (weakTopics.isNotEmpty) {
      _updateStudentWeakAreas(authService, weakTopics);
    }

    // Generate AI recommendations based on performance
    final recommendations = _generateAIRecommendations(
      strongTopics,
      weakTopics,
      topicAccuracy,
      timeTaken,
      test.questions.length,
      correctCount,
      incorrectCount,
      unattemptedCount,
    );

    // ACCURACY VALIDATION - FIXED SECTION
    // if (validateAccuracy) {
    //   try {
    //     // Validate a sample of questions for accuracy
    //     final sampleQuestions = test.questions.take(3).toList();
    //     for (var question in sampleQuestions) {
    //       final accuracyResult = await AccuracyValidatorService.checkAccuracy(
    //         question: question,
    //         studentId: studentId,
    //         // FIX 3: Remove undefined named parameter 'context'
    //         // context: context, // This parameter doesn't exist in checkAccuracy method
    //       );

    //       if (accuracyResult['accuracy_score'] != null) {
    //         calculatedAccuracyScore =
    //             accuracyResult['accuracy_score'] as double;
    //         calculatedConfidenceLevel =
    //             accuracyResult['confidence_level'] as String;
    //         break; // Use first valid result
    //       }
    //     }
    //   } catch (e) {
    //     print('Accuracy validation skipped: $e');
    //   }
    // }

    // SAVE COMPLETE TEST DETAILS TO FIREBASE WITH ACCURACY DATA
    try {
      await _firebaseService.saveCompleteTestDetails(
        studentId: studentId,
        testId: testId,
        testName: 'Test ${(authService.currentStudent?.testsGiven ?? 0) + 1}',
        totalQuestions: test.questions.length,
        correctAnswers: correctCount,
        score: score,
        questions: test.questions,
        submittedAnswers: submittedAnswers,
        numericalAnswers: numericalAnswers,
        questionCorrectness: questionCorrectness,
        timeTaken: timeTaken,
        accuracyScore: calculatedAccuracyScore, // Use renamed variable
        confidenceLevel: calculatedConfidenceLevel, // Use renamed variable
      );
    } catch (e) {
      print('❌ Error saving complete test details: $e');
    }

    // Create result with exact marks
    final result = TestResult(
      testId: testId,
      studentId: studentId,
      testName: 'Test ${(authService.currentStudent?.testsGiven ?? 0) + 1}',
      testDate: DateTime.now(),
      totalQuestions: test.questions.length,
      correctAnswers: correctCount,
      score: score,
      totalMarks: totalMarks,
      incorrectAnswers: incorrectCount,
      unattemptedAnswers: unattemptedCount,
      subjectWiseScores: subjectWiseScores,
      topicAccuracy: topicAccuracy,
      strongTopics: strongTopics,
      weakTopics: weakTopics,
      recommendations: recommendations,
      submittedAt: DateTime.now(),
      timeTaken: timeTaken,
      questionCorrectness: questionCorrectness,
      questionDetails: {},
      subject: _getTestSubject(test),
      topic: _getTestTopic(test),
      subTopic: _getTestSubTopic(test),
      // Add accuracy insights - FIXED: Use correct parameter names and renamed variables
      accuracyScore:
          testAccuracyReportData?['overall_accuracy'] ?? (score / totalMarks),
      accuracyInsights: testAccuracyReportData?['test_insights'] ?? {},
      testAccuracyReport: testAccuracyReportData,
    );

    _testResults.add(result);

    // Also save to the old testResults structure for compatibility
    try {
      await _firebaseService.saveTestResult(result);
    } catch (e) {
      print('Error saving test result: $e');
    }

    // INCREMENT TEST COUNT
    authService.incrementTestCount();

    notifyListeners();
    return result;
  }

  String _getTestSubject(Test test) {
    if (test.questions.isEmpty) return 'Mixed';
    final subjects = test.questions.map((q) => q.subject).toSet();
    return subjects.length == 1 ? subjects.first : 'Mixed';
  }

  String _getTestTopic(Test test) {
    if (test.questions.isEmpty) return 'General';
    final topics = test.questions.map((q) => q.topic).toSet();
    return topics.length == 1 ? topics.first : 'Multiple Topics';
  }

  String _getTestSubTopic(Test test) {
    return 'Practice Test';
  }

  // Method to automatically update student's weak areas
  void _updateStudentWeakAreas(
      AuthService authService, List<String> newWeakTopics) {
    final student = authService.currentStudent;
    if (student != null) {
      // Get current weak areas
      final currentWeakAreas = List<String>.from(student.weakAreas);

      // Add new weak topics that aren't already in the list
      for (var topic in newWeakTopics) {
        if (!currentWeakAreas.contains(topic)) {
          currentWeakAreas.add(topic);
        }
      }

      // Limit to top 8 weak areas to keep it manageable
      final updatedWeakAreas = currentWeakAreas.length > 8
          ? currentWeakAreas.sublist(0, 8)
          : currentWeakAreas;

      // Update the student's weak areas
      authService.updateWeakAreas(updatedWeakAreas);
    }
  }

  List<String> _generateAIRecommendations(
    List<String> strongTopics,
    List<String> weakTopics,
    Map<String, double> topicAccuracy,
    int timeTaken,
    int totalQuestions,
    int correctCount,
    int incorrectCount,
    int unattemptedCount,
  ) {
    final recommendations = <String>[];

    // Time management analysis
    final avgTimePerQuestion = timeTaken / totalQuestions;
    if (avgTimePerQuestion > 180) {
      recommendations.add(
        '⏱️ Focus on improving speed: You took ${avgTimePerQuestion.toStringAsFixed(1)} seconds per question. Practice with timed tests.',
      );
    } else if (avgTimePerQuestion < 60) {
      recommendations.add(
        '⚡ Good speed! Maintain accuracy while solving quickly.',
      );
    } else {
      recommendations.add(
        '⏱️ Good time management! Your pace is balanced.',
      );
    }

    // Performance summary
    recommendations.add(
      '📊 Performance Summary: $correctCount correct, $incorrectCount incorrect, $unattemptedCount unattempted',
    );

    // Strong topics recommendations
    if (strongTopics.isNotEmpty) {
      recommendations.add(
        '🎯 Excellent performance in: ${strongTopics.join(', ')}',
      );
      recommendations.add(
        '💪 Maintain your strength in these topics through regular revision',
      );
    }

    // Weak topics recommendations
    if (weakTopics.isNotEmpty) {
      recommendations.add(
        '🔴 Areas needing improvement: ${weakTopics.join(', ')}',
      );

      for (var topic in weakTopics.take(3)) {
        // Show top 3 weak areas
        final accuracy = topicAccuracy[topic] ?? 0;
        final accuracyPercent = (accuracy * 100).toStringAsFixed(1);

        if (accuracy == 0) {
          recommendations.add(
            '📚 For $topic: All questions were incorrect/unattempted. Focus on fundamental concepts.',
          );
        } else {
          recommendations.add(
            '📚 For $topic: Current accuracy $accuracyPercent%. Practice more problems in this area.',
          );
        }
      }

      // Add notification about automatic weak area update
      recommendations.add(
        '🔄 Your weak areas have been automatically updated with these topics for focused practice',
      );
    }

    // General recommendations
    if (unattemptedCount > totalQuestions * 0.3) {
      recommendations.add(
        '🚨 High number of unattempted questions ($unattemptedCount). Work on speed and question selection strategy.',
      );
    }

    if (incorrectCount > totalQuestions * 0.4) {
      recommendations.add(
        '⚠️ Many incorrect answers. Focus on concept clarity and avoid guesswork.',
      );
    }

    recommendations.add(
      '🔍 Review incorrect answers to identify pattern of mistakes',
    );
    recommendations.add(
      '🔄 Practice mixed-topic tests to improve adaptability',
    );
    recommendations.add(
      '🧠 Take regular breaks during long study sessions',
    );

    return recommendations;
  }
}
