import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models.dart';
import '../services/accuracy_validator_service.dart';
import '../auth_service.dart'; // Add this import
import '../ai_test_service.dart'; // Add this import

class TestAccuracyReportScreen extends StatefulWidget {
  const TestAccuracyReportScreen({super.key});

  @override
  State<TestAccuracyReportScreen> createState() =>
      _TestAccuracyReportScreenState();
}

class _TestAccuracyReportScreenState extends State<TestAccuracyReportScreen> {
  int _selectedTab = 0;
  List<Map<String, dynamic>> _accuracyHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccuracyData();
  }

  Future<void> _loadAccuracyData() async {
    // Simulate loading accuracy data
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _accuracyHistory = [
        {
          'date': DateTime.now().subtract(const Duration(days: 1)),
          'accuracy_score': 0.85,
          'confidence_level': 'High',
          'validated_questions': 5,
          'correct_validations': 4,
          'test_id': 'TEST_001',
        },
        {
          'date': DateTime.now().subtract(const Duration(days: 3)),
          'accuracy_score': 0.72,
          'confidence_level': 'Medium',
          'validated_questions': 3,
          'correct_validations': 2,
          'test_id': 'TEST_002',
        },
        {
          'date': DateTime.now().subtract(const Duration(days: 7)),
          'accuracy_score': 0.91,
          'confidence_level': 'Very High',
          'validated_questions': 4,
          'correct_validations': 4,
          'test_id': 'TEST_003',
        },
      ];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final testService = Provider.of<AITestService>(context);
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Accuracy Reports'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAccuracyData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab Selection
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Row(
              children: [
                _buildTab(0, 'Accuracy Overview', Icons.verified),
                _buildTab(1, 'Validation History', Icons.history),
                _buildTab(2, 'Question Analysis', Icons.analytics),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? _buildLoadingIndicator()
                : _buildCurrentTab(testService, authService),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String title, IconData icon) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: Material(
        color: isSelected ? Colors.purple : Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedTab = index;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon,
                    size: 18, color: isSelected ? Colors.white : Colors.grey),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading Accuracy Data...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentTab(AITestService testService, AuthService authService) {
    switch (_selectedTab) {
      case 0:
        return _buildAccuracyOverviewTab(testService);
      case 1:
        return _buildValidationHistoryTab();
      case 2:
        return _buildQuestionAnalysisTab(testService, authService);
      default:
        return _buildAccuracyOverviewTab(testService);
    }
  }

  Widget _buildAccuracyOverviewTab(AITestService testService) {
    final testResults = testService.testResults;

    if (testResults.isEmpty) {
      return _buildPlaceholderCard(
        'Accuracy Overview',
        Icons.verified_user,
        'Complete tests with accuracy validation to see detailed accuracy reports',
      );
    }

    // Calculate accuracy metrics
    final accuracyResults = _calculateAccuracyMetrics(testResults);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Overall Accuracy Score
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Icon(Icons.verified, size: 50, color: Colors.purple),
                  const SizedBox(height: 10),
                  const Text(
                    'Overall Accuracy Score',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${(accuracyResults['overall_accuracy'] * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Based on ${accuracyResults['total_validations']} question validations',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Confidence Level Distribution
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Confidence Levels',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sections: _buildConfidenceSections(accuracyResults),
                        centerSpaceRadius: 40,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Accuracy Trends
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Accuracy Trends',
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
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text('Test ${value.toInt() + 1}'),
                                );
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
                            spots: _buildAccuracyTrendSpots(testResults),
                            isCurved: true,
                            color: Colors.purple,
                            barWidth: 4,
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.purple.withOpacity(0.1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValidationHistoryTab() {
    return ListView.builder(
      itemCount: _accuracyHistory.length,
      itemBuilder: (context, index) {
        final record = _accuracyHistory[index];
        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getAccuracyColor(record['accuracy_score'] as double),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${(record['accuracy_score'] * 100).toInt()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            title: Text(
              'Test ${record['test_id']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'Accuracy: ${(record['accuracy_score'] * 100).toStringAsFixed(1)}%'),
                Text('Confidence: ${record['confidence_level']}'),
                Text('Validated: ${record['validated_questions']} questions'),
                Text('Date: ${_formatDate(record['date'] as DateTime)}'),
              ],
            ),
            trailing: Chip(
              label: Text(record['confidence_level'] as String),
              backgroundColor:
                  _getConfidenceColor(record['confidence_level'] as String),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuestionAnalysisTab(
      AITestService testService, AuthService authService) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Question-Level Accuracy Analysis',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Detailed analysis of question accuracy and validation results',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 20),

          // Sample question validation results
          ..._buildSampleQuestionAnalysis(),

          // Validation Statistics
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Validation Statistics',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  _buildStatRow('Total Questions Validated', '47'),
                  _buildStatRow('High Confidence Validations', '32 (68%)'),
                  _buildStatRow('Medium Confidence Validations', '12 (26%)'),
                  _buildStatRow('Low Confidence Validations', '3 (6%)'),
                  _buildStatRow('Average Validation Time', '2.3s'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Accuracy Improvement Tips
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Accuracy Improvement Tips',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _buildTipItem(
                      'Double-check calculations for numerical questions'),
                  _buildTipItem(
                      'Review theoretical concepts for better understanding'),
                  _buildTipItem(
                      'Practice time management to reduce rushed answers'),
                  _buildTipItem(
                      'Verify units and dimensions in physics problems'),
                  _buildTipItem('Cross-verify answers when unsure'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSampleQuestionAnalysis() {
    return [
      _buildQuestionAnalysisCard(
        'Mathematics - Calculus',
        'Derivative of x²',
        0.95,
        'High',
        'Correct calculation with proper steps',
      ),
      _buildQuestionAnalysisCard(
        'Physics - Mechanics',
        'Newton\'s Second Law',
        0.78,
        'Medium',
        'Minor unit conversion issue',
      ),
      _buildQuestionAnalysisCard(
        'Chemistry - Organic',
        'IUPAC Naming',
        0.85,
        'High',
        'Accurate naming with correct substituents',
      ),
    ];
  }

  Widget _buildQuestionAnalysisCard(
    String subject,
    String question,
    double accuracy,
    String confidence,
    String notes,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(
                  label: Text(subject.split(' - ')[0]),
                  backgroundColor: _getSubjectColor(subject.split(' - ')[0]),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getAccuracyColor(accuracy).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getAccuracyColor(accuracy)),
                  ),
                  child: Text(
                    '${(accuracy * 100).toInt()}%',
                    style: TextStyle(
                      color: _getAccuracyColor(accuracy),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              question,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.verified,
                    size: 14, color: _getConfidenceColor(confidence)),
                const SizedBox(width: 4),
                Text(
                  'Confidence: $confidence',
                  style: TextStyle(
                    fontSize: 12,
                    color: _getConfidenceColor(confidence),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              notes,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(value,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTipItem(String tip) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, size: 16, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderCard(String title, IconData icon, String message) {
    return Center(
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 60, color: Colors.grey),
              const SizedBox(height: 20),
              Text(
                title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods
  Map<String, dynamic> _calculateAccuracyMetrics(List<TestResult> results) {
    double totalAccuracy = 0;
    int totalValidations = 0;
    final confidenceCounts = {'High': 0, 'Medium': 0, 'Low': 0};

    for (var result in results) {
      if (result.accuracyScore != null) {
        totalAccuracy += result.accuracyScore!;
        totalValidations++;

        // Simulate confidence distribution
        if (result.accuracyScore! > 0.8) {
          confidenceCounts['High'] = confidenceCounts['High']! + 1;
        } else if (result.accuracyScore! > 0.6) {
          confidenceCounts['Medium'] = confidenceCounts['Medium']! + 1;
        } else {
          confidenceCounts['Low'] = confidenceCounts['Low']! + 1;
        }
      }
    }

    return {
      'overall_accuracy':
          totalValidations > 0 ? totalAccuracy / totalValidations : 0,
      'total_validations': totalValidations,
      'confidence_counts': confidenceCounts,
    };
  }

  List<PieChartSectionData> _buildConfidenceSections(
      Map<String, dynamic> accuracyResults) {
    final counts = accuracyResults['confidence_counts'] as Map<String, int>;
    final total = counts.values.fold(0, (sum, count) => sum + count);

    if (total == 0) {
      return [
        PieChartSectionData(
          color: Colors.grey,
          value: 100,
          title: 'No Data',
          radius: 60,
        ),
      ];
    }

    return [
      PieChartSectionData(
        color: Colors.green,
        value: counts['High']!.toDouble(),
        title: 'High\n${((counts['High']! / total) * 100).toStringAsFixed(0)}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        color: Colors.orange,
        value: counts['Medium']!.toDouble(),
        title:
            'Medium\n${((counts['Medium']! / total) * 100).toStringAsFixed(0)}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        color: Colors.red,
        value: counts['Low']!.toDouble(),
        title: 'Low\n${((counts['Low']! / total) * 100).toStringAsFixed(0)}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ];
  }

  List<FlSpot> _buildAccuracyTrendSpots(List<TestResult> results) {
    final spots = <FlSpot>[];
    int validTestCount = 0;

    for (var i = 0; i < results.length; i++) {
      if (results[i].accuracyScore != null) {
        spots.add(
            FlSpot(validTestCount.toDouble(), results[i].accuracyScore! * 100));
        validTestCount++;
      }
    }

    return spots;
  }

  Color _getAccuracyColor(double accuracy) {
    if (accuracy >= 0.8) return Colors.green;
    if (accuracy >= 0.6) return Colors.orange;
    return Colors.red;
  }

  Color _getConfidenceColor(String confidence) {
    switch (confidence) {
      case 'High':
      case 'Very High':
        return Colors.green;
      case 'Medium':
        return Colors.orange;
      case 'Low':
      case 'Very Low':
        return Colors.red;
      default:
        return Colors.grey;
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
