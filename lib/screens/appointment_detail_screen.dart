import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/appointment_model.dart';
import '../services/api_service.dart';

class AppointmentDetailScreen extends StatefulWidget {
  final AppointmentModel appointment;

  const AppointmentDetailScreen({
    super.key,
    required this.appointment,
  });

  @override
  State<AppointmentDetailScreen> createState() => _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
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
        title: const Text('Hủy lịch khám bệnh'),
        content: const Text('Bạn có chắc chắn muốn hủy lịch hẹn khám này không? Khung giờ sẽ được giải phóng cho bệnh nhân khác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Không'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
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
          const SnackBar(content: Text('Đã hủy lịch khám thành công.')),
        );
        Navigator.of(context).pop(true); // Trả về true để màn hình trước reload
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final isConfirmed = _appointment.status == 'confirmed';
    final isCancelled = _appointment.status == 'cancelled';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Phiếu Khám Điện Tử', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Thẻ Phiếu khám chính với viền & QR
                  Container(
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        // Header phiếu
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('MÃ PHIẾU KHÁM', style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                                Text(_appointment.bookingCode, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.secondary)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isCancelled
                                    ? Colors.red.shade50
                                    : (isConfirmed ? Colors.green.shade50 : Colors.orange.shade50),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isCancelled ? 'Đã hủy' : (isConfirmed ? 'Đã xác nhận' : 'Chờ khám'),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isCancelled ? Colors.red : (isConfirmed ? Colors.green : Colors.orange),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const Divider(height: 24),

                        // Số thứ tự khám STT lớn
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [colorScheme.primary.withOpacity(0.2), colorScheme.tertiary.withOpacity(0.2)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.confirmation_number_outlined, color: Colors.black87),
                              const SizedBox(width: 8),
                              Text(
                                'SỐ THỨ TỰ KHÁM: ',
                                style: textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${_appointment.queueNumber}',
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorScheme.secondary),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Mã QR xuất trình tại quầy
                        if (!isCancelled && _appointment.qrData.isNotEmpty) ...[
                          Center(
                            child: QrImageView(
                              data: _appointment.qrData,
                              version: QrVersions.auto,
                              size: 170.0,
                              backgroundColor: Colors.white,
                              errorStateBuilder: (cxt, err) {
                                return const Text('Không thể hiển thị mã QR');
                              },
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Quét mã QR tại cây tiếp đón tự động hoặc quầy thu ngân',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                          ),
                          const Divider(height: 28),
                        ],

                        // Thông tin chi tiết
                        _buildInfoRow('Người khám bệnh', _appointment.patientName ?? 'Bệnh nhân', isBold: true),
                        _buildInfoRow('Hình thức khám', _appointment.examType),
                        _buildInfoRow('Bác sĩ phụ trách', _appointment.doctorFullName),
                        _buildInfoRow('Chuyên khoa', _appointment.specialtyName ?? 'Chuyên khoa'),
                        _buildInfoRow('Phòng khám', _appointment.roomNumber ?? (_appointment.roomLocation ?? 'Tầng 2')),
                        _buildInfoRow('Ngày khám', _appointment.workDate ?? ''),
                        _buildInfoRow('Khung giờ', _appointment.timeSlot ?? ''),
                        if (_appointment.symptoms != null && _appointment.symptoms!.isNotEmpty)
                          _buildInfoRow('Triệu chứng', _appointment.symptoms!),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Nút Hủy lịch nếu chưa bị hủy
                  if (!isCancelled)
                    OutlinedButton.icon(
                      onPressed: _handleCancel,
                      icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                      label: const Text('Hủy lịch hẹn khám này', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
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
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
