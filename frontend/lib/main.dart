import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // מייבא את הליבה של פיירבייס
import 'firebase_options.dart'; // מייבא את ההגדרות שנוצרו עבורך

void main() async {
  // 1. שורה זו מוודאת שכל רכיבי ה-Flutter מוכנים לפני שמתחילים
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. פקודה זו מחברת את האפליקציה לפרויקט הספציפי שלכם בענן
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. מפעיל את האפליקציה
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BudBull App',
      theme: ThemeData(primarySwatch: Colors.blue),
      // כאן אנחנו נגדיר בהמשך את מסך ההרשמה
      home: const Scaffold(body: Center(child: Text('Firebase מחובר!'))),
    );
  }
}