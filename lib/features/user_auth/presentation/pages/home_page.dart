import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:SafeHaven/jitsi_meet_flutter_sdk.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/services.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

void main() {
  runApp(MaterialApp(
    home: const HomePage(),
  ));
}

class LetterAvatar extends StatelessWidget {
  final String text;
  final double size;
  final Color backgroundColor;
  final Color textColor;

  LetterAvatar({
    required this.text,
    this.size = 48.0,
    this.backgroundColor = const Color.fromARGB(255, 214, 237, 255),
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
      ),
      child: Center(
        child: Text(
          text.isNotEmpty ? text[0].toUpperCase() : '',
          style: TextStyle(
            color: textColor,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  void initState() {
    super.initState();
    // Load the user's profile data when the UserProfile widget is created.
    loadUserProfileData();
    retrieveMeetings();
  }

  // Define the createMeeting function
  @override
  void dispose() async {
    _pageController.dispose();
    super.dispose();
  }

  String uid = '';

  late String meetingTitle = '';
  late String meetingCategory = '';
  String title = '';
  String selectedCategory = 'Help';
  List<String> categories = [
    'Help',
    'Entertainment',
    'Education',
    'Motivation'
  ];

  String? firstName;
  String? lastName;
  String? userProfileImageURL;
  User? user = FirebaseAuth.instance.currentUser;
  String? createdMeetingTitle;
  String? createdMeetingCategory;

  Future<void> loadUserProfileData() async {
    if (user != null) {
      uid = user!.uid;
      print('User UID: ${user?.uid}');
      try {
        final userId = await FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .get();
        if (userId.exists) {
          setState(() {
            firstName = userId.get('firstName');
            lastName = userId.get('lastName');
          });
        } else {
          setState(() {
            firstName = 'No Data';
            lastName = 'No Data';
          });
        }
      } catch (e) {
        print('Error loading user profile data: $e');
        setState(() {
          firstName = 'Error';
          lastName = "Error";
        });
      }
    }
  }

  String lastJoinedMeetingTitle = "";
  String lastJoinedMeetingCategory = "";

  bool audioMuted = true;
  bool videoMuted = true;
  bool screenShareOn = false;
  List<String> participants = [];
  final _jitsiMeetPlugin = JitsiMeet();
  TextFormField? titleFormField;

  Future<List<Map<String, dynamic>>?> getUserCreatedMeetings() async {
    final firestoreInstance = FirebaseFirestore.instance;
    final meetingsRef = firestoreInstance.collection('meetings');

    try {
      final querySnapshot = await meetingsRef
          .where('creatorUid', isEqualTo: uid) // Filter by the user's UID
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print("Error retrieving user's created meetings: $e");
      return null;
    }
  }

  join(room, meeting) async {
    var options = JitsiMeetConferenceOptions(
      serverURL: 'https://meet.mayfirst.org/',
      room: room,
      configOverrides: {
        "startWithAudioMuted": false,
        "startWithVideoMuted": false,
        "subject": meeting
      },
      featureFlags: {
        "unsaferoomwarning.enabled": false,
        "ios.screensharing.enabled": true
      },
      userInfo: JitsiMeetUserInfo(
          displayName: '$firstName',
          email: user?.email ?? 'No Email',
          avatar:
              "https://www.google.com/url?sa=i&url=https%3A%2F%2Fwww.freepik.com%2Ffree-photos-vectors%2Fprofile-avatar&psig=AOvVaw0hVaxc7wmKozKq7vH5Ze0i&ust=1697986222326000&source=images&cd=vfe&opi=89978449&ved=0CBEQjRxqFwoTCPDv392xh4IDFQAAAAAdAAAAABAF"),
    );

    var listener = JitsiMeetEventListener(
      conferenceJoined: (url) {
        debugPrint("conferenceJoined: url: $url");
      },
      conferenceTerminated: (url, error) {
        debugPrint("conferenceTerminated: url: $url, error: $error");
      },
      conferenceWillJoin: (url) {
        debugPrint("conferenceWillJoin: url: $url");
      },
      participantJoined: (email, name, role, participantId) {
        debugPrint(
          "participantJoined: email: $email, name: $name, role: $role, "
          "participantId: $participantId",
        );
        participants.add(participantId!);
      },
      participantLeft: (participantId) {
        debugPrint("participantLeft: participantId: $participantId");
      },
      audioMutedChanged: (muted) {
        debugPrint("audioMutedChanged: isMuted: $muted");
      },
      videoMutedChanged: (muted) {
        debugPrint("videoMutedChanged: isMuted: $muted");
      },
      endpointTextMessageReceived: (senderId, message) {
        debugPrint(
            "endpointTextMessageReceived: senderId: $senderId, message: $message");
      },
      screenShareToggled: (participantId, sharing) {
        debugPrint(
          "screenShareToggled: participantId: $participantId, "
          "isSharing: $sharing",
        );
      },
      chatMessageReceived: (senderId, message, isPrivate, timestamp) {
        debugPrint(
          "chatMessageReceived: senderId: $senderId, message: $message, "
          "isPrivate: $isPrivate, timestamp: $timestamp",
        );
      },
      chatToggled: (isOpen) => debugPrint("chatToggled: isOpen: $isOpen"),
      participantsInfoRetrieved: (participantsInfo) {
        debugPrint(
            "participantsInfoRetrieved: participantsInfo: $participantsInfo, ");
      },
      readyToClose: () {
        debugPrint("readyToClose");
      },
    );
    await _jitsiMeetPlugin.join(options, listener);
    setState(() {
      lastJoinedMeetingTitle = room;
      lastJoinedMeetingCategory = meeting;
    });
  }

  void deleteMeeting(String meetingTitle) async {
    if (uid.isNotEmpty) {
      // Check if the meeting exists in the local list
      if (meetings == null ||
          !meetings!.any((meeting) => meeting['title'] == meetingTitle)) {
        showToast("No meeting to be deleted");
        return;
      }
      bool success = await removeMeetingData(meetingTitle);

      if (success) {
        showToastDeleted("Meeting data deleted successfully");
        // Remove the specific meeting from the meetings list
        meetings?.removeWhere((meeting) => meeting['title'] == meetingTitle);
        setState(() {});
      } else {
        showToast("Error deleting meeting data");
      }
    }

    // Perform other actions for leaving the meeting
  }

  Future<bool> removeMeetingData(String title) async {
    final firestoreInstance = FirebaseFirestore.instance;
    final meetingsRef = firestoreInstance.collection('meetings');

    try {
      final querySnapshot =
          await meetingsRef.where('title', isEqualTo: title).get();

      for (final doc in querySnapshot.docs) {
        await doc.reference.delete();
        print('Deleted meeting document with title: $title');
      }

      return true; // Deletion was successful
    } catch (e) {
      print("Error deleting meeting data: $e"); // Add this line
      return false; // Deletion failed
    }
  }

  void showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  void showToastDeleted(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      timeInSecForIosWeb: 1,
      backgroundColor: Color(0xFF176A98),
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  hangUp() async {
    await _jitsiMeetPlugin.hangUp();
  }

  setAudioMuted(bool? muted) async {
    var a = await _jitsiMeetPlugin.setAudioMuted(muted!);
    debugPrint("$a");
    setState(() {
      audioMuted = muted;
    });
  }

  setVideoMuted(bool? muted) async {
    var a = await _jitsiMeetPlugin.setVideoMuted(muted!);
    debugPrint("$a");
    setState(() {
      videoMuted = muted;
    });
  }

  sendEndpointTextMessage() async {
    var a = await _jitsiMeetPlugin.sendEndpointTextMessage(message: "HEY");
    debugPrint("$a");

    for (var p in participants) {
      var b =
          await _jitsiMeetPlugin.sendEndpointTextMessage(to: p, message: "HEY");
      debugPrint("$b");
    }
  }

  toggleScreenShare(bool? enabled) async {
    await _jitsiMeetPlugin.toggleScreenShare(enabled!);

    setState(() {
      screenShareOn = enabled;
    });
  }

  openChat() async {
    await _jitsiMeetPlugin.openChat();
  }

  sendChatMessage() async {
    var a = await _jitsiMeetPlugin.sendChatMessage(message: "HEY1");
    debugPrint("$a");

    for (var p in participants) {
      a = await _jitsiMeetPlugin.sendChatMessage(to: p, message: "HEY2");
      debugPrint("$a");
    }
  }

  closeChat() async {
    await _jitsiMeetPlugin.closeChat();
  }

  retrieveParticipantsInfo() async {
    var a = await _jitsiMeetPlugin.retrieveParticipantsInfo();
    debugPrint("$a");
  }

  int _currentIndex = 0;
  PageController _pageController = PageController();

  void createMeeting() async {
    final firestoreInstance = FirebaseFirestore.instance;
    final meetingsRef = firestoreInstance.collection('meetings');

    // Check if a meeting with the same title already exists
    final matchingMeetings =
        await meetingsRef.where('title', isEqualTo: title).get();

    if (matchingMeetings.docs.isNotEmpty) {
      // A meeting with the same title already exists.
      // You can notify the user or take appropriate action.
      print('Meeting with the same title already exists.');
      Fluttertoast.showToast(
          msg: "Meeting Title already Exist",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);

      return;
    } else {
      // Proceed to create the meeting and add it to Firebase Firestore
      final newMeeting = {
        'title': title,
        'category': selectedCategory,
        "creatorUid": uid,
        'status':
            'created', // You can include additional data like the meeting's status
        // Add other meeting details as needed
      };
      await meetingsRef.add(newMeeting);
      join(title, selectedCategory);

      // Update the local state to reflect the newly created meeting
      setState(() {
        createdMeetingTitle = title;
        createdMeetingCategory = selectedCategory;
        // Update your UI to show the meeting details
      });
      retrieveMeetings();
    }
  }

  List<String> meetingTitlesList = [];
  List<String> categoryList = [];

  void retrieveMeetings() {
    final firestoreInstance = FirebaseFirestore.instance;
    final meetingsRef = firestoreInstance.collection('meetings');

    // Set up a real-time listener to receive updates
    meetingsRef.snapshots().listen((querySnapshot) {
      List<String> meetingTitles = [];
      List<String> meetingCategories = []; // Create a list for categories

      querySnapshot.docs.forEach((doc) {
        // Access the data from the document
        meetingTitle = doc['title'];
        meetingCategory = doc['category']; // Access the 'category' field
        meetingTitles.add(meetingTitle);
        meetingCategories.add(meetingCategory); // Add the category to the list
      });

      // Update your UI or data model with the retrieved meeting titles and categories
      setState(() {
        meetingTitlesList = meetingTitles;
        categoryList = meetingCategories; // Update the category list
      });
    });
  }

  List<Map<String, dynamic>>? meetings;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Color.fromARGB(0, 255, 255, 255), //top status bar
          statusBarIconBrightness: Brightness.dark,
        ),
        child: Scaffold(
            backgroundColor: const Color(0xFFEFEFEF),
            appBar: null,
            body: PageView(
              physics: NeverScrollableScrollPhysics(),
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              children: <Widget>[
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                          padding: const EdgeInsets.only(
                              top: 45.0,
                              bottom: 12.0,
                              left: 16.0,
                              right: 16.0), // Add the desired padding
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(),
                                ],
                              ),
                              Row(
                                children: [
                                  Text(
                                    'Last Joined Meeting',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 0.07 *
                                          MediaQuery.of(context).size.width,
                                      color: Color(0xFF176A98),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: 10.0,
                              ),
                              if (lastJoinedMeetingTitle.isEmpty)
                                Container(
                                  margin: EdgeInsets.symmetric(
                                      horizontal: 0.0, vertical: 5.0),
                                  padding: EdgeInsets.all(
                                      25), // Add the desired padding
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(
                                        20), // Adjust the radius as needed
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Color.fromARGB(255, 202, 202, 202)
                                                .withOpacity(0.5),
                                        spreadRadius: 2,
                                        blurRadius: 3,
                                        offset: Offset(
                                            0, 1), // changes position of shadow
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "You haven't joined any meeting yet",
                                        style: TextStyle(
                                          fontWeight: FontWeight.normal,
                                          fontSize: 14,
                                          color: Colors.black,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              if (lastJoinedMeetingTitle.isNotEmpty)
                                Container(
                                  margin: EdgeInsets.symmetric(
                                      horizontal: 0.0, vertical: 5.0),
                                  padding: EdgeInsets.all(
                                      16), // Add the desired padding
                                  decoration: BoxDecoration(
                                    gradient: lastJoinedMeetingCategory ==
                                            "Help"
                                        ? LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Color.fromARGB(
                                                  255, 133, 190, 255),
                                              Color.fromARGB(
                                                  255, 180, 200, 242),
                                              Color.fromARGB(
                                                  255, 191, 214, 255),
                                              Color.fromARGB(
                                                  255, 156, 196, 248),
                                            ],
                                          )
                                        : (lastJoinedMeetingCategory ==
                                                "Entertainment"
                                            ? LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  Color.fromARGB(
                                                      255, 133, 212, 255),
                                                  Color.fromARGB(
                                                      255, 180, 220, 242),
                                                  Color.fromARGB(
                                                      255, 191, 233, 255),
                                                  Color.fromARGB(
                                                      255, 156, 216, 248),
                                                ],
                                              )
                                            : lastJoinedMeetingCategory ==
                                                    "Education"
                                                ? LinearGradient(
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                    colors: [
                                                      Color.fromARGB(
                                                          255, 133, 255, 222),
                                                      Color.fromARGB(
                                                          255, 180, 242, 230),
                                                      Color.fromARGB(
                                                          255, 191, 255, 236),
                                                      Color.fromARGB(
                                                          255, 156, 248, 237)
                                                    ],
                                                  )
                                                : LinearGradient(
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                    colors: [
                                                        Color.fromARGB(
                                                            255, 133, 251, 255),
                                                        Color.fromARGB(
                                                            255, 180, 239, 242),
                                                        Color.fromARGB(
                                                            255, 191, 255, 249),
                                                        Color.fromARGB(
                                                            255, 156, 244, 248)
                                                      ])),
                                    borderRadius: BorderRadius.circular(
                                        20), // Adjust the radius as needed
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Color.fromARGB(255, 247, 245, 245)
                                                .withOpacity(0.5),
                                        spreadRadius: 2,
                                        blurRadius: 3,
                                        offset: Offset(
                                            0, 1), // changes position of shadow
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        flex:
                                            2, // Adjust the flex value as needed
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "$lastJoinedMeetingTitle",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: Color(0xFF176A98),
                                              ),
                                            ),
                                            Text(
                                              "$lastJoinedMeetingCategory",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF176A98),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Flexible(
                                        flex:
                                            1, // Adjust the flex value as needed
                                        child: ElevatedButton(
                                          onPressed: () {
                                            String room =
                                                lastJoinedMeetingTitle;
                                            String categorys =
                                                lastJoinedMeetingCategory;

                                            join(room, categorys);
                                          },
                                          child: Text(
                                            "Join",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            primary: Colors.white,
                                            onPrimary: Color(0xFF176A98),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              SizedBox(
                                height: 15.0,
                              ),
                              Row(
                                children: [
                                  Text("Pick a room you're \ninterested with",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 0.07 *
                                            MediaQuery.of(context).size.width,
                                        color: Color(0xFF176A98),
                                      )),
                                ],
                              )
                            ],
                          )),
                      if (meetingTitlesList.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0, 0, 15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: List.generate(
                              meetingTitlesList.length,
                              (index) => Container(
                                  margin: EdgeInsets.symmetric(
                                      horizontal: 16.0, vertical: 5.0),
                                  padding: EdgeInsets.fromLTRB(16, 16, 16,
                                      16), // Add the desired padding
                                  decoration: BoxDecoration(
                                    gradient: categoryList[index] == "Help"
                                        ? LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Color.fromARGB(
                                                  255, 133, 190, 255),
                                              Color.fromARGB(
                                                  255, 180, 200, 242),
                                              Color.fromARGB(
                                                  255, 191, 214, 255),
                                              Color.fromARGB(
                                                  255, 156, 196, 248),
                                            ],
                                          )
                                        : (categoryList[index] ==
                                                "Entertainment"
                                            ? LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  Color.fromARGB(
                                                      255, 133, 212, 255),
                                                  Color.fromARGB(
                                                      255, 180, 220, 242),
                                                  Color.fromARGB(
                                                      255, 191, 233, 255),
                                                  Color.fromARGB(
                                                      255, 156, 216, 248),
                                                ],
                                              )
                                            : categoryList[index] == "Education"
                                                ? LinearGradient(
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                    colors: [
                                                      Color.fromARGB(
                                                          255, 133, 255, 222),
                                                      Color.fromARGB(
                                                          255, 180, 242, 230),
                                                      Color.fromARGB(
                                                          255, 191, 255, 236),
                                                      Color.fromARGB(
                                                          255, 156, 248, 237)
                                                    ],
                                                  )
                                                : LinearGradient(
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                    colors: [
                                                        Color.fromARGB(
                                                            255, 133, 251, 255),
                                                        Color.fromARGB(
                                                            255, 180, 239, 242),
                                                        Color.fromARGB(
                                                            255, 191, 255, 249),
                                                        Color.fromARGB(
                                                            255, 156, 244, 248)
                                                      ])),

                                    borderRadius: BorderRadius.circular(
                                        20), // Adjust the radius as needed
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Color.fromARGB(255, 247, 245, 245)
                                                .withOpacity(0.5),
                                        spreadRadius: 2,
                                        blurRadius: 3,
                                        offset: Offset(
                                            0, 1), // changes position of shadow
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        flex:
                                            2, // Adjust the flex value as needed
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "${meetingTitlesList[index]}",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: Color(0xFF176A98),
                                              ),
                                            ),
                                            Text(
                                              "${categoryList[index]}",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF176A98),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Flexible(
                                        flex:
                                            1, // Adjust the flex value as needed
                                        child: ElevatedButton(
                                          onPressed: () {
                                            String room =
                                                meetingTitlesList[index];
                                            String categorys =
                                                categoryList[index];
                                            join(room, categorys);
                                          },
                                          child: Text(
                                            "Join",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            primary: Colors.white,
                                            onPrimary: Color(0xFF176A98),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 50,
                        ),
                        Container(
                          margin: EdgeInsets.fromLTRB(15, 0, 15, 0),
                          padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Color.fromARGB(
                                    255, 211, 211, 211), // Color of the shadow
                                offset:
                                    Offset(0, 2), // Offset of the shadow (x, y)
                                blurRadius: 5.0, // Spread of the shadow
                                spreadRadius:
                                    1.0, // Optional, controls the intensity of the shadow
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 15.0,
                                  bottom: 5.0,
                                  right: 16.0,
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      "Host your Own Room",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 0.06 *
                                            MediaQuery.of(context).size.width,
                                        color: Color(0xFF176A98),
                                      ),
                                      textAlign: TextAlign.left,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 10.0,
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10.0),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Color(0xFF176A98),
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButtonFormField<String>(
                                  value: selectedCategory,
                                  onChanged: (value) {
                                    setState(() {
                                      selectedCategory = value!;
                                    });
                                  },
                                  items: categories.map((category) {
                                    return DropdownMenuItem<String>(
                                      value: category,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          Text(
                                            category,
                                            style: TextStyle(
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              SizedBox(
                                height: 20.0,
                              ),
                              FractionallySizedBox(
                                child: TextFormField(
                                  keyboardType: TextInputType.multiline,
                                  maxLines: 2,
                                  decoration: InputDecoration(
                                    labelText: 'Title',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  maxLength: 40,
                                  onChanged: (value) {
                                    setState(() {
                                      title = value;
                                    });
                                  },
                                  validator: (value) {
                                    if (title.isEmpty) {
                                      return 'Please enter a title';
                                    }
                                    return null;
                                  },
                                  onSaved: (value) {
                                    titleFormField = title as TextFormField?;
                                  },
                                ),
                              ),
                              SizedBox(
                                height: 10.0,
                              ),
                              FractionallySizedBox(
                                widthFactor: 0.9,
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      width: 0.8 *
                                          MediaQuery.of(context).size.width,
                                      height: 50,
                                      child: FilledButton.tonal(
                                        onPressed: () {
                                          if (title.isEmpty) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    'Title cannot be empty'),
                                              ),
                                            );
                                          } else {
                                            String room = title;
                                            String meeting = selectedCategory;
                                            createMeeting();
                                            join(room, meeting);
                                          }
                                        },
                                        child: const Text(
                                          'Create Room',
                                          style: TextStyle(
                                            fontSize: 17,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 5.0),
                        Divider(
                          color: Color.fromARGB(255, 223, 219, 219),
                        ),
                        FractionallySizedBox(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Padding(
                                    padding:
                                        EdgeInsets.fromLTRB(7.0, 5.0, 0, 5),
                                    child: Text(
                                      "  Your Existing Rooms",
                                      style: TextStyle(
                                        fontSize: 0.06 *
                                            MediaQuery.of(context).size.width,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF176A98),
                                      ),
                                      textAlign: TextAlign.left,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                height: 320,
                                child:
                                    FutureBuilder<List<Map<String, dynamic>>?>(
                                  future: getUserCreatedMeetings(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return Center(
                                          child: CircularProgressIndicator());
                                    } else if (snapshot.hasError) {
                                      return Text("Error: ${snapshot.error}");
                                    } else if (snapshot.data == null) {
                                      return Text("No data available");
                                    } else if (snapshot.data!.isEmpty) {
                                      return Padding(
                                        padding: EdgeInsets.fromLTRB(
                                            20.0, 5.0, 0, 0),
                                        child: Text(
                                          "You haven't created any meeting yet",
                                          style: TextStyle(
                                            fontWeight: FontWeight.normal,
                                            fontSize: 0.04 *
                                                MediaQuery.of(context)
                                                    .size
                                                    .width,
                                            color: Colors.black,
                                          ),
                                        ),
                                      );
                                    } else {
                                      meetings = snapshot.data;
                                      return ListView.builder(
                                        physics: ClampingScrollPhysics(),
                                        padding: EdgeInsets.only(top: 10),
                                        itemCount: snapshot.data!.length,
                                        itemBuilder: (context, index) {
                                          final meetingData =
                                              snapshot.data![index];
                                          return Container(
                                            decoration: BoxDecoration(
                                              gradient: meetingData[
                                                          'category'] ==
                                                      'Help'
                                                  ? LinearGradient(
                                                      begin: Alignment.topLeft,
                                                      end:
                                                          Alignment.bottomRight,
                                                      colors: [
                                                        Color.fromARGB(
                                                            255, 133, 190, 255),
                                                        Color.fromARGB(
                                                            255, 180, 200, 242),
                                                        Color.fromARGB(
                                                            255, 191, 214, 255),
                                                        Color.fromARGB(
                                                            255, 156, 196, 248),
                                                      ],
                                                    )
                                                  : (meetingData['category'] ==
                                                          'Entertainment'
                                                      ? LinearGradient(
                                                          begin:
                                                              Alignment.topLeft,
                                                          end: Alignment
                                                              .bottomRight,
                                                          colors: [
                                                            Color.fromARGB(255,
                                                                133, 212, 255),
                                                            Color.fromARGB(255,
                                                                180, 220, 242),
                                                            Color.fromARGB(255,
                                                                191, 233, 255),
                                                            Color.fromARGB(255,
                                                                156, 216, 248),
                                                          ],
                                                        )
                                                      : meetingData[
                                                                  'category'] ==
                                                              'Education'
                                                          ? LinearGradient(
                                                              begin: Alignment
                                                                  .topLeft,
                                                              end: Alignment
                                                                  .bottomRight,
                                                              colors: [
                                                                Color.fromARGB(
                                                                    255,
                                                                    133,
                                                                    255,
                                                                    222),
                                                                Color.fromARGB(
                                                                    255,
                                                                    180,
                                                                    242,
                                                                    230),
                                                                Color.fromARGB(
                                                                    255,
                                                                    191,
                                                                    255,
                                                                    236),
                                                                Color.fromARGB(
                                                                    255,
                                                                    156,
                                                                    248,
                                                                    237)
                                                              ],
                                                            )
                                                          : LinearGradient(
                                                              begin: Alignment
                                                                  .topLeft,
                                                              end: Alignment
                                                                  .bottomRight,
                                                              colors: [
                                                                  Color
                                                                      .fromARGB(
                                                                          255,
                                                                          133,
                                                                          251,
                                                                          255),
                                                                  Color
                                                                      .fromARGB(
                                                                          255,
                                                                          180,
                                                                          239,
                                                                          242),
                                                                  Color
                                                                      .fromARGB(
                                                                          255,
                                                                          191,
                                                                          255,
                                                                          249),
                                                                  Color
                                                                      .fromARGB(
                                                                          255,
                                                                          156,
                                                                          244,
                                                                          248)
                                                                ])),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            margin: EdgeInsets.symmetric(
                                                horizontal: 15, vertical: 5),
                                            padding:
                                                EdgeInsets.fromLTRB(0, 8, 0, 8),
                                            child: ListTile(
                                              title: Text(
                                                meetingData['title'] ??
                                                    'No Title',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  color: Color(0xFF176A98),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              subtitle: Text(
                                                meetingData['category'] ??
                                                    'No Category',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xFF176A98)),
                                              ),
                                              trailing: Row(
                                                mainAxisSize: MainAxisSize
                                                    .min, // Ensure buttons take the minimum required space
                                                children: [
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      String room =
                                                          meetingData['title'];
                                                      String categorys =
                                                          meetingData[
                                                              'category'];

                                                      join(room, categorys);
                                                    },
                                                    child: Text(
                                                      "Join",
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 15,
                                                      ),
                                                    ),
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      primary: Colors.white,
                                                      onPrimary:
                                                          Color(0xFF176A98),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                      ),
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: Icon(Icons.delete),
                                                    color: Colors.white,
                                                    onPressed: () {
                                                      // Pass the meeting title to the deleteMeeting function
                                                      deleteMeeting(
                                                          meetingData['title']);
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 0.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        // Make sure the Stack can expand to fit the screen
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              child: topBanner(),
                            ),
                            Positioned(
                              top: 230,
                              left: 0,
                              right: 0,
                              child: topBannerContainer(),
                            ),
                            Positioned(
                              top: 160,
                              child: profileImage(),
                            ),
                            Positioned(
                              top: 308,
                              child: Center(
                                child: Text(
                                  "${firstName ?? "loading"}",
                                  style: TextStyle(
                                    color: Color(0xFF176A98),
                                    fontSize: 20.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 340,
                              child: Text(
                                user?.email ?? 'No Email',
                                style: TextStyle(
                                  fontSize: 13.0,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 400,
                              child: Container(
                                padding: EdgeInsets.all(10.0),
                                width: 350,
                                height: 180,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey,
                                      offset: Offset(0, 2),
                                      blurRadius: 4,
                                      spreadRadius: 0,
                                    ),
                                  ],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.only(
                                          left: 10.0, top: 10.0),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          "Bio",
                                          style: TextStyle(
                                            fontSize: 20.0,
                                            color: Color(0xFF176A98),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(10.0),
                                      child: Text(
                                        "${lastName ?? "No Email"}",
                                        style: TextStyle(
                                          fontSize: 14.0,
                                          color: Colors.black,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              top: 510,
                              child: SizedBox(
                                width:
                                    250, // Set a specific width for the button
                                child: FilledButton.tonal(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: Text('Confirm Logout'),
                                          content: Text(
                                              'Are you sure you want to logout?'),
                                          actions: <Widget>[
                                            TextButton(
                                              onPressed: () {
                                                // Cancel the logout
                                                Navigator.of(context).pop();
                                              },
                                              child: Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () async {
                                                if (FirebaseAuth
                                                        .instance.currentUser !=
                                                    null) {
                                                  try {
                                                    await FirebaseAuth.instance
                                                        .signOut();
                                                    // Successful logout, navigate to the login screen
                                                    Navigator.pushNamed(
                                                        context, "/login");
                                                    hangUp();
                                                    print(
                                                        "Logout is successful");
                                                  } catch (e) {
                                                    // Handle any sign-out errors here
                                                    print(
                                                        "Error during logout: $e");
                                                    // You can display an error message to the user here
                                                  }
                                                } else {
                                                  // User is not authenticated, handle this scenario as needed
                                                  print(
                                                      "User is not authenticated.");
                                                  // You can show a message to the user or take appropriate action
                                                }
                                              },
                                              child: Text('Logout'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment
                                        .center, // Center the icon and text within the button
                                    children: [
                                      Icon(Icons.logout,
                                          color: Colors
                                              .white), // The logout icon on the left
                                      SizedBox(
                                          width:
                                              8), // Space between icon and text
                                      Text('Logout',
                                          style: TextStyle(
                                              color: Colors.white)), // The text
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            bottomNavigationBar: Builder(
              builder: (BuildContext context) {
                return Container(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(50.0, 6.0, 50.0, 6.0),
                    child: GNav(
                      selectedIndex: _currentIndex,
                      onTabChange: (int index) {
                        if (index == 3) {
                          // Open the right-sided drawer when clicking "Settings"
                          Scaffold.of(context).openEndDrawer();
                        } else {
                          setState(() {
                            _currentIndex = index;
                            _pageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          });
                        }
                      },
                      tabs: [
                        GButton(
                          icon: Icons.home,
                          text: 'Home',
                          iconColor: Colors.grey,
                          textColor: Color(0xFF1C5A8A),
                        ),
                        GButton(
                          icon: Icons.video_call,
                          text: 'Create Room',
                          iconColor: Colors.grey,
                          textColor: Color(0xFF1C5A8A),
                        ),
                        GButton(
                          icon: Icons.person,
                          text: 'Profile',
                          iconColor: Colors.grey,
                          textColor: Color(0xFF1C5A8A),
                        ),

                        // Add more GButton widgets as needed
                      ],
                      gap: 15,
                      backgroundColor: Colors.white,
                      activeColor: Color(0xFF1C5A8A),
                      hoverColor: Color.fromARGB(
                          255, 222, 241, 255), // tab button hover color

                      iconSize: 24,
                      tabBackgroundColor: Color.fromARGB(255, 229, 255, 253),
                      padding:
                          EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                    ),
                  ),
                );
              },
            )));
  }

  Widget topBannerContainer() => Container(
        width: double.infinity,
        height: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey,
              offset: Offset(0, 2),
              blurRadius: 4,
              spreadRadius: 0,
            ),
          ],
        ),
      );
  Widget topBanner() => Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
                "assets/fullpoto.jpg"), // Replace with your image asset or network image
            fit: BoxFit
                .cover, // This will cover the entire space of the container, cropping as necessary
          ),
        ),
        width: double.infinity,
        height: 230,
      );

  Widget profileImage() => Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 140.0,
            height: 140.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white, // Add a background color if needed
            ),
          ),
          CircleAvatar(
            radius: 65.0,
            backgroundImage: userProfileImageURL != null
                ? NetworkImage(userProfileImageURL!)
                : null,
            child: userProfileImageURL == null
                ? Text(
                    user?.email?.substring(0, 1) ?? '',
                    style: TextStyle(
                      fontSize: 40.0,
                    ),
                  )
                : null,
          ),
        ],
      );
}
