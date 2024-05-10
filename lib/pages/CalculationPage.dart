import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:node_auth/pages/greenhouse/greenhouse_page.dart';

final databaseReference = FirebaseDatabase.instance.ref();
final TextEditingController namecontroller = TextEditingController();
String Panval = '0';
final TextEditingController namcontroller = TextEditingController();
var display;
//String pannode = 'user/1@gmail/greenhouseDetails/Green1';
bool isIrrigationScheduled = false;

class CalculationPage extends StatefulWidget {
  final String selectedCrop;
  final String selectedDuration;
  final DateTime selectedDate;
  final String selectedWettingArea;
  final String rowSpacing;
  final String cropSpacing;
  final String dripperDischarge;
  final String pan;

  const CalculationPage(
      {super.key,
        required this.selectedCrop,
        required this.selectedDuration,
        required this.selectedDate,
        required this.selectedWettingArea,
        required this.rowSpacing,
        required this.cropSpacing,
        required this.dripperDischarge,
        required this.pan});

  @override
  _CalculationPageState createState() => _CalculationPageState();
}

class _CalculationPageState extends State<CalculationPage>
    with SingleTickerProviderStateMixin {
  double? result;
  late AnimationController _controller;
  double growthPercentage = 0.0;
  bool isIrrigationEnabled = false;
  String irrigationButtonText = 'Schedule Irrigation';

  // var pan = '0';

  @override
  void initState() {
    print(widget.selectedCrop);
    print(widget.selectedDuration);
    print(widget.selectedDate);
    print(widget.selectedWettingArea);
    print(widget.rowSpacing);
    print(widget.cropSpacing);
    print(widget.dripperDischarge);
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _controller.forward();
    // Call the function to perform calculations
    performCalculations();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void performCalculations() {
    // DatabaseReference _test = FirebaseDatabase.instance.ref().child(pan);
    // _test.onValue.listen((event) {
    //   setState(() {
    //     Panval = event.snapshot.value.toString();
    //   });
    //   print(_test);
    // });

    //   {greenHouseId: 101,
    // userId: kannan@mail,
    //   rainFall: ''}
    //
    // {greenHouseId: 102,
    //   userId: kannan@mail}
    //
    //   {greenHouseId: 103,
    //   userId: kannankumar@mail}

    // Sample value for Ep (pan evaporation), to be replaced with actual value from Firebase
    //double epValue = 5.0; // Example value, replace with actual value from Firebase

    // Retrieve Kc values based on selected crop
    double kcInitial = 0.0;
    double kcMid = 0.0;
    double kcFinal = 0.0;
    switch (widget.selectedCrop) {
      case 'Tomato':
        kcInitial = 0.3;
        kcMid = 0.6;
        kcFinal = 0.9;
        break;
      case 'Cucumber':
        kcInitial = 0.35;
        kcMid = 0.65;
        kcFinal = 0.95;
        break;
      case 'Capsicum':
        kcInitial = 0.4;
        kcMid = 0.7;
        kcFinal = 1.0;
        break;
    }

    // Calculate Growth Period
    DateTime currentDate = DateTime.now();
    int daysAfterSowing =
        currentDate.difference(widget.selectedDate).inDays;
    growthPercentage =
        (daysAfterSowing / int.parse(widget.selectedDuration)) * 100;

    // Select appropriate Kc value based on growth period
    double kc;
    if (growthPercentage <= 30) {
      kc = kcInitial;
    } else if (growthPercentage <= 60) {
      kc = kcMid;
    } else {
      kc = kcFinal;
    }
    print('panval:$pan');

    // Calculate Etc (crop evapotranspiration)
    double etc = kc * double.parse(pan);
    // double.parse(Panval)
    // Perform remaining calculations
    result = etc *
        int.parse(widget.cropSpacing) *
        int.parse(widget.rowSpacing) *
        int.parse(widget.selectedWettingArea) *
        (0.00001) *
        (60) /
        int.parse(widget.dripperDischarge);

    namecontroller.text = result?.toString() ?? '';

    setState(() {
      display = result?.toStringAsFixed(2);
      result ?? namecontroller;
    });

    databaseReference.child("5").set({
      'Operation time': namecontroller.text.toString(),
    }); // Update the UI with the calculated result
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculation Page'),
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(20.0),
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Colors.deepPurple[700],
            borderRadius: BorderRadius.circular(20.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                spreadRadius: 5,
                blurRadius: 7,
                offset: const Offset(0, 3), // changes position of shadow
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                widget.selectedCrop,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 200,
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: growthPercentage / 100,
                      backgroundColor: Colors.grey[300],
                      valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.green),
                      strokeWidth: 150,
                    ),
                    Text(
                      '${growthPercentage.toStringAsFixed(0)}%',
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Irrigation Motor',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  Switch(
                    value: isIrrigationEnabled,
                    onChanged: (value) {
                      setState(() {
                        isIrrigationEnabled = value;
                      });

                      String operationTime =
                      isIrrigationEnabled ? "On" : "Off";

                      databaseReference.child("6").set({
                        "Motor status": operationTime,
                      });
                    },
                    activeColor: Colors.green,
                  )
                ],
              ),
              const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {

              },
              child: const Text('Irrigate Tomorrow'),
            ),


              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Placeholder for irrigation tomorrow
                },
                child: const Text('Schedule irrigation'),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 233, 109, 255),
                  borderRadius: BorderRadius.circular(10.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: const Offset(0, 3), // changes position of shadow
                    ),
                  ],
                ),
                child: Text(
                  'Operation Time: ${display ?? ""} minutes',
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:node_auth/pages/greenhouse/greenhouse_page.dart';
// final databaseReference = FirebaseDatabase.instance.ref();
// final TextEditingController namecontroller = TextEditingController();
// String Panval = '0';
// final TextEditingController namcontroller = TextEditingController();
// var display;
// String pannode ='user/1@gmail/greenhouseDetails/Green1';
//
// class CalculationPage extends StatefulWidget {
//   final String selectedCrop;
//   final String selectedDuration;
//   final DateTime selectedDate;
//   final String selectedWettingArea;
//   final String rowSpacing;
//   final String cropSpacing;
//   final String dripperDischarge;
//   final String pan;
//
//
//   const CalculationPage({super.key,
//     required this.selectedCrop,
//     required this.selectedDuration,
//     required this.selectedDate,
//     required this.selectedWettingArea,
//     required this.rowSpacing,
//     required this.cropSpacing,
//     required this.dripperDischarge,
//     required this.pan,
//   });
//
//   @override
//   _CalculationPageState createState() => _CalculationPageState();
// }
//
// class _CalculationPageState extends State<CalculationPage> with SingleTickerProviderStateMixin {
//   double? result;
//   late AnimationController _controller;
//   double growthPercentage = 0.0;
//   bool isIrrigationEnabled = false;
//   String irrigationButtonText = 'Schedule Irrigation';
//
//   @override
//   void initState() {
//
//     print(widget.selectedCrop);
//       print(widget.selectedDuration);
//       print(widget.selectedDate);
//       print(widget.selectedWettingArea);
//       print(widget.rowSpacing);
//       print(widget.cropSpacing);
//       print(widget.dripperDischarge);
//     super.initState();
//     _controller = AnimationController(
//       duration: const Duration(milliseconds: 1000),
//       vsync: this,
//     );
//     _controller.forward();
//     // Call the function to perform calculations
//     performCalculations();
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   void performCalculations() {
//     // DatabaseReference _test = FirebaseDatabase.instance.ref().child(pan);
//     // _test.onValue.listen((event) {
//     //   setState(() {
//     //     Panval = event.snapshot.value.toString();
//     //   });
//     //   print(_test);
//     // });
//
//   //   {greenHouseId: 101,
//   // userId: kannan@mail,
//   //   rainFall: ''}
//   //
//   // {greenHouseId: 102,
//   //   userId: kannan@mail}
//   //
//   //   {greenHouseId: 103,
//   //   userId: kannankumar@mail}
//
//     // Sample value for Ep (pan evaporation), to be replaced with actual value from Firebase
//     //double epValue = 5.0; // Example value, replace with actual value from Firebase
//
//     // Retrieve Kc values based on selected crop
//     double kcInitial = 0.0;
//     double kcMid = 0.0;
//     double kcFinal = 0.0;
//     switch (widget.selectedCrop) {
//       case 'Tomato':
//         kcInitial = 0.3;
//         kcMid = 0.6;
//         kcFinal = 0.9;
//         break;
//       case 'Cucumber':
//         kcInitial = 0.35;
//         kcMid = 0.65;
//         kcFinal = 0.95;
//         break;
//       case 'Capsicum':
//         kcInitial = 0.4;
//         kcMid = 0.7;
//         kcFinal = 1.0;
//         break;
//     }
//
//     // Calculate Growth Period
//     DateTime currentDate = DateTime.now();
//     int daysAfterSowing = currentDate.difference(widget.selectedDate).inDays;
//     growthPercentage = (daysAfterSowing / int.parse(widget.selectedDuration)) * 100;
//
//     // Select appropriate Kc value based on growth period
//     double kc;
//     if (growthPercentage <= 30) {
//       kc = kcInitial;
//     } else if (growthPercentage <= 60) {
//       kc = kcMid;
//     } else {
//       kc = kcFinal;
//     };
//
//
//
//
//
//
//     // Calculate Etc (crop evapotranspiration)
//     double etc = kc * double.parse(pan) ;
//     // double.parse(Panval)
//     // Perform remaining calculations
//     result = etc *
//         int.parse(widget.cropSpacing) *
//         int.parse(widget.rowSpacing) *
//         int.parse(widget.selectedWettingArea) *
//         (0.00001) *
//         (60) /
//         int.parse(widget.dripperDischarge);
//
//     namecontroller.text = result ?.toString() ?? '';
//
//
//
//     setState(() {
//       display = result?.toStringAsFixed(2);
//       result ?? namecontroller;
//     } );
//
//     databaseReference.child("5").set({
//       'Operation time':namecontroller.text.toString(),
//     });// Update the UI with the calculated result
//
//
//
//
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Calculation Page'),
//       ),
//       body: Center(
//         child: Container(
//           margin: const EdgeInsets.all(20.0),
//           padding: const EdgeInsets.all(20.0),
//           decoration: BoxDecoration(
//             color: Colors.deepPurple[700],
//             borderRadius: BorderRadius.circular(20.0),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.3),
//                 spreadRadius: 5,
//                 blurRadius: 7,
//                 offset: const Offset(0, 3), // changes position of shadow
//               ),
//             ],
//           ),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               Text(
//                 widget.selectedCrop,
//                 style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
//               ),
//               const SizedBox(height: 20),
//               SizedBox(
//                 width: 200,
//                 height: 200,
//                 child: Stack(
//                   alignment: Alignment.center,
//                   children: [
//                     CircularProgressIndicator(
//                       value: growthPercentage / 100,
//                       backgroundColor: Colors.grey[300],
//                       valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
//                       strokeWidth: 150,
//                     ),
//                     Text(
//                       '${growthPercentage.toStringAsFixed(0)}%',
//                       style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black54),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 20),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const Text(
//                     'Irrigation Motor',
//                     style: TextStyle(fontSize: 18, color: Colors.white),
//                   ),
//                   Switch(
//                     value: isIrrigationEnabled,
//                     onChanged: (value) {
//                       setState(() {
//                         isIrrigationEnabled = value;
//                       });
//
//                       String operationTime = isIrrigationEnabled ? "On" : "Off";
//
//                       databaseReference.child("6").set({
//                         "Motor status": operationTime,
//                       });
//                     },
//                     activeColor: Colors.green,
//                   )
//
//                   // Switch(
//                   //    value: isIrrigationEnabled,
//                   //   onChanged: (value) {
//                   //     setState(() {
//                   //       isIrrigationEnabled = value ;
//                   //
//                   //     });
//                   //     if(isIrrigationEnabled = value){
//                   //       namcontroller.text = "On";
//                   //
//                   //       databaseReference.child("6").set({
//                   //         'Operation time':namcontroller.text.toString(),
//                   //       });
//                   //
//                   //     }
//                   //     else if (isIrrigationEnabled =! value){
//                   //       namcontroller.text = "Off";
//                   //
//                   //       databaseReference.child("6").set({
//                   //         'Operation time':namcontroller.text.toString(),
//                   //       });
//                   //     }
//                   //   },
//                   //   activeColor: Colors.green,
//                   // ),
//                 ],
//               ),
//               const SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: () {
//                   // Placeholder for scheduling irrigation
//                   showTimePicker(
//                     context: context,
//                     initialTime: TimeOfDay.now(),
//                   ).then((selectedTime) {
//                     if (selectedTime != null) {
//                       setState(() {
//                         // Update the button text with the scheduled time
//                         irrigationButtonText =
//                             'Irrigation scheduled at ${selectedTime.hour}:${selectedTime.minute.toString().padLeft(2, '0')}';
//                       });
//                     }
//                   });
//                 },
//                 child: Text(irrigationButtonText),
//               ),
//               const SizedBox(height: 20),
//
//           ElevatedButton(
//             onPressed: () {
//
//             },
//             child: const Text('Irrigate Tomorrow'),
//           ),
//
//
//               const SizedBox(height: 20),
//               Container(
//                 padding: const EdgeInsets.all(10.0),
//                 decoration: BoxDecoration(
//                   color: const Color.fromARGB(255, 233, 109, 255),
//                   borderRadius: BorderRadius.circular(10.0),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.3),
//                       spreadRadius: 5,
//                       blurRadius: 7,
//                       offset: const Offset(0, 3), // changes position of shadow
//                     ),
//                   ],
//                 ),
//                 child: Text(
//
//
//
//                   'Operation Time: ${display ?? ""} minutes',
//                   style: const TextStyle(fontSize: 18, color: Colors.white),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
