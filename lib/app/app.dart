import 'package:flutter/material.dart';
import 'package:medreminder/app/theme.dart';
import 'package:medreminder/app/routes.dart';
import 'package:medreminder/screens/splash_screen.dart';
import 'package:medreminder/screens/registration_screen.dart';
import 'package:medreminder/screens/home_screen.dart';
import 'package:medreminder/screens/add_medicine_screen.dart';

class MedCareApp extends StatelessWidget {
  const MedCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MedCare+',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (context) => const SplashScreen(),
        AppRoutes.registration: (context) => const RegistrationScreen(),
        AppRoutes.home: (context) => const HomeScreen(),
        AppRoutes.addMedicine: (context) => const AddMedicineScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.editMedicine) {
          return MaterialPageRoute(
            builder: (context) => AddMedicineScreen(
              medicine: settings.arguments as dynamic,
            ),
          );
        }
        return null;
      },
    );
  }
}
