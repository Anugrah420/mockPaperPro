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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDwmJEq3o-RlK0bPRzcvxupD96bGt-nL-Y",
      authDomain: "classicopaper.firebaseapp.com",
      databaseURL:
          "https://classicopaper-default-rtdb.asia-southeast1.firebasedatabase.app",
      projectId: "classicopaper",
      storageBucket: "classicopaper.firebasestorage.com",
      messagingSenderId: "14400084629",
      appId: "1:14400084629:web:80cc32c700fae7e132999c",
      measurementId: "G-28EQXKPXZW",
    ),
  );

  await _testFirebaseDirectly();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthService()),
        ChangeNotifierProvider(create: (context) => AITestService()),
      ],
      child: const AIJeeMockTestApp(),
    ),
  );
}

Future<void> _testFirebaseDirectly() async {
  try {
    print('🔄 Testing Firebase connection directly...');
    final DatabaseReference database = FirebaseDatabase.instance.ref();
    final testRef = database.child('connection_test');

    await testRef.set({
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'message': 'Test connection from Flutter Web'
    });

    print('✅ Firebase connection test: SUCCESS - Data written to database');

    final snapshot = await testRef.get();
    if (snapshot.exists) {
      print('✅ Data verification: SUCCESS - Data found in database');
      print('📊 Data: ${snapshot.value}');
    } else {
      print('❌ Data verification: FAILED - No data found');
    }

    await testRef.remove();
    print('🧹 Test data cleaned up');
  } catch (e) {
    print('❌ Firebase connection test: FAILED - $e');
    print('📋 Error details:');
    print('  - Type: ${e.runtimeType}');
    if (e is FirebaseException) {
      print('  - Code: ${e.code}');
      print('  - Message: ${e.message}');
    }
  }
}

class AuthService with ChangeNotifier {
  bool _isAuthenticated = false;
  Student? _currentStudent;
  final List<Student> _students = [];
  final Random _random = Random();
  final FirebaseService _firebaseService = FirebaseService();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  bool get isAuthenticated => _isAuthenticated;
  Student? get currentStudent => _currentStudent;

  AuthService() {
    _initializeStudents();
  }

