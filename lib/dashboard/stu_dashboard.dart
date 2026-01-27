import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cbf/Attendance_UI/stu_attendance_report.dart';
import 'package:cbf/Exam/exam_schedule.dart';
import 'package:cbf/Exam/stu_result.dart';
import 'package:cbf/api_service.dart';
import 'package:cbf/complaint/view_complaints_page.dart';
import 'package:cbf/connect_teacher/connect_with_us.dart';
import 'package:cbf/dashboard/calendar.dart';
import 'package:cbf/dashboard/timetable_page.dart';
import 'package:cbf/payment/payment_page.dart';
import 'package:cbf/school_info_page.dart';
import 'package:cbf/subjects_page.dart';
import 'package:cbf/syllabus/syllabus.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int fine = 0;
  int dues = 0;
  int payments = 0;
  String lastPaymentDate = '';
  String status = '';
  int subjects = 0;

  Map<String, dynamic> attendance = {};
  List<Map<String, dynamic>> homeworks = [];
  List notices = [];
  List events = [];
  List siblings = [];

  bool loading = true;
  @override
  void initState() {
    super.initState();
    fetchDashboardData(context).then((_) {
      setState(() {
        loading = false;
      });
    });
  }

  Future<void> fetchDashboardData(BuildContext context) async {
    final response = await ApiService.post(context, "/student/dashboard");

    if (response == null) return;

    debugPrint("🔵 DASHBOARD STATUS: ${response.statusCode}");
    debugPrint("🔵 DASHBOARD BODY: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      debugPrint("📢 RAW NOTICES: ${data['notices']}");
      fine = data['fine'] ?? 0;
      dues = data['dues'] ?? 0;
      payments = int.tryParse(data['payments'].toString()) ?? 0;

      final rawDate = data['payment_date'] ?? '';
      if (rawDate.isNotEmpty) {
        try {
          final dateObject = DateTime.parse(rawDate);
          lastPaymentDate =
              '${dateObject.day}/${dateObject.month}/${dateObject.year}';
        } catch (_) {
          lastPaymentDate = rawDate;
        }
      }

      status = data['today_status'] ?? '';
      subjects = data['subjects'] ?? 0;

      attendance = {
        'present': data['attendances']?['present'] ?? 0,
        'absent': data['attendances']?['absent'] ?? 0,
        'leave': data['attendances']?['leave'] ?? 0,
        'half_day': data['attendances']?['half_day'] ?? 0,
        'working_days': data['attendances']?['working_days'] ?? 0,
      };

      homeworks = List<Map<String, dynamic>>.from(data['homeworks'] ?? []);
      notices = data['notices'] ?? [];
      events = data['events'] ?? [];
      siblings = data['siblings'] ?? [];

      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),

      // 🔹 TOP PROFILE BAR
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ================= HEADER =================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(22),
                    bottomRight: Radius.circular(22),
                  ),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundImage: AssetImage("assets/images/logo.png"),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Vishal Raj",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Class 1 - Section A",
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Column(
                      children: const [
                        Icon(Icons.menu_book, color: Colors.white, size: 30),
                        SizedBox(height: 4),
                        Text(
                          "Shiwalik\nPublic School",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 05),

              // ================= TOP STATUS CARDS =================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: const [
                    Expanded(
                      child: _TopCard(
                        title: "Due Fee",
                        subtitle: "Pending: ",
                        value: "₹5,000",
                        color: Color(0xFFEF4444),
                        icon: Icons.currency_rupee,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: _TopCard(
                        title: "Late Pay",
                        subtitle: "",
                        value: "Pay Overdue",
                        color: Color(0xFFF97316),
                        icon: Icons.access_time,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: _TopCard(
                        title: "Today Attendance",
                        subtitle: "Present: ",
                        value: "5/6",
                        color: Color(0xFF22C55E),
                        icon: Icons.check_circle,
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      "Quick Links",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),

              // ================= QUICK LINKS GRID =================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  crossAxisCount: 4,
                  childAspectRatio: 0.95,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: const [
                    _QuickItem("Subjects", Icons.menu_book, Color(0xff42A5F5)),
                    _QuickItem(
                      "Time Table",
                      Icons.access_time,
                      Color(0xff7E57C2),
                    ),
                    _QuickItem(
                      "Calendar",
                      Icons.calendar_month,
                      Color(0xff66BB6A),
                    ),
                    _QuickItem("Syllabus", Icons.edit, Color(0xff26A69A)),

                    _QuickItem("Exam", Icons.assignment, Color(0xffFFA726)),
                    _QuickItem(
                      "Payment",
                      Icons.currency_rupee,
                      Color(0xffEF5350),
                    ),
                    _QuickItem("School Info", Icons.home, Color(0xff5C6BC0)),
                    _QuickItem("Notice", Icons.campaign, Color(0xffEC407A)),

                    _QuickItem(
                      "Attendance",
                      Icons.celebration,
                      Color(0xffFFB300),
                    ),
                    _QuickItem("Result", Icons.star, Color(0xffAB47BC)),
                    _QuickItem(
                      "Complaint",
                      Icons.report_problem,
                      Color(0xffFB8C00),
                    ),
                    _QuickItem("Chat", Icons.chat, Color(0xff43A047)),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ================= HOMEWORK SECTION =================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Homework",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),

                    if (homeworks.isEmpty) const Text("No homework assigned"),

                    ...List.generate(homeworks.length, (i) {
                      final hw = homeworks[i];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _HomeworkCard(
                          work: hw['HomeworkTitle'] ?? '',
                          date: hw['WorkDate'] ?? '',
                          attachment: hw['Attachment'],
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),

      // ================= BOTTOM NAV =================
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xff3F51B5),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.campaign), label: "Notice"),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Chat"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

class _TopCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;

  const _TopCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54, // 🔥 minimum practical height
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.35),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ROW 1: ICON + TITLE
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.28),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 13),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          // DIVIDER LINE
          Container(
            height: 1,
            width: double.infinity,
            color: Colors.white.withOpacity(0.25),
          ),

          const SizedBox(height: 4),

          // ROW 2: SUBTITLE + VALUE
          Row(
            children: [
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 9.5),
                ),
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _QuickItem(this.title, this.icon, this.color);
  void _openPage(BuildContext context, String title) {
    switch (title) {
      case "Subjects":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SubjectsPage()),
        );
        break;

      case "Time Table":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TimeTablePage()),
        );
        break;

      case "Calendar":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StudentCalendarPage()),
        );
        break;

      case "Syllabus":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SyllabusPage()),
        );
        break;

      case "Exam":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ExamSchedulePage()),
        );
        break;

      case "Payment":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PaymentPage()),
        );
        break;

      case "School Info":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SchoolInfoPage()),
        );
        break;

      case "Notice":
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(builder: (_) => const NoticePage()),
        // );
        break;

      case "Attendance":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => StudentAttendanceScreen()),
        );
        break;

      case "Result":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => StudentResultPage()),
        );
        break;

      case "Complaint":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ViewComplaintPage()),
        );
        break;

      case "Chat":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ConnectWithUsPage(
              teacherId: 0,
              teacherName: '',
              teacherPhoto: '',
            ),
          ),
        );
        break;

      default:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("$title page coming soon")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        _openPage(context, title); // 🔥 yahin navigation hoga
      },
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.30),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 26),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 2,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeworkCard extends StatefulWidget {
  final String work;
  final String date;
  final String attachment;

  const _HomeworkCard({
    required this.work,
    required this.date,
    required this.attachment,
  });

  @override
  State<_HomeworkCard> createState() => _HomeworkCardState();
}

