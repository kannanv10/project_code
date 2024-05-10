import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:node_auth/pages/greenhouse/greenhouse_details.dart';
import 'package:node_auth/pages/firstpage.dart';
import 'package:node_auth/pages/CalculationPage.dart';
late String cropSpacing;
late String dripperDischarge;
late String rowSpacing;
late String selectedCrop;
late String selectedDate;
late String selectedDuration;
late String selectedWettingArea;
var pan = '0';
class GreenHouseDetailsPage extends StatefulWidget {
  @override
  _GreenHouseDetailsPageState createState() => _GreenHouseDetailsPageState();
}

class _GreenHouseDetailsPageState extends State<GreenHouseDetailsPage> {
  String kannanKey = '0';
  Greenhouse? greenhouseRetrievedDetails;
  String? selectedGreenKey;
  String kannanKeys ='0';

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  void fetchData() async {
    final DatabaseReference ref = FirebaseDatabase.instance.ref('user/1@gmail/greenhouseDetails');
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
    print(greenKeys);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to Automated Irrigation System'),
        titleTextStyle: const TextStyle(fontSize: 19),
        backgroundColor: Colors.green[700],
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

  void showGreenKeysDropdown(BuildContext context, List<String> greenKeys) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select a Greenhouse device'),

          content: DropdownButton<String>(
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

  void fetchDataFromFirebase(String? selectedGreenKey) async {
    final DatabaseReference ref = FirebaseDatabase.instance.ref('user/1@gmail/greenhouseDetails/$selectedGreenKey');
    await ref.once().then((event) {
      final DataSnapshot snapshot = event.snapshot;
      print(snapshot.value.toString());
      print('green:$selectedGreenKey');

      setState(() {
        kannanKeys = snapshot.value.toString(); // Update kannanKey with the retrieved value
      });
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
                pan: pan,
                cropSpacing: cropSpacing,
                dripperDischarge: dripperDischarge,
                rowSpacing: rowSpacing,
                selectedCrop: selectedCrop,
                selectedDate: DateTime.parse(selectedDate),
                selectedDuration: selectedDuration,
                selectedWettingArea: selectedWettingArea,
              ),
            ),
          );
        } else {
        // If data is null, navigate to page 1
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CropDetailsPage(),
          ),
        );
      }}}
    ).catchError((error) {
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
}



//
// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/material.dart';
// import 'package:node_auth/pages/greenhouse/greenhouse_details.dart';
// import 'package:node_auth/pages/firstpage.dart';
// import 'package:node_auth/pages/CalculationPage.dart';
// class GreenHouseDetailsPage extends StatefulWidget {
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
//   @override
//   void initState() {
//     super.initState();
//     fetchData();
//   }
//
//   void fetchData() async {
//     final DatabaseReference ref = FirebaseDatabase.instance.ref('user/1@gmail');
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
//   @override
//   Widget build(BuildContext context) {
//     // Extract Green keys from kannanKey and convert them into a list
//     final List<String> greenKeys = extractGreenKeys(kannanKey);
//     print(greenKeys);
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Welcome to Automated Irrigation System'),
//         titleTextStyle: const TextStyle(fontSize: 19),
//         backgroundColor: Colors.green[700],
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
//   void showGreenKeysDropdown(BuildContext context, List<String> greenKeys)async {
//
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//
//         return AlertDialog(
//           title: const Text('Select a Greenhouse device'),
//           content: DropdownButton<String>(
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
// //   void assignvalues() async{
// //     DatabaseReference _test = FirebaseDatabase.instance.ref('user/1@gmail/greenhouseDetails/$selectedGreenKey/cropSpacing');
// //     _test.onValue.listen((event) {
// //       setState(() {
// //         Panval = event.snapshot.value.toString();
// //       });
// //
// //     });
// //     DatabaseReference _test1 = FirebaseDatabase.instance.ref('user/1@gmail/greenhouseDetails/$selectedGreenKey/cropSpacing');
// //     _test.onValue.listen((event) {
// //       setState(() {
// //         Panval = event.snapshot.value.toString();
// //       });
// //
// //     });
// //
// // }
//
//   void fetchDataFromFirebase(String? selectedGreenKey) async {
//     final DatabaseReference ref = FirebaseDatabase.instance.ref('user/1@gmail/greenhouseDetails/$selectedGreenKey');
//     await ref.once().then((event) {
//       final DataSnapshot snapshot = event.snapshot;
//       print(snapshot.value.toString());
//       print('green:$selectedGreenKey');
//
//       setState(() {
//         kannanKeys = snapshot.value.toString(); // Update kannanKey with the retrieved value
//       });
//
//       // Check if data is not null
//       if (snapshot.value != null) {
//         // Extract fetched data
//         var data = snapshot.value as Map<String, dynamic>;
//
//         // Navigate to CalculationPage and pass the fetched data as arguments
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => CalculationPage(pan: '4' ,
//               cropSpacing: data['cropSpacing'].toString(),
//               dripperDischarge: data['dripperDischarge'].toString(),
//               rowSpacing: data['rowSpacing'].toString(),
//               selectedCrop: data['selectedCrop'].toString(),
//               selectedDate: data['selectedDate'],
//               selectedDuration: data['selectedDuration'].toString(),
//               selectedWettingArea: data['selectedWettingArea'].toString(),
//             ),
//           ),
//         );
//       } else {
//         // If data is null, navigate to page 1
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => CropDetailsPage(),
//           ),
//         );
//       }
//     }).catchError((error) {
//       print('Failed to fetch data: $error');
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
// }





// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/material.dart';
// import 'package:node_auth/pages/greenhouse/greenhouse_details.dart';
// import 'package:node_auth/pages/firstpage.dart';
// class GreenHouseDetailsPage extends StatefulWidget {
//   @override
//   _GreenHouseDetailsPageState createState() => _GreenHouseDetailsPageState();
// }
//
// class _GreenHouseDetailsPageState extends State<GreenHouseDetailsPage> {
//   String kannanKey = '0';
//   Greenhouse? greenhouseRetrievedDetails;
//   String? selectedGreenKey;
//
//   @override
//   void initState() {
//     super.initState();
//     fetchData();
//   }
//
//   void fetchData() async {
//     final DatabaseReference ref = FirebaseDatabase.instance.ref('user/1@gmail');
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
//   @override
//   Widget build(BuildContext context) {
//     // Extract Green keys from kannanKey and convert them into a list
//     final List<String> greenKeys = extractGreenKeys(kannanKey);
//     print(greenKeys);
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Welcome to Automated Irrigation System'),
//         titleTextStyle: const TextStyle(fontSize: 19),
//         backgroundColor: Colors.green[700],
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
//               // Text(
//               //   'Selected Green Key: ${selectedGreenKey ?? "None"}',
//               //   style: TextStyle(fontSize: 16, color: Colors.white),
//               //   textAlign: TextAlign.center,
//               // ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   void showGreenKeysDropdown(BuildContext context, List<String> greenKeys) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//
//           title: const Text('Select a Greenhouse device'),
//           content: DropdownButton<String>(
//             value: selectedGreenKey, // Set the selected value
//             onChanged: (String? newValue) {
//               setState(() {
//                 selectedGreenKey = newValue; // Update the selected value
//               });
//               Navigator.of(context).pop(); // Close the dialog
//             },
//             items: greenKeys.map<DropdownMenuItem<String>>((String value) {
//               return DropdownMenuItem<String>(
//                 value: value,
//                 child: Text(value),
//     //             onTap:  () {
//     // // Navigate to CalculationPage and pass crop details
//     //                 Navigator.push(
//     //                   context,
//     //                   MaterialPageRoute(
//     //                     builder: (context) => crop_details_page(
//     //
//     //                     ),
//     //                   ),
//     //                 );}
//
//
//               );
//             }).toList(),
//           ),
//         );
//       },
//     );
//   }
// }
//
// List<String> extractGreenKeys(String kannanKey) {
//   // Define a regular expression pattern to match "GreenX"
//   final RegExp regex = RegExp(r'Green\d');
//
//   // Find all matches in the kannanKey string
//   final Iterable<RegExpMatch> matches = regex.allMatches(kannanKey);
//
//   // Extract matched substrings
//   final List<String> greenKeys = matches.map((match) => match.group(0)!).toList();
//
//   return greenKeys;
// }
