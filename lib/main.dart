import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_qryoklamasistemi/pages/lecturer_login.dart';
import 'pages/student_login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  await initializeDateFormatting('tr_TR', '');
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  try {
    await FirebaseAuth.instance.signInAnonymously();
    print("✅ Anonim giriş başarılı.");
  } catch (e) {
    print("❌ Anonim giriş başarısız: \$e");
  }
  runApp(
    const MaterialApp(
      home: QRyoklamasistemi(),
      debugShowCheckedModeBanner: false,
    ),
  );
}

class QRyoklamasistemi extends StatelessWidget {
  const QRyoklamasistemi({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(
            image: DecorationImage(
                fit: BoxFit.cover,
                image: AssetImage("assets/images/arkaplanmain.png"))),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 125.0),
              child: SizedBox(
                height: 200,
                width: 200,
                child:
                Image(image: AssetImage('assets/images/omulogo.png')),
              ),
            ),
            const SizedBox(
              height: 25,
            ),
            const Text(
              'Hoşgeldiniz',
              style: TextStyle(
                fontSize: 30,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 30),
            GestureDetector(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const StudentLoginPage()));
              },
              child: Container(
                height: 53,
                width: 320,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.black),
                ),
                child: const Center(
                  child: Text(
                    'Öğrenci',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 25),
            GestureDetector(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                        const LecturerLoginPage()));
              },
              child: Container(
                height: 53,
                width: 320,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.black),
                ),
                child: const Center(
                  child: Text(
                    'Öğretim Görevlisi',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.all(15.0),
              child: Text(
                'ONDOKUZ MAYIS ÜNİVERSİTESİ',
                style: TextStyle(
                  fontSize: 17,
                  color: Colors.black,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
