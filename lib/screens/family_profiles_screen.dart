import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/patient_profile_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../state/auth_provider.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class FamilyProfilesScreen extends StatefulWidget {
  const FamilyProfilesScreen({super.key});

  @override
  State<FamilyProfilesScreen> createState() => _FamilyProfilesScreenState();
}

class _FamilyProfilesScreenState extends State<FamilyProfilesScreen> {
  final ApiService _apiService = ApiService();

  List<PatientProfileModel> _profiles = [];
  UserModel? _user;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final user = await _apiService.getMe();
      final profiles = await _apiService.getProfiles();
      setState(() {
        _user = user;
        _profiles = profiles;
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

  void _showProfileModal({PatientProfileModel? existingProfile}) {
    final isEditing = existingProfile != null;
    final nameCtrl = TextEditingController(text: existingProfile?.fullName ?? '');
    final dobCtrl = TextEditingController(text: existingProfile?.dob ?? '1995-01-01');
    final cccdCtrl = TextEditingController(text: existingProfile?.cccd ?? '');
    final bhytCtrl = TextEditingController(text: existingProfile?.bhytCode ?? '');
    final allergiesCtrl = TextEditingController(text: existingProfile?.allergies ?? '');
    final phoneCtrl = TextEditingController(text: existingProfile?.phone ?? '');
    final addressCtrl = TextEditingController(text: existingProfile?.address ?? '');
    String gender = existingProfile?.gender ?? 'Nam';
    String relationship = existingProfile?.relationship ?? 'Con';

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
                Text(
                  isEditing ? 'Cập Nhật Hồ Sơ Người Bệnh' : 'Thêm Thành Viên Mới',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Họ và tên *'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: dobCtrl,
                        decoration: const InputDecoration(labelText: 'Ngày sinh (YYYY-MM-DD)'),
                      ),
                    ),
                    const SizedBox(width: 10),
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
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text('Quan hệ: ', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: relationship,
                      items: const [
                        DropdownMenuItem(value: 'Bản thân', child: Text('Bản thân')),
                        DropdownMenuItem(value: 'Bố', child: Text('Bố')),
                        DropdownMenuItem(value: 'Mẹ', child: Text('Mẹ')),
                        DropdownMenuItem(value: 'Con', child: Text('Con')),
                        DropdownMenuItem(value: 'Vợ/Chồng', child: Text('Vợ/Chồng')),
                        DropdownMenuItem(value: 'Khác', child: Text('Khác')),
                      ],
                      onChanged: (val) => setModalState(() => relationship = val ?? 'Con'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: cccdCtrl,
                  decoration: const InputDecoration(labelText: 'Số CCCD / Định danh cá nhân'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: bhytCtrl,
                  decoration: const InputDecoration(labelText: 'Mã số thẻ BHYT (nếu có)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Số điện thoại liên hệ'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: allergiesCtrl,
                  decoration: const InputDecoration(labelText: 'Tiền sử dị ứng (thuốc, thức ăn)'),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) return;
                    try {
                      if (isEditing) {
                        await _apiService.updateProfile(
                          existingProfile.id,
                          fullName: nameCtrl.text.trim(),
                          dob: dobCtrl.text.trim(),
                          gender: gender,
                          relationship: relationship,
                          cccd: cccdCtrl.text.trim().isNotEmpty ? cccdCtrl.text.trim() : null,
                          bhytCode: bhytCtrl.text.trim().isNotEmpty ? bhytCtrl.text.trim() : null,
                          allergies: allergiesCtrl.text.trim().isNotEmpty ? allergiesCtrl.text.trim() : null,
                          phone: phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : null,
                          address: addressCtrl.text.trim().isNotEmpty ? addressCtrl.text.trim() : null,
                        );
                      } else {
                        await _apiService.createProfile(
                          fullName: nameCtrl.text.trim(),
                          dob: dobCtrl.text.trim(),
                          gender: gender,
                          relationship: relationship,
                          cccd: cccdCtrl.text.trim().isNotEmpty ? cccdCtrl.text.trim() : null,
                          bhytCode: bhytCtrl.text.trim().isNotEmpty ? bhytCtrl.text.trim() : null,
                          allergies: allergiesCtrl.text.trim().isNotEmpty ? allergiesCtrl.text.trim() : null,
                          phone: phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : null,
                          address: addressCtrl.text.trim().isNotEmpty ? addressCtrl.text.trim() : null,
                        );
                      }
                      Navigator.of(ctx).pop();
                      _fetchData();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppTheme.errorColor),
                      );
                    }
                  },
                  child: Text(isEditing ? 'Cập nhật hồ sơ' : 'Lưu hồ sơ mới'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleDeleteProfile(PatientProfileModel p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa hồ sơ người thân'),
        content: Text('Bạn có chắc chắn muốn xóa hồ sơ của ${p.fullName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _apiService.deleteProfile(p.id);
      _fetchData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Đăng xuất tài khoản'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng MEDBOOK?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Không')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Hồ Sơ Cá Nhân & Gia Đình',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
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
                      FilledButton(onPressed: _fetchData, child: const Text('Thử lại')),
                    ],
                  ),
                )
              : RefreshIndicator(
              onRefresh: _fetchData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // THẺ TÀI KHOẢN NGƯỜI DÙNG CHÍNH
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppTheme.elevatedShadow,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white,
                            backgroundImage: _user?.avatarUrl != null ? NetworkImage(_user!.avatarUrl!) : null,
                            child: _user?.avatarUrl == null
                                ? const Icon(Icons.person, size: 34, color: AppTheme.primaryColor)
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _user?.fullName ?? 'Người dùng',
                                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'SĐT: ${_user?.phone ?? ""}',
                                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                                ),
                                if (_user?.email != null)
                                  Text(
                                    'Email: ${_user!.email}',
                                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // DANH SÁCH HỒ SƠ THÀNH VIÊN GIA ĐÌNH
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Danh sách hồ sơ khám bệnh',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        TextButton.icon(
                          onPressed: () => _showProfileModal(),
                          icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                          label: const Text('Thêm hồ sơ'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    ..._profiles.map((p) {
                      final isOwner = p.relationship == 'Bản thân';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
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
                                    Icon(
                                      isOwner ? Icons.badge_outlined : Icons.family_restroom,
                                      color: AppTheme.primaryColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(p.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    p.relationship,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 18, color: Color(0xFFF1F5F9)),
                            _buildInfoLine('Ngày sinh:', '${p.dob} (${p.gender})'),
                            if (p.cccd != null && p.cccd!.isNotEmpty)
                              _buildInfoLine('Số CCCD:', p.cccd!),
                            if (p.bhytCode != null && p.bhytCode!.isNotEmpty)
                              _buildInfoLine('Mã thẻ BHYT:', p.bhytCode!),
                            if (p.allergies != null && p.allergies!.isNotEmpty)
                              _buildInfoLine('Tiền sử dị ứng:', p.allergies!, isAlert: true),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (!isOwner) ...[
                                  TextButton.icon(
                                    onPressed: () => _handleDeleteProfile(p),
                                    icon: const Icon(Icons.delete_outline, size: 16, color: AppTheme.errorColor),
                                    label: const Text('Xóa', style: TextStyle(color: AppTheme.errorColor, fontSize: 12)),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                OutlinedButton.icon(
                                  onPressed: () => _showProfileModal(existingProfile: p),
                                  icon: const Icon(Icons.edit_outlined, size: 16),
                                  label: const Text('Chỉnh sửa', style: TextStyle(fontSize: 12)),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 24),

                    // CÀI ĐẶT & ĐĂNG XUẤT
                    const Text('Hệ thống', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 10),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.support_agent_outlined, color: AppTheme.primaryColor),
                            title: const Text('Tổng đài hỗ trợ CSKH MedBook'),
                            subtitle: const Text('1900 6868 (24/7)'),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                            onTap: () {},
                          ),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          const ListTile(
                            leading: Icon(Icons.info_outline, color: AppTheme.accentColor),
                            title: Text('Phiên bản ứng dụng'),
                            trailing: Text('v2.0.0 (MEDBOOK)', style: TextStyle(color: Colors.grey)),
                          ),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          ListTile(
                            leading: const Icon(Icons.logout, color: AppTheme.errorColor),
                            title: const Text('Đăng xuất tài khoản', style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.bold)),
                            onTap: _handleLogout,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoLine(String label, String value, {bool isAlert = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isAlert ? FontWeight.bold : FontWeight.w500,
                color: isAlert ? AppTheme.errorColor : const Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
