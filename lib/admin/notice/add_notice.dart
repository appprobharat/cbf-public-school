import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cbf/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class AddNoticePage extends StatefulWidget {
  final String? noticeId;
  const AddNoticePage({super.key, this.noticeId});
  bool get isEdit => noticeId != null;

  @override
  State<AddNoticePage> createState() => _AddNoticePageState();
}

class RoleModel {
  final String id;
  final String role;

  RoleModel({required this.id, required this.role});

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(id: json['id'].toString(), role: json['Role'].toString());
  }
}

class EmployeeModel {
  final String id;
  final String name;
  final String designation;
  final String phone;

  EmployeeModel({
    required this.id,
    required this.name,
    required this.designation,
    required this.phone,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['id'].toString(),
      name: json['EmployeeName'].toString(),
      designation: json['Designation'].toString(),
      phone: json['ContactNo'].toString(),
    );
  }
}

class _AddNoticePageState extends State<AddNoticePage> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  List<EmployeeModel> employeeList = [];
  String? selectedEmployeeId;

  DateTime _issueDate = DateTime.now();
  DateTime _validDate = DateTime.now();
  File? _pickedFile;
  String _fileName = "No File Chosen";
  final ImagePicker _picker = ImagePicker();
  bool isEditLoading = false;
  bool isSaving = false;
  List<RoleModel> roleList = [];
  String? selectedRoleId;
  bool isRoleLoading = false;
  @override
  void initState() {
    super.initState();
    loadEmployees();
    loadRoles();
    if (widget.isEdit) {
      loadNoticeDetail();
    }
  }

  Future<void> loadRoles() async {
    try {
      setState(() => isRoleLoading = true);

      final response = await ApiService.post(context, "/get_role");

      if (response != null && response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        roleList = data.map((e) => RoleModel.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint("ROLE ERROR: $e");
    }

    if (mounted) {
      setState(() => isRoleLoading = false);
    }
  }

  Future<void> loadNoticeDetail() async {
    try {
      setState(() => isEditLoading = true);

      final response = await ApiService.post(
        context,
        "/admin/notice/edit",
        body: {"NoticeId": widget.noticeId},
      );

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);

        _titleCtrl.text = data['Title'] ?? "";
        _descCtrl.text = data['Description'] ?? "";

        selectedEmployeeId = data['AddedBy']?.toString();
        final roleNameFromApi = data['NoticeFor']?.toString();

        final matchedRole = roleList.firstWhere(
          (r) => r.role == roleNameFromApi,
          orElse: () => RoleModel(id: '', role: ''),
        );

        selectedRoleId = matchedRole.id.isEmpty ? null : matchedRole.id;

        _issueDate = DateTime.parse(data['Date']);
        _validDate = DateTime.parse(data['ValidDate']);

        if (data['Attachment'] != null) {
          _fileName = "Existing file";
        }
      }
    } catch (e) {
      debugPrint(e.toString());
    }

    if (mounted) {
      setState(() => isEditLoading = false);
    }
  }

  Future<void> loadEmployees() async {
    try {
      final response = await ApiService.post(context, "/get_employee");

      if (response != null && response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        employeeList = data.map((e) => EmployeeModel.fromJson(e)).toList();
        setState(() {});
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> saveNotice({bool isUpdate = false, String? noticeId}) async {
    if (_titleCtrl.text.isEmpty ||
        _descCtrl.text.isEmpty ||
        selectedRoleId == null ||
        selectedEmployeeId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Fill required fields")));
      return;
    }

    try {
      setState(() => isSaving = true); // ⭐ START LOADER

      final request = http.MultipartRequest(
        "POST",
        Uri.parse("${ApiService.baseUrl}/admin/notice/store"),
      );

      request.headers.addAll(await ApiService.multipartHeaders());

      request.fields.addAll({
        "Title": _titleCtrl.text,
        "Description": _descCtrl.text,
        "AddedBy": selectedEmployeeId!,
        "Date": formatApiDate(_issueDate),
        "ValidDate": formatApiDate(_validDate),
        "NoticeFor": roleList.firstWhere((r) => r.id == selectedRoleId).role,
      });

      if (isUpdate && noticeId != null) {
        request.fields["Type"] = "update";
        request.fields["NoticeId"] = noticeId;
      }

      if (_pickedFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('Attachment', _pickedFile!.path),
        );
      }

      final response = await request.send();

      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.pop(context, true); // ⭐ true bhej rahe hain
        }
      }
    } catch (e) {
      debugPrint("SAVE ERROR: $e");
    }

    if (mounted) {
      setState(() => isSaving = false); // ⭐ STOP LOADER
    }
  }

  Future<void> _pickDate(bool isIssue) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        if (isIssue) {
          _issueDate = picked;
        } else {
          _validDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6ECFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        leading: BackButton(),
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          widget.isEdit ? "Edit Notice" : "Add Notice",

          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: isEditLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: _box(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create Notice',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Divider(height: 16),

                    _label('Notice Title*'),
                    _input(_titleCtrl, 'Enter Notice Title'),

                    const SizedBox(height: 6),
                    _label('Notice Release By'),
                    _dropdownReleaseBy(),

                    const SizedBox(height: 6),
                    _label('Issue Date'),
                    _dateField(_issueDate, () => _pickDate(true)),

                    const SizedBox(height: 6),
                    _label('Valid Date'),
                    _dateField(_validDate, () => _pickDate(false)),

                    const SizedBox(height: 6),
                    _label('Description*'),
                    _textarea(_descCtrl, 'Enter Notice Description'),

                    const SizedBox(height: 6),
                    _label('Notice For*'),
                    _dropdownNoticeFor(),

                    const SizedBox(height: 6),
                    _label('Attachment/File/Document'),
                    _filePicker(),

                    const SizedBox(height: 14),
                    _saveBtn(),
                  ],
                ),
              ),
            ),
    );
  }

  // ---------- widgets ----------

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(t, style: const TextStyle(fontSize: 11)),
  );

  Widget _input(TextEditingController c, String hint) {
    return SizedBox(
      height: 36,
      child: TextField(
        controller: c,
        style: const TextStyle(fontSize: 11),
        decoration: _dec(hint),
      ),
    );
  }

  Widget _textarea(TextEditingController c, String hint) {
    return TextField(
      controller: c,
      maxLines: 3,
      style: const TextStyle(fontSize: 11),
      decoration: _dec(hint),
    );
  }

  Widget _dropdownReleaseBy() {
    return SizedBox(
      height: 34,
      child: DropdownButtonFormField<String>(
        value: selectedEmployeeId,
        hint: const Text('--Select Employee--', style: TextStyle(fontSize: 11)),
        items: employeeList.map((e) {
          return DropdownMenuItem(
            value: e.id,
            child: Text(
              "${e.name} (${e.designation}) / ${e.phone}",
              style: const TextStyle(fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: (v) => setState(() => selectedEmployeeId = v),
        decoration: _dec(''),
      ),
    );
  }

  Widget _dropdownNoticeFor() {
    return SizedBox(
      height: 34,
      child: DropdownButtonFormField<String>(
        value: selectedRoleId,
        hint: isRoleLoading
            ? const Text("Loading...", style: TextStyle(fontSize: 11))
            : const Text("--Select Role--", style: TextStyle(fontSize: 11)),
        items: roleList.map((role) {
          return DropdownMenuItem(
            value: role.id,
            child: Text(role.role, style: const TextStyle(fontSize: 11)),
          );
        }).toList(),
        onChanged: (v) => setState(() => selectedRoleId = v),
        decoration: _dec(''),
      ),
    );
  }

  String formatApiDate(DateTime d) {
    return "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
  }

  Widget _dateField(DateTime d, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 34,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: _innerBox(),
        child: Text(
          '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}',
          style: const TextStyle(fontSize: 11),
        ),
      ),
    );
  }

  Future<void> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() {
          _pickedFile = File(image.path);
          _fileName = image.name;
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Widget _filePicker() {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: _innerBox(),
      child: Row(
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade300,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
            onPressed: pickImage,
            child: const Text(
              'Choose Image',
              style: TextStyle(fontSize: 10, color: Colors.black),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _fileName,
              style: const TextStyle(fontSize: 10),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _saveBtn() {
    return Align(
      alignment: Alignment.center,
      child: SizedBox(
        height: 38,
        width: 130,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: isSaving
              ? null
              : () {
                  saveNotice(
                    isUpdate: widget.isEdit,
                    noticeId: widget.noticeId,
                  );
                },
          child: isSaving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.save, size: 16, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      widget.isEdit ? "Update" : "Save",
                      style: TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
  // ---------- decorations ----------

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 11),
    filled: true,
    fillColor: const Color(0xFFF4ECFA),
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
  );

  BoxDecoration _box() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
  );

  BoxDecoration _innerBox() => BoxDecoration(
    color: const Color(0xFFF4ECFA),
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: Colors.grey.shade300),
  );
}
