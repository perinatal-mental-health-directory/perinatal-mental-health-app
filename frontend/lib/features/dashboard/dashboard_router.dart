// frontend/lib/features/dashboard/dashboard_router.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'dashboard.dart';
import 'professional_dashboard.dart';

class DashboardRouter extends StatelessWidget {
  const DashboardRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final userRole = authProvider.user?['role']?.toString().toLowerCase();

        // Handle both formats: 'professional'/'Professional' and 'nhs_staff'/'NHS Staff'
        final isProfessional = userRole == 'professional' ||
            userRole == 'nhs_staff' ||
            userRole == 'nhs staff'; // Handle space variant too

        if (isProfessional) {
          return const ProfessionalDashboardScreen();
        }

        // Show regular dashboard for parents/service users
        return const DashboardScreen();
      },
    );
  }
}