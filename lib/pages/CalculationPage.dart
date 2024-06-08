import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';

import 'package:node_auth/pages/greenhouse/greenhouse_page.dart';


final databaseReference = FirebaseDatabase.instance.reference();
final TextEditingController namecontroller = TextEditingController();
double panValue = 0;
var display;
bool isIrrigationMotorOn = false;
bool isIrrigationScheduled = false;
late DateTime scheduledIrrigationTime;
Timer? irrigationTimer;
Timer? operationTimeTimer;
bool isMotorOn = false;
String selectedWettingArea = '8';

class CalculationPage extends StatefulWidget {
  final String selectedCrop;
  final String selectedDuration;
  final DateTime selectedDate;
  final String rowSpacing;
  final String cropSpacing;
  final String dripperDischarge;
  final String pan;
  final String? greenKey;

  const CalculationPage({
    Key? key,
    required this.selectedCrop,
    required this.selectedDuration,
    required this.selectedDate,
    required this.rowSpacing,
    required this.cropSpacing,
    required this.dripperDischarge,
    required this.pan,
    required this.greenKey,
  }) : super(key: key);

  @override
  _CalculationPageState createState() => _CalculationPageState();
}

class _CalculationPageState extends State<CalculationPage>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  double growthPercentage = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _controller.forward();
    performCalculations();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
    irrigationTimer?.cancel();
    operationTimeTimer?.cancel();
  }

  void performCalculations() {
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
      case 'String bean':
        kcInitial = 0.45;
        kcMid = 1.01;
        kcFinal = 0.39;
        break;
      case 'Cauliflower':
        kcInitial = 0.65;
        kcMid = 1.05;
        kcFinal = 0.95;
        break;
    }

    DateTime currentDate = DateTime.now();
    int daysAfterSowing =
        currentDate.difference(widget.selectedDate).inDays;
    growthPercentage =
        (daysAfterSowing / int.parse(widget.selectedDuration)) * 100;

    double kc;
    if (growthPercentage <= 30) {
      kc = kcInitial;
    } else if (growthPercentage <= 60) {
      kc = kcMid;
    } else {
      kc = kcFinal;
    }

    panValue = double.parse(widget.pan);
    double etc = kc * panValue;

    double result = etc *
        (3.14 * int.parse(widget.rowSpacing) * int.parse(widget.rowSpacing)) *
        (0.0001) *
        (60) /
        int.parse(widget.dripperDischarge);

    namecontroller.text = result.toString();
    setState(() {
      display = result.toStringAsFixed(0);
    });

    if (isIrrigationMotorOn && display != null) {
      startIrrigationTimer(double.parse(display!));
    }
    if (isIrrigationScheduled) {
      startScheduledIrrigation();
    }
  }

  void startScheduledIrrigation() {
    DateTime currentTime = DateTime.now();
    Duration timeUntilScheduled = scheduledIrrigationTime.difference(currentTime);

    if (timeUntilScheduled.inSeconds > 0) {
      Timer(timeUntilScheduled, () {
        setState(() {
          isMotorOn = true;
        });
        updateMotorStatusToFirebase("On");
        if (display != null) {
          startIrrigationTimer(double.parse(display!));
        }
      });
    }
  }

  void startOperationTimeCountdown() {
    operationTimeTimer = Timer(Duration(minutes: int.parse(display!)), () {
      setState(() {
        isMotorOn = false;
        isIrrigationMotorOn = false;
      });
      updateMotorStatusToFirebase("Off");
    });
  }

  void scheduleIrrigation(BuildContext context) async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      DateTime currentTime = DateTime.now();
      DateTime scheduledTime = DateTime(
        currentTime.year,
        currentTime.month,
        currentTime.day,
        pickedTime.hour,
        pickedTime.minute,
      );

      setState(() {
        scheduledIrrigationTime = scheduledTime;
        isIrrigationScheduled = true;
      });

      startScheduledIrrigation();
    }
  }

  void startIrrigationTimer(double durationInMinutes) {
    irrigationTimer = Timer(Duration(minutes: durationInMinutes.toInt()), () {
      setState(() {
        isMotorOn = false;
        isIrrigationMotorOn = false;
      });
      updateMotorStatusToFirebase("Off");
    });

    setState(() {
      isMotorOn = true;
      isIrrigationMotorOn = true;
    });
    updateMotorStatusToFirebase("On");
  }

  void irrigateTomorrow(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Irrigation Notice"),
          content: Text("Irrigation will be done tomorrow."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );

    DateTime currentTime = DateTime.now();

    Duration timeUntil730AM = DateTime(
      currentTime.year,
      currentTime.month,
      currentTime.day +1 ,
      07,
      59,
    ).difference(currentTime);

    Timer(timeUntil730AM, () {
      databaseReference
          .child("user/1@gmail/greenhouseDetails/${widget.greenKey}/pan")
          .once()
          .then((DatabaseEvent snapshot) {
        var newPan = snapshot.snapshot.value.toString();
        double newPanValue = double.parse(newPan);

        double cumulativePan = newPanValue + panValue;
        performCalculationsForTomorrow(cumulativePan);
      });
    });
  }

  void performCalculationsForTomorrow(double modPan) {
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
      case 'String bean':
        kcInitial = 0.45;
        kcMid = 1.01;
        kcFinal = 0.39;
        break;
      case 'Cauliflower':
        kcInitial = 0.65;
        kcMid = 1.05;
        kcFinal = 0.95;
        break;
    }

    double panValue = double.parse(widget.pan);

    DateTime currentDate = DateTime.now();
    int daysAfterSowing =
        currentDate.difference(widget.selectedDate).inDays;
    growthPercentage =
        (daysAfterSowing / int.parse(widget.selectedDuration)) * 100;

    double kc;
    if (growthPercentage <= 30) {
      kc = kcInitial;
    } else if (growthPercentage <= 60) {
      kc = kcMid;
    } else {
      kc = kcFinal;
    }

    double etc = kc * modPan;

    double result = etc *
        (3.14 * int.parse(widget.rowSpacing) * int.parse(widget.rowSpacing)) *
        (0.0001) *
        (60) /
        int.parse(widget.dripperDischarge);

    namecontroller.text = result.toString();
    setState(() {
      display = result.toStringAsFixed(0);
    });
  }

  void updateMotorStatusToFirebase(String status) {
    databaseReference
        .child("user/1@gmail/greenhouseDetails/${widget.greenKey}")
        .update({
      "Motor status": status,
    }).then((_) {
      print("Motor status updated successfully: $status");
    }).catchError((error) {
      print("Failed to update motor status: $error");
    });
  }

  void _showResetConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Reset Crop Data'),
          content: Text('Reset all the crop data?'),
          actions: [
            TextButton(
              onPressed: () {
                _resetCropData();
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Yes'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('No'),
            ),
          ],
        );
      },
    );
  }

  void _resetCropData() {
    databaseReference
        .child("user/1@gmail/greenhouseDetails/${widget.greenKey}")
        .once()
        .then((snapshot) {
      // Retrieve current data
      Map<dynamic, dynamic>? currentData =
      snapshot.snapshot.value as Map<dynamic, dynamic>?;

      if (currentData != null) {
        // Keep only the pan data
        Map<String, dynamic> newData = {'pan': currentData['pan']};

        // Update the node with the new data
        databaseReference
            .child("user/1@gmail/greenhouseDetails/${widget.greenKey}")
            .set(newData)
            .then((_) {
          print("Crop data reset successfully");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => GreenHouseDetailsPage()),
          );
        }).catchError((error) {
          print("Failed to reset crop data: $error");
        });
      } else {
        print("No data found to reset");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => GreenHouseDetailsPage()),
        );
      }
    }).catchError((error) {
      print("Failed to fetch current crop data: $error");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculation Page'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(20.0),
            height: 700,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.deepPurple[800],
              borderRadius: BorderRadius.circular(20.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  widget.selectedCrop,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.yellow,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Crop Growth Progress',
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w300,
                          fontFamily: AutofillHints.addressState,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(
                        width: 300,
                        height: 75,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            LinearProgressIndicator(
                              value: growthPercentage / 100,
                              backgroundColor: Colors.grey[300],
                              valueColor:
                              const AlwaysStoppedAnimation<Color>(
                                  Colors.green),
                              minHeight: 25,
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            Text(
                              '${growthPercentage.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
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
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    'Operation Time: ${display ?? ""} minutes',
                    style: const TextStyle(
                        fontSize: 18, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: 4, // Increased count by 1 for manual run tile
                  itemBuilder: (BuildContext context, int index) {
                    IconData? icon;
                    String textstyle;
                    String text;
                    Function()? onPressed;
                    Color? tileColor;

                    switch (index) {
                      case 0:
                        text = ' Irrigation Motor';

                        tileColor = isMotorOn ? Colors.green : Colors.red;
                        onPressed = () {
                          setState(() {
                            isMotorOn = !isMotorOn;
                            if (isMotorOn) {
                              startIrrigationTimer(double.parse(display!));
                            } else {
                              startOperationTimeCountdown();
                            }
                          });
                          updateMotorStatusToFirebase(isMotorOn ? "On" : "Off");
                        };
                        tileColor = Colors.green[300];
                        break;
                      case 1:
                        text = ' Schedule Irrigation';
                        icon = Icons.schedule;

                        onPressed = () => scheduleIrrigation(context);
                        tileColor = Colors.green[300];
                        break;
                      case 2:
                        text = ' Irrigate Tomorrow';
                        icon = Icons.message;
                        onPressed = () => irrigateTomorrow(context);
                        tileColor = Colors.green[300];
                        break;
                      case 3: // Manual Run Tile
                        text = 'Manual Run';
                        icon = Icons.add;
                        onPressed = () => _manualRun(context);
                        tileColor = Colors.green[300];
                        break;
                      default:
                        text = 'Error';
                        tileColor = Colors.grey;
                    }

                    return GestureDetector(
                      onTap: onPressed,
                      child: Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        color: tileColor,
                        child: SizedBox(
                          height: 60,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    text,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black54),
                                  ),
                                ),
                                if (icon != null) ...[
                                  Icon(
                                    icon,
                                    color: Colors.black,
                                    size: 24,
                                  ),
                                ],
                                if (index == 0) ...[
                                  Switch(
                                    value: isMotorOn,
                                    onChanged: (value) {
                                      setState(() {
                                        isMotorOn = value;
                                        if (value) {
                                          startIrrigationTimer(double.parse(display!));
                                        } else {
                                          startOperationTimeCountdown();
                                        }
                                      });
                                      updateMotorStatusToFirebase(
                                          isMotorOn ? "On" : "Off");
                                    },
                                    activeColor: Colors.red,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    _showResetConfirmationDialog(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: const ContinuousRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20.0)),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.restore, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        'Reset Data',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _manualRun(BuildContext context) async {
    int selectedDuration = 5; // Default duration

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Select Duration'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text('Select the duration for manual run:'),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            if (selectedDuration > 1) {
                              selectedDuration--;
                            }
                          });
                        },
                        icon: Icon(Icons.remove),
                      ),
                      Text('$selectedDuration minutes'),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            selectedDuration++;
                          });
                        },
                        icon: Icon(Icons.add),
                      ),
                    ],
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    startIrrigationTimer(selectedDuration.toDouble());
                  },
                  child: Text('Start'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }



}


// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'dart:async';
//
// final databaseReference = FirebaseDatabase.instance.reference();
// final TextEditingController namecontroller = TextEditingController();
// double panValue = 0;
// var display;
// bool isIrrigationMotorOn = false;
// bool isIrrigationScheduled = false;
// late DateTime scheduledIrrigationTime;
// late Timer? irrigationTimer;
// late Timer? operationTimeTimer;
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
//   final String? greenKey;
//
//   const CalculationPage({
//     Key? key,
//     required this.selectedCrop,
//     required this.selectedDuration,
//     required this.selectedDate,
//     required this.selectedWettingArea,
//     required this.rowSpacing,
//     required this.cropSpacing,
//     required this.dripperDischarge,
//     required this.pan,
//     required this.greenKey
//   }) : super(key: key);
//
//   @override
//   _CalculationPageState createState() => _CalculationPageState();
// }
//
// class _CalculationPageState extends State<CalculationPage>
//     with TickerProviderStateMixin {
//   late AnimationController _controller;
//   double growthPercentage = 0.0;
//   Timer? irrigationTimer;
//
//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       duration: const Duration(milliseconds: 1000),
//       vsync: this,
//     );
//     _controller.forward();
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
//     DateTime currentDate = DateTime.now();
//     int daysAfterSowing = currentDate.difference(widget.selectedDate).inDays;
//     growthPercentage =
//         (daysAfterSowing / int.parse(widget.selectedDuration)) * 100;
//
//     double kc;
//     if (growthPercentage <= 30) {
//       kc = kcInitial;
//     } else if (growthPercentage <= 60) {
//       kc = kcMid;
//     } else {
//       kc = kcFinal;
//     }
//     panValue = double.parse(widget.pan);
//
//     double etc = kc * panValue;
//
//     double result = etc *
//         int.parse(widget.cropSpacing) *
//         int.parse(widget.rowSpacing) *
//         int.parse(widget.selectedWettingArea) *
//         (0.00001) *
//         (60) /
//         int.parse(widget.dripperDischarge);
//
//     namecontroller.text = result.toString();
//     setState(() {
//       display = result.toStringAsFixed(0);
//     });
//
//     databaseReference.child("5").set({
//       'Operation time': namecontroller.text,
//     });
//
//     if (isIrrigationMotorOn && display != null) {
//       startIrrigationTimer(double.parse(display!));
//     }
//     if (isIrrigationScheduled) {
//       startScheduledIrrigation();
//     }
//
//   }
//   void startScheduledIrrigation() {
//     // Get the current time
//     DateTime currentTime = DateTime.now();
//     // Calculate the time until the scheduled irrigation
//     Duration timeUntilScheduled = scheduledIrrigationTime.difference(currentTime);
//
//     if (timeUntilScheduled.inSeconds > 0) {
//       // Schedule the irrigation to start at the specified time
//       Timer(timeUntilScheduled, () {
//         setState(() {
//           isIrrigationMotorOn = true; // Turn on the irrigation motor
//         });
//         // Start operation time countdown
//         startOperationTimeCountdown();
//       });
//     }
//   }
//   void scheduleIrrigation(BuildContext context) async {
//     // Show time picker
//     TimeOfDay? pickedTime = await showTimePicker(
//       context: context,
//       initialTime: TimeOfDay.now(),
//     );
//
//     if (pickedTime != null) {
//       // Convert picked time to DateTime
//       DateTime currentTime = DateTime.now();
//       DateTime scheduledTime = DateTime(
//         currentTime.year,
//         currentTime.month,
//         currentTime.day,
//         pickedTime.hour,
//         pickedTime.minute,
//       );
//
//       // Set the scheduled irrigation time
//       setState(() {
//         scheduledIrrigationTime = scheduledTime;
//         isIrrigationScheduled = true;
//       });
//     }
//   }
//
//
//   void startIrrigationTimer(double durationInMinutes) {
//     irrigationTimer = Timer(Duration(minutes: durationInMinutes.toInt()), () {
//       setState(() {
//         isIrrigationMotorOn = false;
//         databaseReference.child("user/1@gmail/greenhouseDetails/${widget.greenKey}/").set({
//           "Motor status": "Off",
//         });
//       });
//       print("Irrigation timer expired");
//
//       databaseReference.child("user/1@gmail/greenhouseDetails/${widget.greenKey}/").set({
//         "Motor status": "Off",
//         "Operation time": durationInMinutes.toString(),
//       });
//     });
//
//     setState(() {
//       isIrrigationMotorOn = true;
//       databaseReference.child("6").set({
//         "Motor status": "On",
//       });
//     });
//   }
//
//   void saveOperationTimeToFirebase(String operationTime) {
//     databaseReference
//         .child("user/1@gmail/greenhouseDetails/${widget.greenKey}/cumulative")
//         .set({
//       "operationTime": operationTime,
//     });
//   }
//
//   void irrigateTomorrow(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text("Irrigation Notice"),
//           content: Text("Irrigation will be done tomorrow."),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//               child: Text("OK"),
//             ),
//           ],
//         );
//       },
//     );
//     // Get the current time
//     DateTime currentTime = DateTime.now();
//
//     // Calculate the time until 7:30 AM tomorrow
//     Duration timeUntil730AM = DateTime(
//       currentTime.year,
//       currentTime.month,
//       currentTime.day +1 ,
//       8,
//       00,
//     ).difference(currentTime);
//
//     // Schedule the data retrieval at 7:30 AM tomorrow
//     Timer(timeUntil730AM, () {
//       print('object over time');
//       // Perform the data retrieval
//       databaseReference
//           .child("user/1@gmail/greenhouseDetails/${widget.greenKey}/pan")
//           .once()
//           .then((DatabaseEvent snapshot) {
//         var newPan = snapshot.snapshot.value.toString() ;
//         double newPanValue = double.parse(newPan);
//
//         print('panvla:$newPanValue');
//         double cumulativePan = newPanValue + panValue;
//         performCalculationsForTomorrow(cumulativePan);
//       });
//     });
//   }
//   void scheduleIrrigation(BuildContext context) async {
//     // Show time picker
//     TimeOfDay? pickedTime = await showTimePicker(
//       context: context,
//       initialTime: TimeOfDay.now(),
//     );
//
//     if (pickedTime != null) {
//       // Convert picked time to DateTime
//       DateTime currentTime = DateTime.now();
//       DateTime scheduledTime = DateTime(
//         currentTime.year,
//         currentTime.month,
//         currentTime.day,
//         pickedTime.hour,
//         pickedTime.minute,
//       );
//
//       // Set the scheduled irrigation time
//       setState(() {
//         scheduledIrrigationTime = scheduledTime;
//         isIrrigationScheduled = true;
//       });
//     }
//   }
//
//
//   void performCalculationsForTomorrow(double modPan) {
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
//     double panValue = double.parse(widget.pan);
//
//     DateTime currentDate = DateTime.now();
//     int daysAfterSowing = currentDate.difference(widget.selectedDate).inDays;
//     growthPercentage =
//         (daysAfterSowing / int.parse(widget.selectedDuration)) * 100;
//
//     double kc;
//     if (growthPercentage <= 30) {
//       kc = kcInitial;
//     } else if (growthPercentage <= 60) {
//       kc = kcMid;
//     } else {
//       kc = kcFinal;
//     }
//
//     double etc = kc * modPan;
//
//     double result = etc *
//         int.parse(widget.cropSpacing) *
//         int.parse(widget.rowSpacing) *
//         int.parse(widget.selectedWettingArea) *
//         (0.00001) *
//         (60) /
//         int.parse(widget.dripperDischarge);
//
//     namecontroller.text = result.toString();
//     setState(() {
//       display = result.toStringAsFixed(0);
//     });
//
//     databaseReference.child("5").set({
//       'Operation time': namecontroller.text,
//     });
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
//                 offset: const Offset(0, 3),
//               ),
//             ],
//           ),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               Text(
//                 widget.selectedCrop,
//                 style: const TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white),
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
//                       valueColor:
//                       const AlwaysStoppedAnimation<Color>(Colors.green),
//                       strokeWidth: 150,
//                     ),
//                     Text(
//                       '${growthPercentage.toStringAsFixed(0)}%',
//                       style: const TextStyle(
//                           fontSize: 20,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.black54),
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
//                     value: isIrrigationMotorOn,
//                     onChanged: (value) {
//                       setState(() {
//                         isIrrigationMotorOn = value;
//                         if (value) {
//                           performCalculations();
//                         } else {
//                           irrigationTimer?.cancel();
//                           databaseReference.child("user/1@gmail/greenhouseDetails/${widget.greenKey}/").set({
//                             "Motor status": "Off",
//                           });
//                         }
//                       });
//                     },
//                     activeColor: Colors.green,
//                   )
//                 ],
//               ),
//               const SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: (){irrigateTomorrow(context);},
//                 child: const Text('Irrigate Tomorrow'),
//               ),
//               const SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: () {
//                   // Placeholder for scheduling irrigation
//                 },
//                 child: const Text('Schedule irrigation'),
//               ),
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
//                       offset: const Offset(0, 3),
//                     ),
//                   ],
//                 ),
//                 child: Text(
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


// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'dart:async';
//
// import 'package:node_auth/Pages/CalculationPage.dart';
//
// final databaseReference = FirebaseDatabase.instance.ref();
// final TextEditingController namecontroller = TextEditingController();
// String panValue = '0';
// var display;
// bool isIrrigationScheduled = false;
// bool isIrrigationMotorOn = false; // Track the state of irrigation motor
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
//   const CalculationPage({
//     Key? key,
//     required this.selectedCrop,
//     required this.selectedDuration,
//     required this.selectedDate,
//     required this.selectedWettingArea,
//     required this.rowSpacing,
//     required this.cropSpacing,
//     required this.dripperDischarge,
//     required this.pan,
//   }) : super(key: key);
//
//   @override
//   _CalculationPageState createState() => _CalculationPageState();
// }
//
// class _CalculationPageState extends State<CalculationPage>
//     with SingleTickerProviderStateMixin {
//   double? result;
//   late AnimationController _controller;
//   double growthPercentage = 0.0;
//   bool isIrrigationEnabled = false;
//   String irrigationButtonText = 'Schedule Irrigation';
//
//   Timer? irrigationTimer; // Timer to control irrigation duration
//
//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       duration: const Duration(milliseconds: 1000),
//       vsync: this,
//     );
//     _controller.forward();
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
//     // Calculate growth percentage, etc, and result
//     // ...
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
//     growthPercentage =
//         (daysAfterSowing / int.parse(widget.selectedDuration)) * 100;
//
//     // Select appropriate Kc value based on growth period
//     double kc;
//     if (growthPercentage <= 30) {
//       kc = kcInitial;
//     } else if (growthPercentage <= 60) {
//       kc = kcMid;
//     } else {
//       kc = kcFinal;
//     }
//
//     // Calculate Etc (crop evapotranspiration)
//     double etc = kc * double.parse(widget.pan);
//
//     // Perform remaining calculations
//     result = etc *
//         int.parse(widget.cropSpacing) *
//         int.parse(widget.rowSpacing) *
//         int.parse(widget.selectedWettingArea) *
//         (0.00001) *
//         (60) /
//         int.parse(widget.dripperDischarge);
//
//     // Update the text field with the calculated result
//     namecontroller.text = result?.toString() ?? '';
//
//     // Update the display variable
//     setState(() {
//       display = result?.toStringAsFixed(2);
//     });
//
//     // Update Firebase with operation time
//     databaseReference.child("5").set({
//       'Operation time': namecontroller.text.toString(),
//     });
//
//     // Start the irrigation timer when irrigation is scheduled
//     if (isIrrigationScheduled && result != null) {
//       startIrrigationTimer(int.parse(result!.toString()));
//     }
//
//     // Update Firebase with operation time
//     databaseReference.child("5").set({
//       'Operation time': namecontroller.text.toString(),
//     });
//   }
//
//   void startIrrigationTimer(display) {
//     // Start the timer for irrigation duration
//     irrigationTimer = Timer(Duration(minutes: (int.parse(result!.toStringAsFixed(2))) ), () {
//       // When timer expires, turn off the irrigation motor switch
//       setState(() {
//         isIrrigationMotorOn = false;
//         // Update Firebase with motor status
//         databaseReference.child("6").set({
//           "Motor status": "Off",
//         });
//       });
//     });
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
//                 offset: const Offset(0, 3),
//               ),
//             ],
//           ),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               Text(
//                 widget.selectedCrop,
//                 style: const TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white),
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
//                       valueColor:
//                       const AlwaysStoppedAnimation<Color>(Colors.green),
//                       strokeWidth: 150,
//                     ),
//                     Text(
//                       '${growthPercentage.toStringAsFixed(0)}%',
//                       style: const TextStyle(
//                           fontSize: 20,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.black54),
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
//                     value: isIrrigationMotorOn,
//                     onChanged: (value) {
//                       setState(() {
//                         isIrrigationMotorOn = value;
//                       });
//
//                       String operationTime =
//                       isIrrigationMotorOn ? "On" : "Off";
//
//                       databaseReference.child("6").set({
//                         "Motor status": operationTime,
//                       });
//                     },
//                     activeColor: Colors.green,
//                   )
//                 ],
//               ),
//               const SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: () {
//                   // Start irrigation when button is pressed
//                   setState(() {
//                     isIrrigationMotorOn = true;
//                     // Update Firebase with motor status
//                     databaseReference.child("6").set({
//                       "Motor status": "On",
//                     });
//                   });
//
//                   // Schedule irrigation if not already scheduled
//                   if (!isIrrigationScheduled) {
//                     performCalculations(); // Update calculations
//                     isIrrigationScheduled = true;
//                   }
//                 },
//                 child: const Text('Irrigate Tomorrow'),
//               ),
//
//               const SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: () {
//                   // Placeholder for scheduling irrigation
//                 },
//                 child: const Text('Schedule irrigation'),
//               ),
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
//                       offset: const Offset(0, 3),
//                     ),
//                   ],
//                 ),
//                 child: Text(
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
//
//





// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:node_auth/pages/greenhouse/greenhouse_page.dart';
//
// final databaseReference = FirebaseDatabase.instance.ref();
// final TextEditingController namecontroller = TextEditingController();
// String Panval = '0';
// final TextEditingController namcontroller = TextEditingController();
// var display;
// //String pannode = 'user/1@gmail/greenhouseDetails/Green1';
// bool isIrrigationScheduled = false;
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
//   const CalculationPage(
//       {super.key,
//         required this.selectedCrop,
//         required this.selectedDuration,
//         required this.selectedDate,
//         required this.selectedWettingArea,
//         required this.rowSpacing,
//         required this.cropSpacing,
//         required this.dripperDischarge,
//         required this.pan});
//
//   @override
//   _CalculationPageState createState() => _CalculationPageState();
// }
//
// class _CalculationPageState extends State<CalculationPage>
//     with SingleTickerProviderStateMixin {
//   double? result;
//   late AnimationController _controller;
//   double growthPercentage = 0.0;
//   bool isIrrigationEnabled = false;
//   String irrigationButtonText = 'Schedule Irrigation';
//
//   // var pan = '0';
//
//   @override
//   void initState() {
//     print(widget.selectedCrop);
//     print(widget.selectedDuration);
//     print(widget.selectedDate);
//     print(widget.selectedWettingArea);
//     print(widget.rowSpacing);
//     print(widget.cropSpacing);
//     print(widget.dripperDischarge);
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
//     //   {greenHouseId: 101,
//     // userId: kannan@mail,
//     //   rainFall: ''}
//     //
//     // {greenHouseId: 102,
//     //   userId: kannan@mail}
//     //
//     //   {greenHouseId: 103,
//     //   userId: kannankumar@mail}
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
//     int daysAfterSowing =
//         currentDate.difference(widget.selectedDate).inDays;
//     growthPercentage =
//         (daysAfterSowing / int.parse(widget.selectedDuration)) * 100;
//
//     // Select appropriate Kc value based on growth period
//     double kc;
//     if (growthPercentage <= 30) {
//       kc = kcInitial;
//     } else if (growthPercentage <= 60) {
//       kc = kcMid;
//     } else {
//       kc = kcFinal;
//     }
//     print('panval:$pan');
//
//     // Calculate Etc (crop evapotranspiration)
//     double etc = kc * double.parse(pan);
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
//     namecontroller.text = result?.toString() ?? '';
//
//     setState(() {
//       display = result?.toStringAsFixed(2);
//       result ?? namecontroller;
//     });
//
//     databaseReference.child("5").set({
//       'Operation time': namecontroller.text.toString(),
//     }); // Update the UI with the calculated result
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
//                 style: const TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white),
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
//                       valueColor:
//                       const AlwaysStoppedAnimation<Color>(Colors.green),
//                       strokeWidth: 150,
//                     ),
//                     Text(
//                       '${growthPercentage.toStringAsFixed(0)}%',
//                       style: const TextStyle(
//                           fontSize: 20,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.black54),
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
//                       String operationTime =
//                       isIrrigationEnabled ? "On" : "Off";
//
//                       databaseReference.child("6").set({
//                         "Motor status": operationTime,
//                       });
//                     },
//                     activeColor: Colors.green,
//                   )
//                 ],
//               ),
//               const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: () {
//
//               },
//               child: const Text('Irrigate Tomorrow'),
//             ),
//
//
//               const SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: () {
//                   // Placeholder for irrigation tomorrow
//                 },
//                 child: const Text('Schedule irrigation'),
//               ),
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
