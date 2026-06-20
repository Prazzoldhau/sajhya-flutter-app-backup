import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  final Map<String, dynamic> patientData;

  const DashboardScreen({super.key, required this.patientData});

  @override
  Widget build(BuildContext context) {
    final name = patientData['patient_name'] ?? 'Patient';
    final code = patientData['patient_code'] ?? 'N/A';

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome, $name!', style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 8),
            Text('Patient Code: $code'),
            const SizedBox(height: 32),
            const Text('Your prescriptions will appear here.'),
          ],
        ),
      ),
    );
  }
}
