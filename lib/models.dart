// models.dart
// Shared models that are used across multiple files

class Student {
  final String studentId;
  final String name;
  final String email;
  final String password;
  final List<String> weakAreas;
  final String performanceLevel;
  final Map<String, double> topicProficiency;
  final int testsGiven;
  final DateTime createdAt;

  Student({
    required this.studentId,
    required this.name,
    required this.email,
    required this.password,
    required this.weakAreas,
    required this.performanceLevel,
    required this.topicProficiency,
    this.testsGiven = 0,
    required this.createdAt,
  });
}

class UserModel {
  final String uid;
  final String email;
  final String name;
  final int testsGiven; // Total number of tests taken
  final List<TestResult> testResults; // List of all test results

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.testsGiven,
    required this.testResults,
  });
}

class Question {
  final String id;
  final String questionText;
  final List<String> options;
  final int correctAnswerIndex;
  final String subject;
  final String topic;
  final String subTopic;
  final String difficulty;
  final double marks;
  final int timeRequired;
  final List<String> concepts;
  final String questionType;
  final String solution;
  final bool isNumerical;

  Question({
    required this.id,
    required this.questionText,
    required this.options,
    required this.correctAnswerIndex,
    required this.subject,
    required this.topic,
    required this.subTopic,
    required this.difficulty,
    required this.marks,
    required this.timeRequired,
    required this.concepts,
    required this.questionType,
    this.solution = '',
    this.isNumerical = false,
  });
}

class Test {
  final String testId;
  final List<Question> questions;
  final DateTime createdAt;
  final int duration;
  final String testType;
  final Map<String, int> topicDistribution;

  Test({
    required this.testId,
    required this.questions,
    required this.createdAt,
    required this.duration,
    required this.testType,
    required this.topicDistribution,
  });
}

class TestResult {
  final String testId;
  final String studentId;
  final String testName;
  final DateTime testDate;
  final int totalQuestions;
  final int correctAnswers;
  final double score;
  final double totalMarks;
  final int incorrectAnswers;
  final int unattemptedAnswers;
  final Map<String, double> subjectWiseScores;
  final Map<String, double> topicAccuracy;
  final List<String> strongTopics;
  final List<String> weakTopics;
  final List<String> recommendations;
  final DateTime submittedAt;
  final int timeTaken;
  final Map<String, bool> questionCorrectness;
  final Map<String, dynamic> questionDetails;
  final String subject;
  final String topic;
  final String subTopic;

  // ADD THESE NEW PARAMETERS:
  final double? accuracyScore;
  final Map<String, dynamic>? accuracyInsights;
  final Map<String, dynamic>? testAccuracyReport;

  TestResult({
    required this.testId,
    required this.studentId,
    required this.testName,
    required this.testDate,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.score,
    required this.totalMarks,
    required this.incorrectAnswers,
    required this.unattemptedAnswers,
    required this.subjectWiseScores,
    required this.topicAccuracy,
    required this.strongTopics,
    required this.weakTopics,
    required this.recommendations,
    required this.submittedAt,
    required this.timeTaken,
    required this.questionCorrectness,
    required this.questionDetails,
    required this.subject,
    required this.topic,
    required this.subTopic,
    // ADD THESE WITH DEFAULTS:
    this.accuracyScore,
    this.accuracyInsights,
    this.testAccuracyReport,
  });

  Map<String, dynamic> toMap() {
    return {
      'testId': testId,
      'studentId': studentId,
      'testName': testName,
      'testDate': testDate.millisecondsSinceEpoch,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'score': score,
      'questionDetails': questionDetails,
      'questionCorrectness': questionCorrectness,
      'subject': subject,
      'topic': topic,
      'subTopic': subTopic,
      // Add the additional fields to toMap
      'totalMarks': totalMarks,
      'incorrectAnswers': incorrectAnswers,
      'unattemptedAnswers': unattemptedAnswers,
      'subjectWiseScores': subjectWiseScores,
      'topicAccuracy': topicAccuracy,
      'strongTopics': strongTopics,
      'weakTopics': weakTopics,
      'recommendations': recommendations,
      'submittedAt': submittedAt.millisecondsSinceEpoch,
      'timeTaken': timeTaken,
    };
  }

