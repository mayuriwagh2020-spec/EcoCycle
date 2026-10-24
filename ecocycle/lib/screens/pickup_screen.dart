import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PickupScreen extends StatefulWidget {
  const PickupScreen({super.key});

  @override
  State<PickupScreen> createState() => _PickupScreenState();
}

class _PickupScreenState extends State<PickupScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController itemNameController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();

  DateTime? selectedDate;
  XFile? selectedImage;
  Uint8List? selectedImageBytes;

  bool isLoading = false;

  String selectedCategory = 'Mobile Phone';

  final List<String> categories = [
    'Mobile Phone',
    'Laptop',
    'Computer',
    'Tablet',
    'Television',
    'Refrigerator',
    'Washing Machine',
    'Printer',
    'Battery',
    'Other',
  ];

  static const String baseUrl = 'https://ecocycle-hue5.onrender.com';

  @override
  void dispose() {
    itemNameController.dispose();
    quantityController.dispose();
    addressController.dispose();
    notesController.dispose();
    super.dispose();
  }

  // ============================================================
  // SELECT IMAGE (Web-Safe)
  // ============================================================
  Future<void> pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (image == null) {
        return;
      }

      final bytes = await image.readAsBytes();

      setState(() {
        selectedImage = image;
        selectedImageBytes = bytes;
      });
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not select image: $error'),
        ),
      );
    }
  }

  // ============================================================
  // UPLOAD IMAGE TO SUPABASE (Web-Safe)
  // ============================================================
  Future<String> uploadImage() async {
    if (selectedImage == null || selectedImageBytes == null) {
      return '';
    }

    final supabase = Supabase.instance.client;
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? 'unknown-user';

    final fileExtension = selectedImage!.name.split('.').last.toLowerCase();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
    final filePath = '$userId/$fileName';

    await supabase.storage.from('ewaste-images').uploadBinary(
          filePath,
          selectedImageBytes!,
          fileOptions: FileOptions(
            contentType: 'image/$fileExtension',
            upsert: false,
          ),
        );

    final imageUrl = supabase.storage
        .from('ewaste-images')
        .getPublicUrl(filePath);

    return imageUrl;
  }

  // ============================================================
  // SELECT DATE
  // ============================================================
  Future<void> selectDate() async {
    final DateTime now = DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  // ============================================================
  // CREATE PICKUP REQUEST
  // ============================================================
  Future<void> submitPickupRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a preferred pickup date'),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        throw Exception('You are not logged in');
      }

      // ----------------------------------------------------------
      // 1. Upload image to Supabase
      // ----------------------------------------------------------
      String imageUrl = '';

      if (selectedImage != null) {
        imageUrl = await uploadImage();
      }

      // ----------------------------------------------------------
      // 2. Create pickup request in MongoDB through API
      // ----------------------------------------------------------
      final response = await http.post(
        Uri.parse('$baseUrl/api/pickups'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'itemName': itemNameController.text.trim(),
          'category': selectedCategory,
          'quantity': int.parse(quantityController.text.trim()),
          'address': addressController.text.trim(),
          'preferredDate': selectedDate!.toIso8601String(),
          'notes': notesController.text.trim(),
          'imageUrl': imageUrl,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Pickup request created successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Clear form
        itemNameController.clear();
        quantityController.clear();
        addressController.clear();
        notesController.clear();

        setState(() {
          selectedDate = null;
          selectedImage = null;
          selectedImageBytes = null;
          selectedCategory = 'Mobile Phone';
        });

        Navigator.pop(context);
      } else {
        throw Exception(
          responseData['message'] ?? 'Failed to create pickup request',
        );
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule E-Waste Pickup'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'E-Waste Details',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // ==================================================
              // ITEM NAME
              // ==================================================
              TextFormField(
                controller: itemNameController,
                decoration: const InputDecoration(
                  labelText: 'Item Name',
                  hintText: 'Example: Old Samsung Mobile',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.devices),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter item name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // ==================================================
              // CATEGORY
              // ==================================================
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'E-Waste Category',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    selectedCategory = value;
                  });
                },
              ),

              const SizedBox(height: 16),

              // ==================================================
              // QUANTITY
              // ==================================================
              TextFormField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  hintText: 'Example: 2',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter quantity';
                  }
                  final quantity = int.tryParse(value);
                  if (quantity == null || quantity < 1) {
                    return 'Enter a valid quantity';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // ==================================================
              // ADDRESS
              // ==================================================
              TextFormField(
                controller: addressController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Pickup Address',
                  hintText: 'Enter complete pickup address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter pickup address';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // ==================================================
              // DATE
              // ==================================================
              InkWell(
                onTap: selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Preferred Pickup Date',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_month),
                  ),
                  child: Text(
                    selectedDate == null
                        ? 'Select date'
                        : '${selectedDate!.day}/'
                            '${selectedDate!.month}/'
                            '${selectedDate!.year}',
                    style: TextStyle(
                      fontSize: 16,
                      color: selectedDate == null
                          ? Colors.grey
                          : Colors.black,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ==================================================
              // IMAGE SECTION (Web-Safe with Image.memory)
              // ==================================================
              const Text(
                'E-Waste Image',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              if (selectedImageBytes != null)
                Container(
                  width: double.infinity,
                  height: 220,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green,
                      width: 2,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.memory(
                    selectedImageBytes!,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey,
                    ),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_outlined,
                        size: 50,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'No image selected',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isLoading ? null : pickImage,
                  icon: const Icon(Icons.photo_library),
                  label: Text(
                    selectedImage == null
                        ? 'Select E-Waste Image'
                        : 'Change Image',
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ==================================================
              // NOTES
              // ==================================================
              TextFormField(
                controller: notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Additional Notes',
                  hintText: 'Any additional information...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes),
                ),
              ),

              const SizedBox(height: 28),

              // ==================================================
              // SUBMIT BUTTON
              // ==================================================
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : submitPickupRequest,
                  icon: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.local_shipping),
                  label: Text(
                    isLoading ? 'Submitting...' : 'Schedule Pickup',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}