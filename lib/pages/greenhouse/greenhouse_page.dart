import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:node_auth/pages/CalculationPage.dart';
import 'package:node_auth/pages/firstpage.dart';
import 'package:node_auth/pages/greenhouse/greenhouse_details.dart';
import '../login/login_page.dart';

late String cropSpacing;
late String dripperDischarge;
late String rowSpacing;
late String selectedCrop;
late String selectedDate;
late String selectedDuration;
late String selectedWettingArea;
var pan = '0';
var pans = "0";

class GreenHouseDetailsPage extends StatefulWidget {
  static const routeName = '/green_house_details_page';

  const GreenHouseDetailsPage({super.key});

  @override
  _GreenHouseDetailsPageState createState() => _GreenHouseDetailsPageState();
}

class _GreenHouseDetailsPageState extends State<GreenHouseDetailsPage> {
  String kannanKey = '0';
  Greenhouse? greenhouseRetrievedDetails;
  String? selectedGreenKey;
  String kannanKeys = '0';
  String? userEmail; // Add a variable to store the email

  @override
  void initState() {
    super.initState();
    fetchUserEmail();
    fetchData();
  }

  void fetchUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userEmail = prefs.getString('userEmail'); // Get the email from shared preferences
      print('User email: $userEmail'); // Print the email
    });
  }

  String formatEmail(String email) {
    // Replace '@' and '.' with '_'
    return email.replaceAll('@', '_').replaceAll('.', '_');
  }

  void fetchData() async {
    if (userEmail == null) return; // Make sure the email is fetched before proceeding

    final formattedEmail = formatEmail(userEmail!);
    final DatabaseReference ref = FirebaseDatabase.instance.ref('user/$formattedEmail/greenhouseDetails');

    await ref.once().then((event) {
      final DataSnapshot snapshot = event.snapshot;
      print(snapshot.value.toString());

      setState(() {
        kannanKey = snapshot.value.toString(); // Update kannanKey with the retrieved value
      });
    }).catchError((error) {
      print('Failed to fetch data: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    // Extract Green keys from kannanKey and convert them into a list
    final List<String> greenKeys = extractGreenKeys(kannanKey);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to Automated Irrigation System'),
        titleTextStyle: const TextStyle(fontSize: 19),
        backgroundColor: Colors.green[700],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                '',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  LoginPage.routeName,
                      (_) => false,
                );
              },
              child: const Text('Log Out'),
            ),
            ElevatedButton(
              onPressed: () {
                clearUserData(context);
              },
              child: const Text('Delete Account'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // Set the button color to red
              ),
            ),
            if (userEmail != null)
              Text(
                'User email: ${formatEmail(userEmail!)}', // Display the formatted email
                style: const TextStyle(fontSize: 16.0, color: Colors.white),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
      backgroundColor: Colors.purple[50],
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          margin: const EdgeInsets.symmetric(vertical: 60.0),
          decoration: BoxDecoration(
            color: Colors.green[400],
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Select the greenhouse to load value',
                style: TextStyle(fontSize: 20, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  // Show the dropdown menu
                  showGreenKeysDropdown(context, greenKeys);
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0), // Rounded corners
                  ),
                ),
                child: Text(selectedGreenKey ?? 'Select a Greenhouse device '),
              ),
              const SizedBox(height: 16.0),
            ],
          ),
        ),
      ),
    );
  }

  void clearUserData(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print('All shared preferences cleared');
    Navigator.of(context).pushNamedAndRemoveUntil(
      LoginPage.routeName,
          (_) => false,
    );
  }

  void showGreenKeysDropdown(BuildContext context, List<String> greenKeys) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select a Greenhouse device'),
          content: DropdownButton<String>(
            hint: const Text("--no devices selected--"),
            value: selectedGreenKey, // Set the selected value
            onChanged: (String? newValue) {
              setState(() {
                selectedGreenKey = newValue; // Update the selected value
              });
              // Close the dialog
              Navigator.of(context).pop();
              // Call a function to fetch data from Firebase
              fetchDataFromFirebase(newValue);
            },
            items: greenKeys.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void fetchPanFromFirebase(String? selectedGreenKey) async {
    if (userEmail == null) return; // Make sure the email is fetched before proceeding

    final formattedEmail = formatEmail(userEmail!);
    final DatabaseReference ref = FirebaseDatabase.instance.ref('user/$formattedEmail/greenhouseDetails/$selectedGreenKey/pan');

    await ref.once().then((event) {
      final DataSnapshot snapshot = event.snapshot;
      print('pan value: ${snapshot.value.toString()}');
      print(userEmail);

      setState(() {
        pans = snapshot.value.toString(); // Update pans with the retrieved value
      });

      // After fetching the pan value, navigate to the CropDetailsPage
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CropDetailsPage(
            greenKey: selectedGreenKey,
            pan: pans,
          ),
        ),
      );
    }).catchError((error) {
      print('Failed to fetch pan value: $error');
    });
  }

  void fetchDataFromFirebase(String? selectedGreenKey) async {
    if (userEmail == null) return; // Make sure the email is fetched before proceeding

    final formattedEmail = formatEmail(userEmail!);
    final DatabaseReference ref = FirebaseDatabase.instance.ref('user/$formattedEmail/greenhouseDetails/$selectedGreenKey');

    await ref.once().then((event) {
      final DataSnapshot snapshot = event.snapshot;
      print(snapshot.value.toString());
      print('green:$selectedGreenKey');

      final Map<dynamic, dynamic>? data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        // If data is not null, check if it contains 'cropSpacing'
        if (data.containsKey('cropSpacing')) {
          // If 'cropSpacing' is present, assign values and navigate to CalculationPage
          assignValuesFromFirebase(data);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CalculationPage(
                greenKey: selectedGreenKey,
                pan: pan,
                cropSpacing: cropSpacing,
                dripperDischarge: dripperDischarge,
                rowSpacing: rowSpacing,
                selectedCrop: selectedCrop,
                selectedDate: DateTime.parse(selectedDate),
                selectedDuration: selectedDuration,
                //selectedWettingArea: selectedWettingArea,
              ),
            ),
          );
        } else {
          // If 'cropSpacing' is not present, fetch the 'pan' value and navigate to CropDetailsPage
          fetchPanFromFirebase(selectedGreenKey);
        }
      }
    }).catchError((error) {
      print('Failed to fetch data: $error');
    });
  }

  void assignValuesFromFirebase(Map<dynamic, dynamic> data) {
    print('Pan:$pan');
    setState(() {
      cropSpacing = data['cropSpacing'].toString();
      dripperDischarge = data['dripperDischarge'].toString();
      rowSpacing = data['rowSpacing'].toString();
      selectedCrop = data['selectedCrop'].toString();
      selectedDate = data['selectedDate'].toString();
      selectedDuration = data['selectedDuration'].toString();
      selectedWettingArea = data['selectedWettingArea'].toString();
      pan = data['pan'].toString();
    });
  }

  List<String> extractGreenKeys(String kannanKey) {
    // Define a regular expression pattern to match "GreenX"
    final RegExp regex = RegExp(r'Green\d');

    // Find all matches in the kannanKey string
    final Iterable<RegExpMatch> matches = regex.allMatches(kannanKey);

    // Extract matched substrings
    final List<String> greenKeys = matches.map((match) => match.group(0)!).toList();

    return greenKeys;
  }

  void navigateToLogin() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      LoginPage.routeName,
          (_) => false,
    );
  }
}



// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/material.dart';
// import 'package:node_auth/pages/greenhouse/greenhouse_details.dart';
// import 'package:node_auth/pages/firstpage.dart';
// import 'package:node_auth/pages/CalculationPage.dart';
//
// import '../login/login_page.dart';
//
// late String cropSpacing;
// late String dripperDischarge;
// late String rowSpacing;
// late String selectedCrop;
// late String selectedDate;
// late String selectedDuration;
// late String selectedWettingArea;
// var pan = '0';
// var pans = "0";
// class GreenHouseDetailsPage extends StatefulWidget {
//   static const routeName = '/green_house_details_page';
//
//   const GreenHouseDetailsPage({super.key});
//   @override
//   _GreenHouseDetailsPageState createState() => _GreenHouseDetailsPageState();
// }
//
// class _GreenHouseDetailsPageState extends State<GreenHouseDetailsPage> {
//   String kannanKey = '0';
//   Greenhouse? greenhouseRetrievedDetails;
//   String? selectedGreenKey;
//   String kannanKeys ='0';
//
//
//   @override
//   void initState() {
//     super.initState();
//     fetchData();
//   }
//
//   void fetchData() async {
//     final DatabaseReference ref = FirebaseDatabase.instance.ref('user/1@gmail/greenhouseDetails');
//     await ref.once().then((event) {
//       final DataSnapshot snapshot = event.snapshot;
//       print(snapshot.value.toString());
//
//       setState(() {
//         kannanKey = snapshot.value.toString(); // Update kannanKey with the retrieved value
//       });
//     }).catchError((error) {
//       print('Failed to fetch data: $error');
//     });
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     // Extract Green keys from kannanKey and convert them into a list
//     final List<String> greenKeys = extractGreenKeys(kannanKey);
//
//
//     return Scaffold(
//
//       appBar: AppBar(
//         title: const Text('Welcome to Automated Irrigation System'),
//         titleTextStyle: const TextStyle(fontSize: 19),
//         backgroundColor: Colors.green[700],
//       ),
//       drawer: Drawer(
//         child: ListView(
//           padding: EdgeInsets.zero,
//           children: [
//             const DrawerHeader(
//               decoration: BoxDecoration(
//                 color: Colors.blue,
//               ),
//               child: Text(
//                 '',
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 24,
//                 ),
//               ),
//             ),
//             ElevatedButton(
//               onPressed: () {
//                 Navigator.of(context).pushNamedAndRemoveUntil(
//                   LoginPage.routeName,
//                       (_) => false,
//                 );
//               },
//               child: const Text('Log Out'),
//             )
//           ],
//         ),
//       ),
//       backgroundColor: Colors.purple[50],
//       body: Center(
//         child: Container(
//           padding: const EdgeInsets.all(16.0),
//           margin: const EdgeInsets.symmetric(vertical: 60.0),
//           decoration: BoxDecoration(
//             color: Colors.green[400],
//             borderRadius: BorderRadius.circular(10.0),
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               const Text(
//                 'Select the greenhouse to load value',
//                 style: TextStyle(fontSize: 20, color: Colors.white),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 16.0),
//               ElevatedButton(
//                 onPressed: () {
//                   // Show the dropdown menu
//                   showGreenKeysDropdown(context, greenKeys);
//                 },
//                 style: ElevatedButton.styleFrom(
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(10.0), // Rounded corners
//                   ),
//                 ),
//                 child: Text(selectedGreenKey ?? 'Select a Greenhouse device '),
//               ),
//               const SizedBox(height: 16.0),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//
//   void showGreenKeysDropdown(BuildContext context, List<String> greenKeys) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('Select a Greenhouse device'),
//
//           content: DropdownButton<String>(
//             hint: const Text("--no devices selected--"),
//             value: selectedGreenKey, // Set the selected value
//             onChanged: (String? newValue) {
//               setState(() {
//                 selectedGreenKey = newValue; // Update the selected value
//               });
//               // Close the dialog
//               Navigator.of(context).pop();
//               // Call a function to fetch data from Firebase
//               fetchDataFromFirebase(newValue);
//             },
//             items: greenKeys.map<DropdownMenuItem<String>>((String value) {
//               return DropdownMenuItem<String>(
//                 value: value,
//                 child: Text(value),
//               );
//             }).toList(),
//           ),
//         );
//       },
//     );
//   }
//   void fetchPanFromFirebase(String? selectedGreenKey) async {
//     final DatabaseReference ref = FirebaseDatabase.instance.ref('user/1@gmail/greenhouseDetails/$selectedGreenKey/pan');
//     await ref.once().then((event) {
//       final DataSnapshot snapshot = event.snapshot;
//       print('pan value: ${snapshot.value.toString()}');
//
//       setState(() {
//         pans = snapshot.value.toString(); // Update pans with the retrieved value
//       });
//
//       // After fetching the pan value, navigate to the CropDetailsPage
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => CropDetailsPage(
//             greenKey: selectedGreenKey,
//             pan: pans,
//           ),
//         ),
//       );
//     }).catchError((error) {
//       print('Failed to fetch pan value: $error');
//     });
//   }
//
//
//
//
//   void fetchDataFromFirebase(String? selectedGreenKey) async {
//     final DatabaseReference ref = FirebaseDatabase.instance.ref('user/1@gmail/greenhouseDetails/$selectedGreenKey');
//     await ref.once().then((event) {
//       final DataSnapshot snapshot = event.snapshot;
//       print(snapshot.value.toString());
//       print('green:$selectedGreenKey');
//
//       final Map<dynamic, dynamic>? data = event.snapshot.value as Map<dynamic, dynamic>?;
//
//       if (data != null) {
//         // If data is not null, check if it contains 'cropSpacing'
//         if (data.containsKey('cropSpacing')) {
//           // If 'cropSpacing' is present, assign values and navigate to CalculationPage
//           assignValuesFromFirebase(data);
//
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => CalculationPage(
//                 greenKey: selectedGreenKey,
//                 pan: pan,
//                 cropSpacing: cropSpacing,
//                 dripperDischarge: dripperDischarge,
//                 rowSpacing: rowSpacing,
//                 selectedCrop: selectedCrop,
//                 selectedDate: DateTime.parse(selectedDate),
//                 selectedDuration: selectedDuration,
//                 //selectedWettingArea: selectedWettingArea,
//               ),
//             ),
//           );
//         } else {
//           // If 'cropSpacing' is not present, fetch the 'pan' value and navigate to CropDetailsPage
//           fetchPanFromFirebase(selectedGreenKey);
//         }
//       }
//     }).catchError((error) {
//       print('Failed to fetch data: $error');
//     });
//   }
//
//
//   void assignValuesFromFirebase(Map<dynamic, dynamic> data) {
//     print('Pan:$pan');
//     setState(() {
//       cropSpacing = data['cropSpacing'].toString();
//       dripperDischarge = data['dripperDischarge'].toString();
//       rowSpacing = data['rowSpacing'].toString();
//       selectedCrop = data['selectedCrop'].toString();
//       selectedDate = data['selectedDate'].toString();
//       selectedDuration = data['selectedDuration'].toString();
//       selectedWettingArea = data['selectedWettingArea'].toString();
//       pan = data['pan'].toString();
//     });
//   }
//
//   List<String> extractGreenKeys(String kannanKey) {
//     // Define a regular expression pattern to match "GreenX"
//     final RegExp regex = RegExp(r'Green\d');
//
//     // Find all matches in the kannanKey string
//     final Iterable<RegExpMatch> matches = regex.allMatches(kannanKey);
//
//     // Extract matched substrings
//     final List<String> greenKeys = matches.map((match) => match.group(0)!).toList();
//
//     return greenKeys;
//   }
//
//   void navigateToLogin() {
//     Navigator.of(context).pushNamedAndRemoveUntil(
//       LoginPage.routeName,
//           (_) => false,
//     );
//   }
// }
