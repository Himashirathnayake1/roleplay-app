import 'package:flutter/material.dart';
import 'role_detail_screen.dart';

class Role {
  final String title;
  final String description;
  final String subtitle;
  final IconData icon;

  Role({
    required this.title,
    required this.description,
    required this.subtitle,
    required this.icon,
  });
}

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  static final List<Role> roles = [
    Role(
      title: 'Day-to-Day Life',
      description: 'Practice everyday conversations and greetings',
      subtitle:
          'You are a friendly person engaging in casual everyday conversations. Be warm, helpful, and ask follow-up questions. Keep responses natural and conversational.',
      icon: Icons.wb_sunny_rounded,
    ),
    Role(
      title: 'At a Restaurant',
      description: 'Learn to order food and talk to waiters',
      subtitle:
          'You are a polite and attentive restaurant waiter. Help customers order, suggest popular dishes, answer questions about ingredients, and provide excellent service. Be professional but friendly.',
      icon: Icons.restaurant,
    ),
    Role(
      title: 'At a Hotel',
      description: 'Check-in, ask for service, and more',
      subtitle:
          'You are a helpful hotel receptionist. Assist with check-in, room requests, directions, restaurant reservations, and any guest needs. Be professional, courteous, and efficient.',
      icon: Icons.apartment,
    ),
    Role(
      title: 'At the Office',
      description: 'Professional workplace conversations',
      subtitle:
          'You are a professional colleague in a workplace setting. Engage in business discussions, meetings, and professional interactions. Be formal, respectful, and helpful.',
      icon: Icons.business_center,
    ),
  ];

  void _navigateToRole(BuildContext context, Role role) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) =>
                RoleDetailScreen(title: role.title, description: role.subtitle),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose a Role Play Scenario'),
        elevation: 0.5,
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
          child: ListView.builder(
            itemCount: roles.length,
            itemBuilder: (context, index) {
              final role = roles[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () => _navigateToRole(context, role),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              role.icon,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  role.title,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  role.description,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.grey[400],
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
