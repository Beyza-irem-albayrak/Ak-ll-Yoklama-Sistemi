import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_qryoklamasistemi/pages/student_page.dart';

class StudentSlotsPage extends StatefulWidget {
  final String ders;
  final String studentId;
  StudentSlotsPage({Key? key, required this.studentId, required this.ders})
      : super(key: key);

  @override
  State<StudentSlotsPage> createState() => _StudentSlotsPageState();
}

class _StudentSlotsPageState extends State<StudentSlotsPage> {
  final collection = FirebaseFirestore.instance.collection("classes");
  final studentsCollection = FirebaseFirestore.instance.collection("students");

  Future<int> GetWeekCount(String ders) async {
    var querySnapshot =
    await collection.where('classname', isEqualTo: ders).get();

    if (querySnapshot.docs.isEmpty) {
      return 0;
    }

    var document = querySnapshot.docs.first;
    var data = document.data();

    int count = 0;
    for (var key in data.keys) {
      if (key.startsWith("Hafta ")) count++;
    }
    return count;
  }

  Future<String?> getNumberByStudentId(String studentId) async {
    try {
      var docSnapshot = await FirebaseFirestore.instance
          .collection('students')
          .doc(studentId)
          .get();
      return docSnapshot.get('number')?.toString();
    } catch (e) {
      print('Hata: $e');
      return null;
    }
  }

  Future<List<List<String>>> GetWeekDetails(
      String ders, String studentId) async {
    var studentDoc = await studentsCollection.doc(studentId).get();
    if (!studentDoc.exists) {
      return [
        ["\u00d6\u011frenci Bulunamad\u0131"]
      ];
    }

    var querySnapshot =
    await collection.where('classname', isEqualTo: ders).get();

    if (querySnapshot.docs.isEmpty) {
      return [
        ["Bo\u015f Hafta"]
      ];
    }

    var document = querySnapshot.docs.first;
    var data = document.data();
    var studentnumber = await getNumberByStudentId(widget.studentId);

    List<List<String>> weeklist = [];

    for (var i = 1; i <= 16; i++) {
      var weekKey = 'Hafta $i';
      if (!data.containsKey(weekKey)) continue;

      var weekData = data[weekKey];

      if (weekData is List) {
        List<String> weekStudentStatuses = [];
        if (weekData.contains(studentnumber)) {
          weekStudentStatuses.add("Kat\u0131ld\u0131");
        } else {
          weekStudentStatuses.add("Kat\u0131lmad\u0131");
        }
        weeklist.add(weekStudentStatuses);
      }
    }

    return weeklist;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              fit: BoxFit.cover,
              image: AssetImage("assets/images/arkaplanmain.png"),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StudentPage(
                        studentId: widget.studentId,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 100),
              Image.asset(
                'assets/images/omulogo.png',
                fit: BoxFit.contain,
                height: 85.0,
              ),
              Expanded(child: Container()),
            ],
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            fit: BoxFit.cover,
            image: AssetImage("assets/images/arkaplanmain.png"),
          ),
        ),
        child: FutureBuilder<List<List<String>>>(
          future: GetWeekDetails(widget.ders, widget.studentId),
          builder: (context, detailsSnapshot) {
            if (detailsSnapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (detailsSnapshot.hasError) {
              return Center(child: Text('Error: ${detailsSnapshot.error}'));
            } else {
              final weekDetails = detailsSnapshot.data ?? [];
              final weeks =
              List.generate(weekDetails.length, (index) => 'Hafta ${index + 1}');
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(0xFFD6EAF8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${widget.ders} Dersine Kat\u0131l\u0131m Detaylar\u0131',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: weekDetails.length,
                      itemBuilder: (context, index) {
                        return WeekTile(
                          week: weeks[index],
                          items: weekDetails[index],
                        );
                      },
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}

class WeekTile extends StatefulWidget {
  final String week;
  final List<String> items;

  const WeekTile({Key? key, required this.week, required this.items})
      : super(key: key);

  @override
  _WeekTileState createState() => _WeekTileState();
}

class _WeekTileState extends State<WeekTile> {
  bool _isExpanded = false;

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Color(0xFFE6F0FA),
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(
              widget.week,
              style: TextStyle(
                color: Colors.blue.shade800,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
              color: Colors.grey.shade700,
            ),
            onTap: _toggleExpand,
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Column(
                children: widget.items
                    .map(
                      (item) => ListTile(
                    leading: Icon(
                      item == "Kat\u0131ld\u0131"
                          ? Icons.check_circle
                          : Icons.cancel,
                      color: item == "Kat\u0131ld\u0131"
                          ? Colors.green
                          : Colors.red,
                    ),
                    title: Text(
                      item,
                      style: TextStyle(
                        color: item == "Kat\u0131ld\u0131"
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}
