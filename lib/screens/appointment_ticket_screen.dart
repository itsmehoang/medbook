import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/appointment_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class DashedLinePainter extends CustomPainter {
  final Color color;
  final double dashWidth;
  final double dashSpace;

  const DashedLinePainter({
    this.color = const Color(0xFFCBD5E1),
    this.dashWidth = 6.0,
    this.dashSpace = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double startX = 0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AppointmentTicketScreen extends StatefulWidget {
  final AppointmentModel appointment;

  const AppointmentTicketScreen({
    super.key,
    required this.appointment,
  });

  @override
  State<AppointmentTicketScreen> createState() => _AppointmentTicketScreenState();
}

class _AppointmentTicketScreenState extends State<AppointmentTicketScreen> {
  late AppointmentModel _appointment;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _appointment = widget.appointment;
  }

  Future<void> _handleCancel() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.errorColor),
            SizedBox(width: 8),
            Text('Hủy phiếu hẹn khám'),
          ],
        ),
        content: const Text(
          'Bạn có chắc chắn muốn hủy phiếu khám này không? Khung giờ sẽ được giải phóng cho bệnh nhân khác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Giữ lại'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xác nhận hủy'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await ApiService().cancelAppointment(_appointment.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã hủy lịch khám thành công.'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,###', 'vi_VN');
    final isCancelled = _appointment.status == 'cancelled';
    final isCompleted = _appointment.status == 'completed';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Phiếu Khám Điện Tử',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
        actions: [
          if (!isCancelled && !isCompleted)
            IconButton(
              icon: const Icon(Icons.cancel_outlined, color: AppTheme.errorColor),
              tooltip: 'Hủy phiếu khám',
              onPressed: _handleCancel,
            ),
          IconButton(
            icon: const Icon(Icons.home_outlined),
            tooltip: 'Trang chủ',
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Column(
                  children: [
                    // THẺ PHIẾU KHÁM DẠNG VÉ (TICKET STYLE)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20.0),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // PHẦN HEADER PHIẾU KHÁM
                          Container(
                            padding: const EdgeInsets.all(20.0),
                            decoration: BoxDecoration(
                              gradient: isCancelled
                                  ? const LinearGradient(
                                      colors: [Color(0xFF64748B), Color(0xFF475569)],
                                    )
                                  : isCompleted
                                      ? const LinearGradient(
                                          colors: [AppTheme.accentColor, Color(0xFF0F766E)],
                                        )
                                      : AppTheme.primaryGradient,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 20),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              'BV ĐA KHOA MEDBOOK',
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.95),
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1.1,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isCancelled
                                            ? const Color(0xFFEF4444)
                                            : (isCompleted ? AppTheme.accentColor : Colors.white),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        isCancelled
                                            ? 'ĐÃ HỦY'
                                            : (isCompleted ? 'ĐÃ KHÁM' : 'ĐÃ XÁC NHẬN'),
                                        style: TextStyle(
                                          color: (isCancelled || isCompleted) ? Colors.white : AppTheme.primaryColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'MÃ PHIẾU KHÁM',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 11,
                                    letterSpacing: 1,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _appointment.bookingCode,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // VẾT KHOÉT BÁN NGUYỆT 2 BÊN + ĐƯỜNG NÉT ĐỨT (TICKET NOTCHES)
                          Container(
                            color: Colors.white,
                            height: 24,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Positioned(
                                  left: 18,
                                  right: 18,
                                  child: CustomPaint(
                                    size: const Size(double.infinity, 2),
                                    painter: DashedLinePainter(color: Colors.grey.shade300),
                                  ),
                                ),
                                Positioned(
                                  left: -12,
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.backgroundColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: -12,
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.backgroundColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // PHẦN THÂN VÉ: SỐ THỨ TỰ & MÃ QR
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 20.0),
                            child: Column(
                              children: [
                                // KHỐI SỐ THỨ TỰ NỔI BẬT (36pt ĐẬM)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryLight,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'SỐ THỨ TỰ DỰ KIẾN',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryColor,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${_appointment.queueNumber}',
                                        style: const TextStyle(
                                          fontSize: 36,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryColor,
                                          height: 1.1,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Tại ${_appointment.roomNumber ?? "Phòng khám"}${_appointment.roomLocation != null ? " - ${_appointment.roomLocation}" : ""}',
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // MÃ QR ĐIỆN TỬ
                                if (!isCancelled && _appointment.qrData.isNotEmpty) ...[
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.grey.shade200),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.04),
                                          blurRadius: 10,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: QrImageView(
                                      data: _appointment.qrData,
                                      version: QrVersions.auto,
                                      size: 180.0,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Quét mã tại cây tiếp đón tự động để in phiếu số thứ tự',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ],

                                // THÔNG TIN CHI TIẾT
                                _buildTicketRow('Người khám:', _appointment.patientName ?? 'Bệnh nhân', isBold: true),
                                if (_appointment.bhytCode != null && _appointment.bhytCode!.isNotEmpty)
                                  _buildTicketRow('Mã thẻ BHYT:', _appointment.bhytCode!),
                                _buildTicketRow('Hình thức:', 'Khám ${_appointment.examType}'),
                                _buildTicketRow('Bác sĩ:', _appointment.doctorFullName),
                                _buildTicketRow('Chuyên khoa:', _appointment.specialtyName ?? 'Chuyên khoa'),
                                _buildTicketRow('Ngày khám:', _appointment.workDate ?? ''),
                                _buildTicketRow('Khung giờ:', _appointment.timeSlot ?? '', isHighlight: true),
                                if (_appointment.basePrice != null)
                                  _buildTicketRow(
                                    'Phí khám dự kiến:',
                                    '${currencyFormat.format(_appointment.basePrice)} đ',
                                    isHighlight: true,
                                  ),
                                if (_appointment.symptoms != null && _appointment.symptoms!.isNotEmpty)
                                  _buildTicketRow('Triệu chứng:', _appointment.symptoms!),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // KHỐI LƯU Ý Y TẾ TRƯỚC KHI ĐI KHÁM (HỘP THÔNG BÁO XANH NHẠT TRANG NHÃ)
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.health_and_safety_outlined, color: AppTheme.successColor, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'LƯU Ý QUAN TRỌNG KHI ĐI KHÁM',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Color(0xFF166534),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _buildNoticeBullet('Nhịn ăn sáng: Vui lòng nhịn ăn ít nhất 6-8 tiếng nếu quý khách có lịch chỉ định xét nghiệm máu hoặc nội soi tiêu hóa.'),
                          _buildNoticeBullet('Mang theo giấy tờ: Xuất trình CCCD gắn chip và thẻ BHYT gốc (nếu chọn khám diện BHYT).'),
                          _buildNoticeBullet('Có mặt đúng giờ: Đề nghị có mặt trước giờ hẹn 15 phút tại sảnh tiếp đón để làm thủ tục check-in.'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // NÚT HỦY HẸN
                    if (!isCancelled && !isCompleted)
                      OutlinedButton.icon(
                        onPressed: _handleCancel,
                        icon: const Icon(Icons.cancel_outlined, color: AppTheme.errorColor),
                        label: const Text(
                          'Hủy lịch hẹn khám này',
                          style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.errorColor),
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTicketRow(String label, String value, {bool isBold = false, bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: (isBold || isHighlight) ? FontWeight.bold : FontWeight.w500,
                color: isHighlight ? AppTheme.primaryColor : const Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF166534))),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade800, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
