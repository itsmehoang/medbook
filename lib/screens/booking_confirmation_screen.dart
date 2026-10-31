import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/doctor_model.dart';
import '../models/patient_profile_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'appointment_ticket_screen.dart';

class BookingConfirmationScreen extends StatefulWidget {
  final DoctorModel doctor;
  final String workDate;
  final ScheduleSlot selectedSlot;

  const BookingConfirmationScreen({
    super.key,
    required this.doctor,
    required this.workDate,
    required this.selectedSlot,
  });

  @override
  State<BookingConfirmationScreen> createState() => _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  final _apiService = ApiService();
  final _symptomsController = TextEditingController();

  List<PatientProfileModel> _profiles = [];
  PatientProfileModel? _selectedProfile;
  String _examType = 'Dịch vụ'; // 'Dịch vụ' hoặc 'BHYT'
  bool _isLoadingProfiles = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  @override
  void dispose() {
    _symptomsController.dispose();
    super.dispose();
  }

  Future<void> _loadProfiles() async {
    setState(() => _isLoadingProfiles = true);
    try {
      final profiles = await _apiService.getProfiles();
      setState(() {
        _profiles = profiles;
        if (_profiles.isNotEmpty) {
          _selectedProfile = _profiles.first;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tải danh sách hồ sơ: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingProfiles = false);
    }
  }

  void _showAddProfileDialog() {
    final nameCtrl = TextEditingController();
    final dobCtrl = TextEditingController(text: '1990-01-01');
    final bhytCtrl = TextEditingController();
    String gender = 'Nam';
    String relationship = 'Con';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Thêm hồ sơ người thân', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Họ và tên người khám *'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: dobCtrl,
                        decoration: const InputDecoration(labelText: 'Ngày sinh (YYYY-MM-DD)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<String>(
                      value: gender,
                      items: const [
                        DropdownMenuItem(value: 'Nam', child: Text('Nam')),
                        DropdownMenuItem(value: 'Nữ', child: Text('Nữ')),
                      ],
                      onChanged: (val) => setModalState(() => gender = val ?? 'Nam'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Quan hệ: '),
                    DropdownButton<String>(
                      value: relationship,
                      items: const [
                        DropdownMenuItem(value: 'Bản thân', child: Text('Bản thân')),
                        DropdownMenuItem(value: 'Bố', child: Text('Bố')),
                        DropdownMenuItem(value: 'Mẹ', child: Text('Mẹ')),
                        DropdownMenuItem(value: 'Con', child: Text('Con')),
                        DropdownMenuItem(value: 'Vợ/Chồng', child: Text('Vợ/Chồng')),
                      ],
                      onChanged: (val) => setModalState(() => relationship = val ?? 'Con'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bhytCtrl,
                  decoration: const InputDecoration(labelText: 'Mã số thẻ BHYT (nếu có)'),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) return;
                    try {
                      final newProfile = await _apiService.createProfile(
                        fullName: nameCtrl.text.trim(),
                        dob: dobCtrl.text.trim(),
                        gender: gender,
                        relationship: relationship,
                        bhytCode: bhytCtrl.text.trim().isNotEmpty ? bhytCtrl.text.trim() : null,
                      );
                      if (ctx.mounted) Navigator.of(ctx).pop();
                      if (mounted) {
                        setState(() {
                          _profiles.add(newProfile);
                          _selectedProfile = newProfile;
                        });
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppTheme.errorColor),
                        );
                      }
                    }
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Lưu hồ sơ người khám'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleConfirmBooking() async {
    setState(() => _isSubmitting = true);

    try {
      debugPrint('[Booking] Bắt đầu gọi API đặt lịch khám...');
      debugPrint('[Booking] Doctor ID: ${widget.doctor.id} (${widget.doctor.displayName}), Profile ID: ${_selectedProfile?.id}, Slot ID: ${widget.selectedSlot.id}, Ngày: ${widget.workDate}, Giờ: ${widget.selectedSlot.timeSlot}, Hình thức: $_examType');

      final appointment = await _apiService.createAppointment(
        profileId: _selectedProfile?.id,
        doctorId: widget.doctor.id,
        scheduleId: widget.selectedSlot.id,
        workDate: widget.workDate,
        timeSlot: widget.selectedSlot.timeSlot,
        examType: _examType,
        symptoms: _symptomsController.text.trim(),
      );

      debugPrint('[Booking] Đặt lịch THÀNH CÔNG! Mã phiếu: ${appointment.bookingCode}, STT: ${appointment.queueNumber}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đặt lịch khám thành công!'),
            backgroundColor: AppTheme.successColor,
            duration: Duration(seconds: 2),
          ),
        );

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => AppointmentTicketScreen(appointment: appointment),
          ),
        );
      }
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      debugPrint('[Booking Error] Thất bại khi đặt lịch: $errorMsg');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đặt khám thất bại: $errorMsg'),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Đóng',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,###', 'vi_VN');

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Xác Nhận Đặt Khám', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tổng phí khám', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  Text(
                    '${currencyFormat.format(widget.doctor.basePrice)} đ',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _handleConfirmBooking,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'XÁC NHẬN ĐẶT LỊCH',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isLoadingProfiles
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tóm tắt lịch hẹn đã chọn (Card bo góc 16)
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
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: AppTheme.primaryLight,
                              backgroundImage: widget.doctor.avatarUrl != null
                                  ? NetworkImage(widget.doctor.avatarUrl!)
                                  : null,
                              child: widget.doctor.avatarUrl == null
                                  ? const Icon(Icons.person, color: AppTheme.primaryColor)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.doctor.displayName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.doctor.specialtyName ?? 'Chuyên khoa',
                                    style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 16, color: AppTheme.textSecondary),
                            const SizedBox(width: 6),
                            Text('Ngày: ${widget.workDate}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const Spacer(),
                            const Icon(Icons.access_time_rounded, size: 16, color: AppTheme.textSecondary),
                            const SizedBox(width: 6),
                            Text(widget.selectedSlot.timeSlot, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.room_outlined, size: 16, color: AppTheme.textSecondary),
                            const SizedBox(width: 6),
                            Text(widget.doctor.roomNumber, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                            const Spacer(),
                            Text(
                              '${currencyFormat.format(widget.doctor.basePrice)} đ',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor, fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 1. CHỌN HỒ SƠ NGƯỜI KHÁM
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '1. Chọn hồ sơ người khám',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary),
                      ),
                      TextButton.icon(
                        onPressed: _showAddProfileDialog,
                        icon: const Icon(Icons.add, size: 16, color: AppTheme.primaryColor),
                        label: const Text('Thêm hồ sơ', style: TextStyle(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (_profiles.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F9FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBAE6FD)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.person_pin_rounded, color: AppTheme.primaryColor, size: 22),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Đang dùng hồ sơ mặc định "Bản thân" từ thông tin tài khoản đăng ký của bạn.',
                              style: TextStyle(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._profiles.map((profile) {
                      final isSelected = _selectedProfile?.id == profile.id;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedProfile = profile),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFF0F9FF) : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
                              width: isSelected ? 1.5 : 1,
                            ),
                            boxShadow: isSelected ? AppTheme.elevatedShadow : AppTheme.cardShadow,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                                color: isSelected ? AppTheme.primaryColor : Colors.grey.shade400,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(profile.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary)),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryLight,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(profile.relationship, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Ngày sinh: ${profile.dob} • Giới tính: ${profile.gender}${profile.bhytCode != null ? " • BHYT: ${profile.bhytCode}" : ""}',
                                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                  const SizedBox(height: 18),

                  // 2. HÌNH THỨC KHÁM
                  const Text(
                    '2. Hình thức khám',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _examType = 'Dịch vụ'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _examType == 'Dịch vụ' ? AppTheme.primaryColor : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _examType == 'Dịch vụ' ? AppTheme.primaryColor : AppTheme.borderColor,
                              ),
                              boxShadow: _examType == 'Dịch vụ' ? AppTheme.elevatedShadow : AppTheme.cardShadow,
                            ),
                            child: Center(
                              child: Text(
                                'Khám Dịch vụ',
                                style: TextStyle(
                                  color: _examType == 'Dịch vụ' ? Colors.white : AppTheme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _examType = 'BHYT'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _examType == 'BHYT' ? AppTheme.primaryColor : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _examType == 'BHYT' ? AppTheme.primaryColor : AppTheme.borderColor,
                              ),
                              boxShadow: _examType == 'BHYT' ? AppTheme.elevatedShadow : AppTheme.cardShadow,
                            ),
                            child: Center(
                              child: Text(
                                'Khám BHYT',
                                style: TextStyle(
                                  color: _examType == 'BHYT' ? Colors.white : AppTheme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 3. TRIỆU CHỨNG BỆNH NHÂN
                  const Text(
                    '3. Triệu chứng hoặc lý do khám',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _symptomsController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Mô tả ngắn gọn cảm giác khó chịu, đau nhức để bác sĩ chuẩn bị trước...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
