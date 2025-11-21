import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../firebase_service.dart'; // Make sure this import is present

class AccuracyHistoryScreen extends StatefulWidget {
  final String studentId;

  const AccuracyHistoryScreen({super.key, required this.studentId});

  @override
  State<AccuracyHistoryScreen> createState() => _AccuracyHistoryScreenState();
}

class _AccuracyHistoryScreenState extends State<AccuracyHistoryScreen> {
  List<Map<String, dynamic>> _accuracyHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccuracyHistory();
  }

  Future<void> _loadAccuracyHistory() async {
    try {
      // Create FirebaseService instance
      final firebaseService = FirebaseService();

      final history =
          await firebaseService.getAccuracyHistory(widget.studentId);
      setState(() {
        _accuracyHistory = history;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading accuracy history: $e');
      setState(() {
        _isLoading = false;
      });

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load accuracy history: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accuracy History'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadAccuracyHistory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _accuracyHistory.isEmpty
              ? _buildEmptyState()
              : _buildHistoryList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'No Accuracy History',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'Complete tests with accuracy validation to see your question accuracy history here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return ListView.builder(
      itemCount: _accuracyHistory.length,
      itemBuilder: (context, index) {
        final record = _accuracyHistory[index];
        final accuracyResults =
            (record['accuracyResults'] as List<dynamic>?) ?? [];
        final averageAccuracy = (record['averageAccuracy'] as double?) ?? 0.0;
        final timestamp = (record['timestamp'] as int?) ?? 0;
        final testId = (record['testId'] as String?) ?? 'Unknown Test';

        return Card(
          margin: const EdgeInsets.all(8),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: _getScoreColor(averageAccuracy),
              child: Text(
                '${(averageAccuracy * 100).toInt()}',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
                'Test: ${testId.substring(0, testId.length > 15 ? 15 : testId.length)}...'),
            subtitle: Text('${accuracyResults.length} questions validated'),
            trailing: Chip(
              label: Text(_formatDate(timestamp)),
              backgroundColor: Colors.grey[200],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Question Accuracy Scores:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (accuracyResults.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: accuracyResults.map((result) {
                          final score =
                              (result['accuracy_score'] as double?) ?? 0.0;
                          final confidence =
                              (result['confidence_level'] as String?) ??
                                  'Unknown';
                          return Tooltip(
                            message: 'Confidence: $confidence',
                            child: Chip(
                              label: Text('${(score * 100).toInt()}%'),
                              backgroundColor: _getScoreColor(score),
                              labelStyle: const TextStyle(color: Colors.white),
                            ),
                          );
                        }).toList(),
                      )
                    else
                      const Text('No accuracy data available'),
                    const SizedBox(height: 12),
                    Text(
                      'Average Accuracy: ${(averageAccuracy * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: _getScoreColor(averageAccuracy),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getScoreColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.orange;
    return Colors.red;
  }
}
