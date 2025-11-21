import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models.dart';
import 'firebase_service.dart';
import 'dart:math';
import 'dart:async';

class AuthService with ChangeNotifier {
  bool _isAuthenticated = false;
  Student? _currentStudent;
  final List<Student> _students = [];
  final Random _random = Random();
  final FirebaseService _firebaseService = FirebaseService();

  // Google Sign-In
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

  // Google Sign-In method
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

      // Check if user exists
      Student? existingStudent;
      try {
        existingStudent = await _firebaseService.getStudentByEmail(email);
      } catch (e) {
        // If Firebase fails, check local
        try {
          existingStudent = _students.firstWhere(
            (student) => student.email == email,
          );
        } catch (e) {
          existingStudent = null;
        }
      }

      // If new user, create profile
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

        // Save to Firebase
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
        // Existing user
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

    // Check if email exists - FIXED
    Student? existingStudent;
    try {
      existingStudent = await _firebaseService.getStudentByEmail(email);
    } catch (e) {
      print('Error checking existing student: $e');
    }

    // Also check locally
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

    // Generate unique student ID - FIXED
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

    // Add to local list FIRST
    _students.add(newStudent);
    _currentStudent = newStudent;
    _isAuthenticated = true;

    // Then save to Firebase
    try {
      await _firebaseService.saveStudentData(newStudent);
      print('✅ Student registered successfully: $studentId');
    } catch (e) {
      print('❌ Firebase save failed: $e');
      // Remove from local list if Firebase save fails
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
    await Future.delayed(const Duration(seconds: 1));

    Student? student;

    // Try Firebase first
    try {
      student = await _firebaseService.getStudentByEmail(email);
      if (student != null && student.password == password) {
        _currentStudent = student;
        _isAuthenticated = true;
        notifyListeners();
        return {'success': true, 'message': 'Login successful!'};
      }
    } catch (e) {
      // If Firebase fails, try local
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
          weakAreas: newWeakAreas,
          performanceLevel: _currentStudent!.performanceLevel,
          topicProficiency: _currentStudent!.topicProficiency,
          createdAt: _currentStudent!.createdAt,
        );
        _currentStudent = _students[index];

        // Update Firebase
        try {
          _firebaseService.updateWeakAreas(
              _currentStudent!.studentId, newWeakAreas);
        } catch (e) {
          print('Firebase update failed: $e');
        }

        notifyListeners();
      }
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
          testsGiven: _currentStudent!.testsGiven, // ADD THIS
        );
        _currentStudent = _students[index];

        // Update in Firebase
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

        // Update in Firebase
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
