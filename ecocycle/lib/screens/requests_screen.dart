import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  static const String baseUrl = 'https://ecocycle-hue5.onrender.com';

  List<dynamic> requests = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchRequests();
  }

  Future<void> fetchRequests() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        setState(() {
          isLoading = false;
          errorMessage = 'Please login again.';
        });
        return;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/pickups/my'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;

      if (response.statusCode != 200) {
        setState(() {
          isLoading = false;
          errorMessage =
              'Server error: ${response.statusCode}';
        });
        return;
      }

      final data = jsonDecode(response.body);

      final receivedRequests = data['requests'];

      if (receivedRequests is List) {
        setState(() {
          requests = receivedRequests;
          isLoading = false;
        });
      } else {
        setState(() {
          requests = [];
          isLoading = false;
          errorMessage = 'Invalid request data received.';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = 'Could not connect to server.';
      });
    }
  }

  String formatDate(dynamic date) {
    if (date == null) {
      return '-';
    }

    try {
      final parsed = DateTime.parse(date.toString());

      return '${parsed.day.toString().padLeft(2, '0')}/'
          '${parsed.month.toString().padLeft(2, '0')}/'
          '${parsed.year}';
    } catch (_) {
      return date.toString();
    }
  }

  Color statusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;

      case 'Collector Assigned':
        return Colors.blue;

      case 'Pickup Scheduled':
        return Colors.indigo;

      case 'Picked Up':
        return Colors.purple;

      case 'Sent to Recycler':
        return Colors.teal;

      case 'Completed':
        return Colors.green;

      default:
        return Colors.grey;
    }
  }

  Widget requestCard(dynamic request) {
    final itemName = request['itemName']?.toString() ?? 'E-Waste';
    final category = request['category']?.toString() ?? '-';
    final quantity = request['quantity']?.toString() ?? '-';
    final address = request['address']?.toString() ?? '-';
    final date = request['preferredDate'];
    final notes = request['notes']?.toString() ?? '';
    final status = request['status']?.toString() ?? 'Pending';

    final color = statusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 18),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ITEM
            Row(
              children: [
                const CircleAvatar(
                  radius: 25,
                  child: Icon(Icons.recycling),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    itemName,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // STATUS
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: color,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.local_shipping,
                    color: color,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Pickup Status:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      status,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // DETAILS
            const Text(
              'Pickup Details',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            detailRow(
              Icons.category,
              'Category',
              category,
            ),

            detailRow(
              Icons.numbers,
              'Quantity',
              quantity,
            ),

            detailRow(
              Icons.location_on,
              'Address',
              address,
            ),

            detailRow(
              Icons.calendar_today,
              'Pickup Date',
              formatDate(date),
            ),

            if (notes.isNotEmpty)
              detailRow(
                Icons.notes,
                'Notes',
                notes,
              ),
          ],
        ),
      ),
    );
  }

  Widget detailRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.grey.shade700,
          ),
          const SizedBox(width: 10),
          Text(
            '$title: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Pickup Requests'),
        actions: [
          IconButton(
            onPressed: fetchRequests,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 60,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 15),
                        Text(
                          errorMessage!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: fetchRequests,
                          child: const Text('TRY AGAIN'),
                        ),
                      ],
                    ),
                  ),
                )
              : requests.isEmpty
                  ? RefreshIndicator(
                      onRefresh: fetchRequests,
                      child: ListView(
                        children: const [
                          SizedBox(height: 180),
                          Center(
                            child: Icon(
                              Icons.inbox_outlined,
                              size: 70,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 15),
                          Center(
                            child: Text(
                              'No pickup requests yet.',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: fetchRequests,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: requests.length,
                        itemBuilder: (context, index) {
                          return requestCard(
                            requests[index],
                          );
                        },
                      ),
                    ),
    );
  }
}