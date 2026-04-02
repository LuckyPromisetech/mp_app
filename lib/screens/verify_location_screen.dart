import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class VerifyLocationScreen extends StatefulWidget {
  const VerifyLocationScreen({Key? key}) : super(key: key);

  @override
  State<VerifyLocationScreen> createState() => _VerifyLocationScreenState();
}

class _VerifyLocationScreenState extends State<VerifyLocationScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Position? _currentPosition;
  bool _loading = false;
  String? selectedState;

  Future<void> _getCurrentLocation() async {
    setState(() => _loading = true);

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enable location services")),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permission denied")),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Location permission permanently denied. Please enable it from settings.",
          ),
        ),
      );
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to get location: $e")));
    }
  }

  Future<void> _saveLocation() async {
    final user = _auth.currentUser;
    if (user == null || selectedState == null) return;

    try {
      await _firestore.collection('sellers').doc(user.uid).update({
        'state': selectedState,
        'location': _currentPosition != null
            ? {
                'latitude': _currentPosition!.latitude,
                'longitude': _currentPosition!.longitude,
                'verifiedAt': FieldValue.serverTimestamp(),
              }
            : null,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location verified successfully!")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to save location: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color orange = Color(0xFFFF8C00);
    const Color navy = Color(0xFF0A1D37);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Verify Location"),
        backgroundColor: navy,
        iconTheme: const IconThemeData(color: orange),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // State Dropdown
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('states').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }
                final states = snapshot.data!.docs;
                return DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: "Select Your State",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  value: selectedState,
                  items: states
                      .map(
                        (doc) => DropdownMenuItem<String>(
                          value: doc.id,
                          child: Text(doc.id),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() => selectedState = value);
                  },
                );
              },
            ),
            const SizedBox(height: 20),

            // Get Current Location button
            ElevatedButton.icon(
              icon: const Icon(Icons.my_location),
              label: const Text("Get Current Location"),
              style: ElevatedButton.styleFrom(
                backgroundColor: orange,
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: _loading ? null : _getCurrentLocation,
            ),
            const SizedBox(height: 20),

            // Show GPS coordinates if available
            if (_currentPosition != null)
              Text(
                "Latitude: ${_currentPosition!.latitude}\nLongitude: ${_currentPosition!.longitude}",
                style: const TextStyle(fontSize: 16, color: Colors.white),
                textAlign: TextAlign.center,
              ),

            const Spacer(),

            // Save button
            ElevatedButton(
              onPressed: selectedState != null
                  ? _saveLocation
                  : null, // require state
              style: ElevatedButton.styleFrom(
                backgroundColor: navy,
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text(
                "Verify & Save Location",
                style: TextStyle(color: orange, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: orange,
    );
  }
}
