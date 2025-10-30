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
  final DateTime createdAt;

  Student({
    required this.studentId,
    required this.name,
    required this.email,
    required this.password,
    required this.weakAreas,
    required this.performanceLevel,
    required this.topicProficiency,
    required this.createdAt,
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
  final String
      questionType; // 'numerical', 'theory', 'conceptual', 'assertion-reason'

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
    this.questionType = 'numerical',
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
  final double score;
  final double totalMarks;
  final int totalQuestions;
  final int correctAnswers; // Add this field
  final Map<String, double> subjectWiseScores;
  final Map<String, double> topicAccuracy;
  final List<String> strongTopics;
  final List<String> weakTopics;
  final List<String> recommendations;
  final DateTime submittedAt;
  final int timeTaken;

  TestResult({
    required this.testId,
    required this.studentId,
    required this.score,
    required this.totalMarks,
    required this.totalQuestions,
    required this.correctAnswers, // Add this
    required this.subjectWiseScores,
    required this.topicAccuracy,
    required this.strongTopics,
    required this.weakTopics,
    required this.recommendations,
    required this.submittedAt,
    required this.timeTaken,
  });
}