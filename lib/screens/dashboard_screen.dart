// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';

import '../widgets/custom_app_bar.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_section_header.dart';

// --- Models (unchanged) ---
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
// DASHBOARD SCREEN – YOUTUBE STYLE (dark background, thumbnails + titles)
// ---------------------------------------------------------------------------
class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic> patientData;

  const DashboardScreen({super.key, required this.patientData});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final patientName = widget.patientData['patient_name'] ?? 'Patient';
    final diagnosis = widget.patientData['diagnosis'] ?? 'Not specified';
    final rawPrescription = widget.patientData['latest_prescription'];

    final Prescription? prescription = rawPrescription != null
        ? Prescription.fromJson(rawPrescription)
        : null;

    return Scaffold(
      // Dark app bar matching YouTube style
      appBar: AppBar(
        title: const Text(
          'Exercise Prescriptions',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // Dark background (like YouTube dark theme)
      body: Container(
        color: Colors.black,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ListView(
              children: [
                // Patient header – keep it readable on dark background
                CustomSectionHeader(
                  patientName: patientName,
                  diagnosis: diagnosis,
                ),
                const SizedBox(height: 16),
                if (prescription == null)
                  _buildEmptyState()
                else ...[
                  _buildExerciseFeed(prescription.exercises),
                  if (prescription.notes != null &&
                      prescription.notes!.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _buildNotesCard(prescription.notes!),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const CustomCard(
      color: Colors.grey,
      padding: EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.assignment_outlined, size: 48, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'No Prescriptions Yet',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
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

  Widget _buildExerciseFeed(List<Exercise> exercises) {
    if (exercises.isEmpty) {
      return const CustomCard(
        color: Colors.grey,
        child: Text(
          'No exercises assigned.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: exercises.length,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        return _buildFeedItem(exercise);
      },
    );
  }

  // --- YouTube-style feed item: thumbnail + title below ---
  Widget _buildFeedItem(Exercise exercise) {
    // 16:9 aspect ratio – width is screen width minus padding, so we compute height.
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth - 24; // 12 padding on each side
    final thumbnailHeight = cardWidth * 9 / 16; // 16:9

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Thumbnail ---
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: exercise.exerciseUrl != null
                ? Image.network(
                    exercise.exerciseUrl!,
                    width: double.infinity,
                    height: thumbnailHeight,
                    fit: BoxFit.cover, // fills the width, crops if needed
                    errorBuilder: (_, __, ___) => Container(
                      height: thumbnailHeight,
                      color: Colors.grey[800],
                      child: const Icon(Icons.image_not_supported, color: Colors.grey),
                    ),
                  )
                : Container(
                    height: thumbnailHeight,
                    color: Colors.grey[800],
                    child: const Icon(Icons.image_not_supported, color: Colors.grey),
                  ),
          ),
          const SizedBox(height: 8),
          // --- Title (white text on dark background) ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              exercise.exerciseName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard(String notes) {
    return CustomCard(
      color: Colors.grey[800]!, // dark background for notes
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📋 Prescription Notes',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            notes,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }
}