import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
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
  if (!kDebugMode) {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
      appleProvider: AppleProvider.appAttest,
      webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
    );
  } else {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.debug,
    );
  }
  runApp(const NavigationBarApp());
}

class NavigationBarApp extends StatelessWidget {
  const NavigationBarApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: const NavigationExample(),
    );
  }
}

class NavigationExample extends StatefulWidget {
  const NavigationExample({Key? key});

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

  int currentPageIndex = 1;
  late GoogleMapController _mapController;
  late FirebaseFirestore _firestore;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  bool _isLoading = false;
  List<Card> cardsList = [];
  late File _image;

  // Define variables to hold the latitude and longitude
  late double latitude;
  late double longitude;
  final dateFormat = DateFormat("yyyy-MM-dd");
  final timeFormat = DateFormat("HH:mm");

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance; // Initialize FirebaseFirestore
    addCustomIcon();
    // Initialize latitude and longitude with default values
    latitude = currentLocation.latitude;
    longitude = currentLocation.longitude;
  }

  @override
  Widget build(BuildContext context) {
    Future uploadPic(BuildContext context) async {
      String fileName = "${DateTime.now().millisecondsSinceEpoch}.png";
      Reference firebaseStorageRef = _storage.ref().child(fileName);
      UploadTask uploadTask = firebaseStorageRef.putFile(_image);
      TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() =>
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text("Image Uploaded"))));
    }

    Future getImage(BuildContext context) async {
      var image = await ImagePicker().pickImage(source: ImageSource.gallery);
      File file = File(image!.path);

      setState(() {
        _image = file;
        print("Image Path ${file.path}");
        uploadPic(context);
      });
    }

    readAll();
    clearStickerAfterDate();
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      body: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          children: [
            if (currentPageIndex == 0) // Display only for the Home page
              SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: Stack(
                  children: [
                    GoogleMap(
                      mapType: MapType.normal,
                      initialCameraPosition: CameraPosition(
                        target: LatLng(latitude,
                            longitude), // Use latitude and longitude variables
                        zoom: 16,
                      ),
                      onMapCreated: (controller) {
                        _mapController = controller;
                      },
                      markers: {
                        Marker(
                          onTap: () {
                            print('Tapped');
                            getImage(context);
                          },
                          draggable: true,
                          markerId: MarkerId('Marker'),
                          position: LatLng(latitude,
                              longitude), // Use latitude and longitude variables
                          onDragEnd: ((newPosition) {
                            // Update latitude and longitude when dragging ends
                            setState(() {
                              latitude = newPosition.latitude;
                              longitude = newPosition.longitude;
                            });
                            print(newPosition.latitude);
                            print(newPosition.longitude);
                          }),
                        ),
                      },
                    ),
                    Positioned(
                      bottom: 80.0, // Adjusted position to raise it higher
                      left: 0,
                      right: 0,
                      child: Container(
                        color: Colors.white, // Set the background color here
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Enter Name',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) {
                                // Handle name changes here
                                print('Name changed: $value');
                              },
                            ),
                            SizedBox(height: 8.0),
                            Text(
                              'Latitude: ${latitude.toStringAsFixed(6)}, Longitude: ${longitude.toStringAsFixed(6)}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8.0),
                            Row(
                              children: [
                                Expanded(
                                  child: DateTimeField(
                                    initialValue: DateTime.now(),
                                    format: dateFormat,
                                    onShowPicker: (context, currentValue) {
                                      return showDatePicker(
                                          context: context,
                                          firstDate: DateTime(1900),
                                          initialDate:
                                              currentValue ?? DateTime.now(),
                                          lastDate: DateTime(2100));
                                    },
                                  ),
                                ),
                                SizedBox(width: 8.0),
                                Expanded(
                                  child: DateTimeField(
                                    initialValue: DateTime.now(),
                                    format: timeFormat,
                                    onShowPicker:
                                        (context, currentValue) async {
                                      final time = await showTimePicker(
                                        context: context,
                                        initialTime: TimeOfDay.fromDateTime(
                                            currentValue ?? DateTime.now()),
                                      );
                                      return DateTimeField.convert(time);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (currentPageIndex == 1) // Display only for the Map page
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
                  child: ListView.builder(
                    itemCount: cardsList.length,
                    itemBuilder: (context, index) {
                      return cardsList[index];
                    },
                  )),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
            if (currentPageIndex == 2) {
              updateCards();
            }
          });
        },
        indicatorColor: Colors.amber,
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.add_circle),
            icon: Icon(Icons.add_circle_outline),
            label: 'Add Drop',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.map),
            icon: Icon(Icons.map_outlined),
            label: 'Map',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.notifications),
            icon: Icon(Icons.notifications_outlined),
            label: 'All Drops',
          ),
        ],
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

  Future<String?> downloadImage(String filename) async {
    try {
      String downloadURL = await FirebaseStorage.instance
          .ref()
          .child("petr.png")
          .getDownloadURL();
      print("downloadUrl = $downloadURL");
      return downloadURL;
    } on FirebaseException catch (e) {
      print('Error downloading image: $e');
      // Handle the error appropriately
      return null;
    }
  }

  Future<void> updateCards() async {
    QuerySnapshot<Map<String, dynamic>> snapshot =
        await _firestore.collection("drops").get();

    List<Card> cards = [];
    for (var doc in snapshot.docs) {
      String documentId = getDocumentId(doc);
      DateTime dateTime = getDateTime(doc).toDate();

      // Formatting date and time
      String formattedDateTime = DateFormat.yMMMd().add_jms().format(dateTime);

      // Creating a Card for each document
      if (documentId != 'Error') {
        String imageName = "petr";
        String? downloadURL = await downloadImage('$imageName.png');
        Card card = Card(
          child: ListTile(
            leading: downloadURL != null
                ? Image.network(
                    downloadURL,
                    width: 50.0, // Set the width as needed
                    height: 50.0, // Set the height as needed
                    fit: BoxFit.cover,
                  )
                : Image.asset(
                    'assets/images/petr.png', // Replace with a placeholder image
                    width: 50.0,
                    height: 50.0,
                    fit: BoxFit.cover,
                  ),
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
      markers.clear();
      for (var doc in event.docs) {
        //log("${doc.id} => ${doc.data()}");
        String documentId = getDocumentId(doc);
        double latitude = getLatitude(doc);
        double longitude = getLongitude(doc);
        DateTime dateTime = getDateTime(doc).toDate();
        DateTime currentDate = DateTime.now();

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
