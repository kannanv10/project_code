import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:node_auth/pages/greenhouse/greenhouse_page.dart';
import 'CalculationPage.dart';

class CropDetailsPage extends StatefulWidget {
  static const routeName = '/crop_details_page';
  final String? greenKey;
  final String? pan;

  const CropDetailsPage({Key? key, required this.greenKey,this.pan}) : super(key: key);

  @override
  _CropDetailsPageState createState() => _CropDetailsPageState();
}

class _CropDetailsPageState extends State<CropDetailsPage> {
  final TextEditingController _cropSpacingController = TextEditingController();
  final TextEditingController _rowSpacingController = TextEditingController();
  final TextEditingController _dripperDischargeController = TextEditingController();

  String _selectedCrop = '--Select Variety--';
  String _selectedDuration = '--Select Duration--';
  String _selectedWettingArea = '--Select Area Wetting Percentage--';
  List<String> cropDropDown = [
    '--Select Variety--',
    'Tomato',
    'Cucumber',
    'Capsicum'
  ];
  List<String> durationDropDown = ['--Select Duration--', '90', '110', '150'];
  List<String> areaDropDown = [
    '--Select Area Wetting Percentage--',
    '50',
    '70',
    '80'
  ];

  DateTime _selectedDate = DateTime.now();


  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;


  @override
  void initState() {
    super.initState();
    _initializeFirebaseMessaging();
  }

  void _initializeFirebaseMessaging() async {
    await FirebaseMessaging.instance.setAutoInitEnabled(true);
    _firebaseMessaging.getToken().then((String? token) {
      print('FCM Token: $token');
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Handle incoming messages when the app is in the foreground
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Handle when the app is opened from a background state
    });
    print("valueda:$pan");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple[900], // Dark purple background
      appBar: AppBar(
        backgroundColor: Colors.black26,
        title: const Text('Crop Details'),
        titleTextStyle: const TextStyle(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Container(
          width: MediaQuery
              .of(context)
              .size
              .width * 0.8,
          margin: EdgeInsets.symmetric(vertical: 50, horizontal: 50),
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Colors.deepPurple[200], // Light purple background
            borderRadius: BorderRadius.circular(20.0), // Rounded corners
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              buildDropdownButton(
                'Crop Name',
                _selectedCrop,
                cropDropDown,
                    (String? newValue) {
                  setState(() {
                    _selectedCrop = newValue!;
                  });
                },
                'Variety', // Hint text
              ),
              const SizedBox(height: 20.0),
              buildDropdownButton(
                'Crop Duration',
                _selectedDuration,
                durationDropDown,
                    (String? newValue) {
                  setState(() {
                    _selectedDuration = newValue!;
                  });
                },
                'Number of days', // Hint text
              ),
              const SizedBox(height: 20.0),
              buildDatePickerButton('Sowing Date'),
              const SizedBox(height: 20.0),
              buildDropdownButton(
                'Area of Wetting',
                _selectedWettingArea,
                areaDropDown,
                    (String? newValue) {
                  setState(() {
                    _selectedWettingArea = newValue!;
                  });
                },
                'Percentage', // Hint text
              ),
              const SizedBox(height: 20.0),
              TextField(
                controller: _rowSpacingController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Row Spacing',
                ),
              ),
              const SizedBox(height: 20.0),
              TextField(
                controller: _cropSpacingController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Crop Spacing',
                ),
              ),
              const SizedBox(height: 20.0),
              TextField(
                controller: _dripperDischargeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Dripper Discharge',
                ),
              ),
              const SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: () {
                  fetchPanAndNavigateToCalculationPage();
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildDropdownButton(String labelText,
      String value,
      List<String> items,
      Function(String?) onChanged,
      String hintText,) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(labelText),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.0), // Rounded corners
            color: Colors.white, // Dropdown background color
          ),
          child: DropdownButton<String>(
            value: value,
            onChanged: onChanged,
            items: items.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            hint: Text(hintText),
            isExpanded: true,
            underline: const SizedBox(),
            // Remove the underline
            style: const TextStyle(color: Colors.black), // Text color
          ),
        ),
      ],
    );
  }

  Widget buildDatePickerButton(String hintText) {
    String formattedDate =
        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(hintText),
        TextButton(
          onPressed: () {
            _selectDate(context);
          },
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(Colors.white),
            // Background color
            shape: MaterialStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0), // Rounded corners
              ),
            ),
          ),
          child: Text(
            formattedDate,
            style: const TextStyle(color: Colors.black), // Text color
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void fetchPanAndNavigateToCalculationPage() async {
    try {
      // Fetch FCM token
      String? fcmToken = await _firebaseMessaging.getToken();
      print('FCM Token: $fcmToken');

      // Reference to the database
      final DatabaseReference ref = FirebaseDatabase.instance.ref('user/1@gmail/greenhouseDetails/${widget.greenKey}');

      // Prepare data to update
      Map<String, dynamic> dataToUpdate = {
        'selectedCrop': _selectedCrop,
        'selectedDuration': _selectedDuration,
        'selectedDate': _selectedDate.toIso8601String(),
        'selectedWettingArea': _selectedWettingArea,
        'rowSpacing': _rowSpacingController.text,
        'cropSpacing': _cropSpacingController.text,
        'dripperDischarge': _dripperDischargeController.text,
      };

      // Check if FCM token is available
      if (fcmToken != null) {
        dataToUpdate['fcmToken'] = fcmToken; // Add FCM token to the data
      }

      // Update data in Firebase
      await ref.update(dataToUpdate);

      // Navigate to CalculationPage and pass crop details
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CalculationPage(
            greenKey: widget.greenKey,
            pan: widget.pan ?? "",
            selectedCrop: _selectedCrop,
            selectedDuration: _selectedDuration,
            selectedDate: _selectedDate,
            selectedWettingArea: _selectedWettingArea,
            rowSpacing: _rowSpacingController.text,
            cropSpacing: _cropSpacingController.text,
            dripperDischarge: _dripperDischargeController.text,
          ),
        ),
      );
    } catch (error) {
      print('Failed to fetch pan: $error');
    }
  }

}