  // Create from Map from Firestore
  static TestResult fromMap(Map<String, dynamic> map) {
    return TestResult(
      testId: map['testId'] ?? '',
      studentId: map['studentId'] ?? '',
      testName: map['testName'] ?? '',
      testDate: DateTime.fromMillisecondsSinceEpoch(map['testDate'] ?? 0),
      totalQuestions: map['totalQuestions'] ?? 0,
      correctAnswers: map['correctAnswers'] ?? 0,
      score: (map['score'] ?? 0).toDouble(),
      questionDetails: Map<String, dynamic>.from(map['questionDetails'] ?? {}),
      questionCorrectness:
          Map<String, bool>.from(map['questionCorrectness'] ?? {}),
      subject: map['subject'] ?? '',
      topic: map['topic'] ?? '',
      subTopic: map['subTopic'] ?? '',
      // Add the additional fields with proper defaults
      totalMarks: (map['totalMarks'] ?? 0).toDouble(),
      incorrectAnswers: map['incorrectAnswers'],
      unattemptedAnswers: map['unattemptedAnswers'],
      subjectWiseScores:
          Map<String, double>.from(map['subjectWiseScores'] ?? {}),
      topicAccuracy: Map<String, double>.from(map['topicAccuracy'] ?? {}),
      strongTopics: List<String>.from(map['strongTopics'] ?? []),
      weakTopics: List<String>.from(map['weakTopics'] ?? []),
      recommendations: List<String>.from(map['recommendations'] ?? []),
      submittedAt: DateTime.fromMillisecondsSinceEpoch(
          map['submittedAt'] ?? DateTime.now().millisecondsSinceEpoch),
      timeTaken: map['timeTaken'] ?? 0,
    );
  }
}

// Add to your models.dart file
class CompleteTest {
  final String testId;
  final String studentId;
  final String testName;
  final DateTime testDate;
  final int totalQuestions;
  final int correctAnswers;
  final double score;
  final Map<String, dynamic> questionDetails;
  final Map<String, bool> questionCorrectness;
  final String subject;
  final String topic;
  final String subTopic;
  final int timeTaken;

  CompleteTest({
    required this.testId,
    required this.studentId,
    required this.testName,
    required this.testDate,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.score,
    required this.questionDetails,
    required this.questionCorrectness,
    required this.subject,
    required this.topic,
    required this.subTopic,
    required this.timeTaken,
  });

  Map<String, dynamic> toMap() {
    return {
      'testId': testId,
      'studentId': studentId,
      'testName': testName,
      'testDate': testDate.millisecondsSinceEpoch,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'score': score,
      'questionDetails': questionDetails,
      'questionCorrectness': questionCorrectness,
      'subject': subject,
      'topic': topic,
      'subTopic': subTopic,
      'timeTaken': timeTaken,
    };
  }

  static CompleteTest fromMap(Map<dynamic, dynamic> map) {
    return CompleteTest(
      testId: map['testId'] ?? '',
      studentId: map['studentId'] ?? '',
      testName: map['testName'] ?? '',
      testDate: DateTime.fromMillisecondsSinceEpoch(map['testDate'] ?? 0),
      totalQuestions: map['totalQuestions'] ?? 0,
      correctAnswers: map['correctAnswers'] ?? 0,
      score: (map['score'] ?? 0).toDouble(),
      questionDetails: Map<String, dynamic>.from(map['questionDetails'] ?? {}),
      questionCorrectness:
          Map<String, bool>.from(map['questionCorrectness'] ?? {}),
      subject: map['subject'] ?? '',
      topic: map['topic'] ?? '',
      subTopic: map['subTopic'] ?? '',
      timeTaken: map['timeTaken'] ?? 0,
    );
  }
}
