// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';

// --- Reusable widgets ---
import '../widgets/gradient_background.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_section_header.dart';

// --- Models (same) ---
class Exercise {
  final String exerciseName;
  final String? exerciseUrl;

  Exercise({required this.exerciseName, this.exerciseUrl});

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      exerciseName: json['exercise_name'] ?? 'Unnamed exercise',
      exerciseUrl: json['exercise_url'],
    );
  }
}

class Prescription {
  final int id;
  final String createdAt;
  final String status;
  final String? notes;
  final List<Exercise> exercises;

  Prescription({
    required this.id,
    required this.createdAt,
    required this.status,
    this.notes,
    required this.exercises,
  });

  factory Prescription.fromJson(Map<String, dynamic> json) {
    return Prescription(
      id: json['id'],
      createdAt: json['created_at'] ?? '',
      status: json['status'] ?? 'active',
      notes: json['prescription_notes'],
      exercises: (json['exercises'] as List<dynamic>? ?? [])
          .map((e) => Exercise.fromJson(e))
          .toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// DASHBOARD SCREEN with HORIZONTAL EXERCISE SCROLL
// ---------------------------------------------------------------------------
class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic> patientData;

  const DashboardScreen({super.key, required this.patientData});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final patientName = widget.patientData['patient_name'] ?? 'Patient';
    final diagnosis = widget.patientData['diagnosis'] ?? 'Not specified';
    final rawPrescription = widget.patientData['latest_prescription'];

    final Prescription? prescription = rawPrescription != null
        ? Prescription.fromJson(rawPrescription)
        : null;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Exercise Prescriptions'),
      body: GradientBackground(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: ListView(
          children: [
            CustomSectionHeader(
              patientName: patientName,
              diagnosis: diagnosis,
            ),
            const SizedBox(height: 16),
            if (prescription == null)
              _buildEmptyState()
            else
              _buildPrescriptionCard(prescription),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const CustomCard(
      padding: EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.assignment_outlined, size: 48, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'No Prescriptions Yet',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 4),
          Text(
            'You do not have any exercise prescriptions.',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionCard(Prescription prescription) {
    return CustomCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Header (clickable) ---
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Prescription ${prescription.createdAt}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  _buildStatusBadge(prescription.status),
                  const SizedBox(width: 8),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),

          // --- Expanded body with horizontal exercise carousel ---
          if (_isExpanded) ...[
            const Divider(height: 1),
            if (prescription.exercises.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No exercises assigned in this prescription.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              _buildExerciseCarousel(prescription.exercises),

            // --- Notes section (unchanged) ---
            if (prescription.notes != null &&
                prescription.notes!.trim().isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📋 Prescription Notes',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      prescription.notes!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  // --- Horizontal carousel of exercises (Instagram/Facebook style) ---
  Widget _buildExerciseCarousel(List<Exercise> exercises) {
    return SizedBox(
      height: 220, // fixed height for the carousel
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: exercises.length,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        itemBuilder: (context, index) {
          final exercise = exercises[index];
          return _buildExerciseItem(exercise);
        },
      ),
    );
  }

  Widget _buildExerciseItem(Exercise exercise) {
    return Container(
      width: 150,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image – 120x120 or similar
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: exercise.exerciseUrl != null
                ? Image.network(
                    exercise.exerciseUrl!,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildNoImagePlaceholder(height: 120),
                  )
                : _buildNoImagePlaceholder(height: 120),
          ),
          // Caption
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              exercise.exerciseName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoImagePlaceholder({double height = 120}) {
    return Container(
      height: height,
      width: double.infinity,
      color: Colors.grey[200],
      child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'completed':
        color = Colors.blue;
        break;
      case 'paused':
        color = Colors.orange;
        break;
      default:
        color = Colors.green;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}