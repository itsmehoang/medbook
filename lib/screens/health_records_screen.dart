import 'package:flutter/material.dart';
import '../models/medical_record_model.dart';
import '../models/medication_reminder_model.dart';
import '../models/patient_profile_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class HealthRecordsScreen extends StatefulWidget {
  const HealthRecordsScreen({super.key});

  @override
  State<HealthRecordsScreen> createState() => _HealthRecordsScreenState();
}

class _HealthRecordsScreenState extends State<HealthRecordsScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;

  List<PatientProfileModel> _profiles = [];
  int? _selectedProfileId;

  List<MedicalRecordModel> _records = [];
  List<MedicationReminderModel> _medications = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final profiles = await _apiService.getProfiles();
      final records = await _apiService.getMedicalRecords(profileId: _selectedProfileId);
      final meds = await _apiService.getMedications(profileId: _selectedProfileId);

      setState(() {
        _profiles = profiles;
        _records = records;
        _medications = meds;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleToggleMed(MedicationReminderModel med) async {
    final original = med.isTakenToday;
    setState(() => med.isTakenToday = !original);

    try {
      await _apiService.toggleMedication(med.id);
    } catch (e) {
      setState(() => med.isTakenToday = original);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi cập nhật: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _showAddRecordDialog() {
    final specialtyCtrl = TextEditingController(text: 'Khám tổng quát');
    final diagnosisCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final prescriptionCtrl = TextEditingController();
    final bpCtrl = TextEditingController(text: '120/80 mmHg');
    final hrCtrl = TextEditingController(text: '75');
    final sugarCtrl = TextEditingController(text: '5.6');
    final weightCtrl = TextEditingController(text: '65');
    final dateCtrl = TextEditingController(text: DateTime.now().toString().split(' ')[0]);
    int profileId = _selectedProfileId ?? (_profiles.isNotEmpty ? _profiles.first.id : 1);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Thêm Hồ Sơ Khám & Chỉ Số',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Text('Người khám: ', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButton<int>(
                        value: profileId,
                        isExpanded: true,
                        items: _profiles
                            .map((p) => DropdownMenuItem(value: p.id, child: Text('${p.fullName} (${p.relationship})')))
                            .toList(),
                        onChanged: (val) => setModalState(() => profileId = val ?? profileId),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: specialtyCtrl,
                  decoration: const InputDecoration(labelText: 'Chuyên khoa *'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: diagnosisCtrl,
                  decoration: const InputDecoration(labelText: 'Chẩn đoán xác định *'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: bpCtrl,
                        decoration: const InputDecoration(labelText: 'Huyết áp (mmHg)'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: hrCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Nhịp tim (bpm)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: sugarCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Đường huyết (mmol/L)'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: weightCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Cân nặng (kg)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: prescriptionCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Đơn thuốc kê đơn'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(labelText: 'Lời dặn dò của bác sĩ'),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () async {
                    if (diagnosisCtrl.text.trim().isEmpty) return;
                    try {
                      await _apiService.createMedicalRecord(
                        profileId: profileId,
                        specialtyName: specialtyCtrl.text.trim(),
                        diagnosis: diagnosisCtrl.text.trim(),
                        examDate: dateCtrl.text.trim(),
                        doctorNotes: notesCtrl.text.trim(),
                        prescription: prescriptionCtrl.text.trim(),
                        bloodPressure: bpCtrl.text.trim(),
                        heartRate: int.tryParse(hrCtrl.text.trim()),
                        bloodSugar: double.tryParse(sugarCtrl.text.trim()),
                        weight: double.tryParse(weightCtrl.text.trim()),
                      );
                      Navigator.of(ctx).pop();
                      _loadAllData();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppTheme.errorColor),
                      );
                    }
                  },
                  child: const Text('Lưu hồ sơ'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddMedDialog() {
    final medNameCtrl = TextEditingController();
    final dosageCtrl = TextEditingController(text: '1 viên sau ăn');
    String timeOfDay = 'Sáng';
    final timeCtrl = TextEditingController(text: '08:00:00');
    final startDateCtrl = TextEditingController(text: DateTime.now().toString().split(' ')[0]);
    final endDateCtrl = TextEditingController(text: DateTime.now().add(const Duration(days: 30)).toString().split(' ')[0]);
    int profileId = _selectedProfileId ?? (_profiles.isNotEmpty ? _profiles.first.id : 1);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Thêm Nhắc Lịch Uống Thuốc',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Text('Người uống: ', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButton<int>(
                        value: profileId,
                        isExpanded: true,
                        items: _profiles
                            .map((p) => DropdownMenuItem(value: p.id, child: Text('${p.fullName} (${p.relationship})')))
                            .toList(),
                        onChanged: (val) => setModalState(() => profileId = val ?? profileId),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: medNameCtrl,
                  decoration: const InputDecoration(labelText: 'Tên thuốc * (VD: Amlodipine 5mg)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: dosageCtrl,
                  decoration: const InputDecoration(labelText: 'Liều lượng * (VD: 1 viên sau ăn)'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text('Buổi: ', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: timeOfDay,
                      items: const [
                        DropdownMenuItem(value: 'Sáng', child: Text('Sáng')),
                        DropdownMenuItem(value: 'Trưa', child: Text('Trưa')),
                        DropdownMenuItem(value: 'Chiều', child: Text('Chiều')),
                        DropdownMenuItem(value: 'Tối', child: Text('Tối')),
                      ],
                      onChanged: (val) => setModalState(() => timeOfDay = val ?? 'Sáng'),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextField(
                        controller: timeCtrl,
                        decoration: const InputDecoration(labelText: 'Giờ (HH:mm:ss)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () async {
                    if (medNameCtrl.text.trim().isEmpty) return;
                    try {
                      await _apiService.createMedication(
                        profileId: profileId,
                        medicineName: medNameCtrl.text.trim(),
                        dosage: dosageCtrl.text.trim(),
                        timeOfDay: timeOfDay,
                        reminderTime: timeCtrl.text.trim(),
                        startDate: startDateCtrl.text.trim(),
                        endDate: endDateCtrl.text.trim(),
                      );
                      Navigator.of(ctx).pop();
                      _loadAllData();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppTheme.errorColor),
                      );
                    }
                  },
                  child: const Text('Tạo lịch nhắc thuốc'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Hồ Sơ Sức Khỏe & Trị Liệu',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: AppTheme.primaryColor,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(icon: Icon(Icons.assignment_outlined), text: 'Bệnh án & Chỉ số'),
            Tab(icon: Icon(Icons.medication_outlined), text: 'Nhắc uống thuốc'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryColor,
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddRecordDialog();
          } else {
            _showAddMedDialog();
          }
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          _tabController.index == 0 ? 'Thêm bệnh án' : 'Thêm cữ thuốc',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
                      const SizedBox(height: 12),
                      Text(_errorMessage!),
                      const SizedBox(height: 16),
                      FilledButton(onPressed: _loadAllData, child: const Text('Thử lại')),
                    ],
                  ),
                )
              : Column(
              children: [
                if (_profiles.isNotEmpty)
                  Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: const Text('Tất cả gia đình'),
                            selected: _selectedProfileId == null,
                            selectedColor: AppTheme.primaryLight,
                            labelStyle: TextStyle(
                              color: _selectedProfileId == null ? AppTheme.primaryColor : const Color(0xFF475569),
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (val) {
                              setState(() => _selectedProfileId = null);
                              _loadAllData();
                            },
                          ),
                        ),
                        ..._profiles.map((p) {
                          final isSelected = _selectedProfileId == p.id;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text('${p.fullName} (${p.relationship})'),
                              selected: isSelected,
                              selectedColor: AppTheme.primaryLight,
                              labelStyle: TextStyle(
                                color: isSelected ? AppTheme.primaryColor : const Color(0xFF475569),
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              onSelected: (val) {
                                setState(() => _selectedProfileId = val ? p.id : null);
                                _loadAllData();
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildMedicalRecordsTab(),
                      _buildMedicationsTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMedicalRecordsTab() {
    final latestRecord = _records.isNotEmpty ? _records.first : null;

    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // KHỐI CHỈ SỐ SINH TỒN HIỆN ĐẠI (4 THẺ PASTEL)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'CHỈ SỐ SINH TỒN GẦN NHẤT',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppTheme.primaryColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (latestRecord != null)
                      Text(
                        'Ngày: ${latestRecord.examDate}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _buildVitalTile(
                      label: 'Huyết áp',
                      value: latestRecord?.bloodPressure ?? '120/80',
                      unit: 'mmHg',
                      icon: Icons.favorite_rounded,
                      bgColor: const Color(0xFFE0F2FE),
                      iconColor: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    _buildVitalTile(
                      label: 'Nhịp tim',
                      value: '${latestRecord?.heartRate ?? 75}',
                      unit: 'bpm',
                      icon: Icons.monitor_heart_rounded,
                      bgColor: const Color(0xFFFCE7F3),
                      iconColor: const Color(0xFFDB2777),
                    ),
                    const SizedBox(width: 8),
                    _buildVitalTile(
                      label: 'Đường huyết',
                      value: '${latestRecord?.bloodSugar ?? 5.4}',
                      unit: 'mmol/L',
                      icon: Icons.water_drop_rounded,
                      bgColor: const Color(0xFFFEF3C7),
                      iconColor: const Color(0xFFD97706),
                    ),
                    const SizedBox(width: 8),
                    _buildVitalTile(
                      label: 'Cân nặng',
                      value: '${latestRecord?.weight ?? 65}',
                      unit: 'kg',
                      icon: Icons.scale_rounded,
                      bgColor: const Color(0xFFCCFBF1),
                      iconColor: AppTheme.accentColor,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Lịch sử khám & Hồ sơ bệnh án',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),

          if (_records.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.folder_open_outlined, size: 54, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    const Text('Chưa có hồ sơ bệnh án nào được ghi nhận.'),
                  ],
                ),
              ),
            )
          else
            ..._records.map((rec) {
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          rec.specialtyName,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor, fontSize: 14),
                        ),
                        Text(rec.examDate, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Chẩn đoán: ${rec.diagnosis}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    if (rec.doctorName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Bác sĩ điều trị: ${rec.doctorDisplayName}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ],
                    if (rec.doctorNotes != null && rec.doctorNotes!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.lightbulb_outline, size: 16, color: Color(0xFFB45309)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Lời dặn: ${rec.doctorNotes!}',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (rec.prescription != null && rec.prescription!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('Đơn thuốc kê toa:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                      Text(rec.prescription!, style: const TextStyle(fontSize: 12, height: 1.4)),
                    ],
                  ],
                ),
              );
            }),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildVitalTile({
    required String label,
    required String value,
    required String unit,
    required IconData icon,
    required Color bgColor,
    required Color iconColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '$label\n($unit)',
              style: const TextStyle(fontSize: 9, color: Color(0xFF475569)),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationsTab() {
    if (_medications.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadAllData,
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Center(
              child: Column(
                children: [
                  Icon(Icons.medication_liquid_rounded, size: 54, color: Color(0xFFCBD5E1)),
                  SizedBox(height: 12),
                  Text('Chưa có lịch nhắc thuốc nào.'),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _medications.length,
        separatorBuilder: (ctx, i) => const SizedBox(height: 12),
        itemBuilder: (ctx, i) {
          final med = _medications[i];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => _handleToggleMed(med),
                  icon: Icon(
                    med.isTakenToday ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                    color: med.isTakenToday ? AppTheme.successColor : const Color(0xFFCBD5E1),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        med.medicineName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          decoration: med.isTakenToday ? TextDecoration.lineThrough : null,
                          color: med.isTakenToday ? const Color(0xFF94A3B8) : const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Liều dùng: ${med.dosage}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Buổi: ${med.timeOfDay} lúc ${med.reminderTime.substring(0, 5)}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: const Text('Xóa nhắc thuốc'),
                        content: Text('Xóa lịch nhắc thuốc "${med.medicineName}"?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Hủy')),
                          FilledButton(
                            style: FilledButton.styleFrom(backgroundColor: AppTheme.errorColor),
                            onPressed: () => Navigator.pop(c, true),
                            child: const Text('Xóa'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await _apiService.deleteMedication(med.id);
                      _loadAllData();
                    }
                  },
                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFF94A3B8), size: 20),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
