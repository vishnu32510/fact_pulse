import 'package:fact_pulse/authentication/authentication.dart';
import 'package:fact_pulse/bloc_observer.dart';
import 'package:fact_pulse/firebase_options.dart';
import 'package:fact_pulse/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: ".env");
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  Bloc.observer = SimpleBlocObserver();
  runApp(AuthenticationWrapper(firebase: true,child: const DebateDynamicApp()));
}

class DebateDynamicApp extends StatelessWidget {
  const DebateDynamicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Facts Dynamics',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const LoginScreen(),
    );
  }
}
