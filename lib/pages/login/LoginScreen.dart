import 'package:flutter/material.dart';

import 'LoginApiService.dart';

class _LoginScreen extends State<LoginScreen> {
  bool obsecureText = true;
  bool? checkBoxState = false;
  String email = '';
  String password = '';
  bool showProgress = false;

  @override
  void initState() {
    super.initState();
  }

  void showPassword() {
    setState(() {
      obsecureText = !obsecureText;
    });
  }

  void showOrHideProgress(bool isShow) {
    setState(() {
      showProgress = isShow;
    });
  }

  // Home Screen
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AbsorbPointer(
            absorbing: showProgress,
            child: Stack(
              children: <Widget>[
                Scaffold(
                    body: SingleChildScrollView(
                      child: Column(
                        children: <Widget>[
                          const Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: EdgeInsets.only(left: 40, top: 80),
                                child: Text('Getting Started ',
                                    style: TextStyle(
                                        fontSize: 24,
                                        color: Color(0xff37364A),
                                        fontWeight: FontWeight.w300)),
                              )),
                          const Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: EdgeInsets.only(top: 70, left: 30),
                                child: Text('Sign In ',
                                    style: TextStyle(
                                        fontSize: 18,
                                        color: Color(0xff120D26),
                                        fontWeight: FontWeight.w400)),
                              )),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 20),
                            child: TextField(
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.phone),
                                focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        width: 2, color: Color(0xff807A7A)),
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(15.0),
                                    )),
                                border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        width: 2, color: Color(0xff807A7A)),
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(15.0),
                                    )),
                                hintText: 'Phone',
                                hintStyle: TextStyle(
                                    color: Color(0xff747688), fontSize: 14),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  email = value;
                                });
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            //padding: EdgeInsets.symmetric(horizontal: 15),
                            child: TextField(
                                obscureText: obsecureText,
                                onChanged: (value) {
                                  setState(() {
                                    password = value;
                                  });
                                },
                                decoration: InputDecoration(
                                    prefixIcon:
                                        const Icon(Icons.password_outlined),
                                    suffixIcon: IconButton(
                                      onPressed: showPassword,
                                      icon: Icon(
                                        obsecureText
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                      ),
                                    ),
                                    focusedBorder: const OutlineInputBorder(
                                        borderSide: BorderSide(
                                            width: 2, color: Color(0xff807A7A)),
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(15.0),
                                        )),
                                    border: const OutlineInputBorder(
                                        borderSide: BorderSide(
                                            width: 2, color: Color(0xff807A7A)),
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(15.0),
                                        )),
                                    hintText: 'Password',
                                    hintStyle: const TextStyle(
                                        color: Color(0xff747688),
                                        fontSize: 14))),
                          ),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(
                                    left: 15, top: 20, bottom: 10),
                                child: Row(children: <Widget>[
                                  /*Checkbox(
                                activeColor: const Color(0xe03D56F0),
                                value: checkBoxState,
                                onChanged: (bool? value) {
                                  setState(() {
                                    checkBoxState = value;
                                  });
                                },
                              ),*/
                                ]),
                              ),
                              /*const Padding(
                            padding: EdgeInsets.only(
                                top: 20, right: 30, bottom: 10),
                            child: Text('Forgot Password?',
                                style: TextStyle(
                                    color: Color(0xff120D26), fontSize: 12)),
                          )*/
                            ],
                          ),
                          Container(
                            height: 56,
                            width: 360,
                            margin: const EdgeInsets.symmetric(
                                vertical: 10.0, horizontal: 40.0),
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: Color(0xe03D56F0),
                              borderRadius: BorderRadius.all(
                                Radius.circular(15.0),
                              ),
                            ),
                            child: InkWell(
                              child: const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Stack(
                                  children: <Widget>[
                                    Center(
                                      child: Text('SIGN IN',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 20)),
                                    ),
                                  ],
                                ),
                              ),
                              onTap: () {
                                showOrHideProgress(true);
                                if (email == "Kannan" && password == "1234") {
                                  navigateToDashboard(context);
                                }

                                /*if (password.isNotEmpty) {
                                  LoginApiService()
                                      .doLogin(email, password)
                                      .catchError((error, stackTrace) {
                                    print(error);
                                    print(stackTrace);
                                    showOrHideProgress(false);
                                    return error;
                                  }).whenComplete(() {
                                    navigateToDashboard(context);
                                  });
                                } else {
                                  showOrHideProgress(false);
                                }*/
                                //navigateToDashboard(context);
                              },
                            ),
                          ),
                          /*const Padding(
                        padding: EdgeInsets.only(),
                        child: Text('OR ',
                            style: TextStyle(
                                fontSize: 14,
                                color: Color(0xff9D9898),
                                fontWeight: FontWeight.bold)),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 30,bottom: 30),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Don\'t have an account? '),
                            Padding(
                              padding: const EdgeInsets.only(left: 5.0,),
                              child: InkWell(
                                  onTap: () {
                                    Navigator.of(context)
                                        .pushReplacement(MaterialPageRoute(
                                      builder: (context) =>
                                      const SignUpScreen(),
                                    ));
                                  },
                                  child: const Text(
                                    'Sign Up',
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xe03D56F0)),
                                  )),
                            )
                          ],
                        ),
                      )*/
                        ],
                      ),
                    )),
                /*Visibility(
                  visible: showProgress,
                  child: const Center(child: CircularProgressIndicator()),
                ),*/
              ],
            )),
        if (showProgress)
          const Center(
            child: SizedBox(
              width: 100,
              height: 100,
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  navigateToDashboard(BuildContext context) {
    //set to shared preferences.
    // todo add shared preference initialization in UserSessionDetails
    showOrHideProgress(false);
    LoginApiService().navigateDashboardPage(context);
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreen createState() => _LoginScreen();
}
