import 'package:flutter/material.dart';
import 'package:flutter_qryoklamasistemi/pages/lecturer_login.dart';
import 'lecturer_slot_page.dart';
import 'createqr.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/services.dart';
import 'lecturer_active_week_page.dart';

class LecturerPage extends StatefulWidget {
  final String lecturerId; // Öğretim görevlisi ID
  const LecturerPage({required this.lecturerId, super.key});

  @override
  _LecturerPageState createState() => _LecturerPageState();
}

class _LecturerPageState extends State<LecturerPage> {
  String formattedDateTime = ''; // Saat bilgisini saklayan değişken
  late Timer _timer; // Timer nesnesini burada tanımlıyoruz
  String lecturerName = ''; //Öğretmen ismi
  String lecturerEmail = ''; //öğretmen maili

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('tr_TR', ''); // DateFormat için tr_TR dil
    // Zamanlayıcıyı başlatma
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
    //Firestore'dan email ve isim alma işlemleri:
    FirebaseFirestore.instance
        .collection('lecturers')
        .doc(widget.lecturerId)
        .get()
        .then((DocumentSnapshot snapshot) {
      if (snapshot.exists) {
        setState(() {
          lecturerName = (snapshot.data() as Map<String, dynamic>)['name'];
          lecturerEmail = (snapshot.data() as Map<String, dynamic>)[
              'email']; // Firestore'daki 'name' alanından değeri al
        });
      } else {
        setState(() {
          lecturerName =
              'Bilinmeyen Öğretmen'; // Eğer belge bulunamazsa varsayılan değeri kullan
        });
      }
    }).catchError((error) {
      setState(() {
        lecturerName = 'Hata: $error'; // Hata durumunda hata mesajını kullan
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
        '/teacher-page': (context) => LecturerPage(
              lecturerId: widget.lecturerId,
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
                              lecturerEmail,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
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
                              const LecturerLoginPage(), // Bu sınıfın mevcut olduğundan emin olun
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
                        //Drawer'ı aç:
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
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        "Hoş Geldiniz\n$lecturerName",
                        style:
                            const TextStyle(color: Colors.black, fontSize: 30, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                      child: Icon(Icons.person, size: 65, color: Colors.black),
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
                            //Derslerim Bölümü
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
                                    .collection('lecturers')
                                    .doc(widget.lecturerId)
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
                                        child: Text('No data found'));
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
                                          // 'slots_page' sayfasına yönlendir ve seçilen sınıfın adını ile
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => SlotsPage(
                                                lecturerID: widget.lecturerId,
                                                ders: classes[
                                                    index], // Seçilen sınıfın adını SlotsPage'e gönder
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
                            )
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
                                  title: Text('Ders Seçiniz'),
                                  content: FutureBuilder<DocumentSnapshot>(
                                    future: firestore
                                        .collection('lecturers')
                                        .doc(widget.lecturerId)
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

                                      return Container(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.7,
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.5,
                                        child: ListView.builder(
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

                                                        if (snapshot.data == 0) {
                                                          return const Center(child: Text('Hiç hafta bulunamadı'));
                                                        }

                                                        return AlertDialog(
                                                          title: Text('Seçilen Ders: ${classes[index]}'),
                                                          content: Container(
                                                            width: double.maxFinite,
                                                            child: ListView.builder(
                                                              shrinkWrap: true,
                                                              itemCount: snapshot.data!,
                                                              itemBuilder: (context, weekIndex) {
                                                                return ListTile(
                                                                  title: Text('Hafta ${weekIndex + 1}'),
                                                                  onTap: () {
                                                                    Navigator.push(
                                                                      context,
                                                                      MaterialPageRoute(
                                                                        builder: (context) => CreateQR(
                                                                          ders: classes[index],
                                                                          hafta: weekIndex + 1,
                                                                          lecturerId: widget.lecturerId,
                                                                        ),
                                                                      ),
                                                                    );
                                                                  },
                                                                );
                                                              },
                                                            ),
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              child: Text('Kapat'),
                                                              onPressed: () {
                                                                Navigator.of(context).pop();
                                                              },
                                                            ),
                                                            ElevatedButton(
                                                              onPressed: () async {
                                                                final classDoc = await FirebaseFirestore.instance
                                                                    .collection("classes")
                                                                    .where("classname", isEqualTo: classes[index])
                                                                    .get();

                                                                if (classDoc.docs.isNotEmpty) {
                                                                  final docId = classDoc.docs.first.id;
                                                                  final currentData = classDoc.docs.first.data();
                                                                  final weekCount = currentData.keys
                                                                      .where((key) => key.toLowerCase().startsWith("hafta"))
                                                                      .length;
                                                                  final newWeek = "Hafta ${weekCount + 1}";

                                                                  await FirebaseFirestore.instance
                                                                      .collection("classes")
                                                                      .doc(docId)
                                                                      .update({newWeek: []});

                                                                  Navigator.of(context).pop();
                                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                                    SnackBar(content: Text("$newWeek eklendi")),
                                                                  );
                                                                }
                                                              },
                                                              child: Text("Yeni Hafta Ekle"),
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
                                      child: Text('Kapat'),
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
                                'Yoklama Başlat',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
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
                SizedBox(height: 10), // İki buton arasında boşluk

                Container(
                  width: MediaQuery.of(context).size.width / 1.5,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LecturerActiveWeekPage(),
                        ),
                      );
                    },
                    icon: Icon(Icons.edit_calendar, color: Colors.black),
                    label: Text(
                      "Aktif Haftayı Ayarla",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
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
  var querySnapshot = await FirebaseFirestore.instance
      .collection('classes')
      .where('classname', isEqualTo: ders)
      .get();

  if (querySnapshot.docs.isEmpty) {
    print('Belge bulunamadı: $ders');
    return 0;
  }

  var data = querySnapshot.docs.first.data();

  print("Firestore verisi: $data");

  // Herhangi bir 'Hafta ' ile başlayan alanı say
  int count = data.keys
      .where((key) => key.toLowerCase().contains("hafta"))
      .length;

  return count == 0 ? 1 : count;
}

Future<void> lateStudent(String ders, String number, int hafta) async {
  final collection = FirebaseFirestore.instance.collection("classes");
  var querySnapshot =
      await collection.where('classname', isEqualTo: ders).get();

  if (querySnapshot.docs.isEmpty) {
    print('No documents found for class: $ders');
    return;
  }

  var document = querySnapshot.docs.first;

  // Hafta X alanını güncelle veya oluştur ve bir dizi olarak ayarla
  await FirebaseFirestore.instance
      .collection('classes')
      .doc(document.id)
      .update({
    'Hafta $hafta': FieldValue.arrayUnion([number]),
  });
}

