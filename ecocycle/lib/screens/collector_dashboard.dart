import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'profile_screen.dart';

class CollectorDashboard extends StatefulWidget {
  const CollectorDashboard({super.key});

  @override
  State<CollectorDashboard> createState() =>
      _CollectorDashboardState();
}

class _CollectorDashboardState extends State<CollectorDashboard> {
  int currentIndex = 0;

  static const String baseUrl = 'https://ecocycle-hue5.onrender.com';

  @override
  Widget build(BuildContext context) {
    final pages = [
      const CollectorHome(),
      const CollectorRequests(),
      const CollectorProfile(),
    ];

    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_shipping_outlined),
            selectedIcon: Icon(Icons.local_shipping),
            label: 'Pickups',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// COLLECTOR HOME
// ============================================================

class CollectorHome extends StatefulWidget {
  const CollectorHome({super.key});

  @override
  State<CollectorHome> createState() => _CollectorHomeState();
}

class _CollectorHomeState extends State<CollectorHome> {
  static const String baseUrl = 'https://ecocycle-hue5.onrender.com';

  bool isLoading = true;
  String errorMessage = '';

  int newCount = 0;
  int activeCount = 0;
  int completedCount = 0;

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        throw Exception('Login session not found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/pickups/collector'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to load dashboard (${response.statusCode})',
        );
      }

      final data = jsonDecode(response.body);
      final List requests = data['requests'] ?? [];

      int newRequests = 0;
      int activeRequests = 0;
      int completedRequests = 0;

      for (final request in requests) {
        final status = request['status'];

        if (status == 'Pending') {
          newRequests++;
        } else if (status == 'Completed') {
          completedRequests++;
        } else {
          activeRequests++;
        }
      }

      if (!mounted) return;