  void _initializeStudents() {
    _students.addAll([
      Student(
        studentId: 'AD24B1002',
        name: 'Abhishek Sharma',
        email: 'abhishek@gmail.com',
        password: 'password123',
        weakAreas: [
          'Organic Compounds Containing Nitrogen',
          'Integral Calculus',
          'Electromagnetic Induction and Alternating Currents',
          'Statistics and Probability',
        ],
        performanceLevel: 'Intermediate',
        topicProficiency: {
          'Sets, Relations and Functions': 0.7,
          'Complex Numbers and Quadratic Equations': 0.6,
          'Matrices and Determinants': 0.8,
          'Permutations and Combinations': 0.5,
          'Binomial Theorem and Its Simple Applications': 0.4,
          'Sequence and Series': 0.6,
          'Limit, Continuity and Differentiability': 0.7,
          'Integral Calculus': 0.3,
          'Differential Equations': 0.5,
          'Coordinate Geometry': 0.8,
          'Three Dimensional Geometry': 0.6,
          'Vector Algebra': 0.7,
          'Statistics and Probability': 0.4,
          'Trigonometry': 0.6,
          'Units and Measurements': 0.8,
          'Kinematics': 0.7,
          'Laws of Motion': 0.9,
          'Work, Energy and Power': 0.6,
          'Rotational Motion': 0.5,
          'Gravitation': 0.8,
          'Properties of Solids and Liquids': 0.7,
          'Thermodynamics': 0.6,
          'Kinetic Theory of Gases': 0.5,
          'Oscillations and Waves': 0.8,
          'Electrostatics': 0.7,
          'Current Electricity': 0.6,
          'Magnetic Effects of Current and Magnetism': 0.8,
          'Electromagnetic Induction and Alternating Currents': 0.4,
          'Electromagnetic Waves': 0.5,
          'Optics': 0.7,
          'Dual Nature of Matter and Radiation': 0.6,
          'Atoms and Nuclei': 0.8,
          'Electronic Devices': 0.5,
          'Experimental Skills': 0.7,
          'Some Basic Concepts in Chemistry': 0.8,
          'Atomic Structure': 0.7,
          'Chemical Bonding and Molecular Structure': 0.6,
          'Chemical Thermodynamics': 0.5,
          'Solutions': 0.8,
          'Equilibrium': 0.7,
          'Redox Reactions and Electrochemistry': 0.6,
          'Chemical Kinetics': 0.5,
          'Classification of Elements and Periodicity in Properties': 0.8,
          'p-Block Elements': 0.7,
          'd- and f-Block Elements': 0.6,
          'Coordination Compounds': 0.5,
          'Purification and Characterisation of Organic Compounds': 0.8,
          'Some Basic Principles of Organic Chemistry': 0.7,
          'Hydrocarbons': 0.6,
          'Organic Compounds Containing Halogens': 0.5,
          'Organic Compounds Containing Oxygen': 0.8,
          'Organic Compounds Containing Nitrogen': 0.3,
          'Biomolecules': 0.6,
          'Principles Related to Practical Chemistry': 0.7,
        },
        createdAt: DateTime.now(),
      ),
      Student(
        studentId: 'CS24B1032',
        name: 'Krrish',
        email: 'krrish@gmail.com',
        password: 'password123',
        weakAreas: ['Coordinate Geometry', 'Thermodynamics'],
        performanceLevel: 'Advanced',
        topicProficiency: {
          'Sets, Relations and Functions': 0.9,
          'Complex Numbers and Quadratic Equations': 0.8,
          'Matrices and Determinants': 0.9,
          'Permutations and Combinations': 0.8,
          'Binomial Theorem and Its Simple Applications': 0.7,
          'Sequence and Series': 0.9,
          'Limit, Continuity and Differentiability': 0.8,
          'Integral Calculus': 0.8,
          'Differential Equations': 0.7,
          'Coordinate Geometry': 0.6,
          'Three Dimensional Geometry': 0.8,
          'Vector Algebra': 0.9,
          'Statistics and Probability': 0.7,
          'Trigonometry': 0.8,
          'Units and Measurements': 0.9,
          'Kinematics': 0.8,
          'Laws of Motion': 0.9,
          'Work, Energy and Power': 0.8,
          'Rotational Motion': 0.7,
          'Gravitation': 0.9,
          'Properties of Solids and Liquids': 0.8,
          'Thermodynamics': 0.6,
          'Kinetic Theory of Gases': 0.7,
          'Oscillations and Waves': 0.8,
          'Electrostatics': 0.9,
          'Current Electricity': 0.8,
          'Magnetic Effects of Current and Magnetism': 0.9,
          'Electromagnetic Induction and Alternating Currents': 0.8,
          'Electromagnetic Waves': 0.7,
          'Optics': 0.8,
          'Dual Nature of Matter and Radiation': 0.7,
          'Atoms and Nuclei': 0.9,
          'Electronic Devices': 0.8,
          'Experimental Skills': 0.9,
          'Some Basic Concepts in Chemistry': 0.8,
          'Atomic Structure': 0.9,
          'Chemical Bonding and Molecular Structure': 0.8,
          'Chemical Thermodynamics': 0.7,
          'Solutions': 0.9,
          'Equilibrium': 0.8,
          'Redox Reactions and Electrochemistry': 0.7,
          'Chemical Kinetics': 0.8,
          'Classification of Elements and Periodicity in Properties': 0.9,
          'p-Block Elements': 0.8,
          'd- and f-Block Elements': 0.7,
          'Coordination Compounds': 0.8,
          'Purification and Characterisation of Organic Compounds': 0.9,
          'Some Basic Principles of Organic Chemistry': 0.8,
          'Hydrocarbons': 0.7,
          'Organic Compounds Containing Halogens': 0.8,
          'Organic Compounds Containing Oxygen': 0.9,
          'Organic Compounds Containing Nitrogen': 0.6,
          'Biomolecules': 0.8,
          'Principles Related to Practical Chemistry': 0.9,
        },
        createdAt: DateTime.now(),
      ),
    ]);
  }

  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return {'success': false, 'message': 'Google sign in cancelled'};
      }

      final email = googleUser.email;
      final name = googleUser.displayName ?? 'Google User';

      if (email == null) {
        return {'success': false, 'message': 'Could not get email from Google'};
      }

      Student? existingStudent;
      try {
        existingStudent = await _firebaseService.getStudentByEmail(email);
      } catch (e) {
        try {
          existingStudent = _students.firstWhere(
            (student) => student.email == email,
          );
        } catch (e) {
          existingStudent = null;
        }
      }

      if (existingStudent == null) {
        final studentId =
            'JEE${DateTime.now().year}${_students.length + 1}'.padLeft(3, '0');

        final newStudent = Student(
          studentId: studentId,
          name: name,
          email: email,
          password: 'google_oauth_${DateTime.now().millisecondsSinceEpoch}',
          weakAreas: [],
          performanceLevel: 'Beginner',
          topicProficiency: _generateRandomProficiencies(),
          createdAt: DateTime.now(),
        );

        _students.add(newStudent);
        _currentStudent = newStudent;

        try {
          await _firebaseService.saveStudentData(newStudent);
        } catch (e) {
          print('Firebase save failed: $e');
        }

        _isAuthenticated = true;
        notifyListeners();

        return {
          'success': true,
          'message': 'Welcome! Please set up your profile.',
          'isNewUser': true
        };
      } else {
        _currentStudent = existingStudent;
        _isAuthenticated = true;
        notifyListeners();

        return {
          'success': true,
          'message': 'Welcome back, ${existingStudent.name}!',
          'isNewUser': false
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Google sign in failed: $e'};
    }
  }

  Map<String, double> _generateRandomProficiencies() {
    return {
      'Sets, Relations and Functions': _random.nextDouble(),
      'Complex Numbers and Quadratic Equations': _random.nextDouble(),
      'Matrices and Determinants': _random.nextDouble(),
      'Permutations and Combinations': _random.nextDouble(),
      'Binomial Theorem and Its Simple Applications': _random.nextDouble(),
      'Sequence and Series': _random.nextDouble(),
      'Limit, Continuity and Differentiability': _random.nextDouble(),
      'Integral Calculus': _random.nextDouble(),
      'Differential Equations': _random.nextDouble(),
      'Coordinate Geometry': _random.nextDouble(),
      'Three Dimensional Geometry': _random.nextDouble(),
      'Vector Algebra': _random.nextDouble(),
      'Statistics and Probability': _random.nextDouble(),
      'Trigonometry': _random.nextDouble(),
      'Units and Measurements': _random.nextDouble(),
      'Kinematics': _random.nextDouble(),
      'Laws of Motion': _random.nextDouble(),
      'Work, Energy and Power': _random.nextDouble(),
      'Rotational Motion': _random.nextDouble(),
      'Gravitation': _random.nextDouble(),
      'Properties of Solids and Liquids': _random.nextDouble(),
      'Thermodynamics': _random.nextDouble(),
      'Kinetic Theory of Gases': _random.nextDouble(),
      'Oscillations and Waves': _random.nextDouble(),
      'Electrostatics': _random.nextDouble(),
      'Current Electricity': _random.nextDouble(),
      'Magnetic Effects of Current and Magnetism': _random.nextDouble(),
      'Electromagnetic Induction and Alternating Currents':
          _random.nextDouble(),
      'Electromagnetic Waves': _random.nextDouble(),
      'Optics': _random.nextDouble(),
      'Dual Nature of Matter and Radiation': _random.nextDouble(),
      'Atoms and Nuclei': _random.nextDouble(),
      'Electronic Devices': _random.nextDouble(),
      'Experimental Skills': _random.nextDouble(),
      'Some Basic Concepts in Chemistry': _random.nextDouble(),
      'Atomic Structure': _random.nextDouble(),
      'Chemical Bonding and Molecular Structure': _random.nextDouble(),
      'Chemical Thermodynamics': _random.nextDouble(),
      'Solutions': _random.nextDouble(),
      'Equilibrium': _random.nextDouble(),
      'Redox Reactions and Electrochemistry': _random.nextDouble(),
      'Chemical Kinetics': _random.nextDouble(),
      'Classification of Elements and Periodicity in Properties':
          _random.nextDouble(),
      'p-Block Elements': _random.nextDouble(),
      'd- and f-Block Elements': _random.nextDouble(),
      'Coordination Compounds': _random.nextDouble(),
      'Purification and Characterisation of Organic Compounds':
          _random.nextDouble(),
      'Some Basic Principles of Organic Chemistry': _random.nextDouble(),
      'Hydrocarbons': _random.nextDouble(),
      'Organic Compounds Containing Halogens': _random.nextDouble(),
      'Organic Compounds Containing Oxygen': _random.nextDouble(),
      'Organic Compounds Containing Nitrogen': _random.nextDouble(),
      'Biomolecules': _random.nextDouble(),
      'Principles Related to Practical Chemistry': _random.nextDouble(),
    };
  }

  Future<void> testWeakAreasUpdate() async {
    if (_currentStudent == null) return;

    final testWeakAreas = ['Test Topic 1', 'Test Topic 2', 'Test Topic 3'];
    print('🧪 TEST: Starting weak areas update test...');
    print('📋 Test weak areas: $testWeakAreas');

    updateWeakAreas(testWeakAreas);

    // Wait a bit and check
    await Future.delayed(Duration(seconds: 2));

    print(
        '🧪 TEST: Current weak areas after update: ${_currentStudent?.weakAreas}');

    // Also test Firebase directly
    try {
      await _firebaseService.debugWeakAreasUpdate(
          _currentStudent!.studentId, testWeakAreas);
    } catch (e) {
      print('❌ TEST: Firebase debug failed: $e');
    }
  }

  void _debugStudents() {
    print('📊 Current local students count: ${_students.length}');
    for (var student in _students) {
      print('  - ${student.studentId}: ${student.name} (${student.email})');
    }
  }

  Future<void> googleSignOut() async {
    await _googleSignIn.signOut();
    await logout();
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    if (password != confirmPassword) {
      return {'success': false, 'message': 'Passwords do not match'};
    }

    if (password.length < 6) {
      return {
        'success': false,
        'message': 'Password must be at least 6 characters',
      };
    }

    Student? existingStudent;
    try {
      existingStudent = await _firebaseService.getStudentByEmail(email);
    } catch (e) {
      print('Error checking existing student: $e');
    }

    if (existingStudent == null) {
      try {
        existingStudent = _students.firstWhere(
          (student) => student.email == email,
        );
      } catch (e) {
        existingStudent = null;
      }
    }

    if (existingStudent != null) {
      return {'success': false, 'message': 'Email already registered'};
    }

    final studentId =
        'JEE${DateTime.now().year}${_students.length + 1}${DateTime.now().millisecondsSinceEpoch % 1000}';

    final newStudent = Student(
      studentId: studentId,
      name: name,
      email: email,
      password: password,
      weakAreas: [],
      performanceLevel: 'Beginner',
      topicProficiency: _generateRandomProficiencies(),
      createdAt: DateTime.now(),
    );

    _students.add(newStudent);
    _currentStudent = newStudent;
    _isAuthenticated = true;

    try {
      await _firebaseService.saveStudentData(newStudent);
      print('✅ Student registered successfully: $studentId');
    } catch (e) {
      print('❌ Firebase save failed: $e');
      _students.removeWhere((s) => s.studentId == studentId);
      _currentStudent = null;
      _isAuthenticated = false;
      return {
        'success': false,
        'message': 'Registration failed. Please try again.'
      };
    }

    notifyListeners();

    return {'success': true, 'message': 'Registration successful!'};
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration());

    Student? student;

    try {
      student = await _firebaseService.getStudentByEmail(email);
      if (student != null && student.password == password) {
        _currentStudent = student;
        _isAuthenticated = true;
        notifyListeners();
        return {'success': true, 'message': 'Login successful!'};
      }
    } catch (e) {
      try {
        student = _students.firstWhere(
          (s) => s.email == email && s.password == password,
        );
        _currentStudent = student;
        _isAuthenticated = true;
        notifyListeners();
        return {'success': true, 'message': 'Login successful!'};
      } catch (e) {
        return {'success': false, 'message': 'Invalid email or password'};
      }
    }

    return {'success': false, 'message': 'Invalid email or password'};
  }

  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _isAuthenticated = false;
    _currentStudent = null;
    notifyListeners();
  }

  void updateWeakAreas(List<String> newWeakAreas) {
    print('🔄 STARTING WEAK AREAS UPDATE PROCESS...');
    print('📋 New weak areas received: $newWeakAreas');

    if (_currentStudent == null) {
      print('❌ CRITICAL: No current student available for update');
      return;
    }

    final studentId = _currentStudent!.studentId;
    print('👤 Current student ID: $studentId');
    print('📝 Previous weak areas: ${_currentStudent!.weakAreas}');

    // Update local student data first
    final index = _students.indexWhere((s) => s.studentId == studentId);

    if (index == -1) {
      print('❌ CRITICAL: Student not found in local list');
      return;
    }

    print('✅ Found student at index: $index');

    // Create updated student
    final updatedStudent = Student(
      studentId: _currentStudent!.studentId,
      name: _currentStudent!.name,
      email: _currentStudent!.email,
      password: _currentStudent!.password,
      weakAreas: newWeakAreas,
      performanceLevel: _currentStudent!.performanceLevel,
      topicProficiency: _currentStudent!.topicProficiency,
      createdAt: _currentStudent!.createdAt,
      testsGiven: _currentStudent!.testsGiven,
    );

    // Update local storage
    _students[index] = updatedStudent;
    _currentStudent = updatedStudent;

    print('✅ Local weak areas updated to: ${_currentStudent!.weakAreas}');

    // Update Firebase
    _updateFirebaseWeakAreas(studentId, newWeakAreas);

    notifyListeners();
    print('🔔 Listeners notified of weak areas change');
    print('✅ WEAK AREAS UPDATE PROCESS COMPLETED');
  }

  Future<void> _updateFirebaseWeakAreas(
      String studentId, List<String> weakAreas) async {
    try {
      print('🌐 Starting Firebase weak areas update...');
      await _firebaseService.updateWeakAreas(studentId, weakAreas);
      print('✅ Firebase weak areas update completed successfully');
    } catch (e) {
      print('❌ Firebase weak areas update failed: $e');
      print('⚠️ Continuing with local update only');

      // Show error to user (optional)
      // You can add a snackbar or dialog here to inform the user
    }
  }

  void updateTopicProficiency(String topic, double proficiency) {
    if (_currentStudent != null) {
      final index = _students.indexWhere(
        (s) => s.studentId == _currentStudent!.studentId,
      );
      if (index != -1) {
        var newProficiency = Map<String, double>.from(
          _currentStudent!.topicProficiency,
        );
        newProficiency[topic] = proficiency;

        _students[index] = Student(
          studentId: _currentStudent!.studentId,
          name: _currentStudent!.name,
          email: _currentStudent!.email,
          password: _currentStudent!.password,
          weakAreas: _currentStudent!.weakAreas,
          performanceLevel: _currentStudent!.performanceLevel,
          topicProficiency: newProficiency,
          createdAt: _currentStudent!.createdAt,
          testsGiven: _currentStudent!.testsGiven,
        );
        _currentStudent = _students[index];

        try {
          _firebaseService.updateTopicProficiency(
              _currentStudent!.studentId, newProficiency);
        } catch (e) {
          print('Firebase update failed: $e');
        }

        notifyListeners();
      }
    }
  }

  void incrementTestCount() {
    if (_currentStudent != null) {
      final index = _students.indexWhere(
        (s) => s.studentId == _currentStudent!.studentId,
      );
      if (index != -1) {
        final newTestCount = (_currentStudent!.testsGiven ?? 0) + 1;

        _students[index] = Student(
          studentId: _currentStudent!.studentId,
          name: _currentStudent!.name,
          email: _currentStudent!.email,
          password: _currentStudent!.password,
          weakAreas: _currentStudent!.weakAreas,
          performanceLevel: _currentStudent!.performanceLevel,
          topicProficiency: _currentStudent!.topicProficiency,
          createdAt: _currentStudent!.createdAt,
          testsGiven: newTestCount,
        );
        _currentStudent = _students[index];

        try {
          _firebaseService.updateStudentTestCount(
              _currentStudent!.studentId, newTestCount);
        } catch (e) {
          print('Firebase test count update failed: $e');
        }

        notifyListeners();
      }
    }
  }

  void updatePerformanceLevel(String level) {
    if (_currentStudent != null) {
      final index = _students.indexWhere(
        (s) => s.studentId == _currentStudent!.studentId,
      );
      if (index != -1) {
        _students[index] = Student(
          studentId: _currentStudent!.studentId,
          name: _currentStudent!.name,
          email: _currentStudent!.email,
          password: _currentStudent!.password,
          weakAreas: _currentStudent!.weakAreas,
          performanceLevel: level,
          topicProficiency: _currentStudent!.topicProficiency,
          createdAt: _currentStudent!.createdAt,
        );
        _currentStudent = _students[index];
        notifyListeners();
      }
    }
  }
}

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

  List<Question> get _questionBank => QuestionBank.questions;

  Future<List<Map<String, dynamic>>> getAccuracyHistory(
      String studentId) async {
    try {
      final DatabaseReference database = FirebaseDatabase.instance.ref();
      final accuracyRef = database.child('accuracy_results/$studentId');

      final snapshot = await accuracyRef.get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          final history = <Map<String, dynamic>>[];

          data.forEach((testId, testData) {
            if (testData is Map<dynamic, dynamic>) {
              final convertedMap = <String, dynamic>{};
              testData.forEach((key, value) {
                convertedMap[key.toString()] = value;
              });

              final questionResults = convertedMap.values
                  .whereType<Map<dynamic, dynamic>>()
                  .toList();
              final overallAccuracy = questionResults.isNotEmpty
                  ? questionResults
                          .map((q) => (q['accuracy_score'] ?? 0.0) as double)
                          .reduce((a, b) => a + b) /
                      questionResults.length
                  : 0.0;

              convertedMap['overall_accuracy'] = overallAccuracy;
              convertedMap['questions_analyzed'] = questionResults.length;
              convertedMap['test_id'] = testId.toString();

              history.add(convertedMap);
            }
          });

          return history;
        }
      }
      return [];
    } catch (e) {
      print('❌ Error getting accuracy history: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getCompleteTestDetails(
      String studentId, String testId) async {
    return await _firebaseService.getCompleteTestDetails(studentId, testId);
  }

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

    final weakAreaQuestions =
        _questionBank.where((q) => weakAreas.contains(q.topic)).toList();

    if (weakAreaQuestions.isEmpty) {
      throw Exception(
          'No questions available in your weak areas. Please update your weak areas or contact support.');
    }

    weakAreaQuestions.shuffle();

    if (weakAreaQuestions.length >= numberOfQuestions) {
      selectedQuestions.addAll(weakAreaQuestions.take(numberOfQuestions));
    } else {
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

    if (selectedQuestions.length < numberOfQuestions) {
      for (var entry in sortedQuestions) {
        if (selectedQuestions.length >= numberOfQuestions) break;
        if (!selectedQuestions.contains(entry.key)) {
          selectedQuestions.add(entry.key);
        }
      }
    }

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

    double? calculatedAccuracyScore;
    String? calculatedConfidenceLevel;
    Map<String, dynamic>? testAccuracyReportData;

    if (validateAccuracy) {
      try {
        final accuracyResults = <Map<String, dynamic>>[];

        for (var question in test.questions) {
          final accuracyResult =
              await AccuracyValidatorService.validateQuestionAccuracy(
            question: question,
            studentId: studentId,
          );
          accuracyResults.add(accuracyResult);
        }

        final overallAccuracyScore = accuracyResults.isNotEmpty
            ? accuracyResults
                    .map((r) => r['accuracy_score'] as double)
                    .reduce((a, b) => a + b) /
                accuracyResults.length
            : 0.0;

        final overallConfidenceLevel =
            _getOverallConfidenceLevel(overallAccuracyScore);

        await _firebaseService.saveAccuracyResults(
          studentId: studentId,
          testId: testId,
          accuracyResults: accuracyResults,
        );

        calculatedAccuracyScore = overallAccuracyScore;
        calculatedConfidenceLevel = overallConfidenceLevel;

        testAccuracyReportData =
            _generateDetailedAccuracyReport(accuracyResults, test.questions);

        print(
            '✅ Accuracy validation completed for ${accuracyResults.length} questions');
        print(
            '📊 Overall accuracy score: ${(overallAccuracyScore * 100).toStringAsFixed(1)}%');
        print('🎯 Confidence level: $overallConfidenceLevel');
      } catch (e) {
        print('Accuracy validation error: $e');
        calculatedAccuracyScore = 0.0;
        calculatedConfidenceLevel = 'Medium';
      }
    }

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

    Map<String, int> topicCorrectCount = {};
    Map<String, int> topicIncorrectCount = {};
    Map<String, int> topicUnattemptedCount = {};
    Map<String, int> topicTotalCount = {};

    Map<String, bool> questionCorrectness = {};
    List<String> correctTopics = [];
    List<String> incorrectTopics = [];
    List<String> unattemptedTopics = [];

    for (var question in test.questions) {
      final userAnswer = submittedAnswers[question.id];
      subjectTotalCount[question.subject] =
          (subjectTotalCount[question.subject] ?? 0) + 1;

      topicTotalCount[question.topic] =
          (topicTotalCount[question.topic] ?? 0) + 1;

      if (userAnswer == null) {
        unattemptedCount++;
        topicUnattemptedCount[question.topic] =
            (topicUnattemptedCount[question.topic] ?? 0) + 1;
        unattemptedTopics.add(question.topic);
        questionCorrectness[question.id] = false;
      } else if (userAnswer == question.correctAnswerIndex) {
        correctCount++;
        subjectCorrectCount[question.subject] =
            (subjectCorrectCount[question.subject] ?? 0) + 1;
        topicCorrectCount[question.topic] =
            (topicCorrectCount[question.topic] ?? 0) + 1;
        correctTopics.add(question.topic);
        questionCorrectness[question.id] = true;
      } else {
        incorrectCount++;
        topicIncorrectCount[question.topic] =
            (topicIncorrectCount[question.topic] ?? 0) + 1;
        incorrectTopics.add(question.topic);
        questionCorrectness[question.id] = false;
      }
    }

    double totalMarks = test.questions.length * 4.0;
    double score = correctCount * 4.0;

    Map<String, double> subjectWiseScores = {};
    subjectCorrectCount.forEach((subject, correct) {
      subjectWiseScores[subject] = correct * 4.0;
    });

    double? finalAccuracyScore =
        calculatedAccuracyScore ?? (score / totalMarks);
    String? finalConfidenceLevel = calculatedConfidenceLevel ?? 'Medium';

    Map<String, double> topicAccuracy = {};
    List<String> strongTopics = [];
    List<String> weakTopics = [];

    topicTotalCount.forEach((topic, total) {
      final correct = topicCorrectCount[topic] ?? 0;
      final accuracy = total > 0 ? correct / total : 0.0;
      topicAccuracy[topic] = accuracy;

      if (accuracy < 0.6 && total >= 2) {
        weakTopics.add(topic);
        print(
            '🎯 Identified weak topic: $topic (accuracy: ${(accuracy * 100).toStringAsFixed(1)}%)');
      } else if (accuracy == 1.0 && total >= 1) {
        strongTopics.add(topic);
      }
    });

    for (var topic in incorrectTopics) {
      if (!weakTopics.contains(topic) && !strongTopics.contains(topic)) {
        weakTopics.add(topic);
        print('🎯 Added weak topic from incorrect answers: $topic');
      }
    }

    weakTopics = weakTopics.toSet().toList();

    print('📊 Weak area analysis complete:');
    print('   - Strong topics: $strongTopics');
    print('   - Weak topics: $weakTopics');
    print('   - Topic accuracy: $topicAccuracy');

    if (weakTopics.isNotEmpty) {
      _updateStudentWeakAreas(authService, weakTopics);
    } else {
      print('ℹ️ No weak topics identified for update');
    }

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
        accuracyScore: finalAccuracyScore,
        confidenceLevel: finalConfidenceLevel,
      );
    } catch (e) {
      print('❌ Error saving complete test details: $e');
    }

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
      accuracyScore: finalAccuracyScore,
      accuracyInsights: testAccuracyReportData ?? {},
      testAccuracyReport: testAccuracyReportData,
    );

    _testResults.add(result);

    try {
      await _firebaseService.saveTestResult(result);
    } catch (e) {
      print('Error saving test result: $e');
    }

    authService.incrementTestCount();

    notifyListeners();
    return result;
  }

  String _getOverallConfidenceLevel(double accuracyScore) {
    if (accuracyScore >= 0.9) return 'Very High';
    if (accuracyScore >= 0.8) return 'High';
    if (accuracyScore >= 0.7) return 'Medium';
    if (accuracyScore >= 0.6) return 'Low';
    return 'Very Low';
  }

  Map<String, dynamic> _generateDetailedAccuracyReport(
    List<Map<String, dynamic>> accuracyResults,
    List<Question> questions,
  ) {
    final report = <String, dynamic>{};

    final totalQuestions = accuracyResults.length;
    final highAccuracyCount = accuracyResults
        .where((r) => (r['accuracy_score'] as double) >= 0.8)
        .length;
    final mediumAccuracyCount = accuracyResults.where((r) {
      final score = r['accuracy_score'] as double;
      return score >= 0.6 && score < 0.8;
    }).length;
    final lowAccuracyCount = accuracyResults
        .where((r) => (r['accuracy_score'] as double) < 0.6)
        .length;

    final subjectAccuracy = <String, List<double>>{};
    for (var i = 0; i < questions.length; i++) {
      final question = questions[i];
      final accuracyResult = accuracyResults[i];
      final subject = question.subject;

      if (!subjectAccuracy.containsKey(subject)) {
        subjectAccuracy[subject] = [];
      }
      subjectAccuracy[subject]!.add(accuracyResult['accuracy_score'] as double);
    }

    final subjectAverageAccuracy = <String, double>{};
    subjectAccuracy.forEach((subject, scores) {
      subjectAverageAccuracy[subject] =
          scores.reduce((a, b) => a + b) / scores.length;
    });

    final topicAccuracy = <String, List<double>>{};
    for (var i = 0; i < questions.length; i++) {
      final question = questions[i];
      final accuracyResult = accuracyResults[i];
      final topic = question.topic;

      if (!topicAccuracy.containsKey(topic)) {
        topicAccuracy[topic] = [];
      }
      topicAccuracy[topic]!.add(accuracyResult['accuracy_score'] as double);
    }

    final allIssues = <String>[];
    final allRecommendations = <String>[];

    for (var result in accuracyResults) {
      final issues = result['issues_found'] as List<dynamic>? ?? [];
      final recommendations = result['recommendations'] as List<dynamic>? ?? [];

      allIssues.addAll(issues.map((e) => e.toString()));
      allRecommendations.addAll(recommendations.map((e) => e.toString()));
    }

    final issueFrequency = <String, int>{};
    for (var issue in allIssues) {
      issueFrequency[issue] = (issueFrequency[issue] ?? 0) + 1;
    }

    final mostCommonIssues = issueFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value))
      ..take(5);

    report['overall_accuracy'] = accuracyResults.isNotEmpty
        ? accuracyResults
                .map((r) => r['accuracy_score'] as double)
                .reduce((a, b) => a + b) /
            accuracyResults.length
        : 0.0;

    report['accuracy_breakdown'] = {
      'high_accuracy_questions': highAccuracyCount,
      'medium_accuracy_questions': mediumAccuracyCount,
      'low_accuracy_questions': lowAccuracyCount,
      'total_questions_analyzed': totalQuestions,
    };

    report['subject_accuracy'] = subjectAverageAccuracy;
    report['most_common_issues'] =
        mostCommonIssues.map((e) => '${e.key} (${e.value} questions)').toList();
    report['key_recommendations'] = allRecommendations.toSet().take(5).toList();
    report['questions_analyzed'] = totalQuestions;
    report['confidence_distribution'] = {
      'very_high': accuracyResults
          .where((r) => r['confidence_level'] == 'Very High')
          .length,
      'high':
          accuracyResults.where((r) => r['confidence_level'] == 'High').length,
      'medium': accuracyResults
          .where((r) => r['confidence_level'] == 'Medium')
          .length,
      'low':
          accuracyResults.where((r) => r['confidence_level'] == 'Low').length,
      'very_low': accuracyResults
          .where((r) => r['confidence_level'] == 'Very Low')
          .length,
    };

    return report;
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

  void _updateStudentWeakAreas(
      AuthService authService, List<String> newWeakTopics) {
    print('🎯 STARTING AUTOMATIC WEAK AREAS UPDATE FROM TEST...');

    final student = authService.currentStudent;
    if (student == null) {
      print('❌ Cannot update weak areas: No current student');
      return;
    }

    final currentWeakAreas = List<String>.from(student.weakAreas);
    print('📊 Current weak areas: $currentWeakAreas');
    print('🎯 New weak topics identified: $newWeakTopics');

    // Add new weak topics that aren't already in the list
    final updatedWeakAreas = List<String>.from(currentWeakAreas);
    int addedCount = 0;

    for (var topic in newWeakTopics) {
      if (!updatedWeakAreas.contains(topic)) {
        updatedWeakAreas.add(topic);
        addedCount++;
        print('✅ Added weak area: $topic');
      }
    }

    print('📈 Added $addedCount new weak areas');

    // Limit to maximum 8 weak areas, keeping the newest ones
    final finalWeakAreas = updatedWeakAreas.length > 8
        ? updatedWeakAreas.sublist(updatedWeakAreas.length - 8)
        : updatedWeakAreas;

    print('📝 Final weak areas (max 8): $finalWeakAreas');

    if (finalWeakAreas.length != currentWeakAreas.length) {
      print('🔄 Changes detected, updating weak areas...');
      authService.updateWeakAreas(finalWeakAreas);
    } else {
      print('ℹ️ No changes in weak areas, skipping update');
    }

    print('✅ AUTOMATIC WEAK AREAS UPDATE COMPLETED');
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

    recommendations.add(
      '📊 Performance Summary: $correctCount correct, $incorrectCount incorrect, $unattemptedCount unattempted',
    );

    if (strongTopics.isNotEmpty) {
      recommendations.add(
        '🎯 Excellent performance in: ${strongTopics.join(', ')}',
      );
      recommendations.add(
        '💪 Maintain your strength in these topics through regular revision',
      );
    }

    if (weakTopics.isNotEmpty) {
      recommendations.add(
        '🔴 Areas needing improvement: ${weakTopics.join(', ')}',
      );

      for (var topic in weakTopics.take(3)) {
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

      recommendations.add(
        '🔄 Your weak areas have been automatically updated with these topics for focused practice',
      );
    }

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

class AccuracyValidatorService {
  static Future<Map<String, dynamic>> validateQuestionAccuracy({
    required Question question,
    required String studentId,
  }) async {
    await Future.delayed(const Duration(seconds: 2));

    final analysis = await _analyzeQuestionAccuracy(question);

    return {
      'accuracy_score': analysis['overall_score'],
      'confidence_level': analysis['confidence_level'],
      'validation_timestamp': DateTime.now(),
      'question_id': question.id,
      'logical_accuracy': analysis['logical_accuracy'],
      'grammatical_accuracy': analysis['grammatical_accuracy'],
      'mathematical_consistency': analysis['mathematical_consistency'],
      'issues_found': analysis['issues'],
      'recommendations': analysis['recommendations'],
    };
  }

  static Future<Map<String, dynamic>> _analyzeQuestionAccuracy(
      Question question) async {
    final issues = <String>[];
    final recommendations = <String>[];

    double logicalScore = 1.0;
    double grammaticalScore = 1.0;
    double mathematicalScore = 1.0;

    logicalScore =
        await _checkLogicalConsistency(question, issues, recommendations);

    grammaticalScore =
        await _checkGrammaticalAccuracy(question, issues, recommendations);

    mathematicalScore =
        await _checkMathematicalConsistency(question, issues, recommendations);

    await _checkOptionValidity(question, issues, recommendations);

    final overallScore =
        (logicalScore * 0.4 + grammaticalScore * 0.2 + mathematicalScore * 0.4);

    return {
      'overall_score': overallScore,
      'confidence_level': _getConfidenceLevel(overallScore),
      'logical_accuracy': logicalScore,
      'grammatical_accuracy': grammaticalScore,
      'mathematical_consistency': mathematicalScore,
      'issues': issues,
      'recommendations': recommendations,
    };
  }

  static Future<double> _checkLogicalConsistency(Question question,
      List<String> issues, List<String> recommendations) async {
    double score = 1.0;

    if (_hasContradictions(question.questionText)) {
      issues.add('Logical contradiction detected in question statement');
      score -= 0.3;
    }

    if (!_isQuestionCoherent(question.questionText)) {
      issues.add('Question lacks coherence or clear objective');
      score -= 0.2;
    }

    if (_isAmbiguous(question.questionText)) {
      issues.add('Question contains ambiguous phrasing');
      score -= 0.2;
      recommendations.add('Reformulate question to remove ambiguity');
    }

    return score.clamp(0.0, 1.0);
  }

  static Future<double> _checkGrammaticalAccuracy(Question question,
      List<String> issues, List<String> recommendations) async {
    double score = 1.0;

    final grammarIssues = _checkGrammar(question.questionText);
    if (grammarIssues.isNotEmpty) {
      issues.addAll(grammarIssues);
      score -= grammarIssues.length * 0.1;
    }

    for (var option in question.options) {
      final optionGrammarIssues = _checkGrammar(option);
      if (optionGrammarIssues.isNotEmpty) {
        issues.add('Grammatical issues in options');
        score -= 0.1;
        break;
      }
    }

    final spellingIssues = _checkSpelling(question.questionText);
    if (spellingIssues.isNotEmpty) {
      issues.add('Spelling errors detected');
      score -= 0.1;
      recommendations.add('Review and correct spelling mistakes');
    }

    return score.clamp(0.0, 1.0);
  }

  static Future<double> _checkMathematicalConsistency(Question question,
      List<String> issues, List<String> recommendations) async {
    double score = 1.0;

    if (_hasInconsistentNotation(question.questionText)) {
      issues.add('Inconsistent mathematical notation');
      score -= 0.2;
    }

    if (_hasMathematicalErrors(question.questionText)) {
      issues.add('Potential mathematical errors detected');
      score -= 0.3;
    }

    if (!_isAnswerPlausible(question)) {
      issues.add('Correct answer may not be mathematically plausible');
      score -= 0.2;
      recommendations.add('Verify the correctness of the answer');
    }

    return score.clamp(0.0, 1.0);
  }

  static Future<void> _checkOptionValidity(Question question,
      List<String> issues, List<String> recommendations) async {
    if (!_areOptionsDistinct(question.options)) {
      issues.add('Options are not sufficiently distinct');
      recommendations.add('Ensure all options are clearly different');
    }

    if (!_areDistractorsPlausible(question)) {
      issues.add('Incorrect options may not be good distractors');
      recommendations.add('Review distractor options for plausibility');
    }
  }

  static bool _hasContradictions(String text) {
    final contradictionPatterns = [
      RegExp(r'\b(?:always|never)\b.*\b(?:sometimes|maybe)\b',
          caseSensitive: false),
      RegExp(r'\ball\b.*\bsome\b', caseSensitive: false),
      RegExp(r'\bnone\b.*\bsome\b', caseSensitive: false),
    ];

    return contradictionPatterns.any((pattern) => pattern.hasMatch(text));
  }

  static bool _isQuestionCoherent(String text) {
    final questionWords = [
      'what',
      'which',
      'when',
      'where',
      'why',
      'how',
      'calculate',
      'find',
      'determine'
    ];
    final hasQuestionWord =
        questionWords.any((word) => text.toLowerCase().contains(word));
    final hasQuestionMark = text.contains('?');

    return hasQuestionWord || hasQuestionMark;
  }

  static bool _isAmbiguous(String text) {
    final ambiguousPatterns = [
      RegExp(r'\b(may|might|could|possibly)\b', caseSensitive: false),
      RegExp(r'\b(some|several|a few)\b', caseSensitive: false),
      RegExp(r'\b(etc|and so on)\b', caseSensitive: false),
    ];

    return ambiguousPatterns.any((pattern) => pattern.hasMatch(text));
  }

  static List<String> _checkGrammar(String text) {
    final issues = <String>[];

    if (text.contains(' a ') && text.contains('[aeiou]')) {}

    if (text.split(' ').length > 50) {
      issues.add('Sentence may be too long and complex');
    }

    return issues;
  }

  static List<String> _checkSpelling(String text) {
    final commonMisspellings = {
      'recieve': 'receive',
      'seperate': 'separate',
      'definately': 'definitely',
      'occured': 'occurred',
    };

    final issues = <String>[];
    final words = text.toLowerCase().split(RegExp(r'\W+'));

    for (var word in words) {
      if (commonMisspellings.containsKey(word)) {
        issues.add(
            'Possible misspelling: "$word" should be "${commonMisspellings[word]}"');
      }
    }

    return issues;
  }

  static bool _hasInconsistentNotation(String text) {
    final hasMixedNotation = text.contains('×') && text.contains('*');
    final hasInconsistentVariables = RegExp(r'[a-z][0-9]').hasMatch(text);

    return hasMixedNotation || hasInconsistentVariables;
  }

  static bool _hasMathematicalErrors(String text) {
    final errors = [
      RegExp(r'\b0\s*\/\s*0\b'),
      RegExp(r'\b[0-9]+\s*\/\s*0\b'),
      RegExp(r'\b∞\s*[+\-*/]\s*∞\b'),
    ];

    return errors.any((error) => error.hasMatch(text));
  }

  static bool _isAnswerPlausible(Question question) {
    if (question.options.isNotEmpty) {
      final correctAnswer = question.correctAnswerIndex;
      if (correctAnswer >= 0 && correctAnswer < question.options.length) {
        final answer = question.options[correctAnswer];
        return !answer.toLowerCase().contains('undefined') &&
            !answer.toLowerCase().contains('infinity') &&
            !answer.toLowerCase().contains('error');
      }
    }
    return true;
  }

  static bool _areOptionsDistinct(List<String> options) {
    final distinctOptions = options.toSet();
    if (distinctOptions.length != options.length) {
      return false;
    }

    for (var i = 0; i < options.length; i++) {
      for (var j = i + 1; j < options.length; j++) {
        if (_areStringsSimilar(options[i], options[j])) {
          return false;
        }
      }
    }

    return true;
  }

  static bool _areStringsSimilar(String a, String b) {
    if (a == b) return true;

    final cleanA = a.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
    final cleanB = b.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();

    return cleanA == cleanB;
  }

  static bool _areDistractorsPlausible(Question question) {
    if (question.options.length <= 1) return true;

    final correctIndex = question.correctAnswerIndex;
    final distractors = question.options
        .asMap()
        .entries
        .where((entry) => entry.key != correctIndex)
        .map((entry) => entry.value)
        .toList();

    for (var distractor in distractors) {
      if (distractor.toLowerCase().contains('none of') ||
          distractor.toLowerCase().contains('all of') ||
          distractor.toLowerCase().contains('undefined')) {
        return false;
      }
    }

    return true;
  }

  static String _getConfidenceLevel(double score) {
    if (score >= 0.9) return 'Very High';
    if (score >= 0.8) return 'High';
    if (score >= 0.7) return 'Medium';
    if (score >= 0.6) return 'Low';
    return 'Very Low';
  }
}

class AIJeeMockTestApp extends StatelessWidget {
  const AIJeeMockTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI JEE Mock Test',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: Consumer<AuthService>(
        builder: (context, authService, child) {
          if (authService.isAuthenticated) {
            final currentStudent = authService.currentStudent;
            if (currentStudent != null && currentStudent.weakAreas.isEmpty) {
              return const WeakAreaSetupScreen();
            }
            return const DashboardScreen();
          }
          return const WelcomeScreen();
        },
      ),
    );
  }
}

