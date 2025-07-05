import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mcsh_cbt/theme.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            context.goNamed('adminLogin');
          },
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Admin Dashboard'),
        backgroundColor: AppColors.darkPurple,
        foregroundColor: AppColors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Determine number of grid columns based on screen width
            int crossAxisCount;
            double itemHeight;
            
            if (constraints.maxWidth < 600) {
              // Mobile layout (1 column)
              crossAxisCount = 1;
              itemHeight = 140;
            } else if (constraints.maxWidth < 900) {
              // Tablet layout (2 columns)
              crossAxisCount = 2;
              itemHeight = 160;
            } else {
              // Desktop layout (3 columns)
              crossAxisCount = 3;
              itemHeight = 180;
            }

            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: (constraints.maxWidth / crossAxisCount) / itemHeight,
              ),
              itemCount: 4, // Number of dashboard items
              itemBuilder: (context, index) {
                // Define dashboard items
                final dashboardItems = [
                  {
                    'icon': Icons.school,
                    'title': 'Teacher Management',
                    'subtitle': 'Approve Teachers & Assign to Grades',
                    'color': AppColors.lightPurple,
                    'route': 'adminTeacherManagement',
                  },
                  {
                    'icon': Icons.people,
                    'title': 'Student Management',
                    'subtitle': 'Register Students & Courses',
                    'color': AppColors.darkPurple,
                    'route': 'students',
                  },
                  {
                    'icon': Icons.assignment,
                    'title': 'Exam Management',
                    'subtitle': 'Create and Schedule Exams',
                    'color': AppColors.red,
                    'route': 'adminExamsManagement',
                  },
                  {
                    'icon': Icons.bar_chart,
                    'title': 'Results',
                    'subtitle': 'View and Manage Exam Results',
                    'color': AppColors.darkGrey,
                    'route': 'adminResultsManagement',
                  },
                ];

                final item = dashboardItems[index];
                return _buildDashboardItem(
                  context,
                  icon: item['icon'] as IconData,
                  title: item['title'] as String,
                  subtitle: item['subtitle'] as String,
                  color: item['color'] as Color,
                  route: item['route'] as String,
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildDashboardItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required String route,
  }) {
    // Responsive text sizes
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    final titleSize = isSmallScreen ? 16.0 : 18.0;
    final subtitleSize = isSmallScreen ? 12.0 : 14.0;
    final iconSize = isSmallScreen ? 36.0 : 48.0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: AppColors.darkPurple),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Navigation would go here
          context.pushNamed(route);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Navigating to $title')),
          );
        },
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
          child: Row(
            children: [
              Icon(
                icon,
                size: iconSize,
                color: color,
              ),
              SizedBox(width: isSmallScreen ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 4 : 8),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: subtitleSize,
                        color: AppColors.darkGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}