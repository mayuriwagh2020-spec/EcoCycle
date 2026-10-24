import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'profile_screen.dart';

const String baseUrl = 'https://ecocycle-hue5.onrender.com';

class RecyclerDashboard extends StatefulWidget {
  const RecyclerDashboard({super.key});

  @override
  State<RecyclerDashboard> createState() =>
      _RecyclerDashboardState();
}

class _RecyclerDashboardState
    extends State<RecyclerDashboard> {
  int currentIndex = 0;

  final List<Widget> pages = const [
    RecyclerHome(),
    RecyclerRequests(),
    RecyclerProfile(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.recycling),
            label: 'E-Waste',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}


// ============================================================
// RECYCLER HOME
// ============================================================

class RecyclerHome extends StatefulWidget {
  const RecyclerHome({super.key});

  @override
  State<RecyclerHome> createState() => _RecyclerHomeState();
}

class _RecyclerHomeState extends State<RecyclerHome> {
  bool loading = true;

  int incoming = 0;
  int processing = 0;
  int recycled = 0;

  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    loadRequests();
  }

  Future<void> loadRequests() async {
    try {
      final prefs =
          await SharedPreferences.getInstance();

      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        setState(() {
          loading = false;
          errorMessage =
              'No login token found. Please login again.';
        });
        return;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/pickups/recycler'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print(
        'Recycler HTTP STATUS: ${response.statusCode}',
      );

      print(
        'Recycler RESPONSE: ${response.body}',
      );

      if (response.statusCode != 200) {
        dynamic data;

        try {
          data = jsonDecode(response.body);
        } catch (_) {}

        setState(() {
          loading = false;
          errorMessage =
              'Server error ${response.statusCode}: '
              '${data?['message'] ?? response.body}';
        });

        return;
      }

      final data = jsonDecode(response.body);

      final List<dynamic> serverRequests =
          List<dynamic>.from(
        data['requests'] ?? [],
      );

      if (!mounted) return;

      setState(() {
        incoming = serverRequests.length;
        loading = false;
        errorMessage = '';
      });
    } catch (e) {
      print('Recycler ERROR: $e');

      if (!mounted) return;

      setState(() {
        loading = false;
        errorMessage = 'Connection error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recycler Dashboard'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: loadRequests,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Welcome, Recycler!',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Manage incoming e-waste',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 25),

            if (errorMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                margin:
                    const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius:
                      BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.red.shade300,
                  ),
                ),
                child: Text(
                  errorMessage,
                  style: TextStyle(
                    color: Colors.red.shade800,
                  ),
                ),
              ),

            if (loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              ),

            if (!loading)
              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      'Incoming',
                      incoming.toString(),
                      Icons.inventory_2,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _statCard(
                      'Processing',
                      processing.toString(),
                      Icons.settings,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _statCard(
                      'Recycled',
                      recycled.toString(),
                      Icons.check_circle,
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 25),

            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.recycling),
                ),
                title: const Text(
                  'View Incoming E-Waste',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  'View items sent by collectors',
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const RecyclerRequests(),
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

  Widget _statCard(
    String title,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 18,
        horizontal: 8,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}


// ============================================================
// RECYCLER REQUESTS
// ============================================================

class RecyclerRequests extends StatefulWidget {
  const RecyclerRequests({super.key});

  @override
  State<RecyclerRequests> createState() =>
      _RecyclerRequestsState();
}

class _RecyclerRequestsState
    extends State<RecyclerRequests> {
  bool loading = true;

  List<dynamic> requests = [];

  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    loadRequests();
  }

  Future<void> loadRequests() async {
    setState(() {
      loading = true;
      errorMessage = '';
    });

    try {
      final prefs =
          await SharedPreferences.getInstance();

      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        setState(() {
          loading = false;
          errorMessage =
              'No login token found. Please login again.';
        });
        return;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/pickups/recycler'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print(
        'Recycler Requests STATUS: '
        '${response.statusCode}',
      );

      print(
        'Recycler Requests RESPONSE: '
        '${response.body}',
      );

      dynamic data;

      try {
        data = jsonDecode(response.body);
      } catch (_) {
        setState(() {
          loading = false;
          errorMessage =
              'Invalid server response.\n\n'
              '${response.body}';
        });
        return;
      }

      if (response.statusCode != 200) {
        setState(() {
          loading = false;
          errorMessage =
              'Server error: HTTP '
              '${response.statusCode}\n\n'
              '${data['message'] ?? response.body}';
        });
        return;
      }

      final List<dynamic> serverRequests =
          List<dynamic>.from(
        data['requests'] ?? [],
      );

      if (!mounted) return;

      setState(() {
        requests = serverRequests;
        loading = false;
        errorMessage = '';
      });
    } catch (e) {
      print('Recycler request error: $e');

      if (!mounted) return;

      setState(() {
        loading = false;
        errorMessage =
            'Connection error: $e';
      });
    }
  }

  Future<void> completeRequest(
    String requestId,
  ) async {
    try {
      final prefs =
          await SharedPreferences.getInstance();

      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        showMessage('Please login again.');
        return;
      }

      final response = await http.put(
        Uri.parse(
          '$baseUrl/api/pickups/$requestId/complete',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print(
        'Complete status: ${response.statusCode}',
      );

      print(
        'Complete response: ${response.body}',
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        showMessage(
          'E-waste marked as recycled successfully.',
        );

        await loadRequests();
      } else {
        showMessage(
          data['message'] ??
              'Could not complete recycling.',
        );
      }
    } catch (e) {
      showMessage(
        'Connection error: $e',
      );
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incoming E-Waste'),
        actions: [
          IconButton(
            onPressed: loadRequests,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : errorMessage.isNotEmpty
              ? Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 60,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          errorMessage,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: loadRequests,
                          child: const Text(
                            'Try Again',
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : requests.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 70,
                          ),
                          SizedBox(height: 15),
                          Text(
                            'No e-waste received yet.',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Items sent by collectors will appear here.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: loadRequests,
                      child: ListView.builder(
                        padding:
                            const EdgeInsets.all(16),
                        itemCount: requests.length,
                        itemBuilder:
                            (context, index) {
                          final request =
                              requests[index];

                          final requestId =
                              (request['_id'] ??
                                      request['id'] ??
                                      '')
                                  .toString();

                          final itemName =
                              request['itemName']
                                      ?.toString() ??
                                  '';

                          final category =
                              request['category']
                                      ?.toString() ??
                                  '';

                          final quantity =
                              request['quantity']
                                      ?.toString() ??
                                  '';

                          final address =
                              request['address']
                                      ?.toString() ??
                                  '';

                          final status =
                              request['status']
                                      ?.toString() ??
                                  '';

                          final household =
                              request['household'];

                          final collector =
                              request['collector'];

                          String householdName =
                              '';

                          String householdPhone =
                              '';

                          String collectorName =
                              '';

                          if (household is Map) {
                            householdName =
                                household['name']
                                        ?.toString() ??
                                    '';

                            householdPhone =
                                household['phone']
                                        ?.toString() ??
                                    '';
                          }

                          if (collector is Map) {
                            collectorName =
                                collector['name']
                                        ?.toString() ??
                                    '';
                          }

                          return Card(
                            margin:
                                const EdgeInsets.only(
                              bottom: 16,
                            ),
                            elevation: 3,
                            child: Padding(
                              padding:
                                  const EdgeInsets.all(
                                16,
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons
                                            .devices_other,
                                        size: 32,
                                      ),
                                      const SizedBox(
                                        width: 12,
                                      ),
                                      Expanded(
                                        child: Text(
                                          itemName,
                                          style:
                                              const TextStyle(
                                            fontSize: 20,
                                            fontWeight:
                                                FontWeight
                                                    .bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const Divider(
                                    height: 25,
                                  ),

                                  _detailRow(
                                    Icons.category,
                                    'Category',
                                    category,
                                  ),

                                  _detailRow(
                                    Icons.numbers,
                                    'Quantity',
                                    quantity,
                                  ),

                                  _detailRow(
                                    Icons.location_on,
                                    'Address',
                                    address,
                                  ),

                                  if (householdName
                                      .isNotEmpty)
                                    _detailRow(
                                      Icons.person,
                                      'Household',
                                      householdName,
                                    ),

                                  if (householdPhone
                                      .isNotEmpty)
                                    _detailRow(
                                      Icons.phone,
                                      'Household Phone',
                                      householdPhone,
                                    ),

                                  if (collectorName
                                      .isNotEmpty)
                                    _detailRow(
                                      Icons.local_shipping,
                                      'Collector',
                                      collectorName,
                                    ),

                                  _detailRow(
                                    Icons.info,
                                    'Status',
                                    status,
                                  ),

                                  const SizedBox(
                                    height: 15,
                                  ),

                                  SizedBox(
                                    width:
                                        double.infinity,
                                    child:
                                        ElevatedButton
                                            .icon(
                                      onPressed:
                                          requestId
                                                  .isEmpty
                                              ? null
                                              : () {
                                                  completeRequest(
                                                    requestId,
                                                  );
                                                },
                                      icon: const Icon(
                                        Icons
                                            .check_circle,
                                      ),
                                      label:
                                          const Text(
                                        'Mark as Recycled',
                                      ),
                                    ),
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

  Widget _detailRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                ),
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: value,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// ============================================================
// PROFILE
// ============================================================

class RecyclerProfile extends StatelessWidget {
  const RecyclerProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfileScreen();
  }
}