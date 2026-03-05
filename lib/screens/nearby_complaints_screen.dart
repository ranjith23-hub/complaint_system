import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

import '../models/complaint_model.dart';
import 'package:complaint_system/screens/complaint_detail_screen.dart';
import '../services/app_localizations.dart';

class NearbyComplaintsScreen extends StatefulWidget {
  const NearbyComplaintsScreen({super.key});

  @override
  State<NearbyComplaintsScreen> createState() => _NearbyComplaintsScreenState();
}

class _NearbyComplaintsScreenState extends State<NearbyComplaintsScreen> {
  double? centerLat;
  double? centerLon;
  double _currentRadius = 10.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserDefaultLocation();
  }

  Future<void> _loadUserDefaultLocation() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final userDoc = await FirebaseFirestore.instance.collection('Users').doc(uid).get();
        if (userDoc.exists && userDoc.data() != null) {
          setState(() {
            centerLat = (userDoc.data()!['latitude'] as num?)?.toDouble() ?? 11.0168;
            centerLon = (userDoc.data()!['longitude'] as num?)?.toDouble() ?? 76.9558;
          });
        } else {
          _setFallbackLocation();
        }
      } else {
        _setFallbackLocation();
      }
    } catch (e) {
      _setFallbackLocation();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _setFallbackLocation() {
    centerLat = 11.0168;
    centerLon = 76.9558;
  }

  Future<void> _getCurrentLocation(TextEditingController controller) async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      Position pos = await Geolocator.getCurrentPosition();
      setState(() {
        centerLat = pos.latitude;
        centerLon = pos.longitude;
        controller.text = "Current Location";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)?.translate('nearby_complaints') ?? "Nearby Complaints")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: TypeAheadField<String>(
              suggestionsCallback: (search) async {
                if (search.length < 2) return null; // Returning null keeps existing suggestions

                final encodedSearch = Uri.encodeComponent(search);
                final url = Uri.parse('https://photon.komoot.io/api/?q=$search&limit=5');

                try {
                  final response = await http.get(url);
                  if (response.statusCode == 200) {
                    final Map<String, dynamic> data = json.decode(utf8.decode(response.bodyBytes));
                    final List features = data['features'] ?? [];

                    return features.map((f) {
                      final p = f['properties'] ?? {};
                      List<String> parts = [];
                      if (p['name'] != null) parts.add(p['name'].toString());
                      if (p['city'] != null) parts.add(p['city'].toString());
                      if (p['state'] != null) parts.add(p['state'].toString());

                      return parts.join(', ');
                    }).where((s) => s.isNotEmpty).toList();
                  }
                } catch (e) {
                  debugPrint("Autocomplete Error: $e");
                }
                return [];
              },
              builder: (context, controller, focusNode) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    hintText: "Search location...",
                    prefixIcon: const Icon(Icons.location_on, color: Colors.redAccent),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.my_location, color: Colors.blue),
                      onPressed: () => _getCurrentLocation(controller),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                );
              },
              itemBuilder: (context, String suggestion) {
                return ListTile(
                  leading: const Icon(Icons.place, size: 18),
                  title: Text(suggestion),
                );
              },
              onSelected: (suggestion) async {
                try {
                  List<Location> locations = await locationFromAddress(suggestion);
                  if (locations.isNotEmpty) {
                    setState(() {
                      centerLat = locations.first.latitude;
                      centerLon = locations.first.longitude;
                    });
                  }
                } catch (e) {
                  debugPrint("Geocoding error: $e");
                }
              },
              loadingBuilder: (context) => const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("Searching..."),
              ),
              errorBuilder: (context, error) => const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("Connect to the internet to see results."),
              ),
              emptyBuilder: (context) => const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("No locations found."),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _currentRadius,
                    min: 1, max: 50,
                    divisions: 49,
                    onChanged: (v) => setState(() => _currentRadius = v),
                  ),
                ),
                Text("${_currentRadius.round()} km"),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('complaints').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text("Error loading data"));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final docs = snapshot.data!.docs;
                var nearby = docs.map((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  var complaint = Complaint.fromFirestore(data);

                  double dist = 0.0;
                  if (complaint.latitude != null && complaint.longitude != null && centerLat != null) {
                    dist = Geolocator.distanceBetween(
                        centerLat!, centerLon!,
                        complaint.latitude!, complaint.longitude!
                    ) / 1000;
                  }
                  return {'complaint': complaint, 'distance': dist};
                }).where((item) => (item['distance'] as double) <= _currentRadius).toList();

                nearby.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));

                if (nearby.isEmpty) return const Center(child: Text("No complaints nearby."));

                return ListView.builder(
                  itemCount: nearby.length,
                  itemBuilder: (context, index) {
                    final item = nearby[index];
                    final c = item['complaint'] as Complaint;
                    return ListTile(
                      title: Text(c.title),
                      subtitle: Text("${(item['distance'] as double).toStringAsFixed(1)} km away"),
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (context) => ComplaintDetailsPage(complaint: c)
                      )),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}