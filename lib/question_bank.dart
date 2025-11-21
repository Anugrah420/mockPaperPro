// import 'dart:convert';
// import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'models.dart';

class QuestionBank {
  static List<Question> _questions = [];
  static bool _isInitialized = false;

  static Future<void> initializeFromCSV() async {
    if (_isInitialized) return;

    try {
      final csvData = await rootBundle.loadString('assets/questions.csv');
      _questions = _parseCSV(csvData);
      _isInitialized = true;
      print(
        'Question bank initialized with ${_questions.length} questions from CSV',
      );
    } catch (e) {
      print('Error loading CSV: $e');
      // Fallback to all questions if CSV fails
      _questions = _getAllQuestions();
      _isInitialized = true;
      print(
        'Question bank initialized with ${_questions.length} default questions',
      );
    }
  }

  // Parse CSV data into Question objects
  static List<Question> _parseCSV(String csvData) {
    final lines = csvData.split('\n');
    final questions = <Question>[];

    // Skip header row and process each line
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      try {
        final question = _parseCSVLine(line, i);
        if (question != null) {
          questions.add(question);
        }
      } catch (e) {
        print('Error parsing line $i: $e');
      }
    }

    return questions;
  }

  static Question? _parseCSVLine(String line, int lineNumber) {
    // Handle CSV parsing with proper quote handling
    final fields = _parseCSVFields(line);

    if (fields.length < 6) {
      print('Invalid CSV format at line $lineNumber: $line');
      return null;
    }

    try {
      // final shift = fields[0];
      final questionText = fields[1];
      final optionsString = fields[2];
      final answer = fields[3];
      final subject = fields[4];
      final chapter = fields[5];

      // Parse options (assuming they are separated by '|')
      final options =
          optionsString.split('|').map((opt) => opt.trim()).toList();

      // Parse correct answer index (adjust for 0-based indexing)
      int correctAnswerIndex;
      if (answer.isEmpty) {
        correctAnswerIndex = 0; // Default to first option if answer is empty
      } else {
        correctAnswerIndex = (int.tryParse(answer) ?? 1) - 1;
      }

      if (correctAnswerIndex < 0 || correctAnswerIndex >= options.length) {
        print('Invalid answer index at line $lineNumber: $answer');
        correctAnswerIndex = 0; // Default to first option
      }

      // Generate a unique ID
      final id = 'Q${lineNumber.toString().padLeft(4, '0')}';

      return Question(
        id: id,
        questionText: questionText,
        options: options,
        correctAnswerIndex: correctAnswerIndex,
        subject: _mapSubject(subject),
        topic: chapter,
        subTopic: chapter,
        difficulty: _determineDifficulty(questionText),
        marks: 4.0,
        timeRequired: _calculateTimeRequired(questionText),
        concepts: _extractConcepts(questionText, chapter),
        questionType: _determineQuestionType(questionText, options),
      );
    } catch (e) {
      print('Error creating question from line $lineNumber: $e');
      return null;
    }
  }

  // Helper method to parse CSV fields considering quotes
  static List<String> _parseCSVFields(String line) {
    final fields = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        fields.add(buffer.toString().trim());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }

    // Add the last field
    fields.add(buffer.toString().trim());

    return fields;
  }

  // Map subject names to standardized format
  static String _mapSubject(String subject) {
    final subjectLower = subject.toLowerCase();
    if (subjectLower.contains('math')) return 'Mathematics';
    if (subjectLower.contains('phy')) return 'Physics';
    if (subjectLower.contains('chem')) return 'Chemistry';
    return subject;
  }

  // Determine difficulty based on question text and chapter
  static String _determineDifficulty(String questionText) {
    final text = questionText.toLowerCase();
    if (text.contains('least') ||
        text.contains('minimum') ||
        text.contains('maximum') ||
        text.contains('ratio') ||
        text.contains('complex') ||
        text.contains('integration') ||
        text.contains('differential') ||
        text.contains('eigen') ||
        text.contains('binomial') ||
        text.contains('elliptical')) {
      return 'Hard';
    } else if (text.length > 200 ||
        text.contains('assertion') ||
        text.contains('reason') ||
        text.contains('vector') ||
        text.contains('matrix') ||
        text.contains('coordinate')) {
      return 'Medium';
    }
    return 'Easy';
  }

  // Calculate time required based on question complexity
  static int _calculateTimeRequired(String questionText) {
    final length = questionText.length;
    if (length > 300) return 180;
    if (length > 150) return 150;
    return 120;
  }

  // Extract concepts from question text and chapter
  static List<String> _extractConcepts(String questionText, String chapter) {
    final concepts = <String>[chapter];
    final text = questionText.toLowerCase();

    if (text.contains('integral') ||
        text.contains('different') ||
        text.contains('limit')) {
      concepts.add('Calculus');
    }
    if (text.contains('vector') ||
        text.contains('matrix') ||
        text.contains('determinant')) {
      concepts.add('Algebra');
    }
    if (text.contains('circle') ||
        text.contains('parabola') ||
        text.contains('ellipse') ||
        text.contains('coordinate')) {
      concepts.add('Coordinate Geometry');
    }
    if (text.contains('current') ||
        text.contains('magnetic') ||
        text.contains('electromag')) {
      concepts.add('Electromagnetism');
    }
    if (text.contains('thermo') ||
        text.contains('heat') ||
        text.contains('temperature')) {
      concepts.add('Thermodynamics');
    }
    if (text.contains('organic') ||
        text.contains('compound') ||
        text.contains('reaction')) {
      concepts.add('Organic Chemistry');
    }
    if (text.contains('equilibrium') || text.contains('dissociation')) {
      concepts.add('Chemical Equilibrium');
    }

    return concepts;
  }

  // Determine question type
  static String _determineQuestionType(
    String questionText,
    List<String> options,
  ) {
    final text = questionText.toLowerCase();

    if (text.contains('assertion') && text.contains('reason')) {
      return 'assertion-reason';
    }
    if (options.any((opt) => opt.contains('Match') || opt.contains('List'))) {
      return 'matching';
    }
    if (text.contains('numerical') ||
        options.any(
          (opt) =>
              double.tryParse(opt.replaceAll(RegExp(r'[^0-9.]'), '')) != null,
        )) {
      return 'numerical';
    }

    return 'multiple-choice';
  }

  // Get all questions
  static List<Question> get questions {
    if (!_isInitialized) {
      // Return all questions if not initialized
      return _getAllQuestions();
    }
    return _questions;
  }

  // Get questions by subject
  static List<Question> getQuestionsBySubject(String subject) {
    return questions.where((question) => question.subject == subject).toList();
  }

  // Get questions by topic
  static List<Question> getQuestionsByTopic(String topic) {
    return questions.where((question) => question.topic == topic).toList();
  }

  // Get questions by difficulty
  static List<Question> getQuestionsByDifficulty(String difficulty) {
    return questions
        .where((question) => question.difficulty == difficulty)
        .toList();
  }

  // Get random questions
  static List<Question> getRandomQuestions(int count) {
    final shuffled = List<Question>.from(questions)..shuffle();
    return shuffled.take(count).toList();
  }

  // Get questions by multiple criteria
  static List<Question> getQuestions({
    String? subject,
    String? topic,
    String? difficulty,
    int limit = 10,
  }) {
    var filtered = questions;

    if (subject != null) {
      filtered = filtered.where((q) => q.subject == subject).toList();
    }

    if (topic != null) {
      filtered = filtered.where((q) => q.topic == topic).toList();
    }

    if (difficulty != null) {
      filtered = filtered.where((q) => q.difficulty == difficulty).toList();
    }

    return filtered.take(limit).toList();
  }

  // Get all questions as fallback - COMPLETE LIST
  static List<Question> _getAllQuestions() {
    return [
      // Mathematics Questions (30 questions)
      Question(
        id: 'MATH001',
        questionText:
            "Let x₁, x₂, …, x₁₀ be ten observations such that ∑(xᵢ - 2) = 30, ∑(xᵢ - β)² = 98, β > 2, and their variance is 4/5. If μ and σ² are respectively the mean and the variance of 2(x₁ - 1) + 4β, 2(x₂ - 1) + 4β, …, 2(x₁₀ - 1) + 4β, then βσ²μ is equal to:",
        options: ['100', '120', '110', '90'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Statistics and Probability',
        subTopic: 'Statistics',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Statistics', 'Variance', 'Mean'],
        questionType: 'numerical',
      ),
      Question(
        id: 'MATH002',
        questionText:
            "Consider an A.P. of positive integers, whose sum of the first three terms is 54 and the sum of the first twenty terms lies between 1600 and 1800. Then its 11th term is:",
        options: ['90', '84', '122', '108'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Sequence and Series',
        subTopic: 'Sequences & Series',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['AP', 'Sum of Series'],
        questionType: 'numerical',
      ),
      Question(
        id: 'MATH003',
        questionText:
            "The number of solutions of the equation (9ˣ - 9√ˣ + 2)(2ˣ - 7√ˣ + 3) = 0 is:",
        options: ['2', '3', '1', '4'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Complex Numbers and Quadratic Equations',
        subTopic: 'Quadratic Equations / Algebra',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Exponential Equations', 'Roots'],
        questionType: 'numerical',
      ),
      Question(
        id: 'MATH004',
        questionText:
            "Define a relation R on the interval [0, π) by xRy if and only if sec²x - tan²y = 1. Then R is:",
        options: [
          'both reflexive and transitive but not symmetric',
          'an equivalence relation',
          'reflexive but neither symmetric nor transitive',
          'both reflexive and symmetric but not transitive',
        ],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Sets, Relations and Functions',
        subTopic: 'Relations & Functions',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Relations', 'Trigonometric Relations'],
        questionType: 'theory',
      ),
      Question(
        id: 'MATH005',
        questionText:
            "Two parabolas have the same focus (4,3) and their directrices are the x-axis and the y-axis, respectively. If these parabolas intersect at the points A and B, then (AB)² is equal to:",
        options: ['392', '384', '192', '96'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: 'Conic Sections (Parabola)',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Parabola', 'Focus', 'Directrix'],
        questionType: 'numerical',
      ),
      Question(
        id: 'MATH006',
        questionText:
            "Let P be the set of seven digit numbers with sum of their digits equal to 11. If the numbers in P are formed by using the digits 1,2 and 3 only, then the number of elements in the set P is:",
        options: ['173', '164', '158', '161'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Permutation & Combination',
        subTopic: 'Permutation & Combination',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Permutations', 'Combinations'],
        questionType: 'numerical',
      ),
      Question(
        id: 'MATH007',
        questionText:
            "Let →a = î + 2ĵ + k̂ and →b = 2î + 7ĵ + 3k̂. Let L₁: →r = (-î + 2ĵ + k̂) + λ→a, λ ∈ R and L₂: →r = (ĵ + k̂) + μ→b, μ ∈ R be two lines. If the line L₃ passes through the point of intersection of L₁ and L₂, and is parallel to →a + →b, then L₃ passes through the point:",
        options: ['(1,1,1)', '(2,2,2)', '(-1,-1,1)', '(0,0,0)'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: '3D Geometry (Lines)',
        subTopic: '3D Geometry (Lines)',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['3D Geometry', 'Lines', 'Vectors'],
        questionType: 'numerical',
      ),
      Question(
        id: 'MATH008',
        questionText:
            "Let →a = 2î - ĵ + 3k̂, →b = 3î - 5ĵ + k̂ and →c be a vector such that →a × →c = →c × →b and (→a + →c)⋅(→b + →c) = 168. Then the maximum value of |→c|² is:",
        options: ['462', '77', '154', '308'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Vector Algebra',
        subTopic: 'Vector Algebra',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Vector Algebra', 'Cross Product'],
        questionType: 'numerical',
      ),
      Question(
        id: 'MATH009',
        questionText:
            "The integral ∫₀⁸⁰ (sinθ + cosθ)/(9 + 16sin2θ) dθ is equal to:",
        options: ['3logₑ4', '4logₑ3', '6logₑ4', '2logₑ3'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Integral Calculus',
        subTopic: 'Integration',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Integration', 'Trigonometric'],
        questionType: 'numerical',
      ),
      Question(
        id: 'MATH010',
        questionText:
            "Let the ellipse E₁: x²/a² + y²/b² = 1, a > b and E₂: x²/A² + y²/B² = 1, A < B have same eccentricity 1/√3. Let the product of their lengths of latus rectums be √32/3, and the distance between the foci of E₁ be 4. If E₁ and E₂ meet at A,B,C and D, then the area of the quadrilateral ABCD equals:",
        options: ['12√6', '6√6/5', '18√6/5', '24√6/5'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: 'Conic Sections (Ellipse)',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Ellipse', 'Conic Sections'],
        questionType: 'numerical',
      ),
      Question(
        id: 'MATH011',
        questionText:
            "Let A = [aᵢⱼ] = [log₅8 log₄25]. If Aᵢⱼ is the cofactor of aᵢⱼ, Cᵢⱼ = ∑₂ k=1 aᵢₖ Aⱼₖ, 1 ≤ i,j ≤ 2, and C = [Cᵢⱼ], then 8|C| is equal to:",
        options: ['288', '222', '242', '262'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Matrices & Determinants',
        subTopic: 'Matrices & Determinants',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Matrices', 'Determinants'],
        questionType: 'numerical',
      ),
      Question(
        id: 'MATH012',
        questionText:
            "Let |z₁ - 8 - 2i| ≤ 1 and |z₂ - 2 + 6i| ≤ 2, z₁, z₂ ∈ C. Then the minimum value of |z₁ - z₂| is:",
        options: ['13', '10', '3', '7'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Complex Numbers and Quadratic Equations',
        subTopic: 'Complex Numbers',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Complex Numbers', 'Geometry'],
        questionType: 'numerical',
      ),
      Question(
        id: 'MATH013',
        questionText:
            "Let L₁: (x-1)/1 = (y+1)/2 = (z-2)/1 and L₂: (x+1)/1 = (y-2)/2 = z/1 be two lines. Let L₃ be a line passing through the point (α,β,γ) and be perpendicular to both L₁ and L₂. If L₃ intersects L₁, then |5α - 11β - 8γ| equals:",
        options: ['20', '18', '25', '16'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: '3D Geometry (Lines)',
        subTopic: '3D Geometry (Lines)',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['3D Geometry', 'Lines'],
        questionType: 'numerical',
      ),
      Question(
        id: 'MATH014',
        questionText:
            "Let M and m respectively be the maximum and the minimum values of f(x) = |1+sin2x cos2x 4sin4x; sin2x 1+cos2x 4sin4x; sin2x cos2x 1+4sin4x|, x ∈ R. Then M⁴ - m⁴ is equal to:",
        options: ['1', '2', '3', '4'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Trigonometry',
        subTopic: 'Trigonometric Functions',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Trigonometry', 'Determinants'],
        questionType: 'numerical',
      ),
      Question(
        id: 'MATH015',
        questionText:
            "Let ABC be a triangle formed by the lines 7x-6y+3=0, x+2y-31=0 and 9x-2y-19=0. Let the point (h,k) be the image of the centroid of ΔABC in the line 3x+6y-53=0. Then h² + k² + hk is equal to:",
        options: ['47', '37', '36', '40'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: 'Coordinate Geometry',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Coordinate Geometry', 'Triangle'],
        questionType: 'numerical',
      ),
      Question(
        id: 'MATH016',
        questionText: "The value of lim n→∞ (∑ⁿ k=1 (k³+6)/((k²+3k+1)!)) is:",
        options: ['4/3', '2', '7/3', '5/3'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Limits',
        subTopic: 'Limits',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Limits', 'Sequences'],
        questionType: 'numerical',
      ),
      Question(
        id: 'MATH017',
        questionText:
            "The least value of n for which the number of integral terms in the Binomial expansion of (√3⁷ + 1/√2¹¹)ⁿ is 183, is:",
        options: ['2184', '2196', '2148', '2172'],
        correctAnswerIndex: 4,
        subject: 'Mathematics',
        topic: 'Binomial Theorem and Its Simple Applications',
        subTopic: 'Binomial Theorem',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Binomial Theorem', 'Expansion'],
        questionType: 'numerical',
      ),
      Question(
        id: 'MATH018',
        questionText:
            "Let y = y(x) be the solution of the differential equation cosx(log(cosx))²dy + (sinx - 3ysinxlog(cosx))dx = 0, x ∈ (0, π). If y(π/3) = -1/e², then y(π/4) is equal to:",
        options: ['1/e', 'logₑ2', '-logₑ2', 'logₑ3'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Differential Equations',
        subTopic: 'Differential Equations',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Differential Equations'],
        questionType: 'numerical',
      ),
      Question(
        id: 'MATH019',
        questionText:
            "Let the line x + y = 1 meet the circle x² + y² = 4 at the points A and B. If the line perpendicular to AB and passing through the mid point of the chord AB intersects the circle at C and D, then the area of the quadrilateral ADBC is equal to:",
        options: ['√14', '3√7', '2√14', '5√7'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: 'Circle',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Circle', 'Chord', 'Area'],
        questionType: 'numerical',
      ),
      Question(
        id: 'MATH020',
        questionText:
            "Let the area of the region {(x,y): 2y ≤ x² + 3, y + |x| ≤ 3, y ≥ |x - 1|} be A. Then 6A is equal to:",
        options: ['16', '12', '14', '18'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: 'Coordinate Geometry',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Coordinate Geometry', 'Area'],
        questionType: 'numerical',
      ),
      Question(
        id: 'MATH021',
        questionText:
            "Let S = {x : cos⁻¹x = π + sin⁻¹x + sin⁻¹(2x + 1)}. Then ∑ (2x - 1)² is equal to ______.",
        options: ['4', '5', '6', '7'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Trigonometry',
        subTopic: 'Inverse Trigonometric Functions',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Inverse Trigonometry'],
        questionType: 'numerical',
      ),
      Question(
        id: 'MATH022',
        questionText:
            "Let f : (0,∞) → R be a twice differentiable function. If for some a ≠ 0, ∫₀¹ f(λx)dλ = af(x), f(1) = 1 and f(16) = 1/16, then 16 - f'(1/16) is equal to _______.",
        options: ['110', '112', '114', '116'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Differential Calculus',
        subTopic: 'Differential Calculus',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Differential Calculus'],
        questionType: 'numerical',
      ),
      Question(
        id: 'MATH023',
        questionText:
            "The number of 6-letter words, with or without meaning, that can be formed using the letters of the word MATHS such that any letter that appears in the word must appear at least twice, is _______.",
        options: ['1400', '1405', '1410', '1415'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Permutation & Combination',
        subTopic: 'Permutation & Combination',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Permutations'],
        questionType: 'numerical',
      ),
      Question(
        id: 'MATH024',
        questionText:
            "Let S = {m ∈ Z : Am² + Am = 3I - A - 6}, where A = [1 0; 0 1]. Then n(S) is equal to ______.",
        options: ['1', '2', '3', '4'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Matrices & Determinants',
        subTopic: 'Matrices & Determinants',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Matrices'],
        questionType: 'numerical',
      ),
      Question(
        id: 'MATH025',
        questionText:
            "Let [t] be the greatest integer less than or equal to t. Then the least value of p ∈ N for which lim x→0+ (x([1/x]+[2/x]+…+[p/x]) - x²([1/x²]+[2/x²]+…+[9/x²])) ≥ 1 is equal to ________.",
        options: ['22', '23', '24', '25'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Limits',
        subTopic: 'Limits',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Limits'],
        questionType: 'numerical',
      ),

      // Physics Questions (30 questions)
      Question(
        id: 'PHY001',
        questionText:
            "An electric dipole of mass m, charge q, and length l is placed in a uniform electric field E = E₀î. When the dipole is rotated slightly from its equilibrium position and released, the time period of its oscillations will be:",
        options: [
          '1/2π √(ml/2qE₀)',
          '2π √(ml/qE₀)',
          '1/2π √(2ml/qE₀)',
          '2π √(ml/2qE₀)',
        ],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Oscillations and Waves',
        subTopic: 'Oscillations',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Electric Dipole', 'Oscillations'],
        questionType: 'numerical',
      ),
      Question(
        id: 'PHY002',
        questionText:
            "A coil of area A and N turns is rotating with angular velocity ω in a uniform magnetic field B about an axis perpendicular to B. Magnetic flux φ and induced emf ε across it, at an instant when B is parallel to the plane of coil, are:",
        options: [
          'φ = AB, ε = 0',
          'φ = 0, ε = 0',
          'φ = 0, ε = NABω',
          'φ = AB, ε = NABω',
        ],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Electromagnetic Induction',
        subTopic: 'Electromagnetic Induction',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['EMI', 'Magnetic Flux'],
        questionType: 'theory',
      ),
      Question(
        id: 'PHY003',
        questionText:
            "Assertion (A): Choke coil is simply a coil having a large inductance but a small resistance. Choke coils are used with fluorescent mercury-tube fittings. If household electric power is directly connected to a mercury tube, the tube will be damaged. Reason (R): By using the choke coil, the voltage across the tube is reduced by a factor (R/√(R² + ω²L²)), where ω is frequency of the supply across resistor R and inductor L. If the choke coil were not used, the voltage across the resistor would be the same as the applied voltage.",
        options: [
          '(A) is true but (R) is false',
          'Both (A) and (R) are true and (R) is the correct explanation of (A)',
          '(A) is false but (R) is true',
          'Both (A) and (R) are true but (R) is not the correct explanation of (A)',
        ],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Electromagnetic Induction',
        subTopic: 'Electromagnetic Induction',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Choke Coil', 'Inductance'],
        questionType: 'assertion-reason',
      ),
      Question(
        id: 'PHY004',
        questionText:
            "As shown below, bob A of a pendulum having massless string of length 'R' is released from 60° to the vertical. It hits another bob B of half the mass that is at rest on a frictionless table in the center. Assuming elastic collision, the magnitude of the velocity of bob A after the collision will be (take g as acceleration due to gravity.)",
        options: ['4√(Rg)/3', '2√(Rg)/3', '√(Rg)', '√(Rg)/3'],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Laws of Motion',
        subTopic: 'Laws Of Motion + Collisions',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Collision', 'Pendulum'],
        questionType: 'numerical',
      ),
      Question(
        id: 'PHY005',
        questionText:
            "Assertion (A): Electromagnetic waves carry energy but not momentum. Reason (R): Mass of a photon is zero.",
        options: [
          'Both (A) and (R) are true and (R) is the correct explanation of (A)',
          'Both (A) and (R) are true but (R) is not the correct explanation of (A)',
          '(A) is false but (R) is true',
          '(A) is true but (R) is false',
        ],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Electromagnetic Waves',
        subTopic: 'Electromagnetic Waves',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['EM Waves', 'Photon'],
        questionType: 'assertion-reason',
      ),
      Question(
        id: 'PHY006',
        questionText:
            "Two projectiles are fired with same initial speed from same point on ground at angles of (45° - α) and (45° + α), respectively, with the horizontal direction. The ratio of their maximum heights attained is:",
        options: [
          '(1 - tanα)/(1 - sin²α)',
          '(1 + tanα)/(1 + sin²α)',
          '(1 + sin²α)/(1 - sin²α)',
          '(1 + sinα)/(1 - sinα)',
        ],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Kinematics',
        subTopic: 'Projectile Motion',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Projectile Motion', 'Maximum Height'],
        questionType: 'numerical',
      ),
      Question(
        id: 'PHY007',
        questionText:
            "If λ and K are de Broglie wavelength and kinetic energy, respectively, of a particle with constant mass. The correct graphical representation for the particle will be:",
        options: ['λ ∝ 1/√K', 'λ ∝ 1/K', 'λ ∝ K', 'λ ∝ √K'],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Dual Nature Of Matter And Radiation',
        subTopic: 'Dual Nature Of Matter And Radiation',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['de Broglie Wavelength'],
        questionType: 'theory',
      ),
      Question(
        id: 'PHY008',
        questionText:
            "Assertion (A): Emission of electrons in photoelectric effect can be suppressed by applying a sufficiently negative electron potential to the photoemissive substance. Reason (R): A negative electric potential, which stops the emission of electrons from the surface of a photoemissive substance, varies linearly with frequency of incident radiation.",
        options: [
          '(A) is false but (R) is true',
          '(A) is true but (R) is false',
          'Both (A) and (R) are true and (R) is the correct explanation of (A)',
          'Both (A) and (R) are true but (R) is not the correct explanation of (A)',
        ],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Dual Nature Of Matter And Radiation',
        subTopic: 'Dual Nature Of Matter And Radiation',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Photoelectric Effect'],
        questionType: 'assertion-reason',
      ),
      Question(
        id: 'PHY009',
        questionText:
            "Consider a long straight wire of a circular cross-section (radius a) carrying a steady current I. The current is uniformly distributed across this cross-section. The distances from the centre of the wire's cross-section at which the magnetic field [inside the wire, outside the wire] is half of the maximum possible magnetic field, any where due to the wire, will be",
        options: ['[a/4, 3a/2]', '[a/4, 2a]', '[a/2, 2a]', '[a/2, 3a]'],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Magnetic Effects of Current and Magnetism',
        subTopic: 'Magnetism And Matter / Current Electricity',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Magnetic Field', 'Current'],
        questionType: 'numerical',
      ),
      Question(
        id: 'PHY010',
        questionText:
            "At the interface between two materials having refractive indices n₁ and n₂, the critical angle for reflection of an em wave is θ₁C. The n₂ material is replaced by another material having refractive index n₃ such that the critical angle at the interface between n₁ and n₃ materials is θ₂C. If n₃ > n₂ > n₁; n₂/n₁ = 2/5 and 3sinθ₂C - sinθ₁C = 1/2, then θ₁C is",
        options: ['sin⁻¹(1/6)', 'sin⁻¹(1/3)', 'sin⁻¹(5/6)', 'sin⁻¹(2/3)'],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Ray Optics',
        subTopic: 'Ray Optics',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Refraction', 'Critical Angle'],
        questionType: 'numerical',
      ),
      Question(
        id: 'PHY011',
        questionText:
            "Let u and v be the distances of the object and the image from a lens of focal length f. The correct graphical representation of u and v for a convex lens when |u| > f is:",
        options: [
          '1/v + 1/u = 1/f',
          '1/v - 1/u = 1/f',
          'v = uf/(u - f)',
          'u = vf/(v - f)',
        ],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Ray Optics',
        subTopic: 'Ray Optics',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Lens Formula'],
        questionType: 'theory',
      ),
      Question(
        id: 'PHY012',
        questionText:
            "Match List - I with List - II:\n(A) Electric field inside uniformly charged spherical shell - (I) σ/ε₀\n(B) Electric field at distance r from uniformly charged infinite plane sheet - (II) σ/2ε₀\n(C) Electric field outside uniformly charged spherical shell - (III) 0\n(D) Electric field between 2 oppositely charged infinite plane parallel sheets - (IV) σR²/ε₀r²",
        options: [
          '(A)-(III), (B)-(II), (C)-(IV), (D)-(I)',
          '(A)-(IV), (B)-(II), (C)-(III), (D)-(I)',
          '(A)-(II), (B)-(I), (C)-(IV), (D)-(III)',
          '(A)-(IV), (B)-(I), (C)-(III), (D)-(II)',
        ],
        correctAnswerIndex: 4,
        subject: 'Physics',
        topic: 'Electrostatics',
        subTopic: 'Electrostatics',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Electric Field'],
        questionType: 'matching',
      ),
      Question(
        id: 'PHY013',
        questionText: "For the circuit shown above, equivalent GATE is:",
        options: ['OR gate', 'NAND gate', 'NOT gate', 'AND gate'],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Electronic Devices',
        subTopic: 'Digital Electronics / Logic Gates',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 140,
        concepts: ['Logic Gates'],
        questionType: 'theory',
      ),
      Question(
        id: 'PHY014',
        questionText:
            "The expression given below shows the variation of velocity (v) with time (t), v = (At² + Bt)/(C + t). The dimension of ABC is:",
        options: ['[M⁰ L¹ T⁻³]', '[M⁰ L² T⁻²]', '[M⁰ L¹ T⁻²]', '[M⁰ L² T⁻³]'],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Units & Dimensions',
        subTopic: 'Units & Dimensions',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Dimensions'],
        questionType: 'theory',
      ),
      Question(
        id: 'PHY015',
        questionText:
            "The work done in an adiabatic change in an ideal gas depends upon only:",
        options: [
          'change in its temperature',
          'change in its volume',
          'change in its pressure',
          'change in its specific heat',
        ],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Thermodynamics',
        subTopic: 'Thermodynamics',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 120,
        concepts: ['Thermodynamics', 'Adiabatic Process'],
        questionType: 'theory',
      ),
      Question(
        id: 'PHY016',
        questionText:
            "The fractional compression (ΔV/V) of water at the depth of 2.5 km below the sea level is ______ %. Given, the Bulk modulus of water = 2×10⁹ N m⁻², density of water = 10³ kgm⁻³, acceleration due to gravity = g = 10 m s⁻².",
        options: ['1.25', '1.0', '1.75', '1.5'],
        correctAnswerIndex: 4,
        subject: 'Physics',
        topic: 'Properties of Solids and Liquids',
        subTopic: 'Properties Of Matter',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Bulk Modulus'],
        questionType: 'numerical',
      ),
      Question(
        id: 'PHY017',
        questionText:
            "The pair of physical quantities not having same dimensions is:",
        options: [
          'Pressure and Young\'s modulus',
          'Surface tension and impulse',
          'Torque and energy',
          'Angular momentum and Planck\'s constant',
        ],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Units & Dimensions',
        subTopic: 'Units & Dimensions',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 130,
        concepts: ['Dimensions', 'Physical Quantities'],
        questionType: 'theory',
      ),
      Question(
        id: 'PHY018',
        questionText:
            "Consider I₁ and I₂ are the currents flowing simultaneously in two nearby coils 1 & 2, respectively. If L₁ = self inductance of coil 1, M₁₂ = mutual inductance of coil 1 with respect to coil 2, then the value of induced emf in coil 1 will be:",
        options: [
          'ε₁ = -L₁ dI₂/dt - M₁₂ dI₁/dt',
          'ε₁ = -L₁ dI₁/dt - M₁₂ dI₂/dt',
          'ε₁ = -L₁ dI₁/dt - M₁₂ dI₁/dt',
          'ε₁ = -L₁ dI₁/dt + M₁₂ dI₂/dt',
        ],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Electromagnetic Induction',
        subTopic: 'Electromagnetic Induction',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['EMI', 'Mutual Inductance'],
        questionType: 'theory',
      ),
      Question(
        id: 'PHY019',
        questionText:
            "Assertion (A): Time period of a simple pendulum is longer at the top of a mountain than that at the base of the mountain. Reason (R): Time period of a simple pendulum decreases with increasing value of acceleration due to gravity and vice-versa.",
        options: [
          'Both (A) and (R) are true and (R) is the correct explanation of (A)',
          '(A) is true but (R) is false',
          '(A) is false but (R) is true',
          'Both (A) and (R) are true but (R) is not the correct explanation of (A)',
        ],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Gravitation',
        subTopic: 'Oscillations & Gravitation',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Pendulum', 'Gravity'],
        questionType: 'assertion-reason',
      ),
      Question(
        id: 'PHY020',
        questionText:
            "A body of mass 'm' connected to a massless and unstretchable string goes in vertical circle of radius 'R' under gravity g. The other end of the string is fixed at the center of circle. If velocity at top of circular path is n√gR, where n ≥ 1, then ratio of kinetic energy of the body at bottom to that at top of the circle is:",
        options: ['n²/(n² + 4)', '(n² + 4)/n²', '(n + 4)/n', 'n/(n + 4)'],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Work, Energy and Power',
        subTopic: 'Work, Power & Energy + Circular Motion',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Circular Motion', 'Energy'],
        questionType: 'numerical',
      ),
      Question(
        id: 'PHY021',
        questionText:
            "In a hydraulic lift, the surface area of the input piston is 6 cm² and that of the output piston is 1500 cm². If 100 N force is applied to the input piston to raise the output piston by 20 cm, then the work done is _______ kJ.",
        options: ['4', '5', '6', '7'],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Properties of Solids and Liquids',
        subTopic: 'Fluids',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Hydraulic Lift'],
        questionType: 'numerical',
      ),
      Question(
        id: 'PHY022',
        questionText:
            "The coordinates of a particle with respect to origin in a given reference frame is (1,1,1) meters. If a force of →F = î - ĵ + k̂ acts on the particle, then the magnitude of torque (with respect to origin) in z-direction is ______.",
        options: ['1', '2', '3', '4'],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Rotational Motion',
        subTopic: 'System Of Particles & Rotational Motion',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Torque'],
        questionType: 'numerical',
      ),
      Question(
        id: 'PHY023',
        questionText:
            "Two light beams fall on a transparent material block at point 1 and 2 with angle θ₁ and θ₂ respectively, as shown in figure. After refraction, the beams intersect at point 3 which is exactly on the interface at other end of the block. Given: the distance between 1 and 2, d = 4√3 cm and θ₁ = θ₂ = cos⁻¹(2n₁/n₂), where refractive index of the block n₂ > refractive index of the outside medium n₁, then the thickness of the block is ________ cm.",
        options: ['4', '5', '6', '7'],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Ray Optics',
        subTopic: 'Ray Optics',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Refraction'],
        questionType: 'numerical',
      ),
      Question(
        id: 'PHY024',
        questionText:
            "A container of fixed volume contains a gas at 27°C. To double the pressure of the gas, the temperature of gas should be raised to ______ °C.",
        options: ['54', '127', '327', '427'],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Thermodynamics',
        subTopic: 'Thermodynamics',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 120,
        concepts: ['Gas Laws'],
        questionType: 'numerical',
      ),
      Question(
        id: 'PHY025',
        questionText:
            "The maximum speed of a boat in still water is 27 km/h. Now this boat is moving downstream in a river flowing at 9 km/h. A man in the boat throws a ball vertically upwards with speed of 10 m/s. Range of the ball as observed by an observer at rest on the river bank, is _______ cm. (Take g = 10 m/s²)",
        options: ['1800', '1900', '2000', '2100'],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Kinematics',
        subTopic: 'Relative Motion + Projectile Motion',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Relative Motion', 'Projectile'],
        questionType: 'numerical',
      ),

      // Chemistry Questions (30 questions)
      Question(
        id: 'CHEM001',
        questionText:
            "Match List - I with List - II:\n(A) [MnBr₄]²⁻ - (I) d²sp³ & diamagnetic\n(B) [FeF₆]³⁻ - (II) sp³d² & paramagnetic\n(C) [Co(C₂O₄)₃]³⁻ - (III) sp³ & diamagnetic\n(D) [Ni(CO)₄] - (IV) sp³ & paramagnetic",
        options: [
          '(A)-(IV), (B)-(II), (C)-(I), (D)-(III)',
          '(A)-(III), (B)-(I), (C)-(II), (D)-(IV)',
          '(A)-(IV), (B)-(I), (C)-(II), (D)-(III)',
          '(A)-(III), (B)-(II), (C)-(I), (D)-(IV)',
        ],
        correctAnswerIndex: 2,
        subject: 'Chemistry',
        topic: 'Coordination Compounds',
        subTopic: 'Coordination Compounds',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Coordination Compounds', 'Hybridisation'],
        questionType: 'matching',
      ),
      Question(
        id: 'CHEM002',
        questionText:
            "500 J of energy is transferred as heat to 0.5 mol of Argon gas at 298 K and 1.00 atm. The final temperature and the change in internal energy respectively are: Given: R = 8.3 J K⁻¹ mol⁻¹",
        options: [
          '378 K and 500 J',
          '368 K and 500 J',
          '348 K and 300 J',
          '378 K and 300 J',
        ],
        correctAnswerIndex: 2,
        subject: 'Chemistry',
        topic: 'Thermodynamics',
        subTopic: 'Thermodynamics',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Thermodynamics', 'Internal Energy'],
        questionType: 'numerical',
      ),
      Question(
        id: 'CHEM003',
        questionText:
            "At temperature T, compound AB₂(g) dissociates as AB₂(g) ⇌ AB(g) + 1/2 B₂(g) having degree of dissociation x (small compared to unity). The correct expression for x in terms of Kₚ and p is:",
        options: ['√(4√(2Kₚ/p))', '√(3√(2Kₚ/p))', '√(³√(2Kₚ²/p))', '√(Kₚ/p)'],
        correctAnswerIndex: 2,
        subject: 'Chemistry',
        topic: 'Equilibrium',
        subTopic: 'Chemical Equilibrium',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Chemical Equilibrium', 'Dissociation'],
        questionType: 'numerical',
      ),
      Question(
        id: 'CHEM004',
        questionText:
            "An element 'E' has the ionization enthalpy value of 374 kJ mol⁻¹. 'E' reacts with elements A,B,C and D with electron gain enthalpy values of -328, -349, -325 and -295 kJ mol⁻¹, respectively. The correct order of the products EA, EB, EC and ED in terms of ionic character is:",
        options: [
          'ED > EC > EB > EA',
          'EA > EB > EC > ED',
          'EB > EA > EC > ED',
          'ED > EC > EA > EB',
        ],
        correctAnswerIndex: 2,
        subject: 'Chemistry',
        topic: 'Chemical Bonding and Molecular Structure',
        subTopic: 'Chemical Bonding',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Chemical Bonding', 'Ionic Character'],
        questionType: 'theory',
      ),
      Question(
        id: 'CHEM005',
        questionText:
            "Total number of nucleophiles from the following is: NH₂⁻, PhSH, (H₃C)₂S, H₂C=CH₂, OH⁻, H₃O⁺, (CH₃)₃CO⁻, ≡NCH₃",
        options: ['7', '4', '6', '5'],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Organic Chemistry – General Concepts',
        subTopic: 'Organic Chemistry – General Concepts',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Nucleophiles', 'Organic Chemistry'],
        questionType: 'numerical',
      ),
      Question(
        id: 'CHEM006',
        questionText:
            "The steam volatile compounds among the following are: (A) Phenol (B) o-Nitrophenol (C) m-Nitrophenol (D) p-Nitrophenol",
        options: [
          '(B) and (D) Only',
          '(A) and (C) Only',
          '(A), (B) and (C) Only',
          '(A) and (B) Only',
        ],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Organic Chemistry – General Concepts',
        subTopic: 'Organic Chemistry – General Concepts',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Steam Volatility'],
        questionType: 'theory',
      ),
      Question(
        id: 'CHEM007',
        questionText:
            "Statement (I): The radii of isoelectronic species increases in the order. Mg²⁺ < Na⁺ < F⁻ < O²⁻ Statement (II): The magnitude of electron gain enthalpy of halogen decreases in the order. Cl > F > Br > I",
        options: [
          'Statement I is incorrect but Statement II is correct',
          'Statement I is correct but Statement II is incorrect',
          'Both Statement I and Statement II are incorrect',
          'Both Statement I and Statement II are correct',
        ],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Classification of Elements and Periodicity in Properties',
        subTopic: 'Periodic Table & Properties',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Periodic Table'],
        questionType: 'theory',
      ),
      Question(
        id: 'CHEM008',
        questionText:
            "Match List - I with List - II:\n(A) Amylose - (I) β-C₁-C₄, plant\n(B) Cellulose - (II) α-C₁-C₄, animal\n(C) Glycogen - (III) α-C₁-C₄, α-C₁-C₆, plant\n(D) Amylopectin - (IV) α-C₁-C₄, plant",
        options: [
          '(A)-(IV), (B)-(I), (C)-(III), (D)-(II)',
          '(A)-(III), (B)-(II), (C)-(I), (D)-(IV)',
          '(A)-(II), (B)-(III), (C)-(I), (D)-(IV)',
          '(A)-(IV), (B)-(I), (C)-(II), (D)-(III)',
        ],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Biomolecules',
        subTopic: 'Biomolecules',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Carbohydrates'],
        questionType: 'matching',
      ),
      Question(
        id: 'CHEM009',
        questionText:
            "The molar conductivity of a weak electrolyte when plotted against the square root of its concentration, which of the following is expected to be observed?",
        options: [
          'A small decrease in molar conductivity is observed at infinite dilution',
          'Molar conductivity decreases sharply with increase in concentration',
          'A small increase in molar conductivity is observed at infinite dilution',
          'Molar conductivity increases sharply with increase in concentration',
        ],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'Electrochemistry',
        subTopic: 'Electrochemistry',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Electrochemistry', 'Conductivity'],
        questionType: 'theory',
      ),
      Question(
        id: 'CHEM010',
        questionText:
            "The standard reduction potential values of some of the p-block ions are given below. Predict the one with the strongest oxidising capacity.",
        options: [
          'E⊖ = +1.67 V (Pb⁴⁺/Pb²⁺)',
          'E⊖ = +1.15 V (Sn⁴⁺/Sn²⁺)',
          'E⊖ = -1.66 V (Al³⁺/Al)',
          'E⊖ = +2.26 V (Tl³⁺/Tl)',
        ],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'Electrochemistry',
        subTopic: 'Electrochemistry',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Electrochemistry', 'Reduction Potential'],
        questionType: 'theory',
      ),
      Question(
        id: 'CHEM011',
        questionText:
            "The product (P) formed in the following reaction is: Benzene + CH₃COCl → P",
        options: ['Acetophenone', 'Benzaldehyde', 'Toluene', 'Benzoic acid'],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Some Basic Principles of Organic Chemistry',
        subTopic: 'Organic Chemistry – Reaction Mechanisms',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 140,
        concepts: ['Friedel-Crafts'],
        questionType: 'theory',
      ),
      Question(
        id: 'CHEM012',
        questionText:
            "If a₀ is denoted as the Bohr radius of hydrogen atom, then what is the de-Broglie wavelength (λ) of the electron present in the second orbit of hydrogen atom?",
        options: ['8πa₀/n', '2a₀/nπ', '4n/πa₀', '4πa₀/n'],
        correctAnswerIndex: 4,
        subject: 'Chemistry',
        topic: 'Atomic Structure',
        subTopic: 'Atomic Structure',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Atomic Structure', 'de-Broglie Wavelength'],
        questionType: 'numerical',
      ),
      Question(
        id: 'CHEM013',
        questionText:
            "Match List - I with List - II:\n(A) Zero order reaction - (I) t₁/₂ ∝ 1/[A]₀\n(B) First order reaction - (II) t₁/₂ ∝ [A]₀\n(C) Second order reaction - (III) t₁/₂ independent of [A]₀\n(D) Third order reaction - (IV) t₁/₂ ∝ 1/[A]₀²",
        options: [
          '(A)-(II), (B)-(III), (C)-(IV), (D)-(I)',
          '(A)-(II), (B)-(III), (C)-(I), (D)-(IV)',
          '(A)-(III), (B)-(II), (C)-(I), (D)-(IV)',
          '(A)-(III), (B)-(II), (C)-(IV), (D)-(I)',
        ],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'Chemical Kinetics',
        subTopic: 'Chemical Kinetics',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Chemical Kinetics'],
        questionType: 'matching',
      ),
      Question(
        id: 'CHEM014',
        questionText:
            "The reaction A₂ + B₂ → 2AB follows the mechanism A₂ ⇌ 2A (fast), A + B₂ → AB + B (slow), A + B → AB (fast). The overall order of the reaction is:",
        options: ['2', '2.5', '3', '1.5'],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Chemical Kinetics',
        subTopic: 'Chemical Kinetics',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Chemical Kinetics', 'Reaction Order'],
        questionType: 'numerical',
      ),
      Question(
        id: 'CHEM015',
        questionText:
            "1.24 g of AX₂ (molar mass 124 g mol⁻¹) is dissolved in 1 kg of water to form a solution with boiling point of 100.0156°C, while 25.4 g of AY₂ (molar mass 250 g mol⁻¹) in 2 kg of water constitutes a solution with a boiling point of 100.0260°C. K_b(H₂O) = 0.52 K kg mol⁻¹ Which of the following is correct?",
        options: [
          'AX₂ is fully ionised while AY₂ is completely unionised',
          'AX₂ is completely unionised while AY₂ is fully ionised',
          'AX₂ and AY₂ (both) are completely unionised',
          'AX₂ and AY₂ (both) are fully ionised',
        ],
        correctAnswerIndex: 2,
        subject: 'Chemistry',
        topic: 'Solutions & Colligative Properties',
        subTopic: 'Solutions & Colligative Properties',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Colligative Properties'],
        questionType: 'theory',
      ),
      Question(
        id: 'CHEM016',
        questionText:
            "Choose the correct statements:\n(A) Weight of a substance is the amount of matter present in it\n(B) Mass is the force exerted by gravity on an object\n(C) Volume is the amount of space occupied by a substance\n(D) Temperatures below 0°C are possible in Celsius scale, but in Kelvin scale negative temperature is not possible\n(E) Precision refers to the closeness of various measurements for the same quantity",
        options: [
          '(A), (D) and (E) Only',
          '(C), (D) and (E) Only',
          '(A), (B) and (C) Only',
          '(B), (C) and (D) Only',
        ],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'Basic Concepts Of Chemistry',
        subTopic: 'Basic Concepts Of Chemistry',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 140,
        concepts: ['Basic Concepts', 'Measurements'],
        questionType: 'theory',
      ),
      Question(
        id: 'CHEM017',
        questionText:
            "The correct option with order of melting points of the pairs (Mn,Fe), (Tc,Ru) and (Re,Os) is:",
        options: [
          'Fe < Mn, Ru < Tc and Re < Os',
          'Mn < Fe, Tc < Ru and Os < Re',
          'Mn < Fe, Tc < Ru and Re < Os',
          'Fe < Mn, Ru < Tc and Os < Re',
        ],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'Classification of Elements and Periodicity in Properties',
        subTopic: 'Periodic Table',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Periodic Table', 'Melting Points'],
        questionType: 'theory',
      ),
      Question(
        id: 'CHEM018',
        questionText:
            "For a Mg | Mg²⁺(aq) || Ag⁺(aq) | Ag the correct Nernst Equation is:",
        options: [
          'E = E° - (RT/2F) ln([Ag⁺]/[Mg²⁺])',
          'E = E° + (RT/2F) ln([Ag⁺]²/[Mg²⁺])',
          'E = E° - (RT/2F) ln([Ag⁺]²/[Mg²⁺])',
          'E = E° - (RT/2F) ln([Mg²⁺]/[Ag⁺])',
        ],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'Electrochemistry',
        subTopic: 'Electrochemistry',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Electrochemistry', 'Nernst Equation'],
        questionType: 'theory',
      ),
      Question(
        id: 'CHEM019',
        questionText:
            "In the following substitution reaction: CH₃-CH₂-Br + OH⁻ → product 'P' formed is:",
        options: ['CH₃-CH₂-OH', 'CH₂=CH₂', 'CH₃-CHO', 'CH₃-COOH'],
        correctAnswerIndex: 2,
        subject: 'Chemistry',
        topic: 'Organic Compounds Containing Halogens',
        subTopic: 'Organic Chemistry – Haloalkanes',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 120,
        concepts: ['Substitution Reaction'],
        questionType: 'theory',
      ),
      Question(
        id: 'CHEM020',
        questionText:
            "The correct increasing order of stability of the complexes based on Δ₀ value is: I. [Mn(CN)₆]³⁻ II. [Co(CN)₆]⁴⁻ III. [Fe(CN)₆]⁴⁻ IV. [Fe(CN)₆]³⁻",
        options: [
          'IV < III < II < I',
          'I < II < IV < III',
          'III < II < IV < I',
          'II < III < I < IV',
        ],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'Coordination Compounds',
        subTopic: 'Coordination Compounds',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Coordination Compounds', 'Crystal Field'],
        questionType: 'theory',
      ),
      Question(
        id: 'CHEM021',
        questionText:
            "The molar mass of the water insoluble product formed from the fusion of chromite ore (FeCr₂O₄) with Na₂CO₃ in presence of O₂ is _______ gmol⁻¹.",
        options: ['152', '160', '168', '176'],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'd- and f-Block Elements',
        subTopic: 'General Principles Of Metallurgy',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Metallurgy'],
        questionType: 'numerical',
      ),
      Question(
        id: 'CHEM022',
        questionText:
            "Given below are some nitrogen containing compounds. Each of them is treated with HCl separately. 1.0 g of the most basic compound will consume _______ mg of HCl. (Given molar mass in gmol⁻¹ C: 12, H: 1, O: 16, Cl: 35.5)",
        options: ['335', '341', '347', '353'],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'Organic Compounds Containing Nitrogen',
        subTopic: 'Organic Chemistry – Amines',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Amines', 'Basicity'],
        questionType: 'numerical',
      ),
      Question(
        id: 'CHEM023',
        questionText:
            "The sum of sigma (σ) and pi (π) bonds in Hex-1,3-dien-5-yne is _______.",
        options: ['13', '14', '15', '16'],
        correctAnswerIndex: 2,
        subject: 'Chemistry',
        topic: 'Hydrocarbons',
        subTopic: 'Organic Chemistry – Hydrocarbons',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Chemical Bonding'],
        questionType: 'numerical',
      ),
      Question(
        id: 'CHEM024',
        questionText:
            "0.1 mole of compound 'S' will weigh _______ g. (Given molar mass in gmol⁻¹ C: 12, H: 1, O: 16)",
        options: ['11', '12', '13', '14'],
        correctAnswerIndex: 2,
        subject: 'Chemistry',
        topic: 'Basic Concepts Of Chemistry',
        subTopic: 'Basic Concepts Of Chemistry',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 120,
        concepts: ['Mole Concept'],
        questionType: 'numerical',
      ),
      Question(
        id: 'CHEM025',
        questionText:
            "If A₂B is 30% ionised in an aqueous solution, then the value of van't Hoff factor (i) is ______ ×10⁻¹.",
        options: ['14', '15', '16', '17'],
        correctAnswerIndex: 2,
        subject: 'Chemistry',
        topic: 'Solutions & Colligative Properties',
        subTopic: 'Solutions & Colligative Properties',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Colligative Properties'],
        questionType: 'numerical',
      ),
      Question(
        id: 'MATH0175',
        questionText:
            'If the first term of an A.P. is 3 and the sum of its first four terms is equal to one-fifth of the sum of the next four terms, then the sum of the first 20 terms is equal to',
        options: ['−1080', '−1020', '−1200', '−120'],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Sequence and Series',
        subTopic: 'Arithmetic Progression',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Arithmetic Progression', 'Sum of Terms'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0176',
        questionText:
            'One die has two faces marked 1, two faces marked 2, one face marked 3 and one face marked 4. Another die has one face marked 1, two faces marked 2, two faces marked 3 and one face marked 4. The probability of getting the sum of numbers to be 4 or 5, when both the dice are thrown together, is',
        options: ['1/3', '1/2', '4/9', '3/5'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Statistics and Probability',
        subTopic: 'Probability',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Probability', 'Dice', 'Sum of Numbers'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0177',
        questionText:
            'Let the position vectors of the vertices A, B and C of a tetrahedron ABCD be i+2j+k, i+3j−2k and 2i+j−k respectively. The altitude from the vertex D to the opposite face ABC meets the median line segment through A of the triangle ABC at the point E. If the length of AD is √110 and the volume of the tetrahedron is (3√805)/6√2, then the position vector of E is',
        options: [
          '1/12(i+4j+7k)',
          '1/2(i+4j+7k)',
          '1/6(i+4j+7k)',
          '1/4(i+4j+7k)'
        ],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Vector Algebra',
        subTopic: '3D Geometry',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Vectors', 'Tetrahedron', 'Position Vectors'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0178',
        questionText:
            'If A, B, and (adj(A⁻¹)+adj(B⁻¹)) are non-singular matrices of same order, then the inverse of A(adj(A⁻¹)+adj(B⁻¹))⁻¹B, is equal to',
        options: [
          'AB⁻¹ + A⁻¹B',
          'adj(B⁻¹)+adj(A⁻¹)',
          'AB⁻¹ + BA⁻¹',
          '(adj(B)+adj(A))/|AB|'
        ],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Matrices and Determinants',
        subTopic: 'Matrix Inverse',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Matrices', 'Inverse', 'Adjoint'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0179',
        questionText:
            'Marks obtained by all the students of class 12 are presented in a frequency distribution with classes of equal width. Let the median of this grouped data be 14 with median class interval 12-18 and median class frequency 12. If the number of students whose marks are less than 12 is 18, then the total number of students is',
        options: ['52', '48', '44', '40'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Statistics and Probability',
        subTopic: 'Statistics',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Statistics', 'Median', 'Frequency Distribution'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0180',
        questionText:
            'Let a curve y = f(x) pass through the points (0,5) and (logₑ2,k). If the curve satisfies the differential equation 2(3+y)e²ˣdx−(7+e²ˣ)dy = 0, then k is equal to',
        options: ['4', '32', '8', '16'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Differential Equations',
        subTopic: 'First Order DE',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Differential Equations', 'Curve', 'Integration'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0181',
        questionText:
            'If the function f(x) is continuous at x = 0, where f(x) = {2{sin(k₁+1)x+sin(k₁−1)x}/x, x < 0; 4, x = 0; 2logₑ(2+k₂x)/x, x > 0}, then k₁² + k₂² is equal to',
        options: ['20', '5', '8', '10'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Limit, Continuity and Differentiability',
        subTopic: 'Continuity',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Continuity', 'Limits', 'Piecewise Function'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0182',
        questionText:
            'If the line 3x−2y+12 = 0 intersects the parabola 4y = 3x² at the points A and B, then at the vertex of the parabola, the line segment AB subtends an angle equal to',
        options: [
          'tan⁻¹(4/5)',
          'tan⁻¹(9/7)',
          'tan⁻¹(11/9)',
          'π/2 − tan⁻¹(3/2)'
        ],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: 'Parabola',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Parabola', 'Line', 'Angle'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0183',
        questionText:
            'Let P be the foot of the perpendicular from the point Q(10,−3,−1) on the line (x−3)/7 = (y−2)/−1 = (z+1)/−2. Then the area of the right angled triangle PQR, where R is the point (3,−2,1), is',
        options: ['9√15', '√30', '8√15', '3√30'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: '3D Geometry',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['3D Geometry', 'Perpendicular', 'Area'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0184',
        questionText:
            'Let the arc AC of a circle subtend a right angle at the centre O. If the point B on the arc AC divides the arc AC such that (length of arc AB)/(length of arc BC) = 1/5, and OC = αOA + βOB, then α + √2(√3−1)β is equal to',
        options: ['2√3', '2−√3', '5√3', '2+√3'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Vector Algebra',
        subTopic: 'Circle Geometry',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Vectors', 'Circle', 'Arc Length'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0185',
        questionText:
            'Let f(x) = logₑx and g(x) = (x⁴−2x³+3x²−2x+2)/(2x²−2x+1). Then the domain of f∘g is',
        options: ['[0,∞)', '[1,∞)', 'R', 'R - {0}'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Sets, Relations and Functions',
        subTopic: 'Functions',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Functions', 'Domain', 'Composition'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0186',
        questionText:
            'If the system of equations (λ−1)x+(λ−4)y+λz = 5, λx+(λ−1)y+(λ−4)z = 7, (λ+1)x+(λ+2)y−(λ+2)z = 9 has infinitely many solutions, then λ² + λ is equal to',
        options: ['6', '10', '20', '12'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Matrices and Determinants',
        subTopic: 'System of Equations',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: [
          'System of Equations',
          'Infinitely Many Solutions',
          'Determinant'
        ],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0187',
        questionText:
            'The number of words which can be formed using all the letters of the word "DAUGHTER", so that all the vowels never come together, is',
        options: ['36000', '37000', '34000', '35000'],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Permutations and Combinations',
        subTopic: 'Arrangements',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Permutations', 'Arrangements', 'Vowels'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0188',
        questionText:
            'Let R = {(1,2),(2,3),(3,3)} be a relation defined on the set {1,2,3,4}. Then the minimum number of elements needed to be added in R so that R becomes an equivalence relation, is',
        options: ['10', '7', '8', '9'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Sets, Relations and Functions',
        subTopic: 'Relations',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: [
          'Relations',
          'Equivalence Relation',
          'Reflexive Symmetric Transitive'
        ],
        questionType: 'numerical',
      ),
      Question(
        id: 'MATH0189',
        questionText:
            'Let the area of a triangle PQR with vertices P(5,4), Q(−2,4) and R(a,b) be 35 square units. If its orthocenter and centroid are O(2,14) and C(c,d) respectively, then c + 2d is equal to',
        options: ['8/3', '7/3', '2', '3'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: 'Triangles',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Area of Triangle', 'Orthocenter', 'Centroid'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0190',
        questionText:
            'The value of ∫₁ᵉ⁴ (e^((logₑx)²+1) - 1)/(e^((logₑx)²+1) - 1 + e^((6−logₑx)²+1) - 1) dx is',
        options: ['2', 'logₑ2', '1', 'e²/2'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Integral Calculus',
        subTopic: 'Definite Integrals',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: [
          'Integration',
          'Logarithmic Functions',
          'Exponential Functions'
        ],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0191',
        questionText:
            'Let |(z̄ - i)/(2z̄ + i)| = 1/3, z ∈ C, be the equation of a circle with center at C. If the area of the triangle, whose vertices are at the points (0,0), C and (α,0) is 11 square units, then α² equals:',
        options: ['50', '100', '81/25', '121/25'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Complex Numbers',
        subTopic: 'Geometry',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Complex Numbers', 'Circle', 'Area of Triangle'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0192',
        questionText: 'The value of (sin70°)(cot10°cot70° − 1) is',
        options: ['2/3', '1', '0', '3/2'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Trigonometry',
        subTopic: 'Trigonometric Identities',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Trigonometric Functions', 'Identities', 'Angles'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0193',
        questionText:
            'Let I(x) = ∫dx/[(x−11)¹/³(x+15)¹/³]. If I(37) − I(24) = 1/4(1/b¹/³ − 1/c¹/³), b,c ∈ N, then 3(b+c) is equal to',
        options: ['22', '39', '40', '26'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Integral Calculus',
        subTopic: 'Indefinite Integrals',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Integration', 'Algebraic Functions', 'Natural Numbers'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0194',
        questionText:
            'If π/2 ≤ x ≤ 3π/4, then cos⁻¹(12/13 cosx + 5/13 sinx) is equal to',
        options: [
          'x − tan⁻¹(4/3)',
          'x + tan⁻¹(4/5)',
          'x − tan⁻¹(5/12)',
          'x + tan⁻¹(5/12)'
        ],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Trigonometry',
        subTopic: 'Inverse Trigonometric Functions',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: [
          'Inverse Trigonometric Functions',
          'Trigonometric Identities'
        ],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0195',
        questionText:
            'Let the circle C touch the line x−y+1 = 0, have the centre on the positive x-axis, and cut off a chord of length 4 along the line −3x+2y = 1. Let H be the hyperbola x²/α² − y²/β² = 1/√13, whose one of the foci is the centre of C and the length of the transverse axis is the diameter of C. Then 2α² + 3β² is equal to ______',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: 'Circle and Hyperbola',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Circle', 'Hyperbola', 'Chord Length', 'Focus'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0196',
        questionText:
            'If the equation a(b−c)x² + b(c−a)x + c(a−b) = 0 has equal roots, where a+c = 15 and b = 36/5, then a² + c² is equal to',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Algebra',
        subTopic: 'Quadratic Equations',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Quadratic Equations', 'Equal Roots', 'Algebra'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0197',
        questionText:
            'If the set of all values of a, for which the equation 5x³ − 15x − a = 0 has three distinct real roots, is the interval (α,β), then β − 2α is equal to ______',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Algebra',
        subTopic: 'Cubic Equations',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Cubic Equations', 'Real Roots', 'Intervals'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0198',
        questionText:
            'The sum of all rational terms in the expansion of (1 + 2¹/² + 3¹/²)⁶ is equal to',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Algebra',
        subTopic: 'Binomial Theorem',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Binomial Theorem', 'Rational Terms', 'Expansion'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0199',
        questionText:
            'If the area of the larger portion bounded between the curves x² + y² = 25 and y = |x−1| is 1/4(bπ + c), b,c ∈ N, then b + c is equal to',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: 'Area between Curves',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Area between Curves', 'Circle', 'Absolute Value'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0174',
        questionText:
            'A point particle of charge Q is located at P along the axis of an electric dipole 1 at a distance r as shown in the figure. The point P is also on the equatorial plane of a second electric dipole 2 at a distance r. The dipoles are made of opposite charge q separated by a distance 2a. For the charge particle at P not to experience any net force, which of the following correctly describes the situation?',
        options: ['a ∼ 10/r', 'a ∼ 20/r', 'a ∼ 0.5/r', 'a ∼ 3/r'],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Electrostatics',
        subTopic: 'Electric Dipole',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Electric Dipole', 'Electric Field', 'Net Force'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0175',
        questionText:
            'A spherical surface of radius of curvature R, separates air from glass (refractive index = 1.5). The centre of curvature is in the glass medium. A point object O placed in air on the optic axis of the surface, so that its real image is formed at I inside glass. The line OI intersects the spherical surface at P and PO = PI. The distance PO equals to',
        options: ['5R', '3R', '1.5R', '2R'],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Optics',
        subTopic: 'Refraction at Spherical Surface',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Refraction', 'Spherical Surface', 'Image Formation'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0176',
        questionText:
            'The position of a particle moving on x-axis is given by x(t) = Asint + Bcos2t + Ct² + D, where t is time. The dimension of ABC/D is',
        options: ['L²T⁻²', 'L²', 'L', 'L³T⁻²'],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Units and Measurements',
        subTopic: 'Dimensional Analysis',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Dimensional Analysis', 'Dimensions', 'Physical Quantities'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0177',
        questionText:
            'Given a thin convex lens (refractive index μ₂), kept in a liquid (refractive index μ₁, μ₁ < μ₂) having radii of curvatures |R₁| and |R₂|. Its second surface is silver polished. Where should an object be placed on the optic axis so that a real and inverted image is formed at the same place?',
        options: [
          'μ₁|R₁|⋅|R₂|/[μ₂(|R₁|+|R₂|)−μ₁|R₂|]',
          'μ₁|R₁|⋅|R₂|/[μ₂(|R₁|+|R₂|)−μ₁|R₁|]',
          '(μ₂+μ₁)|R₁|/(μ₂−μ₁)',
          'μ₁|R₁|⋅|R₂|/μ₂'
        ],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Optics',
        subTopic: 'Lens and Mirror Combination',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Lens', 'Silvered Surface', 'Image Formation'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0178',
        questionText:
            'Refer to the circuit diagram given in the figure. Which of the following observations are correct? A. Total resistance of circuit is 6Ω B. Current in Ammeter is 1 A C. Potential across AB is 4 Volts. D. Potential across CD is 4 Volts E. Total resistance of the circuit is 8Ω.',
        options: [
          'A, B and D Only',
          'A, B and C Only',
          'A, C and D Only',
          'B, C and E Only'
        ],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Current Electricity',
        subTopic: 'Circuit Analysis',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Circuit Analysis', 'Resistance', 'Potential Difference'],
        questionType: 'multiple',
      ),

      Question(
        id: 'PHY0179',
        questionText:
            'Given below are two statements: Statement I: The hot water flows faster than cold water Statement II: Soap water has higher surface tension as compared to fresh water. In the light above statements, choose the correct answer from the options given below',
        options: [
          'Statement I is true but Statement II is false',
          'Statement I is false but Statement II is true',
          'Both Statement I and Statement II are false',
          'Both Statement I and Statement II are true'
        ],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Properties of Matter',
        subTopic: 'Fluid Mechanics',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Viscosity', 'Surface Tension', 'Fluid Flow'],
        questionType: 'multiple',
      ),

      Question(
        id: 'PHY0180',
        questionText:
            'Consider a circular disc of radius 20 cm with centre located at the origin. A circular hole of radius 5 cm is cut from this disc in such a way that the edge of the hole touches the edge of the disc. The distance of centre of mass of residual or remaining disc from the origin will be',
        options: ['2.0 cm', '1.5 cm', '1.0 cm', '0.5 cm'],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Mechanics',
        subTopic: 'Center of Mass',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Center of Mass', 'Circular Disc', 'Hole'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0181',
        questionText:
            'The electric flux is ϕ = ασ + βλ where λ and σ are linear and surface charge density, respectively. (α/β) represents',
        options: ['electric field', 'area', 'charge', 'displacement'],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Electrostatics',
        subTopic: 'Electric Flux',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Electric Flux', 'Charge Density', 'Dimensional Analysis'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0182',
        questionText:
            'A sub-atomic particle of mass 10⁻³⁰ kg is moving with a velocity 2.21×10⁶ m/s. Under the matter wave consideration, the particle will behave closely like (h = 6.63×10⁻³⁴ J.s)',
        options: [
          'Visible radiation',
          'Gamma rays',
          'Infra-red radiation',
          'X-rays'
        ],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Modern Physics',
        subTopic: 'Matter Waves',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: [
          'Matter Waves',
          'de Broglie Wavelength',
          'Electromagnetic Spectrum'
        ],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0183',
        questionText:
            'Consider a moving coil galvanometer (MCG): A. The torsional constant in moving coil galvanometer has dimensions [ML²T⁻²] B. Increasing the current sensitivity may not necessarily increase the voltage sensitivity. C. If we increase number of turns (N) to its double (2N), then the voltage sensitivity doubles. D. MCG can be converted into an ammeter by introducing a shunt resistance of large value in parallel with galvanometer. E. Current sensitivity of MCG depends inversely on number of turns of coil.',
        options: ['A, D Only', 'A, B, E Only', 'B, D, E Only', 'A, B Only'],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Electromagnetic Induction',
        subTopic: 'Galvanometer',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Galvanometer', 'Sensitivity', 'Dimensions'],
        questionType: 'multiple',
      ),

      Question(
        id: 'PHY0184',
        questionText:
            'Match the LIST-I with LIST-II: A. Pressure varies inversely with volume of an ideal gas. B. Heat absorbed goes partly to increase internal energy and partly to do work. C. Heat is neither absorbed nor released by a system. D. No work is done on or by a gas.',
        options: [
          'A-III, B-IV, C-I, D-II',
          'A-I, B-IV, C-II, D-III',
          'A-III, B-I, C-IV, D-II',
          'A-I, B-III, C-II, D-IV'
        ],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Thermodynamics',
        subTopic: 'Thermodynamic Processes',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Thermodynamic Processes', 'Ideal Gas', 'Work and Heat'],
        questionType: 'matching',
      ),

      Question(
        id: 'PHY0185',
        questionText:
            'The electric field of an electromagnetic wave in free space is E = 57cos[7.5×10⁶t − 5×10⁻³(3x+4y)](4î − 3ĵ) N/C. The associated magnetic field in Tesla is',
        options: [
          'B = 57/c cos[7.5×10⁶t − 5×10⁻³(3x+4y)] (3î + 4ĵ)',
          'B = -57/c cos[7.5×10⁶t − 5×10⁻³(3x+4y)] (4î − 3ĵ)',
          'B = -57/c cos[7.5×10⁶t − 5×10⁻³(3x+4y)] (3î + 4ĵ)',
          'B = 57/c cos[7.5×10⁶t − 5×10⁻³(3x+4y)] (4î − 3ĵ)'
        ],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Electromagnetic Waves',
        subTopic: 'Wave Propagation',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Electromagnetic Waves', 'Electric Field', 'Magnetic Field'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0186',
        questionText:
            'A gun fires a lead bullet of temperature 300 K into a wooden block. The bullet having melting temperature of 600 K penetrates into the block and melts down. If the total heat required for the process is 625 J, then the mass of the bullet is grams. (Latent heat of fusion of lead = 2.5×10⁴ J/Kg and specific heat capacity of lead = 125 J/Kg K)',
        options: ['10', '20', '5', '15'],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Thermodynamics',
        subTopic: 'Heat Transfer',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Heat Transfer', 'Latent Heat', 'Specific Heat'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0187',
        questionText:
            'What is the lateral shift of a ray refracted through a parallel-sided glass slab of thickness h in terms of the angle of incidence i and angle of refraction r, if the glass slab is placed in air medium?',
        options: ['htan(i−r)/tanr', 'hsin(i−r)/cosr', 'hcos(i−r)/sinr', 'h'],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Optics',
        subTopic: 'Refraction',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Refraction', 'Lateral Shift', 'Glass Slab'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0188',
        questionText:
            'A radioactive nucleus n₂ has 3 times the decay constant as compared to the decay constant of another radioactive nucleus n₁. If initial number of both nuclei are the same, what is the ratio of number of nuclei of n₂ to the number of nuclei of n₁, after one half-life of n₁?',
        options: ['1/8', '8', '4', '1/4'],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Modern Physics',
        subTopic: 'Radioactivity',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Radioactivity', 'Decay Constant', 'Half-life'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0189',
        questionText:
            'A light hollow cube of side length 10 cm and mass 10 g, is floating in water. It is pushed down and released to execute simple harmonic oscillations. The time period of oscillations is yπ×10⁻² s, where the value of y is (Acceleration due to gravity, g = 10 m/s², density of water = 10³ kg/m³)',
        options: ['6', '2', '4', '1'],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Oscillations',
        subTopic: 'Simple Harmonic Motion',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Simple Harmonic Motion', 'Buoyancy', 'Time Period'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0190',
        questionText:
            'Regarding self-inductance: A. The self-inductance of the coil depends on its geometry. B. Self-inductance does not depend on the permeability of the medium. C. Self-induced e.m.f. opposes any change in the current in a circuit. D. Self-inductance is electromagnetic analogue of mass in mechanics. E. Work needs to be done against self-induced e.m.f. in establishing the current.',
        options: [
          'A,B,C,E only',
          'B, C, D, E only',
          'A,C,D,E only',
          'A, B, C, D only'
        ],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Electromagnetic Induction',
        subTopic: 'Self Inductance',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Self Inductance', 'Electromagnetic Induction', 'Lenz Law'],
        questionType: 'multiple',
      ),

      Question(
        id: 'PHY0191',
        questionText:
            'The motion of an airplane is represented by velocity-time graph as shown below. The distance covered by airplane in the first 30.5 second is _______ km.',
        options: ['12', '3', '6', '9'],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Kinematics',
        subTopic: 'Motion Graphs',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Velocity-Time Graph', 'Distance', 'Area under Curve'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0192',
        questionText:
            'Identify the valid statements relevant to the given circuit at the instant when the key is closed. A. There will be no current through resistor R. B. There will be maximum current in the connecting wires. C. Potential difference between the capacitor plates A and B is minimum. D. Charge on the capacitor plates is minimum.',
        options: ['A, C Only', 'A, B, D Only', 'C, D Only', 'B, C, D Only'],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Current Electricity',
        subTopic: 'RC Circuit',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['RC Circuit', 'Capacitor', 'Current'],
        questionType: 'multiple',
      ),

      Question(
        id: 'PHY0193',
        questionText:
            'A solid sphere of mass m and radius r is allowed to roll without slipping from the highest point of an inclined plane of length L and makes an angle 30° with the horizontal. The speed of the particle at the bottom of the plane is v₁. If the angle of inclination is increased to 45° while keeping L constant. Then the new speed of the sphere at the bottom of the plane is v₂. The ratio v₁² : v₂² is',
        options: ['1 : √2', '1 : √3', '1 : 3', '1 : 2'],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Mechanics',
        subTopic: 'Rolling Motion',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: [
          'Rolling Motion',
          'Inclined Plane',
          'Conservation of Energy'
        ],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0194',
        questionText:
            'A positive ion A and a negative ion B has charges 6.67×10⁻¹⁹C and 9.6×10⁻¹⁰C, and masses 19.2×10⁻²⁷ kg and 9×10⁻²⁷ kg respectively. At an instant, the ions are separated by a certain distance r. At that instant the ratio of the magnitudes of electrostatic force to gravitational force is P × 10⁴⁵, where the value of 10P is (Take 1/4πε₀ = 9×10⁹ Nm²C⁻¹ and universal gravitational constant as 6.67×10⁻¹¹ Nm² kg⁻²)',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Electrostatics',
        subTopic: 'Forces between Ions',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Electrostatic Force', 'Gravitational Force', 'Ratio'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0195',
        questionText:
            'In the given circuit the sliding contact is pulled outwards such that electric current in the circuit changes at the rate of 8 A/s. At an instant when R is 12Ω, the value of the current in the circuit will be ______ A.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Current Electricity',
        subTopic: 'Variable Resistance',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Variable Resistance', 'Rate of Change', 'Current'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0196',
        questionText:
            'Two particles are located at equal distance from origin. The position vectors of those are represented by A = 2î + 3nĵ + 2k̂ and B = 2î − 2ĵ + 4pk̂, respectively. If both the vectors are at right angle to each other, the value of n⁻¹ is _____ .',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Vector Algebra',
        subTopic: 'Dot Product',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Vectors', 'Dot Product', 'Perpendicular Vectors'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0197',
        questionText:
            'An ideal gas initially at 0°C temperature, is compressed suddenly to one fourth of its volume. If the ratio of specific heat at constant pressure to that at constant volume is 3/2, the change in temperature due to the thermodynamic process is _____ K.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Thermodynamics',
        subTopic: 'Adiabatic Process',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Adiabatic Process', 'Ideal Gas', 'Temperature Change'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0198',
        questionText:
            'A force F = x²y î + y² ĵ acts on a particle in a plane x + y = 10. The work done by this force during a displacement from (0,0) to (4 m,2 m) is Joule (round off to the nearest integer)',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Work, Energy and Power',
        subTopic: 'Work Done',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Work Done', 'Force', 'Displacement'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0179',
        questionText:
            'Given below are two statements: Statement I: Fructose does not contain an aldehydic group but still reduces Tollen\'s reagent Statement II: In the presence of base, fructose undergoes rearrangement to give glucose. In the light of the above statements, choose the correct answer from the options given below',
        options: [
          'Both Statement I and Statement II are true',
          'Both Statement I and Statement II are false',
          'Statement I is true but Statement II is false',
          'Statement I is false but Statement II is true'
        ],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Organic Chemistry',
        subTopic: 'Carbohydrates',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Carbohydrates', 'Fructose', 'Tollen\'s Test'],
        questionType: 'multiple',
      ),

      Question(
        id: 'CHEM0180',
        questionText:
            'The complex that shows Facial - Meridional isomerism is:',
        options: [
          '[Co(en)₂Cl₂]+',
          '[Co(en)₃]³⁺',
          '[Co(NH₃)₃Cl₃]',
          '[Co(NH₃)₄Cl₂]+'
        ],
        correctAnswerIndex: 2,
        subject: 'Chemistry',
        topic: 'Coordination Compounds',
        subTopic: 'Isomerism',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Coordination Compounds', 'Isomerism', 'Facial-Meridional'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0181',
        questionText:
            'FeO₄²⁻ →²·⁰ Fe³⁺ →⁰·⁸ Fe²⁺ →⁻⁰·⁵ Fe⁰ In the above diagram, the standard electrode potentials are given in volts (over the arrow). The value of E° for FeO₄²⁻/Fe²⁺ is',
        options: ['2.1 V', '1.7 V', '1.4 V', '1.2 V'],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'Electrochemistry',
        subTopic: 'Electrode Potentials',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: [
          'Electrode Potentials',
          'Redox Reactions',
          'Standard Potential'
        ],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0182',
        questionText:
            'The element that does not belong to the same period of the remaining elements (modern periodic table) is:',
        options: ['Iridium', 'Platinum', 'Osmium', 'Palladium'],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Periodic Table',
        subTopic: 'Periods and Groups',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Periodic Table', 'Periods', 'Elements'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0183',
        questionText: 'Match the LIST-I with LIST-II',
        options: [
          'A-IV, B-I, C-III, D-II',
          'A-IV, B-II, C-I, D-III',
          'A-II, B-IV, C-III, D-I',
          'A-III, B-II, C-I, D-IV'
        ],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'Organic Chemistry',
        subTopic: 'Functional Groups',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Functional Groups', 'Organic Compounds', 'Classification'],
        questionType: 'matching',
      ),

      Question(
        id: 'CHEM0184',
        questionText:
            'What amount of bromine will be required to convert 2 g of phenol into 2,4,6-tribromophenol? (Given molar mass in gmol⁻¹ of C,H,O,Br are 12,1,16,80 respectively)',
        options: ['20.44 g', '4.0 g', '6.0 g', '10.22 g'],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Organic Chemistry',
        subTopic: 'Stoichiometry',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Stoichiometry', 'Bromination', 'Phenol'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0185',
        questionText:
            'Which among the following react with Hinsberg\'s reagent?',
        options: [
          'A, B and E Only',
          'A, C and E Only',
          'C and D Only',
          'B and D Only'
        ],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'Organic Chemistry',
        subTopic: 'Reagents',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Hinsberg\'s Reagent', 'Amines', 'Reactivity'],
        questionType: 'multiple',
      ),

      Question(
        id: 'CHEM0186',
        questionText:
            'The correct set of ions (aqueous solution) with same colour from the following is:',
        options: [
          'Sc³⁺, Ti³⁺, Cr²⁺',
          'V²⁺, Cr³⁺, Mn³⁺',
          'Ti⁴⁺, V⁴⁺, Mn²⁺',
          'Zn²⁺, V³⁺, Fe³⁺'
        ],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'd and f Block Elements',
        subTopic: 'Colour of Ions',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Transition Metals', 'Colour', 'Aqueous Solutions'],
        questionType: 'numerical',
      ),
      Question(
        id: 'CHEM0187',
        questionText:
            'Given below are two statements: Statement I: In Lassaigne\'s test, the covalent organic molecules are transformed into ionic compounds. Statement II: The sodium fusion extract of an organic compound having N and S gives prussian blue colour with FeSO₄ and Na₄[Fe(CN)₆]. In the light of the above statements, choose the correct answer from the options given below.',
        options: [
          'Statement I is true but Statement II is false',
          'Both Statement I and Statement II are false',
          'Both Statement I and Statement II are true',
          'Statement I is false but Statement II is true'
        ],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Purification and Characterisation of Organic Compounds',
        subTopic: 'Lassaigne\'s Test',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: [
          'Lassaigne\'s Test',
          'Sodium Fusion Extract',
          'Qualitative Analysis'
        ],
        questionType: 'multiple',
      ),

      Question(
        id: 'CHEM0188',
        questionText:
            'Propane molecule on chlorination under photochemical condition gives two di-chloro products, "x" and "y". Amongst "x" and "y", "x" is an optically active molecule. How many tri-chloro products (consider only structural isomers) will be obtained from "x" when it is further treated with chlorine under the photochemical condition?',
        options: ['2', '5', '4', '3'],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Hydrocarbons',
        subTopic: 'Halogenation',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Halogenation', 'Structural Isomers', 'Optical Activity'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0189',
        questionText:
            'CrCl₃·xNH₃ can exist as a complex. 0.1 molal aqueous solution of this complex shows a depression in freezing point of 0.558°C. Assuming 100% ionisation of this complex and coordination number of Cr is 6, the complex will be (Given Kf = 1.86 K kg mol⁻¹)',
        options: [
          '[Cr(NH₃)₅Cl]Cl₂',
          '[Cr(NH₃)₆]Cl₃',
          '[Cr(NH₃)₃Cl₃]',
          '[Cr(NH₃)₄Cl₂]Cl'
        ],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Coordination Compounds',
        subTopic: 'Complex Formation',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: [
          'Coordination Compounds',
          'Freezing Point Depression',
          'Ionisation'
        ],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0190',
        questionText:
            'Which of the following happens when NH₄OH is added gradually to the solution containing 1 M A²⁺ and 1 M B³⁺ ions? Given: Ksp[A(OH)₂] = 9×10⁻¹⁰ and Ksp[B(OH)₃] = 27×10⁻¹⁸ at 298 K.',
        options: [
          'Both A(OH)₂ and B(OH)₃ do not show precipitation with NH₄OH',
          'A(OH)₂ will precipitate before B(OH)₃',
          'B(OH)₃ will precipitate before A(OH)₂',
          'A(OH)₂ and B(OH)₃ will precipitate together'
        ],
        correctAnswerIndex: 2,
        subject: 'Chemistry',
        topic: 'Equilibrium',
        subTopic: 'Solubility Product',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Solubility Product', 'Precipitation', 'Hydroxides'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0191',
        questionText:
            'The major product of the following reaction is: CH₃CH₂CHO + excess HCHO + alkali → ? (reflux)',
        options: [
          'HOCH₂C(CH₂OH)₂CHO',
          'CH₃CH₂CH(OH)CH₂OH',
          'CH₃CH₂COOH',
          'CH₂=CHCHO'
        ],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Organic Compounds Containing Oxygen',
        subTopic: 'Aldol Condensation',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Aldol Condensation', 'Formaldehyde', 'Crossed Aldol'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0192',
        questionText:
            'Ice at -5°C is heated to become vapor with temperature of 110°C at atmospheric pressure. The entropy change associated with this process can be obtained from',
        options: [
          'ΔS = ∫(Cp(ice)/T)dT + ΔHfusion/T + ∫(Cp(water)/T)dT + ΔHvap/T + ∫(Cp(steam)/T)dT',
          'ΔS = ∫(Cp(ice)/T)dT + ΔHfusion/Tm + ∫(Cp(water)/T)dT + ΔHvap/Tb + ∫(Cp(steam)/T)dT',
          'ΔS = Cp(ice)ln(T2/T1) + ΔHfusion/Tm + Cp(water)ln(T2/T1) + ΔHvap/Tb + Cp(steam)ln(T2/T1)',
          'ΔS = ΔHfusion/Tm + ΔHvap/Tb'
        ],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'Chemical Thermodynamics',
        subTopic: 'Entropy Change',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Entropy', 'Phase Transitions', 'Thermodynamics'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0193',
        questionText: 'The incorrect statement among the following is',
        options: [
          'PH₃ shows lower proton affinity than NH₃',
          'SO₂ can act as an oxidizing agent, but not as a reducing agent',
          'PF₃ exists but NF₅ does not',
          'NO₂ can dimerise easily'
        ],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'p-Block Elements',
        subTopic: 'Chemical Properties',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: [
          'p-Block Elements',
          'Chemical Properties',
          'Oxidizing/Reducing Agents'
        ],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0194',
        questionText:
            '2.8×10⁻³ mol of CO₂ is left after removing 10²¹ molecules from its "x" mg sample. The mass of CO₂ taken initially is (Given: Nₐ = 6.02×10²³ mol⁻¹)',
        options: ['98.3 mg', '48.2 mg', '196.2 mg', '150.4 mg'],
        correctAnswerIndex: 2,
        subject: 'Chemistry',
        topic: 'Some Basic Concepts in Chemistry',
        subTopic: 'Mole Concept',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Mole Concept', 'Avogadro\'s Number', 'Mass Calculation'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0195',
        questionText: 'Match the LIST-I with LIST-II',
        options: [
          'A-II, B-I, C-III, D-IV',
          'A-II, B-III, C-I, D-IV',
          'A-IV, B-I, C-III, D-II',
          'A-IV, B-III, C-I, D-II'
        ],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Chemical Kinetics',
        subTopic: 'Reaction Mechanisms',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Chemical Kinetics', 'Reaction Mechanisms', 'Rate Laws'],
        questionType: 'matching',
      ),

      Question(
        id: 'CHEM0196',
        questionText:
            'Heat treatment of muscular pain involves radiation of wavelength of about 900 nm. Which spectral line of H atom is suitable for this? (Given: Rydberg constant R_H = 105 cm⁻¹, h = 6.6×10⁻³⁴ J s, c = 3×10⁸ m/s)',
        options: [
          'Balmer series, ∞ → 2',
          'Lyman series, ∞ → 1',
          'Paschen series, ∞ → 3',
          'Paschen series, 5 → 3'
        ],
        correctAnswerIndex: 2,
        subject: 'Chemistry',
        topic: 'Atomic Structure',
        subTopic: 'Hydrogen Spectrum',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: [
          'Hydrogen Spectrum',
          'Spectral Series',
          'Wavelength Calculation'
        ],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0197',
        questionText:
            'The d-electronic configuration of an octahedral Co(II) complex having magnetic moment of 3.95 BM is:',
        options: ['t₂g³eg⁰', 't₂g⁶eg¹', 't₂g⁵eg²', 't₂g⁴eg³'],
        correctAnswerIndex: 2,
        subject: 'Chemistry',
        topic: 'd- and f-Block Elements',
        subTopic: 'Magnetic Properties',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: [
          'Magnetic Moment',
          'Crystal Field Theory',
          'd-Orbital Splitting'
        ],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0198',
        questionText:
            'The correct stability order of the following species/molecules is:',
        options: ['q > r > p', 'r > q > p', 'q > p > r', 'p > q > r'],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Chemical Bonding and Molecular Structure',
        subTopic: 'Molecular Stability',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Molecular Stability', 'Resonance', 'Bond Order'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0199',
        questionText:
            'The standard enthalpy and standard entropy of decomposition of N₂O₄ to NO₂ are 55.0 kJ mol⁻¹ and 175.0 J/K/mol respectively. The standard free energy change for this reaction at 25°C in J mol⁻¹ is ______ (Nearest integer)',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Chemical Thermodynamics',
        subTopic: 'Gibbs Free Energy',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Gibbs Free Energy', 'Enthalpy', 'Entropy'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0200',
        questionText:
            'For the thermal decomposition of N₂O₅(g) at constant volume, the following table can be formed, for the reaction mentioned below. 2N₂O₅(g) → 2N₂O₄(g) + O₂(g). x = …×10⁻³ atm [nearest integer] Given: Rate constant for the reaction is 4.606×10⁻² s⁻¹.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Chemical Kinetics',
        subTopic: 'First Order Reactions',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: [
          'Chemical Kinetics',
          'First Order Reactions',
          'Rate Constant'
        ],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0201',
        questionText:
            'During "S" estimation, 160 mg of an organic compound gives 466 mg of barium sulphate. The percentage of Sulphur in the given compound is _______ %. (Given molar mass in gmol⁻¹ of Ba: 137, S: 32, O: 16)',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Purification and Characterisation of Organic Compounds',
        subTopic: 'Elemental Analysis',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: [
          'Elemental Analysis',
          'Sulphur Estimation',
          'Percentage Calculation'
        ],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0202',
        questionText:
            'If 1 mM solution of ethylamine produces pH = 9, then the ionization constant (Kb) of ethylamine is 10⁻ˣ. The value of x is ______ (nearest integer). [The degree of ionization of ethylamine can be neglected with respect to unity.]',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Equilibrium',
        subTopic: 'Base Ionization Constant',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Base Ionization Constant', 'pH Calculation', 'Weak Base'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0203',
        questionText:
            'Consider the following sequence of reactions to produce major product (A). Molar mass of product (A) is ______ gmol⁻¹. (Given molar mass in gmol⁻¹ of C: 12, H: 1, O: 16, Br: 80, N: 14, P: 31)',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Some Basic Principles of Organic Chemistry',
        subTopic: 'Reaction Sequence',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Organic Reactions', 'Molar Mass', 'Reaction Sequence'],
        questionType: 'numerical',
      ),
      Question(
        id: 'MATH0200',
        questionText:
            'For a 3×3 matrix M, let trace(M) denote the sum of all the diagonal elements of M. Let A be a 3×3 matrix such that |A| = 1 and trace(A) = 3. If B = adj(adj(2A)), then the value of |B| + trace(B) equals:',
        options: ['56', '132', '174', '280'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Matrices and Determinants',
        subTopic: 'Adjoint and Trace',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Matrix Trace', 'Adjoint', 'Determinant'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0201',
        questionText:
            'In a group of 3 girls and 4 boys, there are two boys B₁ and B₂. The number of ways, in which these girls and boys can stand in a queue such that all the girls stand together, all the boys stand together, but B₁ and B₂ are not adjacent to each other, is:',
        options: ['96', '144', '120', '72'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Permutations and Combinations',
        subTopic: 'Arrangements',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Permutations', 'Arrangements', 'Adjacency'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0202',
        questionText:
            'Let α, β, γ and δ be the coefficients of x⁷, x⁵, x³ and x respectively in the expansion of (x + √(x³ - 1))⁵ + (x - √(x³ - 1))⁵, x > 1. If u and v satisfy the equations αu + βv = 18 and γu + δv = 20, then u + v equals:',
        options: ['5', '3', '4', '8'],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Binomial Theorem and Its Simple Applications',
        subTopic: 'Binomial Expansion',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Binomial Expansion', 'Coefficients', 'Equations'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0203',
        questionText:
            'Let a line pass through two distinct points P(-2,-1,3) and Q, and be parallel to the vector 3î + 2ĵ + 2k̂. If the distance of the point Q from the point R(1,3,3) is 5, then the square of the area of triangle PQR is equal to:',
        options: ['148', '136', '144', '140'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: '3D Geometry',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['3D Geometry', 'Distance', 'Area of Triangle'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0204',
        questionText:
            'If A and B are two events such that P(A∩B) = 0.1, and P(A|B) and P(B|A) are the roots of the equation 12x² - 7x + 1 = 0, then the value of P(A∪B)/P(A∩B) is:',
        options: ['4/3', '7/4', '5/3', '9/4'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Statistics and Probability',
        subTopic: 'Conditional Probability',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: [
          'Conditional Probability',
          'Probability Rules',
          'Quadratic Roots'
        ],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0205',
        questionText:
            'If ∫eˣ(xsin⁻¹x + sin⁻¹x + x/√(1-x²))dx = g(x) + C, where C is the constant of integration, then g(1/2) equals:',
        options: ['π√e/4', 'π√e/6', 'π√e/3', 'π√e/2'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Integral Calculus',
        subTopic: 'Integration',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: [
          'Integration',
          'Inverse Trigonometric Functions',
          'Exponential Functions'
        ],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0206',
        questionText:
            'The area of the region enclosed by the curves y = x² - 4x + 4 and y² = 16 - 8x is:',
        options: ['8/3', '4/3', '8', '5'],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Integral Calculus',
        subTopic: 'Area between Curves',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Area between Curves', 'Parabola', 'Integration'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0207',
        questionText:
            'Let f(x) = ∫₀ˣ² (t² - 8t + 15)/eᵗ dt, x ∈ R. Then the numbers of local maximum and local minimum points of f, respectively, are:',
        options: ['2 and 3', '2 and 2', '3 and 2', '1 and 3'],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Differential Calculus',
        subTopic: 'Maxima and Minima',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Maxima and Minima', 'Integration', 'Critical Points'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0208',
        questionText:
            'Let P(4,4√3) be a point on the parabola y² = 4ax and PQ be a focal chord of the parabola. If M and N are the foot of perpendiculars drawn from P and Q respectively on the directrix of the parabola, then the area of the quadrilateral PQMN is equal to:',
        options: ['17√3', '263√3/8', '34√3/3', '343√3/8'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: 'Parabola',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Parabola', 'Focal Chord', 'Area'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0209',
        questionText:
            'Let a and b be two unit vectors such that the angle between them is π/3. If λa + 2b and 3a - λb are perpendicular to each other, then the number of values of λ in [-1,3] is:',
        options: ['2', '1', '0', '3'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Vector Algebra',
        subTopic: 'Dot Product',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Vectors', 'Dot Product', 'Perpendicular Vectors'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0210',
        questionText:
            'If lim(x→∞) ((1 - e/x)(1/x - 1/(x+e)))ˣ = α, then the value of 1 + logₑα equals:',
        options: ['e⁻¹', 'e²', 'e⁻²', 'e'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Limit, Continuity and Differentiability',
        subTopic: 'Limits',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Limits', 'Exponential Limits', 'Logarithms'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0211',
        questionText:
            'Let A = {1,2,3,4} and B = {1,4,9,16}. Then the number of many-one functions f: A → B such that 1 ∈ f(A) is equal to:',
        options: ['151', '139', '163', '127'],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Sets, Relations and Functions',
        subTopic: 'Functions',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Functions', 'Many-one Functions', 'Set Theory'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0212',
        questionText:
            'Suppose that the number of terms in an A.P. is 2k, k ∈ N. If the sum of all odd terms of the A.P. is 40, the sum of all even terms is 55 and the last term of the A.P. exceeds the first term by 27, then k is equal to:',
        options: ['6', '5', '8', '4'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Sequence and Series',
        subTopic: 'Arithmetic Progression',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Arithmetic Progression', 'Sum of Terms', 'Odd-Even Terms'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0213',
        questionText:
            'The perpendicular distance, of the line (x-1)/2 = (y+2)/-1 = (z+3)/2 from the point P(2,-10,1), is:',
        options: ['6', '5√2', '4√3', '3√5'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Three Dimensional Geometry',
        subTopic: 'Distance from Point to Line',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['3D Geometry', 'Distance', 'Line in Space'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0214',
        questionText:
            'If the system of linear equations: x + y + 2z = 6, 2x + 3y + az = a + 1, -x - 3y + bz = 2, where a,b ∈ R, has infinitely many solutions, then 7a + 3b is equal to:',
        options: ['16', '12', '22', '9'],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Matrices and Determinants',
        subTopic: 'System of Equations',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: [
          'System of Equations',
          'Infinitely Many Solutions',
          'Determinant'
        ],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0215',
        questionText:
            'If x = f(y) is the solution of the differential equation (1+y²) + (x - 2e^(tan⁻¹y))dy/dx = 0, y ∈ (-π/2, π/2) with f(0) = 1, then f(1/√3) is equal to:',
        options: ['e^(π/12)', 'e^(π/4)', 'e^(π/3)', 'e^(π/6)'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Differential Equations',
        subTopic: 'First Order DE',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: [
          'Differential Equations',
          'Integration',
          'Inverse Trigonometric Functions'
        ],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0216',
        questionText:
            'Let α(θ) and β(θ) be the distinct roots of 2x² + (cosθ)x - 1 = 0, θ ∈ (0,2π). If m and M are the minimum and the maximum values of α⁴(θ) + β⁴(θ), then 16(M + m) equals:',
        options: ['24', '25', '17', '27'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Complex Numbers and Quadratic Equations',
        subTopic: 'Quadratic Equations',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Quadratic Equations', 'Roots', 'Maxima Minima'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0217',
        questionText:
            'The sum of all values of θ ∈ [0,2π] satisfying 2sin²θ = cos2θ and 2cos²θ = 3sinθ is:',
        options: ['4π', '5π/6', 'π', 'π/2'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Trigonometry',
        subTopic: 'Trigonometric Equations',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: [
          'Trigonometric Equations',
          'Multiple Angles',
          'Sum of Solutions'
        ],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0218',
        questionText:
            'Let the curve z(1+i) + z̄(1-i) = 4, z ∈ C, divide the region |z-3| ≤ 1 into two parts of areas α and β. Then |α - β| equals:',
        options: ['1 + π/2', '1 + π/3', '1 + π/6', '1 + π/4'],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Complex Numbers',
        subTopic: 'Geometry in Complex Plane',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Complex Numbers', 'Geometry', 'Area'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0219',
        questionText:
            'Let E: x²/a² + y²/b² = 1, a > b and H: x²/A² - y²/B² = 1. Let the distance between the foci of E and the foci of H be 2√3. If a - A = 2, and the ratio of the eccentricities of E and H is 1/3, then the sum of the lengths of their latus rectums is equal to:',
        options: ['10', '9', '8', '7'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: 'Conic Sections',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Ellipse', 'Hyperbola', 'Latus Rectum'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0220',
        questionText:
            'If ∑(r=1 to 30) [r²(³⁰Cᵣ)²/(³⁰Cᵣ₋₁)] = α × 2²⁹, then α is equal to ______',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Binomial Theorem and Its Simple Applications',
        subTopic: 'Binomial Coefficients',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Binomial Coefficients', 'Summation', 'Combinatorics'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0221',
        questionText:
            'Let A = {1,2,3}. The number of relations on A, containing (1,2) and (2,3), which are reflexive and transitive but not symmetric, is ______',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Sets, Relations and Functions',
        subTopic: 'Relations',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Relations', 'Reflexive', 'Transitive', 'Symmetric'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0222',
        questionText:
            'Let A(6,8), B(10cosα, -10sinα) and C(-10sinα, 10cosα) be the vertices of a triangle. If L(a,9) and G(h,k) be its orthocenter and centroid respectively, then (5a - 3h + 6k + 100sin2α) is equal to ______',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: 'Triangle Properties',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: [
          'Triangle',
          'Orthocenter',
          'Centroid',
          'Coordinate Geometry'
        ],
        questionType: 'numerical',
      ),
      Question(
        id: 'MATH0223',
        questionText:
            'Let y = f(x) be the solution of the differential equation dy/dx + (xy)/(x²-1) = (x⁶+4x)/√(1-x²), -1 < x < 1 such that f(0) = 0. If 6∫₋₁/₂¹/₂ f(x)dx = 2π - α then α² is equal to _______',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Differential Equations',
        subTopic: 'First Order Linear DE',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: [
          'Differential Equations',
          'Integration',
          'Definite Integral'
        ],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0224',
        questionText:
            'Let the distance between two parallel lines be 5 units and a point P lie between the lines at a unit distance from one of them. An equilateral triangle PQR is formed such that Q lies on one of the parallel lines, while R lies on the other. Then (QR)² is equal to _______',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: 'Lines and Triangles',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: [
          'Coordinate Geometry',
          'Parallel Lines',
          'Equilateral Triangle'
        ],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0199',
        questionText:
            'To obtain the given truth table, following logic gate should be placed at G:',
        options: ['OR Gate', 'AND Gate', 'NOR Gate', 'NAND Gate'],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Electronic Devices',
        subTopic: 'Logic Gates',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Logic Gates', 'Truth Table', 'Digital Electronics'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0200',
        questionText:
            'A small rigid spherical ball of mass M is dropped in a long vertical tube containing glycerine. The velocity of the ball becomes constant after some time. If the density of glycerine is half of the density of the ball, then the viscous force acting on the ball will be (consider g as acceleration due to gravity)',
        options: ['2Mg', 'Mg', '3Mg/2', 'Mg/2'],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Properties of Solids and Liquids',
        subTopic: 'Viscosity',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Viscous Force', 'Terminal Velocity', 'Buoyancy'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0201',
        questionText:
            'The torque due to the force (2î + ĵ + 2k̂) about the origin, acting on a particle whose position vector is (î + ĵ + k̂), would be',
        options: ['î - k̂', 'î + k̂', 'ĵ + k̂', 'î - ĵ + k̂'],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Mechanics',
        subTopic: 'Torque',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Torque', 'Cross Product', 'Vectors'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0202',
        questionText:
            'A symmetric thin biconvex lens is cut into four equal parts by two planes AB and CD as shown in figure. If the power of original lens is 4 D then the power of a part of the divided lens is',
        options: ['1 D', '8 D', '2 D', '4 D'],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Optics',
        subTopic: 'Lens Power',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Lens Power', 'Biconvex Lens', 'Optics'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0203',
        questionText:
            'For a short dipole placed at origin O, the dipole moment P is along x-axis. If the electric potential and electric field at A are V₀ and E₀ respectively, then the correct combination of the electric potential and electric field at point B on the y-axis is given by',
        options: [
          'V₀/4 and E₀',
          'zero and E₀/16',
          'zero and E₀/8',
          'V₀/2 and E₀/16'
        ],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Electrostatics',
        subTopic: 'Electric Dipole',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Electric Dipole', 'Electric Potential', 'Electric Field'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0204',
        questionText:
            'A transparent film of refractive index 2.0 is coated on a glass slab of refractive index 1.45. What is the minimum thickness of transparent film to be coated for the maximum transmission of Green light of wavelength 550 nm. [Assume that the light is incident nearly perpendicular to the glass surface.]',
        options: ['137.5 nm', '275 nm', '94.8 nm', '68.7 nm'],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Optics',
        subTopic: 'Thin Film Interference',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Thin Film Interference', 'Refractive Index', 'Wavelength'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0205',
        questionText:
            'Given are statements for certain thermodynamic variables: (A) Internal energy, volume (V) and mass (M) are extensive variables. (B) Pressure (P), temperature (T) and density (ρ) are intensive variables. (C) Volume (V), temperature (T) and density (ρ) are intensive variables. (D) Mass (M), temperature (T) and internal energy are extensive variables.',
        options: [
          '(B) and (C) Only',
          '(C) and (D) Only',
          '(D) and (A) Only',
          '(A) and (B) Only'
        ],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Thermodynamics',
        subTopic: 'Thermodynamic Variables',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: [
          'Extensive Variables',
          'Intensive Variables',
          'Thermodynamics'
        ],
        questionType: 'multiple',
      ),

      Question(
        id: 'PHY0206',
        questionText:
            'An electron projected perpendicular to a uniform magnetic field B moves in a circle. If Bohr\'s quantization is applicable, then the radius of the electronic orbit in the first excited state is:',
        options: ['√(h/πeB)', '√(2h/πeB)', '√(h/2πeB)', '√(4h/πeB)'],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Modern Physics',
        subTopic: 'Bohr Quantization',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Bohr Quantization', 'Magnetic Field', 'Circular Motion'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0207',
        questionText:
            'Given below are two statements. One is labelled as Assertion (A) and the other is labelled as Reason (R). Assertion (A): In Young\'s double slit experiment, the fringes produced by red light are closer as compared to those produced by blue light. Reason (R): The fringe width is directly proportional to the wavelength of light.',
        options: [
          'Both (A) and (R) are true but (R) is NOT the correct explanation of (A)',
          '(A) is true but (R) is false',
          'Both (A) and (R) are true and (R) is the correct explanation of (A)',
          '(A) is false but (R) is true'
        ],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Optics',
        subTopic: 'Interference',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Young\'s Double Slit', 'Fringe Width', 'Wavelength'],
        questionType: 'multiple',
      ),

      Question(
        id: 'PHY0208',
        questionText:
            'A rectangular metallic loop is moving out of a uniform magnetic field region to a field free region with a constant speed. When the loop is partially inside the magnetic field, the plot of magnitude of induced emf (ε) with time (t) is given by',
        options: [
          'Constant emf',
          'Linearly increasing emf',
          'Parabolic emf',
          'Linearly decreasing emf'
        ],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Electromagnetic Induction',
        subTopic: 'Induced EMF',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: [
          'Electromagnetic Induction',
          'Motional EMF',
          'Faraday\'s Law'
        ],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0209',
        questionText:
            'A ball of mass 100 g is projected with velocity 20 m/s at 60° with horizontal. The decrease in kinetic energy of the ball during the motion from point of projection to highest point is',
        options: ['5 J', '15 J', '20 J', 'zero'],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Mechanics',
        subTopic: 'Projectile Motion',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: [
          'Projectile Motion',
          'Kinetic Energy',
          'Conservation of Energy'
        ],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0210',
        questionText:
            'A body of mass 100 g is moving in circular path of radius 2 m on vertical plane. The velocity of the body at point A is 10 m/s. The ratio of its kinetic energies at point B and C is: (Take acceleration due to gravity as 10 m/s²)',
        options: ['(2+√2)/3', '(2+√3)/3', '(3+√3)/2', '(3-√2)/2'],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Mechanics',
        subTopic: 'Circular Motion',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Circular Motion', 'Kinetic Energy', 'Vertical Circle'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0211',
        questionText:
            'Given below are two statements. One is labelled as Assertion (A) and the other is labelled as Reason (R). Assertion (A): A simple pendulum is taken to a planet of mass and radius, 4 times and 2 times, respectively, than the Earth. The time period of the pendulum remains same on earth and the planet. Reason (R): The mass of the pendulum remains unchanged at Earth and the other planet.',
        options: [
          '(A) is false but (R) is true',
          '(A) is true but (R) is false',
          'Both (A) and (R) are true and (R) is the correct explanation of (A)',
          'Both (A) and (R) are true but (R) is NOT the correct explanation of (A)'
        ],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Gravitation',
        subTopic: 'Simple Pendulum',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: [
          'Simple Pendulum',
          'Time Period',
          'Gravitational Acceleration'
        ],
        questionType: 'multiple',
      ),

      Question(
        id: 'PHY0212',
        questionText:
            'A series LCR circuit is connected to an alternating source of emf E. The current amplitude at resonant frequency is I₀. If the value of resistance R becomes twice of its initial value then amplitude of current at resonance will be',
        options: ['2I₀', 'I₀', 'I₀/2', 'I₀/√2'],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Alternating Current',
        subTopic: 'LCR Circuit',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['LCR Circuit', 'Resonance', 'Current Amplitude'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0213',
        questionText:
            'Which one of the following is the correct dimensional formula for the capacitance in F? M,L,T and C stand for unit of mass, length, time and charge.',
        options: ['[C²M⁻¹L⁻²T²]', '[C²M⁻²L²T²]', '[CM⁻²L⁻²T⁻²]', '[CM⁻¹L⁻²T²]'],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Units and Measurements',
        subTopic: 'Dimensional Analysis',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Dimensional Analysis', 'Capacitance', 'Units'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0214',
        questionText:
            'A tube of length L is shown in the figure. The radius of cross section at point 1 is 2 cm and at point 2 is 1 cm. If the velocity of water entering at point 1 is 2 m/s, then velocity of water leaving the point 2 will be',
        options: ['4 m/s', '2 m/s', '6 m/s', '8 m/s'],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Fluid Mechanics',
        subTopic: 'Continuity Equation',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Continuity Equation', 'Fluid Flow', 'Velocity'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0215',
        questionText:
            'A light source of wavelength λ illuminates a metal surface and electrons are ejected with maximum kinetic energy of 2 eV. If the same surface is illuminated by a light source of wavelength λ/2, then the maximum kinetic energy of ejected electrons will be (The work function of metal is 1 eV)',
        options: ['3 eV', '2 eV', '6 eV', '5 eV'],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Modern Physics',
        subTopic: 'Photoelectric Effect',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Photoelectric Effect', 'Work Function', 'Kinetic Energy'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0216',
        questionText:
            'The maximum percentage error in the measurement of density of a wire is [Given: mass of wire = (0.60±0.003)g, radius of wire = (0.50±0.01)cm, length of wire = (10.00±0.05)cm]',
        options: ['8', '5', '4', '7'],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Units and Measurements',
        subTopic: 'Error Analysis',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Error Analysis', 'Percentage Error', 'Density'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0217',
        questionText:
            'For a diatomic gas, if γ₁ = (Cp/Cv) for rigid molecules and γ₂ = (Cp/Cv) for another diatomic molecules, but also having vibrational modes. Then, which one of the following options is correct?',
        options: ['γ₂ = γ₁', '2γ₂ = γ₁', 'γ₂ < γ₁', 'γ₂ > γ₁'],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Thermodynamics',
        subTopic: 'Specific Heats',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Specific Heats', 'Diatomic Gas', 'Vibrational Modes'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0218',
        questionText:
            'A force F = 2î + bĵ + k̂ is applied on a particle and it undergoes a displacement î - 2ĵ - k̂. What will be the value of b, if work done on the particle is zero.',
        options: ['0', '1/2', '2', '3'],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Mechanics',
        subTopic: 'Work',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Work', 'Dot Product', 'Force and Displacement'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0219',
        questionText:
            'A proton is moving undeflected in a region of crossed electric and magnetic fields at a constant speed of 2×10⁵ m/s. When the electric field is switched off, the proton moves along a circular path of radius 2 cm. The magnitude of electric field is x×10⁴ N/C. The value of x is _______',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Electromagnetism',
        subTopic: 'Crossed Fields',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Crossed Fields', 'Proton Motion', 'Circular Path'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0220',
        questionText:
            'The net current flowing in the given circuit is _______ A.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Current Electricity',
        subTopic: 'Circuit Analysis',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Circuit Analysis', 'Current', 'Resistors'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0221',
        questionText:
            'A parallel plate capacitor of area A = 16 cm² and separation between the plates 10 cm, is charged by a DC current. Consider a hypothetical plane surface of area A₀ = 3.2 cm² inside the capacitor and parallel to the plates. At an instant, the current through the circuit is 6A. At the same instant the displacement current through A₀ is ________ mA.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Electromagnetism',
        subTopic: 'Displacement Current',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Displacement Current', 'Capacitor', 'Maxwell\'s Equations'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0222',
        questionText:
            'A tube of length 1 m is filled completely with an ideal liquid of mass 2M, and closed at both ends. The tube is rotated uniformly in horizontal plane about one of its ends. If the force exerted by the liquid at the other end is F then angular velocity of the tube is √(F/αM) in SI unit. The value of α is __________.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Mechanics',
        subTopic: 'Rotational Motion',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Rotational Motion', 'Centrifugal Force', 'Fluid Mechanics'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0223',
        questionText:
            'Two long parallel wires X and Y, separated by a distance of 6 cm, carry currents of 5A and 4A respectively in opposite directions. Magnitude of the resultant magnetic field at point P at a distance of 4 cm from wire Y is x×10⁻⁵ T. The value of x is __________.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Magnetism',
        subTopic: 'Magnetic Field due to Wires',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Magnetic Field', 'Parallel Wires', 'Superposition'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0225',
        questionText:
            'Let a₁, a₂, a₃, … be a G.P. of increasing positive terms. If a₁a₅ = 28 and a₂ + a₄ = 29, then a₆ is equal to:',
        options: ['628', '812', '526', '784'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Sequence and Series',
        subTopic: 'Geometric Progression',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Geometric Progression', 'Terms', 'Product and Sum'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0226',
        questionText:
            'Let x = x(y) be the solution of the differential equation y²dx + (x - 1/y)dy = 0. If x(1) = 1, then x(1/2) is:',
        options: ['1 + e', '(3 + e)/2', '3 - e', '(3 + e)/2'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Differential Equations',
        subTopic: 'First Order DE',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: [
          'Differential Equations',
          'Initial Value Problem',
          'Solution'
        ],
        questionType: 'numerical',
      ),
      Question(
        id: 'MATH0227',
        questionText:
            'Two balls are selected at random one by one without replacement from a bag containing 4 white and 6 black balls. If the probability that the first selected ball is black, given that the second selected ball is also black, is m/n, where gcd(m,n) = 1, then m+n is equal to:',
        options: ['4', '14', '13', '11'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Statistics and Probability',
        subTopic: 'Conditional Probability',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: [
          'Conditional Probability',
          'Without Replacement',
          'Probability'
        ],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0228',
        questionText:
            'The product of all solutions of the equation e^(5(logₑx)²+3 = x⁸, x > 0, is:',
        options: ['e^(8/5)', 'e^(6/5)', 'e²', 'e'],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Algebra',
        subTopic: 'Exponential Equations',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Exponential Equations', 'Logarithms', 'Product of Roots'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0229',
        questionText:
            'Let the triangle PQR be the image of the triangle with vertices (1,3), (3,1) and (2,4) in the line x+2y = 2. If the centroid of triangle PQR is the point (α,β), then 15(α−β) is equal to:',
        options: ['19', '24', '21', '22'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: 'Reflection',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Reflection', 'Centroid', 'Coordinate Geometry'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0230',
        questionText:
            'Let for f(x) = 7tan⁸x + 7tan⁶x − 3tan⁴x − 3tan²x, I₁ = ∫₀^(π/4) f(x)dx and I₂ = ∫₀^(π/4) xf(x)dx. Then 7I₁ + 12I₂ is equal to:',
        options: ['2', '1', '2π', 'π'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Integral Calculus',
        subTopic: 'Definite Integrals',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: [
          'Definite Integrals',
          'Trigonometric Functions',
          'Integration'
        ],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0231',
        questionText:
            'Let the parabola y = x² + px − 3, meet the coordinate axes at the points P, Q and R. If the circle C with centre at (−1,−1) passes through the points P, Q and R, then the area of triangle PQR is:',
        options: ['7', '4', '6', '5'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: 'Parabola and Circle',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Parabola', 'Circle', 'Area of Triangle'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0232',
        questionText:
            'Let L₁: (x-2)/1 = (y-3)/2 = (z-4)/3 and L₂: (x-3)/2 = (y-4)/4 = (z-5)/5 be two lines. Then which of the following points lies on the line of the shortest distance between L₁ and L₂?',
        options: ['(1/3, 1/3, 1/3)', '(-5,-7,1)', '(2,3,4)', '(3,4,5)'],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Three Dimensional Geometry',
        subTopic: 'Shortest Distance',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Shortest Distance', 'Lines in 3D', 'Geometry'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0233',
        questionText:
            'Let f(x) be a real differentiable function such that f(0) = 1 and f(x+y) = f(x)f′(y) + f′(x)f(y) for all x,y ∈ R. Then ∑ₙ₌₁¹⁰⁰ logₑf(n) is equal to:',
        options: ['2525', '5220', '2384', '2406'],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Differential Calculus',
        subTopic: 'Functional Equations',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Functional Equations', 'Differentiation', 'Summation'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0234',
        questionText:
            'From all the English alphabets, five letters are chosen and are arranged in alphabetical order. The total number of ways, in which the middle letter is M, is:',
        options: ['5148', '6084', '4356', '14950'],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Permutations and Combinations',
        subTopic: 'Combinations',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Combinations', 'Alphabetical Order', 'Selection'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0235',
        questionText:
            'Using the principal values of the inverse trigonometric functions, the sum of the maximum and the minimum values of 16((sec⁻¹x)² + (cosec⁻¹x)²) is:',
        options: ['24π²', '22π²', '31π²', '18π²'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Trigonometry',
        subTopic: 'Inverse Trigonometric Functions',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: [
          'Inverse Trigonometric Functions',
          'Principal Values',
          'Maxima Minima'
        ],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0236',
        questionText:
            'Let f: R → R be a twice differentiable function such that f(x+y) = f(x)f(y) for all x,y ∈ R. If f′(0) = 4a and f satisfies f′′(x) − 3af′(x) − f(x) = 0, a > 0, then the area of the region R = {(x,y) ∣ 0 ≤ y ≤ f(ax), 0 ≤ x ≤ 2} is:',
        options: ['e² − 1', 'e² + 1', 'e⁴ + 1', 'e⁴ − 1'],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Differential Calculus',
        subTopic: 'Functional Equations',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Functional Equations', 'Differential Equations', 'Area'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0237',
        questionText:
            'The area of the region, inside the circle (x−2√3)² + y² = 12 and outside the parabola y² = 2√3x is:',
        options: ['3π + 8', '6π − 16', '3π − 8', '6π − 8'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: 'Area between Curves',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Area between Curves', 'Circle', 'Parabola'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0238',
        questionText:
            'Let the foci of a hyperbola be (1,14) and (1,−12). If it passes through the point (1,6), then the length of its latus-rectum is:',
        options: ['24/5', '25/6', '144/5', '288/5'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: 'Hyperbola',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Hyperbola', 'Foci', 'Latus Rectum'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0239',
        questionText:
            'If ∑ᵣ₌₁ⁿ Tᵣ = (2n−1)(2n+1)(4)/(6(2n+3)(2n+5)), then limₙ→∞ ∑ᵣ₌₁ⁿ (1/Tᵣ) is equal to:',
        options: ['0', '2/3', '1', '1/3'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Sequence and Series',
        subTopic: 'Limits of Series',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Series', 'Limits', 'Summation'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0240',
        questionText:
            'A coin is tossed three times. Let X denote the number of times a tail follows a head. If μ and σ² denote the mean and variance of X, then the value of 64(μ+σ²) is:',
        options: ['51', '64', '32', '48'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Statistics and Probability',
        subTopic: 'Probability Distribution',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Probability Distribution', 'Mean', 'Variance'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0241',
        questionText:
            'The number of non-empty equivalence relations on the set {1,2,3} is:',
        options: ['6', '5', '7', '4'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Sets, Relations and Functions',
        subTopic: 'Equivalence Relations',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Equivalence Relations', 'Set Theory', 'Relations'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0242',
        questionText:
            'A circle C of radius 2 lies in the second quadrant and touches both the coordinate axes. Let r be the radius of a circle that has centre at the point (2,5) and intersects the circle C at exactly two points. If the set of all possible values of r is the interval (α,β), then 3β−2α is equal to:',
        options: ['10', '15', '12', '14'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: 'Circles',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Circles', 'Coordinate Geometry', 'Intersection'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0243',
        questionText:
            'Let A = {1,2,3,…,10} and B = {m/n : m,n ∈ A, m < n and gcd(m,n) = 1}. Then n(B) is equal to:',
        options: ['36', '31', '37', '29'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Sets, Relations and Functions',
        subTopic: 'Set Theory',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Set Theory', 'GCD', 'Fractions'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0244',
        questionText:
            'Let z₁, z₂ and z₃ be three complex numbers on the circle |z| = 1 with arg(z₁) = −π/4, arg(z₂) = 0 and arg(z₃) = π/4. If |z₁z̄₂ + z₂z̄₃ + z₃z̄₁|² = α + β√2, α,β ∈ Z, then the value of α² + β² is:',
        options: ['24', '29', '41', '31'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Complex Numbers',
        subTopic: 'Complex Geometry',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Complex Numbers', 'Argument', 'Modulus'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0245',
        questionText:
            'Let A be a square matrix of order 3 such that det(A) = −2 and det(3adj(−6adj(3A))) = 2ᵐ⁺ⁿ ⋅ 3ᵐⁿ, m > n. Then 4m + 2n is equal to _______',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Matrices and Determinants',
        subTopic: 'Determinants',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Determinants', 'Adjoint', 'Matrix Properties'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0246',
        questionText:
            'If ∑ᵣ₌₀⁵ ¹¹C₂ᵣ₊₂/(2r+2) = m/n, gcd(m,n) = 1, then m−n is equal to _______',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Binomial Theorem',
        subTopic: 'Binomial Coefficients',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Binomial Coefficients', 'Summation', 'Combinatorics'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0247',
        questionText:
            'Let c be the projection vector of b = λî + 4k̂, λ > 0, on the vector a = î + 2ĵ + 2k̂. If |a + c| = 7, then the area of the parallelogram formed by the vectors b and c is ________',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Vector Algebra',
        subTopic: 'Projection',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Vector Projection', 'Area of Parallelogram', 'Vectors'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0248',
        questionText:
            'Let the function f(x) = {−3ax² − 2, x < 1; a² + bx, x ≥ 1} be differentiable for all x ∈ R, where a > 1, b ∈ R. If the area of the region enclosed by y = f(x) and the line y = −20 is α + β√3, α,β ∈ Z, then the value of α + β is ________',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Calculus',
        subTopic: 'Differentiability',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Differentiability', 'Area', 'Piecewise Function'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0249',
        questionText:
            'Let L₁: (x−3)/1 = (y+1)/−1 = (z+0)/1 and L₂: (x−2)/2 = y/0 = (z+α)/4, α ∈ R, be two lines which intersect at the point B. If P is the foot of perpendicular from the point A(1,1,−1) on L₂, then the value of 26α(PB)² is _________',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Three Dimensional Geometry',
        subTopic: 'Lines in 3D',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Lines in 3D', 'Foot of Perpendicular', 'Distance'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0224',
        questionText:
            'An electron is made to enter symmetrically between two parallel and equally but oppositely charged metal plates, each of 10 cm length. The electron emerges out of the electric field region with a horizontal component of velocity 10⁶ m/s. If the magnitude of the electric field between the plates is 9.1 V/cm, then the vertical component of velocity of electron is (mass of electron = 9.1×10⁻³¹ kg and charge of electron = 1.6×10⁻¹⁹ C)',
        options: ['0', '1×10⁶ m/s', '16×10⁶ m/s', '16×10⁴ m/s'],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Electrostatics',
        subTopic: 'Motion in Electric Field',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Electric Field', 'Electron Motion', 'Velocity Components'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0225',
        questionText:
            'Given below are two statements: Statement-I: The equivalent emf of two nonideal batteries connected in parallel is smaller than either of the two emfs. Statement-II: The equivalent internal resistance of two nonideal batteries connected in parallel is smaller than the internal resistance of either of the two batteries.',
        options: [
          'Both Statement-I and Statement-II are false',
          'Statement-I is false but Statement-II is true',
          'Both Statement-I and Statement-II are true',
          'Statement-I is true but Statement-II is false'
        ],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Current Electricity',
        subTopic: 'Batteries in Parallel',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Batteries in Parallel', 'EMF', 'Internal Resistance'],
        questionType: 'multiple',
      ),

      Question(
        id: 'PHY0226',
        questionText:
            'A uniform circular disc of radius R and mass M is rotating about an axis perpendicular to its plane and passing through its centre. A small circular part of radius R/2 is removed from the original disc as shown in the figure. Find the moment of inertia of the remaining part of the original disc about the axis as given above.',
        options: ['7MR²/32', '9MR²/32', '17MR²/32', '13MR²/32'],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Rotational Motion',
        subTopic: 'Moment of Inertia',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Moment of Inertia', 'Circular Disc', 'Removed Part'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0227',
        questionText:
            'An amount of ice of mass 10⁻³ kg and temperature −10°C is transformed to vapour of temperature 110°C by applying heat. The total amount of work required for this conversion is, (Take, specific heat of ice = 2100 J/kg·K, specific heat of water = 4180 J/kg·K, specific heat of steam = 1920 J/kg·K, Latent heat of ice = 3.35×10⁵ J/kg and Latent heat of steam = 2.25×10⁶ J/kg)',
        options: ['3043 J', '3024 J', '3003 J', '3022 J'],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Thermodynamics',
        subTopic: 'Heat Transfer',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Heat Transfer', 'Phase Changes', 'Specific Heat'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0228',
        questionText:
            'An electron in the ground state of the hydrogen atom has the orbital radius of 5.3×10⁻¹¹ m while that for the electron in third excited state is 8.48×10⁻¹⁰ m. The ratio of the de Broglie wavelengths of electron in the excited state to that in the ground state is',
        options: ['3', '16', '9', '4'],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Modern Physics',
        subTopic: 'de Broglie Wavelength',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['de Broglie Wavelength', 'Hydrogen Atom', 'Energy States'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0229',
        questionText:
            'A bob of mass m is suspended at a point O by a light string of length l and left to perform vertical motion (circular) as shown in figure. Initially, by applying horizontal velocity v₀ at the point A, the string becomes slack when the bob reaches at the point D. The ratio of the kinetic energy of the bob at the points B and C is ______',
        options: ['1', '2', '4', '3'],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Mechanics',
        subTopic: 'Circular Motion',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Circular Motion', 'Kinetic Energy', 'Vertical Circle'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0230',
        questionText:
            'Given is a thin convex lens of glass (refractive index μ) and each side having radius of curvature R. One side is polished for complete reflection. At what distance from the lens, an object be placed on the optic axis so that the image gets formed on the object itself?',
        options: ['R/μ', 'R/(μ−1)', 'μR', 'R/(2(μ−1))'],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Optics',
        subTopic: 'Lens and Mirror',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Lens', 'Mirror', 'Image Formation'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0231',
        questionText:
            'Which of the following circuits represents a forward biased diode?',
        options: [
          '(A) and (D) only',
          '(B), (D) and (E) only',
          '(C) and (E) only',
          '(B), (C) and (E) only'
        ],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Electronic Devices',
        subTopic: 'Diodes',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Diodes', 'Forward Bias', 'Circuit Analysis'],
        questionType: 'multiple',
      ),

      Question(
        id: 'PHY0232',
        questionText:
            'Sliding contact of a potentiometer is in the middle of the potentiometer wire having resistance Rₚ = 1Ω as shown in the figure. An external resistance of Rₑ = 2Ω is connected via the sliding contact. The electric current in the circuit is:',
        options: ['0.9 A', '1.35 A', '0.3 A', '1.0 A'],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Current Electricity',
        subTopic: 'Potentiometer',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Potentiometer', 'Current', 'Resistance'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0233',
        questionText:
            'A small point of mass m is placed at a distance 2R from the centre O of a big uniform solid sphere of mass M and radius R. The gravitational force on m due to M is F₁. A spherical part of radius R/3 is removed from the big sphere as shown in the figure and the gravitational force on m due to remaining part of M is found to be F₂. The value of ratio F₁ : F₂ is',
        options: ['12 : 11', '11 : 10', '12 : 9', '16 : 9'],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Gravitation',
        subTopic: 'Gravitational Force',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Gravitational Force', 'Sphere', 'Removed Part'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0234',
        questionText:
            'A closed organ and an open organ tube are filled by two different gases having same bulk modulus but different densities ρ₁ and ρ₂, respectively. The frequency of 9th harmonic of closed tube is identical with 4th harmonic of open tube. If the length of the closed tube is 10 cm and the density ratio of the gases is ρ₁ : ρ₂ = 1 : 16, then the length of the open tube is:',
        options: ['15/7 cm', '20/7 cm', '15/9 cm', '20/9 cm'],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Waves',
        subTopic: 'Organ Pipes',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Organ Pipes', 'Harmonics', 'Frequency'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0235',
        questionText:
            'If B is magnetic field and μ₀ is permeability of free space, then the dimensions of (B/μ₀) is',
        options: ['ML²T⁻²A⁻¹', 'MT⁻²A⁻¹', 'L⁻¹A', 'LT⁻²A⁻¹'],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Units and Measurements',
        subTopic: 'Dimensional Analysis',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Dimensional Analysis', 'Magnetic Field', 'Permeability'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0236',
        questionText:
            'A line charge of length a is kept at the center of an edge BC of a cube ABCDEFGH having edge length 2a as shown in the figure. If the density of line charge is λ C per unit length, then the total electric flux through all the faces of the cube will be. (Take, ϵ₀ as the free space permittivity)',
        options: ['λa/2ϵ₀', 'λa/4ϵ₀', 'λa/16ϵ₀', 'λa/8ϵ₀'],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Electrostatics',
        subTopic: 'Electric Flux',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Electric Flux', 'Line Charge', 'Gauss Law'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0237',
        questionText:
            'Given below are two statements: Statement I: In a vernier callipers, one vernier scale division is always smaller than one main scale division. Statement II: The vernier constant is given by one main scale division multiplied by the number of vernier scale divisions.',
        options: [
          'Statement I is true but Statement II is false',
          'Statement I is false but Statement II is true',
          'Both Statement I and Statement II are false',
          'Both Statement I and Statement II are true'
        ],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Units and Measurements',
        subTopic: 'Vernier Callipers',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Vernier Callipers', 'Measurement', 'Instruments'],
        questionType: 'multiple',
      ),

      Question(
        id: 'PHY0238',
        questionText:
            'The work functions of cesium (Cs) and lithium (Li) metals are 1.9 eV and 2.5 eV, respectively. If we incident a light of wavelength 550 nm on these two metal surfaces, then photo-electric effect is possible for the case of',
        options: ['Both Cs and Li', 'Neither Cs nor Li', 'Cs only', 'Li only'],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Modern Physics',
        subTopic: 'Photoelectric Effect',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: [
          'Photoelectric Effect',
          'Work Function',
          'Threshold Wavelength'
        ],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0239',
        questionText:
            'Two spherical bodies of same materials having radii 0.2 m and 0.8 m are placed in same atmosphere. The temperature of the smaller body is 800 K and temperature of the bigger body is 400 K. If the energy radiated from the smaller body is E, the energy radiated from the bigger body is (assume, effect of the surrounding temperature to be negligible)',
        options: ['16E', 'E', '64E', '256E'],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Thermal Physics',
        subTopic: 'Radiation',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Radiation', 'Stefan-Boltzmann Law', 'Temperature'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0240',
        questionText:
            'In the diagram given below, there are three lenses formed. Considering negligible thickness of each of them as compared to |R₁| and |R₂|, i.e., the radii of curvature for upper and lower surfaces of the glass lens, the power of the combination is',
        options: [
          '(1/6)(1/|R₁| − 1/|R₂|)',
          '−(1/6)(1/|R₁| + 1/|R₂|)',
          '(1/6)(1/|R₁| + 1/|R₂|)',
          '−(1/6)(1/|R₁| − 1/|R₂|)'
        ],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Optics',
        subTopic: 'Lens Power',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Lens Power', 'Combination', 'Radius of Curvature'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0241',
        questionText:
            'Given below are two statements: one is labelled as Assertion (A) and the other is labelled as Reason (R). Assertion-(A): If Young\'s double slit experiment is performed in an optically denser medium than air, then the consecutive fringes come closer. Reason-(R): The speed of light reduces in an optically denser medium than air while its frequency does not change.',
        options: [
          'Both (A) and (R) are true but (R) is not the correct explanation of (A)',
          'Both (A) and (R) are true and (R) is the correct explanation of (A)',
          '(A) is true but (R) is false',
          '(A) is false but (R) is true'
        ],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Optics',
        subTopic: 'Interference',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Young\'s Double Slit', 'Fringe Width', 'Refractive Index'],
        questionType: 'multiple',
      ),

      Question(
        id: 'PHY0242',
        questionText:
            'A parallel-plate capacitor of capacitance 40μF is connected to a 100 V power supply. Now the intermediate space between the plates is filled with a dielectric material of dielectric constant K = 2. Due to the introduction of dielectric material, the extra charge and the change in the electrostatic energy in the capacitor, respectively, are',
        options: [
          '4 mC and 0.2 J',
          '8 mC and 2.0 J',
          '2 mC and 0.4 J',
          '2 mC and 0.2 J'
        ],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Electrostatics',
        subTopic: 'Capacitors',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Capacitors', 'Dielectric', 'Energy'],
        questionType: 'numerical',
      ),
      Question(
        id: 'PHY0243',
        questionText:
            'Which of the following resistivity (ρ) v/s temperature (T) curves is most suitable to be used in wire bound standard resistors?',
        options: [
          'Curve showing increasing resistivity with temperature',
          'Curve showing decreasing resistivity with temperature',
          'Curve showing constant resistivity with temperature',
          'Curve showing very small temperature coefficient of resistivity'
        ],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Current Electricity',
        subTopic: 'Resistivity',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: [
          'Resistivity',
          'Temperature Dependence',
          'Standard Resistors'
        ],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0244',
        questionText:
            'The driver sitting inside a parked car is watching vehicles approaching from behind with the help of his side view mirror, which is a convex mirror with radius of curvature R = 2 m. Another car approaches him from behind with a uniform speed of 90 km/hr. When the car is at a distance of 24 m from him, the magnitude of the acceleration of the image of the car in the side view mirror is "a". The value of 100a is _______ m/s².',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Ray Optics',
        subTopic: 'Convex Mirror',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Convex Mirror', 'Image Acceleration', 'Mirror Formula'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0245',
        questionText:
            'Two soap bubbles of radius 2 cm and 4 cm, respectively, are in contact with each other. The radius of curvature of the common surface, in cm, is ______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Properties of Solids and Liquids',
        subTopic: 'Surface Tension',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Soap Bubbles', 'Surface Tension', 'Radius of Curvature'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0246',
        questionText:
            'The position vectors of two 1 kg particles, (A) and (B), are given by r_A = (α₁t²î + α₂tĵ + α₃tk̂) m and r_B = (β₁tî + β₂t²ĵ + β₃tk̂) m, respectively; (α₁ = 1 m/s², α₂ = 3n m/s, α₃ = 2 m/s, β₁ = 2 m/s, β₂ = −1 m/s², β₃ = 4p m/s), where t is time, n and p are constants. At t = 1 s, V_A = V_B and velocities V_A and V_B of the particles are orthogonal to each other. At t = 1 s, the magnitude of angular momentum of particle (A) with respect to the position of particle (B) is √L kg·m²/s. The value of L is _______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'System of Particles and Rotational Motion',
        subTopic: 'Angular Momentum',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: [
          'Angular Momentum',
          'Position Vectors',
          'Orthogonal Velocities'
        ],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0247',
        questionText:
            'Three conductors of same length having thermal conductivity k₁, k₂ and k₃ are connected as shown in figure. Area of cross sections of 1st and 2nd conductor are same and for 3rd conductor it is double of the 1st conductor. The temperatures are given in the figure. In steady state condition, the value of θ is _______ °C. (Given: k₁ = 60 J/s·m·K, k₂ = 120 J/s·m·K, k₃ = 135 J/s·m·K)',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Properties of Solids and Liquids',
        subTopic: 'Thermal Conduction',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Thermal Conduction', 'Steady State', 'Heat Transfer'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0248',
        questionText:
            'A particle is projected at an angle of 30° from horizontal at a speed of 60 m/s. The height traversed by the particle in the first second is h₀ and height traversed in the last second, before it reaches the maximum height, is h₁. The ratio h₀ : h₁ is _________ [Take, g = 10 m/s²]',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Kinematics',
        subTopic: 'Projectile Motion',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Projectile Motion', 'Height Calculation', 'Time Intervals'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0229',
        questionText:
            'Radius of the first excited state of Helium ion is given as: a₀ → radius of first stationary state of hydrogen atom.',
        options: ['r = 4a₀', 'r = 2a₀', 'r = a₀', 'r = a₀/2'],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'Atomic Structure',
        subTopic: 'Atomic Radius',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Helium Ion', 'Excited State', 'Atomic Radius'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0230',
        questionText:
            'The incorrect statements regarding geometrical isomerism are: (A) Propene shows geometrical isomerism. (B) Trans isomer has identical atoms/groups on the opposite sides of the double bond. (C) Cis-but-2-ene has higher dipole moment than trans-but-2-ene. (D) 2-methylbut-2-ene shows two geometrical isomers. (E) Trans-isomer has lower melting point than cis isomer.',
        options: [
          '(A) and (E) Only',
          '(A), (D) and (E) Only',
          '(B) and (C) Only',
          '(C), (D) and (E) Only'
        ],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'Hydrocarbons',
        subTopic: 'Geometrical Isomerism',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Geometrical Isomerism', 'Alkenes', 'Dipole Moment'],
        questionType: 'multiple',
      ),

      Question(
        id: 'CHEM0231',
        questionText:
            'A liquid when kept inside a thermally insulated closed vessel at 25°C was mechanically stirred from outside. What will be the correct option for the following thermodynamic parameters?',
        options: [
          'ΔU < 0, q = 0, w > 0',
          'ΔU = 0, q = 0, w = 0',
          'ΔU > 0, q = 0, w > 0',
          'ΔU = 0, q < 0, w > 0'
        ],
        correctAnswerIndex: 2,
        subject: 'Chemistry',
        topic: 'Chemical Thermodynamics',
        subTopic: 'First Law',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['First Law of Thermodynamics', 'Internal Energy', 'Work'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0232',
        questionText:
            'Which of the following electronegativity order is incorrect?',
        options: [
          'Mg < Be < B < N',
          'S < Cl < O < F',
          'Al < Si < C < N',
          'Al < Mg < B < N'
        ],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Classification of Elements and Periodicity in Properties',
        subTopic: 'Electronegativity',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Electronegativity', 'Periodic Trends', 'Elements'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0233',
        questionText:
            'Lanthanoid ions with 4f⁷ configuration are: (A) Eu²⁺ (B) Gd³⁺ (C) Eu³⁺ (D) Tb³⁺ (E) Sm²⁺',
        options: [
          '(A) and (D) only',
          '(B) and (C) only',
          '(A) and (B) only',
          '(B) and (E) only'
        ],
        correctAnswerIndex: 2,
        subject: 'Chemistry',
        topic: 'd- and f-Block Elements',
        subTopic: 'Lanthanoids',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: [
          'Lanthanoids',
          'Electronic Configuration',
          'f-Block Elements'
        ],
        questionType: 'multiple',
      ),

      Question(
        id: 'CHEM0234',
        questionText:
            'Given below are two statements: Statement I: One mole of propyne reacts with excess of sodium to liberate half a mole of H₂ gas. Statement II: Four g of propyne reacts with NaNH₂ to liberate NH₃ gas which occupies 224 mL at STP.',
        options: [
          'Statement I is incorrect but Statement II is correct',
          'Both Statement I and Statement II are correct',
          'Statement I is correct but Statement II is incorrect',
          'Both Statement I and Statement II are incorrect'
        ],
        correctAnswerIndex: 2,
        subject: 'Chemistry',
        topic: 'Hydrocarbons',
        subTopic: 'Alkynes',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Alkynes', 'Reactivity', 'Gas Volume'],
        questionType: 'multiple',
      ),

      Question(
        id: 'CHEM0235',
        questionText:
            'The compounds which give positive Fehling\'s test are: (A) (B) (C) HOCH₂−CO−(CHOH)₃−CH₂−OH (D) (E)',
        options: [
          '(A), (D) and (E) Only',
          '(C), (D) and (E) Only',
          '(A), (C) and (D) Only',
          '(A), (B) and (C) Only'
        ],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'Biomolecules',
        subTopic: 'Fehling\'s Test',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Fehling\'s Test', 'Reducing Sugars', 'Carbohydrates'],
        questionType: 'multiple',
      ),

      Question(
        id: 'CHEM0236',
        questionText:
            'Which of the following electrolyte can be used to obtain H₂S₂O₈ by the process of electrolysis?',
        options: [
          'Dilute solution of sodium sulphate',
          'Acidified dilute solution of sodium sulphate',
          'Dilute solution of sulphuric acid',
          'Concentrated solution of sulphuric acid'
        ],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Electrochemistry',
        subTopic: 'Electrolysis',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Electrolysis', 'Peroxodisulphuric Acid', 'Sulphuric Acid'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0237',
        questionText:
            'Given below are two statements: Statement I: CH₃−O−CH₂−Cl will undergo S_N1 reaction though it is a primary halide. Statement II: will not undergo S_N2 reaction very easily though it is a primary halide.',
        options: [
          'Both Statement I and Statement II are incorrect',
          'Both Statement I and Statement II are correct',
          'Statement I is incorrect but Statement II is correct',
          'Statement I is correct but Statement II is incorrect'
        ],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'Haloalkanes and Haloarenes',
        subTopic: 'Reaction Mechanisms',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['S_N1 Reaction', 'S_N2 Reaction', 'Haloalkanes'],
        questionType: 'multiple',
      ),

      Question(
        id: 'CHEM0238',
        questionText: 'Which of the following acids is a vitamin?',
        options: [
          'Adipic acid',
          'Ascorbic acid',
          'Saccharic acid',
          'Aspartic acid'
        ],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'Biomolecules',
        subTopic: 'Vitamins',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Vitamins', 'Ascorbic Acid', 'Biomolecules'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0239',
        questionText:
            'Match List-I with List-II. List-I: (A) Al³⁺ < Mg²⁺ < Na⁺ < F⁻ (B) B < C < O < N (C) B < Al < Mg < K (D) Si < P < S < Cl List-II: (I) Ionisation Enthalpy (II) Metallic character (III) Electronegativity (IV) Ionic radii',
        options: [
          '(A)-(IV), (B)-(I), (C)-(II), (D)-(III)',
          '(A)-(IV), (B)-(I), (C)-(III), (D)-(II)',
          '(A)-(III), (B)-(IV), (C)-(II), (D)-(I)',
          '(A)-(II), (B)-(III), (C)-(IV), (D)-(I)'
        ],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Classification of Elements and Periodicity in Properties',
        subTopic: 'Periodic Trends',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Periodic Trends', 'Ionic Radii', 'Electronegativity'],
        questionType: 'matching',
      ),

      Question(
        id: 'CHEM0240',
        questionText:
            'Which of the following statement is not true for radioactive decay?',
        options: [
          'Decay constant increases with increase in temperature',
          'Amount of radioactive substance remained after three half lives is 1/8th of original amount',
          'Decay constant does not depend upon temperature',
          'Half life is ln2 times of 1/rate constant'
        ],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Nuclear Chemistry',
        subTopic: 'Radioactive Decay',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Radioactive Decay', 'Half Life', 'Decay Constant'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0241',
        questionText:
            'The products formed in the following reaction sequence are:',
        options: [
          'Benzaldehyde and Acetaldehyde',
          'Benzaldehyde and Acetic acid',
          'Benzaldehyde only',
          'Benzaldehyde and Formaldehyde'
        ],
        correctAnswerIndex: 2,
        subject: 'Chemistry',
        topic: 'Aldehydes and Ketones',
        subTopic: 'Reaction Sequence',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Reaction Sequence', 'Aldehydes', 'Organic Reactions'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0242',
        questionText:
            'How many different stereoisomers are possible for the given molecule?',
        options: ['2', '1', '4', '3'],
        correctAnswerIndex: 2,
        subject: 'Chemistry',
        topic: 'Organic Compounds Containing Oxygen',
        subTopic: 'Stereoisomerism',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Stereoisomerism', 'Chirality', 'Optical Isomers'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0243',
        questionText:
            'A vessel at 1000 K contains CO₂ with a pressure of 0.5 atm. Some of CO₂ is converted into CO on addition of graphite. If total pressure at equilibrium is 0.8 atm, then Kp is:',
        options: ['1.8 atm', '0.3 atm', '3 atm', '0.18 atm'],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Equilibrium',
        subTopic: 'Chemical Equilibrium',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Chemical Equilibrium', 'Kp', 'Partial Pressure'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0244',
        questionText:
            'A solution of aluminium chloride is electrolysed for 30 minutes using a current of 2 A. The amount of the aluminium deposited at the cathode is [Given: molar mass of aluminium and chlorine are 27 g/mol and 35.5 g/mol respectively. Faraday constant = 96500 C/mol]',
        options: ['1.660 g', '0.336 g', '0.441 g', '1.007 g'],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'Electrochemistry',
        subTopic: 'Electrolysis',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Electrolysis', 'Faraday\'s Law', 'Aluminium Deposition'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0245',
        questionText: 'The IUPAC name of the following compound is:',
        options: [
          'Methyl-6-carboxy-2,5-dimethylhexanoate',
          '2-Carboxy-5-methoxycarbonylhexane',
          '6-Methoxycarbonyl-2,5-dimethylhexanoic acid',
          'Methyl-5-carboxy-2-methylhexanoate'
        ],
        correctAnswerIndex: 2,
        subject: 'Chemistry',
        topic: 'Organic Compounds Containing Oxygen',
        subTopic: 'IUPAC Nomenclature',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['IUPAC Nomenclature', 'Carboxylic Acids', 'Esters'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0246',
        questionText:
            'In which of the following complexes the CFSE, Δ₀ will be equal to zero?',
        options: [
          '[Fe(en)₃]Cl₃',
          'K₄[Fe(CN)₆]',
          '[Fe(NH₃)₆]Br₂',
          'K₃[Fe(SCN)₆]'
        ],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Coordination Compounds',
        subTopic: 'Crystal Field Theory',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Crystal Field Theory', 'CFSE', 'Coordination Compounds'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0247',
        questionText:
            'Arrange the following solutions in order of their increasing boiling points. (i) 10⁻⁴M NaCl (ii) 10⁻⁴M Urea (iii) 10⁻³M NaCl (iv) 10⁻²M NaCl',
        options: [
          '(i) < (ii) < (iii) < (iv)',
          '(iv) < (iii) < (i) < (ii)',
          '(ii) < (i) ≡ (iii) < (iv)',
          '(ii) < (i) < (iii) < (iv)'
        ],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Solutions',
        subTopic: 'Colligative Properties',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: [
          'Boiling Point Elevation',
          'Colligative Properties',
          'Van\'t Hoff Factor'
        ],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0248',
        questionText:
            'From the magnetic behaviour of [NiCl₄]²⁻ (paramagnetic) and [Ni(CO)₄] (diamagnetic), choose the correct geometry and oxidation state.',
        options: [
          '[NiCl₄]²⁻: Ni(II), tetrahedral; [Ni(CO)₄]: Ni(II), square planar',
          '[NiCl₄]²⁻: Ni(II), square planar; [Ni(CO)₄]: Ni(0), square planar',
          '[NiCl₄]²⁻: Ni(II), tetrahedral; [Ni(CO)₄]: Ni(0), tetrahedral',
          '[NiCl₄]²⁻: Ni(0), tetrahedral; [Ni(CO)₄]: Ni(0), square planar'
        ],
        correctAnswerIndex: 2,
        subject: 'Chemistry',
        topic: 'Coordination Compounds',
        subTopic: 'Magnetic Properties',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Magnetic Properties', 'Geometry', 'Oxidation State'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0249',
        questionText:
            'The number of molecules/ions that show linear geometry among the following is ________ SO₂, BeCl₂, CO₂, N₃⁻, NO₂, F₂O, XeF₂, NO₂⁺, I₃⁻, O₃',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Chemical Bonding and Molecular Structure',
        subTopic: 'Molecular Geometry',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Molecular Geometry', 'Linear Geometry', 'VSEPR Theory'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0250',
        questionText:
            'A → B The molecule A changes into its isomeric form B by following a first order kinetics at a temperature of 1000 K. If the energy barrier with respect to reactant energy for such isomeric transformation is 191.48 kJ/mol and the frequency factor is 10²⁰, the time required for 50% molecules of A to become B is _________ picoseconds (nearest integer). [R = 8.314 J/K·mol]',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Chemical Kinetics',
        subTopic: 'First Order Kinetics',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['First Order Kinetics', 'Half Life', 'Arrhenius Equation'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0251',
        questionText:
            'Consider the following sequence of reactions: Molar mass of the product formed (A) is _______ g/mol.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Some Basic Principles of Organic Chemistry',
        subTopic: 'Reaction Sequence',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Reaction Sequence', 'Molar Mass', 'Organic Synthesis'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0252',
        questionText:
            'Some CO₂ gas was kept in a sealed container at a pressure of 1 atm and at 273 K. This entire amount of CO₂ gas was later passed through an aqueous solution of Ca(OH)₂. The excess unreacted Ca(OH)₂ was later neutralized with 0.1 M of 40 mL HCl. If the volume of the sealed container of CO₂ was x, then x is ________ cm³ (nearest integer). [Given: The entire amount of CO₂(g) reacted with exactly half the initial amount of Ca(OH)₂ present in the aqueous solution.]',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Some Basic Concepts in Chemistry',
        subTopic: 'Stoichiometry',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Stoichiometry', 'Gas Volume', 'Neutralization'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0253',
        questionText:
            'In Carius method for estimation of halogens, 180 mg of an organic compound produced 143.5 mg of AgCl. The percentage composition of chlorine in the compound is _______ %. (Given: molar mass in g/mol of Ag: 108, Cl: 35.5)',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Some Basic Concepts in Chemistry',
        subTopic: 'Percentage Composition',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: [
          'Carius Method',
          'Percentage Composition',
          'Halogen Estimation'
        ],
        questionType: 'numerical',
      ),
      Question(
        id: 'PHY0249',
        questionText:
            'Match List - I with List - II. List - I (Number) List - II (Significant figure) (A) 1001 (I) 3 (B) 010.1 (II) 4 (C) 100.100 (III) 5 (D) 0.0010010 (IV) 6',
        options: [
          '(A)-(III), (B)-(IV), (C)-(II), (D)-(I)',
          '(A)-(IV), (B)-(III), (C)-(I), (D)-(II)',
          '(A)-(II), (B)-(I), (C)-(IV), (D)-(III)',
          '(A)-(I), (B)-(II), (C)-(III), (D)-(IV)'
        ],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Units and Measurements',
        subTopic: 'Significant Figures',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: [
          'Significant Figures',
          'Number Representation',
          'Measurement'
        ],
        questionType: 'matching',
      ),

      Question(
        id: 'PHY0250',
        questionText:
            'Train A is moving along two parallel rail tracks towards north with 72 km/h and train B is moving towards south with speed 108 km/h. Velocity of train B with respect to A and velocity of ground with respect to B are (in m/s):',
        options: ['-30 and 50', '-50 and -30', '-50 and 30', '50 and -30'],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Kinematics',
        subTopic: 'Relative Velocity',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Relative Velocity', 'Vector Addition', 'Speed Conversion'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0251',
        questionText:
            'A cricket player catches a ball of mass 120 g moving with 25 m/s speed. If the catching process is completed in 0.1 s then the magnitude of force exerted by the ball on the hand of player will be (in SI unit):',
        options: ['24', '12', '25', '30'],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Laws of Motion',
        subTopic: 'Impulse',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Impulse', 'Force', 'Momentum Change'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0252',
        questionText:
            'A body of mass 4 kg experiences two forces F₁ = 5î + 8ĵ + 7k̂ and F₂ = 3î - 4ĵ - 3k̂. The acceleration acting on the body is:',
        options: [
          '-2î - ĵ - k̂',
          '4î + 2ĵ + 2k̂',
          '2î + ĵ + k̂',
          '2î + 3ĵ + 3k̂'
        ],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Laws of Motion',
        subTopic: 'Newton\'s Second Law',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Newton\'s Second Law', 'Vector Addition', 'Acceleration'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0253',
        questionText:
            'A disc of radius R and mass M is rolling horizontally without slipping with speed v. It then moves up an inclined smooth surface as shown in figure. The maximum height that the disc can go up the incline is:',
        options: ['v²/g', '3v²/4g', 'v²/2g', '2v²/3g'],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Work, Energy and Power',
        subTopic: 'Conservation of Energy',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: [
          'Conservation of Energy',
          'Rolling Motion',
          'Kinetic Energy'
        ],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0254',
        questionText:
            'A light planet is revolving around a massive star in a circular orbit of radius R with a period of revolution T. If the force of attraction between planet and star is proportional to R^(-3/2) then choose the correct option:',
        options: ['T² ∝ R^(5/2)', 'T² ∝ R^(7/2)', 'T² ∝ R^(3/2)', 'T² ∝ R³'],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Gravitation',
        subTopic: 'Orbital Motion',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Orbital Motion', 'Kepler\'s Laws', 'Gravitational Force'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0255',
        questionText:
            'A big drop is formed by coalescing 1000 small droplets of water. The surface energy will become:',
        options: ['100 times', '10 times', '1/100th', '1/10th'],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Properties of Solids and Liquids',
        subTopic: 'Surface Energy',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Surface Energy', 'Coalescence', 'Surface Tension'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0263',
        questionText:
            'A diatomic gas γ = 1.4 does 200 J of work when it is expanded isobarically. The heat given to the gas in the process is:',
        options: ['850 J', '800 J', '600 J', '700 J'],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Thermodynamics',
        subTopic: 'First Law',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: [
          'First Law of Thermodynamics',
          'Isobaric Process',
          'Heat Transfer'
        ],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0264',
        questionText:
            'If the root mean square velocity of hydrogen molecule at a given temperature and pressure is 2 km/s, the root mean square velocity of oxygen at the same condition in km/s is:',
        options: ['2.0', '0.5', '1.5', '1.0'],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Kinetic Theory of Gases',
        subTopic: 'RMS Velocity',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['RMS Velocity', 'Molecular Speed', 'Temperature Dependence'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0265',
        questionText:
            'C₁ and C₂ are two hollow concentric cubes enclosing charges 2Q and 3Q respectively as shown in figure. The ratio of electric flux passing through C₁ and C₂ is:',
        options: ['2 : 5', '5 : 2', '2 : 3', '3 : 2'],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Electrostatics',
        subTopic: 'Gauss Law',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Gauss Law', 'Electric Flux', 'Charge Enclosed'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0266',
        questionText:
            'A galvanometer G of 2Ω resistance is connected in the given circuit. The ratio of charge stored in C₁ and C₂ is:',
        options: ['2/3', '3/2', '1', '2'],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Current Electricity',
        subTopic: 'Capacitors',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Capacitors', 'Charge Storage', 'Circuit Analysis'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0267',
        questionText:
            'In a metre-bridge when a resistance in the left gap is 2 Ω and unknown resistance in the right gap, the balance length is found to be 40 cm. On shunting the unknown resistance with 2 Ω, the balance length changes by:',
        options: ['22.5 cm', '20 cm', '62.5 cm', '65 cm'],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Current Electricity',
        subTopic: 'Metre Bridge',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: [
          'Metre Bridge',
          'Wheatstone Bridge',
          'Resistance Measurement'
        ],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0268',
        questionText:
            'In an ammeter, 5% of the main current passes through the galvanometer. If resistance of the galvanometer is G, the resistance of ammeter will be:',
        options: ['G/20', 'G/199', '199G', '200G'],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Current Electricity',
        subTopic: 'Ammeter',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Ammeter', 'Shunt Resistance', 'Current Division'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0269',
        questionText:
            'To measure the temperature coefficient of resistivity α of a semiconductor, an electrical arrangement shown in the figure is prepared. The arm BC is made up of the semiconductor. The experiment is being conducted at 25°C and resistance of the semiconductor arm is 3 mΩ. Arm BC is cooled at a constant rate of 2 °C/s. If the galvanometer G shows no deflection after 10 s, then α is:',
        options: [
          '-2×10⁻² °C⁻¹',
          '-1.5×10⁻² °C⁻¹',
          '-1×10⁻² °C⁻¹',
          '-2.5×10⁻² °C⁻¹'
        ],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Current Electricity',
        subTopic: 'Temperature Coefficient',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: [
          'Temperature Coefficient',
          'Semiconductor',
          'Resistance Change'
        ],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0270',
        questionText:
            'A transformer has an efficiency of 80% and works at 10 V and 4 kW. If the secondary voltage is 240 V, then the current in the secondary coil is:',
        options: ['1.59 A', '13.33 A', '1.33 A', '15.1 A'],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Electromagnetic Induction',
        subTopic: 'Transformer',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Transformer', 'Efficiency', 'Power Transfer'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0271',
        questionText:
            'If frequency of electromagnetic wave is 60 MHz and it travels in air along z direction then the corresponding electric and magnetic field vectors will be mutually perpendicular to each other and the wavelength of the wave in m is:',
        options: ['2.5', '10', '5', '2'],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Electromagnetic Waves',
        subTopic: 'Wave Properties',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Electromagnetic Waves', 'Wavelength', 'Frequency'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0272',
        questionText:
            'A microwave of wavelength 2.0 cm falls normally on a slit of width 4.0 cm. The angular spread of the central maxima of the diffraction pattern obtained on a screen 1.5 m away from the slit, will be:',
        options: ['30°', '15°', '60°', '45°'],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Optics',
        subTopic: 'Diffraction',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Diffraction', 'Single Slit', 'Angular Spread'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0273',
        questionText:
            'Monochromatic light of frequency 6×10¹⁴ Hz is produced by a laser. The power emitted is 2×10⁻³ W. How many photons per second on an average, are emitted by the source? (Given h = 6.63×10⁻³⁴ J s)',
        options: ['9×10¹⁸', '6×10¹⁵', '5×10¹⁵', '7×10¹⁶'],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Modern Physics',
        subTopic: 'Photons',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Photons', 'Energy Calculation', 'Power'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0274',
        questionText:
            'From the statements given below: (A) The angular momentum of an electron in nth orbit is an integral multiple of h. (B) Nuclear forces do not obey inverse square law. (C) Nuclear forces are spin dependent. (D) Nuclear forces are central and charge independent. (E) Stability of nucleus is inversely proportional to the value of packing fraction.',
        options: [
          '(A), (B), (C), (D) only',
          '(A), (C), (D), (E) only',
          '(A), (B), (C), (E) only',
          '(B), (C), (D), (E) only'
        ],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Atoms and Nuclei',
        subTopic: 'Nuclear Physics',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Nuclear Forces', 'Atomic Structure', 'Nuclear Stability'],
        questionType: 'multiple',
      ),

      Question(
        id: 'PHY0275',
        questionText:
            'Conductivity of a photodiode starts changing only if the wavelength of incident light is less than 660 nm. The band gap of photodiode is found to be X/8 eV. The value of X is: (Given h = 6.6×10⁻³⁴ J s, e = 1.6×10⁻¹⁹ C)',
        options: ['15', '11', '13', '21'],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Electronic Devices',
        subTopic: 'Photodiode',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Photodiode', 'Band Gap', 'Wavelength'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0276',
        questionText:
            'A particle initially at rest starts moving from reference point x = 0 along x-axis, with velocity v that varies as v = 4√x m/s. The acceleration of the particle is _____ m/s².',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Kinematics',
        subTopic: 'Acceleration',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Acceleration', 'Velocity Relation', 'Differentiation'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0277',
        questionText:
            'A uniform rod AB of mass 2 kg and Length 30 cm at rest on a smooth horizontal surface. An impulse of force 0.2 N s is applied to end B. The time taken by the rod to turn through π/2 at right angles will be π/x s, where x = ____.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Rotational Motion',
        subTopic: 'Angular Motion',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Rotational Motion', 'Impulse', 'Angular Displacement'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0278',
        questionText:
            'One end of a metal wire is fixed to a ceiling and a load of 2 kg hangs from the other end. A similar wire is attached to the bottom of the load and another load of 1 kg hangs from this lower wire. Then the ratio of longitudinal strain of upper wire to that of the lower wire will be [Area of cross section of wire = 0.005 cm², Y = 2×10¹¹ N/m² and g = 10 m/s²]',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Properties of Solids and Liquids',
        subTopic: 'Strain',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Strain', 'Young\'s Modulus', 'Stress'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0279',
        questionText:
            'A mass m is suspended from a spring of negligible mass and the system oscillates with a frequency f₁. The frequency of oscillations if a mass 9m is suspended from the same spring is f₂. The value of f₁/f₂ is _____.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Oscillations and Waves',
        subTopic: 'Spring-Mass System',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Spring-Mass System', 'Frequency', 'Oscillations'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0280',
        questionText:
            'Suppose a uniformly charged wall provides a uniform electric field of 2×10⁴ N/C normally. A charged particle of mass 2 g being suspended through a silk thread of length 20 cm and remain stayed at a distance of 10 cm from the wall. Then the charge on the particle will be 1/x μC where x = ________ [use g = 10 m/s²]',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Electrostatics',
        subTopic: 'Electric Field',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Electric Field', 'Equilibrium', 'Charged Particle'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0281',
        questionText:
            'In an electrical circuit drawn below the amount of charge stored in the capacitor is _______ μC.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Current Electricity',
        subTopic: 'Capacitors',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Capacitors', 'Charge Storage', 'Circuit Analysis'],
        questionType: 'numerical',
      ),
      Question(
        id: 'PHY0282',
        questionText:
            'A moving coil galvanometer has 100 turns and each turn has an area of 2.0 cm². The magnetic field produced by the magnet is 0.01 T and the deflection in the coil is 0.05 radian when a current of 10 mA is passed through it. The torsional constant of the suspension wire is x×10⁻⁵ N·m/rad. The value of x is ______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Magnetic Effects of Current and Magnetism',
        subTopic: 'Moving Coil Galvanometer',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Galvanometer', 'Torsional Constant', 'Magnetic Field'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0283',
        questionText:
            'A coil of 200 turns and area 0.20 m² is rotated at half a revolution per second and is placed in uniform magnetic field of 0.01 T perpendicular to axis of rotation of the coil. The maximum voltage generated in the coil is 2π/β volt. The value of β is ______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Electromagnetic Induction and Alternating Currents',
        subTopic: 'Induced EMF',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Induced EMF', 'Rotating Coil', 'Magnetic Field'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0284',
        questionText:
            'In Young\'s double slit experiment, monochromatic light of wavelength 5000 Å is used. The slits are 1.0 mm apart and screen is placed at 1.0 m away from slits. The distance from the centre of the screen where intensity becomes half of the maximum intensity for the first time is ______ ×10⁻⁶ m.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Optics',
        subTopic: 'Interference',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Young\'s Double Slit', 'Intensity', 'Interference Pattern'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0254',
        questionText:
            'A particular hydrogen-like ion emits the radiation of frequency 3×10¹⁵ Hz when it makes transition from n = 2 to n = 1. The frequency of radiation emitted in transition from n = 3 to n = 1 is (x/9)×10¹⁵ Hz, when x = _____.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Atomic Structure',
        subTopic: 'Hydrogen Spectrum',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Hydrogen Spectrum', 'Energy Levels', 'Frequency'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0255',
        questionText: 'The number of radial node/s for 3p orbital is:',
        options: ['1', '4', '2', '3'],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Atomic Structure',
        subTopic: 'Atomic Orbitals',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Atomic Orbitals', 'Radial Nodes', 'Quantum Numbers'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0256',
        questionText:
            'Given below are two statements: Statement (I): Both metal and non-metal exist in p and d-block elements. Statement (II): Non-metals have higher ionisation enthalpy and higher electronegativity than the metals.',
        options: [
          'Both Statement I and Statement II are false',
          'Statement I is false but Statement II is true',
          'Statement I is true but Statement II is false',
          'Both Statement I and Statement II are true'
        ],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'Classification of Elements and Periodicity in Properties',
        subTopic: 'Periodic Table',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: [
          'Periodic Table',
          'Metals and Non-metals',
          'Periodic Properties'
        ],
        questionType: 'multiple',
      ),

      Question(
        id: 'CHEM0257',
        questionText:
            'Given below are two statements: Statement (I): A π bonding MO has lower electron density above and below the inter-nuclear axis. Statement (II): The π* antibonding MO has a node between the nuclei.',
        options: [
          'Both Statement I and Statement II are false',
          'Both Statement I and Statement II are true',
          'Statement I is false but Statement II is true',
          'Statement I is true but Statement II is false'
        ],
        correctAnswerIndex: 2,
        subject: 'Chemistry',
        topic: 'Chemical Bonding and Molecular Structure',
        subTopic: 'Molecular Orbitals',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Molecular Orbitals', 'π Bonds', 'Antibonding Orbitals'],
        questionType: 'multiple',
      ),

      Question(
        id: 'CHEM0258',
        questionText:
            'Select the compound from the following that will show intramolecular hydrogen bonding.',
        options: ['H₂O', 'NH₃', 'C₂H₅OH', 'Salicylaldehyde'],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Chemical Bonding and Molecular Structure',
        subTopic: 'Hydrogen Bonding',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Hydrogen Bonding', 'Intramolecular', 'Intermolecular'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0259',
        questionText:
            'Solubility of calcium phosphate (molecular mass, M) in water is W g per 100 mL at 25°C. Its solubility product at 25°C will be approximately.',
        options: ['10⁷W³/M⁵', '10⁷W⁵/M⁵', '10³W/M', '10⁵W/M'],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'Equilibrium',
        subTopic: 'Solubility Product',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Solubility Product', 'Calcium Phosphate', 'Solubility'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0260',
        questionText:
            'Match List - I with List - II. List - I Compound List-II Use (A) Carbon tetrachloride (I) Paint remover (B) Methylene chloride (II) Refrigerators and air conditioners (C) DDT (III) Fire extinguisher (D) Freons (IV) Non Biodegradable insecticide',
        options: [
          '(A)-(I), (B)-(II), (C)-(III), (D)-(IV)',
          '(A)-(III), (B)-(I), (C)-(IV), (D)-(II)',
          '(A)-(IV), (B)-(III), (C)-(II), (D)-(I)',
          '(A)-(II), (B)-(III), (C)-(I), (D)-(IV)'
        ],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'Hydrocarbons',
        subTopic: 'Organic Compounds',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Organic Compounds', 'Uses', 'Applications'],
        questionType: 'matching',
      ),

      Question(
        id: 'CHEM0261',
        questionText:
            'Given below are two statements: Statement (I): SiO₂ and GeO₂ are acidic while SnO₂ and PbO₂ are amphoteric in nature. Statement (II): Allotropic forms of carbon are due to property of catenation and pπ-dπ bond formation.',
        options: [
          'Both Statement I and Statement II are false',
          'Both Statement I and Statement II are true',
          'Statement I is true but Statement II is false',
          'Statement I is true but Statement II is true'
        ],
        correctAnswerIndex: 2,
        subject: 'Chemistry',
        topic: 'p-Block Elements',
        subTopic: 'Group 14 Elements',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Group 14 Elements', 'Oxides', 'Allotropes'],
        questionType: 'multiple',
      ),

      Question(
        id: 'CHEM0262',
        questionText: 'Which among the following has highest boiling point?',
        options: [
          'CH₃CH₂CH₂CH₃',
          'CH₃CH₂CH₂CH₂OH',
          'CH₃CH₂CH₂CHO',
          'H₅C₂-O-C₂H₅'
        ],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'Chemical Bonding and Molecular Structure',
        subTopic: 'Intermolecular Forces',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: [
          'Boiling Point',
          'Hydrogen Bonding',
          'Intermolecular Forces'
        ],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0263',
        questionText:
            'The set of meta directing functional groups from the following sets is:',
        options: [
          '-CN, -NH₂, -NHR, -OCH₃',
          '-NO₂, -NH₂, -COOH, -COOR',
          '-NO₂, -CHO, -SO₃H, -COR',
          '-CN, -CHO, -NHCOCH₃, -COOR'
        ],
        correctAnswerIndex: 2,
        subject: 'Chemistry',
        topic: 'Some Basic Principles of Organic Chemistry',
        subTopic: 'Directing Effects',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: [
          'Directing Effects',
          'Meta Directors',
          'Electrophilic Substitution'
        ],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0264',
        questionText:
            'The functional group that shows negative resonance effect is:',
        options: ['-NH₂', '-OH', '-COOH', '-OR'],
        correctAnswerIndex: 2,
        subject: 'Chemistry',
        topic: 'Some Basic Principles of Organic Chemistry',
        subTopic: 'Resonance Effect',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: [
          'Resonance Effect',
          'Functional Groups',
          'Electronic Effects'
        ],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0265',
        questionText: 'Lassaigne\'s test is used for detection of:',
        options: [
          'Nitrogen and Sulphur only',
          'Nitrogen, Sulphur and Phosphorous Only',
          'Phosphorous and halogens only',
          'Nitrogen, Sulphur, and halogens'
        ],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Purification and Characterisation of Organic Compounds',
        subTopic: 'Elemental Analysis',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: [
          'Lassaigne\'s Test',
          'Elemental Analysis',
          'Organic Compounds'
        ],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0266',
        questionText: 'In the given reactions identify A and B.',
        options: [
          'A: 2-Pentyne, B: trans-2-butene',
          'A: n-Pentane, B: trans-2-butene',
          'A: 2-Pentyne, B: cis-2-butene',
          'A: n-Pentane, B: cis-2-butene'
        ],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Organic Compounds Containing Oxygen',
        subTopic: 'Reaction Identification',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Reaction Identification', 'Alkynes', 'Alkenes'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0267',
        questionText: 'The strongest reducing agent among the following is:',
        options: ['NH₃', 'SbH₃', 'BiH₃', 'PH₃'],
        correctAnswerIndex: 2,
        subject: 'Chemistry',
        topic: 'Hydrogen',
        subTopic: 'Hydrides',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Hydrides', 'Reducing Agents', 'Group 15 Elements'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0268',
        questionText:
            'The transition metal having highest 3rd ionisation enthalpy is:',
        options: ['Cr', 'Mn', 'V', 'Fe'],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'd- and f-Block Elements',
        subTopic: 'Ionisation Enthalpy',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: [
          'Ionisation Enthalpy',
          'Transition Metals',
          'Electronic Configuration'
        ],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0269',
        questionText:
            'Which of the following compounds show colour due to d-d transition?',
        options: ['CuSO₄·5H₂O', 'K₂Cr₂O₇', 'K₂CrO₄', 'KMnO₄'],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'd- and f-Block Elements',
        subTopic: 'Colour in Compounds',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['d-d Transition', 'Colour', 'Transition Metal Compounds'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0270',
        questionText:
            'Given below are two statements: one is labelled as Assertion A and the other is labelled as Reason R. Assertion A: In aqueous solutions Cr²⁺ is reducing while Mn³⁺ is oxidising in nature. Reason R: Extra stability to half filled electronic configuration is observed than incompletely filled electronic configuration.',
        options: [
          'Both A and R are true and R is the correct explanation of A',
          'Both A and R are true but R is not the correct explanation of A',
          'A is false but R is true',
          'A is true but R is false'
        ],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'd- and f-Block Elements',
        subTopic: 'Oxidation States',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Oxidation States', 'Electronic Configuration', 'Stability'],
        questionType: 'multiple',
      ),

      Question(
        id: 'CHEM0271',
        questionText:
            'Given below are two statements: Statement (I): Dimethyl glyoxime forms a six membered covalent chelate when treated with NiCl₂ solution in presence of NH₄OH. Statement (II): Prussian blue precipitate contains iron both in +2 and +3 oxidation states.',
        options: [
          'Statement I is false but Statement II is true',
          'Both Statement I and Statement II are true',
          'Both Statement I and Statement II are false',
          'Statement I is true but Statement II is false'
        ],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Coordination Compounds',
        subTopic: 'Complex Formation',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Complex Formation', 'Chelates', 'Prussian Blue'],
        questionType: 'multiple',
      ),

      Question(
        id: 'CHEM0272',
        questionText: '[Co(NH₃)₆]³⁺ and [CoF₆]³⁻ are respectively known as:',
        options: [
          'Spin free Complex, Spin paired Complex',
          'Spin paired Complex, Spin free Complex',
          'Outer orbital Complex, Inner orbital Complex',
          'Inner orbital Complex, Spin paired Complex'
        ],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'Coordination Compounds',
        subTopic: 'Magnetic Properties',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: [
          'Magnetic Properties',
          'Spin States',
          'Coordination Compounds'
        ],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0273',
        questionText: 'Acid D formed in above reaction is:',
        options: [
          'Gluconic acid',
          'Succinic acid',
          'Oxalic acid',
          'Malonic acid'
        ],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'Coordination Compounds',
        subTopic: 'Organic Acids',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Organic Acids', 'Reaction Products', 'Identification'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0274',
        questionText:
            'Match List - I with List - II. List-I (Reactants) List-II Products (A) Phenol, Zn/∆ (I) Salicylaldehyde (B) Phenol, CHCl₃, NaOH, HCl (II) Salicylic acid (C) Phenol, CO₂, NaOH, HCl (III) Benzene (D) Phenol, Conc. HNO₃ (IV) Picric acid',
        options: [
          '(A)-(IV), (B)-(II), (C)-(I), (D)-(III)',
          '(A)-(IV), (B)-(I), (C)-(II), (D)-(III)',
          '(A)-(III), (B)-(I), (C)-(II), (D)-(IV)',
          '(A)-(III), (B)-(IV), (C)-(I), (D)-(II)'
        ],
        correctAnswerIndex: 2,
        subject: 'Chemistry',
        topic: 'Organic Compounds Containing Oxygen',
        subTopic: 'Phenol Reactions',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Phenol Reactions', 'Reaction Products', 'Matching'],
        questionType: 'matching',
      ),

      Question(
        id: 'CHEM0275',
        questionText:
            '10 mL of gaseous hydrocarbon on combustion gives 40 mL of CO₂(g) and 50 mL of water vapour. Total number of carbon and hydrogen atoms in the hydrocarbon is _______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Organic Compounds Containing Oxygen',
        subTopic: 'Combustion Analysis',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Combustion Analysis', 'Hydrocarbons', 'Stoichiometry'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0276',
        questionText:
            'For a certain reaction at 300 K, K = 10, then ΔG° for the same reaction is - _______ ×10⁻¹ kJ/mol. (Given R = 8.314 J/K·mol)',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Some Basic Concepts in Chemistry',
        subTopic: 'Thermodynamics',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: [
          'Gibbs Free Energy',
          'Equilibrium Constant',
          'Thermodynamics'
        ],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0277',
        questionText:
            'Following Kjeldahl\'s method, 1 g of organic compound released ammonia, that neutralised 10 mL of 2M H₂SO₄. The percentage of nitrogen in the compound is _______ %.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Chemical Thermodynamics',
        subTopic: 'Nitrogen Estimation',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: [
          'Kjeldahl Method',
          'Nitrogen Estimation',
          'Percentage Composition'
        ],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0278',
        questionText:
            'Total number of isomeric compounds (including stereoisomers) formed by monochlorination of 2-methylbutane is ______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Some Basic Concepts in Chemistry',
        subTopic: 'Isomerism',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Isomerism', 'Monochlorination', 'Alkanes'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0279',
        questionText:
            'Mass of ethylene glycol (antifreeze) to be added to 18.6 kg of water to protect the freezing point at -24°C is _______ kg (Molar mass in g/mol for ethylene glycol 62, K_f of water = 1.86 K·kg/mol)',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Hydrocarbons',
        subTopic: 'Colligative Properties',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: [
          'Colligative Properties',
          'Freezing Point Depression',
          'Ethylene Glycol'
        ],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0280',
        questionText:
            'The amount of electricity in Coulomb required for the oxidation of 1 mol of H₂O to O₂ is ______ ×10⁵ C.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Solutions',
        subTopic: 'Electrochemistry',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Electrochemistry', 'Faraday\'s Law', 'Oxidation'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0281',
        questionText:
            'Consider the following redox reaction: MnO₄⁻ + H⁺ + H₂C₂O₄ ⇌ Mn²⁺ + H₂O + CO₂ The standard reduction potentials are given as below E°_red: E°(MnO₄⁻/Mn²⁺) = +1.51 V; E°(CO₂/H₂C₂O₄) = -0.49 V If the equilibrium constant of the above reaction is given as K_eq = 10^x, then the value of x = _______ (nearest integer)',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Redox Reactions and Electrochemistry',
        subTopic: 'Equilibrium Constant',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: [
          'Redox Reactions',
          'Equilibrium Constant',
          'Standard Potentials'
        ],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0282',
        questionText:
            'The following data were obtained during the first order thermal decomposition of a gas A at constant volume: A(g) → 2B(g) + C(g) S. No Time/s Total pressure/(atm) 1. 0 0.1 2. 115 0.28 The rate constant of the reaction is _______ ×10⁻² s⁻¹ (nearest integer)',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Redox Reactions and Electrochemistry',
        subTopic: 'Chemical Kinetics',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: [
          'Chemical Kinetics',
          'First Order Reaction',
          'Rate Constant'
        ],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0283',
        questionText:
            'Number of compounds which give reaction with Hinsberg\'s reagent is _________.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Organic Compounds Containing Nitrogen',
        subTopic: 'Hinsberg\'s Test',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Hinsberg\'s Test', 'Amines', 'Reactivity'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0284',
        questionText:
            'The number of tripeptides formed by three different amino acids using each amino acid once is _______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Biomolecules',
        subTopic: 'Peptides',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Peptides', 'Amino Acids', 'Combinations'],
        questionType: 'numerical',
      ),
      Question(
        id: 'MATH0250',
        questionText:
            'Let α and β be the roots of the equation px² + qx - r = 0, where p ≠ 0. If p, q and r be the consecutive terms of a non-constant G.P and 1/α + 1/β = 3/4, then the value of (α - β)² is:',
        options: ['80/9', '9/20', '8/3', '1'],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Algebra',
        subTopic: 'Quadratic Equations',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Quadratic Equations', 'Geometric Progression', 'Roots'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0251',
        questionText:
            'If z is a complex number such that |z| ≤ 1, then the minimum value of |z + (3+4i)/2| is:',
        options: ['2', '2/3', '3/2', '3'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Complex Numbers',
        subTopic: 'Modulus',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Complex Numbers', 'Modulus', 'Minimum Value'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0252',
        questionText:
            'Let Sₙ denote the sum of the first n terms of an arithmetic progression. If S₁₀ = 390 and the ratio of the tenth and the fifth terms is 15 : 7, then S₁₅ - S₅ is equal to:',
        options: ['800', '890', '790', '690'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Sequence and Series',
        subTopic: 'Arithmetic Progression',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Arithmetic Progression', 'Sum of Terms', 'Ratio'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0253',
        questionText:
            'Let m and n be the coefficients of seventh and thirteenth terms respectively in the expansion of (x^(1/3) + 1/(2x^(1/3)))^18. Then n/(3m) is:',
        options: ['1/9', '9', '1/4', '9/4'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Binomial Theorem',
        subTopic: 'Binomial Expansion',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Binomial Theorem', 'Coefficients', 'Term Identification'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0254',
        questionText:
            'The number of solutions of the equation 4sin²x - 4cos³x + 9 - 4cosx = 0; x ∈ [-2π, 2π] is:',
        options: ['1', '3', '2', '0'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Trigonometry',
        subTopic: 'Trigonometric Equations',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Trigonometric Equations', 'Solutions', 'Interval'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0255',
        questionText:
            'Let the locus of the mid points of the chords of circle x² + (y-1)² = 1 drawn from the origin intersect the line x + y = 1 at P and Q. Then, the length of PQ is:',
        options: ['1/√2', '√2', '1/2', '1'],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: 'Circle',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Circle', 'Chord Midpoints', 'Line Intersection'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0256',
        questionText:
            'Let P be a point on the ellipse x²/9 + y²/4 = 1. Let the line passing through P and parallel to y-axis meet the circle x² + y² = 9 at point Q such that P and Q are on the same side of the x-axis. Then, the eccentricity of the locus of the point R on PQ such that PR:RQ = 4:3 as P moves on the ellipse, is:',
        options: ['11/19', '13/21', '√139/23', '√13/7'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: 'Ellipse',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Ellipse', 'Locus', 'Eccentricity'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0257',
        questionText:
            'Let f(x) = {x-1, if x is even; 2x, if x is odd}, x ∈ N. If for some a ∈ N, f(f(f(a))) = 21, then lim(x→a) ([x³] - [a³])/(x - a), where [t] denotes the greatest integer less than or equal to t, is equal to:',
        options: ['121', '144', '169', '225'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Calculus',
        subTopic: 'Limits',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: [
          'Limits',
          'Greatest Integer Function',
          'Composite Functions'
        ],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0258',
        questionText:
            'Consider 10 observations x₁, x₂, ..., x₁₀, such that ∑(xᵢ - α) = 2 and ∑(xᵢ - β)² = 40, where α, β are positive integers. Let the mean and the variance of the observations be 6/5 and 84/25 respectively. Then β/α is equal to:',
        options: ['2', '2/5', '3/2', '1'],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Statistics',
        subTopic: 'Mean and Variance',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Mean', 'Variance', 'Statistics'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0259',
        questionText:
            'Consider the relations R₁ and R₂ defined as aR₁b ⇔ a² + b² = 1 for all a,b ∈ R and (a,b)R₂(c,d) ⇔ a + d = b + c for all (a,b),(c,d) ∈ N×N. Then',
        options: [
          'Only R₁ is an equivalence relation',
          'Only R₂ is an equivalence relation',
          'R₁ and R₂ both are equivalence relations',
          'Neither R₁ nor R₂ is an equivalence relation'
        ],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Sets and Relations',
        subTopic: 'Equivalence Relations',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: [
          'Equivalence Relations',
          'Reflexive',
          'Symmetric',
          'Transitive'
        ],
        questionType: 'multiple',
      ),

      Question(
        id: 'MATH0260',
        questionText:
            'Let the system of equations x + 2y + 3z = 5, 2x + 3y + z = 9, 4x + 3y + λz = μ have infinite number of solutions. Then λ + 2μ is equal to:',
        options: ['28', '17', '22', '15'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Linear Algebra',
        subTopic: 'System of Equations',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['System of Equations', 'Infinite Solutions', 'Parameters'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0261',
        questionText:
            'If the domain of the function f(x) = √(x² - 25) + log₁₀(x² + 2x - 15) is (-∞, α) ∪ (β, ∞), then α² + β³ is equal to:',
        options: ['140', '175', '150', '125'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Functions',
        subTopic: 'Domain',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Domain', 'Logarithmic Functions', 'Square Root'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0262',
        questionText:
            'Let f(x) = |2x² + 5x - 3|, x ∈ R. If m and n denote the number of points where f is not continuous and not differentiable respectively, then m + n is equal to:',
        options: ['5', '2', '0', '3'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Calculus',
        subTopic: 'Continuity and Differentiability',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: [
          'Continuity',
          'Differentiability',
          'Absolute Value Function'
        ],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0263',
        questionText:
            'The value of ∫₀¹ (2x³ - 3x² - x + 1)^(1/3) dx is equal to:',
        options: ['0', '1', '2', '-1'],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Integral Calculus',
        subTopic: 'Definite Integrals',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Definite Integrals', 'Cube Root', 'Polynomial'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0264',
        questionText:
            'If ∫₀^(π/3) cos⁴x dx = aπ + b√3, where a and b are rational numbers, then 9a + 8b is equal to:',
        options: ['2', '1/3', '3', '2/3'],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Integral Calculus',
        subTopic: 'Definite Integrals',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: [
          'Definite Integrals',
          'Trigonometric Functions',
          'Rational Numbers'
        ],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0265',
        questionText:
            'Let α be a non-zero real number. Suppose f: R → R is a differentiable function such that f(0) = 1 and lim(x→-∞) f(x) = 1. If f′(x) = αf(x) + 3, for all x ∈ R, then f(-logₑ2) is equal to:',
        options: ['1', '5', '9', '7'],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Differential Equations',
        subTopic: 'First Order DE',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Differential Equations', 'Exponential Functions', 'Limits'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0266',
        questionText:
            'Consider a triangle ABC where A(1,3,2), B(-2,8,0) and C(3,6,7). If the angle bisector of ∠BAC meets the line BC at D, then the length of the projection of the vector AD on the vector AC is:',
        options: ['37/(2√38)', '√38/2', '39/(2√38)', '√19/(2√38)'],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Vector Algebra',
        subTopic: 'Projection',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Vectors', 'Projection', 'Angle Bisector'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0267',
        questionText:
            'If the mirror image of the point P(3,4,9) in the line (x-1)/3 = (y+1)/2 = (z-2)/1 is (α,β,γ), then 14α + β + γ is:',
        options: ['102', '138', '108', '132'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: '3D Geometry',
        subTopic: 'Mirror Image',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['3D Geometry', 'Mirror Image', 'Line'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0268',
        questionText:
            'Let P and Q be the points on the line (x+3)/8 = (y-4)/2 = (z+1)/2 which are at a distance of 6 units from the point R(1,2,3). If the centroid of the triangle PQR is (α,β,γ), then α² + β² + γ² is:',
        options: ['26', '36', '18', '24'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: '3D Geometry',
        subTopic: 'Distance and Centroid',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['3D Geometry', 'Distance', 'Centroid'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0269',
        questionText:
            'Let Ajay will not appear in JEE exam with probability p = 2/7, while both Ajay and Vijay will appear in the exam with probability q = 1/5. Then the probability that Ajay will appear in the exam and Vijay will not appear is:',
        options: ['9/35', '18/35', '24/35', '3/35'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Probability',
        subTopic: 'Conditional Probability',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Probability', 'Conditional Probability', 'Events'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0270',
        questionText:
            'The lines L₁, L₂, ..., L₂₀ are distinct. For n = 1,2,3,...,10 all the lines L₂ₙ₋₁ are parallel to each other and all the lines L₂ₙ pass through a given point P. The maximum number of points of intersection of pairs of lines from the set {L₁, L₂, ..., L₂₀} is equal to:',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Permutations and Combinations',
        subTopic: 'Lines and Intersections',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Lines', 'Intersections', 'Maximum Points'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0271',
        questionText:
            'If three successive terms of a G.P. with common ratio r (r > 1) are the length of the sides of a triangle and [r] denotes the greatest integer less than or equal to r, then 3[r] + [-r] is equal to:',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Sequence and Series',
        subTopic: 'Geometric Progression',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: [
          'Geometric Progression',
          'Triangle Inequality',
          'Greatest Integer Function'
        ],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0272',
        questionText:
            'Let ABC be an isosceles triangle in which A is at (-1,0), ∠A = 2π/3, AB = AC and B is on the positive x-axis. If BC = 4√3 and the line BC intersects the line y = x + 3 at (α,β), then β/α² is:',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: 'Triangle Geometry',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Coordinate Geometry', 'Triangle', 'Line Intersection'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0273',
        questionText:
            'Let A = I₂ - 2MMᵀ, where M is real matrix of order 2×1 such that the relation MᵀM = I₁ holds. If λ is a real number such that the relation AX = λX holds for some non-zero real matrix X of order 2×1, then the sum of squares of all possible values of λ is equal to:',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Linear Algebra',
        subTopic: 'Eigenvalues',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Eigenvalues', 'Matrices', 'Identity Matrix'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0274',
        questionText:
            'If y = √(x + 1/x²) - √(x + 1/(x√x + x + √x)) + (3cos2x - 5cos3x)/15, then 96y′(π/6) is equal to:',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Calculus',
        subTopic: 'Differentiation',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: [
          'Differentiation',
          'Trigonometric Functions',
          'Square Roots'
        ],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0275',
        questionText:
            'Let f: (0,∞) → R and F(x) = ∫₀ˣ t f(t) dt. If F(x²) = x⁴ + x⁵, then ∑(r=1 to 12) f(r²) is equal to:',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Integral Calculus',
        subTopic: 'Definite Integrals',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Definite Integrals', 'Summation', 'Functional Equation'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0276',
        questionText:
            'Three points O(0,0), P(a,a²), Q(-b,b²), a > 0, b > 0, are on the parabola y = x². Let S₁ be the area of the region bounded by the line PQ and the parabola, and S₂ be the area of the triangle OPQ. If the minimum value of S₁/S₂ is m/n, gcd(m,n) = 1, then m + n is equal to:',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Integral Calculus',
        subTopic: 'Area',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Area', 'Parabola', 'Triangle'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0277',
        questionText:
            'The sum of squares of all possible values of k, for which area of the region bounded by the parabolas 2y² = kx and ky² = 2y - x is maximum, is equal to:',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Integral Calculus',
        subTopic: 'Area Optimization',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Area', 'Optimization', 'Parabolas'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0278',
        questionText:
            'If dx/dy = (1 + x - y²)/y, x(1) = 1, then 5x(2) is equal to:',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Differential Equations',
        subTopic: 'First Order DE',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: [
          'Differential Equations',
          'Initial Value Problem',
          'Separation of Variables'
        ],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0279',
        questionText:
            'Let a = î + ĵ + k̂, b = -î - 8ĵ + 2k̂ and c = 4î + c₂ĵ + c₃k̂ be three vectors such that b × a = c × a. If the angle between the vector c and the vector 3î + 4ĵ + k̂ is θ, then the greatest integer less than or equal to tan²θ is:',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Vector Algebra',
        subTopic: 'Cross Product',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Vectors', 'Cross Product', 'Angle'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0285',
        questionText:
            'The radius r, length l and resistance R of a metal wire was measured in the laboratory as r = 0.35 ± 0.05 cm, R = 100 ± 10 ohm, l = 15 ± 0.2 cm. The percentage error in resistivity of the material of the wire is:',
        options: ['25.6%', '39.9%', '37.3%', '35.6%'],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Units and Measurements',
        subTopic: 'Error Analysis',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Error Analysis', 'Percentage Error', 'Resistivity'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0286',
        questionText: 'The dimensional formula of angular impulse is:',
        options: ['ML⁻²T⁻¹', 'ML²T⁻²', 'MLT⁻¹', 'ML²T⁻¹'],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Units and Measurements',
        subTopic: 'Dimensional Analysis',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Dimensional Analysis', 'Angular Impulse', 'Dimensions'],
        questionType: 'numerical',
      ),
      Question(
        id: 'PHY0287',
        questionText:
            'A particle moving in a circle of radius R with uniform speed takes time T to complete one revolution. If this particle is projected with the same speed at an angle θ to the horizontal, the maximum height attained by it is equal to 4R. The angle of projection θ is then given by:',
        options: [
          'sin⁻¹(2gT²/π²R)',
          'sin⁻¹(π²R/2gT²)',
          'cos⁻¹(2gT²/πR)',
          'cos⁻¹(π²R/2gT²)'
        ],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Kinematics',
        subTopic: 'Projectile Motion',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Projectile Motion', 'Circular Motion', 'Maximum Height'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0288',
        questionText:
            'Consider a block and trolley system as shown in figure. If the coefficient of kinetic friction between the trolley and the surface is 0.04, the acceleration of the system in m/s² is: (Consider that the string is massless and unstretchable and the pulley is also massless and frictionless)',
        options: ['3', '4', '2', '1.2'],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Laws of Motion',
        subTopic: 'Systems with Friction',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Friction', 'System Acceleration', 'Pulley Systems'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0289',
        questionText:
            'A simple pendulum of length 1 m has a wooden bob of mass 1 kg. It is struck by a bullet of mass 10⁻² kg moving with a speed of 2×10² m/s. The bullet gets embedded into the bob. The height to which the bob rises before swinging back is. (use g = 10 m/s²)',
        options: ['0.30 m', '0.20 m', '0.35 m', '0.40 m'],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Work, Energy and Power',
        subTopic: 'Collision and Energy',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Collision', 'Conservation of Energy', 'Pendulum'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0290',
        questionText:
            'A ball of mass 0.5 kg is attached to a string of length 50 cm. The ball is rotated on a horizontal circular path about its vertical axis. The maximum tension that the string can bear is 400 N. The maximum possible value of angular velocity of the ball in rad/s is:',
        options: ['1600', '40', '1000', '20'],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Laws of Motion',
        subTopic: 'Circular Motion',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Circular Motion', 'Tension', 'Angular Velocity'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0291',
        questionText:
            'If R is the radius of the earth and the acceleration due to gravity on the surface of earth is g = π² m/s², then the length of the second\'s pendulum at a height h = 2R from the surface of earth will be:',
        options: ['2/9 m', '1/9 m', '4/9 m', '8/9 m'],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Oscillations and Waves',
        subTopic: 'Simple Pendulum',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Simple Pendulum', 'Gravity Variation', 'Time Period'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0292',
        questionText:
            'With rise in temperature, the Young\'s modulus of elasticity',
        options: [
          'changes erratically',
          'decreases',
          'increases',
          'remains unchanged'
        ],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Properties of Solids and Liquids',
        subTopic: 'Elasticity',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Young\'s Modulus', 'Temperature Effect', 'Elasticity'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0293',
        questionText:
            'The pressure and volume of an ideal gas are related as PV² = K (Constant). The work done when the gas is taken from state A(P₁, V₁, T₁) to state B(P₂, V₂, T₂) is:',
        options: [
          '2(P₁V₁ - P₂V₂)',
          '2(P₂V₂ - P₁V₁)',
          '2(P₁V₁ - P₂V₂)',
          '2(P₂V₂ - P₁V₁)'
        ],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Thermodynamics',
        subTopic: 'Work Done',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Thermodynamic Work', 'Ideal Gas', 'Polytropic Process'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0294',
        questionText:
            'Two moles of a monoatomic gas is mixed with six moles of a diatomic gas. The molar specific heat of the mixture at constant volume is:',
        options: ['9R/4', '7R/4', '3R/2', '5R/2'],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Thermodynamics',
        subTopic: 'Specific Heat',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Specific Heat', 'Gas Mixture', 'Degrees of Freedom'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0295',
        questionText:
            'Two identical capacitors have same capacitance C. One of them is charged to the potential V and other to the potential 2V. The negative ends of both are connected together. When the positive ends are also joined together, the decrease in energy of the combined system is:',
        options: ['1/4 CV²', '2CV²', '1/2 CV²', '3/4 CV²'],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Electrostatics',
        subTopic: 'Capacitors',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Capacitors', 'Energy Loss', 'Connection'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0296',
        questionText:
            'The reading in the ideal voltmeter V shown in the given circuit diagram is:',
        options: ['5 V', '10 V', '0 V', '3 V'],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Current Electricity',
        subTopic: 'Voltmeter Reading',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Voltmeter', 'Circuit Analysis', 'Potential Difference'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0297',
        questionText:
            'A galvanometer has a resistance of 50 Ω and it allows maximum current of 5 mA. It can be converted into voltmeter to measure upto 100 V by connecting in series a resistor of resistance.',
        options: ['5975 Ω', '20050 Ω', '19950 Ω', '19500 Ω'],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Current Electricity',
        subTopic: 'Voltmeter Conversion',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Galvanometer', 'Voltmeter', 'Series Resistance'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0298',
        questionText:
            'A parallel plate capacitor has a capacitance C = 200 pF. It is connected to 230 V ac supply with an angular frequency 300 rad/s. The rms value of conduction current in the circuit and displacement current in the capacitor respectively are:',
        options: [
          '1.38 μA and 1.38 μA',
          '14.3 μA and 143 μA',
          '13.8 μA and 138 μA',
          '13.8 μA and 13.8 μA'
        ],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Electromagnetic Waves',
        subTopic: 'Displacement Current',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Displacement Current', 'Conduction Current', 'AC Circuits'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0299',
        questionText:
            'In series LCR circuit, the capacitance is changed from C to 4C. To keep the resonance frequency unchanged, the new inductance should be:',
        options: [
          'reduced by L/4',
          'increased by 2L',
          'reduced by 3L/4',
          'increased to 4L'
        ],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Electromagnetic Induction',
        subTopic: 'LCR Circuit',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['LCR Circuit', 'Resonance', 'Inductance Change'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0300',
        questionText:
            'A monochromatic light of wavelength 6000 Å is incident on the single slit of width 0.01 mm. If the diffraction pattern is formed at the focus of the convex lens of focal length 20 cm, the linear width of the central maximum is:',
        options: ['60 mm', '24 mm', '120 mm', '12 mm'],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Optics',
        subTopic: 'Diffraction',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: [
          'Single Slit Diffraction',
          'Central Maximum',
          'Linear Width'
        ],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0301',
        questionText:
            'The de Broglie wavelengths of a proton and an α particle are λ and 2λ respectively. The ratio of the velocities of proton and α particle will be:',
        options: ['1 : 8', '1 : 2', '4 : 1', '8 : 1'],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Modern Physics',
        subTopic: 'de Broglie Wavelength',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['de Broglie Wavelength', 'Particle Velocity', 'Mass Ratio'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0302',
        questionText:
            'The minimum energy required by a hydrogen atom in ground state to emit radiation in Balmer series is nearly:',
        options: ['1.5 eV', '13.6 eV', '1.9 eV', '12.1 eV'],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Atoms and Nuclei',
        subTopic: 'Hydrogen Spectrum',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Hydrogen Spectrum', 'Balmer Series', 'Energy Levels'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0303',
        questionText:
            'In the given circuit if the power rating of Zener diode is 10 mW, the value of series resistance R_s to regulate the input unregulated supply is:',
        options: ['3/7 kΩ', '10 Ω', '1 kΩ', '10 kΩ'],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Electronic Devices',
        subTopic: 'Zener Diode',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Zener Diode', 'Voltage Regulation', 'Series Resistance'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0304',
        questionText:
            '10 divisions on the main scale of a Vernier calliper coincide with 11 divisions on the Vernier scale. If each division on the main scale is of 5 units, the least count of the instrument is:',
        options: ['1/2', '10/11', '50/11', '5/11'],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Experimental Skills',
        subTopic: 'Vernier Calliper',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Vernier Calliper', 'Least Count', 'Measurement'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0305',
        questionText:
            'A particle is moving in one dimension (along x axis) under the action of a variable force. Its initial position was 16 m right of origin. The variation of its position x with time t is given as x = -3t³ + 18t² + 16t, where x is in m and t is in s. The velocity of the particle when its acceleration becomes zero is _________ m/s.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Kinematics',
        subTopic: 'Variable Acceleration',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Variable Acceleration', 'Velocity', 'Differentiation'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0306',
        questionText:
            'The identical spheres each of mass 2M are placed at the corners of a right angled triangle with mutually perpendicular sides equal to 4 m each. Taking point of intersection of these two sides as origin, the magnitude of position vector of the centre of mass of the system is 4√2/x, where the value of x is ________.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Rotational Motion',
        subTopic: 'Center of Mass',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Center of Mass', 'Position Vector', 'System of Particles'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0307',
        questionText:
            'A plane is in level flight at constant speed and each of its two wings has an area of 40 m². If the speed of the air is 180 km/h over the lower wing surface and 252 km/h over the upper wing surface, the mass of the plane is ________ kg. (Take air density to be 1 kg/m³ and g = 10 m/s²)',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Fluid Mechanics',
        subTopic: 'Bernoulli\'s Principle',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Bernoulli\'s Principle', 'Lift Force', 'Aerodynamics'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0308',
        questionText:
            'A tuning fork resonates with a sonometer wire of length 1 m stretched with a tension of 6 N. When the tension in the wire is changed to 54 N, the same tuning fork produces 12 beats per second with it. The frequency of the tuning fork is _______ Hz.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Waves',
        subTopic: 'Beats',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Beats', 'Sonometer', 'Frequency'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0309',
        questionText:
            'Two identical charged spheres are suspended by strings of equal lengths. The strings make an angle θ with each other. When suspended in water the angle remains the same. If density of the material of the sphere is 1.5 g/cc, the dielectric constant of water will be ______. (Take density of water = 1 g/cc)',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Electrostatics',
        subTopic: 'Dielectric Constant',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Dielectric Constant', 'Electrostatics', 'Buoyancy'],
        questionType: 'numerical',
      ),
      Question(
        id: 'MATH0280',
        questionText:
            'Let S = {x ∈ R: √(3+√2) + √(3-√2) = 10}. Then the number of elements in S is:',
        options: ['4', '0', '2', '1'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Complex Numbers and Quadratic Equations',
        subTopic: 'Radical Equations',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Radical Equations', 'Set Theory'],
        questionType: 'mcq',
      ),

      Question(
        id: 'MATH0281',
        questionText:
            'Let S = {z ∈ C: |z-1| = 1 and |√2 - 1|z + z̄ - i(z - z̄)| = 2√2}. Let z₁, z₂ ∈ S be such that |z₁| = max|z| and |z₂| = min|z|. Then |√2z₁ - z₂| equals:',
        options: ['1', '4', '3', '2'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Complex Numbers and Quadratic Equations',
        subTopic: 'Complex Numbers Geometry',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Complex Numbers', 'Geometry in Complex Plane'],
        questionType: 'mcq',
      ),

      Question(
        id: 'MATH0282',
        questionText:
            'If n is the number of ways five different employees can sit into four indistinguishable offices where any office may have any number of persons including zero, then n is equal to:',
        options: ['47', '53', '51', '43'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Permutations and Combinations',
        subTopic: 'Distribution Problems',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Distribution', 'Indistinguishable Boxes'],
        questionType: 'mcq',
      ),

      Question(
        id: 'MATH0283',
        questionText:
            'Let 3, a, b, c be in A.P. and 3, a-1, b+1, c+9 be in G.P. Then, the arithmetic mean of a, b and c is:',
        options: ['-4', '-1', '13', '11'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Sequence and Series',
        subTopic: 'AP and GP',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Arithmetic Progression', 'Geometric Progression'],
        questionType: 'mcq',
      ),
      Question(
        id: 'MATH0284',
        questionText:
            'If tanA = 1/x, tanB = √x/(x²+x+1) and tanC = (x³+x²+x-1)/(x²+x+1), 0 < A,B,C < π/2, then A+B is equal to:',
        options: ['C', 'π - C', '2π - C', 'π/2 - C'],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Trigonometry',
        subTopic: 'Tangent Addition Formula',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Tangent Addition', 'Trigonometric Identities'],
        questionType: 'mcq',
      ),

      Question(
        id: 'MATH0285',
        questionText:
            'Let C: x² + y² = 4 and C\': x² + y² - 4λx + 9 = 0 be two circles. If the set of all values of λ so that the circles C and C\' intersect at two distinct points, is R - {a,b}, then the point (8a + 12, 16b - 20) lies on the curve:',
        options: [
          'x² + 2y² - 5x + 6y = 3',
          '5x² - y = -11',
          'x² - 4y² = 7',
          '6x² + y² = 42'
        ],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: 'Circles',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Circle Intersection', 'Locus'],
        questionType: 'mcq',
      ),

      Question(
        id: 'MATH0286',
        questionText:
            'Let x²/a² + y²/b² = 1, a > b be an ellipse, whose eccentricity is 1/√2 and the length of the latus rectum is √14. Then the square of the eccentricity of x²/a² - y²/b² = 1 is:',
        options: ['3/2', '2/3', '5/2', '2'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: 'Conic Sections',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Ellipse', 'Hyperbola', 'Eccentricity'],
        questionType: 'mcq',
      ),

      Question(
        id: 'MATH0287',
        questionText:
            'For 0 < θ < π/2, if the eccentricity of the hyperbola x² - y²cosec²θ = 5 is √7 times eccentricity of the ellipse x²cosec²θ + y² = 5, then the value of θ is:',
        options: ['π/6', '5π/12', 'π/3', 'π/4'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: 'Conic Sections',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Ellipse', 'Hyperbola', 'Eccentricity'],
        questionType: 'mcq',
      ),

      Question(
        id: 'MATH0288',
        questionText:
            'Let the median and the mean deviation about the median of 7 observations 170,125,230,190,210,a,b be 170 and 205/7 respectively. Then the mean deviation about the mean of these 7 observations is:',
        options: ['31', '28', '30', '32'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Statistics and Probability',
        subTopic: 'Measures of Dispersion',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Median', 'Mean Deviation'],
        questionType: 'mcq',
      ),

      Question(
        id: 'MATH0289',
        questionText:
            'If A = [[√2, 1], [-1, √2]], B = [[1, 1], [0, 1]], C = ABAᵀ and X = AᵀC²A, then det(X) is equal to:',
        options: ['243', '729', '27', '891'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Matrices and Determinants',
        subTopic: 'Matrix Operations',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Matrix Multiplication', 'Determinant'],
        questionType: 'mcq',
      ),

      Question(
        id: 'MATH0290',
        questionText:
            'If the system of equations\n2x + 3y - z = 5\nx + αy + 3z = -4\n3x - y + βz = 7\nhas infinitely many solutions, then 13αβ is equal to:',
        options: ['1110', '1120', '1210', '1220'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Matrices and Determinants',
        subTopic: 'System of Equations',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Infinite Solutions', 'Determinant'],
        questionType: 'mcq',
      ),

      Question(
        id: 'MATH0291',
        questionText:
            'Let f: R → R and g: R → R be defined as f(x) = {log|x|, x > 0; e^x, x ≤ 0} and g(x) = {x, x ≥ 0; e^(-x), x < 0}. Then, g∘f: R → R is:',
        options: [
          'one-one but not onto',
          'neither one-one nor onto',
          'onto but not one-one',
          'both one-one and onto'
        ],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Sets, Relations and Functions',
        subTopic: 'Composite Functions',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Function Composition', 'One-one', 'Onto'],
        questionType: 'mcq',
      ),

      Question(
        id: 'MATH0292',
        questionText:
            'Let f: R → R be defined as f(x) = {(a - bcos2x)/x²; x < 0; x² + cx + 2; 0 ≤ x ≤ 1; 2x + 1; x > 1}. If f is continuous everywhere in R and m is the number of points where f is NOT differentiable then m + a + b + c equals:',
        options: ['1', '4', '3', '2'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Limit, Continuity and Differentiability',
        subTopic: 'Continuity and Differentiability',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Continuity', 'Differentiability', 'Piecewise Function'],
        questionType: 'mcq',
      ),

      Question(
        id: 'MATH0293',
        questionText:
            'If 5f(x) + 4f(1/x) = x² - 2, ∀ x ≠ 0 and y = 9x²f(x), then y is strictly increasing in:',
        options: [
          '(0, 1/√5) ∪ (1/√5, ∞)',
          '(-1/√5, 0) ∪ (1/√5, ∞)',
          '(-1/√5, 0) ∪ (0, 1/√5)',
          '(-∞, -1/√5) ∪ (0, 1/√5)'
        ],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Limit, Continuity and Differentiability',
        subTopic: 'Monotonic Functions',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Functional Equation', 'Increasing Function'],
        questionType: 'mcq',
      ),

      Question(
        id: 'MATH0294',
        questionText:
            'The value of the integral ∫₀^(π/4) xdx/(sin⁴2x + cos⁴2x) equals:',
        options: ['√2π²/8', '√2π²/16', '√2π²/32', '√2π²/64'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Integral Calculus',
        subTopic: 'Definite Integrals',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Definite Integral', 'Trigonometric Identities'],
        questionType: 'mcq',
      ),

      Question(
        id: 'MATH0295',
        questionText:
            'The area enclosed by the curves xy + 4y = 16 and x + y = 6 is equal to:',
        options: ['28 - 30log₂', '30 - 28log₂', '30 - 32log₂', '32 - 30log₂'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Integral Calculus',
        subTopic: 'Area Under Curves',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Area Between Curves', 'Integration'],
        questionType: 'mcq',
      ),

      Question(
        id: 'MATH0296',
        questionText:
            'Let y = y(x) be the solution of the differential equation dy/dx = 2x(x+y)³ - x(x+y) - 1, y(0) = 1. Then, 1 + y(1/√2) equals:',
        options: ['4/(4+√e)', '3/(3-√e)', '2/(1+√e)', '1/(2-√e)'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Differential Equations',
        subTopic: 'First Order Differential Equations',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Differential Equation', 'Initial Value Problem'],
        questionType: 'mcq',
      ),

      Question(
        id: 'MATH0297',
        questionText:
            'Let a = -5i + j - 3k, b = i + 2j - 4k and c = a × (b × (i × (i × i))). Then c·(-i + j + k) is equal to:',
        options: ['-12', '-10', '-13', '-15'],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Vector Algebra',
        subTopic: 'Vector Triple Product',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Vector Triple Product', 'Dot Product'],
        questionType: 'mcq',
      ),

      Question(
        id: 'MATH0298',
        questionText:
            'If the shortest distance between the lines (x-λ)/-2 = (y-2)/1 = (z-1)/1 and (x-√3)/1 = (y-1)/-2 = (z-2)/1 is 1, then the sum of all possible values of λ is:',
        options: ['0', '2√3', '3√3', '-2√3'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Three Dimensional Geometry',
        subTopic: 'Shortest Distance Between Lines',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Skew Lines', 'Shortest Distance'],
        questionType: 'mcq',
      ),

      Question(
        id: 'MATH0299',
        questionText:
            'A bag contains 8 balls, whose colours are either white or black. 4 balls are drawn at random without replacement and it was found that 2 balls are white and other 2 balls are black. The probability that the bag contains equal number of white and black balls is:',
        options: ['2/5', '2/7', '1/7', '1/5'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Statistics and Probability',
        subTopic: 'Conditional Probability',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Conditional Probability', 'Bayes Theorem'],
        questionType: 'mcq',
      ),

      Question(
        id: 'MATH0300',
        questionText:
            'Let P = {z ∈ C: |z + 2 - 3i| ≤ 1} and Q = {z ∈ C: |z(1+i) + z̄(1-i)| ≤ -8}. Let in P∩Q, |z - 3 + 2i| be maximum and minimum at z₁ and z₂ respectively. If |z₁|² + 2|z₂|² = α + β√2, where α,β are integers, then α + β equals ______',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Complex Numbers and Quadratic Equations',
        subTopic: 'Complex Numbers Geometry',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Complex Numbers', 'Geometry'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0301',
        questionText:
            'Let 3, 7, 11, 15, ..., 403 and 2, 5, 8, 11, ..., 404 be two arithmetic progressions. Then the sum of the common terms in them is equal to ______',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Sequence and Series',
        subTopic: 'Arithmetic Progressions',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Arithmetic Progression', 'Common Terms'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0302',
        questionText:
            'If the coefficient of x³⁰ in the expansion of (1 + 1/x)⁶(1 + x²)⁷(1 - x³)⁸; x ≠ 0 is α, then α equals ______',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Binomial Theorem and Its Simple Applications',
        subTopic: 'Binomial Expansion',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Binomial Theorem', 'Coefficient'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0303',
        questionText:
            'Let the line L: √2x + y = α pass through the point of the intersection P(in the first quadrant) of the circle x² + y² = 3 and the parabola x² = 2y. Let the line L touch two circles C₁ and C₂ of equal radius 2√3. If the centres Q₁ and Q₂ of the circles C₁ and C₂ lie on the y-axis, then the square of the area of the triangle PQ₁Q₂ is equal to ______',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: 'Circles and Conics',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Circle', 'Parabola', 'Tangent'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0304',
        questionText:
            'Let {x} denote the fractional part of x and f(x) = (cos⁻¹(1-{x}²) - sin⁻¹(1-{x}))/(x - x³), x ≠ 0. If L and R respectively denotes the left hand limit and the right hand limit of f(x) at x = 0, then (32/π²)(L² + R²) is equal to ______',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Limit, Continuity and Differentiability',
        subTopic: 'Limits',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Limits', 'Fractional Part'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0305',
        questionText:
            'The number of elements in the set S = {(x,y,z): x,y,z ∈ Z, x + 2y + 3z = 42, x,y,z ≥ 0} equals ______',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Permutations and Combinations',
        subTopic: 'Integer Solutions',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Integer Solutions', 'Non-negative Solutions'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0306',
        questionText:
            'Let A = {1,2,3,...,20}. Let R₁ and R₂ be two relations on A such that R₁ = {(a,b): b is divisible by a} and R₂ = {(a,b): a is an integral multiple of b}. Then, number of elements in R₁ - R₂ is equal to ______',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Sets, Relations and Functions',
        subTopic: 'Relations',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Relations', 'Set Difference'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0307',
        questionText:
            'If ∫₋ᵖᶦ⁄₂ᵖᶦ⁄₂ (8√2cosx dx)/((1+eˢᶦⁿˣ)(1+sin⁴x)) = απ + βlogₑ(3+2√2), where α, β are integers, then α² + β² equals ______',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Integral Calculus',
        subTopic: 'Definite Integrals',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Definite Integral', 'Properties of Integration'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0308',
        questionText:
            'If x = x(t) is the solution of the differential equation (t+1)dx = 2(x + (t+1)⁴)dt, x(0) = 2, then x(1) equals ______',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Differential Equations',
        subTopic: 'First Order Differential Equations',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Differential Equation', 'Initial Value Problem'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0309',
        questionText:
            'Let the line of the shortest distance between the lines L₁: r = i + 2j + 3k + λ(i - j + k) and L₂: r = 4i + 5j + 6k + μ(i + j - k) intersect L₁ and L₂ at P and Q respectively. If (α,β,γ) is the midpoint of the line segment PQ, then 2α + β + γ is equal to ______',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Three Dimensional Geometry',
        subTopic: 'Shortest Distance Between Lines',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Skew Lines', 'Shortest Distance'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0310',
        questionText:
            'If two vectors A and B having equal magnitude R are inclined at an angle θ, then:',
        options: [
          '|A - B| = √2R sin(θ/2)',
          '|A + B| = 2R sin(θ/2)',
          '|A + B| = 2R cos(θ/2)',
          '|A - B| = 2R cos(θ/2)'
        ],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Vector Algebra',
        subTopic: 'Vector Addition',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Vector Addition', 'Magnitude'],
        questionType: 'mcq',
      ),
      Question(
        id: 'PHY0316',
        questionText:
            'Consider two physical quantities A and B related to each other as E = (B - x²)/(At) where E, x and t have dimensions of energy, length and time respectively. The dimension of AB is:',
        options: ['L⁻²M¹T⁰', 'L²M⁻¹T¹', 'L⁻²M⁻¹T¹', 'L⁰M⁻¹T¹'],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Units and Measurements',
        subTopic: 'Dimensional Analysis',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Dimensional Analysis', 'Physical Quantities'],
        questionType: 'mcq',
      ),
      Question(
        id: 'CHEM0314',
        questionText:
            'A nucleus has mass number A₁ and volume V₁. Another nucleus has mass number A₂ and volume V₂. If relation between mass number is A₂ = 4A₁, then V₂/V₁ = ______',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Some Basic Concepts in Chemistry',
        subTopic: 'Nuclear Volume',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Nuclear Volume', 'Mass Number'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0315',
        questionText:
            'A sample of CaCO₃ and MgCO₃ weighed 2.21 g is ignited to constant weight of 1.152 g. The composition of the mixture is: (Given molar mass in g mol⁻¹, CaCO₃: 100, MgCO₃: 84)',
        options: [
          '1.187 g CaCO₃ + 1.023 g MgCO₃',
          '1.023 g CaCO₃ + 1.023 g MgCO₃',
          '1.187 g CaCO₃ + 1.187 g MgCO₃',
          '1.023 g CaCO₃ + 1.187 g MgCO₃'
        ],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Atomic Structure',
        subTopic: 'Stoichiometry',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Stoichiometry', 'Decomposition'],
        questionType: 'mcq',
      ),

      Question(
        id: 'CHEM0316',
        questionText:
            'The four quantum numbers for the electron in the outer most orbital of potassium (atomic no. 19) are:',
        options: [
          'n = 4, l = 2, m = -1, s = +1/2',
          'n = 4, l = 0, m = 0, s = +1/2',
          'n = 3, l = 0, m = -1, s = +1/2',
          'n = 2, l = 0, m = 0, s = +1/2'
        ],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'Classification of Elements and Periodicity in Properties',
        subTopic: 'Quantum Numbers',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Quantum Numbers', 'Electronic Configuration'],
        questionType: 'mcq',
      ),

      Question(
        id: 'CHEM0317',
        questionText:
            'Consider the following elements. Which of the following is/are true about A, B, C and D?\nA. Order of atomic radii: B < A < D < C\nB. Order of metallic character: B < A < D < C\nC. Size of the element: D < C < B < A\nD. Order of ionic radii: B⁺ < A⁺ < D⁺ < C⁺\nChoose the correct answer from the options given below:',
        options: [
          'A only',
          'A, B and D only',
          'A and B only',
          'B, C and D only'
        ],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'Chemical Bonding and Molecular Structure',
        subTopic: 'Periodic Trends',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Atomic Radius', 'Metallic Character', 'Ionic Radius'],
        questionType: 'mcq',
      ),

      Question(
        id: 'CHEM0318',
        questionText: 'Which of the following is least ionic?',
        options: ['BaCl₂', 'AgCl', 'KCl', 'CoCl₂'],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'Chemical Thermodynamics',
        subTopic: 'Ionic Character',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Ionic Character', 'Fajans Rule'],
        questionType: 'mcq',
      ),

      Question(
        id: 'CHEM0319',
        questionText:
            'A(g) ⇌ B(g) + 1/2 C(g). The correct relationship between Kp, α and equilibrium pressure P is:',
        options: [
          'Kp = α²P²/(2+α²)(1-α)',
          'Kp = α²P¹/²/(2+α²)(1-α)',
          'Kp = α²P²/(2+α²)',
          'Kp = α²P¹/²/(2+α²)'
        ],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'p-Block Elements',
        subTopic: 'Equilibrium Constant',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Equilibrium Constant', 'Degree of Dissociation'],
        questionType: 'mcq',
      ),

      Question(
        id: 'CHEM0320',
        questionText:
            'Given below are two statements:\nStatement I: S₈ solid undergoes disproportionation reaction under alkaline conditions to form S²⁻ and S₂O₃²⁻\nStatement II: ClO₄⁻ can undergo disproportionation reaction under acidic condition.\nIn the light of the above statements, choose the most appropriate answer from the options given below:',
        options: [
          'Statement I is correct but statement II is incorrect',
          'Statement I is incorrect but statement II is correct',
          'Both statement I and statement II are incorrect',
          'Both statement I and statement II are correct'
        ],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'p-Block Elements',
        subTopic: 'Disproportionation',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: [
          'Disproportionation',
          'Sulfur Chemistry',
          'Chlorine Chemistry'
        ],
        questionType: 'mcq',
      ),

      Question(
        id: 'CHEM0321',
        questionText:
            'Given below are two statements:\nStatement I: Group 13 trivalent halides get easily hydrolysed by water due to their covalent nature.\nStatement II: AlCl₃ upon hydrolysis in acidified aqueous solution forms octahedral [Al(H₂O)₆]³⁺ ion.\nIn the light of the above statements, choose the correct answer from the options given below:',
        options: [
          'Statement I is true but statement II is false',
          'Statement I is false but statement II is true',
          'Both statement I and statement II are false',
          'Both statement I and statement II are true'
        ],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Hydrocarbons',
        subTopic: 'Group 13 Elements',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Group 13 Halides', 'Hydrolysis'],
        questionType: 'mcq',
      ),

      Question(
        id: 'CHEM0322',
        questionText: 'Identify structure of 2,3-dibromo-1-phenylpentane.',
        options: ['(1)', '(2)', '(3)', '(4)'],
        correctAnswerIndex: 2,
        subject: 'Chemistry',
        topic: 'Purification and Characterisation of Organic Compounds',
        subTopic: 'Nomenclature',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['IUPAC Nomenclature', 'Structural Isomerism'],
        questionType: 'mcq',
      ),

      Question(
        id: 'CHEM0323',
        questionText:
            'The fragrance of flowers is due to the presence of some steam volatile organic compounds called essential oils. These are generally insoluble in water at room temperature but are miscible with water vapour in the vapour phase. A suitable method for the extraction of these oils from the flowers is:',
        options: [
          'crystallisation',
          'distillation under reduced pressure',
          'distillation',
          'steam distillation'
        ],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Organic Compounds Containing Oxygen',
        subTopic: 'Extraction Methods',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Steam Distillation', 'Essential Oils'],
        questionType: 'mcq',
      ),

      Question(
        id: 'CHEM0324',
        questionText: 'Major product of the following reaction is:',
        options: ['(1)', '(2)', '(3)', '(4)'],
        correctAnswerIndex: 2,
        subject: 'Chemistry',
        topic: 'Organic Compounds Containing Nitrogen',
        subTopic: 'Organic Reactions',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Organic Reactions', 'Reaction Mechanism'],
        questionType: 'mcq',
      ),

      Question(
        id: 'CHEM0325',
        questionText: 'Identify A and B in the following reaction sequence.',
        options: ['(1)', '(2)', '(3)', '(4)'],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'p-Block Elements',
        subTopic: 'Reaction Sequence',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Reaction Sequence', 'p-Block Chemistry'],
        questionType: 'mcq',
      ),
      Question(
        id: 'CHEM0326',
        questionText:
            'Choose the correct statements from the following:\nA. All group 16 elements form oxides of general formula EO₂ and EO₃ where E = S, Se, Te and Po. Both the types of oxides are acidic in nature.\nB. TeO₂ is an oxidising agent while SO₂ is reducing in nature.\nC. The reducing property decreases from H₂S to H₂Te down the group.\nD. The ozone molecule contains five lone pairs of electrons.\nChoose the correct answer from the options given below:',
        options: [
          'A and D only',
          'B and C only',
          'C and D only',
          'A and B only'
        ],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'd- and f-Block Elements',
        subTopic: 'Group 16 Elements',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Group 16 Elements', 'Oxides', 'Redox Properties'],
        questionType: 'mcq',
      ),

      Question(
        id: 'CHEM0327',
        questionText:
            'Choose the correct statements from the following:\nA. Mn₂O₇ is an oil at room temperature\nB. V₂O₅ reacts with acid to give VO₂⁺\nC. CrO is a basic oxide\nD. V₂O₅ does not react with acid\nChoose the correct answer from the options given below:',
        options: [
          'A, B and D only',
          'A and C only',
          'A, B and C only',
          'B and C only'
        ],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'Coordination Compounds',
        subTopic: 'Transition Metal Oxides',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Transition Metal Oxides', 'Chemical Properties'],
        questionType: 'mcq',
      ),

      Question(
        id: 'CHEM0328',
        questionText: 'Select the option with correct property:',
        options: [
          'Ni(CO)₄ and NiCl₄²⁻ both diamagnetic',
          'Ni(CO)₄ and NiCl₄²⁻ both paramagnetic',
          'NiCl₄²⁻ diamagnetic, Ni(CO)₄ paramagnetic',
          'Ni(CO)₄ diamagnetic, NiCl₄²⁻ paramagnetic'
        ],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Coordination Compounds',
        subTopic: 'Magnetic Properties',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Magnetic Properties', 'Coordination Compounds'],
        questionType: 'mcq',
      ),

      Question(
        id: 'CHEM0329',
        questionText:
            'Match List I with List II\nLIST I (Complex ion) - LIST II (Electronic Configuration)\nA. Cr(H₂O)₆³⁺ - I. t₂g⁶eg⁰\nB. Fe(H₂O)₆³⁺ - II. t₂g³eg⁰\nC. Ni(H₂O)₆²⁺ - III. t₂g³eg²\nD. V(H₂O)₆³⁺ - IV. t₂g⁶eg²\nChoose the correct answer from the options given below:',
        options: [
          'A-III, B-II, C-IV, D-I',
          'A-IV, B-I, C-II, D-III',
          'A-IV, B-III, C-I, D-II',
          'A-II, B-III, C-IV, D-I'
        ],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Some Basic Principles of Organic Chemistry',
        subTopic: 'Crystal Field Theory',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Crystal Field Theory', 'Electronic Configuration'],
        questionType: 'mcq',
      ),

      Question(
        id: 'CHEM0330',
        questionText:
            'The correct order of reactivity in electrophilic substitution reaction of the following compounds is:',
        options: [
          'B > C > A > D',
          'D > C > B > A',
          'A > B > C > D',
          'B > A > C > D'
        ],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Organic Compounds Containing Nitrogen',
        subTopic: 'Electrophilic Substitution',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Electrophilic Substitution', 'Reactivity Order'],
        questionType: 'mcq',
      ),

      Question(
        id: 'CHEM0331',
        questionText: 'Identify the name reaction.',
        options: [
          'Stephen reaction',
          'Etard reaction',
          'Gatterman-Koch reaction',
          'Rosenmund reduction'
        ],
        correctAnswerIndex: 2,
        subject: 'Chemistry',
        topic: 'Organic Compounds Containing Nitrogen',
        subTopic: 'Name Reactions',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Name Reactions', 'Organic Chemistry'],
        questionType: 'mcq',
      ),

      Question(
        id: 'CHEM0332',
        questionText: '',
        options: ['(1)', '(2)', '(3)', '(4)'],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Organic Compounds Containing Nitrogen',
        subTopic: 'Organic Reactions',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Organic Reactions'],
        questionType: 'mcq',
      ),

      Question(
        id: 'CHEM0333',
        questionText:
            'The azo-dye Y formed in the following reactions is:\nSulphanilic acid + NaNO₂ + CH₃COOH → X',
        options: ['(1)', '(2)', '(3)', '(4)'],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Some Basic Concepts in Chemistry',
        subTopic: 'Azo Dye Formation',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Azo Dye', 'Diazotization'],
        questionType: 'mcq',
      ),

      Question(
        id: 'CHEM0334',
        questionText:
            'Given below are two statements:\nStatement I: Aniline reacts with con. H₂SO₄ followed by heating at 453-473 K gives p-aminobenzene sulphonic acid, which gives blood red colour in the \'Lassaigne\'s test\'.\nStatement II: In Friedel-Craft\'s alkylation and acylation reactions, aniline forms salt with the AlCl₃ catalyst. Due to this, nitrogen of aniline acquires a positive charge and acts as deactivating group.\nIn the light of the above statements, choose the correct answer from the options given below:',
        options: [
          'Statement I is false but statement II is true',
          'Both statement I and statement II are false',
          'Statement I is true but statement II is false',
          'Both statement I and statement II are true'
        ],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Organic Compounds Containing Oxygen',
        subTopic: 'Aniline Reactions',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Aniline Reactions', 'Friedel-Crafts Reaction'],
        questionType: 'mcq',
      ),

      Question(
        id: 'CHEM0335',
        questionText:
            'The molarity of 1L orthophosphoric acid H₃PO₄ having 70% purity by weight (specific gravity 1.54 g cm⁻³) is ______ M. (Molar mass of H₃PO₄ = 98 g mol⁻¹)',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Chemical Thermodynamics',
        subTopic: 'Molarity Calculation',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Molarity', 'Percentage Purity'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0336',
        questionText:
            'Identify major product \'P\' formed in the following reaction.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Hydrocarbons',
        subTopic: 'Organic Reactions',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Organic Reactions', 'Product Identification'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0337',
        questionText:
            'If 5 moles of an ideal gas expands from 10L to a volume of 100L at 300K under isothermal and reversible condition then work, w, is -x J. The value of x is ______. (Given R = 8.314 J K⁻¹ mol⁻¹)',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Electrochemistry',
        subTopic: 'Isothermal Work',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Isothermal Expansion', 'Work Done'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0338',
        questionText:
            'Number of isomeric products formed by monochlorination of 2-methylbutane in presence of sunlight is _______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Chemical Kinetics',
        subTopic: 'Monochlorination',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Monochlorination', 'Structural Isomers'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0339',
        questionText:
            'The values of conductivity of some materials at 298.15 K in S m⁻¹ are: 2.1×10³, 1.0×10⁻¹⁶, 1.2×10, 3.91, 1.5×10⁻², 1×10⁻⁷, 1.0×10³. The number of conductors among the materials is ______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Redox Reactions and Electrochemistry',
        subTopic: 'Conductivity',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Electrical Conductivity', 'Materials Classification'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0340',
        questionText:
            'r = k[A] for a reaction, 50% of A is decomposed in 120 minutes. The time taken for 90% decomposition of A is ______ minutes.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'd- and f-Block Elements',
        subTopic: 'First Order Kinetics',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['First Order Reaction', 'Half Life'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0341',
        questionText:
            'Number of moles of H⁺ ions required by 1 mole of MnO₄⁻ to oxidise oxalate ion to CO₂ is ______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Organic Compounds Containing Nitrogen',
        subTopic: 'Redox Reactions',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Redox Reactions', 'Stoichiometry'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0342',
        questionText:
            'In the reaction of potassium dichromate, potassium chloride and sulfuric acid (conc.), the oxidation state of the chromium in the product is + ______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Biomolecules',
        subTopic: 'Oxidation State',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Oxidation State', 'Chromium Chemistry'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0343',
        questionText:
            'A compound x with molar mass 108 g mol⁻¹ undergoes acetylation to give product with molar mass 192 g mol⁻¹. The number of amino groups in the compound x is ______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Trigonometry',
        subTopic: 'Acetylation',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Acetylation', 'Amino Groups'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0344',
        questionText:
            'From the vitamins A, B₁, B₆, B₁₂, C, D, E and K, the number of vitamins that can be stored in our body is ______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Complex Numbers and Quadratic Equations',
        subTopic: 'Vitamins',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Vitamins', 'Storage in Body'],
        questionType: 'numerical',
      ),
      Question(
        id: 'MATH0311',
        questionText:
            'The number of solutions of the equation e^(sinx) - 2e^(-sinx) = 2 is:',
        options: ['2', 'more than 2', '1', '0'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Permutations and Combinations',
        subTopic: 'Exponential Equations',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Exponential Equations', 'Trigonometric Functions'],
        questionType: 'mcq',
      ),

      Question(
        id: 'MATH0312',
        questionText:
            'Let z₁ and z₂ be two complex numbers such that z₁ + z₂ = 5 and z₁³ + z₂³ = 20 + 15i. Then z₁⁴ + z₂⁴ equals:',
        options: ['30√3', '75', '15√15', '25√3'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Sequence and Series',
        subTopic: 'Complex Numbers',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Complex Numbers', 'Polynomial Equations'],
        questionType: 'mcq',
      ),

      Question(
        id: 'MATH0313',
        questionText:
            'The number of ways in which 21 identical apples can be distributed among three children such that each child gets at least 2 apples, is:',
        options: ['406', '130', '142', '136'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Permutations and Combinations',
        subTopic: 'Distribution',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Distribution', 'Combinations'],
        questionType: 'mcq',
      ),

      Question(
        id: 'MATH0314',
        questionText:
            'Let 2nd, 8th and 44th terms of a non-constant A.P. be respectively the 1st, 2nd and 3rd terms of G.P. If the first term of A.P. is 1 then the sum of first 20 terms is equal to:',
        options: ['980', '960', '990', '970'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: 'Arithmetic and Geometric Progressions',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['AP and GP', 'Sequence Sum'],
        questionType: 'mcq',
      ),

      Question(
        id: 'MATH0315',
        questionText:
            'If for some m, n; ⁶Cₘ + 2⁶Cₘ₊₁ + ⁶Cₘ₊₂ > ⁸C₃ and ⁿ⁻¹P₃ : ⁿP₄ = 1:8, then ⁿPₘ₊₁ + ⁿ⁺¹Cₘ is equal to:',
        options: ['380', '376', '384', '372'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: 'Permutations and Combinations',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Combinations', 'Permutations'],
        questionType: 'mcq',
      ),

      Question(
        id: 'MATH0316',
        questionText:
            'Let A(a, b), B(3, 4) and (-6, -8) respectively denote the centroid, circumcentre and orthocentre of a triangle. Then, the distance of the point P(2a+3, 7b+5) from the line 2x+3y-4=0 measured parallel to the line x-2y-1=0 is:',
        options: ['15√5/7', '17√5/6', '17√5/7', '√5/17'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: 'Triangle Centers',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Triangle Centers', 'Distance Formula'],
        questionType: 'mcq',
      ),

      Question(
        id: 'MATH0317',
        questionText:
            'Let a variable line passing through the centre of the circle x²+y²-16x-4y=0, meet the positive coordinate axes at the points A and B. Then the minimum value of OA+OB, where O is the origin, is equal to:',
        options: ['12', '18', '20', '24'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Limit, Continuity and Differentiability',
        subTopic: 'Coordinate Geometry',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Coordinate Geometry', 'Optimization'],
        questionType: 'mcq',
      ),

      Question(
        id: 'MATH0318',
        questionText:
            'Let P be a parabola with vertex (2, 3) and directrix 2x+y=6. Let an ellipse E: x²/a² + y²/b² = 1, a > b of eccentricity 1/√2 pass through the focus of the parabola P. Then the square of the length of the latus rectum of E, is:',
        options: ['385/8', '347/8', '512/25', '656/25'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Statistics and Probability',
        subTopic: 'Conic Sections',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Parabola', 'Ellipse', 'Latus Rectum'],
        questionType: 'mcq',
      ),

      Question(
        id: 'MATH0319',
        questionText:
            'Let f: R → (0,∞) be strictly increasing function such that lim(x→∞) f(7x)/f(5x) = 1. Then, the value of lim(x→∞) [f(x)]⁻¹ is equal to:',
        options: ['4/7', '0', '7/5', '1'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Matrices and Determinants',
        subTopic: 'Limits',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Limits', 'Increasing Functions'],
        questionType: 'mcq',
      ),

      Question(
        id: 'MATH0320',
        questionText:
            'Let the mean and the variance of 6 observations a, b, 68, 44, 48, 60 be 55 and 194, respectively. If a > b, then a + 3b is:',
        options: ['200', '190', '180', '210'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Trigonometry',
        subTopic: 'Statistics',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Mean', 'Variance', 'Statistics'],
        questionType: 'mcq',
      ),

      Question(
        id: 'MATH0321',
        questionText:
            'Let A be a 3×3 real matrix such that A[1,0,1]ᵀ = [2,0,1]ᵀ, A[1,1,0]ᵀ = [4,0,1]ᵀ, A[0,1,1]ᵀ = [2,1,0]ᵀ. Then, the system (A-3I)[x,y,z]ᵀ = [1,2,3]ᵀ has:',
        options: [
          'unique solution',
          'exactly two solutions',
          'no solution',
          'infinitely many solutions'
        ],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Sets, Relations and Functions',
        subTopic: 'Linear Algebra',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Linear Systems', 'Matrix Algebra'],
        questionType: 'mcq',
      ),

      Question(
        id: 'MATH0322',
        questionText:
            'If a = sin⁻¹(sin5) and b = cos⁻¹(cos5), then a² + b² is equal to:',
        options: ['4π² + 25', '8π² - 40π + 50', '4π² - 20π + 50', '25'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Limit, Continuity and Differentiability',
        subTopic: 'Inverse Trigonometric Functions',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Inverse Trigonometric Functions', 'Trigonometry'],
        questionType: 'mcq',
      ),

      Question(
        id: 'MATH0323',
        questionText:
            'If the function f: (-∞, -1] → [a,b] defined by f(x) = e^(x³-3x+1) is one-one and onto, then the distance of the point P(2b+4, a+2) from the line x+e⁻³y=4 is:',
        options: ['2√(1+e⁶)', '4√(1+e⁶)', '3√(1+e⁶)', '√(1+e⁶)'],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Integral Calculus',
        subTopic: 'Functions and Distance',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['One-one Onto Functions', 'Distance Formula'],
        questionType: 'mcq',
      ),

      Question(
        id: 'MATH0324',
        questionText:
            'Consider the function f: (0,∞) → R defined by f(x) = |e - logₑx|. If m and n be respectively the number of points at which f is not continuous and f is not differentiable, then m+n is:',
        options: ['0', '3', '1', '2'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Integral Calculus',
        subTopic: 'Continuity and Differentiability',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Continuity', 'Differentiability'],
        questionType: 'mcq',
      ),

      Question(
        id: 'MATH0325',
        questionText:
            'Let f,g: (0,∞) → R be two functions defined by f(x) = ∫₋ₓˣ (t-t²)e⁻ᵗ² dt and g(x) = ∫₀ˣ² (t/2)e⁻ᵗ² dt. Then the value of 9f(logₑ9) + g(logₑ9) is equal to:',
        options: ['6', '9', '8', '10'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Differential Equations',
        subTopic: 'Definite Integrals',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Definite Integrals', 'Function Composition'],
        questionType: 'mcq',
      ),

      Question(
        id: 'MATH0326',
        questionText:
            'The area of the region enclosed by the parabola y = 4x - x² and 3y = (x-4)² is equal to:',
        options: ['32/9', '4', '6', '14/3'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Three Dimensional Geometry',
        subTopic: 'Area Between Curves',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Area Between Curves', 'Integration'],
        questionType: 'mcq',
      ),

      Question(
        id: 'MATH0327',
        questionText:
            'The temperature T(t) of a body at time t=0 is 160°F and it decreases continuously as per the differential equation dT/dt = -K(T-80), where K is positive constant. If T(15)=120°F, then T(45) is equal to:',
        options: ['85°F', '95°F', '90°F', '80°F'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Three Dimensional Geometry',
        subTopic: 'Differential Equations',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Differential Equations', 'Cooling Law'],
        questionType: 'mcq',
      ),

      Question(
        id: 'MATH0328',
        questionText:
            'Let (α,β,γ) be mirror image of the point (2,3,5) in the line (x-1)/2 = (y-2)/3 = (z-3)/4. Then 2α+3β+4γ is equal to:',
        options: ['32', '33', '31', '34'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Statistics and Probability',
        subTopic: '3D Geometry',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['3D Geometry', 'Mirror Image'],
        questionType: 'mcq',
      ),

      Question(
        id: 'MATH0329',
        questionText:
            'The shortest distance between lines L₁ and L₂, where L₁: (x-1)/2 = (y+1)/-3 = (z+4)/2 and L₂ is the line passing through the points A(-4,4,3), B(-1,6,3) and perpendicular to the line (x-3)/-2 = y/3 = (z-1)/1, is:',
        options: ['121/√221', '24/√117', '141/√221', '42/√117'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Complex Numbers and Quadratic Equations',
        subTopic: '3D Geometry',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Shortest Distance', '3D Lines'],
        questionType: 'mcq',
      ),

      Question(
        id: 'MATH0330',
        questionText:
            'A coin is biased so that a head is twice as likely to occur as a tail. If the coin is tossed 3 times, then the probability of getting two tails and one head is:',
        options: ['2/9', '1/9', '2/27', '1/27'],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Binomial Theorem and Its Simple Applications',
        subTopic: 'Probability',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Probability', 'Binomial Distribution'],
        questionType: 'mcq',
      ),

      Question(
        id: 'MATH0331',
        questionText:
            'Let a,b,c be the length of three sides of a triangle satisfying the condition (a²+b²)x² - 2b(a+c)x + (b²+c²) = 0. If the set of all possible values of x is in the interval (α,β), then 12(α²+β²) is equal to ______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: 'Quadratic Equations',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Quadratic Equations', 'Triangle Inequality'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0332',
        questionText:
            'Let the coefficient of xʳ in the expansion of (x+3)ⁿ⁻¹ + (x+3)ⁿ⁻²(x+2) + (x+3)ⁿ⁻³(x+2)² + ... + (x+2)ⁿ⁻¹ be αᵣ. If ∑αᵣ = βⁿ - γⁿ, β,γ ∈ N, then the value of β²+γ² equals ______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Limit, Continuity and Differentiability',
        subTopic: 'Binomial Expansion',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Binomial Expansion', 'Series Sum'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0333',
        questionText:
            'Let A(-2,-1), B(1,0), C(α,β) and D(γ,δ) be the vertices of a parallelogram ABCD. If the point C lies on 2x-y=5 and the point D lies on 3x-2y=6, then the value of α+β+γ+δ is equal to ______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Sets, Relations and Functions',
        subTopic: 'Coordinate Geometry',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Parallelogram', 'Coordinate Geometry'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0334',
        questionText:
            'If lim(x→0) (ax²eˣ - b logₑ(1+x) + cxe⁻ˣ)/(x²sinx) = 1, then 16(a²+b²+c²) is equal to ______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Matrices and Determinants',
        subTopic: 'Limits',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Limits', 'Series Expansion'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0335',
        questionText:
            'Let A = {1,2,3,...,100}. Let R₁ be a relation on A defined by (x,y) ∈ R₁ if and only if 2x = 3y. Let R be a symmetric relation on A such that R₁ ⊂ R and the number of elements in R is n. Then the minimum value of n is ______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Integral Calculus',
        subTopic: 'Relations',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Relations', 'Set Theory'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0336',
        questionText:
            'Let A be a 3×3 matrix and det(A) = 2. If n = det(adj(adj(...adj(A)...))), then the remainder when n is divided by 9 is equal to ______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Differential Equations',
        subTopic: 'Matrices',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Matrices', 'Adjoint', 'Determinant'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0337',
        questionText:
            '∫₀^(π/3) (120x²sinxcosx)/(sin⁴x+cos⁴x) dx is equal to ______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Vector Algebra',
        subTopic: 'Definite Integrals',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Definite Integrals', 'Trigonometric Functions'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0338',
        questionText:
            'Let y = y(x) be the solution of the differential equation sec²x dx + e²ʸ(tan²x + tanx)dy = 0, 0 < x < π/2, y(π/4) = 0. If y(π/6) = α, then e⁸ᵅ is equal to ______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Three Dimensional Geometry',
        subTopic: 'Differential Equations',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Differential Equations', 'Separation of Variables'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0339',
        questionText:
            'Let a = 3i + 2j + k, b = 2i - j + 3k and c be a vector such that (a+b)×c = 2(a×b) + 24j - 6k and (2a-b+i)·c = -3. Then |c|² is equal to ______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Vector Algebra',
        subTopic: 'Vector Operations',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Vector Cross Product', 'Vector Dot Product'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0340',
        questionText:
            'A line passes through A(4,-6,-2) and B(16,-2,4). The point P(a,b,c) where a,b,c are non-negative integers, on the line AB lies at a distance of 21 units from the point A. The distance between the points P(a,b,c) and Q(4,-12,3) is equal to ______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: '3D Geometry',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['3D Geometry', 'Distance Formula'],
        questionType: 'numerical',
      ),
      Question(
        id: 'PHY0344',
        questionText:
            'If the percentage errors in measuring the length and the diameter of a wire are 0.1% each, the percentage error in measuring its resistance will be:',
        options: ['0.2%', '0.3%', '0.1%', '0.144%'],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Units and Measurements',
        subTopic: 'Error Analysis',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Error Analysis', 'Resistance Measurement'],
        questionType: 'mcq',
      ),
      Question(
        id: 'CHEM0345',
        questionText:
            'The correct sequence of electron gain enthalpy of the elements listed below is:\nA. Ar\nB. Br\nC. F\nD. S\nChoose the most appropriate from the options given below:',
        options: [
          'C > B > D > A',
          'A > D > B > C',
          'A > D > C > B',
          'D > C > B > A'
        ],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'Classification of Elements and Periodicity in Properties',
        subTopic: 'Electron Gain Enthalpy',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Electron Gain Enthalpy', 'Periodic Trends'],
        questionType: 'mcq',
      ),

      Question(
        id: 'CHEM0346',
        questionText:
            'The linear combination of atomic orbitals to form molecular orbitals takes place only when the combining atomic orbitals:\nA. have the same energy\nB. have the minimum overlap\nC. have same symmetry about the molecular axis\nD. have different symmetry about the molecular axis\nChoose the most appropriate from the options given below:',
        options: [
          'A, B, C only',
          'A and C only',
          'B, C, D only',
          'B and D only'
        ],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'Chemical Bonding and Molecular Structure',
        subTopic: 'Molecular Orbital Theory',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Molecular Orbital Theory', 'LCAO'],
        questionType: 'mcq',
      ),

      Question(
        id: 'CHEM0347',
        questionText:
            'For the given reaction, choose the correct expression of Kc from the following:\nFe³⁺(aq) + SCN⁻(aq) ⇌ Fe(SCN)²⁺(aq)',
        options: [
          'Kc = [Fe(SCN)²⁺] / [Fe³⁺][SCN⁻]',
          'Kc = [Fe³⁺][SCN⁻] / [Fe(SCN)²⁺]',
          'Kc = [Fe(SCN)²⁺] / [Fe³⁺]²[SCN⁻]²',
          'Kc = [Fe(SCN)²⁺]² / [Fe³⁺][SCN⁻]'
        ],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Equilibrium',
        subTopic: 'Equilibrium Constant',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Equilibrium Constant', 'Complex Formation'],
        questionType: 'mcq',
      ),
      Question(
        id: 'CHEM0358',
        questionText:
            'Give below are two statements: Statement-I : Noble gases have very high boiling points. Statement-II: Noble gases are monoatomic gases. They are held together by strong dispersion forces. Because of this they are liquefied at very low temperature. Hence, they have very high boiling points. In the light of the above statements. choose the correct answer from the options given below:',
        options: [
          'Statement I is false but Statement II is true',
          'Both Statement I and Statement II are true',
          'Statement I is true but Statement II is false',
          'Both Statement I and Statement II are false'
        ],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'p-Block Elements',
        subTopic: 'Noble Gases',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Noble Gases', 'Boiling Points', 'Dispersion Forces'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'CHEM0359',
        questionText:
            'Identify correct statements from below: A. The chromate ion is square planar. B. Dichromates are generally prepared from chromates. C. The green manganate ion is diamagnetic. D. Dark green coloured K₂MnO₄ disproportionates in a neutral or acidic medium to give permanganate. E. With increasing oxidation number of transition metal, ionic character of the oxides decreases. Choose the correct answer from the options given below:',
        options: [
          'B, C, D only',
          'A, D, E only',
          'A, B, C only',
          'B, D, E only'
        ],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'd- and f-Block Elements',
        subTopic: 'Transition Metal Compounds',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Chromates', 'Manganates', 'Transition Metal Oxides'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'CHEM0360',
        questionText:
            'The correct statements from the following are: A. The strength of anionic ligands can be explained by crystal field theory. B. Valence bond theory does not give a quantitative interpretation of kinetic stability of coordination compounds. C. The hybridization involved in formation of [Ni(CN)₄]²⁻ complex is dsp². D. The number of possible isomer(s) of cis-[PtCl₂(en)]²⁺ is one. Choose the correct answer from the options given below:',
        options: ['A, D only', 'A, C only', 'B, D only', 'B, C only'],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Coordination Compounds',
        subTopic: 'Coordination Chemistry Theories',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: [
          'Crystal Field Theory',
          'Valence Bond Theory',
          'Hybridization',
          'Isomerism'
        ],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'CHEM0361',
        questionText:
            'Given below are two statements: One is labelled as Assertion A and the other is labelled as Reason R: Assertion A: pKₐ value of phenol is 10.0 while that of ethanol is 15.9. Reason R: Ethanol is stronger acid than phenol. In the light of the above statements, choose the correct answer from the options given below:',
        options: [
          'A is true but R is false',
          'A is false but R is true',
          'Both A and R are true and R is the correct explanation of A',
          'Both A and R are true but R is NOT the correct explanation of A'
        ],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Organic Compounds Containing Oxygen',
        subTopic: 'Acidity of Alcohols and Phenols',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Acidity', 'pKa Values', 'Phenol', 'Ethanol'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'CHEM0362',
        questionText:
            'Given below are two statements: One is labelled as Assertion A and the other is labelled as Reason R: Assertion A: Alcohols react both as nucleophiles and electrophiles. Reason R: Alcohols react with active metals such as sodium, potassium and aluminum to yield corresponding alkoxides and liberate hydrogen. In the light of the above statements, choose the correct answer from the options given below:',
        options: [
          'A is false but R is true',
          'A is true but R is false',
          'Both A and R are true and R is the correct explanation of A',
          'Both A and R are true but R is NOT the correct explanation of A'
        ],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Organic Compounds Containing Oxygen',
        subTopic: 'Chemical Properties of Alcohols',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: [
          'Alcohols',
          'Nucleophiles',
          'Electrophiles',
          'Reactivity with Metals'
        ],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'CHEM0363',
        questionText: 'The compound that is white in color is',
        options: [
          'ammonium sulphide',
          'lead sulphate',
          'lead iodide',
          'ammonium arsinomolybdate'
        ],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'p-Block Elements',
        subTopic: 'Chemical Compounds and Colors',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Compound Colors', 'Lead Compounds', 'Sulphides', 'Iodides'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'CHEM0364',
        questionText:
            'Match List I with List II List-I List-II A. Glucose/NaHCO₃/∆ I. Gluconic acid B. Glucose/HNO₃ II. No reaction C. Glucose/HI/∆ III. n-hexane D. Glucose/Bromine water IV. Saccharic acid Choose the correct answer from the options given below:',
        options: [
          'A-IV, B-I, C-III, D-II',
          'A-II, B-IV, C-III, D-I',
          'A-III, B-II, C-I, D-IV',
          'A-I, B-IV, C-III, D-II'
        ],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'Some Basic Concepts in Chemistry',
        subTopic: 'Glucose Reactions',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: [
          'Glucose Reactions',
          'Oxidation',
          'Reduction',
          'Bromine Water Test'
        ],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'CHEM0365',
        questionText:
            'Number of moles of methane required to produce 22g CO₂ after combustion is x×10⁻² moles. The value of x is',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Atomic Structure',
        subTopic: 'Stoichiometry Calculations',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Stoichiometry', 'Combustion', 'Mole Concept'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0366',
        questionText:
            'The ionization energy of sodium in kJ mol⁻¹. If electromagnetic radiation of wavelength 242 nm is just sufficient to ionize sodium atom is ______.(nearest integer)',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Chemical Bonding and Molecular Structure',
        subTopic: 'Ionization Energy',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: [
          'Ionization Energy',
          'Electromagnetic Radiation',
          'Wavelength-Energy Relationship'
        ],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0367',
        questionText:
            'The number of species from the following in which the central atom uses sp³ hybrid orbitals in its bonding is _________. NH₃, SO₂, SiO₂, BeCl₂, CO₂, H₂O, CH₄, BF₃',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Chemical Thermodynamics',
        subTopic: 'Chemical Bonding and Hybridization',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Hybridization', 'sp³ Hybridization', 'Molecular Geometry'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0368',
        questionText:
            'Consider the following reaction at 298 K. 3O₂(g) ⇌ 2O₃(g). Kp = 2.47×10⁻²⁹. ΔG⁰ for the reaction is _________ kJ. (Given R = 8.314 JK⁻¹ mol⁻¹) Round off your answer to the nearest integer.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Hydrocarbons',
        subTopic: 'Chemical Thermodynamics',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: [
          'Gibbs Free Energy',
          'Equilibrium Constant',
          'Thermodynamics'
        ],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0369',
        questionText:
            'Number of alkanes obtained on electrolysis of a mixture of CH₃COONa and C₂H₅COONa is_____.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Electrochemistry',
        subTopic: 'Kolbe Electrolysis',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Kolbe Electrolysis', 'Alkanes', 'Electrolysis'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0370',
        questionText:
            'One Faraday of electricity liberates x×10⁻¹ gram atom of copper from copper sulphate, x is______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'd- and f-Block Elements',
        subTopic: 'Electrochemical Equivalents',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Faraday Law', 'Electrochemistry', 'Copper'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0371',
        questionText:
            'The Spin only Magnetic moment for [Ni(NH₃)₆]²⁺ is______× 10⁻¹ BM. (given Atomic number of Ni : 28) Round off your answer to the nearest integer.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Organic Compounds Containing Oxygen',
        subTopic: 'Magnetic Properties',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: [
          'Magnetic Moment',
          'Coordination Compounds',
          'Nickel Complexes'
        ],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0372',
        questionText:
            'The total number of hydrogen atoms in product A and product B is__________.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Purification and Characterisation of Organic Compounds',
        subTopic: 'Organic Analysis',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Hydrogen Atoms', 'Organic Products', 'Molecular Formula'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0373',
        questionText:
            'The product of the following reaction is P. The number of hydroxyl groups present in the product P is________.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Some Basic Concepts in Chemistry',
        subTopic: 'Functional Groups',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Hydroxyl Groups', 'Organic Reactions', 'Functional Groups'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0341',
        questionText:
            'Molar mass of the salt from NaBr, NaNO₃, KI and CaF₂ which does not evolve coloured vapours on heating with concentrated H₂SO₄ is ____ g mol⁻¹, (Molar mass in g mol⁻¹ : Na : 23, N : 14, K : 39, O : 16, Br : 80, I : 127, F : 19, Ca : 40 )',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Sets, Relations and Functions',
        subTopic: 'Stoichiometry and Molar Mass',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Molar Mass', 'Chemical Reactions', 'Salts'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0342',
        questionText:
            'Let S be the set of positive integral values of a for which (a𝑥² + 2(a+1)𝑥 + 9a + 4)/(𝑥² - 8𝑥 + 32) < 0, ∀𝑥 ∈ ℝ. Then, the number of elements in S is:',
        options: ['1', '0', '∞', '3'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Quadratic Equations and Complex Numbers',
        subTopic: 'Inequalities',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Inequalities', 'Quadratic Expressions', 'Set Theory'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'MATH0343',
        questionText:
            'For 0 < c < b < a, let (a+b–2c)𝑥² + (b+c–2a)𝑥 + (c+a–2b) = 0 and α ≠ 1 be one of its root. Then, among the two statements (I) If α ∈ (-1, 0), then b cannot be the geometric mean of a and c. (II) If α ∈ (0, 1), then b may be the geometric mean of a and c.',
        options: [
          'Both (I) and (II) are true',
          'Neither (I) nor (II) is true',
          'Only (II) is true',
          'Only (I) is true'
        ],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Sequence and Series',
        subTopic: 'Quadratic Equations and Geometric Mean',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: [
          'Quadratic Equations',
          'Geometric Mean',
          'Roots of Equations'
        ],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'MATH0344',
        questionText:
            'The sum of the series 1/(1−3⋅1²+1⁴) + 1/(1−3⋅2²+2⁴) + 1/(1−3⋅3²+3⁴) + ... up to 10 terms is',
        options: ['45/109', '-45/109', '55/109', '-55/109'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: 'Series and Sequences',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Series Summation', 'Algebraic Series', 'Sequence Patterns'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'MATH0345',
        questionText:
            'Let α, β, γ, δ ∈ Z and let A(α, β), B(1, 0), C(γ, δ) and D(1, 2) be the vertices of a parallelogram ABCD. If AB = √10 and the points A and C lie on the line 3𝑦 = 2𝑥+1, then 2α+β+γ+δ is equal to',
        options: ['10', '5', '12', '8'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: 'Coordinate Geometry of Parallelograms',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Coordinate Geometry', 'Parallelograms', 'Distance Formula'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'MATH0346',
        questionText:
            'If one of the diameters of the circle 𝑥²+𝑦²-10𝑥+4𝑦+13 = 0 is a chord of another circle C, whose center is the point of intersection of the lines 2𝑥+3𝑦 = 12 and 3𝑥-2𝑦 = 5, then the radius of the circle C is',
        options: ['√20', '4', '6', '3√2'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Three Dimensional Geometry',
        subTopic: 'Circle Geometry',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Circle Geometry', 'Chords', 'Intersection Points'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'MATH0347',
        questionText:
            'If the foci of a hyperbola are same as that of the ellipse 𝑥²/9 + 𝑦²/25 = 1 and the eccentricity of the hyperbola is 2 times the eccentricity of the ellipse, then the smaller focal distance of the point (√2, 14/5) on the hyperbola, is equal to',
        options: [
          '(7√2/5) - (8/3)',
          '(14√2/5) - (4/3)',
          '(14√2/5) - (16/3)',
          '(7√2/5) + (8/3)'
        ],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Limit, Continuity and Differentiability',
        subTopic: 'Conic Sections',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Hyperbola', 'Ellipse', 'Focal Distance', 'Eccentricity'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'MATH0348',
        questionText: 'lim (𝑥→0) (𝑒^(2sin𝑥) - 2sin𝑥 - 1)/𝑥²',
        options: [
          'is equal to -1',
          'does not exist',
          'is equal to 1',
          'is equal to 2'
        ],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Binomial Theorem and Its Simple Applications',
        subTopic: 'Limits',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Limits', 'Exponential Functions', 'Trigonometric Limits'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'MATH0349',
        questionText:
            'Let a be the sum of all coefficients in the expansion of (1 – 2𝑥+2𝑥²)²⁰²³ (3-4𝑥²+2𝑥³)²⁰²⁴ and b = lim (𝑥→0) (∫₀ˣ log(1+𝑡) 𝑑𝑡)/(𝑡²⁰²⁴+1)/𝑥². If the equations c𝑥²+𝑑𝑥+𝑒 = 0 and 2b𝑥²+a𝑥+4 = 0 have a common root, where c, d, e ∈ R, then d : c : e equals',
        options: ['2 : 1 : 4', '4 : 1 : 4', '1 : 2 : 4', '1 : 1 : 4'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic:
            'Differential Calculus (Limit, Continuity and Differentiability)',
        subTopic: 'Binomial Expansion and Limits',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: [
          'Binomial Expansion',
          'Limits',
          'Common Roots',
          'Quadratic Equations'
        ],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'MATH0350',
        questionText:
            'If 𝑓(𝑥) = |𝑥³ 2𝑥²+1 1+3𝑥; 3𝑥²+2 2𝑥 𝑥³+6; 𝑥³−𝑥 4 𝑥²−2| for all 𝑥 ∈ ℝ, then 2𝑓(0)+𝑓′(0) is equal to',
        options: ['48', '24', '42', '18'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Matrices and Determinants',
        subTopic: 'Determinants and Differentiation',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Determinants', 'Differentiation', 'Matrix Functions'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'MATH0351',
        questionText:
            'If the system of linear equations 𝑥-2𝑦+𝑧 = -4; 2𝑥+𝛼𝑦+3𝑧 = 5; 3𝑥-𝑦+𝛽𝑧 = 3 has infinitely many solutions, then 12𝛼+13𝛽 is equal to',
        options: ['60', '64', '54', '58'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Trigonometry',
        subTopic: 'Linear Equations',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: [
          'Linear Equations',
          'Infinite Solutions',
          'System of Equations'
        ],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'MATH0352',
        questionText:
            'For α,β,γ ≠ 0. If sin⁻¹α+sin⁻¹β+sin⁻¹γ = π and (α+β+γ)(α−γ+β) = 3αβ, then γ equal to',
        options: ['√3/2', '1/2', '√2/2', '√3-1/2√2'],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Relations and Functions',
        subTopic: 'Inverse Trigonometric Functions',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: [
          'Inverse Trigonometric Functions',
          'Trigonometric Identities',
          'Algebraic Equations'
        ],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'MATH0353',
        questionText:
            'If 𝑓(𝑥) = (4𝑥+3)/(6𝑥-4), 𝑥 ≠ 2/3 and 𝑓𝑜𝑓 (𝑥) = 𝑔(𝑥), where 𝑔:𝑅-{2/3} → 𝑅-{2/3}, then 𝑔𝑜𝑔𝑜𝑔 (4) is equal to',
        options: ['-19/20', '19/20', '-4', '4'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Relations and Functions',
        subTopic: 'Function Composition',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: [
          'Function Composition',
          'Rational Functions',
          'Iterated Functions'
        ],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'MATH0354',
        questionText:
            'Let 𝑔(𝑥) be a linear function and 𝑓(𝑥) = {𝑔(𝑥), 𝑥 ≤ 0; 1/(1+𝑥ˣ), 𝑥 > 0} is continuous at 𝑥 = 0. If 𝑓′(1) = 𝑓(−1), then the value of 𝑔(3) is',
        options: [
          '(1/3)logₑ(4/9)',
          '(1/3)logₑ(4/9)+1',
          '(4/3)logₑ(1/9)−1',
          '(4/3)logₑ(1/9𝑒)'
        ],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Limit, Continuity and Differentiability',
        subTopic: 'Continuity and Differentiability',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Continuity', 'Differentiability', 'Piecewise Functions'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'MATH0355',
        questionText:
            'The area of the region {(𝑥, 𝑦):𝑦² ≤ 4𝑥, 𝑥 < 4, (𝑥𝑦(𝑥-1)(𝑥-2))/((𝑥-3)(𝑥-4)) > 0} is',
        options: ['16/3', '64/3', '8/3', '32/3'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Integral Calculus',
        subTopic: 'Area Calculation',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: [
          'Area Calculation',
          'Integration',
          'Region Bounded by Curves'
        ],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'MATH0356',
        questionText:
            'The solution curve of the differential equation 𝑦(𝑑𝑦/𝑑𝑥) = 𝑥(logₑ 𝑥 - logₑ 𝑦 + 1), 𝑥 > 0, 𝑦 > 0 passing through the point (𝑒, 1) is',
        options: [
          'logₑ(𝑦/𝑒𝑥) = 𝑥',
          'logₑ(𝑦/𝑒𝑥) = 𝑦²',
          'logₑ(𝑥/𝑒𝑦) = 𝑦',
          '2logₑ(𝑥/𝑒𝑦) = 𝑦+1'
        ],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Differential Equations',
        subTopic: 'Differential Equations Solutions',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: [
          'Differential Equations',
          'Solution Curves',
          'Logarithmic Functions'
        ],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'MATH0357',
        questionText:
            'Let 𝑦 = 𝑦(𝑥) be the solution of the differential equation 𝑑𝑦/𝑑𝑥 = (tan𝑥+𝑦)/(sin𝑥(sec𝑥 - sin𝑥tan𝑥)), 𝑥 ∈ (0, π/2) satisfying the condition 𝑦(π/4) = 2. Then, 𝑦(π/3) is',
        options: [
          '√3/2 + logₑ(√3/2)',
          '√3/2 + logₑ(3/2)',
          '√3(1+2logₑ(3))',
          '√3(2+logₑ(3))'
        ],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Differential Equations',
        subTopic: 'First Order Differential Equations',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: [
          'Differential Equations',
          'Initial Value Problems',
          'Trigonometric Functions'
        ],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'MATH0358',
        questionText:
            'Let 𝑎 = 3𝑖 + 𝑗 - 2𝑘, 𝑏 = 4𝑖 + 𝑗 + 7𝑘 and 𝑐 = 𝑖 - 3𝑗 + 4𝑘 be three vectors. If a vector 𝑝 satisfies 𝑝 × 𝑏 = 𝑐 × 𝑏 and 𝑝 ⋅ 𝑎 = 0, then 𝑝 ⋅ (𝑖 - 𝑗 - 𝑘) is equal to',
        options: ['24', '36', '28', '32'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Vector Algebra',
        subTopic: 'Vector Operations',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: [
          'Vector Cross Product',
          'Vector Dot Product',
          'Vector Equations'
        ],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'MATH0359',
        questionText:
            'The distance of the point 𝑄(0, 2, -2) from the line passing through the point 𝑃(5, -4, 3) and perpendicular to the lines 𝑟 = (-3𝑖+2𝑘) + 𝜆(2𝑖+3𝑗+5𝑘), 𝜆 ∈ ℝ and 𝑟 = (𝑖-2𝑗+𝑘) + 𝜇(-𝑖+3𝑗+2𝑘), 𝜇 ∈ ℝ is',
        options: ['√86', '√20', '√54', '√74'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Three Dimensional Geometry',
        subTopic: 'Distance from Line',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['3D Geometry', 'Distance Formula', 'Lines in Space'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'MATH0360',
        questionText:
            'Two marbles are drawn in succession from a box containing 10 red, 30 white, 20 blue and 15 orange marbles, with replacement being made after each drawing. Then the probability, that first drawn marble is red and second drawn marble is white, is',
        options: ['2/25', '4/25', '2/75', '4/75'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Statistics and Probability',
        subTopic: 'Probability',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Probability', 'Independent Events', 'With Replacement'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'MATH0361',
        questionText:
            'Three rotten apples are accidently mixed with fifteen good apples. Assuming the random variable 𝑥 to be the number of rotten apples in a draw of two apples, the variance of 𝑥 is',
        options: ['37/153', '57/153', '47/153', '40/153'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Statistics and Probability',
        subTopic: 'Variance',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Variance', 'Probability Distribution', 'Random Variables'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'MATH0362',
        questionText:
            'If 𝛼 denotes the number of solutions of (1−𝑖)ˣ = 2ˣ and 𝛽 = |𝑧|/arg(𝑧), where 𝑧 = (π(1+𝑖)⁴(1−√π·𝑖) + (√π−𝑖))/(π+𝑖(1+√π·𝑖)), 𝑖 = √−1, then the distance of the point (𝛼, 𝛽) from the line 4𝑥−3𝑦 = 7 is ______',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Complex Numbers and Quadratic Equations',
        subTopic: 'Complex Numbers and Geometry',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: [
          'Complex Numbers',
          'Distance from Line',
          'Complex Equations'
        ],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0363',
        questionText:
            'The total number of words (with or without meaning) that can be formed out of the letters of the word "DISTRIBUTION" taken four at a time, is equal to ______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Permutations and Combinations',
        subTopic: 'Word Formation',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Permutations', 'Combinations', 'Word Problems'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0364',
        questionText:
            'In the expansion of (1+𝑥)(1−𝑥²)(1 + 3/𝑥 + 3/𝑥² + 1/𝑥³), 𝑥 ≠ 0, the sum of the coefficient of 𝑥³ and 𝑥⁻¹³ is equal to ______',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Binomial Theorem and Its Simple Applications',
        subTopic: 'Binomial Expansion',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: [
          'Binomial Expansion',
          'Coefficients',
          'Algebraic Expressions'
        ],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0365',
        questionText:
            'Let the foci and length of the latus rectum of an ellipse 𝑥²/𝑎² + 𝑦²/𝑏² = 1, 𝑎 > 𝑏 be (±5, 0) and √50, respectively. Then, the square of the eccentricity of the hyperbola 𝑥²/𝑏² − 𝑦²/𝑎²𝑏² = 1 equals',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: 'Conic Sections',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Ellipse', 'Hyperbola', 'Eccentricity'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0366',
        questionText:
            'Let 𝐴 = {1, 2, 3, 4} and 𝑅 = {(1, 2), (2, 3), (1, 4)} be a relation on 𝐴. Let 𝑆 be the equivalence relation on 𝐴 such that 𝑅 ⊂ 𝑆 and the number of elements in 𝑆 is 𝑛. Then, the minimum value of 𝑛 is _______',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Sets, Relations and Functions',
        subTopic: 'Equivalence Relations',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Equivalence Relations', 'Set Theory', 'Relations'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0367',
        questionText:
            'Let 𝑓:ℝ → ℝ be a function defined by 𝑓(𝑥) = 4ˣ/(4ˣ+2) and 𝑀 = ∫[𝑓(𝑎) to 𝑓(1−𝑎)] 𝑥sin(4𝑥(1−𝑥)) 𝑑𝑥, 𝑁 = ∫[𝑓(𝑎) to 𝑓(1−𝑎)] sin(4𝑥(1−𝑥)) 𝑑𝑥; 𝑎 ≠ 1/2. If 𝛼𝑀 = 𝛽𝑁, 𝛼, 𝛽 ∈ ℕ, then the least value of 𝛼²+𝛽² is equal to ______',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Integral Calculus',
        subTopic: 'Definite Integrals',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Definite Integrals', 'Integration', 'Natural Numbers'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0368',
        questionText:
            'Let 𝑆 = (−1, ∞) and 𝑓:𝑆 → ℝ be defined as 𝑓(𝑥) = ∫[−1 to 𝑥] 𝑒^(𝑡−1) (2𝑡−1)(5𝑡−2)(7𝑡−3)(122𝑡−1061) 𝑑𝑡. Let 𝑝 = Sum of square of the values of 𝑥, where 𝑓(𝑥) attains local maxima on 𝑆 and 𝑞 = Sum of the values of 𝑥, where 𝑓(𝑥) attains local minima on 𝑆. Then, the value of 𝑝²+2𝑞 is ________',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Differential Equations',
        subTopic: 'Maxima and Minima',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: [
          'Function Composition',
          'Rational Functions',
          'Iterated Functions'
        ],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'MATH0369',
        questionText:
            'If the integral ∫₀^(π/2) sin²𝑥 cos²𝑥 (1+cos²𝑥) 𝑑𝑥 is equal to (𝑛√2)/64, then 𝑛 is equal to ________',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Integral Calculus',
        subTopic: 'Definite Integrals',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: [
          'Definite Integrals',
          'Trigonometric Integrals',
          'Integration'
        ],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0370',
        questionText:
            'Let 𝑎 and 𝑏 be two vectors such that |𝑎| = 1, |𝑏| = 4 and 𝑎⋅𝑏 = 2. If 𝑐 = 2(𝑎×𝑏) - 3𝑏 and the angle between 𝑏 and 𝑐 is 𝛼, then 192sin²𝛼 is equal to _________',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Vector Algebra',
        subTopic: 'Vector Operations',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: [
          'Vector Cross Product',
          'Vector Dot Product',
          'Angle Between Vectors'
        ],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0371',
        questionText:
            'Let 𝑄 and 𝑅 be the feet of perpendiculars from the point 𝑃(𝑎, 𝑎, 𝑎) on the lines 𝑥 = 𝑦, 𝑧 = 1 and 𝑥 = −𝑦, 𝑧 = −1 respectively. If ∠𝑄𝑃𝑅 is a right angle, then 12𝑎² is equal to ________',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Three Dimensional Geometry',
        subTopic: '3D Geometry and Lines',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['3D Geometry', 'Perpendicular Distance', 'Right Angle'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0374',
        questionText:
            'If mass is written as 𝑚 = 𝑘𝑐ᴾ𝐺^(-1/2) ℎ^(1/2), then the value of 𝑃 will be : (Constants have their usual meaning with 𝑘 a dimensionless constant)',
        options: ['1/2', '1/3', '2', '-1/3'],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Units and Measurements',
        subTopic: 'Dimensional Analysis',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: [
          'Dimensional Analysis',
          'Physical Constants',
          'Mass Formula'
        ],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'PHY0375',
        questionText:
            'Projectiles 𝐴 and 𝐵 are thrown at angles of 45° and 60° with vertical respectively from top of a 400 m high tower. If their times of flight are same, the ratio of their speeds of projection 𝑣𝐴:𝑣𝐵 is:',
        options: ['1:√3', '√2:1', '1:2', '1:√2'],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Kinematics',
        subTopic: 'Projectile Motion',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: [
          'Projectile Motion',
          'Time of Flight',
          'Angle of Projection'
        ],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'PHY0376',
        questionText:
            'Three blocks 𝐴, 𝐵 and 𝐶 are pulled on a horizontal smooth surface by a force of 80 N as shown in figure. The tensions 𝑇₁ and 𝑇₂ in the string are respectively:',
        options: ['40N, 64N', '60N, 80N', '88N, 96N', '80N, 100N'],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Laws of Motion',
        subTopic: 'Tension and Forces',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Tension', 'Newton Laws', 'Connected Bodies'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'PHY0377',
        questionText:
            'A block of mass 𝑚 is placed on a surface having vertical cross section given by 𝑦 = 𝑥²/4. If coefficient of friction is 0.5, the maximum height above the ground at which block can be placed without slipping is:',
        options: ['1/4 m', '1/2 m', '1/6 m', '1/3 m'],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Laws of Motion',
        subTopic: 'Friction on Curved Surface',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Friction', 'Curved Surface', 'Maximum Height'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'PHY0378',
        questionText:
            'A block of mass 1 kg is pushed up a surface inclined to horizontal at an angle of 60° by a force of 10 N parallel to the inclined surface as shown in figure. When the block is pushed up by 10 m along inclined surface, the work done against frictional force is : (𝑔 = 10 m s⁻²)',
        options: ['5√3 J', '5 J', '5×10³ J', '10 J'],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Work, Energy and Power',
        subTopic: 'Work Done Against Friction',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Work Done', 'Friction', 'Inclined Plane'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'PHY0379',
        questionText:
            'Escape velocity of a body from earth is 11.2 km s⁻¹. If the radius of a planet be one-third the radius of earth and mass be one-sixth that of earth, the escape velocity from the planet is:',
        options: ['11.2 km s⁻¹', '8.4 km s⁻¹', '4.2 km s⁻¹', '7.9 km s⁻¹'],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Gravitation',
        subTopic: 'Escape Velocity',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: [
          'Escape Velocity',
          'Planetary Parameters',
          'Gravitational Constant'
        ],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'PHY0380',
        questionText:
            'A block of ice at -10 °C is slowly heated and converted to steam at 100 °C. Which of the following curves represent the phenomenon qualitatively:',
        options: [
          'Temperature vs Time',
          'Temperature vs Heat',
          'Heat vs Time',
          'Temperature vs Energy'
        ],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Properties of Solids and Liquids',
        subTopic: 'Phase Transitions',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Phase Transitions', 'Heating Curve', 'Temperature Changes'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'PHY0381',
        questionText:
            'Choose the correct statement for processes 𝐴 & 𝐵 shown in figure.',
        options: [
          '𝑃𝑉^𝛾 = 𝑘 for process 𝐵 and 𝑃𝑉 = 𝑘 for process 𝐴',
          '𝑃𝑉 = 𝑘 for process 𝐵 and 𝐴',
          '𝑃^(𝛾-1) = 𝑘 for process 𝐵 and 𝑇 = 𝑘 for process 𝐴',
          '𝑇^𝛾 = 𝑘 for process 𝐴 and 𝑃𝑉 = 𝑘 for process 𝐵'
        ],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Thermodynamics',
        subTopic: 'Thermodynamic Processes',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: [
          'Thermodynamic Processes',
          'Adiabatic Process',
          'Isothermal Process'
        ],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'PHY0382',
        questionText:
            'If three moles of monoatomic gas (𝛾 = 5/3) is mixed with two moles of a diatomic gas (𝛾 = 7/5), the value of adiabatic exponent 𝛾 for the mixture is:',
        options: ['1.75', '1.40', '1.52', '1.35'],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Kinetic Theory of Gases',
        subTopic: 'Adiabatic Exponent',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: [
          'Adiabatic Exponent',
          'Gas Mixtures',
          'Specific Heat Capacity'
        ],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'PHY0383',
        questionText:
            'A particle of charge -𝑞 and mass 𝑚 moves in a circle of radius 𝑟 around an infinitely long line charge of linear density +𝜆. Then time period will be given as: (Consider 𝑘 as Coulomb constant)',
        options: [
          '𝑇² = (4𝜋²𝑚𝑟³)/(2𝑘𝜆𝑞)',
          '𝑇 = 2𝜋𝑟√(𝑚/(2𝑘𝜆𝑞))',
          '𝑇 = (1/(2𝜋𝑟))√(2𝑘𝜆𝑞/𝑚)',
          '𝑇 = (1/2𝜋)√(2𝑘𝜆𝑞/𝑚)'
        ],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Electrostatics',
        subTopic: 'Charged Particle Motion',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Circular Motion', 'Electrostatic Force', 'Time Period'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'PHY0384',
        questionText:
            'When a potential difference 𝑉 is applied across a wire of resistance 𝑅, it dissipates energy at a rate 𝑊. If the wire is cut into two halves and these halves are connected mutually parallel across the same supply, the energy dissipation rate will become:',
        options: ['1/4 W', '1/2 W', '2 W', '4 W'],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Current Electricity',
        subTopic: 'Power Dissipation',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Power Dissipation', 'Parallel Resistance', 'Wire Cutting'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'PHY0385',
        questionText:
            'An alternating voltage 𝑉(𝑡) = 220sin(100𝜋𝑡) volt is applied to a purely resistive load of 50 𝛺. The time taken for the current to rise from half of the peak value to the peak value is:',
        options: ['5 ms', '3.3 ms', '7.2 ms', '2.2 ms'],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Electromagnetic Induction and Alternating Currents',
        subTopic: 'AC Circuit Analysis',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['AC Circuits', 'Time Calculation', 'Peak Current'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'PHY0386',
        questionText:
            'Match List I with List II: List I (Laws) - List II (Equations) A. Gauss law of magnetostatics, B. Faraday law of electromagnetic induction, C. Ampere law, D. Gauss law of electrostatics',
        options: [
          'A-I, B-III, C-IV, D-II',
          'A-III, B-IV, C-I, D-II',
          'A-IV, B-II, C-III, D-I',
          'A-II, B-III, C-IV, D-I'
        ],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Electromagnetic Induction and Alternating Currents',
        subTopic: 'Maxwell Equations',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Maxwell Equations', 'Electromagnetic Laws', 'Matching'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'PHY0387',
        questionText:
            'A beam of unpolarised light of intensity 𝐼₀ is passed through a polaroid 𝐴 and then through another polaroid 𝐵 which is oriented so that its principal plane makes an angle of 45° relative to that of 𝐴. The intensity of emergent light is :',
        options: ['𝐼₀/4', '𝐼₀', '𝐼₀/2', '𝐼₀/8'],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Optics',
        subTopic: 'Polarization',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Polarization', 'Malus Law', 'Light Intensity'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'PHY0388',
        questionText:
            'If the total energy transferred to a surface in time 𝑡 is 6.48×10⁵ J, then the magnitude of the total momentum delivered to this surface for complete absorption will be :',
        options: [
          '2.46×10⁻³ kg m s⁻¹',
          '2.16×10⁻³ kg m s⁻¹',
          '1.58×10⁻³ kg m s⁻¹',
          '4.32×10⁻³ kg m s⁻¹'
        ],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Dual Nature of Matter and Radiation',
        subTopic: 'Momentum of Radiation',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: [
          'Radiation Pressure',
          'Momentum',
          'Energy-Momentum Relation'
        ],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'PHY0389',
        questionText:
            'For the photoelectric effect, the maximum kinetic energy 𝐸𝑘 of the photoelectrons is plotted against the frequency (𝑣) of the incident photons as shown in figure. The slope of the graph gives',
        options: [
          'Ratio of Planck constant to electric charge',
          'Work function of the metal',
          'Charge of electron',
          'Planck constant'
        ],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Dual Nature of Matter and Radiation',
        subTopic: 'Photoelectric Effect',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Photoelectric Effect', 'Planck Constant', 'Kinetic Energy'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'PHY0390',
        questionText:
            'An electron revolving in 𝑛th Bohr orbit has magnetic moment 𝜇𝑛. If 𝜇𝑛 ∝ 𝑛^𝑥, the value of 𝑥 is:',
        options: ['2', '1', '3', '0'],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Atoms and Nuclei',
        subTopic: 'Bohr Model',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Bohr Model', 'Magnetic Moment', 'Quantum Number'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'PHY0391',
        questionText:
            'In a nuclear fission reaction of an isotope of mass 𝑀, three similar daughter nuclei of same mass are formed. The speed of a daughter nuclei in terms of mass defect 𝛥𝑀 will be :',
        options: [
          '2𝑐√(𝛥𝑀/𝑀)',
          '𝛥𝑀𝑐²/3',
          '𝑐√(2𝛥𝑀/𝑀)',
          '𝑐√(3𝛥𝑀/𝑀)'
        ],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Atoms and Nuclei',
        subTopic: 'Nuclear Fission',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Nuclear Fission', 'Mass Defect', 'Energy Conservation'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'PHY0392',
        questionText:
            'In the given circuit, the voltage across load resistance 𝑅𝐿 is:',
        options: ['8.75 V', '9.00 V', '8.50 V', '14.00 V'],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Electronic Devices',
        subTopic: 'Circuit Analysis',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Circuit Analysis', 'Voltage Division', 'Load Resistance'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'PHY0393',
        questionText:
            'If 50 Vernier divisions are equal to 49 main scale divisions of a travelling microscope and one smallest reading of main scale is 0.5 mm, the Vernier constant of travelling microscope is:',
        options: ['0.1 mm', '0.1 cm', '0.01 cm', '0.01 mm'],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Experimental Skills',
        subTopic: 'Vernier Caliper',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Vernier Constant', 'Least Count', 'Microscope'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'PHY0394',
        questionText:
            'A vector has magnitude same as that of 𝐴 = 3𝑖 + 4𝑗 and is parallel to 𝐵 = 4𝑖 + 3𝑗. The 𝑥 and 𝑦 components of this vector in first quadrant are 𝑥 and 3 respectively where x = ____.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Kinematics',
        subTopic: 'Vector Components',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Vector Components', 'Magnitude', 'Parallel Vectors'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0395',
        questionText:
            'Two discs of moment of inertia 𝐼₁ = 4 kg m² and 𝐼₂ = 2 kg m² about their central axes & normal to their planes, rotating with angular speeds 10 rad s⁻¹ & 4 rad s⁻¹ respectively are brought into contact face to face with their axes of rotation coincident. The loss in kinetic energy of the system in the process is _________J.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Rotational Motion',
        subTopic: 'Conservation of Angular Momentum',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Angular Momentum', 'Kinetic Energy Loss', 'Rotating Discs'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0396',
        questionText:
            'A big drop is formed by coalescing 1000 small identical drops of water. If 𝐸₁ be the total surface energy of 1000 small drops of water and 𝐸₂ be the surface energy of single big drop of water, the 𝐸₁:𝐸₂ is 𝑥:1, where 𝑥 = ________.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Properties of Solids and Liquids',
        subTopic: 'Surface Energy',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Surface Energy', 'Drop Coalescence', 'Surface Area'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0397',
        questionText:
            'A simple pendulum is placed at a place where its distance from the earth surface is equal to the radius of the earth. If the length of the string is 4 m, then the time period of small oscillations will be _________s. [take 𝑔 = 𝜋² m s⁻²]',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Oscillations and Waves',
        subTopic: 'Pendulum Time Period',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Simple Pendulum', 'Time Period', 'Gravitational Variation'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0398',
        questionText:
            'A point source is emitting sound waves of intensity 16×10⁻⁸ W m⁻² at the origin. The difference in intensity (magnitude only) at two points located at distances of 2 m and 4 m from the origin respectively will be ________×10⁻⁸ W m⁻².',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Oscillations and Waves',
        subTopic: 'Sound Intensity',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Sound Intensity', 'Inverse Square Law', 'Point Source'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0399',
        questionText:
            'Two identical charged spheres are suspended by strings of equal lengths. The strings make an angle of 37° with each other. When suspended in a liquid of density 0.7 g cm⁻³, the angle remains same. If density of material of the sphere is 1.4 g cm⁻³, the dielectric constant of the liquid is _____ (tan37° = 3/4)',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Electrostatics',
        subTopic: 'Dielectric Constant',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Dielectric Constant', 'Charged Spheres', 'Buoyancy'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0400',
        questionText:
            'Two resistances of 100𝛺 and 200𝛺 are connected in series with a battery of 4 V and negligible internal resistance. A voltmeter is used to measure voltage across 100𝛺 resistance, which gives reading as 1 V. The resistance of voltmeter must be _______ 𝛺.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Current Electricity',
        subTopic: 'Voltmeter Resistance',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: [
          'Voltmeter Resistance',
          'Circuit Analysis',
          'Voltage Measurement'
        ],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0401',
        questionText:
            'The current of 5 A flows in a square loop of sides 1 m is placed in air. The magnetic field at the centre of the loop is X√2 ×10⁻⁷ T. The value of X is _________.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Magnetic Effects of Current and Magnetism',
        subTopic: 'Magnetic Field of Square Loop',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Magnetic Field', 'Square Loop', 'Biot-Savart Law'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0402',
        questionText:
            'A power transmission line feeds input power at 2.3 kV to a step down transformer with its primary winding having 3000 turns. The output power is delivered at 230 V by the transformer. The current in the primary of the transformer is 5 A and its efficiency is 90%. The output current of transformer is ____A.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Electromagnetic Induction and Alternating Currents',
        subTopic: 'Transformer Calculations',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Transformer', 'Efficiency', 'Current Calculation'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0403',
        questionText:
            'In an experiment to measure the focal length (𝑓) of a convex lens, the magnitude of object distance(𝑥) and the image distance(𝑦) are measured with reference to the focal point of the lens. The 𝑦-𝑥 plot is shown in figure. The focal length of the lens is _____cm.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Optics',
        subTopic: 'Lens Focal Length',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Convex Lens', 'Focal Length', 'Lens Formula'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0374',
        questionText:
            'Given below are two statements: Statement - I: Along the period, the chemical reactivity of the element gradually increases from group 1 to group 18. Statement - II: The nature of oxides formed by group 1 element is basic while that of group 17 elements is acidic. In the light of above statements, choose the most appropriate from the questions given below:',
        options: [
          'Both statement I and Statement II are true',
          'Statement I is true but Statement II is False',
          'Statement I is false but Statement II is true',
          'Both Statement I and Statement II are false'
        ],
        correctAnswerIndex: 2,
        subject: 'Chemistry',
        topic: 'Classification of Elements and Periodicity in Properties',
        subTopic: 'Periodic Trends',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Periodic Trends', 'Chemical Reactivity', 'Oxide Nature'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'CHEM0375',
        questionText:
            'Given below are two statements: Statement-I: Since fluorine is more electronegative than nitrogen, the net dipole moment of NF₃ is greater than NH₃. Statement-II: In NH₃, the orbital dipole due to lone pair and the dipole moment of N-H bonds are in opposite direction, but in NF₃ the orbital dipole due to lone pair and dipole moments of N-F bonds are in same direction. In the light of the above statements. Choose the most appropriate from the options given below.',
        options: [
          'Statement I is true but Statement II is false',
          'Both Statement I and Statement II are false',
          'Both statement I and Statement II are true',
          'Statement I is false but Statement II is true'
        ],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'Chemical Bonding and Molecular Structure',
        subTopic: 'Dipole Moment',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Dipole Moment', 'Electronegativity', 'Molecular Geometry'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'CHEM0376',
        questionText:
            'Given below are two statements: One is labelled as Assertion A and the other is labelled as Reason R. Assertion A: H₂Te is more acidic than H₂S. Reason R: Bond dissociation enthalpy of H₂Te is lower than H₂S. In the light of the above statements. Choose the most appropriate from the options given below.',
        options: [
          'Both A and R are true but R is NOT the correct explanation of A',
          'Both A and R are true and R is the correct explanation of A',
          'A is false but R is true',
          'A is true but R is false'
        ],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'Classification of Elements and Periodicity in Properties',
        subTopic: 'Acidity Trends',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: [
          'Acidity',
          'Bond Dissociation Enthalpy',
          'Hydride Properties'
        ],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'CHEM0377',
        questionText: 'IUPAC name of following compound is',
        options: [
          '2-Aminopentanenitrile',
          '2-Aminobutanenitrile',
          '3-Aminobutanenitrile',
          '3-Aminopropanenitrile'
        ],
        correctAnswerIndex: 2,
        subject: 'Chemistry',
        topic: 'Some Basic Principles of Organic Chemistry',
        subTopic: 'IUPAC Nomenclature',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: [
          'IUPAC Nomenclature',
          'Organic Compounds',
          'Functional Groups'
        ],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'CHEM0378',
        questionText:
            'Which among the following purification methods is based on the principle of "Solubility" in two different solvents?',
        options: [
          'Column Chromatography',
          'Sublimation',
          'Distillation',
          'Differential Extraction'
        ],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Purification and Characterisation of Organic Compounds',
        subTopic: 'Purification Methods',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Purification Methods', 'Solubility', 'Extraction'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'CHEM0379',
        questionText: 'The correct stability order of carbocations is',
        options: [
          '(CH₃)₃C⁺ > CH₃-CH₂⁺ > CH₃CH₂⁺ > CH₃⁺',
          'CH₃⁺ > CH₃CH₂⁺ > CH₃-CH₂⁺ > (CH₃)₃C⁺',
          '(CH₃)₃C⁺ > CH₃CH₂⁺ > CH₃-CH₂⁺ > CH₃⁺',
          'CH₃⁺ > CH₃-CH₂⁺ > CH₃CH₂⁺ > (CH₃)₃C⁺'
        ],
        correctAnswerIndex: 2,
        subject: 'Chemistry',
        topic: 'Some Basic Principles of Organic Chemistry',
        subTopic: 'Carbocation Stability',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: [
          'Carbocation Stability',
          'Hyperconjugation',
          'Inductive Effect'
        ],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'CHEM0380',
        questionText:
            'Product A and B formed in the following set of reactions are:',
        options: ['Option 1', 'Option 2', 'Option 3', 'Option 4'],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'Organic Compounds Containing Oxygen',
        subTopic: 'Organic Reactions',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: [
          'Organic Reactions',
          'Product Formation',
          'Reaction Mechanism'
        ],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'CHEM0381',
        questionText:
            'If a substance A dissolves in solution of a mixture of B and C with their respective number of moles as 𝑛𝐴, 𝑛𝐵 and 𝑛𝐶, mole fraction of C in the solution is:',
        options: [
          '𝑛𝐶/(𝑛𝐴×𝑛𝐵×𝑛𝐶)',
          '𝑛𝐶/(𝑛𝐴+𝑛𝐵+𝑛𝐶)',
          '𝑛𝐶/(𝑛𝐴-𝑛𝐵-𝑛𝐶)',
          '𝑛𝐵/(𝑛𝐴+𝑛𝐵)'
        ],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'Solutions',
        subTopic: 'Mole Fraction',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: [
          'Mole Fraction',
          'Solution Composition',
          'Concentration Terms'
        ],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'CHEM0382',
        questionText:
            'The solution from the following with highest depression in freezing point/lowest freezing point is',
        options: [
          '180 g of acetic acid dissolved in 1 L of aqueous solution',
          '180 g of acetic acid dissolved in benzene',
          '180 g of benzoic acid dissolved in benzene',
          '180 g of glucose dissolved in water'
        ],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Solutions',
        subTopic: 'Freezing Point Depression',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: [
          'Freezing Point Depression',
          'Colligative Properties',
          'Solution Concentration'
        ],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'CHEM0383',
        questionText:
            'Reduction potential of ions are given below: ClO₄⁻ E° = 1.19 V; IO₄⁻ E° = 1.65 V; BrO₄⁻ E° = 1.74 V The correct order of their oxidizing power is:',
        options: [
          'ClO₄⁻ > IO₄⁻ > BrO₄⁻',
          'BrO₄⁻ > IO₄⁻ > ClO₄⁻',
          'BrO₄⁻ > ClO₄⁻ > IO₄⁻',
          'IO₄⁻ > BrO₄⁻ > ClO₄⁻'
        ],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'Redox Reactions and Electrochemistry',
        subTopic: 'Oxidizing Power',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Oxidizing Power', 'Reduction Potential', 'Periodate Ions'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'CHEM0384',
        questionText:
            'Choose the correct statements about the hydrides of group 15 elements. A. The stability of the hydrides decreases in the order NH₃ > PH₃ > AsH₃ > SbH₃ > BiH₃ B. The reducing ability of the hydrides increases in the order NH₃ < PH₃ < AsH₃ < SbH₃ < BiH₃ C. Among the hydrides, NH₃ is strong reducing agent while BiH₃ is mild reducing agent. D. The basicity of the hydrides increases in the order NH₃ < PH₃ < AsH₃ < SbH₃ < BiH₃',
        options: [
          'B and C only',
          'C and D only',
          'A and B only',
          'A and D only'
        ],
        correctAnswerIndex: 2,
        subject: 'Chemistry',
        topic: 'p-Block Elements',
        subTopic: 'Group 15 Hydrides',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Group 15 Hydrides', 'Stability Trends', 'Reducing Ability'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'CHEM0385',
        questionText:
            'The orange colour of K₂Cr₂O₇ and purple colour of KMnO₄ is due to',
        options: [
          'Charge transfer transition in both.',
          'd → d transition in KMnO₄ and charge transfer transitions in K₂Cr₂O₇.',
          'd → d transition in K₂Cr₂O₇ and charge transfer transitions in KMnO₄.',
          'd → d transition in both.'
        ],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'd- and f-Block Elements',
        subTopic: 'Colour of Compounds',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Charge Transfer', 'd-d Transition'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0386',
        questionText:
            'A and B formed in the following reactions are: CrO₂Cl₂ + 4NaOH → A + 2NaCl + 2H₂O; A + 2HCl + 2H₂O → B + 3H₂O',
        options: [
          'A = Na₂CrO₄, B = CrO₅',
          'A = Na₂Cr₂O₄, B = CrO₄',
          'A = Na₂Cr₂O₇, B = CrO₃',
          'A = Na₂Cr₂O₇, B = CrO₅'
        ],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'd- and f-Block Elements',
        subTopic: 'Chromium Compounds',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Chromyl Chloride', 'Chemical Reactions'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0387',
        questionText:
            'Alkaline oxidative fusion of MnO₂ gives "A" which on electrolytic oxidation in alkaline solution produces B. A and B respectively are:',
        options: [
          'Mn₂O₇ and MnO₄⁻',
          'MnO₄²⁻ and MnO₄⁻',
          'Mn₂O₃ and MnO₄²⁻',
          'MnO₄²⁻ and Mn₂O₇'
        ],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'd- and f-Block Elements',
        subTopic: 'Manganese Compounds',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Oxidative Fusion', 'Electrolytic Oxidation'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0388',
        questionText: 'The molecule/ion with square pyramidal shape is:',
        options: ['Ni(CN)₄²⁻', 'PCl₄', 'BrF₅', 'PF₅'],
        correctAnswerIndex: 2,
        subject: 'Chemistry',
        topic: 'Chemical Bonding and Molecular Structure',
        subTopic: 'Molecular Shapes',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['VSEPR Theory', 'Square Pyramidal'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0389',
        questionText:
            'The coordination geometry around the manganese in decacarbonyldimanganese(0) is:',
        options: [
          'Octahedral',
          'Trigonal bipyramidal',
          'Square pyramidal',
          'Square planar'
        ],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Coordination Compounds',
        subTopic: 'Coordination Geometry',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Metal Carbonyls', 'Coordination Number'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0390',
        questionText:
            'Given below are two statements: Statement I: High concentration of strong nucleophilic reagent with secondary alkyl halides which do not have bulky substituents will follow SN2 mechanism. Statement II: A secondary alkyl halide when treated with a large excess of ethanol follows SN1 mechanism. In the light of the above statements, choose the most appropriate from the questions given below:',
        options: [
          'Statement I is true but Statement II is false.',
          'Statement I is false but Statement II is true.',
          'Both statement I and Statement II are false.',
          'Both statement I and Statement II are true.'
        ],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Organic Compounds Containing Halogens',
        subTopic: 'Reaction Mechanisms',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['SN1 Mechanism', 'SN2 Mechanism'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0391',
        questionText:
            'Salicylaldehyde is synthesized from phenol, when reacted with',
        options: ['CHCl₃', 'CO₂, NaOH', 'CCl₄, NaOH', 'HCCl₃, NaOH'],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Organic Compounds Containing Oxygen',
        subTopic: 'Phenol Reactions',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Reimer-Tiemann Reaction', 'Salicylaldehyde Synthesis'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0392',
        questionText:
            'm-chlorobenzaldehyde on treatment with 50% KOH solution yields',
        options: [
          'm-chlorobenzyl alcohol',
          'm-chlorobenzoic acid',
          'm-hydroxybenzaldehyde',
          'm-chlorobenzyl alcohol and m-chlorobenzoic acid'
        ],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Organic Compounds Containing Oxygen',
        subTopic: 'Cannizzaro Reaction',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Cannizzaro Reaction', 'Aldehyde Reactions'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0393',
        questionText:
            'The products A and B formed in the following reaction scheme are respectively',
        options: [
          'Nitrobenzene and Aniline',
          'Nitrobenzene and Azoxybenzene',
          'Nitrosobenzene and Azoxybenzene',
          'Nitrosobenzene and Hydrazobenzene'
        ],
        correctAnswerIndex: 2,
        subject: 'Chemistry',
        topic: 'Organic Compounds Containing Nitrogen',
        subTopic: 'Nitro Compounds',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Reduction Reactions', 'Nitro Compounds'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0394',
        questionText:
            'Number of spectral lines obtained in He⁺ spectra, when an electron makes transition from fifth excited state to first excited state will be',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Atomic Structure',
        subTopic: 'Spectral Lines',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Hydrogen-like Atoms', 'Spectral Transitions'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0395',
        questionText:
            'Two reactions are given below: 2Fe(s) + 3/2 O₂(g) → Fe₂O₃(s), ΔH° = -822 kJ/mol; C(s) + 1/2 O₂(g) → CO(g), ΔH° = -110 kJ/mol. Then enthalpy change for following reaction: 3C(s) + Fe₂O₃(s) → 2Fe(s) + 3CO(g)',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Chemical Thermodynamics',
        subTopic: 'Enthalpy Change',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Hess Law', 'Enthalpy Calculation'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0396',
        questionText:
            'The pH of an aqueous solution containing 1M benzoic acid (pKa = 4.20) and 1M sodium benzoate is 4.5. The volume of benzoic acid solution in 300 mL of this buffer solution is __________ mL.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Equilibrium',
        subTopic: 'Buffer Solutions',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Henderson-Hasselbalch Equation', 'Buffer Capacity'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0397',
        questionText:
            'Total number of species from the following which can undergo disproportionation reaction ___________. H₂O₂, ClO⁻, P₄, Cl₂, Ag, Cu⁺, F₂, NO₂, K⁺',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Redox Reactions and Electrochemistry',
        subTopic: 'Disproportionation',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Disproportionation', 'Redox Reactions'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0398',
        questionText:
            'Number of geometrical isomers possible for the given structure is/are _________.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Hydrocarbons',
        subTopic: 'Geometrical Isomerism',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Geometrical Isomerism', 'Coordination Compounds'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0399',
        questionText:
            'NO₂ required for a reaction is produced by decomposition of N₂O₅ in CCl₄ as by equation: 2N₂O₅(g) → 4NO₂(g) + O₂(g). The initial concentration of N₂O₅ is 3 mol L⁻¹ and it is 2.75 mol L⁻¹ after 30 minutes. The rate of formation of NO₂ is x × 10⁻³ mol L⁻¹ min⁻¹, value of x is ________.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Chemical Kinetics',
        subTopic: 'Rate of Reaction',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Rate Calculation', 'Decomposition Kinetics'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0400',
        questionText:
            'Number of complexes which show optical isomerism among the following is _________. [cis-Cr(ox)₂Cl₂]³⁻, [Co(en)₃]³⁺, [cis-Pt(en)₂Cl₂]²⁺, [cis-Co(en)₂Cl₂]⁺, [trans-Pt(en)₂Cl₂]²⁺, [trans-Cr(ox)₂Cl₂]³⁻',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Coordination Compounds',
        subTopic: 'Optical Isomerism',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Optical Isomerism', 'Coordination Complexes'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0401',
        questionText:
            '2-chlorobutane + Cl₂ → C₄H₈Cl₂ (isomers). Total number of optically active isomers shown by C₄H₈Cl₂, obtained in the above reaction is ________.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Organic Compounds Containing Halogens',
        subTopic: 'Optical Isomerism',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Optical Activity', 'Chiral Centers'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0402',
        questionText:
            'Number of metal ions characterized by flame test among the following is _________. Sr²⁺, Ba²⁺, Ca²⁺, Cu²⁺, Zn²⁺, Co²⁺, Fe²⁺',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Principles Related to Practical Chemistry',
        subTopic: 'Flame Test',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Flame Test', 'Metal Ion Identification'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0403',
        questionText:
            'The total number of correct statements, regarding the nucleic acids is _________. A. RNA is regarded as the reserve of genetic information. B. DNA molecule self-duplicates during cell division C. DNA synthesizes proteins in the cell. D. The message for the synthesis of particular proteins is present in DNA E. Identical DNA strands are transferred to daughter cells.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Biomolecules',
        subTopic: 'Nucleic Acids',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['DNA', 'RNA', 'Genetic Information'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0372',
        questionText:
            'If z is a complex number, then the number of common roots of the equation z¹⁹⁸⁵ + z¹⁰⁰ + 1 = 0 and z³ + 2z² + 2z + 1 = 0, is equal to :',
        options: ['1', '2', '0', '3'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Complex Numbers and Quadratic Equations',
        subTopic: 'Complex Roots',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Complex Roots', 'Polynomial Equations'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0373',
        questionText:
            'Let a and b be two distinct positive real numbers. Let 11th term of a GP, whose first term is a and third term is b, is equal to pth term of another GP, whose first term is a and fifth term is b. Then p is equal to',
        options: ['20', '25', '21', '24'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Sequence and Series',
        subTopic: 'Geometric Progression',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Geometric Progression', 'Term Calculation'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0374',
        questionText:
            'Suppose 28 - p, p, 70 - α, α are the coefficient of four consecutive terms in the expansion of (1 + x)ⁿ. Then the value of 2α - 3p equals',
        options: ['7', '10', '4', '6'],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Binomial Theorem and Its Simple Applications',
        subTopic: 'Binomial Coefficients',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Binomial Coefficients', 'Consecutive Terms'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0375',
        questionText:
            'For α, β ∈ (0, π/2), let 3sin(α + β) = 2sin(α - β) and a real number k be such that tanα = k tanβ. Then the value of k is equal to',
        options: ['-5', '5/2', '2/3', '-3/2'],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Trigonometry',
        subTopic: 'Trigonometric Equations',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Trigonometric Identities', 'Tangent Ratio'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0376',
        questionText:
            'If x² - y² + 2hxy + 2gx + 2fy + c = 0 is the locus of a point, which moves such that it is always equidistant from the lines x + 2y + 7 = 0 and 2x - y + 8 = 0, then the value of g + c + h - f equals',
        options: ['14', '6', '8', '29'],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: 'Locus',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Distance from Lines', 'Locus'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0377',
        questionText:
            'Let A(α, 0) and B(0, β) be the points on the line 5x + 7y = 50. Let the point P divide the line segment AB internally in the ratio 7:3. Let 3x - 25 = 0 be a directrix of the ellipse E: x²/a² + y²/b² = 1 and the corresponding focus be S. If from S, the perpendicular on the x-axis passes through P, then the length of the latus rectum of E is equal to',
        options: ['25/3', '32/9', '25/9', '32/5'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: 'Ellipse',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Ellipse Properties', 'Directrix', 'Focus'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0378',
        questionText:
            'Let P be a point on the hyperbola H: x²/9 - y²/4 = 1, in the first quadrant such that the area of triangle formed by P and the two foci of H is 2√13. Then, the square of the distance of P from the origin is',
        options: ['18', '26', '22', '20'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: 'Hyperbola',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Hyperbola', 'Foci', 'Area of Triangle'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0379',
        questionText:
            'Let R = [[x, 0, 0], [0, y, 0], [0, 0, z]] be a non-zero 3×3 matrix, where x sinθ = y sin(θ + 2π/3) = z sin(θ + 4π/3) ≠ 0, θ ∈ (0, 2π). For a square matrix M, let Trace M denote the sum of all the diagonal entries of M. Then, among the statements: I. Trace(R) = 0 (II) If Trace(adj(adj R)) = 0, then R has exactly one non-zero entry.',
        options: [
          'Both (I) and (II) are true',
          'Only (II) is true',
          'Neither (I) nor (II) is true',
          'Only (I) is true'
        ],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Matrices and Determinants',
        subTopic: 'Matrix Properties',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Trace', 'Adjoint', 'Matrix Properties'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0380',
        questionText:
            'Consider the system of linear equations x + y + z = 5, x + 2y + λ²z = 9 and x + 3y + λz = μ, where λ, μ ∈ R. Then, which of the following statement is NOT correct?',
        options: [
          'System has infinite number of solution if λ = 1',
          'System is inconsistent if λ = 1 and μ ≠ 13',
          'System has unique solution if λ ≠ 1 and μ ≠ 13',
          'System is consistent if λ ≠ 1 and μ = 13'
        ],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Matrices and Determinants',
        subTopic: 'System of Equations',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Linear Systems', 'Consistency', 'Unique Solution'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0381',
        questionText:
            'If the domain of the function f(x) = logₑ(4x² + x - 3) + cos⁻¹(2x - 1)/(x + 2) is (α, β), then the value of 5β - 4α is equal to',
        options: ['10', '12', '11', '9'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Sets, Relations and Functions',
        subTopic: 'Domain of Function',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Domain', 'Logarithmic Function', 'Inverse Trigonometric'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0382',
        questionText:
            'Let f: R → R be a function defined f(x) = x and g(x) = f(f(f(f(x)))) then 18∫₀¹ x²g(x)/(1 + x⁴) dx',
        options: ['33', '36', '42', '39'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Integral Calculus',
        subTopic: 'Definite Integration',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Function Composition', 'Definite Integral'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0383',
        questionText:
            'Let a and b be real constants such that the function f defined by f(x) = {x² + 3x + a, x ≤ 1; bx + 2, x > 1} be differentiable on R. Then, the value of ∫₋₂² f(x) dx equals',
        options: ['15/6', '19/6', '21/6', '17/6'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Limit, Continuity and Differentiability',
        subTopic: 'Differentiability',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Differentiability', 'Piecewise Function', 'Integration'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0384',
        questionText:
            'Let f: R - {0} → R be a function satisfying f(x/y) = f(x)/f(y) for all x, y, f(y) ≠ 0. If f′(1) = 2024, then',
        options: [
          'xf′(x) - 2024f(x) = 0',
          'xf′(x) + 2024f(x) = 0',
          'xf′(x) + f(x) = 2024',
          'xf′(x) - 2023f(x) = 0'
        ],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Differential Equations',
        subTopic: 'Functional Equations',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Functional Equation', 'Differentiation'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0385',
        questionText:
            'Let f(x) = (x + 3)²(x - 2)³, x ∈ [-4, 4]. If M and m are the maximum and minimum values of f, respectively in [-4, 4], then the value of M - m is :',
        options: ['600', '392', '608', '108'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Limit, Continuity and Differentiability',
        subTopic: 'Maxima Minima',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Maxima Minima', 'Polynomial Function'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0386',
        questionText:
            'Let y = f(x) be a thrice differentiable function in (-5, 5). Let the tangents to the curve y = f(x) at (1, f(1)) and (3, f(3)) make angles π/6 and π/4, respectively with positive x-axis. If 27∫₁³ (f′(t))² + f″(t) dt = α + β√3 where α, β are integers, then the value of α + β equals',
        options: ['-14', '26', '-16', '36'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Integral Calculus',
        subTopic: 'Definite Integration',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Tangent Slope', 'Definite Integral'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0387',
        questionText:
            'Let f: R → R be defined f(x) = ae²ˣ + beˣ + cx. If f(0) = -1, f′(logₑ2) = 21 and ∫₀^{logₑ4} (f(x) - cx) dx = 39/2, then the value of |a + b + c| equals:',
        options: ['16', '10', '12', '8'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Integral Calculus',
        subTopic: 'Definite Integration',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Exponential Function', 'Integration', 'Differentiation'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0388',
        questionText:
            'Let a = i + αj + βk, α, β ∈ R. Let a vector b be such that the angle between a and b is π/4 and |b| = 6. If a · b = 3√2, then the value of (α² + β²)|a × b|² is equal to',
        options: ['90', '75', '95', '85'],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Vector Algebra',
        subTopic: 'Vector Operations',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Dot Product', 'Cross Product', 'Vector Magnitude'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0389',
        questionText:
            'Let a and b be two vectors such that |b| = 1 and |b × a| = 2. Then |b × (a - b)|² is equal to',
        options: ['3', '5', '1', '4'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Vector Algebra',
        subTopic: 'Vector Operations',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Cross Product', 'Vector Magnitude'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0390',
        questionText:
            'Let L₁: r = (i - j + 2k) + λ(i - j + 2k), λ ∈ R, L₂: r = (j - k) + μ(3i + j + pk), μ ∈ R and L₃: r = δ(li + mj + nk), δ ∈ R be three lines such that L₁ is perpendicular to L₂ and L₃ is perpendicular to both L₁ and L₂. Then the point which lies on L₃ is',
        options: ['(-1, 7, 4)', '(-1, -7, 4)', '(1, 7, -4)', '(1, -7, 4)'],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Three Dimensional Geometry',
        subTopic: 'Lines in Space',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Line Equations', 'Perpendicular Lines'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0391',
        questionText:
            'Bag A contains 3 white, 7 red balls and bag B contains 3 white, 2 red balls. One bag is selected at random and a ball is drawn from it. The probability of drawing the ball from the bag A, if the ball drawn in white, is :',
        options: ['1/4', '1/9', '1/3', '3/10'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Statistics and Probability',
        subTopic: 'Conditional Probability',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Conditional Probability', 'Bayes Theorem'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0392',
        questionText:
            'The number of real solutions of the equation x(x² + 3|x| + 5|x - 1| + 6|x - 2|) = 0 is ______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Complex Numbers and Quadratic Equations',
        subTopic: 'Absolute Value Equations',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Absolute Value', 'Real Solutions'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0393',
        questionText:
            'In an examination of mathematics paper, there are 20 questions of equal marks and the question paper is divided into three sections: A, B and C. A student is required to attempt total 15 questions taking at least 4 questions from each section. If section A has 8 questions, section B has 6 questions and section C has 6 questions, then the total number of ways a student can select 15 questions is _________.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Permutations and Combinations',
        subTopic: 'Combinations',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Combinations', 'Selection with Restrictions'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0394',
        questionText:
            'Let Sₙ be the sum to n-terms of an arithmetic progression 3, 7, 11, …, if 40 < 6/(n(n+1)) ∑ₖ₌₁ⁿ Sₖ < 42, then n equals ____________.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Sequence and Series',
        subTopic: 'Arithmetic Progression',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Arithmetic Progression', 'Sum of Series'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0395',
        questionText:
            'Let α = ∑ₖ₌₀ⁿ ⁿCₖ/(k+1)² and β = ∑ₖ₌₀ⁿ⁻¹ ⁿCₖ ⁿCₖ₊₁/(k+2). If 5α = 6β, then n equals',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Binomial Theorem and Its Simple Applications',
        subTopic: 'Binomial Coefficients',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Binomial Coefficients', 'Summation'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0396',
        questionText:
            'Consider two circles C₁: x² + y² = 25 and C₂: (x - α)² + y² = 16, where α ∈ (5, 9). Let the angle between the two radii (one to each circle) drawn from one of the intersection points of C₁ and C₂ be sin⁻¹(√63/8). If the length of common chord of C₁ and C₂ is β, then the value of (αβ)² equals _________.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: 'Circles',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Circle Geometry', 'Common Chord'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0397',
        questionText:
            'If the variance σ² of the given data is k then the value of k is ______ {where [.] denotes the greatest integer function}',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Statistics and Probability',
        subTopic: 'Variance',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Variance', 'Statistical Measures'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0398',
        questionText:
            'The number of symmetric relations defined on the set {1, 2, 3, 4} which are not reflexive is _______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Sets, Relations and Functions',
        subTopic: 'Relations',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Symmetric Relations', 'Reflexive Relations'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0399',
        questionText:
            'The area of the region enclosed by the parabola (y - 2)² = (x - 1), the line x - 2y + 4 = 0 and the positive coordinate axes is __________.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Integral Calculus',
        subTopic: 'Area Calculation',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Area Integration', 'Parabola', 'Line'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0400',
        questionText:
            'Let Y = Y(X) be a curve lying in the first quadrant such that the area enclosed by the line Y - y = Y′(x)(X - x) and the co-ordinate axes, where (x, y) is any point on the curve, is always -y²/Y′(x) + 1, Y′(x) ≠ 0. If Y(1) = 1, then 12Y(1/2) equals ________.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Differential Equations',
        subTopic: 'Area Calculation',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Area Integration', 'Parabola', 'Line'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0401',
        questionText:
            'Let a line passing through the point (-1, 2, 3) intersect the lines L₁: (x-1)/3 = (y-2)/2 = (z-3)/-2 at M(α, β, γ) and L₂: (x+2)/-3 = (y-2)/-2 = (z-1)/4 at N(a, b, c). Then the value of (α + β + γ)²/(a + b + c)² equals ________________.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Three Dimensional Geometry',
        subTopic: 'Lines in Space',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Line Intersection', 'Coordinates'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0404',
        questionText:
            'Match List-I with List-II. List-I: A. Coefficient of viscosity, B. Surface Tension, C. Angular momentum, D. Rotational kinetic energy. List-II: I. [ML²T⁻²], II. [ML²T⁻¹], III. [ML⁻¹T⁻¹], IV. [ML⁰T⁻²]',
        options: [
          'A-II, B-I, C-IV, D-III',
          'A-I, B-II, C-III, D-IV',
          'A-III, B-IV, C-II, D-I',
          'A-IV, B-III, C-II, D-I'
        ],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Units and Measurements',
        subTopic: 'Dimensional Analysis',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Dimensional Formula', 'Physical Quantities'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0405',
        questionText:
            'A particle of mass m projected with a velocity u making an angle of 30° with the horizontal. The magnitude of angular momentum of the projectile about the point of projection when the particle is at its maximum height h is:',
        options: ['√3 mu³/16g', '√3 mu²/2g', 'mu³/√2g', 'zero'],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Kinematics',
        subTopic: 'Projectile Motion',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Angular Momentum', 'Projectile Motion'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0406',
        questionText:
            'All surfaces shown in figure are assumed to be frictionless and the pulleys and the string are light. The acceleration of the block of mass 2 kg is:',
        options: ['g', 'g/3', 'g/2', 'g/4'],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Laws of Motion',
        subTopic: 'Pulley Systems',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Newton Laws', 'Pulley Mechanics'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0407',
        questionText:
            'A particle is placed at the point A of a frictionless track ABC as shown in figure. It is gently pushed towards right. The speed of the particle when it reaches the point B is: (Take g = 10 m s⁻²)',
        options: ['20 m s⁻¹', '√10 m s⁻¹', '2√10 m s⁻¹', '10 m s⁻¹'],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Work, Energy and Power',
        subTopic: 'Conservation of Energy',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Energy Conservation', 'Potential to Kinetic Energy'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0408',
        questionText:
            'A spherical body of mass 100 g is dropped from a height of 10 m from the ground. After hitting the ground, the body rebounds to a height of 5 m. The impulse of force imparted by the ground to the body is given by: (given g = 9.8 m s⁻²)',
        options: [
          '4.32 kg m s⁻¹',
          '43.2 kg m s⁻¹',
          '23.9 kg m s⁻¹',
          '2.39 kg m s⁻¹'
        ],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Laws of Motion',
        subTopic: 'Impulse',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Impulse', 'Collision'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0409',
        questionText:
            'The gravitational potential at a point above the surface of earth is −5.12×10⁷ J kg⁻¹ and the acceleration due to gravity at that point is 6.4 m s⁻². Assume that the mean radius of earth to be 6400 km. The height of this point above the earth surface is:',
        options: ['1600 km', '540 km', '1200 km', '1000 km'],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Gravitation',
        subTopic: 'Gravitational Potential',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Gravitational Potential', 'Acceleration due to Gravity'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0410',
        questionText:
            'Young modulus of material of a wire of length L and cross-sectional area A is Y. If the length of the wire is doubled and cross-sectional area is halved then Young modulus will be:',
        options: ['Y', '4Y', 'Y/4', '2Y'],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Properties of Solids and Liquids',
        subTopic: 'Elasticity',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Young Modulus', 'Material Property'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0411',
        questionText:
            'At which temperature the r.m.s. velocity of a hydrogen molecule equal to that of an oxygen molecule at 47°C?',
        options: ['80 K', '−73 K', '4 K', '20 K'],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Kinetic Theory of Gases',
        subTopic: 'RMS Velocity',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['RMS Velocity', 'Kinetic Theory'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0412',
        questionText:
            'Two thermodynamical process are shown in the figure. The molar heat capacity for process A and B are C_A and C_B. The molar heat capacity at constant pressure and constant volume are represented by C_P and C_V, respectively. Choose the correct statement.',
        options: [
          'C_P > C_B > C_V',
          'C_A = 0 and C_B = ∞',
          'C_P > C_V > C_A = C_B',
          'C_A > C_P > C_V'
        ],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Thermodynamics',
        subTopic: 'Heat Capacity',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Molar Heat Capacity', 'Thermodynamic Processes'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0413',
        questionText:
            'The electrostatic potential due to an electric dipole at a distance r varies as:',
        options: ['r', '1/r²', '1/r³', '1/r'],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Electrostatics',
        subTopic: 'Electric Dipole',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Electric Dipole', 'Potential Variation'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0414',
        questionText:
            'A potential divider circuit is shown in figure. The output voltage V₀ is',
        options: ['4 V', '2 mV', '0.5 V', '12 mV'],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Current Electricity',
        subTopic: 'Potential Divider',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Potential Divider', 'Voltage Division'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0415',
        questionText:
            'An electric toaster has resistance of 60 Ω at room temperature (27°C). The toaster is connected to a 220 V supply. If the current flowing through it reaches 2.75 A, the temperature attained by toaster is around: (if α = 2×10⁻⁴ °C⁻¹)',
        options: ['694°C', '1235°C', '1694°C', '1667°C'],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Current Electricity',
        subTopic: 'Temperature Dependence of Resistance',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Resistance Temperature Dependence', 'Ohms Law'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0416',
        questionText:
            'Two insulated circular loop A and B radius a carrying a current of I in the anti clockwise direction as shown in figure. The magnitude of the magnetic induction at the centre will be:',
        options: ['√2μ₀I/a', 'μ₀I/2a', 'μ₀I/√2a', '2μ₀I/a'],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Magnetic Effects of Current and Magnetism',
        subTopic: 'Magnetic Field due to Circular Loop',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Magnetic Field', 'Circular Loop'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0417',
        questionText:
            'A series LR circuit connected with an ac source E = (25 sin1000t) V has a power factor of 1/√2. If the source of emf is changed to E = (20 sin2000t) V, the new power factor of the circuit will be:',
        options: ['1/√2', '1/√3', '1/√5', '1/√7'],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Electromagnetic Induction and Alternating Currents',
        subTopic: 'Power Factor',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['LR Circuit', 'Power Factor'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0418',
        questionText:
            'Primary coil of a transformer is connected to 220 V AC. Primary and secondary turns of the transforms are 100 and 10 respectively. Secondary coil of transformer is connected to two series resistances as shown in figure. The output voltage (V₀) is:',
        options: ['7 V', '15 V', '44 V', '22 V'],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Electromagnetic Induction and Alternating Currents',
        subTopic: 'Transformer',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Transformer', 'Voltage Division'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0419',
        questionText:
            'The electric field of an electromagnetic wave in free space is represented as E = E₀ cos(ωt - kz)î. The corresponding magnetic induction vector will be:',
        options: [
          'B = (E₀/C) cos(ωt - kz) ĵ',
          'B = (E₀/C) cos(ωt - kz) ĵ',
          'B = (E₀/C) cos(ωt + kz) ĵ',
          'B = (E₀/C) cos(ωt + kz) ĵ'
        ],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Electromagnetic Waves',
        subTopic: 'Wave Propagation',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Electromagnetic Waves', 'Wave Equations'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0420',
        questionText:
            'The diffraction pattern of a light of wavelength 400 nm diffracting from a slit of width 0.2 mm is focused on the focal plane of a convex lens of focal length 100 cm. The width of the 1st secondary maxima will be:',
        options: ['2 mm', '2 cm', '0.02 mm', '0.2 mm'],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Optics',
        subTopic: 'Diffraction',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Single Slit Diffraction', 'Secondary Maxima'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0421',
        questionText:
            'The work function of a substance is 3.0 eV. The longest wavelength of light that can cause the emission of photoelectrons from this substance is approximately:',
        options: ['215 nm', '414 nm', '400 nm', '200 nm'],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Dual Nature of Matter and Radiation',
        subTopic: 'Photoelectric Effect',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Work Function', 'Threshold Wavelength'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0422',
        questionText:
            'The ratio of the magnitude of the kinetic energy to the potential energy of an electron in the 5th excited state of a hydrogen atom is:',
        options: ['4', '1/4', '1', '1/2'],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Atoms and Nuclei',
        subTopic: 'Hydrogen Atom',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Hydrogen Atom', 'Energy Levels'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0423',
        questionText:
            'A Zener diode of breakdown voltage 10 V is used as a voltage regulator as shown in the figure. The current through the Zener diode is',
        options: ['50 mA', '0', '30 mA', '20 mA'],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Electronic Devices',
        subTopic: 'Zener Diode',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Zener Diode', 'Voltage Regulation'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0424',
        questionText:
            'The displacement and the increase in the velocity of a moving particle in the time interval of t to (t+1) s are 125 m and 50 m s⁻¹, respectively. The distance travelled by the particle in (t+2)th s is ___________ m.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Kinematics',
        subTopic: 'Distance and Displacement',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Uniform Acceleration', 'Distance Calculation'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0425',
        questionText:
            'Consider a disc of mass 5 kg, radius 2 m, rotating with angular velocity of 10 rad s⁻¹ about an axis perpendicular to the plane of rotation. An identical disc is kept gently over the rotating disc along the same axis. The energy dissipated so that both the discs continue to rotate together without slipping is _________ J.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Rotational Motion',
        subTopic: 'Conservation of Angular Momentum',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Angular Momentum Conservation', 'Energy Dissipation'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0426',
        questionText:
            'Each of three blocks P, Q and R shown in figure has a mass of 3 kg. Each of the wire A and B has cross-sectional area 0.005 cm² and Young modulus 2×10¹¹ N m⁻². Neglecting friction, the longitudinal strain on wire B is _____ ×10⁻⁴. (Take g = 10 m s⁻²)',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Properties of Solids and Liquids',
        subTopic: 'Young Modulus',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Young Modulus', 'Strain Calculation'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0427',
        questionText:
            'In a closed organ pipe, the frequency of fundamental note is 30 Hz. A certain amount of water is now poured in the organ pipe so that the fundamental frequency is increased to 110 Hz. If the organ pipe has a cross-sectional area of 2 cm², the amount of water poured in the organ tube is ________ g. (Take speed of sound in air is 330 m s⁻¹)',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Oscillations and Waves',
        subTopic: 'Organ Pipe',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Closed Organ Pipe', 'Fundamental Frequency'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0428',
        questionText:
            'A capacitor of capacitance C and potential V has energy E. It is connected to another capacitor of capacitance 2C and potential 2V. Then the loss of energy is xE, where x is _______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Electrostatics',
        subTopic: 'Capacitor Energy',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Capacitor Energy', 'Energy Loss'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0429',
        questionText:
            'Two cells are connected in opposition as shown. Cell E₁ is of 8 V emf and 2 Ω internal resistance; the cell E₂ is of 2 V emf and 4 Ω internal resistance. The terminal potential difference of cell E₂ is ______ V.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Current Electricity',
        subTopic: 'Cell Circuits',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Internal Resistance', 'Terminal Voltage'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0430',
        questionText:
            'A ceiling fan having 3 blades of length 80 cm each is rotating with an angular velocity of 1200 rpm. The magnetic field of earth in that region is 0.5 G and angle of dip is 30°. The emf induced across the blades is Nπ×10⁻⁵ V. The value of N is _______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Magnetic Effects of Current and Magnetism',
        subTopic: 'Electromagnetic Induction',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Motional EMF', 'Earth Magnetic Field'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0431',
        questionText:
            'The horizontal component of earth magnetic field at a place is 3.5×10⁻⁵ T. A very long straight conductor carrying current of √2 A in the direction from South east to North West is placed. The force per unit length experienced by the conductor is ________×10⁻⁶ N m⁻¹.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Magnetic Effects of Current and Magnetism',
        subTopic: 'Magnetic Force',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Magnetic Force on Conductor', 'Earth Magnetic Field'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0432',
        questionText:
            'The distance between object and its two times magnified real image as produced by a convex lens is 45 cm. The focal length of the lens used is ________ cm.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Optics',
        subTopic: 'Lens Formula',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Lens Formula', 'Magnification'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0433',
        questionText:
            'An electron of hydrogen atom on an excited state is having energy Eₙ = −0.85 eV. The maximum number of allowed transitions to lower energy level is _______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Atoms and Nuclei',
        subTopic: 'Hydrogen Spectrum',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Hydrogen Atom', 'Spectral Transitions'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0404',
        questionText:
            'Given below are two statements: Statement-I: The orbitals having same energy are called as degenerate orbitals. Statement-II: In hydrogen atom, 3p and 3d orbitals are not degenerate orbitals. In the light of the above statements, choose the most appropriate answer from the options given',
        options: [
          'Statement-I is true but Statement-II is false',
          'Both Statement-I and Statement-II are true.',
          'Both Statement-I and Statement-II are false',
          'Statement-I is false but Statement-II is true'
        ],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Atomic Structure',
        subTopic: 'Orbital Degeneracy',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Degenerate Orbitals', 'Hydrogen Atom'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0405',
        questionText:
            'Given below are the two statements: one is labeled as Assertion (A) and the other is labeled as Reason (R). Assertion (A): There is a considerable increase in covalent radius from N to P. However from As to Bi only a small increase in covalent radius is observed. Reason (R): covalent and ionic radii in a particular oxidation state increases down the group. In the light of the above statement, choose the most appropriate answer from the options given below:',
        options: [
          '(A) is false but (R) is true',
          'Both (A) and (R) are true but (R) is not the correct explanation of (A)',
          '(A) is true but (R) is false',
          'Both (A) and (R) are true and (R) is the correct explanation of (A)'
        ],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'Classification of Elements and Periodicity in Properties',
        subTopic: 'Atomic Radius',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Covalent Radius', 'Periodic Trends'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0406',
        questionText:
            'Match List-I with List-II. List I (Molecule): A. BrF₅, B. H₂O, C. ClF₃, D. SF₄. List II (Shape): i. T-shape, ii. See saw, iii. Bent, iv. Square pyramidal',
        options: [
          '(A)-I, (B)-II, (C)-IV, (D)-III',
          '(A)-II, (B)-I, (C)-III, (D)-IV',
          '(A)-III, (B)-IV, (C)-I, (D)-II',
          '(A)-IV, (B)-III, (C)-I, (D)-II'
        ],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Chemical Bonding and Molecular Structure',
        subTopic: 'Molecular Shapes',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['VSEPR Theory', 'Molecular Geometry'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0407',
        questionText: 'Structure of 4-Methylpent-2-enal is:',
        options: [
          'CH₃-CH=CH-CH(CH₃)-CHO',
          'CH₃-CH₂-CH=CH-CH(CH₃)-CHO',
          '(CH₃)₂CH-CH=CH-CHO',
          'CH₃-CH₂-CH₂-CH=CH-CHO'
        ],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Organic Compounds Containing Oxygen',
        subTopic: 'Aldehydes',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['IUPAC Nomenclature', 'Aldehydes'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0408',
        questionText: 'Example of vinylic halide is',
        options: ['CH₂=CH-Cl', 'CH₂=CH-CH₂-Cl', 'C₆H₅-Cl', 'CH₃-CH₂-Cl'],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Organic Compounds Containing Halogens',
        subTopic: 'Vinylic Halides',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Vinylic Halides', 'Halogen Compounds'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0409',
        questionText:
            'Given below are two statement one is labeled as Assertion (A) and the other is labeled as Reason (R). Assertion (A): CH₂=CH-CH₂-Cl is an example of allyl halide. Reason (R): Allyl halides are the compounds in which the halogen atom is attached to sp² hybridised carbon atom. In the light of the two above statements, choose the most appropriate answer from the options given below:',
        options: [
          '(A) is true but (R) is false',
          'Both (A) and (R) are true but (R) is not the correct explanation of A',
          '(A) is false but (R) is true',
          'Both (A) and (R) are true and (R) is the correct explanation of (A)'
        ],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Organic Compounds Containing Halogens',
        subTopic: 'Allyl Halides',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Allyl Halides', 'Hybridization'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0410',
        questionText: 'Which of the following molecule/species is most stable?',
        options: ['CH₃⁺', 'CH₃⁻', 'CH₃', 'CH₄'],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Hydrocarbons',
        subTopic: 'Carbon Compounds Stability',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Carbon Compounds', 'Stability'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0411',
        questionText:
            'Compound A formed in the following reaction reacts with B gives the product C. Find out A and B.',
        options: [
          'A = CH₃-C≡C-Na⁺, B = CH₃-CH₂-CH₂-Br',
          'A = CH₃-CH=CH₂, B = CH₃-CH₂-CH₂-Br',
          'A = CH₃-CH₂-CH₃, B = CH₃-C≡CH',
          'A = CH₃-C≡C-Na⁺, B = CH₃-CH₂-CH₃'
        ],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Hydrocarbons',
        subTopic: 'Alkynes',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Alkynes', 'Chemical Reactions'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0412',
        questionText:
            'In the given reactions identify the reagent A and reagent B',
        options: [
          'A-CrO₃, B-CrO₃',
          'A-CrO₃, B-CrO₂Cl₂',
          'A-CrO₂Cl₂, B-CrO₂Cl₂',
          'A-CrO₂Cl₂, B-CrO₃'
        ],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'Organic Compounds Containing Oxygen',
        subTopic: 'Oxidation Reactions',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Oxidation Reagents', 'Chromium Compounds'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0413',
        questionText:
            'What happens to freezing point of benzene when small quantity of naphthalene is added to benzene?',
        options: [
          'Increases',
          'Remains unchanged',
          'First decreases and then increases',
          'Decreases'
        ],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Solutions',
        subTopic: 'Colligative Properties',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Freezing Point Depression', 'Colligative Properties'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0414',
        questionText: 'Diamagnetic Lanthanoid ions are:',
        options: [
          'Nd³⁺ and Eu³⁺',
          'La³⁺ and Ce⁴⁺',
          'Nd³⁺ and Ce⁴⁺',
          'Lu³⁺ and Eu³⁺'
        ],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'd- and f-Block Elements',
        subTopic: 'Lanthanoids',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Lanthanoids', 'Magnetic Properties'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0415',
        questionText:
            'Match List-I with List-II. List I (Species): A. Cr²⁺, B. Mn⁺, C. Ni²⁺, D. V⁺. List II (Electronic distribution): i. 3d⁸, ii. 3d³4s¹, iii. 3d⁴, iv. 3d⁵4s¹',
        options: [
          '(A)-I, (B)-II, (C)-III, (D)-IV',
          '(A)-III, (B)-IV, (C)-I, (D)-II',
          '(A)-IV, (B)-III, (C)-I, (D)-II',
          '(A)-II, (B)-I, (C)-IV, (D)-III'
        ],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'd- and f-Block Elements',
        subTopic: 'Electronic Configuration',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Electronic Configuration', 'Transition Metals'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0416',
        questionText:
            'Choose the correct Statements from the following: (A) Ethane-1,2-diamine is a chelating ligand. (B) Metallic aluminium is produced by electrolysis of aluminium oxide in presence of cryolite. (C) Cyanide ion is used as ligand for leaching of silver. (D) Phosphine act as a ligand in Wilkinson catalyst. (E) The stability constants of Ca²⁺ and Mg²⁺ are similar with EDTA complexes.',
        options: [
          '(B), (C), (E) only',
          '(C), (D), (E) only',
          '(A), (B), (C) only',
          '(A), (D), (E) only'
        ],
        correctAnswerIndex: 2,
        subject: 'Chemistry',
        topic: 'Coordination Compounds',
        subTopic: 'Coordination Chemistry',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Coordination Compounds', 'Metallurgy'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0417',
        questionText:
            'Aluminium chloride in acidified aqueous solution forms an ion having geometry',
        options: [
          'Octahedral',
          'Square Planar',
          'Tetrahedral',
          'Trigonal bipyramidal'
        ],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Coordination Compounds',
        subTopic: 'Coordination Geometry',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Coordination Geometry', 'Aluminium Compounds'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0418',
        questionText: 'This reduction reaction is known as:',
        options: [
          'Rosenmund reduction',
          'Wolff-Kishner reduction',
          'Stephen reduction',
          'Etard reduction'
        ],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Organic Compounds Containing Oxygen',
        subTopic: 'Reduction Reactions',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Reduction Reactions', 'Named Reactions'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0419',
        questionText:
            'Following is a confirmatory test for aromatic primary amines. Identify reagent (A) and (B)',
        options: [
          'A = NaNO₂ + HCl, B = β-naphthol',
          'A = CHCl₃ + KOH, B = Aniline',
          'A = Br₂ water, B = NaOH',
          'A = FeCl₃, B = KMnO₄'
        ],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Organic Compounds Containing Nitrogen',
        subTopic: 'Amine Tests',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Diazotization', 'Azo Dye Test'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0420',
        questionText:
            'The final product A, formed in the following multistep reaction sequence is:',
        options: ['Benzaldehyde', 'Benzoic acid', 'Benzyl alcohol', 'Phenol'],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'Organic Compounds Containing Nitrogen',
        subTopic: 'Reaction Sequences',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Reaction Mechanism', 'Organic Synthesis'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0421',
        questionText:
            'Given below are two statements: Statement-I: The gas liberated on warming a salt with dil H₂SO₄, turns a piece of paper dipped in lead acetate into black, it is a confirmatory test for sulphide ion. Statement-II: In statement-I the colour of paper turns black because of formation of lead sulphite. In the light of the above statements, choose the most appropriate answer from the options given below:',
        options: [
          'Both Statement-I and Statement-II are false',
          'Statement-I is false but Statement-II is true',
          'Statement-I is true but Statement-II is false',
          'Both Statement-I and Statement-II are true.'
        ],
        correctAnswerIndex: 2,
        subject: 'Chemistry',
        topic: 'Principles Related to Practical Chemistry',
        subTopic: 'Qualitative Analysis',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Sulfide Test', 'Lead Acetate Test'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0422',
        questionText:
            'The Lassaigne extract is boiled with dil HNO₃ before testing for halogens because,',
        options: [
          'AgCN is soluble in HNO₃',
          'Silver halides are soluble in HNO₃',
          'Ag₂S is soluble in HNO₃',
          'Na₂S and NaCN are decomposed by HNO₃'
        ],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Purification and Characterisation of Organic Compounds',
        subTopic: 'Lassaigne Test',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Lassaigne Test', 'Halogen Test'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0423',
        questionText:
            'Sugar which does not give reddish brown precipitate with Fehling reagent is:',
        options: ['Sucrose', 'Lactose', 'Glucose', 'Maltose'],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Biomolecules',
        subTopic: 'Carbohydrates',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Fehling Test', 'Reducing Sugars'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0424',
        questionText:
            '0.05 cm thick coating of silver is deposited on a plate of 0.05 m² area. The number of silver atoms deposited on plate are _______ × 10²³. (At mass Ag = 108, d = 7.9 g cm⁻³) Round off to the nearest integer.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Some Basic Concepts in Chemistry',
        subTopic: 'Mole Concept',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Mole Calculation', 'Density', 'Atomic Mass'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0425',
        questionText:
            'If IUPAC name of an element is "Unununnium" then the element belongs to nth group of periodic table. The value of n is _______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Classification of Elements and Periodicity in Properties',
        subTopic: 'IUPAC Nomenclature',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['IUPAC Naming', 'Periodic Table Groups'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0426',
        questionText:
            'The total number of molecular orbitals formed from 2s and 2p atomic orbitals of a diatomic molecule',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Chemical Bonding and Molecular Structure',
        subTopic: 'Molecular Orbitals',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Molecular Orbital Theory', 'Atomic Orbitals'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0427',
        questionText:
            'An ideal gas undergoes a cyclic transformation starting from the point A and coming back to the same point by tracing the path A → B → C → A as shown in the diagram. The total work done in the process is _____ J.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Thermodynamics',
        subTopic: 'Cyclic Process',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Cyclic Process', 'Work Done'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0428',
        questionText:
            'The pH at which Mg(OH)₂ [Ksp = 1×10⁻¹¹] begins to precipitate from a solution containing 0.10M Mg²⁺ ions is ______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Equilibrium',
        subTopic: 'Solubility Product',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Solubility Product', 'Precipitation'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0429',
        questionText:
            '2MnO₄⁻ + bI⁻ + cH₂O → xI₂ + yMnO₂ + zOH⁻. If the above equation is balanced with integer coefficients, the value of z is ________.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Redox Reactions and Electrochemistry',
        subTopic: 'Balancing Equations',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Redox Balancing', 'Coefficient Calculation'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0430',
        questionText:
            'On a thin layer chromatographic plate, an organic compound moved by 3.5 cm, while the solvent moved by 5 cm. The retardation factor of the organic compound is _____________ × 10⁻¹',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Purification and Characterisation of Organic Compounds',
        subTopic: 'Chromatography',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['TLC', 'Retardation Factor'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0431',
        questionText:
            'The mass of sodium acetate (CH₃COONa) required to prepare 250 mL of 0.35M aqueous solution is _____ g. (Molar mass of CH₃COONa is 82.02 g mol⁻¹) Round off to the nearest integer.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Solutions',
        subTopic: 'Molarity Calculation',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Molarity', 'Mass Calculation'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0432',
        questionText:
            'The rate of first order reaction is 0.04 mol L⁻¹ s⁻¹ at 10 minutes and 0.03 mol L⁻¹ s⁻¹ at 20 minutes after initiation. Half life of the reaction is ______ minutes. (Given log2 = 0.3010, log3 = 0.4771) Round off your answer to the nearest integer.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Chemical Kinetics',
        subTopic: 'Half Life',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['First Order Kinetics', 'Half Life Calculation'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0433',
        questionText:
            'The compound formed by the reaction of ethanal with semicarbazide contains _______ number of nitrogen atoms.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Organic Compounds Containing Oxygen',
        subTopic: 'Carbonyl Compounds',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Semicarbazone Formation', 'Nitrogen Count'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0402',
        questionText:
            'If z = x + iy, xy ≠ 0, satisfies the equation z² + iz = 0, then |z²| is equal to:',
        options: ['9', '1', '4', '1/4'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Complex Numbers and Quadratic Equations',
        subTopic: 'Complex Equations',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Complex Numbers', 'Modulus'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0403',
        questionText:
            'Let Sₙ denote the sum of first n terms of an arithmetic progression. If S₂₀ = 790 and S₁₀ = 145, then S₁₅ − S₅ is:',
        options: ['395', '390', '405', '410'],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Sequence and Series',
        subTopic: 'Arithmetic Progression',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Arithmetic Progression', 'Sum Calculation'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0404',
        questionText:
            'If 2sin³x + sin²x cosx + 4sinx − 4 = 0 has exactly 3 solutions in the interval [0, nπ/2], n ∈ N, then the roots of the equation x² + nx + (n−3) = 0 belong to:',
        options: ['(0,∞)', '(−∞,0)', '(−√17/2, √17/2)', 'Z'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Trigonometry',
        subTopic: 'Trigonometric Equations',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Trigonometric Equations', 'Roots Analysis'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0405',
        questionText:
            'A line passing through the point A(9,0) makes an angle of 30° with the positive direction of x-axis. If this line is rotated about A through an angle of 15° in the clockwise direction, then its equation in the new position is',
        options: [
          'y = (√3−2)(x−9)',
          'x = (√3−2)(y−9)',
          'y = (√3+2)(x−9)',
          'x = (√3+2)(y−9)'
        ],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: 'Line Equations',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Line Rotation', 'Slope Calculation'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0406',
        questionText:
            'If the circles (x+1)² + (y+2)² = r² and x² + y² − 4x − 4y + 4 = 0 intersect at exactly two distinct points, then',
        options: ['5 < r < 9', '0 < r < 7', '3 < r < 7', '1 < r < 7/2'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: 'Circle Intersection',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Circle Geometry', 'Intersection Conditions'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0407',
        questionText:
            'The maximum area of a triangle whose one vertex is at (0,0) and the other two vertices lie on the curve y = −2x² + 54 at points (x, y) and (−x, y) where y > 0 is:',
        options: ['88', '122', '92', '108'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Limit, Continuity and Differentiability',
        subTopic: 'Maxima Minima',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Area Maximization', 'Parabola'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0408',
        questionText:
            'If the length of the minor axis of ellipse is equal to half of the distance between the foci, then the eccentricity of the ellipse is:',
        options: ['√5/3', '√3/2', '1/√3', '2/√5'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: 'Ellipse Properties',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Ellipse', 'Eccentricity'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0409',
        questionText:
            'Let f: [−π, π] → R be a differentiable function such that f(0) = 1/2. If limₓ→₀ (∫₀ˣ f(t)dt)/(eˣ²−1) = α, then 8α² is equal to:',
        options: ['16', '2', '1', '4'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Integral Calculus',
        subTopic: 'Limits and Integration',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['L Hospital Rule', 'Definite Integral'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0410',
        questionText:
            'Let M denote the median of the following frequency distribution. Class: 0-4, 4-8, 8-12, 12-16, 16-20 Frequency: 3, 9, 10, 8, 6 Then 20M is equal to:',
        options: ['416', '104', '52', '208'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Statistics and Probability',
        subTopic: 'Median Calculation',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Frequency Distribution', 'Median'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0411',
        questionText:
            'If f(x) = |3+2cos4x 2sin4x sin²2x; 2sin4x 3+2cos4x sin²2x; sin²2x sin²2x 3+2sin4x| then 1/5 f′(0) is equal to:',
        options: ['0', '1', '2', '6'],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Matrices and Determinants',
        subTopic: 'Determinant Differentiation',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Determinant', 'Differentiation'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0412',
        questionText:
            'Consider the system of linear equation x+y+z = 4μ, x+2y+2λz = 10μ, x+3y+4λ²z = μ²+15, where λ,μ ∈ R. Which one of the following statements is NOT correct?',
        options: [
          'The system has unique solution if λ ≠ 1/2 and μ ≠ 1',
          'The system is inconsistent if λ = 1/2 and μ ≠ 1,15',
          'The system has infinite number of solutions if λ = 1/2 and μ = 15',
          'The system is consistent if λ ≠ 1/2'
        ],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Matrices and Determinants',
        subTopic: 'System of Equations',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Linear Systems', 'Consistency'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0413',
        questionText:
            'If the domain of the function f(x) = cos⁻¹(2−|x|) + (logₑ(3−x))⁻¹ is [−α,β)−{γ}, then α+β+γ is equal to:',
        options: ['12', '9', '11', '8'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Sets, Relations and Functions',
        subTopic: 'Domain of Function',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Domain', 'Inverse Trigonometric', 'Logarithmic'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0414',
        questionText:
            'Let g: R → R be a non constant twice differentiable such that g′(1/2) = g′(3/2). If a real valued function f is defined as f(x) = 1/2[g(x) + g(2−x)], then which of the following is true?',
        options: [
          'f′′(x) = 0 for atleast two x in (1/2,3/2)',
          'f′′(x) = 0 for exactly one x in (1/2,3/2)',
          'f′′(x) = 0 for no x in (1/2,3/2)',
          'f′(3/2) + f′(1/2) = 1'
        ],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Limit, Continuity and Differentiability',
        subTopic: 'Differentiation',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Second Derivative', 'Rolle Theorem'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0415',
        questionText: 'The value of limₙ→∞ ∑ₖ₌₁ⁿ n³/[(n²+k²)(n²+3k²)] is:',
        options: ['π/8', '13π/8', '13/8', 'π/4'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Integral Calculus',
        subTopic: 'Limit of Sum',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Limit of Sum', 'Definite Integral'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0416',
        questionText:
            'The area (in square units) of the region bounded by the parabola y² = 4(x−2) and the line y = 2x−8.',
        options: ['8', '9', '6', '7'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Integral Calculus',
        subTopic: 'Area Calculation',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Area Between Curves', 'Parabola and Line'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0417',
        questionText:
            'Let y = y(x) be the solution of the differential equation secx dy + {2(1−x)tanx + x(2−x)}dx = 0 such that y(0) = 2. Then y(2) is equal to:',
        options: ['2', '2{1−sin(2)}', '2{sin(2)+1}', '1'],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Differential Equations',
        subTopic: 'First Order DE',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Differential Equation', 'Initial Value'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0418',
        questionText:
            'Let A(2,3,5) and C(−3,4,−2) be opposite vertices of a parallelogram ABCD if the diagonal BD = i + 2j + 3k then the area of the parallelogram is equal to',
        options: ['1/2 √410', '1/2 √474', '1/2 √586', '1/2 √306'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Vector Algebra',
        subTopic: 'Parallelogram Area',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Vector Geometry', 'Area Calculation'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0419',
        questionText:
            'Let a = a₁i + a₂j + a₃k and b = b₁i + b₂j + b₃k be two vectors such that |a| = 1; a·b = 2 and |b| = 4. If c = 2(a×b) − 3b, then the angle between b and c is equal to:',
        options: ['cos⁻¹(2/√3)', 'cos⁻¹(−1/√3)', 'cos⁻¹(−√3/2)', 'cos⁻¹(2/3)'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Vector Algebra',
        subTopic: 'Vector Angles',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Dot Product', 'Cross Product', 'Angle Between Vectors'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0420',
        questionText:
            'Let (α,β,γ) be the foot of perpendicular from the point (1,2,3) on the line (x+3)/5 = (y−1)/2 = (z+4)/3. then 19(α+β+γ) is equal to:',
        options: ['102', '101', '99', '100'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Three Dimensional Geometry',
        subTopic: 'Foot of Perpendicular',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['3D Geometry', 'Perpendicular Distance'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0421',
        questionText:
            'Two integers x and y are chosen with replacement from the set {0,1,2,3,…..,10}. Then the probability that |x−y| > 5 is:',
        options: ['30/121', '62/121', '60/121', '31/121'],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Statistics and Probability',
        subTopic: 'Probability',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Probability', 'Absolute Difference'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0422',
        questionText:
            'Let α,β be roots of equation x² − 70x + λ = 0, where λ, λ ∉ Z. If λ assumes the minimum possible value, then (√(α−1) + √(β−1))(|α−β|)/(λ+35) is equal to:',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Complex Numbers and Quadratic Equations',
        subTopic: 'Quadratic Roots',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Quadratic Equations', 'Roots', 'Minimum Value'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0423',
        questionText:
            'Let α = 1² + 4² + 8² + 13² + 19² + 26² + … up to 10 terms and β = ∑₁⁰ n⁴. If 4α − β = 55k + 40, then k is equal to _______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Sequence and Series',
        subTopic: 'Series Sum',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Series Summation', 'Pattern Recognition'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0424',
        questionText:
            'Number of integral terms in the expansion of {7^(1/2) + 11^(1/6)}⁸²⁴ is equal to ______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Binomial Theorem and Its Simple Applications',
        subTopic: 'Binomial Expansion',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Binomial Theorem', 'Integral Terms'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0425',
        questionText:
            'Let the latus rectum of the hyperbola x²/9 − y²/b² = 1 subtend an angle of π/3 at the centre of the hyperbola. If b² is equal to l/m (1+√n), where l and m are co-prime numbers, then l² + m² + n² is equal to __________.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: 'Hyperbola',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Hyperbola', 'Latus Rectum', 'Angle Subtended'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0426',
        questionText:
            'A group of 40 students appeared in an examination of 3 subjects - mathematics, physics & chemistry. It was found that all students passed in at least one of the subjects, 20 students passed in mathematics, 25 students passed in physics, 16 students passed in chemistry, at most 11 students passed in both mathematics and physics, at most 15 students passed in both physics and chemistry, at most 15 students passed in both mathematics and chemistry. The maximum number of students passed in all the three subjects is _____.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Sets, Relations and Functions',
        subTopic: 'Set Theory',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Set Theory', 'Venn Diagram', 'Maximum Intersection'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0427',
        questionText:
            'Let A = {1,2,3,…7} and let P(A) denote the power set of A. If the number of functions f: A → P(A) such that a ∈ f(a), ∀a ∈ A is mⁿ, m and n ∈ N and m is least, then m+n is equal to ______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Sets, Relations and Functions',
        subTopic: 'Functions',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Functions', 'Power Set', 'Counting'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0428',
        questionText:
            'If the function f(x) = {1/|x|, |x| ≥ 2; ax² + 2b, |x| < 2} is differentiable on R, then 48(a+b) is equal to _______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Limit, Continuity and Differentiability',
        subTopic: 'Differentiability',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Piecewise Function', 'Differentiability'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0429',
        questionText:
            'The value of ∫₀⁹ [√(10x/(x+1))] dx, where [t] denotes the greatest integer less than or equal to t, is _____.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Integral Calculus',
        subTopic: 'Definite Integral',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Greatest Integer Function', 'Definite Integral'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0430',
        questionText:
            'Let y = y(x) be the solution of the differential equation (1−x²)dy = [xy + (x³+2)√(3(1−x²))]dx, −1 < x < 1, y(0) = 0. If y(1/2) = m/n, m and n are coprime numbers, then m+n is equal to __________.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Differential Equations',
        subTopic: 'First Order DE',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Differential Equation', 'Initial Value'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0431',
        questionText:
            'If d₁ is the shortest distance between the lines (x+1)/2 = y/2 = −12/z, x = (y+2)/6 = (z−6)/1 and d₂ is the shortest distance between the lines (x−1)/2 = (y+8)/−7 = (z−4)/5, (x−1)/2 = (y−2)/1 = (z−6)/−3, then the value of 32√3 d₁/d₂ is:',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Three Dimensional Geometry',
        subTopic: 'Shortest Distance',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Shortest Distance', 'Skew Lines'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0434',
        questionText:
            'A physical quantity Q is found to depend on quantities a, b, c by the relation Q = a⁴b³/c². The percentage error in a, b and c are 3%, 4% and 5% respectively. Then, the percentage error in Q is:',
        options: ['66%', '43%', '34%', '14%'],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Units and Measurements',
        subTopic: 'Error Analysis',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Percentage Error', 'Error Propagation'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0435',
        questionText:
            'A particle is moving in a straight line. The variation of position x as a function of time t is given as x = (t³ − 6t² + 20t + 15) m. The velocity of the body when its acceleration becomes zero is:',
        options: ['4 m s⁻¹', '8 m s⁻¹', '10 m s⁻¹', '6 m s⁻¹'],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Kinematics',
        subTopic: 'Motion in Straight Line',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Velocity', 'Acceleration', 'Differentiation'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0436',
        questionText:
            'A stone of mass 900 g is tied to a string and moved in a vertical circle of radius 1 m making 10 rpm. The tension in the string, when the stone is at the lowest point is (if π² = 9.8 and g = 9.8 m s⁻²)',
        options: ['97 N', '9.8 N', '8.82 N', '17.8 N'],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Rotational Motion',
        subTopic: 'Circular Motion',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Circular Motion', 'Tension', 'Centripetal Force'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0437',
        questionText:
            'The bob of a pendulum was released from a horizontal position. The length of the pendulum is 10 m. If it dissipates 10% of its initial energy against air resistance, the speed with which the bob arrives at the lowest point is: [Use, g = 10 m s⁻²]',
        options: ['6√5 m s⁻¹', '5√6 m s⁻¹', '5√5 m s⁻¹', '2√5 m s⁻¹'],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Work, Energy and Power',
        subTopic: 'Energy Conservation',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Energy Conservation', 'Pendulum', 'Energy Dissipation'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0438',
        questionText:
            'A bob of mass m is suspended by a light string of length L. It is imparted a minimum horizontal velocity at the lowest point A such that it just completes half circle reaching the top most position B. The ratio of kinetic energies (K.E.)A/(K.E.)B is:',
        options: ['3 : 2', '5 : 1', '2 : 5', '1 : 5'],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Work, Energy and Power',
        subTopic: 'Circular Motion',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Circular Motion', 'Kinetic Energy', 'Energy Conservation'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0439',
        questionText:
            'A planet takes 200 days to complete one revolution around the Sun. If the distance of the planet from Sun is reduced to one fourth of the original distance, how many days will it take to complete one revolution?',
        options: ['25', '50', '100', '20'],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Gravitation',
        subTopic: "Kepler's Laws",
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ["Kepler's Third Law", 'Orbital Period'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0440',
        questionText:
            'A wire of length L and radius r is clamped at one end. If its other end is pulled by a force F, its length increases by l. If the radius of the wire and the applied force both are reduced to half of their original values keeping original length constant, the increase in length will become:',
        options: ['3 times', '3/2 times', '4 times', '2 times'],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Properties of Solids and Liquids',
        subTopic: 'Elasticity',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Young Modulus', 'Elongation'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0441',
        questionText:
            'A small liquid drop of radius R is divided into 27 identical liquid drops. If the surface tension is T, then the work done in the process will be:',
        options: ['8πR²T', '3πR²T', '1/8 πR²T', '4πR²T'],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Properties of Solids and Liquids',
        subTopic: 'Surface Tension',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Surface Tension', 'Work Done'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0442',
        questionText:
            'The temperature of a gas having 2.0×10²⁵ molecules per cubic meter at 1.38 atm (Given, k = 1.38×10⁻²³ J K⁻¹) is:',
        options: ['500 K', '200 K', '100 K', '300 K'],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Kinetic Theory of Gases',
        subTopic: 'Ideal Gas Law',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Ideal Gas Equation', 'Temperature Calculation'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0443',
        questionText:
            'N moles of a polyatomic gas (f = 6) must be mixed with two moles of a monoatomic gas so that the mixture behaves as a diatomic gas. The value of N is:',
        options: ['6', '3', '4', '2'],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Kinetic Theory of Gases',
        subTopic: 'Degrees of Freedom',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Degrees of Freedom', 'Specific Heat'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0444',
        questionText:
            'An electric field is given by (6î + 5ĵ + 3k̂) N C⁻¹. The electric flux through a surface area 30î m² lying in YZ-plane (in SI unit) is:',
        options: ['90', '150', '180', '60'],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Electrostatics',
        subTopic: 'Electric Flux',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Electric Flux', 'Vector Area'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0445',
        questionText: 'In the given circuit, the current in resistance R₃ is:',
        options: ['1 A', '1.5 A', '2 A', '2.5 A'],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Current Electricity',
        subTopic: 'Circuit Analysis',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Kirchhoff Laws', 'Current Division'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0446',
        questionText:
            'Two particles X and Y having equal charges are being accelerated through the same potential difference. Thereafter, they enter normally in a region of uniform magnetic field and describes circular paths of radii R₁ and R₂ respectively. The mass ratio of X and Y is:',
        options: ['(R₂/R₁)²', '(R₁/R₂)²', 'R₁/R₂', 'R₂/R₁'],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Magnetic Effects of Current and Magnetism',
        subTopic: 'Charged Particle in Magnetic Field',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Magnetic Force', 'Circular Motion', 'Mass Ratio'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0447',
        questionText:
            'In an a.c. circuit, voltage and current are given by: V = 100sin(100t) V and I = 100sin(100t + π/3) mA respectively. The average power dissipated in one cycle is:',
        options: ['5 W', '10 W', '2.5 W', '25 W'],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Electromagnetic Induction and Alternating Currents',
        subTopic: 'AC Power',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['AC Power', 'Power Factor'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0448',
        questionText:
            'A plane electromagnetic wave of frequency 35 MHz travels in free space along the X-direction. At a particular point (in space and time) E = 9.6 ĵ V m⁻¹. The value of magnetic field at this point is:',
        options: ['3.2×10⁻⁸ k̂ T', '3.2×10⁻⁸ î T', '9.6 ĵ T', '9.6×10⁻⁸ k̂ T'],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Electromagnetic Waves',
        subTopic: 'EM Wave Properties',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['EM Waves', 'Magnetic Field Component'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0449',
        questionText:
            'If the distance between object and its two times magnified virtual image produced by a curved mirror is 15 cm, the focal length of the mirror must be:',
        options: ['15 cm', '−12 cm', '−10 cm', '10/3 cm'],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Optics',
        subTopic: 'Mirror Formula',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Mirror Formula', 'Magnification'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0450',
        questionText:
            "In Young's double slit experiment, light from two identical sources are superimposing on a screen. The path difference between the two lights reaching at a point on the screen is 7λ/4. The ratio of intensity of fringe at this point with respect to the maximum intensity of the fringe is:",
        options: ['1/2', '3/4', '1/3', '1/4'],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Optics',
        subTopic: 'Interference',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Interference', 'Intensity Pattern'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0451',
        questionText:
            'Two sources of light emit with a power of 200 W. The ratio of number of photons of visible light emitted by each source having wavelengths 300 nm and 500 nm respectively, will be:',
        options: ['1 : 5', '1 : 3', '5 : 3', '3 : 5'],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Dual Nature of Matter and Radiation',
        subTopic: 'Photon Energy',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Photon Energy', 'Wavelength'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0452',
        questionText:
            'Given below are two statements: Statement I: Most of the mass of the atom and all its positive charge are concentrated in a tiny nucleus and the electrons revolve around it, is Rutherford model. Statement II: An atom is a spherical cloud of positive charges with electrons embedded in it, is a special case of Rutherford model. In the light of the above statements, choose the most appropriate from the options given below.',
        options: [
          'Both statement I and statement II are false',
          'Statement I is false but statement II is true',
          'Statement I is true but statement II is false',
          'Both statement I and statement II are true'
        ],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Dual Nature of Matter and Radiation',
        subTopic: 'Atomic Models',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Rutherford Model', 'Atomic Structure'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0453',
        questionText: 'The truth table for this given circuit is:',
        options: ['AND Gate', 'OR Gate', 'NAND Gate', 'NOR Gate'],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Atoms and Nuclei',
        subTopic: 'Logic Gates',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Logic Gates', 'Truth Table'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0454',
        questionText:
            'A particle is moving in a circle of radius 50 cm in such a way that at any instant the normal and tangential components of its acceleration are equal. If its speed at t = 0 is 4 m s⁻¹, the time taken to complete the first revolution will be (1/α)[1−e⁻²π] s, where α =______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Electronic Devices',
        subTopic: 'Circular Motion',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Circular Motion', 'Acceleration Components'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0455',
        questionText:
            'A body of mass 5 kg moving with a uniform speed 3√2 m s⁻¹ in X−Y plane along the line y = x+4. The angular momentum of the particle about the origin will be _______ kg m² s⁻¹.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Circular Motion',
        subTopic: 'Angular Momentum',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Angular Momentum', 'Linear Motion'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0456',
        questionText:
            'Two metallic wires P and Q have same volume and are made up of same material. If their area of cross sections are in the ratio 4 : 1 and force F₁ is applied to P, an extension of Δl is produced. The force which is required to produce same extension in Q is F₂. The value of F₁/F₂ is ______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'System of Particles and Rotational Motion',
        subTopic: 'Elasticity',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Young Modulus', 'Elongation'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0457',
        questionText:
            'A simple harmonic oscillator has an amplitude A and time period 6π second. Assuming the oscillation starts from its mean position, the time required by it to travel from x = A/2 to x = √3A/2 will be π/x s, where x = _______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Mechanical Properties of Solids',
        subTopic: 'Simple Harmonic Motion',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['SHM', 'Time Calculation'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0458',
        questionText:
            'In the given circuit, the current flowing through the resistance 20 Ω is 0.3 A, while the ammeter reads 0.9 A. The value of R₁ is _____ Ω.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Oscillations',
        subTopic: 'Circuit Analysis',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Kirchhoff Laws', 'Current Division'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0459',
        questionText:
            'A charge of 4.0 μC is moving with a velocity of 4.0×10⁶ m s⁻¹ along the positive y-axis under a magnetic field B of strength (2k̂) T. The force acting on the charge is xî N. The value of x is ______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Current Electricity',
        subTopic: 'Magnetic Force',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Magnetic Force', 'Cross Product'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0460',
        questionText:
            'A horizontal straight wire 5 m long extending from east to west falling freely at right angle to horizontal component of earth magnetic field 0.60×10⁻⁴ Wb m⁻². The instantaneous value of emf induced in the wire when its velocity is 10 m s⁻¹ is _______ × 10⁻³ V.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Magnetic Effects of Current and Magnetism',
        subTopic: 'Electromagnetic Induction',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Motional EMF', 'Faraday Law'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0461',
        questionText:
            'In the given figure, the charge stored in 6μF capacitor, when points A and B are joined by a connecting wire is _______ μC.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Electromagnetic Induction and Alternating Currents',
        subTopic: 'Capacitors',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Capacitors', 'Charge Storage'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0462',
        questionText:
            'In a single slit diffraction pattern, a light of wavelength 6000 Å is used. The distance between the first and third minima in the diffraction pattern is found to be 3 mm when the screen is placed 50 cm away from slits. The width of the slit is ____ × 10⁻⁴ m.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Electrostatics',
        subTopic: 'Diffraction',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Single Slit Diffraction', 'Minima Position'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0463',
        questionText:
            'Hydrogen atom is bombarded with electrons accelerated through a potential difference of V, which causes excitation of hydrogen atoms. If the experiment is being performed at T = 0 K. The minimum potential difference needed to observe any Balmer series lines in the emission spectra will be α/10 V, where α = _________. (Write the value to the nearest integer)',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Wave Optics',
        subTopic: 'Atomic Spectra',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Hydrogen Spectrum', 'Excitation Energy'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0434',
        questionText: 'Match List I with List II',
        options: [
          'A-II, B-III, C-I, D-IV',
          'A-I, B-III, C-II, D-IV',
          'A-II, B-IV, C-III, D-I',
          'A-I, B-II, C-III, D-IV'
        ],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Atoms and Nuclei',
        subTopic: 'Matching',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Concepts Matching'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0435',
        questionText:
            'The element having the highest first ionization enthalpy is',
        options: ['Si', 'Al', 'N', 'C'],
        correctAnswerIndex: 2,
        subject: 'Chemistry',
        topic: 'Classification of Elements and Periodicity in Properties',
        subTopic: 'Ionization Enthalpy',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Ionization Energy', 'Periodic Trends'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0436',
        questionText:
            'Given below are two statements: Statement I: Fluorine has most negative electron gain enthalpy in its group. Statement II: Oxygen has least negative electron gain enthalpy in its group. In the light of the above statements, choose the most appropriate from the options given below.',
        options: [
          'Both Statement I and Statement II are true',
          'Statement I is true but Statement II is false',
          'Both Statement I and Statement II are false',
          'Statement I is false but Statement II is true'
        ],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Classification of Elements and Periodicity in Properties',
        subTopic: 'Electron Gain Enthalpy',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Electron Affinity', 'Periodic Trends'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0437',
        questionText: 'According to IUPAC system, the compound is named as:',
        options: [
          'Cyclohex-1-en-2-ol',
          '1-Hydroxyhex-2-ene',
          'Cyclohex-1-en-3-ol',
          'Cyclohex-2-en-1-ol'
        ],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Classification of Elements and Periodicity in Properties',
        subTopic: 'IUPAC Nomenclature',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['IUPAC Naming', 'Organic Compounds'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0438',
        questionText: 'The ascending acidity order of the following H atoms is',
        options: [
          'C < D < B < A',
          'A < B < C < D',
          'A < B < D < C',
          'D < C < B < A'
        ],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Organic Compounds Containing Oxygen',
        subTopic: 'Acidity Order',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Acidity', 'Organic Compounds'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0439',
        questionText: 'Match List I with List II',
        options: [
          'A-I, B-II, C-III, D-IV',
          'A-IV, B-I, C-II, D-III',
          'A-III, B-IV, C-I, D-II',
          'A-II, B-I, C-IV, D-III'
        ],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Some Basic Principles of Organic Chemistry',
        subTopic: 'Matching',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Organic Chemistry Concepts'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0440',
        questionText:
            'Which one of the following will show geometrical isomerism?',
        options: ['Compound A', 'Compound B', 'Compound C', 'Compound D'],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'Some Basic Principles of Organic Chemistry',
        subTopic: 'Geometrical Isomerism',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Geometrical Isomerism', 'Stereochemistry'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0441',
        questionText:
            'Chromatographic technique/s based on the principle of differential adsorption is/are A. Column chromatography B. Thin layer chromatography C. Paper chromatography Choose the most appropriate answer from the options given below:',
        options: ['B only', 'A only', 'A & B only', 'C only'],
        correctAnswerIndex: 2,
        subject: 'Chemistry',
        topic: 'Purification and Characterisation of Organic Compounds',
        subTopic: 'Chromatography',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Chromatography', 'Separation Techniques'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0442',
        questionText: 'Anomalous behaviour of oxygen is due to its',
        options: [
          'Large size and high electronegativity',
          'Small size and low electronegativity',
          'Small size and high electronegativity',
          'Large size and low electronegativity'
        ],
        correctAnswerIndex: 2,
        subject: 'Chemistry',
        topic: 'p-Block Elements',
        subTopic: 'Oxygen Properties',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Anomalous Behavior', 'Oxygen'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0443',
        questionText:
            'Which of the following acts as a strong reducing agent? (Atomic number: Ce = 58, Eu = 63, Gd = 64, Lu = 71)',
        options: ['Lu³⁺', 'Gd³⁺', 'Eu²⁺', 'Ce⁴⁺'],
        correctAnswerIndex: 2,
        subject: 'Chemistry',
        topic: 'd- and f-Block Elements',
        subTopic: 'Reducing Agents',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Reducing Agents', 'f-block Elements'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0444',
        questionText:
            'Which of the following statements are correct about Zn, Cd and Hg? A. They exhibit high enthalpy of atomization as the d-subshell is full. B. Zn and Cd do not show variable oxidation state while Hg shows +I and +II. C. Compounds of Zn, Cd and Hg are paramagnetic in nature. D. Zn, Cd and Hg are called soft metals. Choose the most appropriate from the options given below:',
        options: ['B, D only', 'B, C only', 'A, D only', 'C, D only'],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'd- and f-Block Elements',
        subTopic: 'Zinc Group Properties',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Zinc Group', 'Properties'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0445',
        questionText: 'The correct IUPAC name of K₂MnO₄ is:',
        options: [
          'Potassium tetraoxopermanganate (VI)',
          'Potassium tetraoxidomanganate (VI)',
          'Dipotassium tetraoxidomanganate (VII)',
          'Potassium tetraoxidomanganese (VI)'
        ],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'd- and f-Block Elements',
        subTopic: 'IUPAC Nomenclature',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['IUPAC Naming', 'Coordination Compounds'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0446',
        questionText:
            'Alkyl halide is converted into alkyl isocyanide by reaction with',
        options: ['NaCN', 'NH₄CN', 'KCN', 'AgCN'],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Organic Compounds Containing Nitrogen',
        subTopic: 'Isocyanide Formation',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Isocyanide', 'Alkyl Halide Reactions'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0447',
        questionText:
            'Phenol treated with chloroform in presence of sodium hydroxide, which further hydrolysed in presence of an acid results',
        options: [
          'Salicylic acid',
          'Benzene-1,2-diol',
          'Benzene-1,3-diol',
          '2-Hydroxybenzaldehyde'
        ],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Organic Compounds Containing Oxygen',
        subTopic: 'Phenol Reactions',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Reimer-Tiemann Reaction', 'Phenol'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0448',
        questionText: 'Identify the reagents used for the following conversion',
        options: [
          'A = LiAlH₄, B = NaOH (aq), C = NH₂-NH₂/KOH ethylene glycol',
          'A = LiAlH₄, B = NaOH (alc), C = Zn/HCl',
          'A = DIBAL-H, B = NaOH (aq) C = NH₂-NH₂/KOH ethylene glycol',
          'A = DIBAL-H, B = NaOH (alc), C = Zn/HCl'
        ],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Some Basic Principles of Organic Chemistry',
        subTopic: 'Reagents',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Organic Reagents', 'Reaction Mechanism'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0449',
        questionText: 'Which of the following reaction is correct?',
        options: [
          'Reaction A',
          'Reaction B',
          'Reaction C',
          'C₂H₅CONH₂ + Br₂ + NaOH → C₂H₅CH₂NH₂ + Na₂CO₃ + NaBr + H₂O'
        ],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'Some Basic Principles of Organic Chemistry',
        subTopic: 'Reaction Correctness',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Reaction Mechanism', 'Organic Reactions'],
        questionType: 'multipleChoice',
      ),
      Question(
        id: 'CHEM0450',
        questionText: 'The product A formed in the following reaction is: ',
        options: ['| (1)', '| (2)', '| (3)', '| (4)'],
        correctAnswerIndex: 2,
        subject: 'Chemistry',
        topic: 'Some Basic Principles of Organic chemistry',
        subTopic: '',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Organic Reaction Mechanisms'],
        questionType: 'multipleChoice',
      ),
      Question(
        id: 'CHEM0451',
        questionText:
            'On passing a gas, \"X\", through Nessler\'s reagent, a brown precipitate is obtained. The gas \"X\" is',
        options: ['H₂S', 'CO₂', 'NH₃', 'Cl₂'],
        correctAnswerIndex: 2,
        subject: 'Chemistry',
        topic: 'Principles Related to Practical chemistry',
        subTopic: '',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Nessler\'s Reagent', 'Qualitative Analysis'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0452',
        questionText:
            'A reagent which gives brilliant red precipitate with Nickel ions in basic medium is',
        options: [
          'sodium nitroprusside',
          'neutral FeCl₃',
          'meta-dinitrobenzene',
          'dimethyl glyoxime'
        ],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Principles Related to Practical chemistry',
        subTopic: '',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Nickel Test', 'Precipitation Reactions'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0453',
        questionText:
            'Match List I with List II Choose the correct answer from the options given below :-',
        options: [
          'A-II, B-I, C-III, D-IV',
          'A-IV, B-II, C-I, D-III',
          'A-I, B-III, C-IV, D-II',
          'A-II, B-III, C-I, D-IV'
        ],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Coordination Compounds',
        subTopic: '',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Coordination Compounds', 'Matching'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0454',
        questionText:
            'The total number of molecules with zero dipole moment among CH₄, BF₃, H₂O, HF, NH₃, CO₂ and SO₂ is ______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Chemical Bonding and Molecular Structure',
        subTopic: 'Dipole Moment',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Dipole Moment', 'Molecular Symmetry'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0455',
        questionText:
            'The total number of \"Sigma\" and Pi bonds in 2-formylhex-4-enoic acid is',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Some Basic Principles of Organic chemistry',
        subTopic: 'Chemical Bonding',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Sigma Bonds', 'Pi Bonds', 'Organic Compounds'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0456',
        questionText:
            'The total number of anti bonding molecular orbitals, formed from 2s and 2p atomic orbitals in a diatomic molecule is _____________.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Chemical Bonding and Molecular Structure',
        subTopic: 'Molecular Orbitals',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Molecular Orbitals', 'Anti-bonding Orbitals'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0457',
        questionText:
            'Standard enthalpy of vapourisation for CCl₄ is 30.5 kJ mol⁻¹. Heat required for vapourisation of 284 g of CCl₄ at constant temperature is __________ kJ. (Given molar mass in gmol⁻¹; C = 12, Cl = 35.5) Round off your answer to the nearest integer.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Chemical Thermodynamics',
        subTopic: 'Enthalpy',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Enthalpy of Vaporization', 'Stoichiometry'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0458',
        questionText:
            'The following concentrations were observed at 500 K for the formation of NH₃ from N₂ and H₂. At equilibrium: [N₂] = 2×10⁻²M, [H₂] = 3×10⁻²M and [NH₃] = 1.5×10⁻²M. Equilibrium constant for the reaction is ______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Equilibrium',
        subTopic: 'Equilibrium Constant',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Equilibrium Constant', 'Chemical Equilibrium'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0459',
        questionText:
            'If 50 mL of 0.5M oxalic acid is required to neutralise 25 mL of NaOH solution, the amount of NaOH in 50 mL of given NaOH solution is _______g.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Some Basic Concepts in chemistry',
        subTopic: 'Stoichiometry',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Titration', 'Stoichiometry', 'Neutralization'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0460',
        questionText:
            'Molality of 0.8M H₂SO₄ solution (density 1.06 g cm⁻³) is _______×10⁻³ m. Round off your answer to the nearest integer.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Solutions',
        subTopic: 'Concentration Terms',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Molality', 'Concentration'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0461',
        questionText:
            'A constant current was passed through a solution of AuCl⁻ ion between gold electrodes. After a period of 10.0 minutes, the increase in mass of cathode was 1.314 g. The total charge passed through the solution is ___ ×10⁻² F. (Given atomic mass of Au = 197)',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Redox Reactions and Electrochemistry',
        subTopic: 'Electrolysis',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Electrolysis', 'Faraday\'s Law'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0462',
        questionText:
            'The half-life of radioisotopic bromine-82 is 36 hours. The fraction which remains after one day is _________ ×10⁻². (Given antilog 0.2006 = 1.587) Round off to the nearest integer',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Equilibrium',
        subTopic: 'Radioactive Decay',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Half-life', 'Radioactive Decay'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0463',
        questionText:
            'Oxidation state of Fe(Iron) in complex formed in Brown ring test.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Coordination Compounds',
        subTopic: 'Oxidation State',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Brown Ring Test', 'Oxidation State'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0432',
        questionText:
            'Let r and θ respectively be the modulus and amplitude of the complex number z = 2−i(2tan 5π), then (r,θ) is equal to',
        options: ['| (1)', '| (2)', '| (3)', '| (4)'],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Complex Numbers and Quadratic Equations',
        subTopic: '',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Complex Numbers', 'Modulus', 'Amplitude'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0433',
        questionText:
            'Number of ways of arranging 8 identical books into 4 identical shelves where any number of shelves may remain empty is equal to',
        options: ['18', '16', '12', '15'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Permutations and Combinations',
        subTopic: '',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Combinations', 'Arrangements'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0434',
        questionText:
            'If logₑa, logₑb, logₑc are in an A.P. and logₑa−logₑ2b, logₑ2b−logₑ3c, logₑ3c−logₑa are also in an A.P., then a : b : c is equal to',
        options: ['9 : 6 : 4', '16 : 4 : 1', '25 : 10 : 4', '6 : 3 : 2'],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Sequence and Series',
        subTopic: '',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Arithmetic Progression', 'Logarithms'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0435',
        questionText:
            'If each term of a geometric progression a₁, a₂, a₃, … with a₁ = 1/8 and a₂ ≠ a₁, is the arithmetic mean of the next two terms and Sₙ = a₁ + a₂ + … + aₙ, then S₂₀ − S₁₈ is equal to',
        options: ['2¹⁵', '−2¹⁸', '2¹⁸', '−2¹⁵'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Sequence and Series',
        subTopic: '',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Geometric Progression', 'Arithmetic Mean'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0436',
        questionText:
            'The sum of the solutions x ∈ R of the equation 3cos2x+cos³2x = x³−x²+6 is cos⁶x−sin⁶x',
        options: ['0', '1', '−1', '3'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Trigonometry',
        subTopic: '',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Trigonometric Equations', 'Polynomial Equations'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0437',
        questionText:
            'Let A be the point of intersection of the lines 3x+2y = 14, 5x−y = 6 and B be the point of intersection of the lines 4x+3y = 8, 6x+y = 5. The distance of the point P(5,−2) from the line AB is',
        options: ['13', '8√2', '5', '6√2'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: 'Distance from Line',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Line Intersection', 'Distance Formula'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0438',
        questionText:
            'The distance of the point (2,3) from the line 2x−3y+28 = 0, measured parallel to the line √3x−y+1 = 0, is equal to',
        options: ['4√2', '6√3', '3+4√2', '4+6√3'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: 'Distance from Line',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Distance from Line', 'Parallel Lines'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0439',
        questionText:
            'If the mean and variance of five observations are 24/5 and 194/25 respectively and the mean of first four observations is 7/2, then the variance of the first four observations is equal to',
        options: ['77/5', '105/12', '5/4', '4/5'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Statistics and Probability',
        subTopic: 'Variance',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Mean', 'Variance', 'Statistics'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0440',
        questionText:
            'If R is the smallest equivalence relation on the set {1,2,3,4} such that {(1,2),(1,3)} ⊂ R, then the number of elements in R is ______.',
        options: ['10', '12', '8', '15'],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Sets, Relations and Functions',
        subTopic: 'Equivalence Relations',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Equivalence Relations', 'Set Theory'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0441',
        questionText:
            'Let A = [[6,2,11],[3,3,2]] and P = [[5,0,2],[7,1,5]]. The sum of the prime factors of P⁻¹AP−2I is equal to',
        options: ['26', '27', '66', '23'],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Matrices and Determinants',
        subTopic: 'Matrix Operations',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Matrix Inverse', 'Prime Factors'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0442',
        questionText:
            'Let x = m/n (m,n are co-prime natural numbers) be a solution of the equation cos(2sin⁻¹x) = 1/9 and let α,β(α > β) be the roots of the equation mx² −nx−m+n = 0. Then the point (α,β) lies on the line',
        options: ['3x+2y = 2', '5x−8y = −9', '3x−2y = −2', '5x+8y = 9'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Trigonometry',
        subTopic: 'Inverse Trigonometric Functions',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Inverse Trigonometry', 'Quadratic Equations'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0443',
        questionText:
            'Let y = logₑ(1−x²)/(1+x²), −1 < x < 1. Then at x = 1/2, the value of 225(y′ − y′′) is equal to',
        options: ['732', '746', '742', '736'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Limit, Continuity and Differentiability',
        subTopic: 'Differentiation',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Logarithmic Differentiation', 'Higher Order Derivatives'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0444',
        questionText: 'The function f(x) = 2x + 3x²/³, x ∈ R, has',
        options: [
          'exactly one point of local minima and no point of local maxima',
          'exactly one point of local maxima and no point of local minima',
          'exactly one point of local maxima and exactly one point of local minima',
          'exactly two points of local maxima and exactly one point of local minima'
        ],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Differential Equations',
        subTopic: 'Maxima and Minima',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Local Maxima', 'Local Minima'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0445',
        questionText: 'The function f(x) = x/(x²−6x−16), x ∈ R−{−2,8}',
        options: [
          'decreases in (−2,8) and increases in (−∞,−2)∪(8,∞)',
          'decreases in (−∞,−2)∪(−2,8)∪(8,∞)',
          'decreases in (−∞,−2) and increases in (−2,8)',
          'increases in (−∞,−2)∪(−2,8)∪(8,∞)'
        ],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Integral Calculus',
        subTopic: 'Monotonic Functions',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Increasing/Decreasing Functions'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0446',
        questionText:
            'If ∫(sin²x+cos²x)/√(sin³xcos³xsin(x−θ)) dx = A√(cosθtanx−sinθ) + B√(cosθ−sinθcotx) + C, where C is the integration constant, then AB is equal to',
        options: ['4cosecθ', '4secθ', '2secθ', '8cosecθ'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Vector Algebra',
        subTopic: 'Integration',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Integration', 'Trigonometric Functions'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0447',
        questionText:
            'If sin(y) = logₑx + α is the solution of the differential equation xcos(y)dy/dx = ycos(y) + x and when x = e², y = π/3, then α² is equal to',
        options: ['3', '12', '4', '9'],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Three Dimensional Geometry',
        subTopic: 'Differential Equations',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Differential Equations', 'Trigonometric Functions'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0448',
        questionText:
            'Let OA = a, OB = 12a+4b and OC = b, where O is the origin. If S is the parallelogram with adjacent sides OA and OC, then area of the quadrilateral OABC is equal to _____ area of S',
        options: ['6', '10', '7', '8'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Three Dimensional Geometry',
        subTopic: 'Area Calculation',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Vectors', 'Area of Parallelogram'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0449',
        questionText:
            'Let a unit vector u = xî + yĵ + zk̂ make angles π/2, π/3 and 2π/3 with the vectors (1/√2)î + (1/√2)k̂, (1/√2)ĵ + (1/√2)k̂ and (1/√2)î + (1/√2)ĵ respectively. If v = (1/√2)î + (1/√2)ĵ + (1/√2)k̂, then |u−v|² is equal to',
        options: ['11/2', '5/2', '9/2', '7/2'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Statistics and Probability',
        subTopic: 'Vectors',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Unit Vectors', 'Vector Magnitude'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0450',
        questionText:
            'Let P(3,2,3), Q(4,6,2) and R(7,3,2) be the vertices of ΔPQR. Then, the angle ∠QPR is',
        options: ['π/6', 'cos⁻¹(7/18)', 'cos⁻¹(1/18)', 'π/3'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Complex Numbers and Quadratic Equations',
        subTopic: '3D Geometry',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['3D Geometry', 'Angle between Vectors'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0451',
        questionText:
            'An integer is chosen at random from the integers 1, 2, 3, ....., 50. The probability that the chosen integer is a multiple of at least one of 4, 6 and 7 is',
        options: ['8/25', '21/50', '9/50', '14/25'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Complex Numbers and Quadratic Equations',
        subTopic: 'Probability',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Probability', 'Multiples'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0452',
        questionText:
            'Let the set C = {(x,y) ∣ x² − 2y = 2023, x,y ∈ N}. Then ∑(x+y) over (x,y)∈C is equal to _______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Binomial Theorem and Its Simple Applications',
        subTopic: 'Set Theory',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Set Theory', 'Summation'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0453',
        questionText:
            'Let α,β be the roots of the equation x² − √6x + 3 = 0 such that Im(α) > Im(β). Let a, b be integers not divisible by 3 and n be a natural number such that α⁹⁹ + α⁹⁸/β = 3ⁿ(a+ib), i = √−1. Then n+a+b is equal to ___________.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: 'Complex Numbers',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Complex Numbers', 'Roots of Equations'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0454',
        questionText:
            'Remainder when 64³²³² is divided by 9 is equal to _____.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Limit, Continuity and Differentiability',
        subTopic: 'Number Theory',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Remainder Theorem', 'Modular Arithmetic'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0455',
        questionText:
            'Let P(α,β) be a point on the parabola y² = 4x. If P also lies on the chord of the parabola x² = 8y whose mid point is (1, 5/4), then (α−28)(β−8) is equal to _______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: 'Parabola',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Parabola', 'Chord Properties'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0456',
        questionText:
            'Let the slope of the line 45x+5y+3 = 0 be 27r₁ + 9/2 r₂ for some r₁, r₂ ∈ R. Then lim(x→3) (∫₃ˣ 8t² dt)/(2x³−r₂x²−r₁x³−3x) is equal to ______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: 'Limits and Integration',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Slope', 'Limits', 'Integration'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0457',
        questionText:
            'Let for any three distinct consecutive terms a, b, c of an A.P, the lines ax+by+c = 0 be concurrent at the point P and Q(α,β) be a point such that the system of equations x+y+z = 6, 2x+5y+αz = β and x+2y+3z = 4, has infinitely many solutions. Then (PQ)² is equal to _______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: 'Concurrent Lines',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Arithmetic Progression', 'Concurrent Lines'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0458',
        questionText:
            'Let f(x) = √lim(r→x) {2r²[(f(r))²−f(x)f(r)] − r³e^(f(r)/r)} be differentiable in (−∞,0)∪(0,∞) and f(1) = 1. Then the value of ae, such that f(a) = 0, is equal to ______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: 'Limits and Differentiation',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Differentiability', 'Limits'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0459',
        questionText:
            'If ∫(π/6 to π/3) √(1−sin2x) dx = α+β√2+γ√3, where α,β and γ are rational numbers, then 3α+4β−γ is equal to _____.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Trigonometry',
        subTopic: 'Integration',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Integration', 'Trigonometric Functions'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0460',
        questionText:
            'Let the area of the region {(x,y) : 0 ≤ x ≤ 3, 0 ≤ y ≤ min{x²+2, 2x+2}} be A. Then 12A is equal to ______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Integral Calculus',
        subTopic: 'Area Calculation',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Area under Curves', 'Minimum Function'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0461',
        questionText:
            'Let O be the origin, and M and N be the points on the lines (x−5)/4 = (y−4)/1 = (z−5)/3 and (x+8)/12 = (y+2)/5 = (z+11)/9 respectively such that MN is the shortest distance between the given lines. Then OM ⋅ ON is equal to _________.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: '3D Geometry',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['3D Geometry', 'Shortest Distance'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0464',
        questionText:
            'The resistance R = V/I, where V = (200±5) V and I = (20±0.2) A, the percentage error in the measurement of R is :',
        options: ['3.5%', '7%', '3%', '5.5%'],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Work, Energy and Power',
        subTopic: 'Error Analysis',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Error Analysis', 'Resistance'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0465',
        questionText:
            'A body starts moving from rest with constant acceleration covers displacement S₁ in first (p−1) seconds and S₂ in first p seconds. The displacement S₁ + S₂ will be made in time :',
        options: [
          '(2p−1) seconds',
          '√(2p²−2p+1) seconds',
          '(2p+1) seconds',
          '√(2p²+2p+1) seconds'
        ],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Work, Energy and Power',
        subTopic: 'Kinematics',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Kinematics', 'Constant Acceleration'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0466',
        questionText:
            'If the radius of curvature of the path of two particles of same mass are in the ratio 3 : 4, then in order to have constant centripetal force, their velocities will be in the ratio of:',
        options: ['√3 : 2', '1 : √3', '√3 : 1', '2 : √3'],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Gravitation',
        subTopic: 'Circular Motion',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Centripetal Force', 'Circular Motion'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0467',
        questionText:
            'A block of mass 100 kg slides over a distance of 10 m on a horizontal surface. If the co-efficient of friction between the surfaces is 0.4, then the work done against friction (in J) is:',
        options: ['4200', '3900', '4000', '4500'],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Properties of Solids and Liquids',
        subTopic: 'Friction',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Friction', 'Work Done'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0468',
        questionText:
            'The potential energy function (in J) of a particle in a region of space is given as U = (2x² + 3y³ + 2z). Here x, y and z are in meter. The magnitude of x - component of force (in N) acting on the particle at point P(1, 2, 3) m is:',
        options: ['2', '6', '4', '8'],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Thermodynamics',
        subTopic: 'Potential Energy',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Potential Energy', 'Force Components'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0469',
        questionText:
            'At what distance above and below the surface of the earth a body will have same weight? (Take radius of earth as R)',
        options: ['(√5R−R)/2', '(√3R−R)/2', 'R/2', '(√5R−R)/2'],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Kinetic Theory of Gases',
        subTopic: 'Gravitation',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Gravitation', 'Weight'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0470',
        questionText:
            'Given below are two statements: Statement I : If a capillary tube is immersed first in cold water and then in hot water, the height of capillary rise will be smaller in hot water. Statement II : If a capillary tube is immersed first in cold water and then in hot water, the height of capillary rise will be smaller in cold water. In the light of the above statements, choose the most appropriate from the options given below',
        options: [
          'Both Statement I and Statement II are true',
          'Both Statement I and Statement II are false',
          'Statement I is true but Statement II is false',
          'Statement I is false but Statement II is true'
        ],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Electrostatics',
        subTopic: 'Capillarity',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Capillarity', 'Surface Tension'],
        questionType: 'multipleChoice',
      ),
      Question(
        id: 'PHY0471',
        questionText:
            'A thermodynamic system is taken from an original state A to an intermediate state B by a linear process as shown in the figure. Its volume is then reduced to the original value from B to C by an isobaric process. The total work done by the gas from A to B and B to C would be:',
        options: ['33800 J', '2200 J', '600 J', '800 J'],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Thermodynamics',
        subTopic: 'Work Done in Thermodynamic Processes',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Thermodynamic Processes', 'Work Done'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0472',
        questionText:
            'Two vessels A and B are of the same size and are at same temperature. A contains 1 g of hydrogen and B contains 1 g of oxygen. Pₐ and Pբ are the pressures of the gases in A and B respectively, then Pₐ/Pբ is:',
        options: ['16', '8', '4', '32'],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Kinetic Theory of Gases',
        subTopic: 'Ideal Gas Law',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Ideal Gas Law', 'Molar Mass'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0473',
        questionText:
            'Two charges of 5Q and −2Q are situated at the points (3a, 0) and (−5a, 0) respectively. The electric flux through a sphere of radius 4a having centre at origin is:',
        options: ['2Q/ε₀', '5Q/ε₀', '7Q/ε₀', '3Q/ε₀'],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Electrostatics',
        subTopic: "Gauss's Law",
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ["Gauss's Law", 'Electric Flux'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0474',
        questionText:
            'Match List I with List II Choose the correct answer from the options given below',
        options: [
          'A-IV, B-I, C-III, D-II',
          'A-II, B-III, C-I, D-IV',
          'A-IV, B-III, C-I, D-II',
          'A-I, B-II, C-III, D-IV'
        ],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Electromagnetic Induction and Alternating Currents',
        subTopic: '',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Matching', 'Electromagnetic Concepts'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0475',
        questionText:
            'A capacitor of capacitance 100 μF is charged to a potential of 12 V and connected to a 6.4 mH inductor to produce oscillations. The maximum current in the circuit would be:',
        options: ['3.2 A', '1.5 A', '2.0 A', '1.2 A'],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Electromagnetic Induction and Alternating Currents',
        subTopic: 'LC Oscillations',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['LC Oscillations', 'Energy Conservation'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0476',
        questionText:
            'The electric current through a wire varies with time as I = I₀ + βt, where I₀ = 20 A and β = 3 A s⁻¹. The amount of electric charge crossed through a section of the wire in 20 s is:',
        options: ['80 C', '1000 C', '800 C', '1600 C'],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Current Electricity',
        subTopic: 'Electric Charge',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Electric Current', 'Integration'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0477',
        questionText:
            'A galvanometer having coil resistance 10 Ω shows a full scale deflection for a current of 3 mA. For it to measure a current of 8 A, the value of the shunt should be:',
        options: ['3×10⁻³ Ω', '4.85×10⁻³ Ω', '3.75×10⁻³ Ω', '2.75×10⁻³ Ω'],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Current Electricity',
        subTopic: 'Galvanometer Shunt',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Galvanometer', 'Shunt Resistance'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0478',
        questionText:
            'The deflection in moving coil galvanometer falls from 25 divisions to 5 division when a shunt of 24 Ω is applied. The resistance of galvanometer coil will be:',
        options: ['12 Ω', '96 Ω', '48 Ω', '100 Ω'],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Current Electricity',
        subTopic: 'Galvanometer',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Galvanometer', 'Shunt'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0479',
        questionText:
            'A convex mirror of radius of curvature 30 cm forms an image that is half the size of the object. The object distance is:',
        options: ['−45 cm', '45 cm', '−15 cm', '15 cm'],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Optics',
        subTopic: 'Mirrors',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Convex Mirror', 'Magnification'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0480',
        questionText:
            'A biconvex lens of refractive index 1.5 has a focal length of 20 cm in air. Its focal length when immersed in a liquid of refractive index 1.6 will be:',
        options: ['−16 cm', '−160 cm', '+160 cm', '+16 cm'],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Optics',
        subTopic: 'Lens Maker Formula',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Lens Maker Formula', 'Refractive Index'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0481',
        questionText:
            'The de-Broglie wavelength of an electron is the same as that of a photon. If velocity of electron is 25% of the velocity of light, then the ratio of K.E. of electron and K.E. of photon will be:',
        options: ['1/8', '1', '8', '1/4'],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Dual Nature of Matter and Radiation',
        subTopic: 'de-Broglie Wavelength',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['de-Broglie Wavelength', 'Kinetic Energy'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0482',
        questionText:
            'The explosive in a Hydrogen bomb is a mixture of H₂, H₃ and Li⁶ in some condensed form. The chain reaction is given by: Li⁶ + n¹ → He⁴ + H³; H² + H³ → He⁴ + n¹. During the explosion the energy released is approximately [Given: M(Li) = 6.01690 amu, M(H²) = 2.01471 amu, M(He⁴) = 4.00388 amu and 1 amu = 931.5 MeV]',
        options: ['28.12 MeV', '12.64 MeV', '16.48 MeV', '22.22 MeV'],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Atoms and Nuclei',
        subTopic: 'Nuclear Reactions',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Nuclear Reactions', 'Mass Defect'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0483',
        questionText:
            'In the given circuit, the breakdown voltage of the Zener diode is 3.0 V. What is the value of I_z?',
        options: ['3.3 mA', '5.5 mA', '10 mA', '7 mA'],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Electronic Devices',
        subTopic: 'Zener Diode',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Zener Diode', 'Circuit Analysis'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0484',
        questionText:
            'A ball rolls off the top of a stairway with horizontal velocity u. The steps are 0.1 m high and 0.1 m wide. The minimum velocity u with which that ball just hits the step 5 of the stairway will be √x m s⁻¹, where x = _______ [use g = 10 m s⁻²].',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Kinematics',
        subTopic: 'Projectile Motion',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Projectile Motion', 'Staircase Problem'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0485',
        questionText:
            'A cylinder is rolling down on an inclined plane of inclination 60°. Its acceleration during rolling down will be x/√3 m s⁻², where x = _______ [use g = 10 m s⁻²].',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Rotational Motion',
        subTopic: 'Rolling Motion',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Rolling Motion', 'Inclined Plane'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0486',
        questionText:
            'In a test experiment on a model aeroplane in wind tunnel, the flow speeds on the upper and lower surfaces of the wings are 70 m s⁻¹ and 65 m s⁻¹ respectively. If the wing area is 2 m², the lift of the wing is _______ N. (Given density of air = 1.2 kg m⁻³)',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Properties of Solids and Liquids',
        subTopic: 'Bernoulli Principle',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ["Bernoulli's Principle", 'Lift Force'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0487',
        questionText:
            'When the displacement of a simple harmonic oscillator is one third of its amplitude, the ratio of total energy to the kinetic energy is x/8, where x = _________.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Oscillations and Waves',
        subTopic: 'Simple Harmonic Motion',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Simple Harmonic Motion', 'Energy in SHM'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0488',
        questionText:
            'An electron is moving under the influence of the electric field of a uniformly charged infinite plane sheet S having surface charge density +σ. The electron at t = 0 is at a distance of 1 m from S and has a speed of 1 m s⁻¹. The maximum value of σ, if the electron strikes S at t = 1 s is α[mε₀/e] C/m². The value of α is _____.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Electrostatics',
        subTopic: 'Electric Field',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Electric Field', 'Charged Sheet'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0489',
        questionText:
            'A 16 Ω wire is bend to form a square loop. A 9 V battery with internal resistance 1 Ω is connected across one of its sides. If a 4 μF capacitor is connected across one of its diagonals, the energy stored by the capacitor will be x/2 μJ, where x = ______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Current Electricity',
        subTopic: 'RC Circuit',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['RC Circuit', 'Energy in Capacitor'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0490',
        questionText:
            'The magnetic potential due to a magnetic dipole at a point on its axis situated at a distance of 20 cm from its center is 1.5×10⁻⁵ T m. The magnetic moment of the dipole is _______ A m². (Given: μ₀/4π = 10⁻⁷ T m A⁻¹)',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Magnetic Effects of Current and Magnetism',
        subTopic: 'Magnetic Dipole',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Magnetic Dipole', 'Magnetic Potential'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0491',
        questionText:
            'A square loop of side 10 cm and resistance 0.7 Ω is placed vertically in the east-west plane. A uniform magnetic field of 0.20 T is set up across the plane in the north-east direction. The magnetic field is decreased to zero in 1 s at a steady rate. Then, the magnitude of induced emf is √x × 10⁻³ V. The value of x is _______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Electromagnetic Induction',
        subTopic: "Faraday's Law",
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ["Faraday's Law", 'Induced EMF'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0492',
        questionText:
            'In a double slit experiment shown in figure, when light of wavelength 400 nm is used, dark fringe is observed at P. If D = 0.2 m, the minimum distance between the slits S₁ and S₂ is α mm. Write the value of 10α to the nearest integer.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Wave Optics',
        subTopic: 'Double Slit Experiment',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Double Slit Experiment', 'Interference'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0493',
        questionText:
            'When a hydrogen atom going from n = 2 to n = 1 emits a photon, its recoil speed is x/5 m s⁻¹. Where x = _______. (Use: mass of hydrogen atom = 1.6×10⁻²⁷ kg, charge of electron e = 1.6×10⁻¹⁹ C)',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Atoms and Nuclei',
        subTopic: 'Photon Emission',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Photon Emission', 'Recoil Speed'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0494',
        questionText:
            'The correct set of four quantum numbers for the valence electron of rubidium atom (Z = 37) is:',
        options: ['5,0,0,+1/2', '5,0,1,+1/2', '5,1,0,+1/2', '5,1,1,+1/2'],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Atoms and Nuclei',
        subTopic: 'Quantum Numbers',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Quantum Numbers', 'Electronic Configuration'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0464',
        questionText:
            'Given below are two statements: one is labelled as Assertion A and the other is labelled as Reason R: Assertion A: The first ionisation enthalpy decreases across a period. Reason R: The increasing nuclear charge outweighs the shielding across the period. In the light of the above statements, choose the most appropriate from the options given below:',
        options: [
          'Both A and R are true and R is the correct explanation of A',
          'A is true but R is false',
          'A is false but R is true',
          'Both A and R are true but R is NOT the correct explanation of A'
        ],
        correctAnswerIndex: 2,
        subject: 'Chemistry',
        topic: 'Classification of Elements and Periodicity in Properties',
        subTopic: 'Ionization Enthalpy',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Ionization Enthalpy', 'Periodic Trends'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0465',
        questionText: 'Which of the following is not correct?',
        options: [
          'ΔG is negative for a spontaneous reaction',
          'ΔG is positive for a spontaneous reaction',
          'ΔG is zero for a reversible reaction',
          'ΔG is positive for a non-spontaneous reaction'
        ],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'Chemical Thermodynamics',
        subTopic: 'Gibbs Free Energy',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Gibbs Free Energy', 'Spontaneity'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0466',
        questionText:
            'Chlorine undergoes disproportionation in alkaline medium as shown below: aCl₂(g) + bOH⁻(aq) → cClO⁻(aq) + dCl⁻(aq) + eH₂O(l). The values of a, b, c and d in a balanced redox reaction are respectively:',
        options: [
          '1, 2, 1 and 1',
          '2, 2, 1 and 3',
          '3, 4, 4 and 2',
          '2, 4, 1 and 3'
        ],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Redox Reactions and Electrochemistry',
        subTopic: 'Disproportionation',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Disproportionation', 'Redox Balancing'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0467',
        questionText:
            'KMnO₄ decomposes on heating at 513 K to form O₂ along with',
        options: ['MnO₂ & K₂O₂', 'K₂MnO₄ & Mn', 'Mn & KO₂', 'K₂MnO₄ & MnO₂'],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'The d- and f-Block Elements',
        subTopic: 'Potassium Permanganate',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Potassium Permanganate', 'Decomposition'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0468',
        questionText:
            'Given below are two statements: Statement I: The electronegativity of group 14 elements from Si to Pb gradually decreases. Statement II: Group 14 contains non-metallic, metallic, as well as metalloid elements. In the light of the above statements, choose the most appropriate from the options given below:',
        options: [
          'Statement I is false but Statement II is true',
          'Statement I is true but Statement II is false',
          'Both Statement I and Statement II are true',
          'Both Statement I and Statement II are false'
        ],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Classification of Elements and Periodicity in Properties',
        subTopic: 'Electronegativity',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Electronegativity', 'Group 14 Elements'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0469',
        questionText:
            'The interaction between π bond and lone pair of electrons present on an adjacent atom is responsible for',
        options: [
          'Hyperconjugation',
          'Inductive effect',
          'Electromeric effect',
          'Resonance effect'
        ],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Organic Chemistry - Some Basic Principles and Techniques',
        subTopic: 'Resonance',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Resonance', 'π Bonds'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0470',
        questionText:
            'The difference in energy between the actual structure and the lowest energy resonance structure for the given compound is:',
        options: [
          'electromeric energy',
          'resonance energy',
          'ionization energy',
          'hyperconjugation energy'
        ],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'Organic Chemistry - Some Basic Principles and Techniques',
        subTopic: 'Resonance Energy',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Resonance Energy', 'Stability'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0471',
        questionText:
            'Appearance of blood red colour, on treatment of the sodium fusion extract of an organic compound with FeSO₄ in presence of concentrated H₂SO₄ indicates the presence of element/s',
        options: ['Br', 'N', 'N and S', 'S'],
        correctAnswerIndex: 2,
        subject: 'Chemistry',
        topic: 'Organic Chemistry - Some Basic Principles and Techniques',
        subTopic: 'Qualitative Analysis',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Qualitative Analysis', 'Sodium Fusion Test'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0472',
        questionText: 'Identify product A and product B',
        options: ['Option 1', 'Option 2', 'Option 3', 'Option 4'],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Organic Chemistry - Some Basic Principles and Techniques',
        subTopic: 'Reaction Products',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Reaction Mechanism', 'Product Identification'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0473',
        questionText: 'The major product(P) in the following reaction is',
        options: ['Option 1', 'Option 2', 'Option 3', 'Option 4'],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Organic Chemistry - Some Basic Principles and Techniques',
        subTopic: 'Major Product',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Reaction Mechanism', 'Major Product'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0474',
        questionText:
            'The arenium ion which is not involved in the bromination of Aniline is',
        options: ['Option 1', 'Option 2', 'Option 3', 'Option 4'],
        correctAnswerIndex: 2,
        subject: 'Chemistry',
        topic: 'Organic Chemistry - Some Basic Principles and Techniques',
        subTopic: 'Arenium Ion',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Arenium Ion', 'Electrophilic Substitution'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0475',
        questionText:
            'The final product A formed in the following multistep reaction sequence is',
        options: ['Option 1', 'Option 2', 'Option 3', 'Option 4'],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Organic Chemistry - Some Basic Principles and Techniques',
        subTopic: 'Multistep Synthesis',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Multistep Synthesis', 'Reaction Sequence'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0476',
        questionText: 'Identify the incorrect pair from the following:',
        options: [
          'Fluorspar - BF₃',
          'Cryolite - Na₃AlF₆',
          'Fluoroapatite - 3Ca₃(PO₄)₂·CaF₂',
          'Carnallite - KCl·MgCl₂·6H₂O'
        ],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'General Principles and Processes of Isolation of Elements',
        subTopic: 'Minerals and Ores',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Minerals', 'Ores'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0477',
        questionText:
            'In chromyl chloride test for confirmation of Cl⁻ ion, a yellow solution is obtained. Acidification of the solution and addition of amyl alcohol and 10% H₂O₂ turns organic layer blue indicating formation of chromium pentoxide. The oxidation state of chromium in that is',
        options: ['+6', '+5', '+10', '+3'],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'The d- and f-Block Elements',
        subTopic: 'Chromyl Chloride Test',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Chromyl Chloride Test', 'Oxidation State'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0478',
        questionText: 'In alkaline medium, MnO₄⁻ oxidises I⁻ to',
        options: ['IO⁻', 'IO₄⁻', 'I₂', 'IO₃⁻'],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Redox Reactions and Electrochemistry',
        subTopic: 'Redox Reactions',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Redox Reactions', 'Permanganate'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0479',
        questionText:
            'In which one of the following metal carbonyls, CO forms a bridge between metal atoms?',
        options: ['[Co₂(CO)₈]', '[Mn₂(CO)₁₀]', '[Os₃(CO)₁₂]', '[Ru₃(CO)₁₂]'],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Coordination Compounds',
        subTopic: 'Metal Carbonyls',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Metal Carbonyls', 'Bridging CO'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0480',
        questionText:
            'Given below are two statements: one is labelled as Assertion A and the other is labelled as Reason R: Assertion A: Aryl halides cannot be prepared by replacement of hydroxyl group of phenol by halogen atom. Reason R: Phenols react with halogen acids violently. In the light of the above statements, choose the most appropriate from the options given below:',
        options: [
          'Both A and R are true but R is NOT the correct explanation of A',
          'A is false but R is true',
          'A is true but R is false',
          'Both A and R are true and R is the correct explanation of A'
        ],
        correctAnswerIndex: 2,
        subject: 'Chemistry',
        topic: 'Haloalkanes and Haloarenes',
        subTopic: 'Preparation Methods',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Aryl Halides', 'Phenols'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0481',
        questionText:
            'Type of amino acids obtained by hydrolysis of proteins is:',
        options: ['β', 'α', 'δ', 'γ'],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'Biomolecules',
        subTopic: 'Amino Acids',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Amino Acids', 'Protein Hydrolysis'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0482',
        questionText:
            'Match List I with List II. List I (Substances) List II (Element Present) A. Ziegler catalyst I. Rhodium B. Blood Pigment II. Cobalt C. Wilkinson catalyst III. Iron D. Vitamin B₁₂ IV. Titanium Choose the correct answer from the options given below:',
        options: [
          'A-II, B-IV, C-I, D-III',
          'A-II, B-III, C-IV, D-I',
          'A-III, B-II, C-IV, D-I',
          'A-IV, B-III, C-I, D-II'
        ],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Coordination Compounds',
        subTopic: 'Catalysts and Complexes',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Catalysts', 'Coordination Compounds'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0483',
        questionText:
            'Number of compounds with one lone pair of electrons on central atom amongst following is _ O₃, H₂O, SF₄, ClF₃, NH₃, BrF₅, XeF₄',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Chemical Bonding and Molecular Structure',
        subTopic: 'Lone Pairs',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Lone Pairs', 'Molecular Structure'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0484',
        questionText:
            'The number of species from the following which are paramagnetic and with bond order equal to one is H₂, He₂⁺, O₂⁺, N₂⁻, O₂⁻, F₂, Ne₂⁺, B₂',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Chemical Bonding and Molecular Structure',
        subTopic: 'Paramagnetism',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Paramagnetism', 'Bond Order'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0485',
        questionText:
            'For the reaction N₂O₄(g) ⇌ 2NO₂(g), K_p = 0.492 atm at 300 K. K_c for the reaction at same temperature is ______ × 10⁻². (Given: R = 0.082 L atm mol⁻¹ K⁻¹)',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Equilibrium',
        subTopic: 'Equilibrium Constants',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Equilibrium Constants', 'K_p and K_c'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0486',
        questionText:
            'Number of compounds among the following which contain sulphur as heteroatom is ____. Furan, Thiophene, Pyridine, Pyrrole, Cysteine, Tyrosine',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Organic Chemistry - Some Basic Principles and Techniques',
        subTopic: 'Heteroatoms',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Heteroatoms', 'Organic Compounds'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0487',
        questionText:
            'Consider the given reaction. The total number of oxygen atoms present per molecule of the product (P) is _________.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Organic Chemistry - Some Basic Principles and Techniques',
        subTopic: 'Molecular Formula',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Molecular Formula', 'Oxygen Atoms'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0488',
        questionText:
            'A solution of H₂SO₄ is 31.4% H₂SO₄ by mass and has a density of 1.25 g/mL. The molarity of the H₂SO₄ solution is M (nearest integer) [Given molar mass of H₂SO₄ = 98 g mol⁻¹]',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Solutions',
        subTopic: 'Molarity',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Molarity', 'Concentration'],
        questionType: 'numerical',
      ),
      Question(
        id: 'CHEM0489',
        questionText:
            'The osmotic pressure of a dilute solution is 7×10⁵ Pa at 273 K. Osmotic pressure of the same solution at 283 K is _______×10⁴ Nm⁻². (Nearest integer)',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Solutions',
        subTopic: 'Osmotic Pressure',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Osmotic Pressure', 'Temperature Dependence'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0490',
        questionText:
            'The mass of zinc produced by the electrolysis of zinc sulphate solution with a steady current of 0.015 A for 15 minutes is ______×10⁻⁴ g. (Atomic mass of zinc = 65.4 amu)',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Redox Reactions and Electrochemistry',
        subTopic: 'Electrolysis',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Electrolysis', "Faraday's Law"],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0491',
        questionText:
            'For a reaction taking place in three steps at same temperature, overall rate constant K = K₁K₂/K₃. If Ea₁, Ea₂ and Ea₃ are 40, 50 and 60 kJ/mol respectively, the overall Ea is _________ kJ/mol.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Chemical Kinetics',
        subTopic: 'Activation Energy',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Activation Energy', 'Rate Constant'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0492',
        questionText:
            'From the compounds given below, number of compounds which give positive Fehling\'s test is: Benzaldehyde, Acetaldehyde, Acetone, Acetophenone, Methanal, 4-nitrobenzaldehyde, cyclohexane carbaldehyde.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Organic Compounds Containing Oxygen',
        subTopic: 'Fehling\'s Test',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Fehling\'s Test', 'Aldehydes'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0462',
        questionText:
            'If z = 1 - 2i, is such that z + 1 = αz + β(1 + i), i = √−1 and α,β ∈ R, then α + β is equal to',
        options: ['-4', '3', '2', '-1'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Complex Numbers and Quadratic Equations',
        subTopic: 'Complex Numbers',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Complex Numbers', 'Linear Equations'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0463',
        questionText:
            'In an A.P., the sixth term a₆ = 2. If the a₁a₄a₅ is the greatest, then the common difference of the A.P., is equal to',
        options: ['3/8', '2/5', '2/3', '5/8'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Sequence and Series',
        subTopic: 'Arithmetic Progression',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Arithmetic Progression', 'Common Difference'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0464',
        questionText:
            'If in a G.P. of 64 terms, the sum of all the terms is 7 times the sum of the odd terms of the G.P, then the common ratio of the G.P. is equal to',
        options: ['7', '4', '5', '6'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Sequence and Series',
        subTopic: 'Geometric Progression',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Geometric Progression', 'Common Ratio'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0465',
        questionText:
            'If α, -π < α < π is the solution of 4cosθ + 5sinθ = 1, then the value of tanα is',
        options: ['(10-√10)/6', '(10-√10)/12', '(√10-10)/12', '(√10-10)/6'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Trigonometry',
        subTopic: 'Trigonometric Equations',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Trigonometric Equations', 'Tangent'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0466',
        questionText:
            'Let (5, a) be the circumcenter of a triangle with vertices A(a, -2), B(a, 6) and C(a/4, -2). Let α denote the circumradius, β denote the area and γ denote the perimeter of the triangle. Then α + β + γ is',
        options: ['60', '53', '62', '30'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: 'Circumcenter',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Circumcenter', 'Triangle Properties'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0467',
        questionText:
            'In a ΔABC, suppose y = x is the equation of the bisector of the angle B and the equation of the side AC is 2x - y = 2. If 2AB = BC and the point A and B are respectively (4,6) and (α,β), then α + 2β is equal to',
        options: ['-4', '42', '2', '-1'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: 'Angle Bisector',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Angle Bisector', 'Coordinate Geometry'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0468',
        questionText:
            'lim(x→π/2) [1/(x-π/2)² ∫(π/2 to x³) cos(1/t³) dt] is equal to',
        options: ['3π/8', '3π²/4', '3π²/8', '3π/4'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Limit, Continuity and Differentiability',
        subTopic: 'Limits',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Limits', 'Integration'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0469',
        questionText:
            'Let R be a relation on Z×Z defined by (a, b)R(c, d) if and only if ad - bc is divisible by 5. Then R is',
        options: [
          'Reflexive and symmetric but not transitive',
          'Reflexive but neither symmetric nor transitive',
          'Reflexive, symmetric and transitive',
          'Reflexive and transitive but not symmetric'
        ],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Sets, Relations and Functions',
        subTopic: 'Relations',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Relations', 'Divisibility'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0470',
        questionText:
            'Let A = [[0, α], [β, 0]] and 2A³ = 221 where α,β ∈ Z. Then a value of α is',
        options: ['3', '5', '17', '9'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Matrices and Determinants',
        subTopic: 'Matrix Operations',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Matrix Operations', 'Matrix Equations'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0471',
        questionText:
            'Let A be a square matrix such that AAᵀ = I. Then ½A[(A + Aᵀ)² + (A - Aᵀ)²] is equal to',
        options: ['A² + I', 'A³ + I', 'A² + Aᵀ', 'A³ + Aᵀ'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Matrices and Determinants',
        subTopic: 'Matrix Algebra',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Matrix Algebra', 'Orthogonal Matrix'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0472',
        questionText:
            'If f(x) = {2 + 2x, -1 ≤ x < 0; 1 - x, 0 ≤ x ≤ 3} and g(x) = {-x, -3 ≤ x ≤ 0; x, 0 < x ≤ 1}, then range of (f ∘ g(x)) is',
        options: ['[0,3)', '[0,1]', '[0,1)'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Sets, Relations and Functions',
        subTopic: 'Function Composition',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Function Composition', 'Range'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0473',
        questionText:
            'Consider the function f: [-1,1] → R defined by f(x) = 4√2x³ - 3√2x - 1. Consider the statements (I) The curve y = f(x) intersects the x-axis exactly at one point (II) The curve y = f(x) intersects the x-axis at x = cos(π/12) Then',
        options: [
          'Only (II) is correct',
          'Both (I) and (II) are incorrect',
          'Only (I) is correct',
          'Both (I) and (II) are correct'
        ],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Trigonometry',
        subTopic: 'Trigonometric Functions',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Trigonometric Functions', 'Roots'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0474',
        questionText:
            'Suppose f(x) = (2ˣ + 2⁻ˣ)tanx√(tan⁻¹(x² - x + 1)). Then the value of f′(0) is equal to',
        options: ['π', '0', '√π', 'π/2'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Differential Equations',
        subTopic: 'Differentiation',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Differentiation', 'Inverse Trigonometric Functions'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0475',
        questionText:
            'If the value of the integral ∫(-π/2 to π/2) [(x²cosx)/(1+πˣ) + (1+sin²x)/(1+e^(sinx)²⁰²³)] dx = π(π + a)/4 - 2, then the value of a is',
        options: ['3', '-3/2', '2', '3/2'],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Integral Calculus',
        subTopic: 'Definite Integrals',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Definite Integrals', 'Even-Odd Functions'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0476',
        questionText:
            'For x ∈ (-π/2, π/2), if y(x) = ∫[(cosecx + sinx)/(cosecxsecx + tanxsin²x)] dx and lim(x→(π/4)⁻) y(x) = 0 then y(π/2) is equal to',
        options: [
          'tan⁻¹(1/√2)',
          '½tan⁻¹(1/√2)',
          '-½tan⁻¹(1/√2)',
          '½tan⁻¹(-1/√2)'
        ],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Integral Calculus',
        subTopic: 'Integration',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Integration', 'Trigonometric Functions'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0477',
        questionText:
            'A function y = f(x) satisfies f(x)sin2x + sinx - (1 + cos²x)f′(x) = 0 with condition f(0) = 0. Then f(π/2) is equal to',
        options: ['1', '0', '-1', '2'],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Differential Equations',
        subTopic: 'Differential Equations',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Differential Equations', 'Initial Conditions'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0478',
        questionText:
            'Let a, b and c be three non-zero vectors such that b and c are non-collinear if a + 5b is collinear with c, b + 6c is collinear with a and a + αb + βc = 0, then α + β is equal to',
        options: ['35', '30', '-30', '-25'],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Vector Algebra',
        subTopic: 'Vector Collinearity',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Vector Collinearity', 'Linear Dependence'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0479',
        questionText:
            'Let O be the origin and the position vector of A and B be 2î + 2ĵ + k̂ and 2î + 4ĵ + 4k̂ respectively. If the internal bisector of ∠AOB meets the line AB at C, then the length of OC is',
        options: ['2√31/3', '2√34/3', '3√34/4', '3√31/2'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Vector Algebra',
        subTopic: 'Angle Bisector',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Angle Bisector', 'Vector Geometry'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0480',
        questionText:
            'Let PQR be a triangle with R(-1,4,2). Suppose M(2,1,2) is the mid point of PQ. The distance of the centroid of ΔPQR from the point of intersection of the lines (x-2)/0 = y/2 = (z+3)/(-1) and (x-1)/1 = (y+3)/(-3) = (z+1)/1 is',
        options: ['69', '9', '√69', '√99'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Three Dimensional Geometry',
        subTopic: 'Centroid',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Centroid', 'Line Intersection'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0481',
        questionText:
            'A fair die is thrown until 2 appears. Then the probability, that 2 appears in even number of throws, is',
        options: ['5/6', '1/6', '5/11', '6/11'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Statistics and Probability',
        subTopic: 'Probability',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Probability', 'Geometric Distribution'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0482',
        questionText:
            'Let α,β be the roots of the equation x² - x + 2 = 0 with Im(α) > Im(β). Then α⁶ + α⁴ + β⁴ - 5α² is equal to',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Complex Numbers and Quadratic Equations',
        subTopic: 'Complex Roots',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Complex Roots', 'Polynomial Equations'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0483',
        questionText:
            'All the letters of the word GTWENTY are written in all possible ways with or without meaning and these words are written as in a dictionary. The serial number of the word GTWENTY is',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Permutations and Combinations',
        subTopic: 'Dictionary Order',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Dictionary Order', 'Permutations'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0484',
        questionText:
            'If ¹¹C₁/2 + ¹¹C₂/3 + ... + ¹¹C₉/10 = n/m with gcd(n,m) = 1, then n + m is equal to',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Binomial Theorem and Its Simple Applications',
        subTopic: 'Binomial Coefficients',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Binomial Coefficients', 'Summation'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0485',
        questionText:
            'Equations of two diameters of a circle are 2x - 3y = 5 and 3x - 4y = 7. The line joining the points (-22/7, -4) and (-1, 3/7) intersects the circle at only one point P(α,β). Then 17β - α is equal to',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: 'Circle',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Circle', 'Tangent'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0486',
        questionText:
            'If the points of intersection of two distinct conics x² + y² = 4b and x²/16 + y²/b² = 1 lie on the curve y² = 3x², then 3√3 times the area of the rectangle formed by the intersection points is _______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: 'Conic Sections',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Conic Sections', 'Intersection Points'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0487',
        questionText:
            'If the mean and variance of the data 65,68,58,44,48,45,60,α,β,60 where α > β are 56 and 66.2 respectively, then α² + β² is equal to',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Statistics and Probability',
        subTopic: 'Mean and Variance',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Mean', 'Variance'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0488',
        questionText:
            'Let f(x) = 2x - x², x ∈ R. If m and n are respectively the number of points at which the curves y = f(x) and y = f′(x) intersects the x-axis, then the value of m + n is',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Limit, Continuity and Differentiability',
        subTopic: 'Function Analysis',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Function Analysis', 'Derivative'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0489',
        questionText:
            'The area (in sq. units) of the part of circle x² + y² = 169 which is below the line 5x - y = 13 is (πα/2) - (65/2) + αsin⁻¹(12/13) where α,β are coprime numbers. Then α + β is equal to',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: 'Area Calculation',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Area Calculation', 'Circle'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0490',
        questionText:
            'If the solution curve y = y(x) of the differential equation (1 + y²)(1 + logₑx)dx + xdy = 0, x > 0 passes through the point (e², tan⁻¹3), then α - tan⁻¹3 is equal to',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Differential Equations',
        subTopic: 'Differential Equations',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Differential Equations', 'Solution Curve'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0491',
        questionText:
            'A line with direction ratio 2,1,2 meets the lines x = y + 2 = z and x + 2 = 2y = 2z respectively at the point P and Q. if the length of the perpendicular from the point (1,2,12) to the line PQ is l, then l² is',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Three Dimensional Geometry',
        subTopic: 'Distance from Line',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Distance from Line', '3D Geometry'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0495',
        questionText:
            'The equation of state of a real gas is given by (P + a/V²)(V - b) = RT, where P, V and T are pressure, volume and temperature respectively and R is the universal gas constant. The dimensions of a/b² is similar to that of:',
        options: ['PV', 'P', 'RT', 'R'],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Units and Measurements',
        subTopic: 'Dimensional Analysis',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Dimensional Analysis', 'Gas Laws'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0496',
        questionText:
            'A bullet is fired into a fixed target looses one third of its velocity after travelling 4 cm. It penetrates further D×10⁻³ m before coming to rest. The value of D is:',
        options: ['32', '5', '3', '4'],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Work, Energy and Power',
        subTopic: 'Kinematics',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Kinematics', 'Deceleration'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0497',
        questionText:
            'Given below are two statements: Statement (I): The limiting force of static friction depends on the area of contact and independent of materials. Statement (II): The limiting force of kinetic friction is independent of the area of contact and depends on materials. In the light of the above statements, choose the most appropriate answer from the options given below:',
        options: [
          'Statement I is correct but Statement II is incorrect',
          'Statement I is incorrect but Statement II is correct',
          'Both Statement I and Statement II are incorrect',
          'Both Statement I and Statement II are correct'
        ],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Laws of Motion',
        subTopic: 'Friction',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Friction', 'Static vs Kinetic'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0498',
        questionText:
            'A ball suspended by a thread swings in a vertical plane so that its magnitude of acceleration in the extreme position and lowest position are equal. The angle (θ) of thread deflection in the extreme position will be:',
        options: ['tan⁻¹√2', '2tan⁻¹(1/2)', 'tan⁻¹(1/√5)', '2tan⁻¹(1/2)'],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Oscillations and Waves',
        subTopic: 'Pendulum',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Pendulum', 'Acceleration'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0499',
        questionText:
            'A heavy iron bar of weight 12 kg is having its one end on the ground and the other on the shoulder of a man. The rod makes an angle 60° with the horizontal, the normal force applied by the man on bar is:',
        options: ['6 kg-wt', '12 kg-wt', '3 kg-wt', '6√3 kg-wt'],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Laws of Motion',
        subTopic: 'Torque',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Torque', 'Equilibrium'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0500',
        questionText:
            'Given below are two statements: one is labelled as Assertion (A) and the other is labelled as Reason (R). Assertion (A): The angular speed of the moon in its orbit about the earth is more than the angular speed of the earth in its orbit about the sun. Reason (R): The moon takes less time to move around the earth than the time taken by the earth to move around the sun. In the light of the above statements, choose the most appropriate answer from the options given below:',
        options: [
          '(A) is correct but (R) is not correct',
          'Both (A) and (R) are correct and (R) is the correct explanation of A.',
          'Both (A) and (R) are correct but (R) is not the correct explanation of A.',
          '(A) is not correct but (R) is correct'
        ],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Gravitation',
        subTopic: 'Angular Speed',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Angular Speed', 'Orbital Motion'],
        questionType: 'multipleChoice',
      ),
      Question(
        id: 'PHY0501',
        questionText:
            'Given below are two statements: one is labelled as Assertion (A) and the other is labelled as Reason (R). Assertion (A): The property of body, by virtue of which it tends to regain its original shape when the external force is removed, is Elasticity. Reason (R): The restoring force depends upon the bonded inter atomic and inter molecular force of solid. In the light of the above statements, choose the correct answer from the options given below:',
        options: [
          '(A) is false but (R) is true',
          '(A) is true but (R) is false',
          'Both (A) and (R) are true and (R) is the correct explanation of (A)',
          'Both (A) and (R) are true but (R) is not the correct explanation of (A)'
        ],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Properties of Solids and Liquids',
        subTopic: 'Elasticity',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Elasticity', 'Restoring Force'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0502',
        questionText:
            'During an adiabatic process, the pressure of a gas is found to be proportional to the cube of its absolute temperature. The ratio of Cₚ/Cᵥ for the gas is:',
        options: ['5/3', '3/2', '7/5', '9/7'],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Thermodynamics',
        subTopic: 'Adiabatic Process',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Adiabatic Process', 'Specific Heat Ratio'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0503',
        questionText:
            'The total kinetic energy of 1 mole of oxygen at 27°C is: [Use universal gas constant R = 8.31 J mol⁻¹ K⁻¹]',
        options: ['6845.5 J', '5942.0 J', '6232.5 J', '5670.5 J'],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Kinetic Theory of Gases',
        subTopic: 'Kinetic Energy',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Kinetic Energy', 'Ideal Gas'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0504',
        questionText:
            'Given below are two statements: one is labelled as Assertion (A) and the other is labelled as Reason (R). Assertion (A): Work done by electric field on moving a positive charge on an equipotential surface is always zero. Reason (R): Electric lines of forces are always perpendicular to equipotential surfaces. In the light of the above statements, choose the most appropriate answer from the options given below:',
        options: [
          'Both (A) and (R) are correct but (R) is not the correct explanation of (A)',
          '(A) is correct but (R) is not correct',
          '(A) is not correct but (R) is correct',
          'Both (A) and (R) are correct and (R) is the correct explanation of (A)'
        ],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Electrostatics',
        subTopic: 'Equipotential Surfaces',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Equipotential Surfaces', 'Work Done'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0505',
        questionText:
            'Wheatstone bridge principle is used to measure the specific resistance S of given wire, having length L, radius r. If X is the resistance of wire, then specific resistance is: S = X(πr²/L). If the length of the wire gets doubled then the value of specific resistance will be:',
        options: ['S', '2S', 'S/4', 'S/2'],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Current Electricity',
        subTopic: 'Specific Resistance',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Specific Resistance', 'Wheatstone Bridge'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0506',
        questionText:
            'A current of 200 μA deflects the coil of a moving coil galvanometer through 60°. The current to cause deflection through π/10 radian is',
        options: ['30 μA', '120 μA', '60 μA', '180 μA'],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Current Electricity',
        subTopic: 'Galvanometer',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Galvanometer', 'Deflection'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0507',
        questionText:
            'Three voltmeters, all having different internal resistances are joined as shown in figure. When some potential difference is applied across A and B, their readings are V₁, V₂ and V₃. Choose the correct option.',
        options: ['V₁ = V₂', 'V₁ ≠ V₃ - V₂', 'V₁ + V₂ > V₃', 'V₁ + V₂ = V₃'],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Current Electricity',
        subTopic: 'Voltmeter',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Voltmeter', 'Circuit Analysis'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0508',
        questionText:
            'The primary side of a transformer is connected to 230 V, 50 Hz supply. The turn ratio of primary to secondary winding is 10 : 1. Load resistance connected to the secondary side is 46 Ω. The power consumed in it is:',
        options: ['12.5 W', '10.0 W', '11.5 W', '12.0 W'],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Electromagnetic Induction and Alternating Currents',
        subTopic: 'Transformer',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Transformer', 'Power Calculation'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0509',
        questionText:
            'An object is placed in a medium of refractive index 3. An electromagnetic wave of intensity 6×10⁸ W m⁻² falls normally on the object and it is absorbed completely. The radiation pressure on the object would be (speed of light in free space = 3×10⁸ m s⁻¹):',
        options: ['36 N m⁻²', '18 N m⁻²', '6 N m⁻²', '2 N m⁻²'],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Optics',
        subTopic: 'Radiation Pressure',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Radiation Pressure', 'Electromagnetic Waves'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0510',
        questionText:
            'When a polaroid sheet is rotated between two crossed polaroids then the transmitted light intensity will be maximum for a rotation of:',
        options: ['60°', '30°', '90°', '45°'],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Wave Optics',
        subTopic: 'Polarization',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Polarization', 'Malus Law'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0511',
        questionText:
            'The threshold frequency of a metal with work function 6.63 eV is:',
        options: ['16×10¹⁵ Hz', '16×10¹² Hz', '1.6×10¹² Hz', '1.6×10¹⁵ Hz'],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Dual Nature of Matter and Radiation',
        subTopic: 'Photoelectric Effect',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Photoelectric Effect', 'Threshold Frequency'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0512',
        questionText:
            'The atomic mass of C¹² is 12.000000 u and that of C¹³ is 13.003354 u. The required energy to remove a neutron from C¹³, if mass of neutron is 1.008665 u, will be:',
        options: ['62.5 MeV', '6.25 MeV', '4.95 MeV', '49.5 MeV'],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Atoms and Nuclei',
        subTopic: 'Nuclear Binding Energy',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Nuclear Binding Energy', 'Mass Defect'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0513',
        questionText: 'The truth table of the given circuit diagram is:',
        options: [
          'A B Y\n0 0 1\n0 1 0\n1 0 0\n1 1 1',
          'A B Y\n0 0 0\n0 1 1\n1 0 1\n1 1 0',
          'A B Y\n0 0 0\n0 1 0\n1 0 0\n1 1 1',
          'A B Y\n0 0 1\n0 1 1\n1 0 1\n1 1 0'
        ],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Electronic Devices',
        subTopic: 'Logic Gates',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Logic Gates', 'Truth Table'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0514',
        questionText:
            'Given below are two statements: one is labelled as Assertion (A) and the other is labelled as Reason (R). Assertion (A): In Vernier calliper if positive zero error exists, then while taking measurements, the reading taken will be more than the actual reading. Reason (R): The zero error in Vernier Calliper might have happened due to manufacturing defect or due to rough handling. In the light of the above statements, choose the correct answer from the options given below:',
        options: [
          'Both (A) and (R) are correct and (R) is the correct explanation of (A)',
          'Both (A) and (R) are correct but (R) is not the correct explanation of (A)',
          '(A) is true but (R) is false',
          '(A) is false but (R) is true'
        ],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Units and Measurements',
        subTopic: 'Vernier Calliper',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Vernier Calliper', 'Zero Error'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0515',
        questionText:
            'A body falling under gravity covers two points A and B separated by 80 m in 2 s. The distance of upper point A from the starting point is _____ m. Use g = 10 m s⁻²',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Kinematics',
        subTopic: 'Free Fall',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Free Fall', 'Kinematics'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0516',
        questionText:
            'A ring and a solid sphere roll down the same inclined plane without slipping. They start from rest. The radii of both bodies are identical and the ratio of their kinetic energies is 7/x, where x is ______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Rotational Motion',
        subTopic: 'Rolling Motion',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Rolling Motion', 'Kinetic Energy'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0517',
        questionText:
            'The reading of pressure metre attached with a closed pipe is 4.5×10⁴ N m⁻². On opening the valve, water starts flowing and the reading of pressure metre falls to 2.0×10⁴ N m⁻². The velocity of water is found to be √V m s⁻¹. The value of V is _________.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Fluid Mechanics',
        subTopic: "Bernoulli's Principle",
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ["Bernoulli's Principle", 'Fluid Flow'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0518',
        questionText:
            'A closed organ pipe 150 cm long gives 7 beats per second with an open organ pipe of length 350 cm, both vibrating in fundamental mode. The velocity of sound is ______ m s⁻¹.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Waves',
        subTopic: 'Organ Pipes',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Organ Pipes', 'Beats'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0519',
        questionText:
            'The electric potential at the surface of an atomic nucleus (Z = 50) of radius 9×10⁻¹³ cm is α×10⁶ V. What is the value of α? (Charge of proton 1.6×10⁻¹⁹ C)',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Electrostatics',
        subTopic: 'Electric Potential',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Electric Potential', 'Nuclear Physics'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0520',
        questionText:
            'Two charges of -4 μC and +4 μC are placed at the points A(1, 0, 4) m and B(2, -1, 5) m located in an electric field E = 0.20î V cm⁻¹. The magnitude of the torque acting on the dipole is (8/√α) × 10⁻⁵ N m, where α = _________.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Electrostatics',
        subTopic: 'Torque on Dipole',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Electric Dipole', 'Torque'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0521',
        questionText:
            'The magnetic field at the centre of a wire loop formed by two semicircular wires of radii R₁ = 2π m and R₂ = 4π m carrying current I = 4 A as per figure given below is α×10⁻⁷ T. The value of α is _____. (Centre O is common for all segments)',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Magnetic Effects of Current and Magnetism',
        subTopic: 'Magnetic Field',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Magnetic Field', 'Circular Loop'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0522',
        questionText:
            'A series LCR circuit with L = (100/π) mH, C = (10⁻³/π) F and R = 10 Ω, is connected across an AC source of 220 V, 50 Hz supply. The power factor of the circuit would be ____.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Electromagnetic Induction and Alternating Currents',
        subTopic: 'LCR Circuit',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['LCR Circuit', 'Power Factor'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0523',
        questionText:
            'A parallel beam of monochromatic light of wavelength 5000 Å is incident normally on a single narrow slit of width 0.001 mm. The light is focused by convex lens on screen, placed on its focal plane. The first minima will be formed for the angle of diffraction of ______ (degree).',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Wave Optics',
        subTopic: 'Diffraction',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Diffraction', 'Single Slit'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0524',
        questionText:
            'If Rydberg\'s constant is R, the longest wavelength of radiation in Paschen series will be α/7R, where α = ______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Atoms and Nuclei',
        subTopic: 'Hydrogen Spectrum',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Hydrogen Spectrum', 'Paschen Series'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0493',
        questionText:
            'Which of the following cannot function as an oxidising agent?',
        options: ['N³⁻', 'SO₄²⁻', 'BrO₃⁻', 'MnO₄⁻'],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Redox Reactions and Electrochemistry',
        subTopic: 'Oxidizing Agents',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Oxidizing Agents', 'Redox Reactions'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0494',
        questionText:
            'The molecular formula of second homologue in the homologous series of mono carboxylic acids is _________.',
        options: ['C₃H₆O₂', 'C₂H₄O₂', 'CH₂O₂', 'C₂H₂O₂'],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'Organic Chemistry - Some Basic Principles and Techniques',
        subTopic: 'Homologous Series',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Homologous Series', 'Carboxylic Acids'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0495',
        questionText: 'Bond line formula of HOCH₂(CN) is:',
        options: ['Option 1', 'Option 2', 'Option 3', 'Option 4'],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Organic Chemistry - Some Basic Principles and Techniques',
        subTopic: 'Bond Line Formula',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Bond Line Formula', 'Structural Representation'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0496',
        questionText:
            'The order of relative stability of the contributing structure is: Choose the correct answer from the options given below:',
        options: [
          'I > II > III',
          'II > I > III',
          'I = II = III',
          'III > II > I'
        ],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Organic Chemistry - Some Basic Principles and Techniques',
        subTopic: 'Resonance Structures',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Resonance Structures', 'Stability'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0497',
        questionText:
            'The incorrect statement regarding conformations of ethane is:',
        options: [
          'Ethane has infinite number of conformations',
          'The dihedral angle in staggered conformation is 60°',
          'Eclipsed conformation is the most stable conformation',
          'The conformations of ethane are interconvertible to one-another'
        ],
        correctAnswerIndex: 2,
        subject: 'Chemistry',
        topic: 'Organic Chemistry - Some Basic Principles and Techniques',
        subTopic: 'Conformations',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Conformations', 'Ethane'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0498',
        questionText:
            'The technique used for purification of steam volatile water immiscible substance is:',
        options: [
          'Fractional distillation',
          'Fractional distillation under reduced pressure',
          'Distillation',
          'Steam distillation'
        ],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Organic Chemistry - Some Basic Principles and Techniques',
        subTopic: 'Purification Methods',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Purification Methods', 'Steam Distillation'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0499',
        questionText:
            'The final product A, formed in the following reaction sequence is:',
        options: [
          'Ph-CH₂-CH₂-CH₃',
          'Option 2',
          'Option 3',
          'Ph-CH₂-CH₂-CH₂-OH'
        ],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Organic Chemistry - Some Basic Principles and Techniques',
        subTopic: 'Reaction Products',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Reaction Sequence', 'Product Identification'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0500',
        questionText: 'The quantity which changes with temperature is:',
        options: ['Molarity', 'Mass percentage', 'Molality', 'Mole fraction'],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Solutions',
        subTopic: 'Concentration Terms',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Concentration Terms', 'Temperature Dependence'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0501',
        questionText:
            'Which of the following statements is not correct about rusting of iron?',
        options: [
          'Coating of iron surface by tin prevents rusting, even if the tin coating is peeling off.',
          'When pH lies above 9 or 10, rusting of iron does not take place.',
          'Dissolved acidic oxides SO₂, NO₂ in water act as catalyst in the process of rusting.',
          'Rusting of iron is envisaged as setting up of electrochemical cell on the surface of iron object.'
        ],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Electrochemistry',
        subTopic: 'Corrosion',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Corrosion', 'Rusting'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0502',
        questionText:
            'Given below are two statements: Statement (I): Oxygen being the first member of group 16 exhibits only –2 oxidation state. Statement (II): Down the group 16 stability of +4 oxidation state decreases and +6 oxidation state increases. In the light of the above statements, choose the most appropriate answer from the options given below:',
        options: [
          'Statement I is correct but Statement II is incorrect',
          'Both Statement I and Statement II are correct',
          'Both Statement I and Statement II are incorrect',
          'Statement I is incorrect but Statement II is correct'
        ],
        correctAnswerIndex: 2,
        subject: 'Chemistry',
        topic: 'p-Block Elements',
        subTopic: 'Group 16 Elements',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Group 16 Elements', 'Oxidation States'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0503',
        questionText:
            'Choose the correct option having all the elements with d¹⁰ electronic configuration from the following:',
        options: [
          '²⁷Co, ²⁸Ni, ²⁶Fe, ²⁴Cr',
          '²⁹Cu, ³⁰Zn, ⁴⁸Cd, ⁴⁷Ag',
          '⁴⁶Pd, ²⁸Ni, ²⁶Fe, ²⁴Cr',
          '²⁸Ni, ²⁴Cr, ²⁶Fe, ²⁹Cu'
        ],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'd- and f-Block Elements',
        subTopic: 'Electronic Configuration',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Electronic Configuration', 'd-block Elements'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0504',
        questionText:
            'Given below are two statements: Statement (I): In the Lanthanoids, the formation of Ce⁴⁺ is favoured by its noble gas configuration. Statement (II): Ce⁴⁺ is a strong oxidant reverting to the common +3 state. In the light of the above statements, choose the most appropriate answer from the options given below:',
        options: [
          'Statement I is false but Statement II is true',
          'Both Statement I and Statement II are true',
          'Statement I is true but Statement II is false',
          'Both Statement I and Statement II are false'
        ],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'd- and f-Block Elements',
        subTopic: 'Lanthanoids',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Lanthanoids', 'Cerium'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0505',
        questionText: 'Identify the incorrect pair from the following:',
        options: [
          'Photography - AgBr',
          'Polythene preparation - TiCl₄, Al(CH₃)₃',
          'Haber process - Iron',
          'Wacker process - PtCl₂'
        ],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'General Principles and Processes of Isolation of Elements',
        subTopic: 'Industrial Processes',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Industrial Processes', 'Catalysts'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0506',
        questionText:
            'Identify from the following species in which d²sp³ hybridization is shown by central atom:',
        options: ['[Co(NH₃)₆]³⁺', 'BrF₅', '[Pt(Cl)₆]²⁻', 'SF₄'],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Coordination Compounds',
        subTopic: 'Hybridization',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Hybridization', 'Coordination Compounds'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0507',
        questionText:
            'Which among the following halide/s will not show SN1 reaction:',
        options: ['H₂C=CH-CH₂Cl', 'CH₃-CH=CH-Cl', 'Option 3', 'Option 4'],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'Haloalkanes and Haloarenes',
        subTopic: 'SN1 Reaction',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['SN1 Reaction', 'Reactivity'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0508',
        questionText:
            'Identify B formed in the reaction: Cl-CH₂-CH₂-Cl + excess NH₃ → A + NaOH → B + H₂O + NaCl',
        options: [
          'Option 1',
          'H₂N-CH₂-CH₂-NH₂',
          '⁺H₃N-CH₂-CH₂-NH₃⁺ Cl⁻',
          'Option 4'
        ],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'Amines',
        subTopic: 'Reaction Products',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Amines', 'Reaction Mechanism'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0509',
        questionText: 'Phenolic group can be identified by a positive:',
        options: [
          'Phthalein dye test',
          'Lucas test',
          'Tollen\'s test',
          'Carbylamine test'
        ],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Alcohols, Phenols and Ethers',
        subTopic: 'Phenols Test',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Phenols', 'Identification Tests'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0510',
        questionText:
            'Match List-I with List-II. List I (Reaction) List II (Reagent(s)) (A) (I) Na₂Cr₂O₇/H₂SO₄ (B) (II) (i) NaOH (ii) CH₃Cl (C) (III) (i) NaOH, CHCl₃ (ii) H₃O⁺ (D) (IV) (i) NaOH (ii) CO₂ (iii) H₃O⁺ Choose the correct answer from the options given below:',
        options: [
          '(A)-(IV), (B)-(I), (C)-(III), (D)-(II)',
          '(A)-(II), (B)-(III), (C)-(I), (D)-(IV)',
          '(A)-(II), (B)-(I), (C)-(III), (D)-(IV)',
          '(A)-(IV), (B)-(III), (C)-(I), (D)-(II)'
        ],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Organic Chemistry - Some Basic Principles and Techniques',
        subTopic: 'Reagent Matching',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Reagents', 'Organic Reactions'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0511',
        questionText:
            'Major product formed in the following reaction is a mixture of:',
        options: ['Option 1', 'Option 2', 'Option 3', 'Option 4'],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Organic Chemistry - Some Basic Principles and Techniques',
        subTopic: 'Reaction Products',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Reaction Products', 'Mixture'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0512',
        questionText:
            'Which structure of protein remains intact after coagulation of egg white on boiling?',
        options: ['Primary', 'Tertiary', 'Secondary', 'Quaternary'],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Biomolecules',
        subTopic: 'Proteins',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Proteins', 'Structure'],
        questionType: 'multipleChoice',
      ),
      Question(
        id: 'CHEM0513',
        questionText:
            'Volume of 3M NaOH (formula weight 40 g mol⁻¹) which can be prepared from 84 g of NaOH is ____ ×10⁻¹ dm³.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Solutions',
        subTopic: 'Molarity',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Molarity', 'Solution Preparation'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0514',
        questionText:
            '9.3 g of aniline is subjected to reaction with excess of acetic anhydride to prepare acetanilide. The mass of acetanilide produced if the reaction is 100% completed is _____×10⁻¹ g. (Given molar mass in g mol⁻¹: N = 14, O = 16, C = 12, H = 1)',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Organic Chemistry - Some Basic Principles and Techniques',
        subTopic: 'Stoichiometry',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Stoichiometry', 'Organic Reaction'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0515',
        questionText:
            '1 mole of PbS is oxidised by X moles of O₂ to get Y moles of O₂. X + Y =',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Redox Reactions and Electrochemistry',
        subTopic: 'Stoichiometry',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Redox Reaction', 'Stoichiometry'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0516',
        questionText:
            'Total number of ions from the following with noble gas configuration is: Sr²⁺ (Z = 38), Cs⁺ (Z = 55), La²⁺ (Z = 57), Pb²⁺ (Z = 82), Yb²⁺ (Z = 70) and Fe²⁺ (Z = 26)',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Structure of Atom',
        subTopic: 'Electronic Configuration',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Electronic Configuration', 'Noble Gas Configuration'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0517',
        questionText:
            'The number of non-polar molecules from the following is: HF, H₂O, SO₂, H₂, CO₂, CH₄, NH₃, HCl, CHCl₃, BF₃',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Chemical Bonding and Molecular Structure',
        subTopic: 'Polarity',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Polarity', 'Molecular Structure'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0518',
        questionText:
            'For a certain thermochemical reaction M → N at T = 400 K, ΔH° = 77.2 kJ mol⁻¹, ΔS° = 122 J K⁻¹, log equilibrium constant logK is - _____×10⁻¹.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Chemical Thermodynamics',
        subTopic: 'Equilibrium Constant',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Equilibrium Constant', 'Thermodynamics'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0519',
        questionText:
            'Total number of compounds with Chiral carbon atoms from following is: CH₃-CH₂-CH(NO₂)-COOH, CH₃-CHI-CH₂-NO₂, CH₃-CH₂-CHBr-CH₂-CH₃, CH₃-CH₂-CHOH-CH₂OH',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Organic Chemistry - Some Basic Principles and Techniques',
        subTopic: 'Chirality',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Chirality', 'Stereochemistry'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0520',
        questionText:
            'The hydrogen electrode is dipped in a solution of pH = 3 at 25°C. The potential of the electrode will be - ______×10⁻² V. (2.303RT/F = 0.059 V) Round off the answer to the nearest integer.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Electrochemistry',
        subTopic: 'Electrode Potential',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Electrode Potential', 'Nernst Equation'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0521',
        questionText:
            'Time required for completion of 99.9% of first order reaction is ________ times of half life t₁/₂ of the reaction',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Chemical Kinetics',
        subTopic: 'First Order Reaction',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['First Order Reaction', 'Half Life'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0522',
        questionText:
            'The Spin only magnetic moment value of square planar complex [Pt(NH₃)₂Cl(NH₂CH₃)Cl] is _______ B.M. (Nearest integer) (Given atomic number for Pt = 78)',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Coordination Compounds',
        subTopic: 'Magnetic Moment',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Magnetic Moment', 'Coordination Compounds'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0492',
        questionText:
            'If α,β are the roots of the equation, x² - x - 1 = 0 and Sₙ = 2023αⁿ + 2024βⁿ, then',
        options: [
          '2S₁₂ = S₁₁ + S₁₀',
          'S₁₂ = S₁₁ + S₁₀',
          '2S₁₁ = S₁₂ + S₁₀',
          'S₁₁ = S₁₀ + S₁₂'
        ],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Sequence and Series',
        subTopic: 'Recurrence Relation',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Recurrence Relation', 'Roots of Equation'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0493',
        questionText: 'Let α = (4!)/3! and β = (5!)/4!. Then:',
        options: [
          'α ∈ N and β ∉ N',
          'α ∉ N and β ∈ N',
          'α ∈ N and β ∈ N',
          'α ∉ N and β ∉ N'
        ],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Permutations and Combinations',
        subTopic: 'Factorial',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Factorial', 'Natural Numbers'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0494',
        questionText:
            'The 20th term from the end of the progression 20, 19¹/₄, 18¹/₂, 17³/₄, … , -129¹/₄ is:',
        options: ['-118', '-110', '-115', '-100'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Sequence and Series',
        subTopic: 'Arithmetic Progression',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Arithmetic Progression', 'nth Term'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0495',
        questionText:
            'If 2tan²θ - 5secθ = 1 has exactly 7 solutions in the interval [0, nπ], for the least value of n ∈ N then ∑(k=1 to n) k/2ᵏ is equal to:',
        options: [
          '(1/2¹⁴)(2¹⁴ - 14)',
          '(1/2¹⁵)(2¹⁵ - 15)',
          '1 - 15/2¹³',
          '(1/2¹³)(2¹⁴ - 15)'
        ],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Trigonometry',
        subTopic: 'Trigonometric Equations',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Trigonometric Equations', 'Summation'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0496',
        questionText:
            'Let A and B be two finite sets with m and n elements respectively. The total number of subsets of the set A is 56 more than the total number of subsets of B. Then the distance of the point P(m,n) from the point Q(-2, -3) is',
        options: ['10', '6', '4', '8'],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Sets, Relations and Functions',
        subTopic: 'Sets',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Sets', 'Distance Formula'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0497',
        questionText:
            'Let R be the interior region between the lines 3x - y + 1 = 0 and x + 2y - 5 = 0 containing the origin. The set of all values of a, for which the points (a², a+1) lie in R, is:',
        options: [
          '(-3, -1) ∪ (-1/3, 1)',
          '(-3, 0) ∪ (1/3, 1)',
          '(-3, 0) ∪ (1/2, 1)',
          '(-3, -1) ∪ (1/3, 1)'
        ],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: 'Region',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Coordinate Geometry', 'Region'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0498',
        questionText:
            'Let e₁ be the eccentricity of the hyperbola x²/16 - y²/9 = 1 and e₂ be the eccentricity of the ellipse x²/a² + y²/b² = 1, a > b, which passes through the foci of the hyperbola. If e₁e₂ = 1, then the length of the chord of the ellipse parallel to the x-axis and passing through (0,2) is:',
        options: ['4√5', '8√5/3', '10√5/3', '3√5'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: 'Conic Sections',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Conic Sections', 'Chord Length'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0499',
        questionText:
            'If lim(x→0) [3 + αsinx + βcosx + logₑ(1-x)]/(3tan²x) = 1/3, then 2α - β is equal to:',
        options: ['2', '7', '5', '1'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Limits and Continuity',
        subTopic: 'Limits',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Limits', 'Series Expansion'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0500',
        questionText:
            'The values of α, for which |1 3 α+3; 2 2 1; 1 α+3 3; 2α+3 3α+1 0| = 0, lie in the interval',
        options: ['(-2,1)', '(-3,0)', '(-3/2, 3/2)', '(-1,2)'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Matrices and Determinants',
        subTopic: 'Determinants',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Determinants', 'Matrix'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0501',
        questionText:
            'Considering only the principal values of inverse trigonometric functions, the number of positive real values of x satisfying tan⁻¹x + tan⁻¹2x = π/4 is:',
        options: ['More than 2', '1', '2', '0'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Inverse Trigonometric Functions',
        subTopic: 'Equations',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Inverse Trigonometric Functions', 'Equations'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0502',
        questionText:
            'Let f: R - {-1} → R and g: R - {-5} → R be defined as f(x) = (2x+3)/(2x+1) and g(x) = |x| + 1. Then the domain of the function fog is:',
        options: ['R - {-5/2}', 'R', 'R - {-7/4}', 'R - {-5/2, -7/4}'],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Sets, Relations and Functions',
        subTopic: 'Functions',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Functions', 'Domain'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0503',
        questionText:
            'Consider the function f: (0,2) → R defined by f(x) = 2/x + x and the function g(x) defined by g(x) = min{f(t)}, 0 < t ≤ x for 0 < x ≤ 1 and g(x) = 3/2 + x for 1 < x < 2. Then',
        options: [
          'g is continuous but not differentiable at x = 1',
          'g is not continuous for all x ∈ (0,2)',
          'g is neither continuous nor differentiable at x = 1',
          'g is continuous and differentiable for all x ∈ (0,2)'
        ],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Limits and Continuity',
        subTopic: 'Continuity and Differentiability',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Continuity', 'Differentiability'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0504',
        questionText:
            'Let g(x) = 3f(x/3) + f(3-x) and f″(x) > 0 for all x ∈ (0,3). If g is decreasing in (0,α) and increasing in (α,3), then 8α is',
        options: ['24', '0', '18', '20'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Application of Derivatives',
        subTopic: 'Monotonicity',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Monotonicity', 'Second Derivative'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0505',
        questionText:
            'The integral ∫(x⁸ - x²)/(x¹² + 3x⁶ + 1)tan⁻¹(x³ + 1/x³) dx is equal to:',
        options: [
          '(1/3)log|tan⁻¹(x³ + 1/x³)| + C',
          '(1/2)log|tan⁻¹(x³ + 1/x³)| + C',
          'log|tan⁻¹(x³ + 1/x³)| + C',
          '(1/3)log|tan⁻¹(x³ + 1/x³)³| + C'
        ],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Integral Calculus',
        subTopic: 'Integration',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Integration', 'Substitution'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0506',
        questionText:
            'For 0 < a < 1, the value of the integral ∫(0 to π) dx/(1 - 2a cosx + a²) is:',
        options: ['π²/(π + a²)', 'π²/(π - a²)', 'π/(1 - a²)', 'π/(1 + a²)'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Integral Calculus',
        subTopic: 'Definite Integrals',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Definite Integrals', 'Trigonometric Integrals'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0507',
        questionText:
            'If y = y(x) is the solution curve of the differential equation (x² - 4)dy - (y² - 3y)dx = 0, x > 2, y(4) = 3/2 and the slope of the curve is never zero, then the value of y(10) equals:',
        options: [
          '3/(1 + 2√2)',
          '3/(1 + (8)¹/⁴)',
          '3/(1 - 2√2)',
          '3/(1 - (8)¹/⁴)'
        ],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Differential Equations',
        subTopic: 'Solution Curve',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Differential Equations', 'Solution Curve'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0508',
        questionText:
            'The position vectors of the vertices A, B and C of a triangle are 2î - 3ĵ + 3k̂, 2î + 2ĵ + 3k̂ and -î + ĵ + 3k̂ respectively. Let l denotes the length of the angle bisector AD of ∠BAC where D is on the line segment BC, then 2l² equals:',
        options: ['49', '42', '50', '45'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Vector Algebra',
        subTopic: 'Angle Bisector',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Vector Algebra', 'Angle Bisector'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0509',
        questionText:
            'Let the position vectors of the vertices A, B and C of a triangle be 2î + 2ĵ + k̂, î + 2ĵ + 2k̂ and 2î + ĵ + 2k̂ respectively. Let l₁, l₂ and l₃ be the lengths of perpendiculars drawn from the ortho centre of the triangle on the sides AB, BC and CA respectively, then l₁² + l₂² + l₃² equals:',
        options: ['1/5', '1/2', '1/4', '1/3'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Vector Algebra',
        subTopic: 'Orthocenter',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Vector Algebra', 'Orthocenter'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0510',
        questionText:
            'Let the image of the point (1,0,7) in the line (x-1)/1 = (y-1)/2 = (z-2)/3 be the point (α,β,γ). Then which one of the following points lies on the line passing through (α,β,γ) and making angles 2π/3 and 3π/4 with y-axis and z-axis respectively and an acute angle with x-axis?',
        options: [
          '(1, -2, 1+√2)',
          '(1, 2, 1-√2)',
          '(3, 4, 3-2√2)',
          '(3, -4, 3+2√2)'
        ],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Three Dimensional Geometry',
        subTopic: 'Line',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['3D Geometry', 'Line'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0511',
        questionText:
            'An urn contains 6 white and 9 black balls. Two successive draws of 4 balls are made without replacement. The probability, that the first draw gives all white balls and the second draw gives all black balls, is:',
        options: ['5/256', '5/715', '3/715', '3/256'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Probability',
        subTopic: 'Probability',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Probability', 'Combinations'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0512',
        questionText:
            'Let the complex numbers α and 1/ᾱ lie on the circles |z - z₀|² = 4 and |z - z₀|² = 16 respectively, where z₀ = 1 + i. Then, the value of 100|α|² is __________.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Complex Numbers',
        subTopic: 'Complex Numbers',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Complex Numbers', 'Circles'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0513',
        questionText:
            'The coefficient of x²⁰¹² in the expansion of (1-x)²⁰⁰⁸(1+x+x²)²⁰⁰⁷ is equal to _____.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Binomial Theorem',
        subTopic: 'Coefficient',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Binomial Theorem', 'Coefficient'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0514',
        questionText:
            'If the sum of squares of all real values of α, for which the lines 2x - y + 3 = 0, 6x + 3y + 1 = 0 and αx + 2y - 2 = 0 do not form a triangle is p, then the greatest integer less than or equal to p is ________.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Straight Lines',
        subTopic: 'Triangle Formation',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Straight Lines', 'Triangle Formation'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0515',
        questionText:
            'Consider a circle (x-α)² + (y-β)² = 50, where α,β > 0. If the circle touches the line y + x = 0 at the point P, whose distance from the origin is 4√2, then (α + β)² is equal to _______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: 'Circle',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Circle', 'Tangent'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0516',
        questionText:
            'The mean and standard deviation of 15 observations were found to be 12 and 3 respectively. On rechecking it was found that an observation was read as 10 in place of 12. If μ and σ² denote the mean and variance of the correct observations respectively, then 15μ + μ² + σ² is equal to _________.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Statistics',
        subTopic: 'Mean and Variance',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Statistics', 'Mean and Variance'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0517',
        questionText:
            'Let A be a 2×2 real matrix and I be the identity matrix of order 2. If the roots of the equation |A - xI| = 0 be -1 and 3, then the sum of the diagonal elements of the matrix A² is _____.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Matrices',
        subTopic: 'Matrix',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Matrices', 'Eigenvalues'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0518',
        questionText:
            'Let f(x) = ∫(0 to x) g(t)logₑ((1-t)/(1+t)) dt, where g is a continuous odd function. If ∫(-π/2 to π/2) [f(x) + x²cosx/(1+eˣ)] dx = -πα/2, then α is equal to _____.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Integral Calculus',
        subTopic: 'Definite Integrals',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Definite Integrals', 'Odd Function'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0519',
        questionText:
            'If the area of the region {(x,y): 0 ≤ x ≤ 3, 0 ≤ y ≤ min{x² + 2, 2x + 2}} is A, then 12A is equal to _______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Integral Calculus',
        subTopic: 'Area',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Area', 'Integration'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0520',
        questionText:
            'If the solution curve, of the differential equation dy/dx = (x + y - 2)/(x - y) passing through the point (2,1) is tan⁻¹((y-1)/(x-1)) - (1/β)logₑ(α + (y-1)/(x-1)) = logₑ|x-1|, then 5β + α is equal to',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Differential Equations',
        subTopic: 'Solution Curve',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Differential Equations', 'Solution Curve'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0521',
        questionText:
            'The lines (x-2)/2 = y/-2 = (z-7)/16 and (x+3)/4 = (y+2)/3 = (z+2)/1 intersect at the point P. If the distance of P from the line (x+1)/2 = (y-1)/3 = (z-1)/1 is l, then 14l² is equal to _____.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Three Dimensional Geometry',
        subTopic: 'Distance',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['3D Geometry', 'Distance'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0525',
        questionText:
            'Given below are two statements: Statement (I): Planck\'s constant and angular momentum have the same dimensions. Statement (II): Linear momentum and moment of force have the same dimensions. In light of the above statements, choose the correct answer from the options given below:',
        options: [
          'Statement I is true but Statement II is false',
          'Both Statement I and Statement II are false',
          'Both Statement I and Statement II are true',
          'Statement I is false but Statement II is true'
        ],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Units and Measurements',
        subTopic: 'Dimensions',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Dimensions', 'Physical Quantities'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0526',
        questionText:
            'Position of an ant (S in metres) moving in Y−Z plane is given by S = 2t²ĵ + 5k̂ (where t is in second). The magnitude and direction of velocity of the ant at t = 1 s will be:',
        options: [
          '16 m s⁻¹ in y-direction',
          '4 m s⁻¹ in x-direction',
          '9 m s⁻¹ in z-direction',
          '4 m s⁻¹ in y-direction'
        ],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Kinematics',
        subTopic: 'Velocity',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Velocity', 'Vector'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0527',
        questionText:
            'A train is moving with a speed of 12 m s⁻¹ on rails which are 1.5 m apart. To negotiate a curve radius 400 m, the height by which the outer rail should be raised with respect to the inner rail is (Given, g = 10 m s⁻²):',
        options: ['6.0 cm', '5.4 cm', '4.8 cm', '4.2 cm'],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Circular Motion',
        subTopic: 'Banking of Roads',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Banking of Roads', 'Circular Motion'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0528',
        questionText:
            'Two bodies of mass 4 g and 25 g are moving with equal kinetic energies. The ratio of magnitude of their linear momentum is:',
        options: ['3 : 5', '5 : 4', '2 : 5', '4 : 5'],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Work, Energy and Power',
        subTopic: 'Kinetic Energy and Momentum',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Kinetic Energy', 'Momentum'],
        questionType: 'multipleChoice',
      ),
      Question(
        id: 'PHY0529',
        questionText:
            'A body of mass 1000 kg is moving horizontally with a velocity 6 m s⁻¹. If 200 kg extra mass is added, the final velocity (in m s⁻¹) is:',
        options: ['6', '2', '3', '5'],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Laws of Motion',
        subTopic: 'Conservation of Momentum',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Conservation of Momentum', 'Mass Addition'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0530',
        questionText:
            'The acceleration due to gravity on the surface of earth is g. If the diameter of earth reduces to half of its original value and mass remains constant, then acceleration due to gravity on the surface of earth would be:',
        options: ['g', '2g', 'g/4', '4g'],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Gravitation',
        subTopic: 'Acceleration due to Gravity',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Gravitational Acceleration', 'Earth\'s Radius'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0531',
        questionText:
            'Given below are two statements: Statement (I): Viscosity of gases is greater than that of liquids. Statement (II): Surface tension of a liquid decreases due to the presence of insoluble impurities. In the light of the above statements, choose the most appropriate answer from the options given below:',
        options: [
          'Statement I is correct but statement II is incorrect',
          'Statement I is incorrect but Statement II is correct',
          'Both Statement I and Statement II are incorrect',
          'Both Statement I and Statement II are correct'
        ],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Properties of Solids and Liquids',
        subTopic: 'Viscosity and Surface Tension',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Viscosity', 'Surface Tension'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0532',
        questionText:
            '0.08 kg air is heated at constant volume through 5°C. The specific heat of air at constant volume is 0.17 kcal kg⁻¹ °C⁻¹ and 1 cal = 4.18 J. The change in its internal energy is approximately.',
        options: ['318 J', '298 J', '284 J', '142 J'],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Thermodynamics',
        subTopic: 'Internal Energy',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Internal Energy', 'Specific Heat'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0533',
        questionText:
            'The average kinetic energy of a monatomic molecule is 0.414 eV at temperature: (Use K_B = 1.38×10⁻²³ J mol⁻¹ K⁻¹)',
        options: ['3000 K', '3200 K', '1600 K', '1500 K'],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Kinetic Theory of Gases',
        subTopic: 'Kinetic Energy',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Kinetic Energy', 'Temperature'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0534',
        questionText:
            'An electric charge 10⁻⁶ μC is placed at origin (0, 0) m of X−Y co-ordinate system. Two points P and Q are situated at (√3, √3) m and (√6, 0) m respectively. The potential difference between the points P and Q will be:',
        options: ['√3 V', '√6 V', '0 V', '3 V'],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Electrostatics',
        subTopic: 'Electric Potential',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Electric Potential', 'Point Charge'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0535',
        questionText:
            'A wire of resistance R and length L is cut into 5 equal parts. If these parts are joined parallely, then resultant resistance will be:',
        options: ['R/25', 'R/5', '25R', '5R'],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Current Electricity',
        subTopic: 'Resistance',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Parallel Resistance', 'Wire Cutting'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0536',
        questionText:
            'A wire of length 10 cm and radius √7×10⁻⁴ m connected across the right gap of a meter bridge. When a resistance of 4.5 Ω is connected on the left gap by using a resistance box, the balance length is found to be at 60 cm from the left end. If the resistivity of the wire is R×10⁻⁷ Ω m, then value of R is:',
        options: ['63', '70', '66', '35'],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Current Electricity',
        subTopic: 'Meter Bridge',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Meter Bridge', 'Resistivity'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0537',
        questionText:
            'A proton moving with a constant velocity passes through a region of space without any change in its velocity. If E and B represent the electric and magnetic fields respectively, then the region of space may have: (A) E = 0, B = 0; (B) E = 0, B ≠ 0; (C) E ≠ 0, B = 0; (D) E ≠ 0, B ≠ 0 Choose the most appropriate answer from the options given below:',
        options: [
          '(A), (B) and (C) only',
          '(A), (C) and (D) only',
          '(A), (B) and (D) only',
          '(B), (C) and (D) only'
        ],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Electromagnetic Waves',
        subTopic: 'Electromagnetic Fields',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Electric Field', 'Magnetic Field'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0538',
        questionText:
            'A rectangular loop of length 2.5 m and width 2 m is placed at 60° to a magnetic field of 4 T. The loop is removed from the field in 10 sec. The average emf induced in the loop during this time is',
        options: ['−2 V', '+2 V', '+1 V', '−1 V'],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Electromagnetic Induction and Alternating Currents',
        subTopic: 'Induced EMF',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Induced EMF', 'Faraday\'s Law'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0539',
        questionText:
            'A plane electromagnetic wave propagating in x-direction is described by E_y = (200 V m⁻¹)sin[1.5×10⁷t − 0.05x]; The intensity of the wave is: (Use ε₀ = 8.85×10⁻¹² C² N⁻¹ m⁻²)',
        options: ['35.4 W m⁻²', '53.1 W m⁻²', '26.6 W m⁻²', '106.2 W m⁻²'],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Electromagnetic Waves',
        subTopic: 'Wave Intensity',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['EM Wave Intensity', 'Wave Equation'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0540',
        questionText:
            'If the refractive index of the material of a prism is cot(A/2), where A is the angle of prism then the angle of minimum deviation will be',
        options: ['π − 2A', 'π/2 − 2A', 'π − A', 'π/2 − A'],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Optics',
        subTopic: 'Prism',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Prism', 'Minimum Deviation'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0541',
        questionText:
            'A convex lens of focal length 40 cm forms an image of an extended source of light on a photoelectric cell. A current I is produced. The lens is replaced by another convex lens having the same diameter but focal length 20 cm. The photoelectric current now is',
        options: ['I', '4I', '2I', 'I/2'],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Optics',
        subTopic: 'Lens',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Lens', 'Photoelectric Current'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0542',
        questionText:
            'The radius of third stationary orbit of electron for Bohr\'s atom is R. The radius of fourth stationary orbit will be:',
        options: ['4R', '16R/9', '3R', '9R/16'],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Atoms and Nuclei',
        subTopic: 'Bohr\'s Model',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Bohr\'s Model', 'Stationary Orbits'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0543',
        questionText: 'Which of the following circuits is reverse-biased?',
        options: ['Option 1', 'Option 2', 'Option 3', 'Option 4'],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Electronic Devices',
        subTopic: 'Diode Biasing',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Diode', 'Reverse Bias'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0544',
        questionText:
            'Identify the physical quantity that cannot be measured using spherometer:',
        options: [
          'Radius of curvature of concave surface',
          'Specific rotation of liquids',
          'Thickness of thin plates',
          'Radius of curvature of convex surface'
        ],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Experimental Skills',
        subTopic: 'Spherometer',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Spherometer', 'Measurement'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0545',
        questionText:
            'A particle starts from origin at t = 0 with a velocity 5î m s⁻¹ and moves in x−y plane under action of a force which produces a constant acceleration of (3î + 2ĵ) m s⁻². If the x-coordinate of the particle at that instant is 84 m, then the speed of the particle at this time is √α m s⁻¹. The value of α is _______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Kinematics',
        subTopic: 'Projectile Motion',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Projectile Motion', 'Speed Calculation'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0546',
        questionText:
            'Four particles, each of mass 1 kg are placed at four corners of a square of side 2 m. The moment of inertia of the system about an axis perpendicular to its plane and passing through one of its vertex is ______ kg m².',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Rotational Motion',
        subTopic: 'Moment of Inertia',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Moment of Inertia', 'Square System'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0547',
        questionText:
            'If average depth of an ocean is 4000 m and the bulk modulus of water is 2×10⁹ N m⁻², then fractional compression ΔV/V of water at the bottom of ocean is α×10⁻². The value of α is _______, (Given, g = 10 m s⁻², ρ = 1000 kg m⁻³)',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Properties of Solids and Liquids',
        subTopic: 'Bulk Modulus',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Bulk Modulus', 'Compression'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0548',
        questionText:
            'A particle executes simple harmonic motion with an amplitude of 4 cm. At the mean position, velocity of the particle is 10 cm s⁻¹. The distance of the particle from the mean position when its speed becomes 5 cm s⁻¹ is √α cm, where α =______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Oscillations and Waves',
        subTopic: 'Simple Harmonic Motion',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Simple Harmonic Motion', 'Velocity'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0549',
        questionText:
            'A thin metallic wire having cross sectional area of 10⁻⁴ m² is used to make a ring of radius 30 cm. A positive charge of 2π C is uniformly distributed over the ring, while another positive charge of 30 pC is kept at the centre of the ring. The tension in the ring is _______ N; provided that the ring does not get deformed (neglect the influence of gravity). (Given, 1/4πε₀ = 9×10⁹ SI units)',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Electrostatics',
        subTopic: 'Charged Ring',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Charged Ring', 'Tension'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0550',
        questionText:
            'The charge accumulated on the capacitor connected in the following circuit is ______ μC. (Given C = 150 μF)',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Electrostatics',
        subTopic: 'Capacitor',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Capacitor', 'Charge Accumulation'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0551',
        questionText:
            'Two long, straight wires carry equal currents in opposite directions as shown in figure. The separation between the wires is 5.0 cm. The magnitude of the magnetic field at a point P midway between the wires is _____ μT. (Given: μ₀ = 4π×10⁻⁷ T m A⁻¹)',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Magnetic Effects of Current and Magnetism',
        subTopic: 'Magnetic Field',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Magnetic Field', 'Parallel Wires'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0552',
        questionText:
            'Two coils have mutual inductance 0.002 H. The current changes in the first coil according to the relation i = i₀ sinωt, where i₀ = 5 A and ω = 50π rad s⁻¹. The maximum value of emf in the second coil is (απ/8) V. The value of α is',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Electromagnetic Induction and Alternating Currents',
        subTopic: 'Mutual Inductance',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Mutual Inductance', 'Induced EMF'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0553',
        questionText:
            'Two immiscible liquids of refractive indices 5/2 and 4/3 respectively are put in a beaker as shown in the figure. The height of each column is 6 cm. A coin is placed at the bottom of the beaker. For near normal vision, the apparent depth of the coin is α cm. The value of α is _______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Optics',
        subTopic: 'Refraction',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Refraction', 'Apparent Depth'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0554',
        questionText:
            'In a nuclear fission process, a high mass nuclide (A ≈ 236) with binding energy 7.6 MeV/Nucleon dissociated into two middle mass nuclides (A ≈ 118), having binding energy of 8.6 MeV/Nucleon. The energy released in the process would be _______ MeV.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Atoms and Nuclei',
        subTopic: 'Nuclear Fission',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Nuclear Fission', 'Binding Energy'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0555',
        questionText:
            'The electronic configuration for Neodymium is: [Atomic Number for Neodymium 60]',
        options: [
          '[Xe] 4f⁴ 6s²',
          '[Xe] 5f⁴ 7s²',
          '[Xe] 4f⁶ 6s²',
          '[Xe] 4f¹ 5d¹ 6s²'
        ],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Atoms and Nuclei',
        subTopic: 'Electronic Configuration',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Electronic Configuration', 'Lanthanides'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0523',
        questionText:
            'Which of the following electronic configuration would be associated with the highest magnetic moment?',
        options: ['[Ar] 3d⁷', '[Ar] 3d⁸', '[Ar] 3d³', '[Ar] 3d⁶'],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Coordination Compounds',
        subTopic: 'Magnetic Moment',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Magnetic Moment', 'Electronic Configuration'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0524',
        questionText: 'Choose the polar molecule from the following:',
        options: ['CCl₄', 'CO₂', 'CH₂=CH₂', 'CHCl₃'],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Chemical Bonding and Molecular Structure',
        subTopic: 'Polarity',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Polarity', 'Molecular Structure'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0525',
        questionText: 'Which of the following is strongest Bronsted base?',
        options: ['Option 1', 'Option 2', 'Option 3', 'Option 4'],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Equilibrium',
        subTopic: 'Bronsted Base',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Bronsted Base', 'Basicity'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0526',
        questionText:
            'Given below are two statements: Statement (I): Aqueous solution of ammonium carbonate is basic. Statement (II): Acidic/basic nature of salt solution of a salt of weak acid and weak base depends on K_a and K_b value of acid and the base forming it. In the light of the above statements, choose the most appropriate answer from the options given below:',
        options: [
          'Both Statement I and Statement II are correct',
          'Statement I is correct but Statement II is incorrect',
          'Both Statement I and Statement II are incorrect',
          'Statement I is incorrect but Statement II is correct'
        ],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Equilibrium',
        subTopic: 'Salt Hydrolysis',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Salt Hydrolysis', 'pH of Salts'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0527',
        questionText:
            'Given below are two statements: one is labelled as Assertion (A) and the other is labelled as Reason (R). Assertion (A): Melting point of Boron (2453 K) is unusually high in group 13 elements. Reason (R): Solid Boron has very strong crystalline lattice. In the light of the above statements, choose the most appropriate answer from the options given below:',
        options: [
          'Both (A) and (R) are correct but (R) Is not the correct explanation of (A)',
          'Both (A) and (R) are correct and (R) is the correct explanation of (A)',
          '(A) is true but (R) is false',
          '(A) is false but (R) is true'
        ],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'p-Block Elements',
        subTopic: 'Group 13 Elements',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Group 13 Elements', 'Boron'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0528',
        questionText: 'IUPAC name of following compound (P) is:',
        options: [
          '1−Ethyl−5,5−dimethylcyclohexane',
          '3−Ethyl−1,1−dimethylcyclohexane',
          '1−Ethyl−3,3−dimethylcyclohexane',
          '1,1−Dimethyl−3−ethylcyclohexane'
        ],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'Organic Chemistry - Some Basic Principles and Techniques',
        subTopic: 'IUPAC Nomenclature',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['IUPAC Nomenclature', 'Cycloalkanes'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0529',
        questionText: 'Cyclohexene is _________ type of an organic compound.',
        options: [
          'Benzenoid aromatic',
          'Benzenoid non-aromatic',
          'Acyclic',
          'Alicyclic'
        ],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Organic Chemistry - Some Basic Principles and Techniques',
        subTopic: 'Classification',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Organic Classification', 'Cycloalkenes', 'Hydrocarbons'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0530',
        questionText: 'Which of the following has highly acidic hydrogen?',
        options: ['Option 1', 'Option 2', 'Option 3', 'Option 4'],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Organic Chemistry - Some Basic Principles and Techniques',
        subTopic: 'Acidity',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Acidity', 'Hydrogen Bonding'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0531',
        questionText:
            'The ascending order of acidity of –OH group in the following compounds is: (A) Bu–OH (B) (C) (D) (E) Choose the correct answer from the options given below:',
        options: [
          '(A) < (D) < (C) < (B) < (E)',
          '(C) < (A) < (D) < (B) < (E)',
          '(C) < (D) < (B) < (A) < (E)',
          '(A) < (C) < (D) < (B) < (E)'
        ],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Alcohols, Phenols and Ethers',
        subTopic: 'Acidity Order',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Acidity Order', 'OH Group'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0532',
        questionText: 'Highest enol content will be shown by:',
        options: ['Option 1', 'Option 2', 'Option 3', 'Option 4'],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'Organic Chemistry - Some Basic Principles and Techniques',
        subTopic: 'Enol Content',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Enol Content', 'Tautomerism'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0533',
        questionText:
            'A solution of two miscible liquids showing negative deviation from Raoult\'s law will have:',
        options: [
          'increased vapour pressure, increased boiling point',
          'increased vapour pressure, decreased boiling point',
          'decreased vapour pressure, decreased boiling point',
          'decreased vapour pressure, increased boiling point'
        ],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Solutions',
        subTopic: 'Raoult\'s Law',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Raoult\'s Law', 'Deviation'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0534',
        questionText: 'Element not showing variable oxidation state is:',
        options: ['Bromine', 'Iodine', 'Chlorine', 'Fluorine'],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'p-Block Elements',
        subTopic: 'Oxidation States',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Oxidation States', 'Halogens'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0535',
        questionText:
            'NaCl reacts with conc. H₂SO₄ and K₂Cr₂O₇ to give reddish fumes (B), which react with NaOH to give yellow solution (C). (B) and (C) respectively are:',
        options: [
          'CrO₂Cl₂, Na₂CrO₄',
          'Na₂CrO₄, CrO₂Cl₂',
          'CrO₂Cl₂, KHSO₄',
          'CrO₂Cl₂, Na₂Cr₂O₇'
        ],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'The d- and f-Block Elements',
        subTopic: 'Chromium Compounds',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Chromium Compounds', 'Chromyl Chloride Test'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0536',
        questionText:
            'Given below are two statements: Statement (I): The 4f and 5f - series of elements are placed separately in the Periodic table to preserve the principle of classification. Statement (II): s-block elements can be found in pure form in nature. In light of the above statements, choose the most appropriate answer from the options given below:',
        options: [
          'Statement I is false but Statement II is true',
          'Both Statement I and Statement II are true',
          'Statement I is true but Statement II is false',
          'Both Statement I and Statement II are false'
        ],
        correctAnswerIndex: 2,
        subject: 'Chemistry',
        topic: 'Classification of Elements and Periodicity in Properties',
        subTopic: 'Periodic Table',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Periodic Table', 'f-block Elements'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0537',
        questionText:
            'Yellow compound of lead chromate gets dissolved on treatment with hot NaOH solution. The product of lead formed is a:',
        options: [
          'Tetraanionic complex with coordination number six',
          'Neutral complex with coordination number four',
          'Dianionic complex with coordination number six',
          'Dianionic complex with coordination number four'
        ],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'The d- and f-Block Elements',
        subTopic: 'Lead Chromate',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Lead Chromate', 'Complex Formation'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0538',
        questionText:
            'Consider the following complex ions P = [FeF₆]³⁻, Q = [V(H₂O)₆]²⁺, R = [Fe(H₂O)₆]²⁺ The correct order of the complex ions, according to their spin only magnetic moment values (in B.M.) is:',
        options: ['R < Q < P', 'R < P < Q', 'Q < R < P', 'Q < P < R'],
        correctAnswerIndex: 2,
        subject: 'Chemistry',
        topic: 'Coordination Compounds',
        subTopic: 'Magnetic Moment',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Magnetic Moment', 'Complex Ions'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0539',
        questionText:
            'The correct statement regarding nucleophilic substitution reaction in a chiral alkyl halide is:',
        options: [
          'Retention occurs in SN1 reaction and inversion occurs in SN2 reaction.',
          'Racemisation occurs in SN1 reaction and retention occurs in SN2 reaction.',
          'Racemisation occurs in both SN1 and SN2 reactions.',
          'Racemisation occurs in SN1 reaction and inversion occurs in SN2 reaction.'
        ],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Haloalkanes and Haloarenes',
        subTopic: 'Nucleophilic Substitution',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Nucleophilic Substitution', 'Stereochemistry'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0540',
        questionText:
            'Given below are two statements: Statement (I): p-nitrophenol is more acidic than m-nitrophenol and o-nitrophenol. Statement (II): Ethanol will give immediate turbidity with Lucas reagent. In the light of the above statements, choose the correct answer from the options given below:',
        options: [
          'Statement I is true but Statement II is false',
          'Both Statement I and Statement II are true',
          'Both Statement I and Statement II are false',
          'Statement I is false but Statement II is true'
        ],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Alcohols, Phenols and Ethers',
        subTopic: 'Acidity and Tests',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Acidity of Phenols', 'Lucas Test'],
        questionType: 'multipleChoice',
      ),
      Question(
        id: 'CHEM0358',
        questionText:
            'Give below are two statements: Statement-I : Noble gases have very high boiling points. Statement-II: Noble gases are monoatomic gases. They are held together by strong dispersion forces. Because of this they are liquefied at very low temperature. Hence, they have very high boiling points. In the light of the above statements. choose the correct answer from the options given below:',
        options: [
          'Statement I is false but Statement II is true',
          'Both Statement I and Statement II are true',
          'Statement I is true but Statement II is false',
          'Both Statement I and Statement II are false'
        ],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'p-Block Elements',
        subTopic: 'Noble Gases',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Noble Gases', 'Boiling Points', 'Dispersion Forces'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'CHEM0359',
        questionText:
            'Identify correct statements from below: A. The chromate ion is square planar. B. Dichromates are generally prepared from chromates. C. The green manganate ion is diamagnetic. D. Dark green coloured K₂MnO₄ disproportionates in a neutral or acidic medium to give permanganate. E. With increasing oxidation number of transition metal, ionic character of the oxides decreases. Choose the correct answer from the options given below:',
        options: [
          'B, C, D only',
          'A, D, E only',
          'A, B, C only',
          'B, D, E only'
        ],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'd- and f-Block Elements',
        subTopic: 'Transition Metal Compounds',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Chromates', 'Manganates', 'Transition Metal Oxides'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'CHEM0360',
        questionText:
            'The correct statements from the following are: A. The strength of anionic ligands can be explained by crystal field theory. B. Valence bond theory does not give a quantitative interpretation of kinetic stability of coordination compounds. C. The hybridization involved in formation of [Ni(CN)₄]²⁻ complex is dsp². D. The number of possible isomer(s) of cis-[PtCl₂(en)]²⁺ is one. Choose the correct answer from the options given below:',
        options: ['A, D only', 'A, C only', 'B, D only', 'B, C only'],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Coordination Compounds',
        subTopic: 'Coordination Chemistry Theories',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: [
          'Crystal Field Theory',
          'Valence Bond Theory',
          'Hybridization',
          'Isomerism'
        ],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'CHEM0361',
        questionText:
            'Given below are two statements: One is labelled as Assertion A and the other is labelled as Reason R: Assertion A: pKₐ value of phenol is 10.0 while that of ethanol is 15.9. Reason R: Ethanol is stronger acid than phenol. In the light of the above statements, choose the correct answer from the options given below:',
        options: [
          'A is true but R is false',
          'A is false but R is true',
          'Both A and R are true and R is the correct explanation of A',
          'Both A and R are true but R is NOT the correct explanation of A'
        ],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Organic Compounds Containing Oxygen',
        subTopic: 'Acidity of Alcohols and Phenols',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Acidity', 'pKa Values', 'Phenol', 'Ethanol'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'CHEM0362',
        questionText:
            'Given below are two statements: One is labelled as Assertion A and the other is labelled as Reason R: Assertion A: Alcohols react both as nucleophiles and electrophiles. Reason R: Alcohols react with active metals such as sodium, potassium and aluminum to yield corresponding alkoxides and liberate hydrogen. In the light of the above statements, choose the correct answer from the options given below:',
        options: [
          'A is false but R is true',
          'A is true but R is false',
          'Both A and R are true and R is the correct explanation of A',
          'Both A and R are true but R is NOT the correct explanation of A'
        ],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Organic Compounds Containing Oxygen',
        subTopic: 'Chemical Properties of Alcohols',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: [
          'Alcohols',
          'Nucleophiles',
          'Electrophiles',
          'Reactivity with Metals'
        ],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'CHEM0363',
        questionText: 'The compound that is white in color is',
        options: [
          'ammonium sulphide',
          'lead sulphate',
          'lead iodide',
          'ammonium arsinomolybdate'
        ],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'p-Block Elements',
        subTopic: 'Chemical Compounds and Colors',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Compound Colors', 'Lead Compounds', 'Sulphides', 'Iodides'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'CHEM0364',
        questionText:
            'Match List I with List II List-I List-II A. Glucose/NaHCO₃/∆ I. Gluconic acid B. Glucose/HNO₃ II. No reaction C. Glucose/HI/∆ III. n-hexane D. Glucose/Bromine water IV. Saccharic acid Choose the correct answer from the options given below:',
        options: [
          'A-IV, B-I, C-III, D-II',
          'A-II, B-IV, C-III, D-I',
          'A-III, B-II, C-I, D-IV',
          'A-I, B-IV, C-III, D-II'
        ],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'Some Basic Concepts in Chemistry',
        subTopic: 'Glucose Reactions',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: [
          'Glucose Reactions',
          'Oxidation',
          'Reduction',
          'Bromine Water Test'
        ],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'CHEM0365',
        questionText:
            'Number of moles of methane required to produce 22g CO₂ after combustion is x×10⁻² moles. The value of x is',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Atomic Structure',
        subTopic: 'Stoichiometry Calculations',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Stoichiometry', 'Combustion', 'Mole Concept'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0366',
        questionText:
            'The ionization energy of sodium in kJ mol⁻¹. If electromagnetic radiation of wavelength 242 nm is just sufficient to ionize sodium atom is ______.(nearest integer)',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Chemical Bonding and Molecular Structure',
        subTopic: 'Ionization Energy',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: [
          'Ionization Energy',
          'Electromagnetic Radiation',
          'Wavelength-Energy Relationship'
        ],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0367',
        questionText:
            'The number of species from the following in which the central atom uses sp³ hybrid orbitals in its bonding is _________. NH₃, SO₂, SiO₂, BeCl₂, CO₂, H₂O, CH₄, BF₃',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Chemical Thermodynamics',
        subTopic: 'Chemical Bonding and Hybridization',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Hybridization', 'sp³ Hybridization', 'Molecular Geometry'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0368',
        questionText:
            'Consider the following reaction at 298 K. 3O₂(g) ⇌ 2O₃(g). Kp = 2.47×10⁻²⁹. ΔG⁰ for the reaction is _________ kJ. (Given R = 8.314 JK⁻¹ mol⁻¹) Round off your answer to the nearest integer.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Hydrocarbons',
        subTopic: 'Chemical Thermodynamics',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: [
          'Gibbs Free Energy',
          'Equilibrium Constant',
          'Thermodynamics'
        ],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0369',
        questionText:
            'Number of alkanes obtained on electrolysis of a mixture of CH₃COONa and C₂H₅COONa is_____.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Electrochemistry',
        subTopic: 'Kolbe Electrolysis',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Kolbe Electrolysis', 'Alkanes', 'Electrolysis'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0370',
        questionText:
            'One Faraday of electricity liberates x×10⁻¹ gram atom of copper from copper sulphate, x is______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'd- and f-Block Elements',
        subTopic: 'Electrochemical Equivalents',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Faraday Law', 'Electrochemistry', 'Copper'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0371',
        questionText:
            'The Spin only Magnetic moment for [Ni(NH₃)₆]²⁺ is______× 10⁻¹ BM. (given Atomic number of Ni : 28) Round off your answer to the nearest integer.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Organic Compounds Containing Oxygen',
        subTopic: 'Magnetic Properties',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: [
          'Magnetic Moment',
          'Coordination Compounds',
          'Nickel Complexes'
        ],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0372',
        questionText:
            'The total number of hydrogen atoms in product A and product B is__________.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Purification and Characterisation of Organic Compounds',
        subTopic: 'Organic Analysis',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Hydrogen Atoms', 'Organic Products', 'Molecular Formula'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0373',
        questionText:
            'The product of the following reaction is P. The number of hydroxyl groups present in the product P is________.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Some Basic Concepts in Chemistry',
        subTopic: 'Functional Groups',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Hydroxyl Groups', 'Organic Reactions', 'Functional Groups'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0341',
        questionText:
            'Molar mass of the salt from NaBr, NaNO₃, KI and CaF₂ which does not evolve coloured vapours on heating with concentrated H₂SO₄ is ____ g mol⁻¹, (Molar mass in g mol⁻¹ : Na : 23, N : 14, K : 39, O : 16, Br : 80, I : 127, F : 19, Ca : 40 )',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Sets, Relations and Functions',
        subTopic: 'Stoichiometry and Molar Mass',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Molar Mass', 'Chemical Reactions', 'Salts'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0342',
        questionText:
            'Let S be the set of positive integral values of a for which (a𝑥² + 2(a+1)𝑥 + 9a + 4)/(𝑥² - 8𝑥 + 32) < 0, ∀𝑥 ∈ ℝ. Then, the number of elements in S is:',
        options: ['1', '0', '∞', '3'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Quadratic Equations and Complex Numbers',
        subTopic: 'Inequalities',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Inequalities', 'Quadratic Expressions', 'Set Theory'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'MATH0343',
        questionText:
            'For 0 < c < b < a, let (a+b–2c)𝑥² + (b+c–2a)𝑥 + (c+a–2b) = 0 and α ≠ 1 be one of its root. Then, among the two statements (I) If α ∈ (-1, 0), then b cannot be the geometric mean of a and c. (II) If α ∈ (0, 1), then b may be the geometric mean of a and c.',
        options: [
          'Both (I) and (II) are true',
          'Neither (I) nor (II) is true',
          'Only (II) is true',
          'Only (I) is true'
        ],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Sequence and Series',
        subTopic: 'Quadratic Equations and Geometric Mean',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: [
          'Quadratic Equations',
          'Geometric Mean',
          'Roots of Equations'
        ],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'MATH0344',
        questionText:
            'The sum of the series 1/(1−3⋅1²+1⁴) + 1/(1−3⋅2²+2⁴) + 1/(1−3⋅3²+3⁴) + ... up to 10 terms is',
        options: ['45/109', '-45/109', '55/109', '-55/109'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: 'Series and Sequences',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Series Summation', 'Algebraic Series', 'Sequence Patterns'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'MATH0345',
        questionText:
            'Let α, β, γ, δ ∈ Z and let A(α, β), B(1, 0), C(γ, δ) and D(1, 2) be the vertices of a parallelogram ABCD. If AB = √10 and the points A and C lie on the line 3𝑦 = 2𝑥+1, then 2α+β+γ+δ is equal to',
        options: ['10', '5', '12', '8'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: 'Coordinate Geometry of Parallelograms',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Coordinate Geometry', 'Parallelograms', 'Distance Formula'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'MATH0346',
        questionText:
            'If one of the diameters of the circle 𝑥²+𝑦²-10𝑥+4𝑦+13 = 0 is a chord of another circle C, whose center is the point of intersection of the lines 2𝑥+3𝑦 = 12 and 3𝑥-2𝑦 = 5, then the radius of the circle C is',
        options: ['√20', '4', '6', '3√2'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Three Dimensional Geometry',
        subTopic: 'Circle Geometry',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Circle Geometry', 'Chords', 'Intersection Points'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'MATH0347',
        questionText:
            'If the foci of a hyperbola are same as that of the ellipse 𝑥²/9 + 𝑦²/25 = 1 and the eccentricity of the hyperbola is 2 times the eccentricity of the ellipse, then the smaller focal distance of the point (√2, 14/5) on the hyperbola, is equal to',
        options: [
          '(7√2/5) - (8/3)',
          '(14√2/5) - (4/3)',
          '(14√2/5) - (16/3)',
          '(7√2/5) + (8/3)'
        ],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Limit, Continuity and Differentiability',
        subTopic: 'Conic Sections',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Hyperbola', 'Ellipse', 'Focal Distance', 'Eccentricity'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'MATH0348',
        questionText: 'lim (𝑥→0) (𝑒^(2sin𝑥) - 2sin𝑥 - 1)/𝑥²',
        options: [
          'is equal to -1',
          'does not exist',
          'is equal to 1',
          'is equal to 2'
        ],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Binomial Theorem and Its Simple Applications',
        subTopic: 'Limits',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Limits', 'Exponential Functions', 'Trigonometric Limits'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'MATH0349',
        questionText:
            'Let a be the sum of all coefficients in the expansion of (1 – 2𝑥+2𝑥²)²⁰²³ (3-4𝑥²+2𝑥³)²⁰²⁴ and b = lim (𝑥→0) (∫₀ˣ log(1+𝑡) 𝑑𝑡)/(𝑡²⁰²⁴+1)/𝑥². If the equations c𝑥²+𝑑𝑥+𝑒 = 0 and 2b𝑥²+a𝑥+4 = 0 have a common root, where c, d, e ∈ R, then d : c : e equals',
        options: ['2 : 1 : 4', '4 : 1 : 4', '1 : 2 : 4', '1 : 1 : 4'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic:
            'Differential Calculus (Limit, Continuity and Differentiability)',
        subTopic: 'Binomial Expansion and Limits',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: [
          'Binomial Expansion',
          'Limits',
          'Common Roots',
          'Quadratic Equations'
        ],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'MATH0350',
        questionText:
            'If 𝑓(𝑥) = |𝑥³ 2𝑥²+1 1+3𝑥; 3𝑥²+2 2𝑥 𝑥³+6; 𝑥³−𝑥 4 𝑥²−2| for all 𝑥 ∈ ℝ, then 2𝑓(0)+𝑓′(0) is equal to',
        options: ['48', '24', '42', '18'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Matrices and Determinants',
        subTopic: 'Determinants and Differentiation',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Determinants', 'Differentiation', 'Matrix Functions'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'MATH0351',
        questionText:
            'If the system of linear equations 𝑥-2𝑦+𝑧 = -4; 2𝑥+𝛼𝑦+3𝑧 = 5; 3𝑥-𝑦+𝛽𝑧 = 3 has infinitely many solutions, then 12𝛼+13𝛽 is equal to',
        options: ['60', '64', '54', '58'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Trigonometry',
        subTopic: 'Linear Equations',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: [
          'Linear Equations',
          'Infinite Solutions',
          'System of Equations'
        ],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'MATH0352',
        questionText:
            'For α,β,γ ≠ 0. If sin⁻¹α+sin⁻¹β+sin⁻¹γ = π and (α+β+γ)(α−γ+β) = 3αβ, then γ equal to',
        options: ['√3/2', '1/2', '√2/2', '√3-1/2√2'],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Relations and Functions',
        subTopic: 'Inverse Trigonometric Functions',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: [
          'Inverse Trigonometric Functions',
          'Trigonometric Identities',
          'Algebraic Equations'
        ],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'MATH0353',
        questionText:
            'If 𝑓(𝑥) = (4𝑥+3)/(6𝑥-4), 𝑥 ≠ 2/3 and 𝑓𝑜𝑓 (𝑥) = 𝑔(𝑥), where 𝑔:𝑅-{2/3} → 𝑅-{2/3}, then 𝑔𝑜𝑔𝑜𝑔 (4) is equal to',
        options: ['-19/20', '19/20', '-4', '4'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Relations and Functions',
        subTopic: 'Function Composition',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: [
          'Function Composition',
          'Rational Functions',
          'Iterated Functions'
        ],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'MATH0354',
        questionText:
            'Let 𝑔(𝑥) be a linear function and 𝑓(𝑥) = {𝑔(𝑥), 𝑥 ≤ 0; 1/(1+𝑥ˣ), 𝑥 > 0} is continuous at 𝑥 = 0. If 𝑓′(1) = 𝑓(−1), then the value of 𝑔(3) is',
        options: [
          '(1/3)logₑ(4/9)',
          '(1/3)logₑ(4/9)+1',
          '(4/3)logₑ(1/9)−1',
          '(4/3)logₑ(1/9𝑒)'
        ],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Limit, Continuity and Differentiability',
        subTopic: 'Continuity and Differentiability',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Continuity', 'Differentiability', 'Piecewise Functions'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'MATH0355',
        questionText:
            'The area of the region {(𝑥, 𝑦):𝑦² ≤ 4𝑥, 𝑥 < 4, (𝑥𝑦(𝑥-1)(𝑥-2))/((𝑥-3)(𝑥-4)) > 0} is',
        options: ['16/3', '64/3', '8/3', '32/3'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Integral Calculus',
        subTopic: 'Area Calculation',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: [
          'Area Calculation',
          'Integration',
          'Region Bounded by Curves'
        ],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'MATH0356',
        questionText:
            'The solution curve of the differential equation 𝑦(𝑑𝑦/𝑑𝑥) = 𝑥(logₑ 𝑥 - logₑ 𝑦 + 1), 𝑥 > 0, 𝑦 > 0 passing through the point (𝑒, 1) is',
        options: [
          'logₑ(𝑦/𝑒𝑥) = 𝑥',
          'logₑ(𝑦/𝑒𝑥) = 𝑦²',
          'logₑ(𝑥/𝑒𝑦) = 𝑦',
          '2logₑ(𝑥/𝑒𝑦) = 𝑦+1'
        ],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Differential Equations',
        subTopic: 'Differential Equations Solutions',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: [
          'Differential Equations',
          'Solution Curves',
          'Logarithmic Functions'
        ],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'MATH0357',
        questionText:
            'Let 𝑦 = 𝑦(𝑥) be the solution of the differential equation 𝑑𝑦/𝑑𝑥 = (tan𝑥+𝑦)/(sin𝑥(sec𝑥 - sin𝑥tan𝑥)), 𝑥 ∈ (0, π/2) satisfying the condition 𝑦(π/4) = 2. Then, 𝑦(π/3) is',
        options: [
          '√3/2 + logₑ(√3/2)',
          '√3/2 + logₑ(3/2)',
          '√3(1+2logₑ(3))',
          '√3(2+logₑ(3))'
        ],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Differential Equations',
        subTopic: 'First Order Differential Equations',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: [
          'Differential Equations',
          'Initial Value Problems',
          'Trigonometric Functions'
        ],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'MATH0358',
        questionText:
            'Let 𝑎 = 3𝑖 + 𝑗 - 2𝑘, 𝑏 = 4𝑖 + 𝑗 + 7𝑘 and 𝑐 = 𝑖 - 3𝑗 + 4𝑘 be three vectors. If a vector 𝑝 satisfies 𝑝 × 𝑏 = 𝑐 × 𝑏 and 𝑝 ⋅ 𝑎 = 0, then 𝑝 ⋅ (𝑖 - 𝑗 - 𝑘) is equal to',
        options: ['24', '36', '28', '32'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Vector Algebra',
        subTopic: 'Vector Operations',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: [
          'Vector Cross Product',
          'Vector Dot Product',
          'Vector Equations'
        ],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'MATH0359',
        questionText:
            'The distance of the point 𝑄(0, 2, -2) from the line passing through the point 𝑃(5, -4, 3) and perpendicular to the lines 𝑟 = (-3𝑖+2𝑘) + 𝜆(2𝑖+3𝑗+5𝑘), 𝜆 ∈ ℝ and 𝑟 = (𝑖-2𝑗+𝑘) + 𝜇(-𝑖+3𝑗+2𝑘), 𝜇 ∈ ℝ is',
        options: ['√86', '√20', '√54', '√74'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Three Dimensional Geometry',
        subTopic: 'Distance from Line',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['3D Geometry', 'Distance Formula', 'Lines in Space'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'MATH0360',
        questionText:
            'Two marbles are drawn in succession from a box containing 10 red, 30 white, 20 blue and 15 orange marbles, with replacement being made after each drawing. Then the probability, that first drawn marble is red and second drawn marble is white, is',
        options: ['2/25', '4/25', '2/75', '4/75'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Statistics and Probability',
        subTopic: 'Probability',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Probability', 'Independent Events', 'With Replacement'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'MATH0361',
        questionText:
            'Three rotten apples are accidently mixed with fifteen good apples. Assuming the random variable 𝑥 to be the number of rotten apples in a draw of two apples, the variance of 𝑥 is',
        options: ['37/153', '57/153', '47/153', '40/153'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Statistics and Probability',
        subTopic: 'Variance',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Variance', 'Probability Distribution', 'Random Variables'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'MATH0362',
        questionText:
            'If 𝛼 denotes the number of solutions of (1−𝑖)ˣ = 2ˣ and 𝛽 = |𝑧|/arg(𝑧), where 𝑧 = (π(1+𝑖)⁴(1−√π·𝑖) + (√π−𝑖))/(π+𝑖(1+√π·𝑖)), 𝑖 = √−1, then the distance of the point (𝛼, 𝛽) from the line 4𝑥−3𝑦 = 7 is ______',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Complex Numbers and Quadratic Equations',
        subTopic: 'Complex Numbers and Geometry',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: [
          'Complex Numbers',
          'Distance from Line',
          'Complex Equations'
        ],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0363',
        questionText:
            'The total number of words (with or without meaning) that can be formed out of the letters of the word "DISTRIBUTION" taken four at a time, is equal to ______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Permutations and Combinations',
        subTopic: 'Word Formation',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Permutations', 'Combinations', 'Word Problems'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0364',
        questionText:
            'In the expansion of (1+𝑥)(1−𝑥²)(1 + 3/𝑥 + 3/𝑥² + 1/𝑥³), 𝑥 ≠ 0, the sum of the coefficient of 𝑥³ and 𝑥⁻¹³ is equal to ______',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Binomial Theorem and Its Simple Applications',
        subTopic: 'Binomial Expansion',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: [
          'Binomial Expansion',
          'Coefficients',
          'Algebraic Expressions'
        ],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0365',
        questionText:
            'Let the foci and length of the latus rectum of an ellipse 𝑥²/𝑎² + 𝑦²/𝑏² = 1, 𝑎 > 𝑏 be (±5, 0) and √50, respectively. Then, the square of the eccentricity of the hyperbola 𝑥²/𝑏² − 𝑦²/𝑎²𝑏² = 1 equals',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: 'Conic Sections',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Ellipse', 'Hyperbola', 'Eccentricity'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0366',
        questionText:
            'Let 𝐴 = {1, 2, 3, 4} and 𝑅 = {(1, 2), (2, 3), (1, 4)} be a relation on 𝐴. Let 𝑆 be the equivalence relation on 𝐴 such that 𝑅 ⊂ 𝑆 and the number of elements in 𝑆 is 𝑛. Then, the minimum value of 𝑛 is _______',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Sets, Relations and Functions',
        subTopic: 'Equivalence Relations',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Equivalence Relations', 'Set Theory', 'Relations'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0367',
        questionText:
            'Let 𝑓:ℝ → ℝ be a function defined by 𝑓(𝑥) = 4ˣ/(4ˣ+2) and 𝑀 = ∫[𝑓(𝑎) to 𝑓(1−𝑎)] 𝑥sin(4𝑥(1−𝑥)) 𝑑𝑥, 𝑁 = ∫[𝑓(𝑎) to 𝑓(1−𝑎)] sin(4𝑥(1−𝑥)) 𝑑𝑥; 𝑎 ≠ 1/2. If 𝛼𝑀 = 𝛽𝑁, 𝛼, 𝛽 ∈ ℕ, then the least value of 𝛼²+𝛽² is equal to ______',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Integral Calculus',
        subTopic: 'Definite Integrals',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Definite Integrals', 'Integration', 'Natural Numbers'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0368',
        questionText:
            'Let 𝑆 = (−1, ∞) and 𝑓:𝑆 → ℝ be defined as 𝑓(𝑥) = ∫[−1 to 𝑥] 𝑒^(𝑡−1) (2𝑡−1)(5𝑡−2)(7𝑡−3)(122𝑡−1061) 𝑑𝑡. Let 𝑝 = Sum of square of the values of 𝑥, where 𝑓(𝑥) attains local maxima on 𝑆 and 𝑞 = Sum of the values of 𝑥, where 𝑓(𝑥) attains local minima on 𝑆. Then, the value of 𝑝²+2𝑞 is ________',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Differential Equations',
        subTopic: 'Maxima and Minima',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: [
          'Function Composition',
          'Rational Functions',
          'Iterated Functions'
        ],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'MATH0369',
        questionText:
            'If the integral ∫₀^(π/2) sin²𝑥 cos²𝑥 (1+cos²𝑥) 𝑑𝑥 is equal to (𝑛√2)/64, then 𝑛 is equal to ________',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Integral Calculus',
        subTopic: 'Definite Integrals',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: [
          'Definite Integrals',
          'Trigonometric Integrals',
          'Integration'
        ],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0370',
        questionText:
            'Let 𝑎 and 𝑏 be two vectors such that |𝑎| = 1, |𝑏| = 4 and 𝑎⋅𝑏 = 2. If 𝑐 = 2(𝑎×𝑏) - 3𝑏 and the angle between 𝑏 and 𝑐 is 𝛼, then 192sin²𝛼 is equal to _________',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Vector Algebra',
        subTopic: 'Vector Operations',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: [
          'Vector Cross Product',
          'Vector Dot Product',
          'Angle Between Vectors'
        ],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0371',
        questionText:
            'Let 𝑄 and 𝑅 be the feet of perpendiculars from the point 𝑃(𝑎, 𝑎, 𝑎) on the lines 𝑥 = 𝑦, 𝑧 = 1 and 𝑥 = −𝑦, 𝑧 = −1 respectively. If ∠𝑄𝑃𝑅 is a right angle, then 12𝑎² is equal to ________',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Three Dimensional Geometry',
        subTopic: '3D Geometry and Lines',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['3D Geometry', 'Perpendicular Distance', 'Right Angle'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0374',
        questionText:
            'If mass is written as 𝑚 = 𝑘𝑐ᴾ𝐺^(-1/2) ℎ^(1/2), then the value of 𝑃 will be : (Constants have their usual meaning with 𝑘 a dimensionless constant)',
        options: ['1/2', '1/3', '2', '-1/3'],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Units and Measurements',
        subTopic: 'Dimensional Analysis',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: [
          'Dimensional Analysis',
          'Physical Constants',
          'Mass Formula'
        ],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'PHY0375',
        questionText:
            'Projectiles 𝐴 and 𝐵 are thrown at angles of 45° and 60° with vertical respectively from top of a 400 m high tower. If their times of flight are same, the ratio of their speeds of projection 𝑣𝐴:𝑣𝐵 is:',
        options: ['1:√3', '√2:1', '1:2', '1:√2'],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Kinematics',
        subTopic: 'Projectile Motion',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: [
          'Projectile Motion',
          'Time of Flight',
          'Angle of Projection'
        ],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'PHY0376',
        questionText:
            'Three blocks 𝐴, 𝐵 and 𝐶 are pulled on a horizontal smooth surface by a force of 80 N as shown in figure. The tensions 𝑇₁ and 𝑇₂ in the string are respectively:',
        options: ['40N, 64N', '60N, 80N', '88N, 96N', '80N, 100N'],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Laws of Motion',
        subTopic: 'Tension and Forces',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Tension', 'Newton Laws', 'Connected Bodies'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'PHY0377',
        questionText:
            'A block of mass 𝑚 is placed on a surface having vertical cross section given by 𝑦 = 𝑥²/4. If coefficient of friction is 0.5, the maximum height above the ground at which block can be placed without slipping is:',
        options: ['1/4 m', '1/2 m', '1/6 m', '1/3 m'],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Laws of Motion',
        subTopic: 'Friction on Curved Surface',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Friction', 'Curved Surface', 'Maximum Height'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'PHY0378',
        questionText:
            'A block of mass 1 kg is pushed up a surface inclined to horizontal at an angle of 60° by a force of 10 N parallel to the inclined surface as shown in figure. When the block is pushed up by 10 m along inclined surface, the work done against frictional force is : (𝑔 = 10 m s⁻²)',
        options: ['5√3 J', '5 J', '5×10³ J', '10 J'],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Work, Energy and Power',
        subTopic: 'Work Done Against Friction',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Work Done', 'Friction', 'Inclined Plane'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'PHY0379',
        questionText:
            'Escape velocity of a body from earth is 11.2 km s⁻¹. If the radius of a planet be one-third the radius of earth and mass be one-sixth that of earth, the escape velocity from the planet is:',
        options: ['11.2 km s⁻¹', '8.4 km s⁻¹', '4.2 km s⁻¹', '7.9 km s⁻¹'],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Gravitation',
        subTopic: 'Escape Velocity',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: [
          'Escape Velocity',
          'Planetary Parameters',
          'Gravitational Constant'
        ],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'PHY0380',
        questionText:
            'A block of ice at -10 °C is slowly heated and converted to steam at 100 °C. Which of the following curves represent the phenomenon qualitatively:',
        options: [
          'Temperature vs Time',
          'Temperature vs Heat',
          'Heat vs Time',
          'Temperature vs Energy'
        ],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Properties of Solids and Liquids',
        subTopic: 'Phase Transitions',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Phase Transitions', 'Heating Curve', 'Temperature Changes'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'PHY0381',
        questionText:
            'Choose the correct statement for processes 𝐴 & 𝐵 shown in figure.',
        options: [
          '𝑃𝑉^𝛾 = 𝑘 for process 𝐵 and 𝑃𝑉 = 𝑘 for process 𝐴',
          '𝑃𝑉 = 𝑘 for process 𝐵 and 𝐴',
          '𝑃^(𝛾-1) = 𝑘 for process 𝐵 and 𝑇 = 𝑘 for process 𝐴',
          '𝑇^𝛾 = 𝑘 for process 𝐴 and 𝑃𝑉 = 𝑘 for process 𝐵'
        ],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Thermodynamics',
        subTopic: 'Thermodynamic Processes',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: [
          'Thermodynamic Processes',
          'Adiabatic Process',
          'Isothermal Process'
        ],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'PHY0382',
        questionText:
            'If three moles of monoatomic gas (𝛾 = 5/3) is mixed with two moles of a diatomic gas (𝛾 = 7/5), the value of adiabatic exponent 𝛾 for the mixture is:',
        options: ['1.75', '1.40', '1.52', '1.35'],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Kinetic Theory of Gases',
        subTopic: 'Adiabatic Exponent',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: [
          'Adiabatic Exponent',
          'Gas Mixtures',
          'Specific Heat Capacity'
        ],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'PHY0383',
        questionText:
            'A particle of charge -𝑞 and mass 𝑚 moves in a circle of radius 𝑟 around an infinitely long line charge of linear density +𝜆. Then time period will be given as: (Consider 𝑘 as Coulomb constant)',
        options: [
          '𝑇² = (4𝜋²𝑚𝑟³)/(2𝑘𝜆𝑞)',
          '𝑇 = 2𝜋𝑟√(𝑚/(2𝑘𝜆𝑞))',
          '𝑇 = (1/(2𝜋𝑟))√(2𝑘𝜆𝑞/𝑚)',
          '𝑇 = (1/2𝜋)√(2𝑘𝜆𝑞/𝑚)'
        ],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Electrostatics',
        subTopic: 'Charged Particle Motion',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Circular Motion', 'Electrostatic Force', 'Time Period'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'PHY0384',
        questionText:
            'When a potential difference 𝑉 is applied across a wire of resistance 𝑅, it dissipates energy at a rate 𝑊. If the wire is cut into two halves and these halves are connected mutually parallel across the same supply, the energy dissipation rate will become:',
        options: ['1/4 W', '1/2 W', '2 W', '4 W'],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Current Electricity',
        subTopic: 'Power Dissipation',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Power Dissipation', 'Parallel Resistance', 'Wire Cutting'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'PHY0385',
        questionText:
            'An alternating voltage 𝑉(𝑡) = 220sin(100𝜋𝑡) volt is applied to a purely resistive load of 50 𝛺. The time taken for the current to rise from half of the peak value to the peak value is:',
        options: ['5 ms', '3.3 ms', '7.2 ms', '2.2 ms'],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Electromagnetic Induction and Alternating Currents',
        subTopic: 'AC Circuit Analysis',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['AC Circuits', 'Time Calculation', 'Peak Current'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'PHY0386',
        questionText:
            'Match List I with List II: List I (Laws) - List II (Equations) A. Gauss law of magnetostatics, B. Faraday law of electromagnetic induction, C. Ampere law, D. Gauss law of electrostatics',
        options: [
          'A-I, B-III, C-IV, D-II',
          'A-III, B-IV, C-I, D-II',
          'A-IV, B-II, C-III, D-I',
          'A-II, B-III, C-IV, D-I'
        ],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Electromagnetic Induction and Alternating Currents',
        subTopic: 'Maxwell Equations',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Maxwell Equations', 'Electromagnetic Laws', 'Matching'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'PHY0387',
        questionText:
            'A beam of unpolarised light of intensity 𝐼₀ is passed through a polaroid 𝐴 and then through another polaroid 𝐵 which is oriented so that its principal plane makes an angle of 45° relative to that of 𝐴. The intensity of emergent light is :',
        options: ['𝐼₀/4', '𝐼₀', '𝐼₀/2', '𝐼₀/8'],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Optics',
        subTopic: 'Polarization',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Polarization', 'Malus Law', 'Light Intensity'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'PHY0388',
        questionText:
            'If the total energy transferred to a surface in time 𝑡 is 6.48×10⁵ J, then the magnitude of the total momentum delivered to this surface for complete absorption will be :',
        options: [
          '2.46×10⁻³ kg m s⁻¹',
          '2.16×10⁻³ kg m s⁻¹',
          '1.58×10⁻³ kg m s⁻¹',
          '4.32×10⁻³ kg m s⁻¹'
        ],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Dual Nature of Matter and Radiation',
        subTopic: 'Momentum of Radiation',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: [
          'Radiation Pressure',
          'Momentum',
          'Energy-Momentum Relation'
        ],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'PHY0389',
        questionText:
            'For the photoelectric effect, the maximum kinetic energy 𝐸𝑘 of the photoelectrons is plotted against the frequency (𝑣) of the incident photons as shown in figure. The slope of the graph gives',
        options: [
          'Ratio of Planck constant to electric charge',
          'Work function of the metal',
          'Charge of electron',
          'Planck constant'
        ],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Dual Nature of Matter and Radiation',
        subTopic: 'Photoelectric Effect',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Photoelectric Effect', 'Planck Constant', 'Kinetic Energy'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'PHY0390',
        questionText:
            'An electron revolving in 𝑛th Bohr orbit has magnetic moment 𝜇𝑛. If 𝜇𝑛 ∝ 𝑛^𝑥, the value of 𝑥 is:',
        options: ['2', '1', '3', '0'],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Atoms and Nuclei',
        subTopic: 'Bohr Model',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Bohr Model', 'Magnetic Moment', 'Quantum Number'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'PHY0391',
        questionText:
            'In a nuclear fission reaction of an isotope of mass 𝑀, three similar daughter nuclei of same mass are formed. The speed of a daughter nuclei in terms of mass defect 𝛥𝑀 will be :',
        options: [
          '2𝑐√(𝛥𝑀/𝑀)',
          '𝛥𝑀𝑐²/3',
          '𝑐√(2𝛥𝑀/𝑀)',
          '𝑐√(3𝛥𝑀/𝑀)'
        ],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Atoms and Nuclei',
        subTopic: 'Nuclear Fission',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Nuclear Fission', 'Mass Defect', 'Energy Conservation'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'PHY0392',
        questionText:
            'In the given circuit, the voltage across load resistance 𝑅𝐿 is:',
        options: ['8.75 V', '9.00 V', '8.50 V', '14.00 V'],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Electronic Devices',
        subTopic: 'Circuit Analysis',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Circuit Analysis', 'Voltage Division', 'Load Resistance'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'PHY0393',
        questionText:
            'If 50 Vernier divisions are equal to 49 main scale divisions of a travelling microscope and one smallest reading of main scale is 0.5 mm, the Vernier constant of travelling microscope is:',
        options: ['0.1 mm', '0.1 cm', '0.01 cm', '0.01 mm'],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Experimental Skills',
        subTopic: 'Vernier Caliper',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Vernier Constant', 'Least Count', 'Microscope'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'PHY0394',
        questionText:
            'A vector has magnitude same as that of 𝐴 = 3𝑖 + 4𝑗 and is parallel to 𝐵 = 4𝑖 + 3𝑗. The 𝑥 and 𝑦 components of this vector in first quadrant are 𝑥 and 3 respectively where x = ____.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Kinematics',
        subTopic: 'Vector Components',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Vector Components', 'Magnitude', 'Parallel Vectors'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0395',
        questionText:
            'Two discs of moment of inertia 𝐼₁ = 4 kg m² and 𝐼₂ = 2 kg m² about their central axes & normal to their planes, rotating with angular speeds 10 rad s⁻¹ & 4 rad s⁻¹ respectively are brought into contact face to face with their axes of rotation coincident. The loss in kinetic energy of the system in the process is _________J.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Rotational Motion',
        subTopic: 'Conservation of Angular Momentum',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Angular Momentum', 'Kinetic Energy Loss', 'Rotating Discs'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0396',
        questionText:
            'A big drop is formed by coalescing 1000 small identical drops of water. If 𝐸₁ be the total surface energy of 1000 small drops of water and 𝐸₂ be the surface energy of single big drop of water, the 𝐸₁:𝐸₂ is 𝑥:1, where 𝑥 = ________.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Properties of Solids and Liquids',
        subTopic: 'Surface Energy',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Surface Energy', 'Drop Coalescence', 'Surface Area'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0397',
        questionText:
            'A simple pendulum is placed at a place where its distance from the earth surface is equal to the radius of the earth. If the length of the string is 4 m, then the time period of small oscillations will be _________s. [take 𝑔 = 𝜋² m s⁻²]',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Oscillations and Waves',
        subTopic: 'Pendulum Time Period',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Simple Pendulum', 'Time Period', 'Gravitational Variation'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0398',
        questionText:
            'A point source is emitting sound waves of intensity 16×10⁻⁸ W m⁻² at the origin. The difference in intensity (magnitude only) at two points located at distances of 2 m and 4 m from the origin respectively will be ________×10⁻⁸ W m⁻².',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Oscillations and Waves',
        subTopic: 'Sound Intensity',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Sound Intensity', 'Inverse Square Law', 'Point Source'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0399',
        questionText:
            'Two identical charged spheres are suspended by strings of equal lengths. The strings make an angle of 37° with each other. When suspended in a liquid of density 0.7 g cm⁻³, the angle remains same. If density of material of the sphere is 1.4 g cm⁻³, the dielectric constant of the liquid is _____ (tan37° = 3/4)',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Electrostatics',
        subTopic: 'Dielectric Constant',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Dielectric Constant', 'Charged Spheres', 'Buoyancy'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0400',
        questionText:
            'Two resistances of 100𝛺 and 200𝛺 are connected in series with a battery of 4 V and negligible internal resistance. A voltmeter is used to measure voltage across 100𝛺 resistance, which gives reading as 1 V. The resistance of voltmeter must be _______ 𝛺.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Current Electricity',
        subTopic: 'Voltmeter Resistance',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: [
          'Voltmeter Resistance',
          'Circuit Analysis',
          'Voltage Measurement'
        ],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0401',
        questionText:
            'The current of 5 A flows in a square loop of sides 1 m is placed in air. The magnetic field at the centre of the loop is X√2 ×10⁻⁷ T. The value of X is _________.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Magnetic Effects of Current and Magnetism',
        subTopic: 'Magnetic Field of Square Loop',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Magnetic Field', 'Square Loop', 'Biot-Savart Law'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0402',
        questionText:
            'A power transmission line feeds input power at 2.3 kV to a step down transformer with its primary winding having 3000 turns. The output power is delivered at 230 V by the transformer. The current in the primary of the transformer is 5 A and its efficiency is 90%. The output current of transformer is ____A.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Electromagnetic Induction and Alternating Currents',
        subTopic: 'Transformer Calculations',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Transformer', 'Efficiency', 'Current Calculation'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0403',
        questionText:
            'In an experiment to measure the focal length (𝑓) of a convex lens, the magnitude of object distance(𝑥) and the image distance(𝑦) are measured with reference to the focal point of the lens. The 𝑦-𝑥 plot is shown in figure. The focal length of the lens is _____cm.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Optics',
        subTopic: 'Lens Focal Length',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Convex Lens', 'Focal Length', 'Lens Formula'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0374',
        questionText:
            'Given below are two statements: Statement - I: Along the period, the chemical reactivity of the element gradually increases from group 1 to group 18. Statement - II: The nature of oxides formed by group 1 element is basic while that of group 17 elements is acidic. In the light of above statements, choose the most appropriate from the questions given below:',
        options: [
          'Both statement I and Statement II are true',
          'Statement I is true but Statement II is False',
          'Statement I is false but Statement II is true',
          'Both Statement I and Statement II are false'
        ],
        correctAnswerIndex: 2,
        subject: 'Chemistry',
        topic: 'Classification of Elements and Periodicity in Properties',
        subTopic: 'Periodic Trends',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Periodic Trends', 'Chemical Reactivity', 'Oxide Nature'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'CHEM0375',
        questionText:
            'Given below are two statements: Statement-I: Since fluorine is more electronegative than nitrogen, the net dipole moment of NF₃ is greater than NH₃. Statement-II: In NH₃, the orbital dipole due to lone pair and the dipole moment of N-H bonds are in opposite direction, but in NF₃ the orbital dipole due to lone pair and dipole moments of N-F bonds are in same direction. In the light of the above statements. Choose the most appropriate from the options given below.',
        options: [
          'Statement I is true but Statement II is false',
          'Both Statement I and Statement II are false',
          'Both statement I and Statement II are true',
          'Statement I is false but Statement II is true'
        ],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'Chemical Bonding and Molecular Structure',
        subTopic: 'Dipole Moment',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Dipole Moment', 'Electronegativity', 'Molecular Geometry'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'CHEM0376',
        questionText:
            'Given below are two statements: One is labelled as Assertion A and the other is labelled as Reason R. Assertion A: H₂Te is more acidic than H₂S. Reason R: Bond dissociation enthalpy of H₂Te is lower than H₂S. In the light of the above statements. Choose the most appropriate from the options given below.',
        options: [
          'Both A and R are true but R is NOT the correct explanation of A',
          'Both A and R are true and R is the correct explanation of A',
          'A is false but R is true',
          'A is true but R is false'
        ],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'Classification of Elements and Periodicity in Properties',
        subTopic: 'Acidity Trends',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: [
          'Acidity',
          'Bond Dissociation Enthalpy',
          'Hydride Properties'
        ],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'CHEM0377',
        questionText: 'IUPAC name of following compound is',
        options: [
          '2-Aminopentanenitrile',
          '2-Aminobutanenitrile',
          '3-Aminobutanenitrile',
          '3-Aminopropanenitrile'
        ],
        correctAnswerIndex: 2,
        subject: 'Chemistry',
        topic: 'Some Basic Principles of Organic Chemistry',
        subTopic: 'IUPAC Nomenclature',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: [
          'IUPAC Nomenclature',
          'Organic Compounds',
          'Functional Groups'
        ],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'CHEM0378',
        questionText:
            'Which among the following purification methods is based on the principle of "Solubility" in two different solvents?',
        options: [
          'Column Chromatography',
          'Sublimation',
          'Distillation',
          'Differential Extraction'
        ],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Purification and Characterisation of Organic Compounds',
        subTopic: 'Purification Methods',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Purification Methods', 'Solubility', 'Extraction'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'CHEM0379',
        questionText: 'The correct stability order of carbocations is',
        options: [
          '(CH₃)₃C⁺ > CH₃-CH₂⁺ > CH₃CH₂⁺ > CH₃⁺',
          'CH₃⁺ > CH₃CH₂⁺ > CH₃-CH₂⁺ > (CH₃)₃C⁺',
          '(CH₃)₃C⁺ > CH₃CH₂⁺ > CH₃-CH₂⁺ > CH₃⁺',
          'CH₃⁺ > CH₃-CH₂⁺ > CH₃CH₂⁺ > (CH₃)₃C⁺'
        ],
        correctAnswerIndex: 2,
        subject: 'Chemistry',
        topic: 'Some Basic Principles of Organic Chemistry',
        subTopic: 'Carbocation Stability',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: [
          'Carbocation Stability',
          'Hyperconjugation',
          'Inductive Effect'
        ],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'CHEM0380',
        questionText:
            'Product A and B formed in the following set of reactions are:',
        options: ['Option 1', 'Option 2', 'Option 3', 'Option 4'],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'Organic Compounds Containing Oxygen',
        subTopic: 'Organic Reactions',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: [
          'Organic Reactions',
          'Product Formation',
          'Reaction Mechanism'
        ],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'CHEM0381',
        questionText:
            'If a substance A dissolves in solution of a mixture of B and C with their respective number of moles as 𝑛𝐴, 𝑛𝐵 and 𝑛𝐶, mole fraction of C in the solution is:',
        options: [
          '𝑛𝐶/(𝑛𝐴×𝑛𝐵×𝑛𝐶)',
          '𝑛𝐶/(𝑛𝐴+𝑛𝐵+𝑛𝐶)',
          '𝑛𝐶/(𝑛𝐴-𝑛𝐵-𝑛𝐶)',
          '𝑛𝐵/(𝑛𝐴+𝑛𝐵)'
        ],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'Solutions',
        subTopic: 'Mole Fraction',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: [
          'Mole Fraction',
          'Solution Composition',
          'Concentration Terms'
        ],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'CHEM0382',
        questionText:
            'The solution from the following with highest depression in freezing point/lowest freezing point is',
        options: [
          '180 g of acetic acid dissolved in 1 L of aqueous solution',
          '180 g of acetic acid dissolved in benzene',
          '180 g of benzoic acid dissolved in benzene',
          '180 g of glucose dissolved in water'
        ],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Solutions',
        subTopic: 'Freezing Point Depression',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: [
          'Freezing Point Depression',
          'Colligative Properties',
          'Solution Concentration'
        ],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'CHEM0383',
        questionText:
            'Reduction potential of ions are given below: ClO₄⁻ E° = 1.19 V; IO₄⁻ E° = 1.65 V; BrO₄⁻ E° = 1.74 V The correct order of their oxidizing power is:',
        options: [
          'ClO₄⁻ > IO₄⁻ > BrO₄⁻',
          'BrO₄⁻ > IO₄⁻ > ClO₄⁻',
          'BrO₄⁻ > ClO₄⁻ > IO₄⁻',
          'IO₄⁻ > BrO₄⁻ > ClO₄⁻'
        ],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'Redox Reactions and Electrochemistry',
        subTopic: 'Oxidizing Power',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Oxidizing Power', 'Reduction Potential', 'Periodate Ions'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'CHEM0384',
        questionText:
            'Choose the correct statements about the hydrides of group 15 elements. A. The stability of the hydrides decreases in the order NH₃ > PH₃ > AsH₃ > SbH₃ > BiH₃ B. The reducing ability of the hydrides increases in the order NH₃ < PH₃ < AsH₃ < SbH₃ < BiH₃ C. Among the hydrides, NH₃ is strong reducing agent while BiH₃ is mild reducing agent. D. The basicity of the hydrides increases in the order NH₃ < PH₃ < AsH₃ < SbH₃ < BiH₃',
        options: [
          'B and C only',
          'C and D only',
          'A and B only',
          'A and D only'
        ],
        correctAnswerIndex: 2,
        subject: 'Chemistry',
        topic: 'p-Block Elements',
        subTopic: 'Group 15 Hydrides',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Group 15 Hydrides', 'Stability Trends', 'Reducing Ability'],
        questionType: 'singleCorrect',
      ),

      Question(
        id: 'CHEM0385',
        questionText:
            'The orange colour of K₂Cr₂O₇ and purple colour of KMnO₄ is due to',
        options: [
          'Charge transfer transition in both.',
          'd → d transition in KMnO₄ and charge transfer transitions in K₂Cr₂O₇.',
          'd → d transition in K₂Cr₂O₇ and charge transfer transitions in KMnO₄.',
          'd → d transition in both.'
        ],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'd- and f-Block Elements',
        subTopic: 'Colour of Compounds',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Charge Transfer', 'd-d Transition'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0386',
        questionText:
            'A and B formed in the following reactions are: CrO₂Cl₂ + 4NaOH → A + 2NaCl + 2H₂O; A + 2HCl + 2H₂O → B + 3H₂O',
        options: [
          'A = Na₂CrO₄, B = CrO₅',
          'A = Na₂Cr₂O₄, B = CrO₄',
          'A = Na₂Cr₂O₇, B = CrO₃',
          'A = Na₂Cr₂O₇, B = CrO₅'
        ],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'd- and f-Block Elements',
        subTopic: 'Chromium Compounds',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Chromyl Chloride', 'Chemical Reactions'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0387',
        questionText:
            'Alkaline oxidative fusion of MnO₂ gives "A" which on electrolytic oxidation in alkaline solution produces B. A and B respectively are:',
        options: [
          'Mn₂O₇ and MnO₄⁻',
          'MnO₄²⁻ and MnO₄⁻',
          'Mn₂O₃ and MnO₄²⁻',
          'MnO₄²⁻ and Mn₂O₇'
        ],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'd- and f-Block Elements',
        subTopic: 'Manganese Compounds',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Oxidative Fusion', 'Electrolytic Oxidation'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0388',
        questionText: 'The molecule/ion with square pyramidal shape is:',
        options: ['Ni(CN)₄²⁻', 'PCl₄', 'BrF₅', 'PF₅'],
        correctAnswerIndex: 2,
        subject: 'Chemistry',
        topic: 'Chemical Bonding and Molecular Structure',
        subTopic: 'Molecular Shapes',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['VSEPR Theory', 'Square Pyramidal'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0389',
        questionText:
            'The coordination geometry around the manganese in decacarbonyldimanganese(0) is:',
        options: [
          'Octahedral',
          'Trigonal bipyramidal',
          'Square pyramidal',
          'Square planar'
        ],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Coordination Compounds',
        subTopic: 'Coordination Geometry',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Metal Carbonyls', 'Coordination Number'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0390',
        questionText:
            'Given below are two statements: Statement I: High concentration of strong nucleophilic reagent with secondary alkyl halides which do not have bulky substituents will follow SN2 mechanism. Statement II: A secondary alkyl halide when treated with a large excess of ethanol follows SN1 mechanism. In the light of the above statements, choose the most appropriate from the questions given below:',
        options: [
          'Statement I is true but Statement II is false.',
          'Statement I is false but Statement II is true.',
          'Both statement I and Statement II are false.',
          'Both statement I and Statement II are true.'
        ],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Organic Compounds Containing Halogens',
        subTopic: 'Reaction Mechanisms',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['SN1 Mechanism', 'SN2 Mechanism'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0391',
        questionText:
            'Salicylaldehyde is synthesized from phenol, when reacted with',
        options: ['CHCl₃', 'CO₂, NaOH', 'CCl₄, NaOH', 'HCCl₃, NaOH'],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Organic Compounds Containing Oxygen',
        subTopic: 'Phenol Reactions',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Reimer-Tiemann Reaction', 'Salicylaldehyde Synthesis'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0392',
        questionText:
            'm-chlorobenzaldehyde on treatment with 50% KOH solution yields',
        options: [
          'm-chlorobenzyl alcohol',
          'm-chlorobenzoic acid',
          'm-hydroxybenzaldehyde',
          'm-chlorobenzyl alcohol and m-chlorobenzoic acid'
        ],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Organic Compounds Containing Oxygen',
        subTopic: 'Cannizzaro Reaction',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Cannizzaro Reaction', 'Aldehyde Reactions'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0393',
        questionText:
            'The products A and B formed in the following reaction scheme are respectively',
        options: [
          'Nitrobenzene and Aniline',
          'Nitrobenzene and Azoxybenzene',
          'Nitrosobenzene and Azoxybenzene',
          'Nitrosobenzene and Hydrazobenzene'
        ],
        correctAnswerIndex: 2,
        subject: 'Chemistry',
        topic: 'Organic Compounds Containing Nitrogen',
        subTopic: 'Nitro Compounds',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Reduction Reactions', 'Nitro Compounds'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0394',
        questionText:
            'Number of spectral lines obtained in He⁺ spectra, when an electron makes transition from fifth excited state to first excited state will be',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Atomic Structure',
        subTopic: 'Spectral Lines',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Hydrogen-like Atoms', 'Spectral Transitions'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0395',
        questionText:
            'Two reactions are given below: 2Fe(s) + 3/2 O₂(g) → Fe₂O₃(s), ΔH° = -822 kJ/mol; C(s) + 1/2 O₂(g) → CO(g), ΔH° = -110 kJ/mol. Then enthalpy change for following reaction: 3C(s) + Fe₂O₃(s) → 2Fe(s) + 3CO(g)',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Chemical Thermodynamics',
        subTopic: 'Enthalpy Change',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Hess Law', 'Enthalpy Calculation'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0396',
        questionText:
            'The pH of an aqueous solution containing 1M benzoic acid (pKa = 4.20) and 1M sodium benzoate is 4.5. The volume of benzoic acid solution in 300 mL of this buffer solution is __________ mL.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Equilibrium',
        subTopic: 'Buffer Solutions',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Henderson-Hasselbalch Equation', 'Buffer Capacity'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0397',
        questionText:
            'Total number of species from the following which can undergo disproportionation reaction ___________. H₂O₂, ClO⁻, P₄, Cl₂, Ag, Cu⁺, F₂, NO₂, K⁺',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Redox Reactions and Electrochemistry',
        subTopic: 'Disproportionation',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Disproportionation', 'Redox Reactions'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0398',
        questionText:
            'Number of geometrical isomers possible for the given structure is/are _________.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Hydrocarbons',
        subTopic: 'Geometrical Isomerism',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Geometrical Isomerism', 'Coordination Compounds'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0399',
        questionText:
            'NO₂ required for a reaction is produced by decomposition of N₂O₅ in CCl₄ as by equation: 2N₂O₅(g) → 4NO₂(g) + O₂(g). The initial concentration of N₂O₅ is 3 mol L⁻¹ and it is 2.75 mol L⁻¹ after 30 minutes. The rate of formation of NO₂ is x × 10⁻³ mol L⁻¹ min⁻¹, value of x is ________.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Chemical Kinetics',
        subTopic: 'Rate of Reaction',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Rate Calculation', 'Decomposition Kinetics'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0400',
        questionText:
            'Number of complexes which show optical isomerism among the following is _________. [cis-Cr(ox)₂Cl₂]³⁻, [Co(en)₃]³⁺, [cis-Pt(en)₂Cl₂]²⁺, [cis-Co(en)₂Cl₂]⁺, [trans-Pt(en)₂Cl₂]²⁺, [trans-Cr(ox)₂Cl₂]³⁻',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Coordination Compounds',
        subTopic: 'Optical Isomerism',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Optical Isomerism', 'Coordination Complexes'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0401',
        questionText:
            '2-chlorobutane + Cl₂ → C₄H₈Cl₂ (isomers). Total number of optically active isomers shown by C₄H₈Cl₂, obtained in the above reaction is ________.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Organic Compounds Containing Halogens',
        subTopic: 'Optical Isomerism',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Optical Activity', 'Chiral Centers'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0402',
        questionText:
            'Number of metal ions characterized by flame test among the following is _________. Sr²⁺, Ba²⁺, Ca²⁺, Cu²⁺, Zn²⁺, Co²⁺, Fe²⁺',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Principles Related to Practical Chemistry',
        subTopic: 'Flame Test',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Flame Test', 'Metal Ion Identification'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0403',
        questionText:
            'The total number of correct statements, regarding the nucleic acids is _________. A. RNA is regarded as the reserve of genetic information. B. DNA molecule self-duplicates during cell division C. DNA synthesizes proteins in the cell. D. The message for the synthesis of particular proteins is present in DNA E. Identical DNA strands are transferred to daughter cells.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Biomolecules',
        subTopic: 'Nucleic Acids',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['DNA', 'RNA', 'Genetic Information'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0372',
        questionText:
            'If z is a complex number, then the number of common roots of the equation z¹⁹⁸⁵ + z¹⁰⁰ + 1 = 0 and z³ + 2z² + 2z + 1 = 0, is equal to :',
        options: ['1', '2', '0', '3'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Complex Numbers and Quadratic Equations',
        subTopic: 'Complex Roots',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Complex Roots', 'Polynomial Equations'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0373',
        questionText:
            'Let a and b be two distinct positive real numbers. Let 11th term of a GP, whose first term is a and third term is b, is equal to pth term of another GP, whose first term is a and fifth term is b. Then p is equal to',
        options: ['20', '25', '21', '24'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Sequence and Series',
        subTopic: 'Geometric Progression',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Geometric Progression', 'Term Calculation'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0374',
        questionText:
            'Suppose 28 - p, p, 70 - α, α are the coefficient of four consecutive terms in the expansion of (1 + x)ⁿ. Then the value of 2α - 3p equals',
        options: ['7', '10', '4', '6'],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Binomial Theorem and Its Simple Applications',
        subTopic: 'Binomial Coefficients',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Binomial Coefficients', 'Consecutive Terms'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0375',
        questionText:
            'For α, β ∈ (0, π/2), let 3sin(α + β) = 2sin(α - β) and a real number k be such that tanα = k tanβ. Then the value of k is equal to',
        options: ['-5', '5/2', '2/3', '-3/2'],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Trigonometry',
        subTopic: 'Trigonometric Equations',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Trigonometric Identities', 'Tangent Ratio'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0376',
        questionText:
            'If x² - y² + 2hxy + 2gx + 2fy + c = 0 is the locus of a point, which moves such that it is always equidistant from the lines x + 2y + 7 = 0 and 2x - y + 8 = 0, then the value of g + c + h - f equals',
        options: ['14', '6', '8', '29'],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: 'Locus',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Distance from Lines', 'Locus'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0377',
        questionText:
            'Let A(α, 0) and B(0, β) be the points on the line 5x + 7y = 50. Let the point P divide the line segment AB internally in the ratio 7:3. Let 3x - 25 = 0 be a directrix of the ellipse E: x²/a² + y²/b² = 1 and the corresponding focus be S. If from S, the perpendicular on the x-axis passes through P, then the length of the latus rectum of E is equal to',
        options: ['25/3', '32/9', '25/9', '32/5'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: 'Ellipse',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Ellipse Properties', 'Directrix', 'Focus'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0378',
        questionText:
            'Let P be a point on the hyperbola H: x²/9 - y²/4 = 1, in the first quadrant such that the area of triangle formed by P and the two foci of H is 2√13. Then, the square of the distance of P from the origin is',
        options: ['18', '26', '22', '20'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: 'Hyperbola',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Hyperbola', 'Foci', 'Area of Triangle'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0379',
        questionText:
            'Let R = [[x, 0, 0], [0, y, 0], [0, 0, z]] be a non-zero 3×3 matrix, where x sinθ = y sin(θ + 2π/3) = z sin(θ + 4π/3) ≠ 0, θ ∈ (0, 2π). For a square matrix M, let Trace M denote the sum of all the diagonal entries of M. Then, among the statements: I. Trace(R) = 0 (II) If Trace(adj(adj R)) = 0, then R has exactly one non-zero entry.',
        options: [
          'Both (I) and (II) are true',
          'Only (II) is true',
          'Neither (I) nor (II) is true',
          'Only (I) is true'
        ],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Matrices and Determinants',
        subTopic: 'Matrix Properties',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Trace', 'Adjoint', 'Matrix Properties'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0380',
        questionText:
            'Consider the system of linear equations x + y + z = 5, x + 2y + λ²z = 9 and x + 3y + λz = μ, where λ, μ ∈ R. Then, which of the following statement is NOT correct?',
        options: [
          'System has infinite number of solution if λ = 1',
          'System is inconsistent if λ = 1 and μ ≠ 13',
          'System has unique solution if λ ≠ 1 and μ ≠ 13',
          'System is consistent if λ ≠ 1 and μ = 13'
        ],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Matrices and Determinants',
        subTopic: 'System of Equations',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Linear Systems', 'Consistency', 'Unique Solution'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0381',
        questionText:
            'If the domain of the function f(x) = logₑ(4x² + x - 3) + cos⁻¹(2x - 1)/(x + 2) is (α, β), then the value of 5β - 4α is equal to',
        options: ['10', '12', '11', '9'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Sets, Relations and Functions',
        subTopic: 'Domain of Function',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Domain', 'Logarithmic Function', 'Inverse Trigonometric'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0382',
        questionText:
            'Let f: R → R be a function defined f(x) = x and g(x) = f(f(f(f(x)))) then 18∫₀¹ x²g(x)/(1 + x⁴) dx',
        options: ['33', '36', '42', '39'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Integral Calculus',
        subTopic: 'Definite Integration',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Function Composition', 'Definite Integral'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0383',
        questionText:
            'Let a and b be real constants such that the function f defined by f(x) = {x² + 3x + a, x ≤ 1; bx + 2, x > 1} be differentiable on R. Then, the value of ∫₋₂² f(x) dx equals',
        options: ['15/6', '19/6', '21/6', '17/6'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Limit, Continuity and Differentiability',
        subTopic: 'Differentiability',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Differentiability', 'Piecewise Function', 'Integration'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0384',
        questionText:
            'Let f: R - {0} → R be a function satisfying f(x/y) = f(x)/f(y) for all x, y, f(y) ≠ 0. If f′(1) = 2024, then',
        options: [
          'xf′(x) - 2024f(x) = 0',
          'xf′(x) + 2024f(x) = 0',
          'xf′(x) + f(x) = 2024',
          'xf′(x) - 2023f(x) = 0'
        ],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Differential Equations',
        subTopic: 'Functional Equations',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Functional Equation', 'Differentiation'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0385',
        questionText:
            'Let f(x) = (x + 3)²(x - 2)³, x ∈ [-4, 4]. If M and m are the maximum and minimum values of f, respectively in [-4, 4], then the value of M - m is :',
        options: ['600', '392', '608', '108'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Limit, Continuity and Differentiability',
        subTopic: 'Maxima Minima',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Maxima Minima', 'Polynomial Function'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0386',
        questionText:
            'Let y = f(x) be a thrice differentiable function in (-5, 5). Let the tangents to the curve y = f(x) at (1, f(1)) and (3, f(3)) make angles π/6 and π/4, respectively with positive x-axis. If 27∫₁³ (f′(t))² + f″(t) dt = α + β√3 where α, β are integers, then the value of α + β equals',
        options: ['-14', '26', '-16', '36'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Integral Calculus',
        subTopic: 'Definite Integration',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Tangent Slope', 'Definite Integral'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0387',
        questionText:
            'Let f: R → R be defined f(x) = ae²ˣ + beˣ + cx. If f(0) = -1, f′(logₑ2) = 21 and ∫₀^{logₑ4} (f(x) - cx) dx = 39/2, then the value of |a + b + c| equals:',
        options: ['16', '10', '12', '8'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Integral Calculus',
        subTopic: 'Definite Integration',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Exponential Function', 'Integration', 'Differentiation'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0388',
        questionText:
            'Let a = i + αj + βk, α, β ∈ R. Let a vector b be such that the angle between a and b is π/4 and |b| = 6. If a · b = 3√2, then the value of (α² + β²)|a × b|² is equal to',
        options: ['90', '75', '95', '85'],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Vector Algebra',
        subTopic: 'Vector Operations',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Dot Product', 'Cross Product', 'Vector Magnitude'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0389',
        questionText:
            'Let a and b be two vectors such that |b| = 1 and |b × a| = 2. Then |b × (a - b)|² is equal to',
        options: ['3', '5', '1', '4'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Vector Algebra',
        subTopic: 'Vector Operations',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Cross Product', 'Vector Magnitude'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0390',
        questionText:
            'Let L₁: r = (i - j + 2k) + λ(i - j + 2k), λ ∈ R, L₂: r = (j - k) + μ(3i + j + pk), μ ∈ R and L₃: r = δ(li + mj + nk), δ ∈ R be three lines such that L₁ is perpendicular to L₂ and L₃ is perpendicular to both L₁ and L₂. Then the point which lies on L₃ is',
        options: ['(-1, 7, 4)', '(-1, -7, 4)', '(1, 7, -4)', '(1, -7, 4)'],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Three Dimensional Geometry',
        subTopic: 'Lines in Space',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Line Equations', 'Perpendicular Lines'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0391',
        questionText:
            'Bag A contains 3 white, 7 red balls and bag B contains 3 white, 2 red balls. One bag is selected at random and a ball is drawn from it. The probability of drawing the ball from the bag A, if the ball drawn in white, is :',
        options: ['1/4', '1/9', '1/3', '3/10'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Statistics and Probability',
        subTopic: 'Conditional Probability',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Conditional Probability', 'Bayes Theorem'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0392',
        questionText:
            'The number of real solutions of the equation x(x² + 3|x| + 5|x - 1| + 6|x - 2|) = 0 is ______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Complex Numbers and Quadratic Equations',
        subTopic: 'Absolute Value Equations',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Absolute Value', 'Real Solutions'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0393',
        questionText:
            'In an examination of mathematics paper, there are 20 questions of equal marks and the question paper is divided into three sections: A, B and C. A student is required to attempt total 15 questions taking at least 4 questions from each section. If section A has 8 questions, section B has 6 questions and section C has 6 questions, then the total number of ways a student can select 15 questions is _________.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Permutations and Combinations',
        subTopic: 'Combinations',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Combinations', 'Selection with Restrictions'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0394',
        questionText:
            'Let Sₙ be the sum to n-terms of an arithmetic progression 3, 7, 11, …, if 40 < 6/(n(n+1)) ∑ₖ₌₁ⁿ Sₖ < 42, then n equals ____________.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Sequence and Series',
        subTopic: 'Arithmetic Progression',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Arithmetic Progression', 'Sum of Series'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0395',
        questionText:
            'Let α = ∑ₖ₌₀ⁿ ⁿCₖ/(k+1)² and β = ∑ₖ₌₀ⁿ⁻¹ ⁿCₖ ⁿCₖ₊₁/(k+2). If 5α = 6β, then n equals',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Binomial Theorem and Its Simple Applications',
        subTopic: 'Binomial Coefficients',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Binomial Coefficients', 'Summation'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0396',
        questionText:
            'Consider two circles C₁: x² + y² = 25 and C₂: (x - α)² + y² = 16, where α ∈ (5, 9). Let the angle between the two radii (one to each circle) drawn from one of the intersection points of C₁ and C₂ be sin⁻¹(√63/8). If the length of common chord of C₁ and C₂ is β, then the value of (αβ)² equals _________.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: 'Circles',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Circle Geometry', 'Common Chord'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0397',
        questionText:
            'If the variance σ² of the given data is k then the value of k is ______ {where [.] denotes the greatest integer function}',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Statistics and Probability',
        subTopic: 'Variance',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Variance', 'Statistical Measures'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0398',
        questionText:
            'The number of symmetric relations defined on the set {1, 2, 3, 4} which are not reflexive is _______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Sets, Relations and Functions',
        subTopic: 'Relations',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Symmetric Relations', 'Reflexive Relations'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0399',
        questionText:
            'The area of the region enclosed by the parabola (y - 2)² = (x - 1), the line x - 2y + 4 = 0 and the positive coordinate axes is __________.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Integral Calculus',
        subTopic: 'Area Calculation',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Area Integration', 'Parabola', 'Line'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0400',
        questionText:
            'Let Y = Y(X) be a curve lying in the first quadrant such that the area enclosed by the line Y - y = Y′(x)(X - x) and the co-ordinate axes, where (x, y) is any point on the curve, is always -y²/Y′(x) + 1, Y′(x) ≠ 0. If Y(1) = 1, then 12Y(1/2) equals ________.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Differential Equations',
        subTopic: 'Area Calculation',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Area Integration', 'Parabola', 'Line'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0401',
        questionText:
            'Let a line passing through the point (-1, 2, 3) intersect the lines L₁: (x-1)/3 = (y-2)/2 = (z-3)/-2 at M(α, β, γ) and L₂: (x+2)/-3 = (y-2)/-2 = (z-1)/4 at N(a, b, c). Then the value of (α + β + γ)²/(a + b + c)² equals ________________.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Three Dimensional Geometry',
        subTopic: 'Lines in Space',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Line Intersection', 'Coordinates'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0404',
        questionText:
            'Match List-I with List-II. List-I: A. Coefficient of viscosity, B. Surface Tension, C. Angular momentum, D. Rotational kinetic energy. List-II: I. [ML²T⁻²], II. [ML²T⁻¹], III. [ML⁻¹T⁻¹], IV. [ML⁰T⁻²]',
        options: [
          'A-II, B-I, C-IV, D-III',
          'A-I, B-II, C-III, D-IV',
          'A-III, B-IV, C-II, D-I',
          'A-IV, B-III, C-II, D-I'
        ],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Units and Measurements',
        subTopic: 'Dimensional Analysis',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Dimensional Formula', 'Physical Quantities'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0405',
        questionText:
            'A particle of mass m projected with a velocity u making an angle of 30° with the horizontal. The magnitude of angular momentum of the projectile about the point of projection when the particle is at its maximum height h is:',
        options: ['√3 mu³/16g', '√3 mu²/2g', 'mu³/√2g', 'zero'],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Kinematics',
        subTopic: 'Projectile Motion',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Angular Momentum', 'Projectile Motion'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0406',
        questionText:
            'All surfaces shown in figure are assumed to be frictionless and the pulleys and the string are light. The acceleration of the block of mass 2 kg is:',
        options: ['g', 'g/3', 'g/2', 'g/4'],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Laws of Motion',
        subTopic: 'Pulley Systems',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Newton Laws', 'Pulley Mechanics'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0407',
        questionText:
            'A particle is placed at the point A of a frictionless track ABC as shown in figure. It is gently pushed towards right. The speed of the particle when it reaches the point B is: (Take g = 10 m s⁻²)',
        options: ['20 m s⁻¹', '√10 m s⁻¹', '2√10 m s⁻¹', '10 m s⁻¹'],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Work, Energy and Power',
        subTopic: 'Conservation of Energy',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Energy Conservation', 'Potential to Kinetic Energy'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0408',
        questionText:
            'A spherical body of mass 100 g is dropped from a height of 10 m from the ground. After hitting the ground, the body rebounds to a height of 5 m. The impulse of force imparted by the ground to the body is given by: (given g = 9.8 m s⁻²)',
        options: [
          '4.32 kg m s⁻¹',
          '43.2 kg m s⁻¹',
          '23.9 kg m s⁻¹',
          '2.39 kg m s⁻¹'
        ],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Laws of Motion',
        subTopic: 'Impulse',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Impulse', 'Collision'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0409',
        questionText:
            'The gravitational potential at a point above the surface of earth is −5.12×10⁷ J kg⁻¹ and the acceleration due to gravity at that point is 6.4 m s⁻². Assume that the mean radius of earth to be 6400 km. The height of this point above the earth surface is:',
        options: ['1600 km', '540 km', '1200 km', '1000 km'],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Gravitation',
        subTopic: 'Gravitational Potential',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Gravitational Potential', 'Acceleration due to Gravity'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0410',
        questionText:
            'Young modulus of material of a wire of length L and cross-sectional area A is Y. If the length of the wire is doubled and cross-sectional area is halved then Young modulus will be:',
        options: ['Y', '4Y', 'Y/4', '2Y'],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Properties of Solids and Liquids',
        subTopic: 'Elasticity',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Young Modulus', 'Material Property'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0411',
        questionText:
            'At which temperature the r.m.s. velocity of a hydrogen molecule equal to that of an oxygen molecule at 47°C?',
        options: ['80 K', '−73 K', '4 K', '20 K'],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Kinetic Theory of Gases',
        subTopic: 'RMS Velocity',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['RMS Velocity', 'Kinetic Theory'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0412',
        questionText:
            'Two thermodynamical process are shown in the figure. The molar heat capacity for process A and B are C_A and C_B. The molar heat capacity at constant pressure and constant volume are represented by C_P and C_V, respectively. Choose the correct statement.',
        options: [
          'C_P > C_B > C_V',
          'C_A = 0 and C_B = ∞',
          'C_P > C_V > C_A = C_B',
          'C_A > C_P > C_V'
        ],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Thermodynamics',
        subTopic: 'Heat Capacity',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Molar Heat Capacity', 'Thermodynamic Processes'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0413',
        questionText:
            'The electrostatic potential due to an electric dipole at a distance r varies as:',
        options: ['r', '1/r²', '1/r³', '1/r'],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Electrostatics',
        subTopic: 'Electric Dipole',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Electric Dipole', 'Potential Variation'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0414',
        questionText:
            'A potential divider circuit is shown in figure. The output voltage V₀ is',
        options: ['4 V', '2 mV', '0.5 V', '12 mV'],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Current Electricity',
        subTopic: 'Potential Divider',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Potential Divider', 'Voltage Division'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0415',
        questionText:
            'An electric toaster has resistance of 60 Ω at room temperature (27°C). The toaster is connected to a 220 V supply. If the current flowing through it reaches 2.75 A, the temperature attained by toaster is around: (if α = 2×10⁻⁴ °C⁻¹)',
        options: ['694°C', '1235°C', '1694°C', '1667°C'],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Current Electricity',
        subTopic: 'Temperature Dependence of Resistance',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Resistance Temperature Dependence', 'Ohms Law'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0416',
        questionText:
            'Two insulated circular loop A and B radius a carrying a current of I in the anti clockwise direction as shown in figure. The magnitude of the magnetic induction at the centre will be:',
        options: ['√2μ₀I/a', 'μ₀I/2a', 'μ₀I/√2a', '2μ₀I/a'],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Magnetic Effects of Current and Magnetism',
        subTopic: 'Magnetic Field due to Circular Loop',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Magnetic Field', 'Circular Loop'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0417',
        questionText:
            'A series LR circuit connected with an ac source E = (25 sin1000t) V has a power factor of 1/√2. If the source of emf is changed to E = (20 sin2000t) V, the new power factor of the circuit will be:',
        options: ['1/√2', '1/√3', '1/√5', '1/√7'],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Electromagnetic Induction and Alternating Currents',
        subTopic: 'Power Factor',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['LR Circuit', 'Power Factor'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0418',
        questionText:
            'Primary coil of a transformer is connected to 220 V AC. Primary and secondary turns of the transforms are 100 and 10 respectively. Secondary coil of transformer is connected to two series resistances as shown in figure. The output voltage (V₀) is:',
        options: ['7 V', '15 V', '44 V', '22 V'],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Electromagnetic Induction and Alternating Currents',
        subTopic: 'Transformer',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Transformer', 'Voltage Division'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0419',
        questionText:
            'The electric field of an electromagnetic wave in free space is represented as E = E₀ cos(ωt - kz)î. The corresponding magnetic induction vector will be:',
        options: [
          'B = (E₀/C) cos(ωt - kz) ĵ',
          'B = (E₀/C) cos(ωt - kz) ĵ',
          'B = (E₀/C) cos(ωt + kz) ĵ',
          'B = (E₀/C) cos(ωt + kz) ĵ'
        ],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Electromagnetic Waves',
        subTopic: 'Wave Propagation',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Electromagnetic Waves', 'Wave Equations'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0420',
        questionText:
            'The diffraction pattern of a light of wavelength 400 nm diffracting from a slit of width 0.2 mm is focused on the focal plane of a convex lens of focal length 100 cm. The width of the 1st secondary maxima will be:',
        options: ['2 mm', '2 cm', '0.02 mm', '0.2 mm'],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Optics',
        subTopic: 'Diffraction',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Single Slit Diffraction', 'Secondary Maxima'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0421',
        questionText:
            'The work function of a substance is 3.0 eV. The longest wavelength of light that can cause the emission of photoelectrons from this substance is approximately:',
        options: ['215 nm', '414 nm', '400 nm', '200 nm'],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Dual Nature of Matter and Radiation',
        subTopic: 'Photoelectric Effect',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Work Function', 'Threshold Wavelength'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0422',
        questionText:
            'The ratio of the magnitude of the kinetic energy to the potential energy of an electron in the 5th excited state of a hydrogen atom is:',
        options: ['4', '1/4', '1', '1/2'],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Atoms and Nuclei',
        subTopic: 'Hydrogen Atom',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Hydrogen Atom', 'Energy Levels'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0423',
        questionText:
            'A Zener diode of breakdown voltage 10 V is used as a voltage regulator as shown in the figure. The current through the Zener diode is',
        options: ['50 mA', '0', '30 mA', '20 mA'],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Electronic Devices',
        subTopic: 'Zener Diode',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Zener Diode', 'Voltage Regulation'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0424',
        questionText:
            'The displacement and the increase in the velocity of a moving particle in the time interval of t to (t+1) s are 125 m and 50 m s⁻¹, respectively. The distance travelled by the particle in (t+2)th s is ___________ m.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Kinematics',
        subTopic: 'Distance and Displacement',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Uniform Acceleration', 'Distance Calculation'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0425',
        questionText:
            'Consider a disc of mass 5 kg, radius 2 m, rotating with angular velocity of 10 rad s⁻¹ about an axis perpendicular to the plane of rotation. An identical disc is kept gently over the rotating disc along the same axis. The energy dissipated so that both the discs continue to rotate together without slipping is _________ J.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Rotational Motion',
        subTopic: 'Conservation of Angular Momentum',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Angular Momentum Conservation', 'Energy Dissipation'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0426',
        questionText:
            'Each of three blocks P, Q and R shown in figure has a mass of 3 kg. Each of the wire A and B has cross-sectional area 0.005 cm² and Young modulus 2×10¹¹ N m⁻². Neglecting friction, the longitudinal strain on wire B is _____ ×10⁻⁴. (Take g = 10 m s⁻²)',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Properties of Solids and Liquids',
        subTopic: 'Young Modulus',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Young Modulus', 'Strain Calculation'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0427',
        questionText:
            'In a closed organ pipe, the frequency of fundamental note is 30 Hz. A certain amount of water is now poured in the organ pipe so that the fundamental frequency is increased to 110 Hz. If the organ pipe has a cross-sectional area of 2 cm², the amount of water poured in the organ tube is ________ g. (Take speed of sound in air is 330 m s⁻¹)',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Oscillations and Waves',
        subTopic: 'Organ Pipe',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Closed Organ Pipe', 'Fundamental Frequency'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0428',
        questionText:
            'A capacitor of capacitance C and potential V has energy E. It is connected to another capacitor of capacitance 2C and potential 2V. Then the loss of energy is xE, where x is _______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Electrostatics',
        subTopic: 'Capacitor Energy',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Capacitor Energy', 'Energy Loss'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0429',
        questionText:
            'Two cells are connected in opposition as shown. Cell E₁ is of 8 V emf and 2 Ω internal resistance; the cell E₂ is of 2 V emf and 4 Ω internal resistance. The terminal potential difference of cell E₂ is ______ V.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Current Electricity',
        subTopic: 'Cell Circuits',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Internal Resistance', 'Terminal Voltage'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0430',
        questionText:
            'A ceiling fan having 3 blades of length 80 cm each is rotating with an angular velocity of 1200 rpm. The magnetic field of earth in that region is 0.5 G and angle of dip is 30°. The emf induced across the blades is Nπ×10⁻⁵ V. The value of N is _______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Magnetic Effects of Current and Magnetism',
        subTopic: 'Electromagnetic Induction',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Motional EMF', 'Earth Magnetic Field'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0431',
        questionText:
            'The horizontal component of earth magnetic field at a place is 3.5×10⁻⁵ T. A very long straight conductor carrying current of √2 A in the direction from South east to North West is placed. The force per unit length experienced by the conductor is ________×10⁻⁶ N m⁻¹.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Magnetic Effects of Current and Magnetism',
        subTopic: 'Magnetic Force',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Magnetic Force on Conductor', 'Earth Magnetic Field'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0432',
        questionText:
            'The distance between object and its two times magnified real image as produced by a convex lens is 45 cm. The focal length of the lens used is ________ cm.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Optics',
        subTopic: 'Lens Formula',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Lens Formula', 'Magnification'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0433',
        questionText:
            'An electron of hydrogen atom on an excited state is having energy Eₙ = −0.85 eV. The maximum number of allowed transitions to lower energy level is _______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Atoms and Nuclei',
        subTopic: 'Hydrogen Spectrum',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Hydrogen Atom', 'Spectral Transitions'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0404',
        questionText:
            'Given below are two statements: Statement-I: The orbitals having same energy are called as degenerate orbitals. Statement-II: In hydrogen atom, 3p and 3d orbitals are not degenerate orbitals. In the light of the above statements, choose the most appropriate answer from the options given',
        options: [
          'Statement-I is true but Statement-II is false',
          'Both Statement-I and Statement-II are true.',
          'Both Statement-I and Statement-II are false',
          'Statement-I is false but Statement-II is true'
        ],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Atomic Structure',
        subTopic: 'Orbital Degeneracy',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Degenerate Orbitals', 'Hydrogen Atom'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0405',
        questionText:
            'Given below are the two statements: one is labeled as Assertion (A) and the other is labeled as Reason (R). Assertion (A): There is a considerable increase in covalent radius from N to P. However from As to Bi only a small increase in covalent radius is observed. Reason (R): covalent and ionic radii in a particular oxidation state increases down the group. In the light of the above statement, choose the most appropriate answer from the options given below:',
        options: [
          '(A) is false but (R) is true',
          'Both (A) and (R) are true but (R) is not the correct explanation of (A)',
          '(A) is true but (R) is false',
          'Both (A) and (R) are true and (R) is the correct explanation of (A)'
        ],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'Classification of Elements and Periodicity in Properties',
        subTopic: 'Atomic Radius',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Covalent Radius', 'Periodic Trends'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0406',
        questionText:
            'Match List-I with List-II. List I (Molecule): A. BrF₅, B. H₂O, C. ClF₃, D. SF₄. List II (Shape): i. T-shape, ii. See saw, iii. Bent, iv. Square pyramidal',
        options: [
          '(A)-I, (B)-II, (C)-IV, (D)-III',
          '(A)-II, (B)-I, (C)-III, (D)-IV',
          '(A)-III, (B)-IV, (C)-I, (D)-II',
          '(A)-IV, (B)-III, (C)-I, (D)-II'
        ],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Chemical Bonding and Molecular Structure',
        subTopic: 'Molecular Shapes',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['VSEPR Theory', 'Molecular Geometry'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0407',
        questionText: 'Structure of 4-Methylpent-2-enal is:',
        options: [
          'CH₃-CH=CH-CH(CH₃)-CHO',
          'CH₃-CH₂-CH=CH-CH(CH₃)-CHO',
          '(CH₃)₂CH-CH=CH-CHO',
          'CH₃-CH₂-CH₂-CH=CH-CHO'
        ],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Organic Compounds Containing Oxygen',
        subTopic: 'Aldehydes',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['IUPAC Nomenclature', 'Aldehydes'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0408',
        questionText: 'Example of vinylic halide is',
        options: ['CH₂=CH-Cl', 'CH₂=CH-CH₂-Cl', 'C₆H₅-Cl', 'CH₃-CH₂-Cl'],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Organic Compounds Containing Halogens',
        subTopic: 'Vinylic Halides',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Vinylic Halides', 'Halogen Compounds'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0409',
        questionText:
            'Given below are two statement one is labeled as Assertion (A) and the other is labeled as Reason (R). Assertion (A): CH₂=CH-CH₂-Cl is an example of allyl halide. Reason (R): Allyl halides are the compounds in which the halogen atom is attached to sp² hybridised carbon atom. In the light of the two above statements, choose the most appropriate answer from the options given below:',
        options: [
          '(A) is true but (R) is false',
          'Both (A) and (R) are true but (R) is not the correct explanation of A',
          '(A) is false but (R) is true',
          'Both (A) and (R) are true and (R) is the correct explanation of (A)'
        ],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Organic Compounds Containing Halogens',
        subTopic: 'Allyl Halides',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Allyl Halides', 'Hybridization'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0410',
        questionText: 'Which of the following molecule/species is most stable?',
        options: ['CH₃⁺', 'CH₃⁻', 'CH₃', 'CH₄'],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Hydrocarbons',
        subTopic: 'Carbon Compounds Stability',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Carbon Compounds', 'Stability'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0411',
        questionText:
            'Compound A formed in the following reaction reacts with B gives the product C. Find out A and B.',
        options: [
          'A = CH₃-C≡C-Na⁺, B = CH₃-CH₂-CH₂-Br',
          'A = CH₃-CH=CH₂, B = CH₃-CH₂-CH₂-Br',
          'A = CH₃-CH₂-CH₃, B = CH₃-C≡CH',
          'A = CH₃-C≡C-Na⁺, B = CH₃-CH₂-CH₃'
        ],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Hydrocarbons',
        subTopic: 'Alkynes',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Alkynes', 'Chemical Reactions'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0412',
        questionText:
            'In the given reactions identify the reagent A and reagent B',
        options: [
          'A-CrO₃, B-CrO₃',
          'A-CrO₃, B-CrO₂Cl₂',
          'A-CrO₂Cl₂, B-CrO₂Cl₂',
          'A-CrO₂Cl₂, B-CrO₃'
        ],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'Organic Compounds Containing Oxygen',
        subTopic: 'Oxidation Reactions',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Oxidation Reagents', 'Chromium Compounds'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0413',
        questionText:
            'What happens to freezing point of benzene when small quantity of naphthalene is added to benzene?',
        options: [
          'Increases',
          'Remains unchanged',
          'First decreases and then increases',
          'Decreases'
        ],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Solutions',
        subTopic: 'Colligative Properties',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Freezing Point Depression', 'Colligative Properties'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0414',
        questionText: 'Diamagnetic Lanthanoid ions are:',
        options: [
          'Nd³⁺ and Eu³⁺',
          'La³⁺ and Ce⁴⁺',
          'Nd³⁺ and Ce⁴⁺',
          'Lu³⁺ and Eu³⁺'
        ],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'd- and f-Block Elements',
        subTopic: 'Lanthanoids',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Lanthanoids', 'Magnetic Properties'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0415',
        questionText:
            'Match List-I with List-II. List I (Species): A. Cr²⁺, B. Mn⁺, C. Ni²⁺, D. V⁺. List II (Electronic distribution): i. 3d⁸, ii. 3d³4s¹, iii. 3d⁴, iv. 3d⁵4s¹',
        options: [
          '(A)-I, (B)-II, (C)-III, (D)-IV',
          '(A)-III, (B)-IV, (C)-I, (D)-II',
          '(A)-IV, (B)-III, (C)-I, (D)-II',
          '(A)-II, (B)-I, (C)-IV, (D)-III'
        ],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'd- and f-Block Elements',
        subTopic: 'Electronic Configuration',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Electronic Configuration', 'Transition Metals'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0416',
        questionText:
            'Choose the correct Statements from the following: (A) Ethane-1,2-diamine is a chelating ligand. (B) Metallic aluminium is produced by electrolysis of aluminium oxide in presence of cryolite. (C) Cyanide ion is used as ligand for leaching of silver. (D) Phosphine act as a ligand in Wilkinson catalyst. (E) The stability constants of Ca²⁺ and Mg²⁺ are similar with EDTA complexes.',
        options: [
          '(B), (C), (E) only',
          '(C), (D), (E) only',
          '(A), (B), (C) only',
          '(A), (D), (E) only'
        ],
        correctAnswerIndex: 2,
        subject: 'Chemistry',
        topic: 'Coordination Compounds',
        subTopic: 'Coordination Chemistry',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Coordination Compounds', 'Metallurgy'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0417',
        questionText:
            'Aluminium chloride in acidified aqueous solution forms an ion having geometry',
        options: [
          'Octahedral',
          'Square Planar',
          'Tetrahedral',
          'Trigonal bipyramidal'
        ],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Coordination Compounds',
        subTopic: 'Coordination Geometry',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Coordination Geometry', 'Aluminium Compounds'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0418',
        questionText: 'This reduction reaction is known as:',
        options: [
          'Rosenmund reduction',
          'Wolff-Kishner reduction',
          'Stephen reduction',
          'Etard reduction'
        ],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Organic Compounds Containing Oxygen',
        subTopic: 'Reduction Reactions',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Reduction Reactions', 'Named Reactions'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0419',
        questionText:
            'Following is a confirmatory test for aromatic primary amines. Identify reagent (A) and (B)',
        options: [
          'A = NaNO₂ + HCl, B = β-naphthol',
          'A = CHCl₃ + KOH, B = Aniline',
          'A = Br₂ water, B = NaOH',
          'A = FeCl₃, B = KMnO₄'
        ],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Organic Compounds Containing Nitrogen',
        subTopic: 'Amine Tests',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Diazotization', 'Azo Dye Test'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0420',
        questionText:
            'The final product A, formed in the following multistep reaction sequence is:',
        options: ['Benzaldehyde', 'Benzoic acid', 'Benzyl alcohol', 'Phenol'],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'Organic Compounds Containing Nitrogen',
        subTopic: 'Reaction Sequences',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Reaction Mechanism', 'Organic Synthesis'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0421',
        questionText:
            'Given below are two statements: Statement-I: The gas liberated on warming a salt with dil H₂SO₄, turns a piece of paper dipped in lead acetate into black, it is a confirmatory test for sulphide ion. Statement-II: In statement-I the colour of paper turns black because of formation of lead sulphite. In the light of the above statements, choose the most appropriate answer from the options given below:',
        options: [
          'Both Statement-I and Statement-II are false',
          'Statement-I is false but Statement-II is true',
          'Statement-I is true but Statement-II is false',
          'Both Statement-I and Statement-II are true.'
        ],
        correctAnswerIndex: 2,
        subject: 'Chemistry',
        topic: 'Principles Related to Practical Chemistry',
        subTopic: 'Qualitative Analysis',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Sulfide Test', 'Lead Acetate Test'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0422',
        questionText:
            'The Lassaigne extract is boiled with dil HNO₃ before testing for halogens because,',
        options: [
          'AgCN is soluble in HNO₃',
          'Silver halides are soluble in HNO₃',
          'Ag₂S is soluble in HNO₃',
          'Na₂S and NaCN are decomposed by HNO₃'
        ],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Purification and Characterisation of Organic Compounds',
        subTopic: 'Lassaigne Test',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Lassaigne Test', 'Halogen Test'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0423',
        questionText:
            'Sugar which does not give reddish brown precipitate with Fehling reagent is:',
        options: ['Sucrose', 'Lactose', 'Glucose', 'Maltose'],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Biomolecules',
        subTopic: 'Carbohydrates',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Fehling Test', 'Reducing Sugars'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0424',
        questionText:
            '0.05 cm thick coating of silver is deposited on a plate of 0.05 m² area. The number of silver atoms deposited on plate are _______ × 10²³. (At mass Ag = 108, d = 7.9 g cm⁻³) Round off to the nearest integer.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Some Basic Concepts in Chemistry',
        subTopic: 'Mole Concept',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Mole Calculation', 'Density', 'Atomic Mass'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0425',
        questionText:
            'If IUPAC name of an element is "Unununnium" then the element belongs to nth group of periodic table. The value of n is _______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Classification of Elements and Periodicity in Properties',
        subTopic: 'IUPAC Nomenclature',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['IUPAC Naming', 'Periodic Table Groups'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0426',
        questionText:
            'The total number of molecular orbitals formed from 2s and 2p atomic orbitals of a diatomic molecule',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Chemical Bonding and Molecular Structure',
        subTopic: 'Molecular Orbitals',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Molecular Orbital Theory', 'Atomic Orbitals'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0427',
        questionText:
            'An ideal gas undergoes a cyclic transformation starting from the point A and coming back to the same point by tracing the path A → B → C → A as shown in the diagram. The total work done in the process is _____ J.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Thermodynamics',
        subTopic: 'Cyclic Process',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Cyclic Process', 'Work Done'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0428',
        questionText:
            'The pH at which Mg(OH)₂ [Ksp = 1×10⁻¹¹] begins to precipitate from a solution containing 0.10M Mg²⁺ ions is ______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Equilibrium',
        subTopic: 'Solubility Product',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Solubility Product', 'Precipitation'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0429',
        questionText:
            '2MnO₄⁻ + bI⁻ + cH₂O → xI₂ + yMnO₂ + zOH⁻. If the above equation is balanced with integer coefficients, the value of z is ________.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Redox Reactions and Electrochemistry',
        subTopic: 'Balancing Equations',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Redox Balancing', 'Coefficient Calculation'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0430',
        questionText:
            'On a thin layer chromatographic plate, an organic compound moved by 3.5 cm, while the solvent moved by 5 cm. The retardation factor of the organic compound is _____________ × 10⁻¹',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Purification and Characterisation of Organic Compounds',
        subTopic: 'Chromatography',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['TLC', 'Retardation Factor'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0431',
        questionText:
            'The mass of sodium acetate (CH₃COONa) required to prepare 250 mL of 0.35M aqueous solution is _____ g. (Molar mass of CH₃COONa is 82.02 g mol⁻¹) Round off to the nearest integer.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Solutions',
        subTopic: 'Molarity Calculation',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Molarity', 'Mass Calculation'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0432',
        questionText:
            'The rate of first order reaction is 0.04 mol L⁻¹ s⁻¹ at 10 minutes and 0.03 mol L⁻¹ s⁻¹ at 20 minutes after initiation. Half life of the reaction is ______ minutes. (Given log2 = 0.3010, log3 = 0.4771) Round off your answer to the nearest integer.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Chemical Kinetics',
        subTopic: 'Half Life',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['First Order Kinetics', 'Half Life Calculation'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0433',
        questionText:
            'The compound formed by the reaction of ethanal with semicarbazide contains _______ number of nitrogen atoms.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Organic Compounds Containing Oxygen',
        subTopic: 'Carbonyl Compounds',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Semicarbazone Formation', 'Nitrogen Count'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0402',
        questionText:
            'If z = x + iy, xy ≠ 0, satisfies the equation z² + iz = 0, then |z²| is equal to:',
        options: ['9', '1', '4', '1/4'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Complex Numbers and Quadratic Equations',
        subTopic: 'Complex Equations',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Complex Numbers', 'Modulus'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0403',
        questionText:
            'Let Sₙ denote the sum of first n terms of an arithmetic progression. If S₂₀ = 790 and S₁₀ = 145, then S₁₅ − S₅ is:',
        options: ['395', '390', '405', '410'],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Sequence and Series',
        subTopic: 'Arithmetic Progression',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Arithmetic Progression', 'Sum Calculation'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0404',
        questionText:
            'If 2sin³x + sin²x cosx + 4sinx − 4 = 0 has exactly 3 solutions in the interval [0, nπ/2], n ∈ N, then the roots of the equation x² + nx + (n−3) = 0 belong to:',
        options: ['(0,∞)', '(−∞,0)', '(−√17/2, √17/2)', 'Z'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Trigonometry',
        subTopic: 'Trigonometric Equations',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Trigonometric Equations', 'Roots Analysis'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0405',
        questionText:
            'A line passing through the point A(9,0) makes an angle of 30° with the positive direction of x-axis. If this line is rotated about A through an angle of 15° in the clockwise direction, then its equation in the new position is',
        options: [
          'y = (√3−2)(x−9)',
          'x = (√3−2)(y−9)',
          'y = (√3+2)(x−9)',
          'x = (√3+2)(y−9)'
        ],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: 'Line Equations',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Line Rotation', 'Slope Calculation'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0406',
        questionText:
            'If the circles (x+1)² + (y+2)² = r² and x² + y² − 4x − 4y + 4 = 0 intersect at exactly two distinct points, then',
        options: ['5 < r < 9', '0 < r < 7', '3 < r < 7', '1 < r < 7/2'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: 'Circle Intersection',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Circle Geometry', 'Intersection Conditions'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0407',
        questionText:
            'The maximum area of a triangle whose one vertex is at (0,0) and the other two vertices lie on the curve y = −2x² + 54 at points (x, y) and (−x, y) where y > 0 is:',
        options: ['88', '122', '92', '108'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Limit, Continuity and Differentiability',
        subTopic: 'Maxima Minima',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Area Maximization', 'Parabola'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0408',
        questionText:
            'If the length of the minor axis of ellipse is equal to half of the distance between the foci, then the eccentricity of the ellipse is:',
        options: ['√5/3', '√3/2', '1/√3', '2/√5'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: 'Ellipse Properties',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Ellipse', 'Eccentricity'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0409',
        questionText:
            'Let f: [−π, π] → R be a differentiable function such that f(0) = 1/2. If limₓ→₀ (∫₀ˣ f(t)dt)/(eˣ²−1) = α, then 8α² is equal to:',
        options: ['16', '2', '1', '4'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Integral Calculus',
        subTopic: 'Limits and Integration',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['L Hospital Rule', 'Definite Integral'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0410',
        questionText:
            'Let M denote the median of the following frequency distribution. Class: 0-4, 4-8, 8-12, 12-16, 16-20 Frequency: 3, 9, 10, 8, 6 Then 20M is equal to:',
        options: ['416', '104', '52', '208'],
        correctAnswerIndex: 3,
        subject: 'Mathematics',
        topic: 'Statistics and Probability',
        subTopic: 'Median Calculation',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Frequency Distribution', 'Median'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0411',
        questionText:
            'If f(x) = |3+2cos4x 2sin4x sin²2x; 2sin4x 3+2cos4x sin²2x; sin²2x sin²2x 3+2sin4x| then 1/5 f′(0) is equal to:',
        options: ['0', '1', '2', '6'],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Matrices and Determinants',
        subTopic: 'Determinant Differentiation',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Determinant', 'Differentiation'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0412',
        questionText:
            'Consider the system of linear equation x+y+z = 4μ, x+2y+2λz = 10μ, x+3y+4λ²z = μ²+15, where λ,μ ∈ R. Which one of the following statements is NOT correct?',
        options: [
          'The system has unique solution if λ ≠ 1/2 and μ ≠ 1',
          'The system is inconsistent if λ = 1/2 and μ ≠ 1,15',
          'The system has infinite number of solutions if λ = 1/2 and μ = 15',
          'The system is consistent if λ ≠ 1/2'
        ],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Matrices and Determinants',
        subTopic: 'System of Equations',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Linear Systems', 'Consistency'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0413',
        questionText:
            'If the domain of the function f(x) = cos⁻¹(2−|x|) + (logₑ(3−x))⁻¹ is [−α,β)−{γ}, then α+β+γ is equal to:',
        options: ['12', '9', '11', '8'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Sets, Relations and Functions',
        subTopic: 'Domain of Function',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Domain', 'Inverse Trigonometric', 'Logarithmic'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0414',
        questionText:
            'Let g: R → R be a non constant twice differentiable such that g′(1/2) = g′(3/2). If a real valued function f is defined as f(x) = 1/2[g(x) + g(2−x)], then which of the following is true?',
        options: [
          'f′′(x) = 0 for atleast two x in (1/2,3/2)',
          'f′′(x) = 0 for exactly one x in (1/2,3/2)',
          'f′′(x) = 0 for no x in (1/2,3/2)',
          'f′(3/2) + f′(1/2) = 1'
        ],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Limit, Continuity and Differentiability',
        subTopic: 'Differentiation',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Second Derivative', 'Rolle Theorem'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0415',
        questionText: 'The value of limₙ→∞ ∑ₖ₌₁ⁿ n³/[(n²+k²)(n²+3k²)] is:',
        options: ['π/8', '13π/8', '13/8', 'π/4'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Integral Calculus',
        subTopic: 'Limit of Sum',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Limit of Sum', 'Definite Integral'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0416',
        questionText:
            'The area (in square units) of the region bounded by the parabola y² = 4(x−2) and the line y = 2x−8.',
        options: ['8', '9', '6', '7'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Integral Calculus',
        subTopic: 'Area Calculation',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Area Between Curves', 'Parabola and Line'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0417',
        questionText:
            'Let y = y(x) be the solution of the differential equation secx dy + {2(1−x)tanx + x(2−x)}dx = 0 such that y(0) = 2. Then y(2) is equal to:',
        options: ['2', '2{1−sin(2)}', '2{sin(2)+1}', '1'],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Differential Equations',
        subTopic: 'First Order DE',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Differential Equation', 'Initial Value'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0418',
        questionText:
            'Let A(2,3,5) and C(−3,4,−2) be opposite vertices of a parallelogram ABCD if the diagonal BD = i + 2j + 3k then the area of the parallelogram is equal to',
        options: ['1/2 √410', '1/2 √474', '1/2 √586', '1/2 √306'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Vector Algebra',
        subTopic: 'Parallelogram Area',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Vector Geometry', 'Area Calculation'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0419',
        questionText:
            'Let a = a₁i + a₂j + a₃k and b = b₁i + b₂j + b₃k be two vectors such that |a| = 1; a·b = 2 and |b| = 4. If c = 2(a×b) − 3b, then the angle between b and c is equal to:',
        options: ['cos⁻¹(2/√3)', 'cos⁻¹(−1/√3)', 'cos⁻¹(−√3/2)', 'cos⁻¹(2/3)'],
        correctAnswerIndex: 2,
        subject: 'Mathematics',
        topic: 'Vector Algebra',
        subTopic: 'Vector Angles',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Dot Product', 'Cross Product', 'Angle Between Vectors'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0420',
        questionText:
            'Let (α,β,γ) be the foot of perpendicular from the point (1,2,3) on the line (x+3)/5 = (y−1)/2 = (z+4)/3. then 19(α+β+γ) is equal to:',
        options: ['102', '101', '99', '100'],
        correctAnswerIndex: 1,
        subject: 'Mathematics',
        topic: 'Three Dimensional Geometry',
        subTopic: 'Foot of Perpendicular',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['3D Geometry', 'Perpendicular Distance'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0421',
        questionText:
            'Two integers x and y are chosen with replacement from the set {0,1,2,3,…..,10}. Then the probability that |x−y| > 5 is:',
        options: ['30/121', '62/121', '60/121', '31/121'],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Statistics and Probability',
        subTopic: 'Probability',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Probability', 'Absolute Difference'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'MATH0422',
        questionText:
            'Let α,β be roots of equation x² − 70x + λ = 0, where λ, λ ∉ Z. If λ assumes the minimum possible value, then (√(α−1) + √(β−1))(|α−β|)/(λ+35) is equal to:',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Complex Numbers and Quadratic Equations',
        subTopic: 'Quadratic Roots',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Quadratic Equations', 'Roots', 'Minimum Value'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0423',
        questionText:
            'Let α = 1² + 4² + 8² + 13² + 19² + 26² + … up to 10 terms and β = ∑₁⁰ n⁴. If 4α − β = 55k + 40, then k is equal to _______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Sequence and Series',
        subTopic: 'Series Sum',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Series Summation', 'Pattern Recognition'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0424',
        questionText:
            'Number of integral terms in the expansion of {7^(1/2) + 11^(1/6)}⁸²⁴ is equal to ______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Binomial Theorem and Its Simple Applications',
        subTopic: 'Binomial Expansion',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Binomial Theorem', 'Integral Terms'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0425',
        questionText:
            'Let the latus rectum of the hyperbola x²/9 − y²/b² = 1 subtend an angle of π/3 at the centre of the hyperbola. If b² is equal to l/m (1+√n), where l and m are co-prime numbers, then l² + m² + n² is equal to __________.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Coordinate Geometry',
        subTopic: 'Hyperbola',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Hyperbola', 'Latus Rectum', 'Angle Subtended'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0426',
        questionText:
            'A group of 40 students appeared in an examination of 3 subjects - mathematics, physics & chemistry. It was found that all students passed in at least one of the subjects, 20 students passed in mathematics, 25 students passed in physics, 16 students passed in chemistry, at most 11 students passed in both mathematics and physics, at most 15 students passed in both physics and chemistry, at most 15 students passed in both mathematics and chemistry. The maximum number of students passed in all the three subjects is _____.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Sets, Relations and Functions',
        subTopic: 'Set Theory',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Set Theory', 'Venn Diagram', 'Maximum Intersection'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0427',
        questionText:
            'Let A = {1,2,3,…7} and let P(A) denote the power set of A. If the number of functions f: A → P(A) such that a ∈ f(a), ∀a ∈ A is mⁿ, m and n ∈ N and m is least, then m+n is equal to ______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Sets, Relations and Functions',
        subTopic: 'Functions',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Functions', 'Power Set', 'Counting'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0428',
        questionText:
            'If the function f(x) = {1/|x|, |x| ≥ 2; ax² + 2b, |x| < 2} is differentiable on R, then 48(a+b) is equal to _______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Limit, Continuity and Differentiability',
        subTopic: 'Differentiability',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Piecewise Function', 'Differentiability'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0429',
        questionText:
            'The value of ∫₀⁹ [√(10x/(x+1))] dx, where [t] denotes the greatest integer less than or equal to t, is _____.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Integral Calculus',
        subTopic: 'Definite Integral',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Greatest Integer Function', 'Definite Integral'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0430',
        questionText:
            'Let y = y(x) be the solution of the differential equation (1−x²)dy = [xy + (x³+2)√(3(1−x²))]dx, −1 < x < 1, y(0) = 0. If y(1/2) = m/n, m and n are coprime numbers, then m+n is equal to __________.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Differential Equations',
        subTopic: 'First Order DE',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Differential Equation', 'Initial Value'],
        questionType: 'numerical',
      ),

      Question(
        id: 'MATH0431',
        questionText:
            'If d₁ is the shortest distance between the lines (x+1)/2 = y/2 = −12/z, x = (y+2)/6 = (z−6)/1 and d₂ is the shortest distance between the lines (x−1)/2 = (y+8)/−7 = (z−4)/5, (x−1)/2 = (y−2)/1 = (z−6)/−3, then the value of 32√3 d₁/d₂ is:',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Mathematics',
        topic: 'Three Dimensional Geometry',
        subTopic: 'Shortest Distance',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Shortest Distance', 'Skew Lines'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0434',
        questionText:
            'A physical quantity Q is found to depend on quantities a, b, c by the relation Q = a⁴b³/c². The percentage error in a, b and c are 3%, 4% and 5% respectively. Then, the percentage error in Q is:',
        options: ['66%', '43%', '34%', '14%'],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Units and Measurements',
        subTopic: 'Error Analysis',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Percentage Error', 'Error Propagation'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0435',
        questionText:
            'A particle is moving in a straight line. The variation of position x as a function of time t is given as x = (t³ − 6t² + 20t + 15) m. The velocity of the body when its acceleration becomes zero is:',
        options: ['4 m s⁻¹', '8 m s⁻¹', '10 m s⁻¹', '6 m s⁻¹'],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Kinematics',
        subTopic: 'Motion in Straight Line',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Velocity', 'Acceleration', 'Differentiation'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0436',
        questionText:
            'A stone of mass 900 g is tied to a string and moved in a vertical circle of radius 1 m making 10 rpm. The tension in the string, when the stone is at the lowest point is (if π² = 9.8 and g = 9.8 m s⁻²)',
        options: ['97 N', '9.8 N', '8.82 N', '17.8 N'],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Rotational Motion',
        subTopic: 'Circular Motion',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Circular Motion', 'Tension', 'Centripetal Force'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0437',
        questionText:
            'The bob of a pendulum was released from a horizontal position. The length of the pendulum is 10 m. If it dissipates 10% of its initial energy against air resistance, the speed with which the bob arrives at the lowest point is: [Use, g = 10 m s⁻²]',
        options: ['6√5 m s⁻¹', '5√6 m s⁻¹', '5√5 m s⁻¹', '2√5 m s⁻¹'],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Work, Energy and Power',
        subTopic: 'Energy Conservation',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Energy Conservation', 'Pendulum', 'Energy Dissipation'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0438',
        questionText:
            'A bob of mass m is suspended by a light string of length L. It is imparted a minimum horizontal velocity at the lowest point A such that it just completes half circle reaching the top most position B. The ratio of kinetic energies (K.E.)A/(K.E.)B is:',
        options: ['3 : 2', '5 : 1', '2 : 5', '1 : 5'],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Work, Energy and Power',
        subTopic: 'Circular Motion',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Circular Motion', 'Kinetic Energy', 'Energy Conservation'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0439',
        questionText:
            'A planet takes 200 days to complete one revolution around the Sun. If the distance of the planet from Sun is reduced to one fourth of the original distance, how many days will it take to complete one revolution?',
        options: ['25', '50', '100', '20'],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Gravitation',
        subTopic: "Kepler's Laws",
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ["Kepler's Third Law", 'Orbital Period'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0440',
        questionText:
            'A wire of length L and radius r is clamped at one end. If its other end is pulled by a force F, its length increases by l. If the radius of the wire and the applied force both are reduced to half of their original values keeping original length constant, the increase in length will become:',
        options: ['3 times', '3/2 times', '4 times', '2 times'],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Properties of Solids and Liquids',
        subTopic: 'Elasticity',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Young Modulus', 'Elongation'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0441',
        questionText:
            'A small liquid drop of radius R is divided into 27 identical liquid drops. If the surface tension is T, then the work done in the process will be:',
        options: ['8πR²T', '3πR²T', '1/8 πR²T', '4πR²T'],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Properties of Solids and Liquids',
        subTopic: 'Surface Tension',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Surface Tension', 'Work Done'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0442',
        questionText:
            'The temperature of a gas having 2.0×10²⁵ molecules per cubic meter at 1.38 atm (Given, k = 1.38×10⁻²³ J K⁻¹) is:',
        options: ['500 K', '200 K', '100 K', '300 K'],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Kinetic Theory of Gases',
        subTopic: 'Ideal Gas Law',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Ideal Gas Equation', 'Temperature Calculation'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0443',
        questionText:
            'N moles of a polyatomic gas (f = 6) must be mixed with two moles of a monoatomic gas so that the mixture behaves as a diatomic gas. The value of N is:',
        options: ['6', '3', '4', '2'],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Kinetic Theory of Gases',
        subTopic: 'Degrees of Freedom',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Degrees of Freedom', 'Specific Heat'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0444',
        questionText:
            'An electric field is given by (6î + 5ĵ + 3k̂) N C⁻¹. The electric flux through a surface area 30î m² lying in YZ-plane (in SI unit) is:',
        options: ['90', '150', '180', '60'],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Electrostatics',
        subTopic: 'Electric Flux',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Electric Flux', 'Vector Area'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0445',
        questionText: 'In the given circuit, the current in resistance R₃ is:',
        options: ['1 A', '1.5 A', '2 A', '2.5 A'],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Current Electricity',
        subTopic: 'Circuit Analysis',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Kirchhoff Laws', 'Current Division'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0446',
        questionText:
            'Two particles X and Y having equal charges are being accelerated through the same potential difference. Thereafter, they enter normally in a region of uniform magnetic field and describes circular paths of radii R₁ and R₂ respectively. The mass ratio of X and Y is:',
        options: ['(R₂/R₁)²', '(R₁/R₂)²', 'R₁/R₂', 'R₂/R₁'],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Magnetic Effects of Current and Magnetism',
        subTopic: 'Charged Particle in Magnetic Field',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Magnetic Force', 'Circular Motion', 'Mass Ratio'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0447',
        questionText:
            'In an a.c. circuit, voltage and current are given by: V = 100sin(100t) V and I = 100sin(100t + π/3) mA respectively. The average power dissipated in one cycle is:',
        options: ['5 W', '10 W', '2.5 W', '25 W'],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Electromagnetic Induction and Alternating Currents',
        subTopic: 'AC Power',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['AC Power', 'Power Factor'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0448',
        questionText:
            'A plane electromagnetic wave of frequency 35 MHz travels in free space along the X-direction. At a particular point (in space and time) E = 9.6 ĵ V m⁻¹. The value of magnetic field at this point is:',
        options: ['3.2×10⁻⁸ k̂ T', '3.2×10⁻⁸ î T', '9.6 ĵ T', '9.6×10⁻⁸ k̂ T'],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Electromagnetic Waves',
        subTopic: 'EM Wave Properties',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['EM Waves', 'Magnetic Field Component'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0449',
        questionText:
            'If the distance between object and its two times magnified virtual image produced by a curved mirror is 15 cm, the focal length of the mirror must be:',
        options: ['15 cm', '−12 cm', '−10 cm', '10/3 cm'],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Optics',
        subTopic: 'Mirror Formula',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Mirror Formula', 'Magnification'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0450',
        questionText:
            "In Young's double slit experiment, light from two identical sources are superimposing on a screen. The path difference between the two lights reaching at a point on the screen is 7λ/4. The ratio of intensity of fringe at this point with respect to the maximum intensity of the fringe is:",
        options: ['1/2', '3/4', '1/3', '1/4'],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Optics',
        subTopic: 'Interference',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Interference', 'Intensity Pattern'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0451',
        questionText:
            'Two sources of light emit with a power of 200 W. The ratio of number of photons of visible light emitted by each source having wavelengths 300 nm and 500 nm respectively, will be:',
        options: ['1 : 5', '1 : 3', '5 : 3', '3 : 5'],
        correctAnswerIndex: 3,
        subject: 'Physics',
        topic: 'Dual Nature of Matter and Radiation',
        subTopic: 'Photon Energy',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Photon Energy', 'Wavelength'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0452',
        questionText:
            'Given below are two statements: Statement I: Most of the mass of the atom and all its positive charge are concentrated in a tiny nucleus and the electrons revolve around it, is Rutherford model. Statement II: An atom is a spherical cloud of positive charges with electrons embedded in it, is a special case of Rutherford model. In the light of the above statements, choose the most appropriate from the options given below.',
        options: [
          'Both statement I and statement II are false',
          'Statement I is false but statement II is true',
          'Statement I is true but statement II is false',
          'Both statement I and statement II are true'
        ],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Dual Nature of Matter and Radiation',
        subTopic: 'Atomic Models',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Rutherford Model', 'Atomic Structure'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0453',
        questionText: 'The truth table for this given circuit is:',
        options: ['AND Gate', 'OR Gate', 'NAND Gate', 'NOR Gate'],
        correctAnswerIndex: 1,
        subject: 'Physics',
        topic: 'Atoms and Nuclei',
        subTopic: 'Logic Gates',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Logic Gates', 'Truth Table'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'PHY0454',
        questionText:
            'A particle is moving in a circle of radius 50 cm in such a way that at any instant the normal and tangential components of its acceleration are equal. If its speed at t = 0 is 4 m s⁻¹, the time taken to complete the first revolution will be (1/α)[1−e⁻²π] s, where α =______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Electronic Devices',
        subTopic: 'Circular Motion',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Circular Motion', 'Acceleration Components'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0455',
        questionText:
            'A body of mass 5 kg moving with a uniform speed 3√2 m s⁻¹ in X−Y plane along the line y = x+4. The angular momentum of the particle about the origin will be _______ kg m² s⁻¹.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Circular Motion',
        subTopic: 'Angular Momentum',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Angular Momentum', 'Linear Motion'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0456',
        questionText:
            'Two metallic wires P and Q have same volume and are made up of same material. If their area of cross sections are in the ratio 4 : 1 and force F₁ is applied to P, an extension of Δl is produced. The force which is required to produce same extension in Q is F₂. The value of F₁/F₂ is ______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'System of Particles and Rotational Motion',
        subTopic: 'Elasticity',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Young Modulus', 'Elongation'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0457',
        questionText:
            'A simple harmonic oscillator has an amplitude A and time period 6π second. Assuming the oscillation starts from its mean position, the time required by it to travel from x = A/2 to x = √3A/2 will be π/x s, where x = _______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Mechanical Properties of Solids',
        subTopic: 'Simple Harmonic Motion',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['SHM', 'Time Calculation'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0458',
        questionText:
            'In the given circuit, the current flowing through the resistance 20 Ω is 0.3 A, while the ammeter reads 0.9 A. The value of R₁ is _____ Ω.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Oscillations',
        subTopic: 'Circuit Analysis',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Kirchhoff Laws', 'Current Division'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0459',
        questionText:
            'A charge of 4.0 μC is moving with a velocity of 4.0×10⁶ m s⁻¹ along the positive y-axis under a magnetic field B of strength (2k̂) T. The force acting on the charge is xî N. The value of x is ______.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Current Electricity',
        subTopic: 'Magnetic Force',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Magnetic Force', 'Cross Product'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0460',
        questionText:
            'A horizontal straight wire 5 m long extending from east to west falling freely at right angle to horizontal component of earth magnetic field 0.60×10⁻⁴ Wb m⁻². The instantaneous value of emf induced in the wire when its velocity is 10 m s⁻¹ is _______ × 10⁻³ V.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Magnetic Effects of Current and Magnetism',
        subTopic: 'Electromagnetic Induction',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Motional EMF', 'Faraday Law'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0461',
        questionText:
            'In the given figure, the charge stored in 6μF capacitor, when points A and B are joined by a connecting wire is _______ μC.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Electromagnetic Induction and Alternating Currents',
        subTopic: 'Capacitors',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Capacitors', 'Charge Storage'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0462',
        questionText:
            'In a single slit diffraction pattern, a light of wavelength 6000 Å is used. The distance between the first and third minima in the diffraction pattern is found to be 3 mm when the screen is placed 50 cm away from slits. The width of the slit is ____ × 10⁻⁴ m.',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Electrostatics',
        subTopic: 'Diffraction',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Single Slit Diffraction', 'Minima Position'],
        questionType: 'numerical',
      ),

      Question(
        id: 'PHY0463',
        questionText:
            'Hydrogen atom is bombarded with electrons accelerated through a potential difference of V, which causes excitation of hydrogen atoms. If the experiment is being performed at T = 0 K. The minimum potential difference needed to observe any Balmer series lines in the emission spectra will be α/10 V, where α = _________. (Write the value to the nearest integer)',
        options: [''],
        correctAnswerIndex: 0,
        subject: 'Physics',
        topic: 'Wave Optics',
        subTopic: 'Atomic Spectra',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Hydrogen Spectrum', 'Excitation Energy'],
        questionType: 'numerical',
      ),

      Question(
        id: 'CHEM0434',
        questionText: 'Match List I with List II',
        options: [
          'A-II, B-III, C-I, D-IV',
          'A-I, B-III, C-II, D-IV',
          'A-II, B-IV, C-III, D-I',
          'A-I, B-II, C-III, D-IV'
        ],
        correctAnswerIndex: 2,
        subject: 'Physics',
        topic: 'Atoms and Nuclei',
        subTopic: 'Matching',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Concepts Matching'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0435',
        questionText:
            'The element having the highest first ionization enthalpy is',
        options: ['Si', 'Al', 'N', 'C'],
        correctAnswerIndex: 2,
        subject: 'Chemistry',
        topic: 'Classification of Elements and Periodicity in Properties',
        subTopic: 'Ionization Enthalpy',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Ionization Energy', 'Periodic Trends'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0436',
        questionText:
            'Given below are two statements: Statement I: Fluorine has most negative electron gain enthalpy in its group. Statement II: Oxygen has least negative electron gain enthalpy in its group. In the light of the above statements, choose the most appropriate from the options given below.',
        options: [
          'Both Statement I and Statement II are true',
          'Statement I is true but Statement II is false',
          'Both Statement I and Statement II are false',
          'Statement I is false but Statement II is true'
        ],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Classification of Elements and Periodicity in Properties',
        subTopic: 'Electron Gain Enthalpy',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Electron Affinity', 'Periodic Trends'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0437',
        questionText: 'According to IUPAC system, the compound is named as:',
        options: [
          'Cyclohex-1-en-2-ol',
          '1-Hydroxyhex-2-ene',
          'Cyclohex-1-en-3-ol',
          'Cyclohex-2-en-1-ol'
        ],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Classification of Elements and Periodicity in Properties',
        subTopic: 'IUPAC Nomenclature',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['IUPAC Naming', 'Organic Compounds'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0438',
        questionText: 'The ascending acidity order of the following H atoms is',
        options: [
          'C < D < B < A',
          'A < B < C < D',
          'A < B < D < C',
          'D < C < B < A'
        ],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'Organic Compounds Containing Oxygen',
        subTopic: 'Acidity Order',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Acidity', 'Organic Compounds'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0439',
        questionText: 'Match List I with List II',
        options: [
          'A-I, B-II, C-III, D-IV',
          'A-IV, B-I, C-II, D-III',
          'A-III, B-IV, C-I, D-II',
          'A-II, B-I, C-IV, D-III'
        ],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Some Basic Principles of Organic Chemistry',
        subTopic: 'Matching',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 150,
        concepts: ['Organic Chemistry Concepts'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0440',
        questionText:
            'Which one of the following will show geometrical isomerism?',
        options: ['Compound A', 'Compound B', 'Compound C', 'Compound D'],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'Some Basic Principles of Organic Chemistry',
        subTopic: 'Geometrical Isomerism',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Geometrical Isomerism', 'Stereochemistry'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0441',
        questionText:
            'Chromatographic technique/s based on the principle of differential adsorption is/are A. Column chromatography B. Thin layer chromatography C. Paper chromatography Choose the most appropriate answer from the options given below:',
        options: ['B only', 'A only', 'A & B only', 'C only'],
        correctAnswerIndex: 2,
        subject: 'Chemistry',
        topic: 'Purification and Characterisation of Organic Compounds',
        subTopic: 'Chromatography',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 170,
        concepts: ['Chromatography', 'Separation Techniques'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0442',
        questionText: 'Anomalous behaviour of oxygen is due to its',
        options: [
          'Large size and high electronegativity',
          'Small size and low electronegativity',
          'Small size and high electronegativity',
          'Large size and low electronegativity'
        ],
        correctAnswerIndex: 2,
        subject: 'Chemistry',
        topic: 'p-Block Elements',
        subTopic: 'Oxygen Properties',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Anomalous Behavior', 'Oxygen'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0443',
        questionText:
            'Which of the following acts as a strong reducing agent? (Atomic number: Ce = 58, Eu = 63, Gd = 64, Lu = 71)',
        options: ['Lu³⁺', 'Gd³⁺', 'Eu²⁺', 'Ce⁴⁺'],
        correctAnswerIndex: 2,
        subject: 'Chemistry',
        topic: 'd- and f-Block Elements',
        subTopic: 'Reducing Agents',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Reducing Agents', 'f-block Elements'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0444',
        questionText:
            'Which of the following statements are correct about Zn, Cd and Hg? A. They exhibit high enthalpy of atomization as the d-subshell is full. B. Zn and Cd do not show variable oxidation state while Hg shows +I and +II. C. Compounds of Zn, Cd and Hg are paramagnetic in nature. D. Zn, Cd and Hg are called soft metals. Choose the most appropriate from the options given below:',
        options: ['B, D only', 'B, C only', 'A, D only', 'C, D only'],
        correctAnswerIndex: 0,
        subject: 'Chemistry',
        topic: 'd- and f-Block Elements',
        subTopic: 'Zinc Group Properties',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 190,
        concepts: ['Zinc Group', 'Properties'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0445',
        questionText: 'The correct IUPAC name of K₂MnO₄ is:',
        options: [
          'Potassium tetraoxopermanganate (VI)',
          'Potassium tetraoxidomanganate (VI)',
          'Dipotassium tetraoxidomanganate (VII)',
          'Potassium tetraoxidomanganese (VI)'
        ],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'd- and f-Block Elements',
        subTopic: 'IUPAC Nomenclature',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['IUPAC Naming', 'Coordination Compounds'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0446',
        questionText:
            'Alkyl halide is converted into alkyl isocyanide by reaction with',
        options: ['NaCN', 'NH₄CN', 'KCN', 'AgCN'],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Organic Compounds Containing Nitrogen',
        subTopic: 'Isocyanide Formation',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Isocyanide', 'Alkyl Halide Reactions'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0447',
        questionText:
            'Phenol treated with chloroform in presence of sodium hydroxide, which further hydrolysed in presence of an acid results',
        options: [
          'Salicylic acid',
          'Benzene-1,2-diol',
          'Benzene-1,3-diol',
          '2-Hydroxybenzaldehyde'
        ],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Organic Compounds Containing Oxygen',
        subTopic: 'Phenol Reactions',
        difficulty: 'Easy',
        marks: 4.0,
        timeRequired: 200,
        concepts: ['Reimer-Tiemann Reaction', 'Phenol'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0448',
        questionText: 'Identify the reagents used for the following conversion',
        options: [
          'A = LiAlH₄, B = NaOH (aq), C = NH₂-NH₂/KOH ethylene glycol',
          'A = LiAlH₄, B = NaOH (alc), C = Zn/HCl',
          'A = DIBAL-H, B = NaOH (aq) C = NH₂-NH₂/KOH ethylene glycol',
          'A = DIBAL-H, B = NaOH (alc), C = Zn/HCl'
        ],
        correctAnswerIndex: 3,
        subject: 'Chemistry',
        topic: 'Some Basic Principles of Organic Chemistry',
        subTopic: 'Reagents',
        difficulty: 'Hard',
        marks: 4.0,
        timeRequired: 180,
        concepts: ['Organic Reagents', 'Reaction Mechanism'],
        questionType: 'multipleChoice',
      ),

      Question(
        id: 'CHEM0449',
        questionText: 'Which of the following reaction is correct?',
        options: [
          'Reaction A',
          'Reaction B',
          'Reaction C',
          'C₂H₅CONH₂ + Br₂ + NaOH → C₂H₅CH₂NH₂ + Na₂CO₃ + NaBr + H₂O'
        ],
        correctAnswerIndex: 1,
        subject: 'Chemistry',
        topic: 'Some Basic Principles of Organic Chemistry',
        subTopic: 'Reaction Correctness',
        difficulty: 'Medium',
        marks: 4.0,
        timeRequired: 160,
        concepts: ['Reaction Mechanism', 'Organic Reactions'],
        questionType: 'multipleChoice',
      ),
    ];
  }

  // Get questions by multiple criteria including question type
  static Map<String, int> getQuestionCountBySubject() {
    final counts = <String, int>{};
    for (final question in questions) {
      counts[question.subject] = (counts[question.subject] ?? 0) + 1;
    }
    return counts;
  }

  // Get question count by topic
  static Map<String, int> getQuestionCountByTopic() {
    final counts = <String, int>{};
    for (final question in questions) {
      counts[question.topic] = (counts[question.topic] ?? 0) + 1;
    }
    return counts;
  }

  // Get statistics
  static Map<String, dynamic> getStatistics() {
    return {
      'totalQuestions': questions.length,
      'subjects': getQuestionCountBySubject(),
      'topics': getQuestionCountByTopic(),
      'difficulties': {
        'Easy': questions.where((q) => q.difficulty == 'Easy').length,
        'Medium': questions.where((q) => q.difficulty == 'Medium').length,
        'Hard': questions.where((q) => q.difficulty == 'Hard').length,
      },
    };
  }
}
