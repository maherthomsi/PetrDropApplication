import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petr_drop_application/main.dart'; // Import your main file

void main() {
  test('Test create method', () async {
    await Firebase.initializeApp(); // Initialize Firebase
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Replace with test values
    const double testLat = 37.7749;
    const double testLon = -122.4194;
    const String testId = 'testId';

    await create(testId, testLat, testLon, Timestamp.fromDate(DateTime.now()));

    // Verify that the document is created
    final DocumentSnapshot document =
        await firestore.collection('drops').doc(testId).get();
    expect(document.exists, true);
  });

  test('Test readAll method', () async {
    await Firebase.initializeApp(); // Initialize Firebase
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Replace with test values
    final double testLat = 37.7749;
    final double testLon = -122.4194;
    final String testId = 'testId';

    await create(testId, testLat, testLon, Timestamp.fromDate(DateTime.now()));

    // Call readAll method and verify that it fetches data
    await readAll();

    // You can add more specific assertions based on your application logic
    expect(cardsList.length, greaterThanOrEqualTo(1));
  });

  test('Test fetchUserById method', () async {
    await Firebase.initializeApp(); // Initialize Firebase
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Replace with test values
    final String userId = 'testUserId';

    // Call fetchUserById method and verify that it fetches user data
    await fetchUserById(userId);

    // Add specific assertions based on your application logic
    // For example, check if the fetched user data is correct
  });

  tearDown(() async {
    // Cleanup - delete the documents created during testing
    await Firebase.initializeApp(); // Initialize Firebase
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Replace with the IDs of the documents created during testing
    final List<String> testDocumentIds = ['testId'];

    for (final String documentId in testDocumentIds) {
      await firestore.collection('drops').doc(documentId).delete();
    }
  });
}
