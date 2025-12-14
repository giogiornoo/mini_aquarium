import 'dart:typed_data';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'fishtank.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Upload fish to Firestore (storing image as base64)
  Future<void> uploadFish({
    required String name,
    required String description,
    required Uint8List imageBytes,
  }) async {
    try {
      // Convert image to base64
      final String base64Image = base64Encode(imageBytes);

      // Save to Firestore
      await _firestore.collection('fish').add({
        'name': name,
        'description': description,
        'imageData': base64Image,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('Fish uploaded successfully!');
    } catch (e) {
      print('Error uploading fish: $e');
      rethrow;
    }
  }

  /// Download all fish from Firestore
  Future<List<Fish>> loadAllFish() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('fish')
          .orderBy('createdAt', descending: true)
          .get();

      List<Fish> fishList = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final String base64Image = data['imageData'];

        // Decode base64 to bytes
        final Uint8List imageBytes = base64Decode(base64Image);

        fishList.add(Fish(
          name: data['name'] ?? 'Unknown',
          description: data['description'] ?? '',
          imageBytes: imageBytes,
        ));
      }

      print('Loaded ${fishList.length} fish from Firebase');
      return fishList;
    } catch (e) {
      print('Error loading fish: $e');
      return [];
    }
  }

  /// Listen to real-time fish updates
  Stream<List<Fish>> streamAllFish() {
    return _firestore
        .collection('fish')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      List<Fish> fishList = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final String base64Image = data['imageData'];

        try {
          final Uint8List imageBytes = base64Decode(base64Image);

          fishList.add(Fish(
            name: data['name'] ?? 'Unknown',
            description: data['description'] ?? '',
            imageBytes: imageBytes,
          ));
        } catch (e) {
          print('Error decoding fish image: $e');
        }
      }

      return fishList;
    });
  }
}
