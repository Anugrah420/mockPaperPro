// screens/question_accuracy_screen.dart
import 'package:flutter/material.dart';
import '../models.dart';
import '../services/accuracy_validator_service.dart';

class QuestionAccuracyScreen extends StatefulWidget {
  final Question question;

  const QuestionAccuracyScreen({super.key, required this.question});

  @override
  State<QuestionAccuracyScreen> createState() => _QuestionAccuracyScreenState();
}

class _QuestionAccuracyScreenState extends State<QuestionAccuracyScreen> {
  Map<String, dynamic>? _accuracyReport;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkAccuracy();
  }

  Future<void> _checkAccuracy() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final report = await AccuracyValidatorService.checkAccuracy(
        question: widget.question,
        studentId: 'current_user', // You can get this from auth service
      );

      setState(() {
        _accuracyReport = report;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking accuracy: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Question Accuracy Analysis'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _checkAccuracy,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _accuracyReport == null
              ? const Center(child: Text('No accuracy data available'))
              : _buildAccuracyReport(),
    );
  }

  Widget _buildAccuracyReport() {
    final report = _accuracyReport!;
    final overallScore = report['accuracy_score'] as double;
    final confidenceLevel = report['confidence_level'] as String;
    final logicalAccuracy = report['logical_accuracy'] as double;
    final grammaticalAccuracy = report['grammatical_accuracy'] as double;
    final mathematicalConsistency =
        report['mathematical_consistency'] as double;
    final issues = (report['issues_found'] as List<dynamic>).cast<String>();
    final recommendations =
        (report['recommendations'] as List<dynamic>).cast<String>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall Score Card
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Overall Accuracy Score',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  CircularProgressIndicator(
                    value: overallScore,
                    backgroundColor: Colors.grey[300],
                    color: _getScoreColor(overallScore),
                    strokeWidth: 8,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${(overallScore * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _getScoreColor(overallScore),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Chip(
                    label: Text(
                      'Confidence: $confidenceLevel',
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: _getConfidenceColor(confidenceLevel),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Detailed Scores
          const Text(
            'Detailed Analysis',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          _buildScoreCard(
              'Logical Accuracy', logicalAccuracy, Icons.psychology),
          _buildScoreCard(
              'Grammatical Accuracy', grammaticalAccuracy, Icons.language),
          _buildScoreCard('Mathematical Consistency', mathematicalConsistency,
              Icons.calculate),

          const SizedBox(height: 16),

          // Issues Found
          if (issues.isNotEmpty) ...[
            const Text(
              'Issues Found',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const SizedBox(height: 8),
            ...issues
                .map((issue) => Card(
                      color: Colors.red[50],
                      child: ListTile(
                        leading: const Icon(Icons.warning, color: Colors.red),
                        title: Text(issue),
                      ),
                    ))
                .toList(),
          ],

          const SizedBox(height: 16),

          // Recommendations
          if (recommendations.isNotEmpty) ...[
            const Text(
              'Recommendations',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green),
            ),
            const SizedBox(height: 8),
            ...recommendations
                .map((recommendation) => Card(
                      color: Colors.green[50],
                      child: ListTile(
                        leading:
                            const Icon(Icons.lightbulb, color: Colors.green),
                        title: Text(recommendation),
                      ),
                    ))
                .toList(),
          ],

          const SizedBox(height: 16),

          // Question Preview
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Question Preview',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.question.questionText,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  if (widget.question.options.isNotEmpty) ...[
                    const Text(
                      'Options:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ...widget.question.options.asMap().entries.map((entry) {
                      final index = entry.key;
                      final option = entry.value;
                      final isCorrect =
                          index == widget.question.correctAnswerIndex;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              isCorrect ? Colors.green : Colors.grey,
                          child: Text(
                            String.fromCharCode(65 + index),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(option),
                        trailing: isCorrect
                            ? const Icon(Icons.check, color: Colors.green)
                            : null,
                      );
                    }).toList(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(String title, double score, IconData icon) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: _getScoreColor(score)),
        title: Text(title),
        subtitle: LinearProgressIndicator(
          value: score,
          backgroundColor: Colors.grey[300],
          color: _getScoreColor(score),
        ),
        trailing: Text(
          '${(score * 100).toStringAsFixed(0)}%',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _getScoreColor(score),
          ),
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.orange;
    return Colors.red;
  }

  Color _getConfidenceColor(String level) {
    switch (level) {
      case 'Very High':
        return Colors.green;
      case 'High':
        return Colors.lightGreen;
      case 'Medium':
        return Colors.orange;
      case 'Low':
        return Colors.orangeAccent;
      case 'Very Low':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
