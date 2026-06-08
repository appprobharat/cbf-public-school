import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:cbf/api_service.dart';
import 'package:cbf/homework/homework_detail_page.dart';
import 'package:cbf/homework/homework_page.dart';

bool _isDownloading = false;

String formatDate(String? inputDate) {
  if (inputDate == null || inputDate.isEmpty) return '';
  try {
    return DateFormat('dd-MM-yyyy').format(DateTime.parse(inputDate));
  } catch (_) {
    return inputDate;
  }
}

Future<void> downloadFile(BuildContext context, String filePath) async {
  if (_isDownloading) return;

  _isDownloading = true;

  try {
    print("=========== DOWNLOAD STARTED ===========");

    final fullUrl = filePath.trim();

    print("FULL URL => $fullUrl");

    final uri = Uri.parse(fullUrl);

    final fileName = uri.pathSegments.isNotEmpty
        ? uri.pathSegments.last
        : "downloaded_file";

    print("FILE NAME => $fileName");

    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        followRedirects: true,
        validateStatus: (status) {
          return status != null && status < 500;
        },
      ),
    );

    late String savePath;

    if (Platform.isAndroid) {
      final dir = Directory('/storage/emulated/0/Download');

      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      savePath = '${dir.path}/$fileName';
    } else {
      final dir = await getApplicationDocumentsDirectory();

      savePath = '${dir.path}/$fileName';
    }

    print("SAVE PATH => $savePath");

    final response = await dio.download(
      fullUrl,
      savePath,
      onReceiveProgress: (received, total) {
        if (total != -1) {
          final progress = ((received / total) * 100).toStringAsFixed(0);

          print("DOWNLOAD PROGRESS => $progress%");
        }
      },
    );

    print("STATUS CODE => ${response.statusCode}");
    print("STATUS MESSAGE => ${response.statusMessage}");

    // =========================
    // ❌ ERROR HANDLING
    // =========================

    if (response.statusCode != 200) {
      throw Exception("Server returned ${response.statusCode}");
    }

    final file = File(savePath);

    if (!await file.exists()) {
      throw Exception("File not found after download");
    }

    final fileSize = await file.length();

    print("DOWNLOADED FILE SIZE => $fileSize bytes");

    if (fileSize == 0) {
      throw Exception("Downloaded file is empty");
    }

    // =========================
    // 📂 OPEN FILE
    // =========================

    final openResult = await OpenFile.open(savePath);

    print("OPEN FILE RESULT => ${openResult.message}");

    if (!context.mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("✅ File downloaded successfully")));
  } on DioException catch (e, stack) {
    print("=========== DIO ERROR ===========");

    print("ERROR => $e");

    print("STATUS => ${e.response?.statusCode}");

    print("RESPONSE DATA => ${e.response?.data}");

    print("STACK => $stack");

    String message = "Download failed";

    if (e.response?.statusCode == 404) {
      message = "File not found on server";
    } else if (e.type == DioExceptionType.connectionTimeout) {
      message = "Connection timeout";
    } else if (e.type == DioExceptionType.receiveTimeout) {
      message = "Receive timeout";
    }

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  } catch (e, stack) {
    print("=========== GENERAL ERROR ===========");

    print(e);

    print(stack);

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ $e")));
    }
  } finally {
    print("=========== DOWNLOAD FINISHED ===========");

    _isDownloading = false;
  }
}

// ====================================================
// 📝 RECENT HOMEWORKS WIDGET (UI UNCHANGED)
// ====================================================
Widget buildRecentHomeworks(
  BuildContext context,
  List<Map<String, dynamic>> homeworks,
) {
  final limitedHomeworks = homeworks.take(3).toList();

  return Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.2),
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '📝 Recent Homeworks',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeworkPage()),
                );
              },
              child: const Text(
                "View All",
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
        limitedHomeworks.isEmpty
            ? const Text("No homeworks available.")
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: limitedHomeworks.length,
                itemBuilder: (context, index) {
                  final hw = limitedHomeworks[index];

                  return ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HomeworkDetailPage(homework: hw),
                        ),
                      );
                    },
                    leading: const Icon(Icons.book, color: AppColors.primary),
                    title: Text(
                      hw['HomeworkTitle'] ?? '',
                      style: const TextStyle(fontSize: 14),
                    ),
                    subtitle: Text(
                      'Submission: ${formatDate(hw['SubmissionDate'])}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: hw['Attachment'] != null
                        ? IconButton(
                            icon: const Icon(
                              Icons.download,
                              color: AppColors.primary,
                            ),
                            onPressed: () {
                              downloadFile(context, hw['Attachment']);
                            },
                          )
                        : const SizedBox.shrink(),
                  );
                },
              ),
      ],
    ),
  );
}
