import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import 'firebase_options.dart';

// Project By Maher Tarek Homsi, Cameron Bagheri, Sharon Le, and Paul Khayet

const LatLng currentLocation = LatLng(33.6458544, -117.8428335);
Map<MarkerId, Marker> markers = <MarkerId, Marker>{};

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
  bool _isLoading = false;
  List<Card> cardsList = [];

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance; // Initialize FirebaseFirestore
    addCustomIcon();
  }

  @override
  Widget build(BuildContext context) {
    readAll();
    updateCards();
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
                    markers: Set<Marker>.of(markers.values),
                  )),

              /// Notifications page
              Padding(
                padding: EdgeInsets.all(8.0),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  child:
                    ListView.builder(
                      itemCount: cardsList.length,
                      itemBuilder: (context, index) {
                        return cardsList[index];
                      },
                    )
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
      "id": id,
      "lat": lat,
      "lon": lon,
      "dateTime": Timestamp.fromDate(DateTime.now()), // Use server timestamp
    };

// Add a new document with a generated ID
    _firestore.collection("drops").add(sticker).then((DocumentReference doc) =>
        log('DocumentSnapshot added with ID: ${doc.id}'));
  }

  Future<void> updateCards() async {
    QuerySnapshot<Map<String, dynamic>> snapshot =
    await _firestore.collection("drops").get();

    List<Card> cards = [];
    for (var doc in snapshot.docs) {
      print("Here");
      String documentId = getDocumentId(doc);
      double latitude = getLatitude(doc);
      double longitude = getLongitude(doc);
      DateTime dateTime = getDateTime(doc).toDate();
      DateTime currentDate = DateTime.now();

      // Formatting date and time
      String formattedDateTime = DateFormat.yMMMd().add_jms().format(dateTime);

      // Creating a Card for each document
      if (documentId != 'Error') {
        Card card = Card(
          child: ListTile(
            leading: Image.asset('assets/images/petr.png'),
            title: Text('Petr Name: $documentId'),
            subtitle: Text('Date and Time: $formattedDateTime'),
          ),
        );

        cards.add(card); // Add the card to the list
      }
    }
    setState(() {
      cardsList = cards; // Update the state with the new list of cards
    });
  }

  Future<void> readAll() async {
    await _firestore.collection("drops").get().then((event) {
      for (var doc in event.docs) {
        //log("${doc.id} => ${doc.data()}");
        String documentId = getDocumentId(doc);
        double latitude = getLatitude(doc);
        double longitude = getLongitude(doc);
        DateTime dateTime = getDateTime(doc).toDate();
        DateTime currentDate = DateTime.now();

        markers.clear();
        if (currentDate.isAfter(dateTime)) {
          _add(documentId, latitude, longitude);
        }
      }
    });
  }

  void fetchUserById(String userId) async {
    try {
      DocumentSnapshot userSnapshot =
          await _firestore.collection("users").doc(userId).get();

      if (userSnapshot.exists) {
        log("${userSnapshot.id} => ${userSnapshot.data()}");
      } else {
        log("Document with ID $userId does not exist.");
      }
    } catch (e) {
      log("Error fetching user: $e");
    }
  }

  void clearStickerAfterDate() async {
    //log("ClearStickerAfterDate entered!");
    CollectionReference dropsCollection = _firestore.collection('drops');

    try {
      QuerySnapshot querySnapshot = await dropsCollection.get();

      DateTime currentDate = DateTime.now();

      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

        if (data != null &&
            data.containsKey('dateTime') &&
            data['dateTime'] != null) {
          DateTime documentDateTime = data['dateTime'].toDate();
          //log("dateTime = $documentDateTime");

          // Check if the current date is 1 day past the document's 'dateTime'
          if (currentDate
              .isAfter(documentDateTime.add(const Duration(days: 1)))) {
            log('Document ${doc.id} deleted.');
            await dropsCollection.doc(doc.id).delete();
          }
        }
      }
    } catch (e) {
      log("Error clearing stickers: $e");
    }
  }

  String getDocumentId(DocumentSnapshot documentSnapshot) {
    Map<String, dynamic>? data =
    documentSnapshot.data() as Map<String, dynamic>?;

    if (data != null && data.containsKey('id')) {
      return data['id'] as String;
    }

    return 'Error';

  }

  double getLatitude(DocumentSnapshot documentSnapshot) {
    Map<String, dynamic>? data =
        documentSnapshot.data() as Map<String, dynamic>?;

    if (data != null && data.containsKey('lat')) {
      return data['lat'] as double;
    }

    return 0.0;
  }

  double getLongitude(DocumentSnapshot documentSnapshot) {
    Map<String, dynamic>? data =
        documentSnapshot.data() as Map<String, dynamic>?;

    if (data != null && data.containsKey('lon')) {
      return data['lon'] as double;
    }

    return 0.0;
  }

  Timestamp getDateTime(DocumentSnapshot documentSnapshot) {
    Map<String, dynamic>? data =
        documentSnapshot.data() as Map<String, dynamic>?;

    if (data != null && data.containsKey('dateTime')) {
      return data['dateTime'] as Timestamp;
    }

    return Timestamp.fromDate(DateTime.now());
  }

  void _add(id, lat, lon) {
    var markerIdVal = id;
    final MarkerId markerId = MarkerId(markerIdVal);

    // creating a new MARKER
    final Marker marker = Marker(
      markerId: markerId,
      position: LatLng(
        lat,
        lon,
      ),
      infoWindow: InfoWindow(title: markerIdVal, snippet: '*'),
      onTap: () {},
    );

    setState(() {
      // adding a new marker to map
      markers[markerId] = marker;
      //log("markers = $markers");
      //log("added marker $id");
    });
  }
}