      setState(() {
        newCount = newRequests;
        activeCount = activeRequests;
        completedCount = completedRequests;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collector Dashboard'),
      ),
      body: RefreshIndicator(
        onRefresh: loadDashboard,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Welcome, Collector!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Manage e-waste pickup requests',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 24),

            if (isLoading)
              const Center(
                child: CircularProgressIndicator(),
              )
            else if (errorMessage.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    errorMessage,
                    style: const TextStyle(
                      color: Colors.red,
                    ),
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'New',
                      value: '$newCount',
                      icon: Icons.notifications_active,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      title: 'Active',
                      value: '$activeCount',
                      icon: Icons.local_shipping,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      title: 'Completed',
                      value: '$completedCount',
                      icon: Icons.check_circle,
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 28),

            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.local_shipping),
                ),
                title: const Text('View Pickup Requests'),
                subtitle: const Text(
                  'View e-waste details and customer images',
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CollectorRequestsPage(),
                    ),
                  );
                },
              ),
            ),

            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.update),
                ),
                title: const Text('Update Pickup Status'),
                subtitle: const Text(
                  'Manage pickup progress',
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CollectorRequestsPage(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// STAT CARD
// ============================================================

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 8,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
              color: Colors.green,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// COLLECTOR REQUESTS
// ============================================================

class CollectorRequests extends StatelessWidget {
  const CollectorRequests({super.key});

  @override
  Widget build(BuildContext context) {
    return const CollectorRequestsPage();
  }
}

class CollectorRequestsPage extends StatefulWidget {
  const CollectorRequestsPage({super.key});

  @override
  State<CollectorRequestsPage> createState() =>
      _CollectorRequestsPageState();
}

class _CollectorRequestsPageState
    extends State<CollectorRequestsPage> {
  static const String baseUrl = 'https://ecocycle-hue5.onrender.com';

  bool isLoading = true;
  String errorMessage = '';

  List requests = [];

  @override
  void initState() {
    super.initState();
    loadRequests();
  }

  Future<void> loadRequests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        throw Exception('Login session not found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/pickups/collector'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
          'HTTP ${response.statusCode}: ${response.body}',
        );
      }

      final data = jsonDecode(response.body);

      if (!mounted) return;

      setState(() {
        requests = data['requests'] ?? [];
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString();
        isLoading = false;
      });
    }
  }

  Future<void> acceptRequest(String requestId) async {
    await updateStatus(
      requestId,
      'assign',
      null,
    );
  }

  Future<void> updateStatus(
    String requestId,
    String action,
    String? status,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        throw Exception('Login session not found');
      }

      late http.Response response;

      if (action == 'assign') {
        response = await http.put(
          Uri.parse(
            '$baseUrl/api/pickups/$requestId/assign',
          ),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
      } else {
        response = await http.put(
          Uri.parse(
            '$baseUrl/api/pickups/$requestId/status',
          ),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'status': status,
          }),
        );
      }

      final data = jsonDecode(response.body);

      if (response.statusCode != 200) {
        throw Exception(
          data['message'] ?? 'Request failed',
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            data['message'] ?? 'Updated successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );

      await loadRequests();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget buildStatusButton(Map request) {
    final String status = request['status'] ?? 'Pending';
    final String id = request['_id'];

    if (status == 'Pending') {
      return ElevatedButton.icon(
        onPressed: () => acceptRequest(id),
        icon: const Icon(Icons.check),
        label: const Text('Accept Pickup'),
      );
    }

    if (status == 'Collector Assigned') {
      return ElevatedButton.icon(
        onPressed: () => updateStatus(
          id,
          'status',
          'Pickup Scheduled',
        ),
        icon: const Icon(Icons.calendar_month),
        label: const Text('Schedule Pickup'),
      );
    }

    if (status == 'Pickup Scheduled') {
      return ElevatedButton.icon(
        onPressed: () => updateStatus(
          id,
          'status',
          'Picked Up',
        ),
        icon: const Icon(Icons.inventory),
        label: const Text('Mark Picked Up'),
      );
    }

    if (status == 'Picked Up') {
      return ElevatedButton.icon(
        onPressed: () => updateStatus(
          id,
          'status',
          'Sent to Recycler',
        ),
        icon: const Icon(Icons.recycling),
        label: const Text('Send to Recycler'),
      );
    }

    return const SizedBox.shrink();
  }

  Widget buildImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.trim().isEmpty) {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: 50,
              color: Colors.grey,
            ),
            SizedBox(height: 8),
            Text(
              'No image uploaded',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        imageUrl,
        width: double.infinity,
        height: 220,
        fit: BoxFit.cover,
        loadingBuilder:
            (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }

          return Container(
            height: 220,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 220,
            width: double.infinity,
            color: Colors.grey.shade200,
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image_outlined,
                  size: 50,
                  color: Colors.grey,
                ),
                SizedBox(height: 8),
                Text('Unable to load image'),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pickup Requests'),
      ),
      body: RefreshIndicator(
        onRefresh: loadRequests,
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : errorMessage.isNotEmpty
                ? ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Text(
                        errorMessage,
                        style: const TextStyle(
                          color: Colors.red,
                        ),
                      ),
                    ],
                  )
                : requests.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 180),
                          Center(
                            child: Text(
                              'No pickup requests found',
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: requests.length,
                        itemBuilder: (context, index) {
                          final request = requests[index];

                          final household =
                              request['household'];

                          final imageUrl =
                              request['imageUrl'];

                          return Card(
                            margin: const EdgeInsets.only(
                              bottom: 16,
                            ),
                            elevation: 3,
                            child: Padding(
                              padding:
                                  const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  // ==========================
                                  // IMAGE
                                  // ==========================
                                  const Text(
                                    'E-Waste Image',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  buildImage(imageUrl),

                                  const SizedBox(height: 16),

                                  // ==========================
                                  // ITEM
                                  // ==========================
                                  Text(
                                    request['itemName'] ??
                                        'Unknown Item',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  _InfoRow(
                                    icon: Icons.category,
                                    label: 'Category',
                                    value:
                                        request['category'] ??
                                            '-',
                                  ),

                                  _InfoRow(
                                    icon: Icons.numbers,
                                    label: 'Quantity',
                                    value:
                                        '${request['quantity'] ?? '-'}',
                                  ),

                                  _InfoRow(
                                    icon: Icons.location_on,
                                    label: 'Address',
                                    value:
                                        request['address'] ??
                                            '-',
                                  ),

                                  _InfoRow(
                                    icon:
                                        Icons.calendar_month,
                                    label: 'Pickup Date',
                                    value:
                                        request[
                                                'preferredDate'] ??
                                            '-',
                                  ),

                                  const Divider(
                                    height: 28,
                                  ),

                                  // ==========================
                                  // HOUSEHOLD
                                  // ==========================
                                  const Text(
                                    'Household Details',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  _InfoRow(
                                    icon: Icons.person,
                                    label: 'Name',
                                    value:
                                        household?['name'] ??
                                            '-',
                                  ),

                                  _InfoRow(
                                    icon: Icons.email,
                                    label: 'Email',
                                    value:
                                        household?['email'] ??
                                            '-',
                                  ),

                                  _InfoRow(
                                    icon: Icons.phone,
                                    label: 'Phone',
                                    value:
                                        household?['phone'] ??
                                            '-',
                                  ),

                                  const SizedBox(height: 12),

                                  // ==========================
                                  // STATUS
                                  // ==========================
                                  Container(
                                    padding:
                                        const EdgeInsets
                                            .symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green
                                          .withOpacity(0.1),
                                      borderRadius:
                                          BorderRadius
                                              .circular(20),
                                    ),
                                    child: Text(
                                      'Status: ${request['status'] ?? '-'}',
                                      style:
                                          const TextStyle(
                                        fontWeight:
                                            FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // ==========================
                                  // ACTION
                                  // ==========================
                                  SizedBox(
                                    width: double.infinity,
                                    child:
                                        buildStatusButton(
                                            request),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}

// ============================================================
// INFO ROW
// ============================================================

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.green,
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// COLLECTOR PROFILE
// ============================================================

class CollectorProfile extends StatelessWidget {
  const CollectorProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfileScreen();
  }
}