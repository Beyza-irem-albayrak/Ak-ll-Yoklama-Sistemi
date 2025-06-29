import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_qryoklamasistemi/pages/lecturer_page.dart';

class SlotsPage extends StatefulWidget {
  final String ders;
  final String lecturerID;
  SlotsPage({Key? key, required this.lecturerID, required this.ders})
      : super(key: key);

  @override
  State<SlotsPage> createState() => _SlotsPageState();
}

class _SlotsPageState extends State<SlotsPage> {
  final collection = FirebaseFirestore.instance.collection("classes");

  Future<int> getWeekCount(String ders) async {
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

  Future<String?> getStudentName(String number) async {
    var studentQuery = await FirebaseFirestore.instance
        .collection('students')
        .where('number', isEqualTo: number)
        .get();

    if (studentQuery.docs.isNotEmpty) {
      return studentQuery.docs.first['name'];
    }

    return null;
  }

  Future<List<List<String>>> GetWeekDetails(String ders) async {
    var querySnapshot =
    await collection.where('classname', isEqualTo: ders).get();

    if (querySnapshot.docs.isEmpty) {
      return [];
    }

    var document = querySnapshot.docs.first;
    var data = document.data();

    List<List<String>> weeklist = [];

    for (var i = 1; i <= 16; i++) {
      var weekKey = 'Hafta $i';
      if (!data.containsKey(weekKey)) continue;

      var weekData = data[weekKey];
      List<String> weekStudentNames = [];

      if (weekData is List) {
        for (var item in weekData) {
          if (item is String) {
            var studentName = await getStudentName(item);
            if (studentName != null) {
              weekStudentNames.add(studentName);
            }
          }
        }
      }
      weeklist.add(weekStudentNames);
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
                      builder: (context) => LecturerPage(
                        lecturerId: widget.lecturerID,
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
        child: FutureBuilder<int>(
          future: getWeekCount(widget.ders),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              final weekCount = snapshot.data ?? 0;
              final List<String> weeks =
              List.generate(weekCount, (index) => 'Hafta ${index + 1}');
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
                        '${widget.ders} Dersine Kat\u0131l\u0131m Listesi',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Expanded(
                    child: FutureBuilder<List<List<String>>>(
                      future: GetWeekDetails(widget.ders),
                      builder: (context, detailsSnapshot) {
                        if (detailsSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        } else if (detailsSnapshot.hasError) {
                          return Center(
                            child: Text('Error: ${detailsSnapshot.error}'),
                          );
                        } else {
                          final weekDetails = detailsSnapshot.data ?? [];
                          return ListView.builder(
                            itemCount: weekDetails.length,
                            itemBuilder: (context, index) {
                              return WeekTile(
                                week: 'Hafta ${index + 1}',
                                items: weekDetails[index],
                              );
                            },
                          );
                        }
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
                    leading: Icon(Icons.person_outline),
                    title: Text(
                      item,
                      style: TextStyle(fontWeight: FontWeight.w500),
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
