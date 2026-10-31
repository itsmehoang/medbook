import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/doctor_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'booking_confirmation_screen.dart';

class DoctorDetailsScreen extends StatefulWidget {
  final int doctorId;
  final DoctorModel? initialDoctor;

  const DoctorDetailsScreen({
    super.key,
    required this.doctorId,
    this.initialDoctor,
  });

  @override
  State<DoctorDetailsScreen> createState() => _DoctorDetailsScreenState();
}

class _DoctorDetailsScreenState extends State<DoctorDetailsScreen> {
  final ApiService _apiService = ApiService();
  DoctorModel? _doctor;
  bool _isLoading = true;
  String? _errorMessage;

  String? _selectedDate;
  ScheduleSlot? _selectedSlot;
  bool _showAllBio = false;

  @override
  void initState() {
    super.initState();
    _doctor = widget.initialDoctor;
    _fetchDoctorDetails();
  }

  Future<void> _fetchDoctorDetails() async {
    setState(() => _isLoading = true);
    try {
      final doc = await _apiService.getDoctorById(widget.doctorId);
      setState(() {
        _doctor = doc;
        if (_doctor?.schedules != null && _doctor!.schedules!.isNotEmpty) {
          _selectedDate = _doctor!.schedules!.keys.first;
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,###', 'vi_VN');

    if (_isLoading && _doctor == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Thông tin bác sĩ'),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );
    }

    if (_doctor == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_off_outlined, size: 48, color: AppTheme.textMuted),
              const SizedBox(height: 12),
              Text(_errorMessage ?? 'Không tìm thấy thông tin bác sĩ.', style: const TextStyle(color: AppTheme.textSecondary)),
            ],
          ),
        ),
      );
    }

    final doctor = _doctor!;
    final availableDates = doctor.schedules?.keys.toList() ?? [];
    final currentSlots = (_selectedDate != null && doctor.schedules != null)
        ? (doctor.schedules![_selectedDate] ?? [])
        : <ScheduleSlot>[];

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Hồ Sơ Bác Sĩ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border_rounded),
            onPressed: () {},
          )
        ],
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
                  const Text('Giá khám', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  Text(
                    '${currencyFormat.format(doctor.basePrice)} đ',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: (_selectedDate != null && _selectedSlot != null)
                      ? () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => BookingConfirmationScreen(
                                doctor: doctor,
                                workDate: _selectedDate!,
                                selectedSlot: _selectedSlot!,
                              ),
                            ),
                          );
                        }
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('TIẾP TỤC ĐẶT LỊCH', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thẻ hồ sơ bác sĩ chính (Card trắng bo góc 16)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppTheme.primaryLight,
                        backgroundImage: doctor.avatarUrl != null ? NetworkImage(doctor.avatarUrl!) : null,
                        child: doctor.avatarUrl == null ? const Icon(Icons.person, size: 36, color: AppTheme.primaryColor) : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                doctor.degree,
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              doctor.displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              doctor.specialtyName ?? 'Chuyên khoa',
                              style: const TextStyle(
                                color: AppTheme.accentColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.room_outlined, size: 14, color: AppTheme.textSecondary),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '${doctor.roomNumber} - ${doctor.hospitalName}',
                                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // 4 Thẻ thống kê (Bệnh nhân, Kinh nghiệm, Đánh giá, Lượt khám)
                  Row(
                    children: [
                      _buildStatBadge(Icons.people_outline, '${doctor.patientCount}+', 'Bệnh nhân'),
                      const SizedBox(width: 8),
                      _buildStatBadge(Icons.workspace_premium_outlined, '${doctor.experienceYears} năm', 'Kinh nghiệm'),
                      const SizedBox(width: 8),
                      _buildStatBadge(Icons.star_rounded, '${doctor.rating}', 'Đánh giá'),
                      const SizedBox(width: 8),
                      _buildStatBadge(Icons.rate_review_outlined, '${doctor.reviewCount}', 'Lượt khám'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Giới thiệu chuyên môn
            if (doctor.bio != null && doctor.bio!.isNotEmpty)
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
                    const Text(
                      'Giới thiệu chuyên môn',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      doctor.bio!,
                      maxLines: _showAllBio ? 100 : 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
                    ),
                    if (doctor.bio!.length > 130)
                      Align(
                        alignment: Alignment.centerRight,
                        child: InkWell(
                          onTap: () => setState(() => _showAllBio = !_showAllBio),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              _showAllBio ? 'Thu gọn' : 'Xem thêm',
                              style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // 1. CHỌN NGÀY KHÁM BỆNH
            const Text(
              '1. Chọn ngày khám',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 10),

            if (availableDates.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: const Center(
                  child: Text(
                    'Hiện chưa có lịch khám trực tuyến cho bác sĩ này.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                ),
              )
            else
              SizedBox(
                height: 52,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: availableDates.length,
                  separatorBuilder: (ctx, i) => const SizedBox(width: 10),
                  itemBuilder: (ctx, i) {
                    final date = availableDates[i];
                    final isSelected = date == _selectedDate;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDate = date;
                          _selectedSlot = null;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primaryColor : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: isSelected ? AppTheme.elevatedShadow : AppTheme.cardShadow,
                          border: Border.all(
                            color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            date,
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 22),

            // 2. CHỌN KHUNG GIỜ KHÁM (GRID 3 CỘT)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '2. Chọn khung giờ khám',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary),
                ),
                if (_selectedSlot != null)
                  Text(
                    'Đã chọn: ${_selectedSlot!.timeSlot}',
                    style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            if (currentSlots.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text('Không có khung giờ nào trong ngày này.', style: TextStyle(color: Colors.grey.shade500)),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2.3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: currentSlots.length,
                itemBuilder: (ctx, i) {
                  final slot = currentSlots[i];
                  final isSelected = _selectedSlot?.id == slot.id;
                  final isAvailable = slot.isAvailable;

                  return GestureDetector(
                    onTap: isAvailable
                        ? () {
                            setState(() => _selectedSlot = slot);
                          }
                        : null,
                    child: Container(
                      decoration: BoxDecoration(
                        color: !isAvailable
                            ? const Color(0xFFF1F5F9)
                            : (isSelected ? AppTheme.primaryColor : Colors.white),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: !isAvailable
                              ? AppTheme.borderColor
                              : (isSelected ? AppTheme.primaryColor : const Color(0xFFBAE6FD)),
                          width: isSelected ? 1.5 : 1,
                        ),
                        boxShadow: isSelected ? AppTheme.elevatedShadow : AppTheme.cardShadow,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            slot.timeSlot,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: !isAvailable
                                  ? AppTheme.textMuted
                                  : (isSelected ? Colors.white : AppTheme.textPrimary),
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            !isAvailable ? 'Đầy' : 'Còn ${slot.availableSlots} chỗ',
                            style: TextStyle(
                              fontSize: 9,
                              color: !isAvailable
                                  ? AppTheme.errorColor
                                  : (isSelected ? Colors.white70 : AppTheme.accentColor),
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBadge(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: AppTheme.primaryColor),
            const SizedBox(height: 3),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textPrimary)),
            Text(label, style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary), maxLines: 1),
          ],
        ),
      ),
    );
  }
}
