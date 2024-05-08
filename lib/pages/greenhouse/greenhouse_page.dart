import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:node_auth/pages/greenhouse/greenhouse_details.dart';

class GreenHouseDetailsPage extends StatefulWidget {
  @override
  _GreenHouseDetailsPageState createState() => _GreenHouseDetailsPageState();
}

class _GreenHouseDetailsPageState extends State<GreenHouseDetailsPage> {
  String kannanKey = '0';
  Greenhouse? greenhouseRetrievedDetails;
  String? selectedGreenKey;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  void fetchData() async {
    final DatabaseReference ref = FirebaseDatabase.instance.ref('user/1@gmail');
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
              // Text(
              //   'Selected Green Key: ${selectedGreenKey ?? "None"}',
              //   style: TextStyle(fontSize: 16, color: Colors.white),
              //   textAlign: TextAlign.center,
              // ),
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
              Navigator.of(context).pop(); // Close the dialog
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
