import 'package:firebase_database/firebase_database.dart';
import 'models.dart';

class FirebaseService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  Future<void> saveStudentData(Student student) async {
    try {
      await _database.child('students').child(student.studentId).set({
        'studentId': student.studentId,
        'name': student.name,
        'email': student.email,
        'password': student.password,
        'weakAreas': student.weakAreas,
        'performanceLevel': student.performanceLevel,
        'topicProficiency': student.topicProficiency,
        'createdAt': student.createdAt.millisecondsSinceEpoch,
        'testsGiven': student.testsGiven ?? 0,
      });
      print('✅ Student data saved successfully: ${student.studentId}');
    } catch (e) {
      print('❌ Error saving student: $e');
      rethrow;
    }
  }

  // Get student by email
  Future<Student?> getStudentByEmail(String email) async {
    try {
      final snapshot = await _database.child('students').get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        for (var studentData in data.values) {
          final studentMap = studentData as Map<dynamic, dynamic>;
          if (studentMap['email'] == email) {
            return Student(
              studentId: studentMap['studentId'] ?? '',
              name: studentMap['name'] ?? '',
              email: studentMap['email'] ?? '',
              password: studentMap['password'] ?? '',
              weakAreas: List<String>.from(studentMap['weakAreas'] ?? []),
              performanceLevel: studentMap['performanceLevel'] ?? 'Beginner',
              topicProficiency: Map<String, double>.from(
                studentMap['topicProficiency'] ?? {},
              ),
              createdAt: DateTime.fromMillisecondsSinceEpoch(
                studentMap['createdAt'] ??
                    DateTime.now().millisecondsSinceEpoch,
              ),
              testsGiven: studentMap['testsGiven'] ?? 0,
            );
          }
        }
      }
      return null;
    } catch (e) {
      print('❌ Error getting student: $e');
      rethrow;
    }
  }

  // Get student by ID
  Future<Student?> getStudentById(String studentId) async {
    try {
      final snapshot = await _database.child('students').child(studentId).get();
      if (snapshot.exists) {
        final studentMap = snapshot.value as Map<dynamic, dynamic>;
        return Student(
          studentId: studentMap['studentId'] ?? '',
          name: studentMap['name'] ?? '',
          email: studentMap['email'] ?? '',
          password: studentMap['password'] ?? '',
          weakAreas: List<String>.from(studentMap['weakAreas'] ?? []),
          performanceLevel: studentMap['performanceLevel'] ?? 'Beginner',
          topicProficiency: Map<String, double>.from(
            studentMap['topicProficiency'] ?? {},
          ),
          createdAt: DateTime.fromMillisecondsSinceEpoch(
            studentMap['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
          ),
          testsGiven: studentMap['testsGiven'] ?? 0,
        );
      }
      return null;
    } catch (e) {
      print('❌ Error getting student by ID: $e');
      rethrow;
    }
  }

  // ==================== ACCURACY STORAGE METHODS ====================

  // Store accuracy results
  Future<void> storeAccuracyResult({
    required String studentId,
    required String questionId,
    required double accuracyScore,
    required String confidenceLevel,
    required Map<String, dynamic> validationData,
    required String subject,
    required String topic,
  }) async {
    try {
      final accuracyRef =
          _database.child('accuracy_results').child(studentId).push();

      await accuracyRef.set({
        'question_id': questionId,
        'accuracy_score': accuracyScore,
        'confidence_level': confidenceLevel,
        'subject': subject,
        'topic': topic,
        'validation_data': validationData,
        'timestamp': ServerValue.timestamp,
        'created_at': DateTime.now().toIso8601String(),
      });

      print('✅ Accuracy result stored for question: $questionId');
    } catch (e) {
      print('❌ Error storing accuracy result: $e');
      rethrow;
    }
  }

  // Get accuracy history for a student
  Future<List<Map<String, dynamic>>> getAccuracyHistory(
      String studentId) async {
    try {
      final ref = _database.child('accuracyHistory').child(studentId);
      final snapshot = await ref.get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        return data.entries.map((entry) {
          final record =
              Map<String, dynamic>.from(entry.value as Map<dynamic, dynamic>);
          return record;
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error loading accuracy history: $e');
      throw e;
    }
  }

  // Get average accuracy by subject
  Future<Map<String, double>> getAverageAccuracyBySubject(
      String studentId) async {
    try {
      final history = await getAccuracyHistory(studentId);
      final Map<String, List<double>> subjectScores = {};

      for (var result in history) {
        final subject = result['subject'] ?? 'Unknown';
        final score = (result['accuracy_score'] ?? 0.0).toDouble();

        if (!subjectScores.containsKey(subject)) {
          subjectScores[subject] = [];
        }
        subjectScores[subject]!.add(score);
      }

      final Map<String, double> averages = {};
      subjectScores.forEach((subject, scores) {
        if (scores.isNotEmpty) {
          averages[subject] = scores.reduce((a, b) => a + b) / scores.length;
        }
      });

      return averages;
    } catch (e) {
      print('❌ Error calculating average accuracy: $e');
      rethrow;
    }
  }

  // Get accuracy trends over time
  Future<List<Map<String, dynamic>>> getAccuracyTrends(String studentId,
      {int limit = 30}) async {
    try {
      final history = await getAccuracyHistory(studentId);

      // Group by date and calculate daily averages
      final Map<String, List<double>> dailyScores = {};

      for (var result in history) {
        final timestamp = result['timestamp'];
        if (timestamp != null) {
          final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
          final dateKey = '${date.year}-${date.month}-${date.day}';

          if (!dailyScores.containsKey(dateKey)) {
            dailyScores[dateKey] = [];
          }
          dailyScores[dateKey]!
              .add((result['accuracy_score'] ?? 0.0).toDouble());
        }
      }

      // Calculate daily averages
      final List<Map<String, dynamic>> trends = [];
      dailyScores.forEach((date, scores) {
        final average = scores.reduce((a, b) => a + b) / scores.length;
        trends.add({
          'date': date,
          'average_accuracy': average,
          'tests_count': scores.length,
        });
      });

      // Sort by date and limit results
      trends.sort((a, b) => b['date'].compareTo(a['date']));
      return trends.take(limit).toList();
    } catch (e) {
      print('❌ Error getting accuracy trends: $e');
      return [];
    }
  }

  // Get subject-wise accuracy breakdown
  Future<Map<String, dynamic>> getSubjectAccuracyBreakdown(
      String studentId) async {
    try {
      final history = await getAccuracyHistory(studentId);
      final Map<String, List<double>> subjectScores = {};
      final Map<String, int> subjectCount = {};

      for (var result in history) {
        final subject = result['subject'] ?? 'Unknown';
        final score = (result['accuracy_score'] ?? 0.0).toDouble();
        final confidence = result['confidence_level'] ?? 'unknown';

        if (!subjectScores.containsKey(subject)) {
          subjectScores[subject] = [];
          subjectCount[subject] = 0;
        }
        subjectScores[subject]!.add(score);
        subjectCount[subject] = subjectCount[subject]! + 1;
      }

      final Map<String, double> averages = {};
      final Map<String, Map<String, int>> confidenceDistribution = {};

      subjectScores.forEach((subject, scores) {
        averages[subject] = scores.reduce((a, b) => a + b) / scores.length;

        // Count confidence levels for this subject
        final confidenceCounts = {'high': 0, 'medium': 0, 'low': 0};
        for (var result in history) {
          if (result['subject'] == subject) {
            final confidence =
                (result['confidence_level'] ?? 'unknown').toString();
            if (confidenceCounts.containsKey(confidence)) {
              confidenceCounts[confidence] = confidenceCounts[confidence]! + 1;
            }
          }
        }
        confidenceDistribution[subject] = confidenceCounts;
      });

      return {
        'average_scores': averages,
        'test_counts': subjectCount,
        'confidence_distribution': confidenceDistribution,
        'total_tests': history.length,
      };
    } catch (e) {
      print('❌ Error getting subject accuracy breakdown: $e');
      return {};
    }
  }

  // ==================== EXISTING TEST METHODS (UPDATED) ====================

  // Save test result
  Future<void> saveTestResult(TestResult result) async {
    try {
      await _database
          .child('testResults')
          .child(result.studentId)
          .child(result.testId)
          .set({
        'testId': result.testId,
        'studentId': result.studentId,
        'testName': result.testName,
        'testDate': result.testDate.millisecondsSinceEpoch,
        'score': result.score,
        'totalMarks': result.totalMarks,
        'totalQuestions': result.totalQuestions,
        'correctAnswers': result.correctAnswers,
        'incorrectAnswers': result.incorrectAnswers,
        'unattemptedAnswers': result.unattemptedAnswers,
        'subjectWiseScores': result.subjectWiseScores,
        'topicAccuracy': result.topicAccuracy,
        'strongTopics': result.strongTopics,
        'weakTopics': result.weakTopics,
        'recommendations': result.recommendations,
        'submittedAt': result.submittedAt.millisecondsSinceEpoch,
        'timeTaken': result.timeTaken,
        'questionCorrectness': result.questionCorrectness,
        'subject': result.subject,
        'topic': result.topic,
        'subTopic': result.subTopic,
        // Add accuracy-related fields
        'estimated_accuracy': result.score / result.totalMarks,
        'validation_confidence': 'calculated',
      });
      print('✅ Test result saved successfully: ${result.testId}');
    } catch (e) {
      print('❌ Error saving test result: $e');
      rethrow;
    }
  }

  Future<void> updateWeakAreas(String studentId, List<String> weakAreas) async {
    try {
      print('🔄 Starting weak areas update in FirebaseService...');
      print('👤 Student ID: $studentId');
      print('📋 Weak Areas: $weakAreas');

      if (studentId.isEmpty) {
        print('❌ Error: Empty student ID');
        throw Exception('Student ID cannot be empty');
      }

      if (weakAreas.isEmpty) {
        print('⚠️ Warning: Empty weak areas list provided');
      }

      // Create update data
      final updateData = {
        'weakAreas': weakAreas,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      print('📤 Sending update to Firebase...');

      // Update the student record
      await _database.child('students').child(studentId).update(updateData);

      print('✅ Weak areas updated successfully in Firebase');

      // Verify the update was successful
      final snapshot = await _database
          .child('students')
          .child(studentId)
          .child('weakAreas')
          .get();
      if (snapshot.exists) {
        final updatedWeakAreas = snapshot.value;
        print('✅ Verification - Weak areas in Firebase: $updatedWeakAreas');
      } else {
        print(
            '⚠️ Verification - No weak areas found after update (might be empty)');
      }
    } catch (e) {
      print('❌ CRITICAL: Failed to update weak areas in Firebase: $e');
      print('📋 Error details:');
      print('  - Type: ${e.runtimeType}');
      // if (e is FirebaseException) {
      //   print('  - Code: ${e.code}');
      //   print('  - Message: ${e.message}');
      //   print('  - Details: ${e.stackTrace}');
      // }
      rethrow;
    }
  }

  // Update topic proficiency with accuracy integration
  Future<void> updateTopicProficiency(
      String studentId, Map<String, double> topicProficiency) async {
    try {
      await _database.child('students').child(studentId).update({
        'topicProficiency': topicProficiency,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
        'proficiencyUpdatedAt': DateTime.now().millisecondsSinceEpoch,
      });
      print('✅ Topic proficiency updated for student: $studentId');
    } catch (e) {
      print('❌ Error updating topic proficiency: $e');
      rethrow;
    }
  }

  // Update performance level
  Future<void> updatePerformanceLevel(
      String studentId, String performanceLevel) async {
    try {
      await _database.child('students').child(studentId).update({
        'performanceLevel': performanceLevel,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
      print('✅ Performance level updated for student: $studentId');
    } catch (e) {
      print('❌ Error updating performance level: $e');
      rethrow;
    }
  }

  // Get complete test details
  Future<Map<String, dynamic>?> getCompleteTestDetails(
      String studentId, String testId) async {
    try {
      print('🔄 Fetching complete test details for: $testId');

      final snapshot = await _database
          .child('completeTests')
          .child(studentId)
          .child(testId)
          .get();

      if (snapshot.exists) {
        print('✅ Complete test details found for: $testId');

        final data = snapshot.value;
        print('📊 Raw data type: ${data.runtimeType}');

        if (data is Map) {
          final convertedData = _convertMap(data);
          final questions = convertedData['questions'] as List<dynamic>? ?? [];
          print(
              '✅ Successfully converted data with ${questions.length} questions');
          return convertedData;
        } else {
          print('❌ Data is not a Map: ${data.runtimeType}');
          return null;
        }
      } else {
        print('⚠️ No complete test details found for: $testId');
        return null;
      }
    } catch (e) {
      print('❌ Error getting complete test details: $e');
      print('📋 Error type: ${e.runtimeType}');
      rethrow;
    }
  }

  // Save complete test details with accuracy integration
  Future<void> saveCompleteTestDetails({
    required String studentId,
    required String testId,
    required String testName,
    required int totalQuestions,
    required int correctAnswers,
    required double score,
    required List<Question> questions,
    required Map<String, int> submittedAnswers,
    required Map<String, bool> questionCorrectness,
    required int timeTaken,
    required Map<String, String> numericalAnswers,
    double? accuracyScore,
    String? confidenceLevel,
  }) async {
    try {
      // Convert questions to serializable format with complete details
      final questionsData = questions.map((question) {
        return {
          'id': question.id,
          'questionText': question.questionText,
          'options': question.options,
          'correctAnswerIndex': question.correctAnswerIndex,
          'marks': question.marks,
          'subject': question.subject,
          'topic': question.topic,
          'difficulty': question.difficulty,
          'timeRequired': question.timeRequired,
          'questionType': question.questionType,
          'isNumerical': question.options.isEmpty ||
              (question.options.length == 1 && question.options[0].isEmpty),
        };
      }).toList();

      final testData = {
        'testId': testId,
        'studentId': studentId,
        'testName': testName,
        'testDate': DateTime.now().millisecondsSinceEpoch,
        'totalQuestions': totalQuestions,
        'correctAnswers': correctAnswers,
        'score': score,
        'timeTaken': timeTaken,
        'submittedAt': DateTime.now().millisecondsSinceEpoch,
        'questions': questionsData,
        'submittedAnswers': submittedAnswers,
        'numericalAnswers': numericalAnswers,
        'questionCorrectness': questionCorrectness,
        'testType': 'AI Personalized Test',
        'subjectDistribution': _calculateSubjectDistribution(questions),
        'topicDistribution': _calculateTopicDistribution(questions),
      };

      // Add accuracy data if available
      if (accuracyScore != null) {
        testData['ai_accuracy_score'] = accuracyScore;
      }
      if (confidenceLevel != null) {
        testData['ai_confidence_level'] = confidenceLevel;
      }

      await _database
          .child('completeTests')
          .child(studentId)
          .child(testId)
          .set(testData);

      print('✅ Complete test details saved successfully: $testId');
    } catch (e) {
      print('❌ Error saving complete test details: $e');
      rethrow;
    }
  }

  // ==================== HELPER METHODS ====================

  Map<String, dynamic> _convertMap(Map<dynamic, dynamic> originalMap) {
    final converted = <String, dynamic>{};

    originalMap.forEach((key, value) {
      final stringKey = key.toString();

      if (value is Map<dynamic, dynamic>) {
        converted[stringKey] = _convertMap(value);
      } else if (value is List<dynamic>) {
        converted[stringKey] = _convertList(value);
      } else {
        converted[stringKey] = value;
      }
    });

    return converted;
  }

  List<dynamic> _convertList(List<dynamic> originalList) {
    return originalList.map((item) {
      if (item is Map<dynamic, dynamic>) {
        return _convertMap(item);
      } else if (item is List<dynamic>) {
        return _convertList(item);
      } else {
        return item;
      }
    }).toList();
  }

  Map<String, int> _calculateSubjectDistribution(List<Question> questions) {
    final distribution = <String, int>{};
    for (var question in questions) {
      distribution[question.subject] =
          (distribution[question.subject] ?? 0) + 1;
    }
    return distribution;
  }

  Map<String, int> _calculateTopicDistribution(List<Question> questions) {
    final distribution = <String, int>{};
    for (var question in questions) {
      distribution[question.topic] = (distribution[question.topic] ?? 0) + 1;
    }
    return distribution;
  }

  // ==================== EXISTING METHODS (KEPT AS IS) ====================

  // Get all test results for a student
  Future<List<TestResult>> getStudentTestResults(String studentId) async {
    try {
      final snapshot =
          await _database.child('testResults').child(studentId).get();

      final testResults = <TestResult>[];

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        data.forEach((testId, testData) {
          final testMap = testData as Map<dynamic, dynamic>;
          final result = TestResult(
            testId: testMap['testId'] ?? '',
            studentId: testMap['studentId'] ?? '',
            testName: testMap['testName'] ?? 'Test',
            testDate: DateTime.fromMillisecondsSinceEpoch(
              testMap['testDate'] ?? DateTime.now().millisecondsSinceEpoch,
            ),
            totalQuestions: testMap['totalQuestions'] ?? 0,
            correctAnswers: testMap['correctAnswers'] ?? 0,
            score: (testMap['score'] ?? 0).toDouble(),
            totalMarks: (testMap['totalMarks'] ?? 0).toDouble(),
            incorrectAnswers: testMap['incorrectAnswers'] ?? 0,
            unattemptedAnswers: testMap['unattemptedAnswers'] ?? 0,
            subjectWiseScores:
                Map<String, double>.from(testMap['subjectWiseScores'] ?? {}),
            topicAccuracy:
                Map<String, double>.from(testMap['topicAccuracy'] ?? {}),
            strongTopics: List<String>.from(testMap['strongTopics'] ?? []),
            weakTopics: List<String>.from(testMap['weakTopics'] ?? []),
            recommendations:
                List<String>.from(testMap['recommendations'] ?? []),
            submittedAt: DateTime.fromMillisecondsSinceEpoch(
              testMap['submittedAt'] ?? DateTime.now().millisecondsSinceEpoch,
            ),
            timeTaken: testMap['timeTaken'] ?? 0,
            questionCorrectness:
                Map<String, bool>.from(testMap['questionCorrectness'] ?? {}),
            questionDetails:
                Map<String, dynamic>.from(testMap['questionDetails'] ?? {}),
            subject: testMap['subject'] ?? 'Mixed',
            topic: testMap['topic'] ?? 'General',
            subTopic: testMap['subTopic'] ?? 'Practice Test',
          );
          testResults.add(result);
        });
      }

      print(
          '✅ Loaded ${testResults.length} test results for student: $studentId');
      return testResults;
    } catch (e) {
      print('❌ Error getting student test results: $e');
      rethrow;
    }
  }

  // Get all complete tests for a student
  Future<List<Map<String, dynamic>>> getStudentCompleteTests(
      String studentId) async {
    try {
      final snapshot =
          await _database.child('completeTests').child(studentId).get();

      final completeTests = <Map<String, dynamic>>[];

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        data.forEach((testId, testData) {
          completeTests.add(testData as Map<String, dynamic>);
        });
      }

      print(
          '✅ Loaded ${completeTests.length} complete tests for student: $studentId');
      return completeTests;
    } catch (e) {
      print('❌ Error getting student complete tests: $e');
      rethrow;
    }
  }

  // Update student's test count
  Future<void> updateStudentTestCount(String studentId, int testsGiven) async {
    try {
      await _database.child('students').child(studentId).update({
        'testsGiven': testsGiven,
        'lastTestDate': DateTime.now().millisecondsSinceEpoch,
      });
      print('✅ Test count updated for student: $studentId');
    } catch (e) {
      print('❌ Error updating test count: $e');
      rethrow;
    }
  }

  // Get student's test count
  Future<int> getStudentTestCount(String studentId) async {
    try {
      final snapshot = await _database
          .child('students')
          .child(studentId)
          .child('testsGiven')
          .get();
      return snapshot.exists ? (snapshot.value as int?) ?? 0 : 0;
    } catch (e) {
      print('❌ Error getting test count: $e');
      return 0;
    }
  }

  // Delete test result
  Future<void> deleteTestResult(String studentId, String testId) async {
    try {
      await _database
          .child('testResults')
          .child(studentId)
          .child(testId)
          .remove();
      print('✅ Test result deleted: $testId');
    } catch (e) {
      print('❌ Error deleting test result: $e');
      rethrow;
    }
  }

  // Delete complete test
  Future<void> deleteCompleteTest(String studentId, String testId) async {
    try {
      await _database
          .child('completeTests')
          .child(studentId)
          .child(testId)
          .remove();
      print('✅ Complete test deleted: $testId');
    } catch (e) {
      print('❌ Error deleting complete test: $e');
      rethrow;
    }
  }

  // Delete accuracy results
  Future<void> deleteAccuracyResults(String studentId, String resultId) async {
    try {
      await _database
          .child('accuracy_results')
          .child(studentId)
          .child(resultId)
          .remove();
      print('✅ Accuracy result deleted: $resultId');
    } catch (e) {
      print('❌ Error deleting accuracy result: $e');
      rethrow;
    }
  }

  // Get student progress over time
  Future<List<Map<String, dynamic>>> getStudentProgress(
      String studentId) async {
    try {
      final snapshot =
          await _database.child('testResults').child(studentId).get();

      final progress = <Map<String, dynamic>>[];

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        data.forEach((testId, testData) {
          final testMap = testData as Map<dynamic, dynamic>;
          progress.add({
            'testId': testId,
            'testName': testMap['testName'] ?? 'Test',
            'score': (testMap['score'] ?? 0).toDouble(),
            'totalMarks': (testMap['totalMarks'] ?? 0).toDouble(),
            'percentage': ((testMap['score'] ?? 0).toDouble() /
                (testMap['totalMarks'] ?? 1).toDouble() *
                100),
            'date': DateTime.fromMillisecondsSinceEpoch(
              testMap['submittedAt'] ?? DateTime.now().millisecondsSinceEpoch,
            ),
            'correctAnswers': testMap['correctAnswers'] ?? 0,
            'totalQuestions': testMap['totalQuestions'] ?? 0,
          });
        });
      }

      // Sort by date
      progress.sort(
          (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

      print(
          '✅ Loaded ${progress.length} progress entries for student: $studentId');
      return progress;
    } catch (e) {
      print('❌ Error getting student progress: $e');
      rethrow;
    }
  }

  // Get weak areas statistics
  Future<Map<String, dynamic>> getWeakAreasStats(String studentId) async {
    try {
      final testResults = await getStudentTestResults(studentId);
      final weakAreasStats = <String, int>{};
      int totalTests = testResults.length;

      for (var result in testResults) {
        for (var weakTopic in result.weakTopics) {
          weakAreasStats[weakTopic] = (weakAreasStats[weakTopic] ?? 0) + 1;
        }
      }

      // Calculate frequency percentage
      final weakAreasFrequency = <String, double>{};
      weakAreasStats.forEach((topic, count) {
        weakAreasFrequency[topic] = (count / totalTests) * 100;
      });

      return {
        'weakAreasStats': weakAreasStats,
        'weakAreasFrequency': weakAreasFrequency,
        'totalTests': totalTests,
      };
    } catch (e) {
      print('❌ Error getting weak areas stats: $e');
      return {
        'weakAreasStats': {},
        'weakAreasFrequency': {},
        'totalTests': 0,
      };
    }
  }

  // Test connection to Firebase
  Future<bool> testConnection() async {
    try {
      final DatabaseReference database = FirebaseDatabase.instance.ref();
      final testRef = database.child('connection_test');

      await testRef.set({
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'message': 'Test connection from FirebaseService',
      });

      // Verify the data was written
      final snapshot = await testRef.get();
      if (snapshot.exists) {
        await testRef.remove();
        print('✅ Firebase connection test: SUCCESS');
        return true;
      } else {
        print('❌ Firebase connection test: FAILED - No data found');
        return false;
      }
    } catch (e) {
      print('❌ Firebase connection test: FAILED - $e');
      return false;
    }
  }

  // Store comprehensive test accuracy report
  Future<void> storeTestAccuracyReport({
    required String studentId,
    required String testId,
    required double overallAccuracy,
    required List<Map<String, dynamic>> questionResults,
    required Map<String, dynamic> testInsights,
  }) async {
    try {
      final reportRef = _database
          .child('test_accuracy_reports')
          .child(studentId)
          .child(testId);

      await reportRef.set({
        'test_id': testId,
        'student_id': studentId,
        'overall_accuracy': overallAccuracy,
        'question_results': questionResults,
        'test_insights': testInsights,
        'validated_at': DateTime.now().millisecondsSinceEpoch,
        'total_questions': questionResults.length,
        'confidence_level': _getConfidenceLevel(overallAccuracy),
      });

      print('✅ Test accuracy report stored: $testId');
    } catch (e) {
      print('❌ Error storing test accuracy report: $e');
      rethrow;
    }
  }

  // Get test accuracy history
  Future<List<Map<String, dynamic>>> getTestAccuracyHistory(
      String studentId) async {
    try {
      final snapshot =
          await _database.child('test_accuracy_reports').child(studentId).get();

      if (snapshot.exists) {
        final Map<dynamic, dynamic> data =
            snapshot.value as Map<dynamic, dynamic>;
        final List<Map<String, dynamic>> reports = [];

        data.forEach((key, value) {
          reports.add({
            'report_id': key,
            ...value,
          });
        });

        // Sort by validation date (newest first)
        reports.sort((a, b) =>
            (b['validated_at'] ?? 0).compareTo(a['validated_at'] ?? 0));

        return reports;
      }
      return [];
    } catch (e) {
      print('❌ Error fetching test accuracy history: $e');
      rethrow;
    }
  }

  // Get accuracy report for a specific test
  Future<Map<String, dynamic>?> getTestAccuracyReport(
      String studentId, String testId) async {
    try {
      final snapshot = await _database
          .child('test_accuracy_reports')
          .child(studentId)
          .child(testId)
          .get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        return _convertMap(data);
      }
      return null;
    } catch (e) {
      print('❌ Error fetching test accuracy report: $e');
      rethrow;
    }
  }

  String _getConfidenceLevel(double accuracy) {
    if (accuracy >= 0.8) return 'high';
    if (accuracy >= 0.6) return 'medium';
    return 'low';
  }

  Future<void> saveAccuracyResults({
    required String studentId,
    required String testId,
    required List<Map<String, dynamic>> accuracyResults,
  }) async {
    try {
      final DatabaseReference database = FirebaseDatabase.instance.ref();
      final accuracyRef = database.child('accuracy_results/$studentId/$testId');

      await accuracyRef.set({
        'testId': testId,
        'studentId': studentId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'accuracyResults': accuracyResults,
        'averageAccuracy': _calculateAverageAccuracy(accuracyResults),
      });

      print('✅ Accuracy results saved for test: $testId');
    } catch (e) {
      print('❌ Error saving accuracy results: $e');
      throw e;
    }
  }

  /// Calculate average accuracy from results
  double _calculateAverageAccuracy(List<Map<String, dynamic>> accuracyResults) {
    if (accuracyResults.isEmpty) return 0.0;

    final totalScore = accuracyResults
        .map((result) => result['accuracy_score'] as double? ?? 0.0)
        .reduce((a, b) => a + b);

    return totalScore / accuracyResults.length;
  }

  /// Save individual question accuracy check (for manual checks)
  Future<void> saveQuestionAccuracyCheck({
    required String studentId,
    required String questionId,
    required Map<String, dynamic> accuracyReport,
  }) async {
    try {
      final DatabaseReference database = FirebaseDatabase.instance.ref();
      final accuracyRef = database.child(
          'question_accuracy_checks/$studentId/${DateTime.now().millisecondsSinceEpoch}');

      await accuracyRef.set({
        'questionId': questionId,
        'studentId': studentId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'accuracyReport': accuracyReport,
      });

      print('✅ Question accuracy check saved for question: $questionId');
    } catch (e) {
      print('❌ Error saving question accuracy check: $e');
      throw e;
    }
  }

  /// Get question accuracy checks for a student
  Future<List<Map<String, dynamic>>> getQuestionAccuracyChecks(
      String studentId) async {
    try {
      final DatabaseReference database = FirebaseDatabase.instance.ref();
      final accuracyRef = database.child('question_accuracy_checks/$studentId');

      final snapshot = await accuracyRef.get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          final checks = <Map<String, dynamic>>[];

          data.forEach((timestamp, checkData) {
            if (checkData is Map<dynamic, dynamic>) {
              checks.add(_convertMap(checkData));
            }
          });

          // Sort by timestamp (newest first)
          checks.sort((a, b) =>
              (b['timestamp'] as int).compareTo(a['timestamp'] as int));

          return checks;
        }
      }
      return [];
    } catch (e) {
      print('❌ Error getting question accuracy checks: $e');
      return [];
    }
  }

// Add this method to FirebaseService class
  Future<void> debugWeakAreasUpdate(
      String studentId, List<String> weakAreas) async {
    try {
      print('🔍 DEBUG: Starting weak areas update debug...');
      print('📝 Student ID: $studentId');
      print('📝 Weak Areas to update: $weakAreas');

      // Test if we can write to Firebase
      final testRef = _database.child('debug_test').child(studentId);
      await testRef.set({
        'test_timestamp': DateTime.now().millisecondsSinceEpoch,
        'test_message': 'Testing Firebase write access',
        'weak_areas_test': weakAreas,
      });

      print('✅ DEBUG: Firebase write test successful');

      // Now try the actual update
      await _database.child('students').child(studentId).update({
        'weakAreas': weakAreas,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        'debug_updated': true,
      });

      print('✅ DEBUG: Weak areas update completed');

      // Verify the update
      final snapshot = await _database
          .child('students')
          .child(studentId)
          .child('weakAreas')
          .get();
      if (snapshot.exists) {
        print(
            '✅ DEBUG: Verification - Current weak areas in Firebase: ${snapshot.value}');
      } else {
        print('❌ DEBUG: Verification - No weak areas found in Firebase');
      }
    } catch (e) {
      print('❌ DEBUG: Error in weak areas update: $e');
      print('📋 DEBUG: Error type: ${e.runtimeType}');
      // if (e is FirebaseException) {
      //   print('📋 DEBUG: Firebase error code: ${e.code}');
      //   print('📋 DEBUG: Firebase error message: ${e.message}');
      // }
    }
  }
}
