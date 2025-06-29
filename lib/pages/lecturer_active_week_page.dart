import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LecturerActiveWeekPage extends StatefulWidget {
  const LecturerActiveWeekPage({Key? key}) : super(key: key);

  @override
  State<LecturerActiveWeekPage> createState() => _LecturerActiveWeekPageState();
}

class _LecturerActiveWeekPageState extends State<LecturerActiveWeekPage> {
  String? selectedDers;
  int selectedWeek = 1;
  List<String> dersler = [];

  @override
  void initState() {
    super.initState();
    _fetchDersler();
  }

  Future<void> _fetchDersler() async {
    final query = await FirebaseFirestore.instance.collection("classes").get();
    final names = query.docs.map((doc) => doc.id).toList();
    setState(() {
      dersler = names;
    });
  }

  Future<void> _setActiveWeek() async {
    if (selectedDers == null) return;

    final docRef = FirebaseFirestore.instance.collection("classes").doc(selectedDers);
    await docRef.update({'activeWeek': selectedWeek});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("✅ '$selectedDers' için aktif hafta $selectedWeek olarak ayarlandı.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Aktif Hafta Ayarlama")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Ders Seç:", style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              value: selectedDers,
              hint: Text("Ders Seçiniz"),
              items: dersler.map((ders) {
                return DropdownMenuItem(
                  value: ders,
                  child: Text(ders),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedDers = value;
                });
              },
            ),
            SizedBox(height: 16),
            Text("Aktif Hafta Seç:", style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButton<int>(
              value: selectedWeek,
              items: List.generate(15, (i) => i + 1).map((hafta) {
                return DropdownMenuItem(
                  value: hafta,
                  child: Text("Hafta $hafta"),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedWeek = value;
                  });
                }
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _setActiveWeek,
              child: Text("Aktif Haftayı Kaydet"),
            )
          ],
        ),
      ),
    );
  }
}
