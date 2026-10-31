import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/dashboard_data_model.dart';
import '../models/appointment_model.dart';
import '../models/specialty_model.dart';
import '../models/doctor_model.dart';
import '../models/medication_reminder_model.dart';
import '../models/patient_profile_model.dart';
import '../services/api_service.dart';
import '../state/auth_provider.dart';
import '../theme/app_theme.dart';
import 'categories_screen.dart';
import 'doctor_list_screen.dart';
import 'doctor_details_screen.dart';
import 'appointment_ticket_screen.dart';
import 'family_profiles_screen.dart';

class HomeScreen extends StatefulWidget {
  final bool isEmbedded;

  const HomeScreen({
    super.key,
    this.isEmbedded = false,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  DashboardDataModel? _dashboardData;
  List<PatientProfileModel> _profiles = [];
  PatientProfileModel? _activeProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getDashboard();
      final profiles = await _apiService.getProfiles();
      if (mounted) {
        setState(() {
          _dashboardData = data;
          _profiles = profiles;
          if (_profiles.isNotEmpty && _activeProfile == null) {
            _activeProfile = _profiles.first;
          }
        });
      }
    } catch (e, stack) {
      debugPrint('[HomeScreen Error] Lỗi tải dữ liệu Dashboard: $e');
      debugPrint(stack.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleToggleMedication(MedicationReminderModel med) async {
    final originalState = med.isTakenToday;
    setState(() {
      med.isTakenToday = !originalState;
    });

    try {
      await _apiService.toggleMedication(med.id);
      _fetchDashboardData();
    } catch (e) {
      if (mounted) {
        setState(() {
          med.isTakenToday = originalState;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể cập nhật trạng thái uống thuốc: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _showProfileSwitchModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
              'Chọn hồ sơ người khám',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 12),
            ..._profiles.map((p) {
              final isSelected = _activeProfile?.id == p.id;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: isSelected ? AppTheme.primaryLight : const Color(0xFFF1F5F9),
                  child: Icon(
                    p.relationship == 'Bản thân' ? Icons.person : Icons.family_restroom,
                    color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                  ),
                ),
                title: Text(
                  p.fullName,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                  ),
                ),
                subtitle: Text('${p.relationship} • Ngày sinh: ${p.dob}', style: const TextStyle(fontSize: 12)),
                trailing: isSelected ? const Icon(Icons.check_circle, color: AppTheme.primaryColor) : null,
                onTap: () {
                  setState(() => _activeProfile = p);
                  Navigator.pop(ctx);
                },
              );
            }),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: AppTheme.primaryLight,
                child: Icon(Icons.add, color: AppTheme.primaryColor),
              ),
              title: const Text('Quản lý hồ sơ gia đình', style: TextStyle(fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FamilyProfilesScreen()),
                ).then((_) => _fetchDashboardData());
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickQrModal(AppointmentModel appointment) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            const Text(
              'MÃ QR CHECK-IN TIẾP ĐÓN',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'Mã phiếu: ${appointment.bookingCode} • STT: ${appointment.queueNumber}',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.cardShadow,
              ),
              child: QrImageView(
                data: appointment.qrData,
                version: QrVersions.auto,
                size: 190.0,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Xuất trình mã này tại cây tiếp đón tự động hoặc phòng khám ${appointment.roomNumber ?? ""}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Đóng'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = _dashboardData?.user ?? authProvider.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : RefreshIndicator(
              color: AppTheme.primaryColor,
              onRefresh: _fetchDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. HEADER XANH GRADIENT BO TRÒN HIỆN ĐẠI
                    _buildModernHeader(context, user),

                    const SizedBox(height: 16),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 2. THẺ PHIẾU KHÁM SẮP DIỄN RA (TICKET VIP STYLE)
                          _buildUpcomingAppointmentCard(context, _dashboardData?.upcomingAppointment),

                          const SizedBox(height: 24),

                          // 3. NHẮC THUỐC HÔM NAY (CHECKLIST HOÀN THÀNH XANH LÁ)
                          _buildMedicationSection(context, _dashboardData?.medications),

                          const SizedBox(height: 24),

                          // 4. CHUYÊN KHOA BỆNH VIỆN (PASTEL ICONS)
                          _buildSpecialtiesSection(context, _dashboardData?.specialties ?? []),

                          const SizedBox(height: 24),

                          // 5. BÁC SĨ TIÊU BIỂU
                          _buildTopDoctorsSection(context, _dashboardData?.topDoctors ?? []),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // WIDGET 1: HEADER GRADIENT HIỆN ĐẠI
  Widget _buildModernHeader(BuildContext context, dynamic user) {
    final displayName = _activeProfile?.fullName ?? user?.fullName ?? 'Bệnh nhân';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thanh thông tin người dùng & Chọn hồ sơ
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white,
                    backgroundImage: user?.avatarUrl != null ? NetworkImage(user!.avatarUrl!) : null,
                    child: user?.avatarUrl == null
                        ? const Icon(Icons.person, color: AppTheme.primaryColor, size: 24)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Xin chào 👋',
                              style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: _showProfileSwitchModal,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _activeProfile?.relationship ?? 'Bản thân',
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                    const Icon(Icons.arrow_drop_down, color: Colors.white, size: 14),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const FamilyProfilesScreen()),
                      );
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Thanh tìm kiếm nổi (Search Bar) bo góc 16
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const DoctorListScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, color: AppTheme.primaryColor, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        'Tìm bác sĩ, chuyên khoa, phòng khám...',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.tune_rounded, color: AppTheme.primaryColor, size: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // WIDGET 2: THẺ PHIẾU KHÁM SẮP DIỄN RA (CARD NGÂN HÀNG / VÉ VIP)
  Widget _buildUpcomingAppointmentCard(BuildContext context, AppointmentModel? appointment) {
    if (appointment == null) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.calendar_month_rounded, color: AppTheme.primaryColor, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Bạn chưa có lịch hẹn khám', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary)),
                  const SizedBox(height: 2),
                  Text('Đặt lịch ngay để được cấp số khám tự động', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CategoriesScreen()),
                );
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Đặt khám', style: TextStyle(fontSize: 12)),
            )
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AppointmentTicketScreen(appointment: appointment),
          ),
        ).then((_) => _fetchDashboardData());
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0284C7), Color(0xFF0D9488)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: AppTheme.elevatedShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hàng trên: Tag trạng thái & Nút mở nhanh QR
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_available_rounded, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'LỊCH HẸN SẮP TỚI',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => _showQuickQrModal(appointment),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.qr_code_2_rounded, size: 16, color: AppTheme.primaryColor),
                          SizedBox(width: 4),
                          Text('Mã QR', style: TextStyle(color: AppTheme.primaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Bác sĩ, chuyên khoa & STT to rõ
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.white,
                    backgroundImage: appointment.doctorAvatar != null ? NetworkImage(appointment.doctorAvatar!) : null,
                    child: appointment.doctorAvatar == null ? const Icon(Icons.person, color: AppTheme.primaryColor) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.doctorFullName,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${appointment.specialtyName ?? ""} • ${appointment.roomNumber ?? "Phòng khám"}',
                          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Khối số thứ tự to rõ
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'SỐ THỨ TỰ',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                        ),
                        Text(
                          '${appointment.queueNumber}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const Divider(color: Colors.white24, height: 24),

              // Hàng dưới: Giờ khám, ngày & mã phiếu
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, color: Colors.white, size: 15),
                  const SizedBox(width: 6),
                  Text(
                    '${appointment.timeSlot} • ${appointment.workDate}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                  const Spacer(),
                  Text(
                    appointment.bookingCode,
                    style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11, letterSpacing: 0.5),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // WIDGET 3: NHẮC THUỐC HÔM NAY (CHECKLIST XANH LÁ)
  Widget _buildMedicationSection(BuildContext context, MedicationSummary? medications) {
    final total = medications?.total ?? 0;
    final taken = medications?.taken ?? 0;
    final list = medications?.list ?? [];

    return Container(
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.accentLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.medication_rounded, color: AppTheme.accentColor, size: 18),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Lịch uống thuốc hôm nay',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: taken == total && total > 0 ? AppTheme.successLight : AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$taken/$total cữ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: taken == total && total > 0 ? AppTheme.successColor : AppTheme.primaryColor,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total > 0 ? (taken / total) : 0,
              backgroundColor: const Color(0xFFF1F5F9),
              color: AppTheme.successColor,
              minHeight: 6,
            ),
          ),

          const SizedBox(height: 12),

          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Không có đơn thuốc cần uống hôm nay.',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            )
          else
            ...list.map((med) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: InkWell(
                  onTap: () => _handleToggleMedication(med),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: med.isTakenToday ? const Color(0xFFF8FAFC) : const Color(0xFFF1F5F9).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: med.isTakenToday ? AppTheme.successColor.withOpacity(0.3) : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          med.isTakenToday ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                          color: med.isTakenToday ? AppTheme.successColor : Colors.grey.shade400,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                med.medicineName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  decoration: med.isTakenToday ? TextDecoration.lineThrough : null,
                                  color: med.isTakenToday ? AppTheme.textMuted : AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                '${med.timeOfDay} (${med.reminderTime.substring(0, 5)}) • ${med.dosage}',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: med.isTakenToday ? AppTheme.successLight : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            med.isTakenToday ? 'Đã uống' : 'Chưa uống',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: med.isTakenToday ? AppTheme.successColor : const Color(0xFFB45309),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  // WIDGET 4: CHUYÊN KHOA BỆNH VIỆN (ICON PASTEL)
  Widget _buildSpecialtiesSection(BuildContext context, List<SpecialtyModel> specialties) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Chuyên khoa bệnh viện',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CategoriesScreen()),
                );
              },
              child: const Text('Xem tất cả', style: TextStyle(fontSize: 13, color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 98,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: specialties.length,
            separatorBuilder: (ctx, i) => const SizedBox(width: 12),
            itemBuilder: (ctx, i) {
              final item = specialties[i];
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => DoctorListScreen(specialty: item)),
                  );
                },
                child: SizedBox(
                  width: 76,
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(item.iconData, color: AppTheme.primaryColor, size: 28),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // WIDGET 5: BÁC SĨ TIÊU BIỂU
  Widget _buildTopDoctorsSection(BuildContext context, List<DoctorModel> topDoctors) {
    final currencyFormat = NumberFormat('#,###', 'vi_VN');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Bác sĩ tiêu biểu',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DoctorListScreen()),
                );
              },
              child: const Text('Xem tất cả', style: TextStyle(fontSize: 13, color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: topDoctors.length,
          separatorBuilder: (ctx, i) => const SizedBox(height: 12),
          itemBuilder: (ctx, i) {
            final doctor = topDoctors[i];
            return GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DoctorDetailsScreen(
                      doctorId: doctor.id,
                      initialDoctor: doctor,
                    ),
                  ),
                ).then((_) => _fetchDashboardData());
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppTheme.primaryLight,
                      backgroundImage: doctor.avatarUrl != null ? NetworkImage(doctor.avatarUrl!) : null,
                      child: doctor.avatarUrl == null ? const Icon(Icons.person, color: AppTheme.primaryColor) : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doctor.displayName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            doctor.specialtyName ?? 'Chuyên khoa',
                            style: const TextStyle(color: AppTheme.primaryColor, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                              const SizedBox(width: 2),
                              Text('${doctor.rating} (${doctor.reviewCount})', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                              const SizedBox(width: 8),
                              const Text('•', style: TextStyle(color: Colors.grey)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  doctor.roomNumber,
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${currencyFormat.format(doctor.basePrice)} đ',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        FilledButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => DoctorDetailsScreen(
                                  doctorId: doctor.id,
                                  initialDoctor: doctor,
                                ),
                              ),
                            ).then((_) => _fetchDashboardData());
                          },
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Đặt khám', style: TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