class AIAnalysisScreen extends StatefulWidget {
  const AIAnalysisScreen({super.key});

  @override
  State<AIAnalysisScreen> createState() => _AIAnalysisScreenState();
}

class _AIAnalysisScreenState extends State<AIAnalysisScreen> {
  int _selectedTab = 1;
  Map<String, Map<String, dynamic>> _completeTestDetails = {};

  @override
  void initState() {
    super.initState();
    _loadCompleteTestDetails();
  }

  Future<void> _loadCompleteTestDetails() async {
    final testService = Provider.of<AITestService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);

    for (var result in testService.testResults) {
      try {
        final details = await testService.getCompleteTestDetails(
            authService.currentStudent!.studentId, result.testId);

        if (details != null && mounted) {
          final safeDetails = _ensureStringKeyMap(details);
          setState(() {
            _completeTestDetails[result.testId] = safeDetails;
          });

          final questions = safeDetails['questions'] as List<dynamic>? ?? [];
          print(
              '✅ Loaded ${questions.length} questions for test ${result.testId}');
        }
      } catch (e) {
        print('Error loading test details for ${result.testId}: $e');
      }
    }
  }

  Map<String, dynamic> _ensureStringKeyMap(Map<dynamic, dynamic> map) {
    final result = <String, dynamic>{};
    map.forEach((key, value) {
      result[key.toString()] = value;
    });
    return result;
  }

  void _showQuestionsDialog(
      List<dynamic> questions,
      Map<String, dynamic> submittedAnswers,
      Map<String, dynamic> numericalAnswers,
      Map<String, dynamic> questionCorrectness) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Test Questions & Answers'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: questions.length,
            itemBuilder: (context, index) {
              final question = questions[index] as Map<String, dynamic>;
              final questionId = question['id'] ?? index.toString();
              final isCorrect = questionCorrectness[questionId] == true;
              final userAnswerIndex = submittedAnswers[questionId];
              final numericalAnswer = numericalAnswers[questionId];
              final isNumerical = question['isNumerical'] == true;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: isCorrect ? Colors.green : Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Q${index + 1}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${question['subject']} • ${question['topic']}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Chip(
                            label: Text(
                              '${question['marks']} marks',
                              style: const TextStyle(fontSize: 10),
                            ),
                            backgroundColor: Colors.blue,
                            labelStyle: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        question['questionText'] ?? 'No question text',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      if (isNumerical)
                        _buildNumericalAnswerSection(
                            numericalAnswer, question['correctAnswerIndex'])
                      else
                        _buildOptionsSection(
                            question, userAnswerIndex, isCorrect),
                      if (question['solution'] != null &&
                          question['solution'].isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 12),
                            const Text(
                              'Solution:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            Text(
                              question['solution'],
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildNumericalAnswerSection(
      String? userAnswer, dynamic correctAnswer) {
    final isCorrect = userAnswer == correctAnswer?.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Numerical Answer:',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isCorrect ? Colors.green[50] : Colors.red[50],
            border: Border.all(
              color: isCorrect ? Colors.green : Colors.red,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                color: isCorrect ? Colors.green : Colors.red,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Your answer: ${userAnswer ?? 'Not attempted'}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isCorrect ? Colors.green[700] : Colors.red[700],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green[50],
            border: Border.all(color: Colors.green),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 16),
              const SizedBox(width: 8),
              Text(
                'Correct answer: $correctAnswer',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 58, 153, 63),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOptionsSection(
      Map<String, dynamic> question, dynamic userAnswerIndex, bool isCorrect) {
    final options = question['options'] as List<dynamic>? ?? [];
    final correctAnswerIndex = question['correctAnswerIndex'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Options:',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...options.asMap().entries.map((entry) {
          final optionIndex = entry.key;
          final option = entry.value;
          final isCorrectOption = optionIndex == correctAnswerIndex;
          final isUserAnswer = userAnswerIndex == optionIndex;

          return Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isCorrectOption
                  ? Colors.green[50]
                  : isUserAnswer
                      ? Colors.red[50]
                      : Colors.grey[50],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isCorrectOption
                    ? Colors.green
                    : isUserAnswer
                        ? Colors.red
                        : Colors.grey[300]!,
                width: isCorrectOption || isUserAnswer ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Text(
                  '${String.fromCharCode(65 + optionIndex)}. ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isCorrectOption
                        ? Colors.green[800]
                        : isUserAnswer
                            ? Colors.red[800]
                            : Colors.grey[700],
                  ),
                ),
                Expanded(
                  child: Text(
                    option,
                    style: TextStyle(
                      fontSize: 14,
                      color: isCorrectOption
                          ? Colors.green[800]
                          : isUserAnswer
                              ? Colors.red[800]
                              : Colors.grey[700],
                    ),
                  ),
                ),
                if (isCorrectOption)
                  Icon(Icons.check, size: 16, color: Colors.green[800]),
                if (isUserAnswer && !isCorrectOption)
                  Icon(Icons.close, size: 16, color: Colors.red[800]),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildAccuracySection(Map<String, dynamic> completeDetails) {
    final accuracyResults =
        completeDetails['accuracy_results'] as Map<String, dynamic>? ?? {};
    final questions = completeDetails['questions'] as List<dynamic>? ?? [];

    if (accuracyResults.isEmpty) {
      return const ListTile(
        leading: Icon(Icons.help_outline, color: Colors.grey),
        title: Text('Accuracy analysis not available'),
        subtitle: Text('Complete more tests to see accuracy insights'),
      );
    }

    final accuracyScores = <double>[];
    accuracyResults.forEach((key, value) {
      if (value is Map && value['accuracy_score'] != null) {
        accuracyScores.add((value['accuracy_score'] as num).toDouble());
      }
    });

    final overallAccuracy = accuracyScores.isNotEmpty
        ? accuracyScores.reduce((a, b) => a + b) / accuracyScores.length
        : 0.0;

    return ExpansionTile(
      leading: const Icon(Icons.verified, color: Colors.green),
      title: const Text('Question Accuracy Analysis'),
      subtitle: Text(
          'Overall: ${(overallAccuracy * 100).toStringAsFixed(1)}% accurate'),
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildAccuracyMetric(
                          'High',
                          accuracyScores.where((s) => s >= 0.8).length,
                          Colors.green),
                      _buildAccuracyMetric(
                          'Medium',
                          accuracyScores
                              .where((s) => s >= 0.6 && s < 0.8)
                              .length,
                          Colors.orange),
                      _buildAccuracyMetric(
                          'Low',
                          accuracyScores.where((s) => s < 0.6).length,
                          Colors.red),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Question-wise Accuracy:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...accuracyResults.entries.take(10).map((entry) {
                final accuracyData =
                    entry.value as Map<dynamic, dynamic>? ?? {};
                final accuracyScore =
                    (accuracyData['accuracy_score'] ?? 0.0) as double;
                final confidenceLevel =
                    accuracyData['confidence_level'] ?? 'Unknown';

                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    backgroundColor: _getAccuracyColor(accuracyScore),
                    child: Text(
                      '${(accuracyScore * 100).toInt()}',
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
                  title: Text('Question ${entry.key}'),
                  subtitle: Text('Confidence: $confidenceLevel'),
                  trailing: Icon(
                    _getAccuracyIcon(accuracyScore),
                    color: _getAccuracyColor(accuracyScore),
                  ),
                );
              }).toList(),
              if (accuracyResults.length > 10)
                Text(
                  '... and ${accuracyResults.length - 10} more questions',
                  style: const TextStyle(
                      fontStyle: FontStyle.italic, color: Colors.grey),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccuracyMetric(String level, int count, Color color) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color),
          ),
          child: Center(
            child: Text(
              '$count',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(level, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }

  Color _getAccuracyColor(double accuracy) {
    if (accuracy >= 0.8) return Colors.green;
    if (accuracy >= 0.6) return Colors.orange;
    return Colors.red;
  }

  IconData _getAccuracyIcon(double accuracy) {
    if (accuracy >= 0.8) return Icons.verified;
    if (accuracy >= 0.6) return Icons.warning_amber;
    return Icons.error;
  }

  @override
  Widget build(BuildContext context) {
    final testService = Provider.of<AITestService>(context);
    final authService = Provider.of<AuthService>(context);
    final student = authService.currentStudent!;

    final testResults = testService.testResults;
    final topicProficiency = student.topicProficiency;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Analysis'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Row(
              children: [
                _buildTab(0, 'Overview', Icons.dashboard),
                _buildTab(1, 'Test History', Icons.history),
              ],
            ),
          ),
          Expanded(
            child: _selectedTab == 0
                ? _buildOverviewTab(testResults, topicProficiency, student)
                : _buildTestHistoryTab(testResults, testService, authService),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String title, IconData icon) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: Material(
        color: isSelected ? Colors.green : Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedTab = index;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon,
                    size: 20, color: isSelected ? Colors.white : Colors.grey),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTestHistoryTab(List<TestResult> results,
      AITestService testService, AuthService authService) {
    if (results.isEmpty) {
      return _buildPlaceholderCard('Test History', Icons.history,
          'Complete tests to see your test history');
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildHistoryStat(
                  'Total Tests', results.length.toString(), Icons.assignment),
              _buildHistoryStat(
                  'Avg Score',
                  '${_calculateAverageScore(results).toStringAsFixed(1)}%',
                  Icons.trending_up),
              _buildHistoryStat(
                  'Best Score',
                  '${_calculateBestScore(results).toStringAsFixed(1)}%',
                  Icons.star),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) {
              final reverseIndex = results.length - 1 - index;
              if (reverseIndex < 0 || reverseIndex >= results.length) {
                return const SizedBox.shrink();
              }

              final result = results[reverseIndex];
              final testNumber = results.length - reverseIndex;

              return _buildTestResultCard(
                  result, testService, testNumber, authService);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTestResultCard(TestResult result, AITestService testService,
      int testNumber, AuthService authService) {
    final percentage = (result.score / result.totalMarks * 100);
    final hasCompleteDetails = _completeTestDetails.containsKey(result.testId);

    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 2,
      child: ExpansionTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getScoreColor(percentage).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              'T$testNumber',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _getScoreColor(percentage),
              ),
            ),
          ),
        ),
        title: Text(
          'Test $testNumber',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${result.correctAnswers}/${result.totalQuestions} Correct • ${percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            Text(
              '${_formatDate(result.submittedAt)} • ${_formatTimeTaken(result.timeTaken)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
            if (hasCompleteDetails)
              Text(
                '✓ Full details available',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        trailing: Chip(
          label: Text(
            '${percentage.toStringAsFixed(0)}%',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: _getScoreColor(percentage),
        ),
        children: [
          _buildTestDetails(result, testService, testNumber, authService),
        ],
      ),
    );
  }

  Widget _buildTestDetails(TestResult result, AITestService testService,
      int testNumber, AuthService authService) {
    final completeDetails = _completeTestDetails[result.testId];
    final hasQuestions =
        completeDetails != null && completeDetails['questions'] != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Test $testNumber Details',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildDetailChip(
                          'Test ID: ${result.testId}', Icons.fingerprint),
                      const SizedBox(width: 8),
                      _buildDetailChip(
                          'Date: ${_formatDate(result.submittedAt)}',
                          Icons.calendar_today),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSectionCard(
                  'Test Result',
                  Icons.analytics,
                  Colors.blue,
                  _buildTestResultSection(result),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSectionCard(
                  'Questions',
                  Icons.question_answer,
                  Colors.green,
                  _buildQuestionsSection(result, completeDetails, testService),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (completeDetails != null) _buildAccuracySection(completeDetails),
          if (!hasQuestions)
            Center(
              child: ElevatedButton.icon(
                onPressed: () =>
                    _loadTestDetails(result.testId, authService, testService),
                icon: const Icon(Icons.refresh),
                label: const Text('Load Complete Test Details'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
      String title, IconData icon, Color color, Widget content) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildTestResultSection(TestResult result) {
    final percentage = (result.score / result.totalMarks * 100);

    return Column(
      children: [
        _buildResultItem(
            'Score', '${result.score.toInt()}/${result.totalMarks.toInt()}'),
        _buildResultItem('Percentage', '${percentage.toStringAsFixed(1)}%'),
        _buildResultItem('Correct Answers',
            '${result.correctAnswers}/${result.totalQuestions}'),
        _buildResultItem('Time Taken', _formatTimeTaken(result.timeTaken)),
        const SizedBox(height: 8),
        const Text(
          'Subject Scores:',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        ...result.subjectWiseScores.entries.map((entry) {
          final correctInSubject = (entry.value / 4).toInt();
          return _buildResultItem(entry.key, '$correctInSubject correct');
        }).toList(),
      ],
    );
  }

  Widget _buildQuestionsSection(TestResult result,
      Map<String, dynamic>? completeDetails, AITestService testService) {
    final hasQuestions =
        completeDetails != null && completeDetails['questions'] != null;

    if (!hasQuestions) {
      return const Column(
        children: [
          Icon(Icons.hourglass_empty, size: 30, color: Colors.grey),
          SizedBox(height: 4),
          Text(
            'Details loading...',
            style: TextStyle(fontSize: 10, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    final questions = completeDetails['questions'] as List<dynamic>;
    final submittedAnswers =
        completeDetails['submittedAnswers'] as Map<String, dynamic>? ?? {};
    final numericalAnswers =
        completeDetails['numericalAnswers'] as Map<String, dynamic>? ?? {};
    final questionCorrectness =
        completeDetails['questionCorrectness'] as Map<String, dynamic>? ?? {};

    return Column(
      children: [
        Text(
          'Total: ${questions.length} questions',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: questions.asMap().entries.map((entry) {
            final index = entry.key;
            final question = entry.value as Map<String, dynamic>;
            final questionId = question['id'] ?? index.toString();
            final isCorrect = questionCorrectness[questionId] == true;

            return Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCorrect ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => _showQuestionsDialog(questions, submittedAnswers,
              numericalAnswers, questionCorrectness),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
          ),
          child: const Text(
            'View All Questions →',
            style: TextStyle(fontSize: 12, color: Colors.blue),
          ),
        ),
      ],
    );
  }

  Widget _buildResultItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailChip(String text, IconData icon) {
    return Chip(
      label: Text(
        text,
        style: const TextStyle(fontSize: 10),
      ),
      avatar: Icon(icon, size: 14),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Future<void> _loadTestDetails(
      String testId, AuthService authService, AITestService testService) async {
    try {
      final details = await testService.getCompleteTestDetails(
          authService.currentStudent!.studentId, testId);
      if (details != null && mounted) {
        setState(() {
          _completeTestDetails[testId] = details;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading test details: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildHistoryStat(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.blue),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewTab(List<TestResult> results,
      Map<String, double> proficiency, Student student) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverallPerformanceCard(results),
          const SizedBox(height: 20),
          _buildSubjectPerformanceChart(results),
          const SizedBox(height: 20),
          _buildTestProgressChart(results),
          const SizedBox(height: 20),
          _buildWeakAreasChart(student.weakAreas, proficiency),
        ],
      ),
    );
  }

  Widget _buildOverallPerformanceCard(List<TestResult> results) {
    if (results.isEmpty) {
      return _buildPlaceholderCard(
          'Overall Performance',
          Icons.analytics_outlined,
          'Complete tests to see overall performance');
    }

    final avgScore = _calculateAverageScore(results);
    final totalTests = results.length;
    final bestScore = _calculateBestScore(results);
    final latestScore = results.isNotEmpty
        ? (results.last.score / results.last.totalMarks * 100)
        : 0;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              'Overall Performance',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricCard('Total Tests', totalTests.toString(),
                    Icons.assignment, Colors.blue),
                _buildMetricCard('Avg Score', '${avgScore.toStringAsFixed(1)}%',
                    Icons.trending_up, Colors.green),
                _buildMetricCard(
                    'Best Score',
                    '${bestScore.toStringAsFixed(1)}%',
                    Icons.star,
                    Colors.amber),
              ],
            ),
            const SizedBox(height: 20),
            if (results.isNotEmpty) ...[
              LinearProgressIndicator(
                value: latestScore / 100,
                backgroundColor: Colors.grey[300],
                color: _getScoreColor(latestScore.toDouble()),
                minHeight: 12,
                borderRadius: BorderRadius.circular(6),
              ),
              const SizedBox(height: 10),
              Text(
                'Latest Test: ${latestScore.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _getScoreColor(latestScore.toDouble()),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
      String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 30, color: color),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildSubjectPerformanceChart(List<TestResult> results) {
    if (results.isEmpty) {
      return _buildPlaceholderCard('Subject Performance', Icons.pie_chart,
          'Complete tests to see subject-wise performance');
    }

    final subjectData = _calculateSubjectPerformance(results);
    final chartData = subjectData.entries.map((entry) {
      return PieChartSectionData(
        color: _getSubjectColor(entry.key),
        value: entry.value,
        title: '${entry.value.toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Subject-wise Performance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: chartData,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 5,
              children: subjectData.entries.map((entry) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      color: _getSubjectColor(entry.key),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      entry.key,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestProgressChart(List<TestResult> results) {
    if (results.isEmpty) {
      return _buildPlaceholderCard('Test Progress', Icons.trending_up,
          'Complete tests to see progress over time');
    }

    final spots = results.asMap().entries.map((entry) {
      final index = entry.key;
      final result = entry.value;
      final percentage = (result.score / result.totalMarks * 100);
      return FlSpot(index.toDouble(), percentage);
    }).toList();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Test Progress Over Time',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < results.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text('T${value.toInt() + 1}'),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}%');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 4,
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeakAreasChart(
      List<String> weakAreas, Map<String, double> proficiency) {
    if (weakAreas.isEmpty) {
      return _buildPlaceholderCard(
          'Weak Areas', Icons.emoji_objects, 'No weak areas identified yet');
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weak Areas Proficiency',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Column(
              children: weakAreas.map((area) {
                final proficiencyValue = proficiency[area] ?? 0.0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              area,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          ),
                          Text(
                            '${(proficiencyValue * 100).toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _getProficiencyColor(proficiencyValue),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: proficiencyValue,
                        backgroundColor: Colors.grey[300],
                        color: _getProficiencyColor(proficiencyValue),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderCard(String title, IconData icon, String message) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Icon(icon, size: 60, color: Colors.grey),
            const SizedBox(height: 10),
            Text(
              message,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  double _calculateAverageScore(List<TestResult> results) {
    if (results.isEmpty) return 0;
    final average =
        results.map((r) => r.score / r.totalMarks).reduce((a, b) => a + b) /
            results.length;
    return average * 100;
  }

  double _calculateBestScore(List<TestResult> results) {
    if (results.isEmpty) return 0;
    return results
        .map((r) => r.score / r.totalMarks * 100)
        .reduce((a, b) => a > b ? a : b);
  }

  Map<String, double> _calculateSubjectPerformance(List<TestResult> results) {
    final subjectPerformance = <String, double>{};
    final subjectCounts = <String, int>{};

    for (var result in results) {
      result.subjectWiseScores.forEach((subject, score) {
        final percentage = (score / (result.totalMarks / 3)) * 100;
        subjectPerformance[subject] =
            (subjectPerformance[subject] ?? 0) + percentage;
        subjectCounts[subject] = (subjectCounts[subject] ?? 0) + 1;
      });
    }

    subjectPerformance.forEach((subject, total) {
      final count = subjectCounts[subject]!;
      subjectPerformance[subject] = total / count;
    });

    return subjectPerformance;
  }

  Color _getSubjectColor(String subject) {
    switch (subject) {
      case 'Mathematics':
        return Colors.purple;
      case 'Physics':
        return Colors.blue;
      case 'Chemistry':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getSubjectIcon(String subject) {
    switch (subject) {
      case 'Mathematics':
        return Icons.calculate;
      case 'Physics':
        return Icons.science;
      case 'Chemistry':
        return Icons.emoji_objects;
      default:
        return Icons.subject;
    }
  }

  Color _getScoreColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }

  Color _getProficiencyColor(double proficiency) {
    if (proficiency >= 0.8) return Colors.green;
    if (proficiency >= 0.6) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTimeTaken(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}m ${remainingSeconds}s';
  }
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _showLogin = true;

  void _toggleView() {
    setState(() {
      _showLogin = !_showLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            const Text(
              'Paper Smith AI',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Personalized tests to improve your Performance',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            if (_showLogin)
              LoginForm(onToggle: _toggleView)
            else
              RegisterForm(onToggle: _toggleView),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),

            // Google Sign-In Button
            _buildGoogleSignInButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleSignInButton() {
    return ElevatedButton(
      onPressed: _signInWithGoogle,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        minimumSize: const Size(double.infinity, 50),
        side: const BorderSide(color: Colors.grey),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.g_mobiledata, size: 24, color: Colors.red),
          const SizedBox(width: 12),
          const Text(
            'Continue with Google',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final result = await authService.signInWithGoogle();

    if (!result['success'] && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red,
        ),
      );
    } else if (result['isNewUser'] == true && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const WeakAreaSetupScreen(),
        ),
      );
    }
  }
}

class LoginForm extends StatefulWidget {
  final VoidCallback onToggle;

  const LoginForm({super.key, required this.onToggle});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final result = await authService.login(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    setState(() {
      _isLoading = false;
    });

    if (!result['success'] && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!value.contains('@')) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              return null;
            },
          ),
          const SizedBox(height: 30),
          _isLoading
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Login', style: TextStyle(fontSize: 18)),
                ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: widget.onToggle,
            child: const Text(
              "Don't have an account? Register here",
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

class RegisterForm extends StatefulWidget {
  final VoidCallback onToggle;

  const RegisterForm({super.key, required this.onToggle});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final result = await authService.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      confirmPassword: _confirmPasswordController.text.trim(),
    );

    setState(() {
      _isLoading = false;
    });

    if (!result['success'] && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!value.contains('@')) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Confirm Password',
              prefixIcon: Icon(Icons.lock_outline),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: 30),
          _isLoading
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Register', style: TextStyle(fontSize: 18)),
                ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: widget.onToggle,
            child: const Text(
              'Already have an account? Login here',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}

class WeakAreaSetupScreen extends StatefulWidget {
  const WeakAreaSetupScreen({super.key});

  @override
  State<WeakAreaSetupScreen> createState() => _WeakAreaSetupScreenState();
}

class _WeakAreaSetupScreenState extends State<WeakAreaSetupScreen> {
  final Map<String, List<String>> _topicsBySubject = {
    'Mathematics': [
      'Sets, Relations and Functions',
      'Complex Numbers and Quadratic Equations',
      'Matrices and Determinants',
      'Permutations and Combinations',
      'Binomial Theorem and Its Simple Applications',
      'Sequence and Series',
      'Limit, Continuity and Differentiability',
      'Integral Calculus',
      'Differential Equations',
      'Coordinate Geometry',
      'Three Dimensional Geometry',
      'Vector Algebra',
      'Statistics and Probability',
      'Trigonometry',
    ],
    'Physics': [
      'Units and Measurements',
      'Kinematics',
      'Laws of Motion',
      'Work, Energy and Power',
      'Rotational Motion',
      'Gravitation',
      'Properties of Solids and Liquids',
      'Thermodynamics',
      'Kinetic Theory of Gases',
      'Oscillations and Waves',
      'Electrostatics',
      'Current Electricity',
      'Magnetic Effects of Current and Magnetism',
      'Electromagnetic Induction and Alternating Currents',
      'Electromagnetic Waves',
      'Optics',
      'Dual Nature of Matter and Radiation',
      'Atoms and Nuclei',
      'Electronic Devices',
      'Experimental Skills',
    ],
    'Chemistry': [
      'Some Basic Concepts in Chemistry',
      'Atomic Structure',
      'Chemical Bonding and Molecular Structure',
      'Chemical Thermodynamics',
      'Solutions',
      'Equilibrium',
      'Redox Reactions and Electrochemistry',
      'Chemical Kinetics',
      'Classification of Elements and Periodicity in Properties',
      'p-Block Elements',
      'd- and f-Block Elements',
      'Coordination Compounds',
      'Purification and Characterisation of Organic Compounds',
      'Some Basic Principles of Organic Chemistry',
      'Hydrocarbons',
      'Organic Compounds Containing Halogens',
      'Organic Compounds Containing Oxygen',
      'Organic Compounds Containing Nitrogen',
      'Biomolecules',
      'Principles Related to Practical Chemistry',
    ],
  };

  final List<String> _selectedWeakAreas = [];
  String _performanceLevel = 'Beginner';

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Your Profile'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome to AI JEE Mock Test!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Let\'s personalize your learning experience by setting up your weak areas and performance level.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            const Text(
              'Select your weak areas:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Select topics you find challenging. We\'ll focus on these areas to help you improve.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: _topicsBySubject.entries.map((subjectEntry) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ExpansionTile(
                      leading: Icon(
                        _getSubjectIcon(subjectEntry.key),
                        color: _getSubjectColor(subjectEntry.key),
                      ),
                      title: Text(
                        subjectEntry.key,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '${subjectEntry.value.length} topics',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: subjectEntry.value.map((topic) {
                              final isSelected =
                                  _selectedWeakAreas.contains(topic);
                              return FilterChip(
                                label: Text(topic),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedWeakAreas.add(topic);
                                    } else {
                                      _selectedWeakAreas.remove(topic);
                                    }
                                  });
                                },
                                selectedColor:
                                    _getSubjectColor(subjectEntry.key)
                                        .withOpacity(0.3),
                                checkmarkColor:
                                    _getSubjectColor(subjectEntry.key),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select your performance level:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            DropdownButton<String>(
              value: _performanceLevel,
              onChanged: (String? newValue) {
                setState(() {
                  _performanceLevel = newValue!;
                });
              },
              items: <String>['Beginner', 'Intermediate', 'Advanced']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _selectedWeakAreas.isEmpty
                  ? null
                  : () {
                      authService.updateWeakAreas(_selectedWeakAreas);
                      authService.updatePerformanceLevel(_performanceLevel);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Profile setup completed!'),
                          backgroundColor: Colors.green,
                        ),
                      );

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DashboardScreen(),
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                'Complete Setup & Start Learning',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getSubjectIcon(String subject) {
    switch (subject) {
      case 'Mathematics':
        return Icons.calculate;
      case 'Physics':
        return Icons.science;
      case 'Chemistry':
        return Icons.emoji_objects;
      default:
        return Icons.subject;
    }
  }

  Color _getSubjectColor(String subject) {
    switch (subject) {
      case 'Mathematics':
        return Colors.purple;
      case 'Physics':
        return Colors.blue;
      case 'Chemistry':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final testService = Provider.of<AITestService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paper Smith - AI'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.googleSignOut();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${authService.currentStudent?.name}!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Student ID: ${authService.currentStudent?.studentId}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 5),
            Text(
              'Performance Level: ${authService.currentStudent?.performanceLevel}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 5),
            Text(
              'Tests Completed: ${authService.currentStudent?.testsGiven ?? 0}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            if (authService.currentStudent?.weakAreas.isNotEmpty ?? false)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Focus Areas:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: authService.currentStudent!.weakAreas.map((area) {
                      return Chip(
                        label: Text(area),
                        backgroundColor: Colors.orange[100],
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            Expanded(
              child: GridView(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 1.5,
                ),
                children: [
                  DashboardCard(
                    title: 'AI Personalized Test',
                    icon: Icons.auto_awesome,
                    color: Colors.purple,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AITestConfigScreen(),
                        ),
                      );
                    },
                  ),
                  DashboardCard(
                    title: 'Weak Area Focus Test',
                    icon: Icons.warning,
                    color: Colors.orange,
                    onTap: () async {
                      final student = authService.currentStudent!;
                      if (student.weakAreas.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'No weak areas identified. Please update your weak areas first.'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      try {
                        final test =
                            await testService.generateWeakAreaFocusedTest(
                          student: student,
                          numberOfQuestions: 10,
                        );

                        if (context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TestScreen(test: test),
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e.toString()),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  ),
                  DashboardCard(
                    title: 'View Analysis',
                    icon: Icons.analytics,
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AIAnalysisScreen(),
                        ),
                      );
                    },
                  ),
                  DashboardCard(
                    title: 'Update Weak Areas',
                    icon: Icons.edit,
                    color: Colors.red,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WeakAreaUpdateScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const DashboardCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TestScreen extends StatefulWidget {
  final Test test;

  const TestScreen({super.key, required this.test});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final Map<String, int> _answers = {};
  final Map<String, String> _numericalAnswers = {};
  int _currentQuestionIndex = 0;
  late DateTime _endTime;
  late DateTime _startTime;
  Duration _timeLeft = Duration.zero;
  Timer? _timer;
  List<Question> _orderedQuestions = [];
  bool _showSubjectOrderScreen = true;
  List<String> _selectedSubjectOrder = [];
  late PageController _pageController;
  String _currentNumericalInput = '';
  bool _showNumericalPad = false;

  @override
  void initState() {
    super.initState();
    _initializeTest();
    _pageController = PageController();
  }

  void _initializeTest() {
    final subjects =
        widget.test.questions.map((q) => q.subject).toSet().toList();
    _selectedSubjectOrder = List.from(subjects);
    _orderedQuestions = List.from(widget.test.questions);
  }

  bool _isNumericalQuestion(Question question) {
    return question.options.isEmpty ||
        question.options.length == 1 && question.options[0].isEmpty;
  }

  Widget _buildNumericalPad() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Text(
                  'Answer:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _currentNumericalInput.isEmpty
                        ? 'Enter answer'
                        : _currentNumericalInput,
                    style: TextStyle(
                      fontSize: 14,
                      color: _currentNumericalInput.isEmpty
                          ? Colors.grey
                          : Colors.black,
                    ),
                  ),
                ),
                if (_currentNumericalInput.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.backspace, color: Colors.red, size: 18),
                    onPressed: _backspace,
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(minWidth: 30),
                  ),
              ],
            ),
          ),
          SizedBox(height: 12),
          Container(
            width: 200,
            height: 200,
            child: GridView.count(
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              crossAxisCount: 3,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 1.0,
              children: [
                '1',
                '2',
                '3',
                '4',
                '5',
                '6',
                '7',
                '8',
                '9',
                '.',
                '0',
                '⌫',
              ].map((key) {
                return GestureDetector(
                  onTap: () => _handleKeyPress(key),
                  child: Container(
                    decoration: BoxDecoration(
                      color: key == '⌫' ? Colors.red[100] : Colors.white,
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        key,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: key == '⌫' ? Colors.red : Colors.black,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: OutlinedButton(
                    onPressed: _clearInput,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey,
                      side: BorderSide(color: Colors.grey),
                      padding: EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: Text(
                      'Clear',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: ElevatedButton(
                    onPressed: _currentNumericalInput.isNotEmpty
                        ? _saveNumericalAnswer
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: Text(
                      'Save',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleKeyPress(String key) {
    setState(() {
      if (key == '⌫') {
        _backspace();
      } else if (key == '.' && !_currentNumericalInput.contains('.')) {
        _currentNumericalInput += key;
      } else if (key != '.') {
        _currentNumericalInput += key;
      }
    });
  }

  void _backspace() {
    setState(() {
      if (_currentNumericalInput.isNotEmpty) {
        _currentNumericalInput = _currentNumericalInput.substring(
            0, _currentNumericalInput.length - 1);
      }
    });
  }

  void _clearInput() {
    setState(() {
      _currentNumericalInput = '';
    });
  }

  void _saveNumericalAnswer() {
    final currentQuestion = _orderedQuestions[_currentQuestionIndex];
    setState(() {
      _numericalAnswers[currentQuestion.id] = _currentNumericalInput;
      _showNumericalPad = false;
    });
  }

  void _startTestWithOrder(List<String> subjectOrder) {
    setState(() {
      _selectedSubjectOrder = subjectOrder;
      _showSubjectOrderScreen = false;
      _orderedQuestions = _orderQuestionsBySubject(subjectOrder);
    });

    _startTime = DateTime.now();
    _endTime = DateTime.now().add(Duration(minutes: widget.test.duration));
    _timeLeft = _endTime.difference(DateTime.now());

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeLeft = _endTime.difference(DateTime.now());
        if (_timeLeft.isNegative) {
          _timeLeft = Duration.zero;
          _timer?.cancel();
          _submitTest();
        }
      });
    });
  }

  List<Question> _orderQuestionsBySubject(List<String> subjectOrder) {
    final orderedQuestions = <Question>[];
    for (final subject in subjectOrder) {
      final subjectQuestions =
          widget.test.questions.where((q) => q.subject == subject).toList();
      orderedQuestions.addAll(subjectQuestions);
    }
    return orderedQuestions;
  }

  String _getCurrentSubject() {
    if (_orderedQuestions.isEmpty ||
        _currentQuestionIndex >= _orderedQuestions.length) {
      return '';
    }
    return _orderedQuestions[_currentQuestionIndex].subject;
  }

  List<String> _getRemainingSubjects() {
    if (_orderedQuestions.isEmpty) return [];
    final currentSubject = _getCurrentSubject();
    final currentIndex = _selectedSubjectOrder.indexOf(currentSubject);
    if (currentIndex == -1 ||
        currentIndex >= _selectedSubjectOrder.length - 1) {
      return [];
    }
    return _selectedSubjectOrder.sublist(currentIndex + 1);
  }

  void _submitTest() async {
    _timer?.cancel();
    final timeTaken = DateTime.now().difference(_startTime).inSeconds;

    final authService = Provider.of<AuthService>(context, listen: false);
    final testService = Provider.of<AITestService>(context, listen: false);

    final Map<String, int> allAnswers = Map.from(_answers);

    final result = await testService.analyzePerformanceWithAI(
      authService.currentStudent!.studentId,
      widget.test.testId,
      allAnswers,
      timeTaken,
      context,
      numericalAnswers: _numericalAnswers,
    );

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ResultsScreen(result: result)),
      );
    }
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _orderedQuestions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _showNumericalPad = false;
        _currentNumericalInput = '';
      });
      _pageController.animateToPage(
        _currentQuestionIndex,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
        _showNumericalPad = false;
        _currentNumericalInput = '';
      });
      _pageController.animateToPage(
        _currentQuestionIndex,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _jumpToQuestion(int index) {
    setState(() {
      _currentQuestionIndex = index;
      _showNumericalPad = false;
      _currentNumericalInput = '';
    });
    _pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _jumpToSubject(String subject) {
    final subjectStartIndex =
        _orderedQuestions.indexWhere((q) => q.subject == subject);
    if (subjectStartIndex != -1) {
      setState(() {
        _currentQuestionIndex = subjectStartIndex;
        _showNumericalPad = false;
        _currentNumericalInput = '';
      });
      _pageController.animateToPage(
        subjectStartIndex,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  Widget _buildQuestionNavigationPanel() {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          Text(
            'Questions',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_orderedQuestions.length, (index) {
              final question = _orderedQuestions[index];
              final isAnswered = _answers.containsKey(question.id) ||
                  _numericalAnswers.containsKey(question.id);
              final isCurrent = index == _currentQuestionIndex;

              return GestureDetector(
                onTap: () => _jumpToQuestion(index),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? Colors.blue
                        : isAnswered
                            ? Colors.green
                            : Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isCurrent ? Colors.blue : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: isCurrent || isAnswered
                            ? Colors.white
                            : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectProgressIndicator() {
    final currentSubject = _getCurrentSubject();
    final subjectCounts = <String, int>{};
    final subjectProgress = <String, int>{};

    for (var question in _orderedQuestions) {
      subjectCounts[question.subject] =
          (subjectCounts[question.subject] ?? 0) + 1;
    }

    for (var i = 0; i <= _currentQuestionIndex; i++) {
      final subject = _orderedQuestions[i].subject;
      subjectProgress[subject] = (subjectProgress[subject] ?? 0) + 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Subject Progress:',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Row(
          children: _selectedSubjectOrder.map((subject) {
            final total = subjectCounts[subject] ?? 0;
            final completed = subjectProgress[subject] ?? 0;
            final isCurrent = subject == currentSubject;
            final isCompleted = _selectedSubjectOrder.indexOf(subject) <
                _selectedSubjectOrder.indexOf(currentSubject);

            return Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 2),
                height: 6,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.green
                      : isCurrent
                          ? Colors.blue
                          : Colors.grey[300],
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Tooltip(
                  message: '$subject: $completed/$total completed',
                  child: Container(),
                ),
              ),
            );
          }).toList(),
        ),
        SizedBox(height: 5),
        Text(
          'Current: $currentSubject',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Color _getSubjectColor(String subject) {
    switch (subject) {
      case 'Mathematics':
        return Colors.purple;
      case 'Physics':
        return Colors.blue;
      case 'Chemistry':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildSubjectOrderScreen() {
    final subjects =
        widget.test.questions.map((q) => q.subject).toSet().toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Subject Order'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select the order of Subjects:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            const Text(
              'Drag and drop to reorder the subjects. The test will start with the first subject.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            SizedBox(height: 30),
            Expanded(
              child: ReorderableListView(
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (oldIndex < newIndex) {
                      newIndex -= 1;
                    }
                    final item = _selectedSubjectOrder.removeAt(oldIndex);
                    _selectedSubjectOrder.insert(newIndex, item);
                  });
                },
                children: _selectedSubjectOrder.map((subject) {
                  return Card(
                    key: ValueKey(subject),
                    elevation: 2,
                    child: ListTile(
                      leading: Icon(
                        Icons.drag_handle,
                        color: Colors.grey[600],
                      ),
                      title: Text(
                        subject,
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        '${widget.test.questions.where((q) => q.subject == subject).length} questions',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      trailing: Chip(
                        label: Text(
                          '${_selectedSubjectOrder.indexOf(subject) + 1}',
                          style: TextStyle(color: Colors.white),
                        ),
                        backgroundColor: _getSubjectColor(subject),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _startTestWithOrder(_selectedSubjectOrder),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50),
              ),
              child: const Text(
                'Start Test',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showSubjectOrderScreen && widget.test.questions.length > 1) {
      return _buildSubjectOrderScreen();
    } else if (_showSubjectOrderScreen) {
      _startTestWithOrder(_selectedSubjectOrder);
    }

    if (_orderedQuestions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('No questions available')),
      );
    }

    final currentQuestion = _orderedQuestions[_currentQuestionIndex];
    final remainingSubjects = _getRemainingSubjects();
    final isNumerical = _isNumericalQuestion(currentQuestion);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI JEE Mock Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (remainingSubjects.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: _jumpToSubject,
              itemBuilder: (context) => remainingSubjects.map((subject) {
                return PopupMenuItem<String>(
                  value: subject,
                  child: Text('Jump to $subject'),
                );
              }).toList(),
              icon: const Icon(Icons.skip_next),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: _buildSubjectProgressIndicator(),
          ),
          Card(
            color: _timeLeft.inMinutes < 5 ? Colors.red[100] : Colors.blue[50],
            margin: EdgeInsets.symmetric(horizontal: 20),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Time Left:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatDuration(_timeLeft),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _timeLeft.inMinutes < 5
                              ? Colors.red
                              : Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Question ${_currentQuestionIndex + 1}/${_orderedQuestions.length}',
                        style: TextStyle(fontSize: 16),
                      ),
                      Chip(
                        label: Text(
                          currentQuestion.subject,
                          style: TextStyle(color: Colors.white),
                        ),
                        backgroundColor:
                            _getSubjectColor(currentQuestion.subject),
                      ),
                      if (isNumerical)
                        Chip(
                          label: Text(
                            'Numerical',
                            style: TextStyle(color: Colors.white, fontSize: 10),
                          ),
                          backgroundColor: Colors.orange,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          _buildQuestionNavigationPanel(),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _orderedQuestions.length,
              onPageChanged: (index) {
                setState(() {
                  _currentQuestionIndex = index;
                  _showNumericalPad = false;
                  _currentNumericalInput = '';
                });
              },
              itemBuilder: (context, index) {
                final question = _orderedQuestions[index];
                final isNumericalQuestion = _isNumericalQuestion(question);
                final hasNumericalAnswer =
                    _numericalAnswers.containsKey(question.id);

                return SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Chip(
                            label: Text(
                              '${question.marks} marks',
                              style: TextStyle(color: Colors.white),
                            ),
                            backgroundColor: Colors.green,
                          ),
                          SizedBox(height: 15),
                          if (isNumericalQuestion)
                            Chip(
                              label: Text(
                                'Numerical Answer Type',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                              backgroundColor: Colors.orange,
                            ),
                          SizedBox(height: 15),
                          Text(
                            'Q${index + 1}: ${question.questionText}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 20),
                          if (isNumericalQuestion)
                            Column(
                              children: [
                                if (hasNumericalAnswer)
                                  Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.green[50],
                                      border: Border.all(color: Colors.green),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.check_circle,
                                            color: Colors.green, size: 16),
                                        SizedBox(width: 8),
                                        Text(
                                          'Your answer: ${_numericalAnswers[question.id]}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                SizedBox(height: 20),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _showNumericalPad = !_showNumericalPad;
                                      if (_showNumericalPad) {
                                        _currentNumericalInput =
                                            _numericalAnswers[question.id] ??
                                                '';
                                      }
                                    });
                                  },
                                  icon: Icon(hasNumericalAnswer
                                      ? Icons.edit
                                      : Icons.keyboard),
                                  label: Text(hasNumericalAnswer
                                      ? 'Edit Answer'
                                      : 'Enter Answer'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            )
                          else
                            Column(
                              children:
                                  question.options.asMap().entries.map((entry) {
                                final optionIndex = entry.key;
                                final option = entry.value;

                                return RadioListTile<int>(
                                  title: Text(option),
                                  value: optionIndex,
                                  groupValue: _answers[question.id],
                                  onChanged: (value) {
                                    setState(() {
                                      _answers[question.id] = value!;
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_showNumericalPad &&
              _isNumericalQuestion(_orderedQuestions[_currentQuestionIndex]))
            _buildNumericalPad(),
          Container(
            padding: EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed:
                      _currentQuestionIndex > 0 ? _previousQuestion : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Previous'),
                ),
                if (_currentQuestionIndex == _orderedQuestions.length - 1)
                  ElevatedButton(
                    onPressed: _submitTest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Submit Test'),
                  )
                else
                  ElevatedButton(
                    onPressed: _nextQuestion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Next'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Color _getDifficultyColor(String difficulty) {
  switch (difficulty) {
    case 'Easy':
      return Colors.green;
    case 'Medium':
      return Colors.orange;
    case 'Hard':
      return Colors.red;
    default:
      return Colors.grey;
  }
}

class AITestConfigScreen extends StatefulWidget {
  const AITestConfigScreen({super.key});

  @override
  State<AITestConfigScreen> createState() => _AITestConfigScreenState();
}

class _AITestConfigScreenState extends State<AITestConfigScreen> {
  final Map<String, List<String>> _topicsBySubject = {
    'Mathematics': [
      'Sets, Relations and Functions',
      'Complex Numbers and Quadratic Equations',
      'Matrices and Determinants',
      'Permutations and Combinations',
      'Binomial Theorem and Its Simple Applications',
      'Sequence and Series',
      'Limit, Continuity and Differentiability',
      'Integral Calculus',
      'Differential Equations',
      'Coordinate Geometry',
      'Three Dimensional Geometry',
      'Vector Algebra',
      'Statistics and Probability',
      'Trigonometry',
    ],
    'Physics': [
      'Units and Measurements',
      'Kinematics',
      'Laws of Motion',
      'Work, Energy and Power',
      'Rotational Motion',
      'Gravitation',
      'Properties of Solids and Liquids',
      'Thermodynamics',
      'Kinetic Theory of Gases',
      'Oscillations and Waves',
      'Electrostatics',
      'Current Electricity',
      'Magnetic Effects of Current and Magnetism',
      'Electromagnetic Induction and Alternating Currents',
      'Electromagnetic Waves',
      'Optics',
      'Dual Nature of Matter and Radiation',
      'Atoms and Nuclei',
      'Electronic Devices',
      'Experimental Skills',
    ],
    'Chemistry': [
      'Some Basic Concepts in Chemistry',
      'Atomic Structure',
      'Chemical Bonding and Molecular Structure',
      'Chemical Thermodynamics',
      'Solutions',
      'Equilibrium',
      'Redox Reactions and Electrochemistry',
      'Chemical Kinetics',
      'Classification of Elements and Periodicity in Properties',
      'p-Block Elements',
      'd- and f-Block Elements',
      'Coordination Compounds',
      'Purification and Characterisation of Organic Compounds',
      'Some Basic Principles of Organic Chemistry',
      'Hydrocarbons',
      'Organic Compounds Containing Halogens',
      'Organic Compounds Containing Oxygen',
      'Organic Compounds Containing Nitrogen',
      'Biomolecules',
      'Principles Related to Practical Chemistry',
    ],
  };

  final List<String> _selectedTopics = [];
  int _numberOfQuestions = 10;
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Personalized Test'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStep(0, 'Subjects'),
                _buildStep(1, 'Questions'),
                _buildStep(2, 'Review'),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: _buildCurrentStep(authService),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(int stepNumber, String title) {
    final isActive = stepNumber == _currentStep;
    final isCompleted = stepNumber < _currentStep;

    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: isActive
                ? Colors.purple
                : isCompleted
                    ? Colors.green
                    : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text(
                    '${stepNumber + 1}',
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? Colors.purple : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStep(AuthService authService) {
    switch (_currentStep) {
      case 0:
        return _buildSubjectSelectionStep();
      case 1:
        return _buildQuestionConfigurationStep();
      case 2:
        return _buildReviewStep(authService);
      default:
        return _buildSubjectSelectionStep();
    }
  }

  Widget _buildSubjectSelectionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Subjects & Topics',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        const Text(
          'Choose the topics you want to focus on',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 20),
        const Text(
          'Quick Select:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _topicsBySubject.keys.map((subject) {
            final allSelected = _topicsBySubject[subject]!
                .every((topic) => _selectedTopics.contains(topic));
            return FilterChip(
              label: Text(subject),
              selected: allSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedTopics.addAll(_topicsBySubject[subject]!);
                    _selectedTopics.toSet().toList();
                  } else {
                    _selectedTopics.removeWhere(
                        (topic) => _topicsBySubject[subject]!.contains(topic));
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 10),
        Expanded(
          child: ListView(
            children: _topicsBySubject.entries.map((subjectEntry) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ExpansionTile(
                  leading: Icon(
                    _getSubjectIcon(subjectEntry.key),
                    color: _getSubjectColor(subjectEntry.key),
                  ),
                  title: Text(
                    subjectEntry.key,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '${_getSelectedCountInSubject(subjectEntry.key)}/${subjectEntry.value.length} selected',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: subjectEntry.value.map((topic) {
                          final isSelected = _selectedTopics.contains(topic);
                          return FilterChip(
                            label: Text(
                              topic,
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected ? Colors.white : Colors.black,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedTopics.add(topic);
                                } else {
                                  _selectedTopics.remove(topic);
                                }
                              });
                            },
                            selectedColor: _getSubjectColor(subjectEntry.key),
                            checkmarkColor: Colors.white,
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),
        _buildNavigationButtons(
          onNext: _selectedTopics.isEmpty
              ? null
              : () {
                  setState(() {
                    _currentStep = 1;
                  });
                },
          showBack: false,
        ),
      ],
    );
  }

  Widget _buildQuestionConfigurationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Test Configuration',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        const Text(
          'Set the number of questions for your test',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 30),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const Text(
                  'Number of Questions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),
                Slider(
                  value: _numberOfQuestions.toDouble(),
                  min: 5,
                  max: 30,
                  divisions: 25,
                  label: '$_numberOfQuestions',
                  onChanged: (value) {
                    setState(() {
                      _numberOfQuestions = value.toInt();
                    });
                  },
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$_numberOfQuestions Questions',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('5', style: TextStyle(color: Colors.grey)),
                    Text('30', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 30),
        _buildNavigationButtons(
          onNext: () {
            setState(() {
              _currentStep = 2;
            });
          },
          onBack: () {
            setState(() {
              _currentStep = 0;
            });
          },
        ),
      ],
    );
  }

  Widget _buildReviewStep(AuthService authService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Review Your Test',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        const Text(
          'Confirm your test settings before starting',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 30),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const Icon(Icons.assignment, size: 50, color: Colors.purple),
                const SizedBox(height: 15),
                const Text(
                  'Test Summary',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                _buildSummaryItem('Total Questions', '$_numberOfQuestions'),
                const SizedBox(height: 15),
                _buildSummaryItem(
                    'Subjects Selected', _getSelectedSubjects().join(', ')),
                const SizedBox(height: 15),
                _buildSummaryItem(
                    'Topics Selected', '${_selectedTopics.length} topics'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (_selectedTopics.isNotEmpty) ...[
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selected Topics:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedTopics.take(6).map((topic) {
                      return Chip(
                        label: Text(
                          topic.length > 20
                              ? '${topic.substring(0, 20)}...'
                              : topic,
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: Colors.grey[200],
                      );
                    }).toList(),
                  ),
                  if (_selectedTopics.length > 6)
                    Text(
                      '+ ${_selectedTopics.length - 6} more topics',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
        const Spacer(),
        _buildNavigationButtons(
          onNext: () async {
            final testService =
                Provider.of<AITestService>(context, listen: false);
            final student = authService.currentStudent!;

            try {
              final test = await testService.generateAIPersonalizedTest(
                student: student,
                focusTopics: _selectedTopics,
                testType: 'Mixed Difficulty',
                numberOfQuestions: _numberOfQuestions,
              );

              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TestScreen(test: test),
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString()),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          onBack: () {
            setState(() {
              _currentStep = 1;
            });
          },
          nextText: 'Start Test',
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  List<String> _getSelectedSubjects() {
    final subjects = <String>[];
    for (final subject in _topicsBySubject.keys) {
      if (_selectedTopics
          .any((topic) => _topicsBySubject[subject]!.contains(topic))) {
        subjects.add(subject);
      }
    }
    return subjects;
  }

  Widget _buildNavigationButtons({
    VoidCallback? onNext,
    VoidCallback? onBack,
    bool showBack = true,
    String nextText = 'Next',
  }) {
    return Row(
      children: [
        if (showBack)
          Expanded(
            child: OutlinedButton(
              onPressed: onBack,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.purple,
                side: const BorderSide(color: Colors.purple),
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: const Text('Back'),
            ),
          ),
        if (showBack) const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            child: Text(nextText),
          ),
        ),
      ],
    );
  }

  int _getSelectedCountInSubject(String subject) {
    return _selectedTopics
        .where((topic) => _topicsBySubject[subject]!.contains(topic))
        .length;
  }

  IconData _getSubjectIcon(String subject) {
    switch (subject) {
      case 'Mathematics':
        return Icons.calculate;
      case 'Physics':
        return Icons.science;
      case 'Chemistry':
        return Icons.emoji_objects;
      default:
        return Icons.subject;
    }
  }

  Color _getSubjectColor(String subject) {
    switch (subject) {
      case 'Mathematics':
        return Colors.purple;
      case 'Physics':
        return Colors.blue;
      case 'Chemistry':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

class ResultsScreen extends StatelessWidget {
  final TestResult result;

  const ResultsScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final percentage = (result.score / result.totalMarks * 100);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Results'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const Text(
                        'Overall Score',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${result.score.toInt()}/${result.totalMarks.toInt()}',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${result.correctAnswers} out of ${result.totalQuestions} correct • ${percentage.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Correct Answers:'),
                                Text(
                                  '${result.correctAnswers} × 4 = ${(result.correctAnswers) * 4} marks',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Incorrect Answers:'),
                                Text(
                                  '${result.incorrectAnswers ?? 0} × 0 = 0 marks',
                                  style: const TextStyle(
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Unattempted:'),
                                Text(
                                  '${result.unattemptedAnswers ?? 0} × 0 = 0 marks',
                                  style: const TextStyle(
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: result.score / result.totalMarks,
                        backgroundColor: Colors.grey[300],
                        color: _getScoreColor(percentage),
                        minHeight: 12,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Performance Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildPerformanceMetric(
                            'Correct',
                            '${result.correctAnswers}',
                            Colors.green,
                            Icons.check_circle,
                          ),
                          _buildPerformanceMetric(
                            'Incorrect',
                            '${result.incorrectAnswers ?? 0}',
                            Colors.red,
                            Icons.cancel,
                          ),
                          _buildPerformanceMetric(
                            'Unattempted',
                            '${result.unattemptedAnswers ?? 0}',
                            Colors.orange,
                            Icons.hourglass_empty,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (result.weakTopics.isNotEmpty)
                Card(
                  elevation: 2,
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Icon(Icons.autorenew, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Weak Areas Updated Automatically',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Your focus areas have been updated with the topics below for personalized practice',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (result.weakTopics.isNotEmpty) SizedBox(height: 20),
              const Text(
                'Subject-wise Performance',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: result.subjectWiseScores.entries.map((entry) {
                      int correctInSubject = (entry.value / 4).toInt();
                      int totalInSubject = result.totalQuestions ~/ 3;
                      double subjectPercentage = totalInSubject > 0
                          ? (correctInSubject / totalInSubject) * 100
                          : 0;

                      return ListTile(
                        leading: Icon(
                          _getSubjectIcon(entry.key),
                          color: _getSubjectColor(entry.key),
                        ),
                        title: Text(entry.key),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$correctInSubject/$totalInSubject correct'),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: correctInSubject / totalInSubject,
                              backgroundColor: Colors.grey[300],
                              color: _getSubjectColor(entry.key),
                              minHeight: 4,
                            ),
                          ],
                        ),
                        trailing: Text(
                          '${subjectPercentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _getScoreColor(subjectPercentage),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Test Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Time Taken:'),
                          Text(
                            '${(result.timeTaken / 60).floor()} min ${result.timeTaken % 60} sec',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Average Time per Question:'),
                          Text(
                            '${(result.timeTaken / result.totalQuestions).toStringAsFixed(1)} sec',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Test Date:'),
                          Text(
                            '${result.submittedAt.day}/${result.submittedAt.month}/${result.submittedAt.year}',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pop(context);
        },
        child: const Icon(Icons.home),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildPerformanceMetric(
      String title, String value, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Color _getScoreColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }

  IconData _getSubjectIcon(String subject) {
    switch (subject) {
      case 'Mathematics':
        return Icons.calculate;
      case 'Physics':
        return Icons.science;
      case 'Chemistry':
        return Icons.emoji_objects;
      default:
        return Icons.subject;
    }
  }

  Color _getSubjectColor(String subject) {
    switch (subject) {
      case 'Mathematics':
        return Colors.purple;
      case 'Physics':
        return Colors.blue;
      case 'Chemistry':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

class WeakAreaUpdateScreen extends StatefulWidget {
  const WeakAreaUpdateScreen({super.key});

  @override
  State<WeakAreaUpdateScreen> createState() => _WeakAreaUpdateScreenState();
}

class _WeakAreaUpdateScreenState extends State<WeakAreaUpdateScreen> {
  final Map<String, List<String>> _topicsBySubject = {
    'Mathematics': [
      'Sets, Relations and Functions',
      'Complex Numbers and Quadratic Equations',
      'Matrices and Determinants',
      'Permutations and Combinations',
      'Binomial Theorem and Its Simple Applications',
      'Sequence and Series',
      'Limit, Continuity and Differentiability',
      'Integral Calculus',
      'Differential Equations',
      'Coordinate Geometry',
      'Three Dimensional Geometry',
      'Vector Algebra',
      'Statistics and Probability',
      'Trigonometry',
    ],
    'Physics': [
      'Units and Measurements',
      'Kinematics',
      'Laws of Motion',
      'Work, Energy and Power',
      'Rotational Motion',
      'Gravitation',
      'Properties of Solids and Liquids',
      'Thermodynamics',
      'Kinetic Theory of Gases',
      'Oscillations and Waves',
      'Electrostatics',
      'Current Electricity',
      'Magnetic Effects of Current and Magnetism',
      'Electromagnetic Induction and Alternating Currents',
      'Electromagnetic Waves',
      'Optics',
      'Dual Nature of Matter and Radiation',
      'Atoms and Nuclei',
      'Electronic Devices',
      'Experimental Skills',
    ],
    'Chemistry': [
      'Some Basic Concepts in Chemistry',
      'Atomic Structure',
      'Chemical Bonding and Molecular Structure',
      'Chemical Thermodynamics',
      'Solutions',
      'Equilibrium',
      'Redox Reactions and Electrochemistry',
      'Chemical Kinetics',
      'Classification of Elements and Periodicity in Properties',
      'p-Block Elements',
      'd- and f-Block Elements',
      'Coordination Compounds',
      'Purification and Characterisation of Organic Compounds',
      'Some Basic Principles of Organic Chemistry',
      'Hydrocarbons',
      'Organic Compounds Containing Halogens',
      'Organic Compounds Containing Oxygen',
      'Organic Compounds Containing Nitrogen',
      'Biomolecules',
      'Principles Related to Practical Chemistry',
    ],
  };

  final List<String> _selectedWeakAreas = [];

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);

    _selectedWeakAreas.clear();

    final currentWeakAreas = authService.currentStudent?.weakAreas ?? [];
    if (currentWeakAreas.isNotEmpty) {
      _selectedWeakAreas.addAll(List.from(currentWeakAreas));
      print('📥 Initialized weak areas from student: $_selectedWeakAreas');
    } else {
      print('📥 No existing weak areas found for student');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Weak Areas'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select your weak areas for personalized learning:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: _topicsBySubject.entries.map((subjectEntry) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ExpansionTile(
                      leading: Icon(
                        _getSubjectIcon(subjectEntry.key),
                        color: _getSubjectColor(subjectEntry.key),
                      ),
                      title: Text(
                        subjectEntry.key,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '${_getSelectedCountInSubject(subjectEntry.key)}/${subjectEntry.value.length} selected',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: subjectEntry.value.map((topic) {
                              final isSelected =
                                  _selectedWeakAreas.contains(topic);
                              return Card(
                                child: ListTile(
                                  title: Text(topic),
                                  trailing: Icon(
                                    isSelected
                                        ? Icons.check_circle
                                        : Icons.radio_button_unchecked,
                                    color:
                                        isSelected ? Colors.green : Colors.grey,
                                  ),
                                  onTap: () {
                                    setState(() {
                                      if (isSelected) {
                                        _selectedWeakAreas.remove(topic);
                                      } else {
                                        _selectedWeakAreas.add(topic);
                                      }
                                    });
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                authService.updateWeakAreas(_selectedWeakAreas);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Weak areas updated successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                'Save Weak Areas',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getSelectedCountInSubject(String subject) {
    return _selectedWeakAreas
        .where((topic) => _topicsBySubject[subject]!.contains(topic))
        .length;
  }

  IconData _getSubjectIcon(String subject) {
    switch (subject) {
      case 'Mathematics':
        return Icons.calculate;
      case 'Physics':
        return Icons.science;
      case 'Chemistry':
        return Icons.emoji_objects;
      default:
        return Icons.subject;
    }
  }

  Color _getSubjectColor(String subject) {
    switch (subject) {
      case 'Mathematics':
        return Colors.purple;
      case 'Physics':
        return Colors.blue;
      case 'Chemistry':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