bool _isDownloading = false;

class _HomeworkCardState extends State<_HomeworkCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.book, color: Colors.blue.shade700),
          const SizedBox(width: 12),

          // LEFT CONTENT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.work,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Due: ${widget.date}",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),

          // 🔥 RIGHT DOWNLOAD ICON (ONLY IF ATTACHMENT EXISTS)
          if (widget.attachment.isNotEmpty)
            InkWell(
              onTap: () {
                _downloadAttachment(context, widget.attachment);
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.download_rounded,
                  color: Colors.blue,
                  size: 22,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 🔹 DOWNLOAD FUNCTION
  Future<void> _downloadAttachment(
    BuildContext context,
    String filePath,
  ) async {
    if (_isDownloading) return;
    _isDownloading = true;

    // ✅ URL now comes from ApiService
    final fullUrl = filePath.startsWith('http')
        ? filePath
        : ApiService.homeworkAttachment(filePath);

    try {
      final fileName = fullUrl.split('/').last;
      final dio = Dio();
      late String savePath;

      // ================= ANDROID =================
      if (Platform.isAndroid) {
        final downloadsDir = Directory('/storage/emulated/0/Download');
        savePath = '${downloadsDir.path}/$fileName';

        await dio.download(fullUrl, savePath);

        // ✅ Preview open
        await OpenFile.open(savePath);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("📥 Downloaded & Preview opened")),
          );
        }
      }

      // ================= iOS =================
      if (Platform.isIOS) {
        final dir = await getApplicationDocumentsDirectory();
        savePath = '${dir.path}/$fileName';

        await dio.download(fullUrl, savePath);

        // ✅ Preview open
        await OpenFile.open(savePath);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("❌ Download failed")));
      }
    } finally {
      _isDownloading = false;
    }
  }
}
