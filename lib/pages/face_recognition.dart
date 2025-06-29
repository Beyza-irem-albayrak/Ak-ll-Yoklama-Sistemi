import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'student_page.dart';

class FaceRecognitionPage extends StatefulWidget {
  final String studentId;
  final String number;
  final int hafta;
  final String ders;

  const FaceRecognitionPage({
    Key? key,
    required this.studentId,
    required this.number,
    required this.hafta,
    required this.ders,
  }) : super(key: key);

  @override
  State<FaceRecognitionPage> createState() => _FaceRecognitionPageState();
}

class _FaceRecognitionPageState extends State<FaceRecognitionPage> {
  String message = "Yüz tanıma işlemi başlatılıyor...";
  bool isLoading = true;
  IconData? icon;
  Color? iconColor;

  @override
  void initState() {
    super.initState();
    _handleFaceRecognition();
  }

  Future<void> _handleFaceRecognition() async {
    try {
      // 🔒 Aktif hafta kontrolü
      final classDoc = await FirebaseFirestore.instance
          .collection('classes')
          .where('classname', isEqualTo: widget.ders)
          .get();

      if (classDoc.docs.isNotEmpty) {
        final activeWeek = classDoc.docs.first['activeWeek'];
        if (activeWeek != widget.hafta) {
          setState(() {
            message = "Sadece aktif hafta ($activeWeek) için yoklama alınabilir.";
            icon = Icons.lock_clock;
            iconColor = Colors.red;
            isLoading = false;
          });
          await Future.delayed(const Duration(seconds: 3));
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => StudentPage(studentId: widget.studentId),
            ),
          );
          return;
        }
      }
      const double allowedDistance = 1000;
      const double classLatitude = 41.364410578264135;
      const double classLongitude = 36.18468888229358;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          setState(() {
            message = "Konum izni verilmedi.";
            icon = Icons.location_off;
            iconColor = Colors.red;
            isLoading = false;
          });
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      double distance = Geolocator.distanceBetween(
        classLatitude,
        classLongitude,
        position.latitude,
        position.longitude,
      );

      if (distance > allowedDistance) {
        setState(() {
          message = "Konum dışında olduğunuz için yoklama alınmadı.";
          icon = Icons.cancel;
          iconColor = Colors.red;
          isLoading = false;
        });
        return;
      }

      print("🟡 [1] Firebase'deki kayıtlı yüz kontrol ediliyor...");
      print("📌 Firebase'den indirilecek fotoğraf: students/${widget.number}.jpg");

      final storageRef = FirebaseStorage.instance.ref().child('students/${widget.number}.jpg');

      bool exists;
      try {
        await storageRef.getDownloadURL();
        exists = true;
        print("✅ [1a] Kayıtlı yüz bulundu.");
      } catch (_) {
        exists = false;
        print("⚠️ [1b] Kayıtlı yüz BULUNAMADI. İlk kayıt yapılacak.");
      }

      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 100, // Maksimum kalite
      );
      if (pickedFile == null) {
        setState(() {
          message = "Fotoğraf çekilemedi.";
          icon = Icons.camera_alt_outlined;
          iconColor = Colors.red;
          isLoading = false;
        });
        print("❌ [2] Kamera fotoğrafı alınamadı.");
        return;
      }

      final newImage = File(pickedFile.path);
      print("📷 [2] Yeni yüz başarıyla çekildi.");

      if (!exists) {
        try {
          print("🟡 [3a] Fotoğraf yükleniyor...");
          await storageRef.putFile(newImage);
          print("✅ [3b] Fotoğraf başarıyla yüklendi.");

          setState(() {
            message = "Yüz başarıyla yüklendi. Sonraki yoklamalarda kullanılacaktır.";
            icon = Icons.done;
            iconColor = Colors.green;
            isLoading = false;
          });
          return;
        } catch (e) {
          print("❌ [3c] Fotoğraf yükleme hatası: $e");
          setState(() {
            message = "Fotoğraf yüklenirken hata oluştu: $e";
            icon = Icons.error;
            iconColor = Colors.red;
            isLoading = false;
          });
          return;
        }
      }

      final tempDir = await getTemporaryDirectory();
      final savedImage = File('${tempDir.path}/registered.jpg');
      await storageRef.writeToFile(savedImage);
      print("📥 [4] Kayıtlı fotoğraf geçici dizine indirildi: ${savedImage.path}");

      final uri = Uri.parse("http://172.20.10.12:5000/verify");
      final request = http.MultipartRequest("POST", uri)
        ..files.add(await http.MultipartFile.fromPath('saved', savedImage.path))
        ..files.add(await http.MultipartFile.fromPath('new', newImage.path));

      print("📤 [5] Sunucuya yüz karşılaştırma isteği gönderiliyor...");

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print("📩 [6] Sunucudan gelen yanıt: ${response.statusCode} | Body: $responseBody");

      if (response.statusCode == 200) {
        final result = json.decode(responseBody);
        if (result['match'] == true) {
          final added = await _markAttendance();
          if (added) {
            setState(() {
              message = "Yoklama başarıyla alındı!";
              icon = Icons.check_circle;
              iconColor = Colors.green;
              isLoading = false;
            });
          } else {
            setState(() {
              message = "Zaten yoklama alınmış.";
              icon = Icons.info_outline;
              iconColor = Colors.orange;
              isLoading = false;
            });
          }
        } else {
          setState(() {
            message = "Yüzler eşleşmedi. Yoklama başarısız.";
            icon = Icons.cancel;
            iconColor = Colors.red;
            isLoading = false;
          });
          print("❌ [7] Yüzler eşleşmedi.");
        }
      } else {
        final errorMsg = json.decode(responseBody)['error'] ?? "Sunucu hatası oluştu.";
        setState(() {
          message = "Sunucu hatası: $errorMsg";
          icon = Icons.error;
          iconColor = Colors.red;
          isLoading = false;
        });
        print("❌ [6] Sunucudan hata alındı: $errorMsg");
      }
    } catch (e) {
      setState(() {
        message = "Hata oluştu: $e";
        icon = Icons.error;
        iconColor = Colors.red;
        isLoading = false;
      });
      print("❌ [!] Hata oluştu: $e");
    }

    await Future.delayed(const Duration(seconds: 3));
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => StudentPage(studentId: widget.studentId),
      ),
    );
  }

  Future<bool> _markAttendance() async {
    final firestore = FirebaseFirestore.instance;
    final querySnapshot = await firestore
        .collection('classes')
        .where('classname', isEqualTo: widget.ders)
        .get();

    if (querySnapshot.docs.isEmpty) return false;

    final docRef = querySnapshot.docs.first.reference;
    final haftaKey = 'Hafta ${widget.hafta}';

    final doc = await docRef.get();
    List<dynamic> haftaList = (doc[haftaKey] ?? []);

    if (!haftaList.contains(widget.number)) {
      haftaList.add(widget.number);
      await docRef.update({haftaKey: haftaList});
      print("✅ [8] Yoklama Firestore'a kaydedildi.");
      return true;
    } else {
      print("⚠️ [8] Öğrenci zaten bu hafta için kayıtlı.");
      return false;
    }
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isLoading
                ? const CircularProgressIndicator()
                : Icon(icon ?? Icons.help_outline, size: 80, color: iconColor ?? Colors.grey),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                message,
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
