import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_qryoklamasistemi/pages/scanqr.dart';
import 'package:flutter_qryoklamasistemi/pages/student_login.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'face_recognition.dart';
import 'student_slot_page.dart';

class StudentPage extends StatefulWidget {
  final String studentId;
  const StudentPage({required this.studentId, super.key});

  @override
  _StudentPageState createState() => _StudentPageState();
}

class _StudentPageState extends State<StudentPage> {
  String formattedDateTime = ''; // Saat bilgisini saklayan değişken
  late Timer _timer; // Timer nesnesini burada tanımlıyoruz
  String studentName = ''; //Öğrenci ismi
  String studentEmail = ''; //öğrenci maili
  String studentNumber = ''; //vs

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('tr_TR', ''); // DateFormat için tr_TR dil

    // Zamanlayıcıyı başlatmak için initState içinde Timer.periodic'i kullanıyoruz
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      // Saat bilgisini her dakika başında güncelliyoruz
      setState(() {
        formattedDateTime =
            DateFormat('dd MMMM yyy\nHH:mm', 'tr_TR').format(DateTime.now());
      });
    });
    // Başlangıçta saat bilgisini de güncelliyoruz
    formattedDateTime =
        DateFormat('dd MMMM yyy\nHH:mm', 'tr_TR').format(DateTime.now());

    //Firestore'dan veri alma işlemleri:
    FirebaseFirestore.instance
        .collection('students')
        .doc(widget.studentId)
        .get()
        .then((DocumentSnapshot snapshot) {
      if (snapshot.exists) {
        setState(() {
          studentName = (snapshot.data() as Map<String, dynamic>)['name'];
          studentEmail = (snapshot.data() as Map<String, dynamic>)['email'];
          studentNumber = (snapshot.data() as Map<String, dynamic>)['number'];
        });
      } else {
        setState(() {
          studentName =
          'Bilinmeyen Öğrenci'; // Eğer belge bulunamazsa varsayılan değeri kullan
        });
      }
    }).catchError((error) {
      setState(() {
        studentName = 'Hata: $error'; // Hata durumunda hata mesajını kullan
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel(); // Timer'ı dispose() yönteminde iptal ediyoruz
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Firestore bağlantısı:
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    return MaterialApp(
      routes: {
        '/student-page': (context) => StudentPage(
          studentId: widget.studentId,
        ),
      },
      home: Scaffold(
        drawer: Drawer(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: <Widget>[
                    //Drawer Kodları:
                    DrawerHeader(
                      decoration: const BoxDecoration(
                          image: DecorationImage(
                              fit: BoxFit.cover,
                              image: AssetImage("assets/images/arkaplanmain.png"))),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            padding: EdgeInsets.zero,
                            decoration: const BoxDecoration(
                              image: DecorationImage(
                                image:
                                AssetImage("assets/images/omulogo.png"),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              studentEmail,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('students')
                          .doc(widget.studentId)
                          .get(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        var studentData = snapshot.data!.data() as Map<String, dynamic>;
                        List<String> classes = List<String>.from(studentData['classes']);
                        String number = studentData['number'];

                        return Column(
                          children: classes.map((ders) {
                            return FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('classes')
                                  .doc(ders)
                                  .get(),
                              builder: (context, dersSnap) {
                                if (!dersSnap.hasData || !dersSnap.data!.exists) {
                                  return const SizedBox.shrink();
                                }

                                var data = dersSnap.data!.data() as Map<String, dynamic>;
                                int toplamHafta = 0;
                                int katilimSayisi = 0;

                                data.forEach((key, value) {
                                  if (key.toString().startsWith('Hafta')) {
                                    toplamHafta++;
                                    if (value is List && value.contains(number)) {
                                      katilimSayisi++;
                                    }
                                  }
                                });

                                double oran = toplamHafta == 0 ? 0 : katilimSayisi / toplamHafta;

                                return Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  elevation: 3,
                                  child: Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Text(
                                          ders,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      SizedBox(
                                        height: 150,
                                        child: PieChart(
                                          PieChartData(
                                            centerSpaceRadius: 30,
                                            sections: [
                                              PieChartSectionData(
                                                value: oran,
                                                title: '${(oran * 100).toStringAsFixed(1)}%',
                                                color: Colors.primaries[
                                                classes.indexOf(ders) % Colors.primaries.length],
                                                radius: 50,
                                              ),
                                              PieChartSectionData(
                                                value: 1 - oran,
                                                title: '',
                                                color: Colors.grey.shade200,
                                                radius: 50,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text('Katıldığı: $katilimSayisi / $toplamHafta hafta'),
                                      const SizedBox(height: 8),
                                    ],
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        );
                      },
                    ),

                  ],
                ),
              ),
              Center(
                child: Container(
                  margin: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey,
                      width: 1.0,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                          const StudentLoginPage(), // Bu sınıfın mevcut olduğundan emin olun
                        ),
                      );
                    },
                    child: const ListTile(
                      title: Center(child: Text('Çıkış')),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        body: Center(
          child: Container(
            decoration: const BoxDecoration(
                image: DecorationImage(
                    fit: BoxFit.cover,
                    image: AssetImage("assets/images/arkaplanmain.png"))),
            child: Column(
              children: [
                AppBar(
                  backgroundColor: Colors.transparent,
                  leading: Builder(
                    builder: (BuildContext context) {
                      return IconButton(
                        icon: const Icon(Icons.menu),
                        color: Colors.black,
                        iconSize: 40,
                        onPressed: () {
                          Scaffold.of(context).openDrawer();
                        },
                      );
                    },
                  ),
                ),
                Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        "Hoş Geldiniz\n$studentName",
                        style: TextStyle(color: Colors.black, fontSize: 30, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (studentName.length <=
                        14) //İsim uzunluğu 14 karakterden kısaysa profil ikonu ekle
                      Padding(
                        padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                        child:
                        Icon(Icons.person, size: 65, color: Colors.black),
                      )
                  ],
                ),
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 0, 0),
                      child: Text(
                        formattedDateTime,
                        style:
                        const TextStyle(color: Colors.black, fontSize: 26),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(28.0),
                      child: Container(
                        width: MediaQuery.of(context).size.width / 1.5,
                        height: MediaQuery.of(context).size.height / 3,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              spreadRadius: 2,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Padding(padding: EdgeInsets.only(top: 20.0)),
                            const Text(
                              "Derslerim",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 0),
                            Expanded(
                              child: FutureBuilder<DocumentSnapshot>(
                                future: firestore
                                    .collection('students')
                                    .doc(widget.studentId)
                                    .get(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                        child: CircularProgressIndicator());
                                  }

                                  if (snapshot.hasError) {
                                    return Center(
                                        child:
                                        Text('Error: ${snapshot.error}'));
                                  }

                                  if (!snapshot.hasData ||
                                      !snapshot.data!.exists) {
                                    return const Center(
                                        child: Text('Veri Bulunamadı'));
                                  }

                                  var studentData = snapshot.data!.data()
                                  as Map<String, dynamic>;
                                  List<String> classes =
                                  List<String>.from(studentData['classes']);

                                  return ListView.builder(
                                    itemCount: classes.length,
                                    itemBuilder: (context, index) {
                                      return GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  StudentSlotsPage(
                                                    studentId: widget.studentId,
                                                    ders: classes[index],
                                                  ),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            border: Border(
                                              top: const BorderSide(
                                                  color: Colors
                                                      .grey), // Her öğe için üst kenarlık
                                              bottom: index ==
                                                  classes.length - 1
                                                  ? const BorderSide(
                                                  color: Colors.grey)
                                                  : BorderSide
                                                  .none, // Son öğe için alt kenarlık, diğerleri için yok
                                            ),
                                          ),
                                          child: ListTile(
                                            title: Text(classes[index]),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        width: MediaQuery.of(context).size.width / 1.5,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Ders Seçiniz',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  content: FutureBuilder<DocumentSnapshot>(
                                    future: firestore
                                        .collection('students')
                                        .doc(widget.studentId)
                                        .get(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Center(
                                            child: CircularProgressIndicator());
                                      }

                                      if (snapshot.hasError) {
                                        return Center(
                                            child: Text(
                                                'Error: ${snapshot.error}'));
                                      }

                                      if (!snapshot.hasData ||
                                          !snapshot.data!.exists) {
                                        return const Center(
                                            child: Text('No data found'));
                                      }

                                      var studentData = snapshot.data!.data()
                                      as Map<String, dynamic>;
                                      List<String> classes = List<String>.from(
                                          studentData['classes']);

                                      return SizedBox(
                                        width:
                                        MediaQuery.of(context).size.width *
                                            0.6,
                                        child: ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: classes.length,
                                          itemBuilder: (context, index) {
                                            return GestureDetector(
                                              onTap: () {
                                                showDialog(
                                                  context: context,
                                                  builder:
                                                      (BuildContext context) {
                                                    return FutureBuilder<int>(
                                                      future: getWeekCount(
                                                          classes[index]),
                                                      builder:
                                                          (context, snapshot) {
                                                        if (snapshot
                                                            .connectionState ==
                                                            ConnectionState
                                                                .waiting) {
                                                          return const Center(
                                                              child:
                                                              CircularProgressIndicator());
                                                        }

                                                        if (snapshot.hasError) {
                                                          return Center(
                                                              child: Text(
                                                                  'Error: ${snapshot.error}'));
                                                        }

                                                        if (!snapshot.hasData) {
                                                          return const Center(
                                                              child: Text(
                                                                  'No data found'));
                                                        }

                                                        return AlertDialog(
                                                          title: Text(
                                                              'Seçilen Ders: ${classes[index]}',
                                                            style: const TextStyle(
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                          content: SizedBox(
                                                            width: MediaQuery.of(
                                                                context)
                                                                .size
                                                                .width *
                                                                0.5,
                                                            child: ListView
                                                                .builder(
                                                              shrinkWrap: true,
                                                              itemCount:
                                                              snapshot
                                                                  .data!,
                                                              itemBuilder:
                                                                  (context,
                                                                  weekIndex) {
                                                                return ListTile(
                                                                  title: Text(
                                                                    'Hafta ${weekIndex + 1}',
                                                                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold,),
                                                                  ),
                                                                    onTap: () {
                                                                      showDialog(
                                                                        context: context,
                                                                        builder: (BuildContext dialogContext) {
                                                                          return AlertDialog(
                                                                            title: const Text("Yoklama Yöntemi Seçiniz"),
                                                                            content: Column(
                                                                              mainAxisSize: MainAxisSize.min,
                                                                              children: [
                                                                                ElevatedButton.icon(
                                                                                  onPressed: () {
                                                                                    Navigator.of(dialogContext).pop(); // dialogu kapat
                                                                                    Navigator.push(
                                                                                      context,
                                                                                      MaterialPageRoute(
                                                                                        builder: (context) => ScanQR(
                                                                                          ders: classes[index],
                                                                                          hafta: weekIndex + 1,
                                                                                          number: studentNumber,
                                                                                          studentId: widget.studentId,
                                                                                        ),
                                                                                      ),
                                                                                    );
                                                                                  },
                                                                                  icon: const Icon(Icons.qr_code),
                                                                                  label: const Text("QR ile Yoklama"),
                                                                                ),
                                                                                const SizedBox(height: 10),
                                                                                ElevatedButton.icon(
                                                                                  onPressed: () {
                                                                                    Navigator.of(dialogContext).pop(); // dialogu kapat
                                                                                    Navigator.push(
                                                                                      context,
                                                                                      MaterialPageRoute(
                                                                                        builder: (context) => FaceRecognitionPage(
                                                                                          ders: classes[index],
                                                                                          hafta: weekIndex + 1,
                                                                                          number: studentNumber,
                                                                                          studentId: widget.studentId,
                                                                                        ),
                                                                                      ),
                                                                                    );
                                                                                  },
                                                                                  icon: const Icon(Icons.face),
                                                                                  label: const Text("Face ID ile Yoklama"),
                                                                                ),

                                                                              ],
                                                                            ),
                                                                          );
                                                                        },
                                                                      );
                                                                    }
                                                                );
                                                              },
                                                            ),
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              child: const Text(
                                                                  'Kapat'),
                                                              onPressed: () {
                                                                Navigator.of(
                                                                    context)
                                                                    .pop();
                                                              },
                                                            ),
                                                          ],
                                                        );
                                                      },
                                                    );
                                                  },
                                                );
                                              },
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  border: Border(
                                                    top: const BorderSide(
                                                        color: Colors.grey),
                                                    bottom: index ==
                                                        classes.length - 1
                                                        ? const BorderSide(
                                                        color: Colors.grey)
                                                        : BorderSide.none,
                                                  ),
                                                ),
                                                child: ListTile(
                                                  title: Text(classes[index]),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                  actions: [
                                    TextButton(
                                      child: const Text('Kapat'),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Yoklamaya Katıl',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(width: 10),
                              Icon(Icons.qr_code,
                                  size: 30, color: Colors.black),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final collection = FirebaseFirestore.instance.collection("classes");

Future<int> getWeekCount(String ders) async {
  var querySnapshot = await collection.where('classname', isEqualTo: ders).get();

  if (querySnapshot.docs.isEmpty) {
    return 0;
  }

  var document = querySnapshot.docs.first;
  var data = document.data();

  // 🔍 Sadece "Hafta" ile başlayan alanları say
  int weekCount = data.keys
      .where((key) => key.toLowerCase().startsWith("hafta"))
      .length;

  return weekCount;
}
