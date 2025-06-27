import 'package:fashionfrontend/views/pages/signup_page.dart';
import 'package:flutter/material.dart';
import 'package:fashionfrontend/app_colors.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          //Gradient in the background
          gradient: LinearGradient(
        colors: [
          Color(0xFF087BCE),
          AppColors.surface,
        ], //Blue Color
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: [0, .75],
      )),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * .5,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 175,
                        height: 175,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(20)),
                            color: AppColors.surface,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.onSurface,
                                spreadRadius: 1,
                                blurRadius: 15,
                                offset: const Offset(2, 2),
                              ),
                            ]),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.asset('assets/images/Shoes1.jpg'),
                        ),
                      ),
                      Container(
                        width: 175,
                        height: 175,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(20)),
                            color: AppColors.surface,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.onSurface.withAlpha(64),
                                spreadRadius: 1,
                                blurRadius: 15,
                                offset: const Offset(2, 2),
                              ),
                            ]),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.asset('assets/images/Shoes2.jpg'),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * .5,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 175,
                        height: 175,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(20)),
                            color: AppColors.surface,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.onSurface.withAlpha(64),
                                spreadRadius: 1,
                                blurRadius: 15,
                                offset: const Offset(2, 2),
                              ),
                            ]),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.asset('assets/images/Shoes3.jpg'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * .4,
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 25,
                  bottom: 25,
                ),
                child: Column(
                  spacing: 32,
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: DefaultTextStyle(
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 49,
                            fontWeight: FontWeight.normal,
                            color: AppColors.onSurface),
                        child: Text.rich(
                          TextSpan(children: [
                            TextSpan(
                              text: 'Find ',
                            ),
                            TextSpan(
                              text: 'Your\n',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            TextSpan(
                              text: 'Fashion',
                            ),
                          ]),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: DefaultTextStyle(
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.normal,
                            fontSize: 16,
                            color: AppColors.onSurface),
                        child: Text(
                          'The products you want\nto see, without all the clutter.',
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(context,
                              MaterialPageRoute(builder: (context) {
                            return SignupPage();
                          }));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          fixedSize: Size(150, 50),
                        ),
                        child: 
                        DefaultTextStyle(
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: AppColors.onPrimary),
                          child: Text("Get Started"),),
                      ),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
