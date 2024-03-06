import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'firebase_options.dart';

// Project By Maher Tarek Homsi, Cameron Bagheri, Sharon Le, and Paul Khayet

const LatLng currentLocation = LatLng(33.6458544, -117.8428335);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const NavigationBarApp());
}

class NavigationBarApp extends StatelessWidget {
  const NavigationBarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: const NavigationExample(),
    );
  }
}

class NavigationExample extends StatefulWidget {
  const NavigationExample({super.key});

  @override
  State<NavigationExample> createState() => _NavigationExampleState();
}

class _NavigationExampleState extends State<NavigationExample> {
  BitmapDescriptor markerIcon = BitmapDescriptor.defaultMarker;

  void addCustomIcon() {
    BitmapDescriptor.fromAssetImage(
            const ImageConfiguration(), "assets/images/petrmarker.png")
        .then(
      (icon) {
        setState(() {
          markerIcon = icon;
        });
      },
    );
  }

  int currentPageIndex = 0;
  late GoogleMapController _mapController;
  late FirebaseFirestore _firestore;

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance; // Initialize FirebaseFirestore
    addCustomIcon();
  }

  @override
  Widget build(BuildContext context) {
    readAll();
    clearStickerAfterDate();
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        indicatorColor: Colors.amber,
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.home),
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.map),
            icon: Badge(child: Icon(Icons.map_outlined)),
            label: 'Map',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.notifications),
            icon: Badge(child: Icon(Icons.notifications_outlined)),
            label: 'Notifications',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            <Widget>[
              /// Home page
              SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height / 2,
                  child: GoogleMap(
                    mapType: MapType.normal,
                    initialCameraPosition: const CameraPosition(
                      target: currentLocation,
                      zoom: 16,
                    ),
                    onMapCreated: (controller) {
                      _mapController = controller;
                    },
                    markers: {
                      Marker(
                          onTap: () {
                            print('Tapped');
                          },
                          draggable: true,
                          markerId: MarkerId('Marker'),
                          position: LatLng(currentLocation.latitude,
                              currentLocation.longitude),
                          onDragEnd: ((newPosition) {
                            print(newPosition.latitude);
                            print(newPosition.longitude);
                          }))
                    },
                  )),

              /// Map page
              SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  child: GoogleMap(
                    gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                      Factory<OneSequenceGestureRecognizer>(
                          () => EagerGestureRecognizer())
                    },
                    mapType: MapType.normal,
                    zoomControlsEnabled: false,
                    initialCameraPosition: const CameraPosition(
                      target: currentLocation,
                      zoom: 16,
                    ),
                    onMapCreated: (controller) {
                      _mapController = controller;
                    },
                    markers: {
                      Marker(
                        markerId: const MarkerId("1"),
                        position: currentLocation,
                        draggable: true,
                        onDragEnd: (value) {},
                        icon: markerIcon,
                      )
                    },
                  )),

              /// Notifications page
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Column(
                  children: <Widget>[
                    Card(
                      child: ListTile(
                        leading: Icon(Icons.notifications_sharp),
                        title: Text('Notification 1'),
                        subtitle: Text('This is a notification'),
                      ),
                    ),
                    Card(
                      child: ListTile(
                        leading: Icon(Icons.notifications_sharp),
                        title: Text('Notification 2'),
                        subtitle: Text('This is a notification'),
                      ),
                    ),
                  ],
                ),
              ),
            ][currentPageIndex],
          ],
        ),
      ),
    );
  }

  void create(String id, double lat, double lon, Timestamp dateTime) {
    final DateTime now = DateTime.now();
    final sticker = <String, dynamic>{
      "id": "1",
      "lat": 33.6458544,
      "lon": -117.8428335,
      "dateTime": Timestamp.fromDate(DateTime.now()), // Use server timestamp
    };

// Add a new document with a generated ID
    _firestore.collection("drops").add(sticker).then((DocumentReference doc) =>
        log('DocumentSnapshot added with ID: ${doc.id}'));
  }

  Future<void> readAll() async {
    await _firestore.collection("drops").get().then((event) {
      for (var doc in event.docs) {
        log("${doc.id} => ${doc.data()}");
      }
    });
  }

  void fetchUserById(String userId) async {
    try {
      // Retrieve a specific document based on the provided doc.id
      DocumentSnapshot userSnapshot =
          await _firestore.collection("users").doc(userId).get();

      if (userSnapshot.exists) {
        // Document exists, print its data
        log("${userSnapshot.id} => ${userSnapshot.data()}");
      } else {
        // Document doesn't exist
        log("Document with ID $userId does not exist.");
      }
    } catch (e) {
      // Handle any errors that might occur during the process
      log("Error fetching user: $e");
    }
  }

  void clearStickerAfterDate() async {
    log("ClearStickerAfterDate entered!");
    CollectionReference dropsCollection = _firestore
        .collection('drops'); // Replace with your actual collection name

    try {
      // Retrieve all documents in the collection
      QuerySnapshot querySnapshot = await dropsCollection.get();

      // Get the current date and time
      DateTime currentDate = DateTime.now();

      // Iterate through the documents
      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        // Check if the document has a 'dateTime' field
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

        if (data != null &&
            data.containsKey('dateTime') &&
            data['dateTime'] != null) {
          // Parse the 'dateTime' field to a DateTime object
          DateTime documentDateTime = data['dateTime'].toDate();

          // Check if the current date is 1 day past the document's 'dateTime'
          if (currentDate.isAfter(documentDateTime.add(Duration(days: 1)))) {
            // Delete the document
            await dropsCollection.doc(doc.id).delete();
            log('Document ${doc.id} deleted.');
          }
        }
      }
    } catch (e) {
      // Handle any errors that might occur during the process
      log("Error clearing stickers: $e");
    }
  }
}
