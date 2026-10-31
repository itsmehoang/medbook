import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/doctor_model.dart';
import '../models/specialty_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'doctor_details_screen.dart';

class DoctorListScreen extends StatefulWidget {
  final SpecialtyModel? specialty;

  const DoctorListScreen({
    super.key,
    this.specialty,
  });

  @override
  State<DoctorListScreen> createState() => _DoctorListScreenState();
}

class _DoctorListScreenState extends State<DoctorListScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<DoctorModel> _doctors = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchDoctors({String? search}) async {
    setState(() => _isLoading = true);
    try {
      final list = await _apiService.getDoctors(
        specialtyId: widget.specialty?.id,
        search: search,
      );
      setState(() {
        _doctors = list;
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

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,###', 'vi_VN');

    final title = widget.specialty != null
        ? 'Khoa ${widget.specialty!.name}'
        : 'Danh Sách Bác Sĩ';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.cardShadow,
              ),
              child: TextField(
                controller: _searchController,
                onSubmitted: (val) => _fetchDoctors(search: val.trim()),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm bác sĩ theo tên...',
                  prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, color: Color(0xFF94A3B8)),
                    onPressed: () {
                      _searchController.clear();
                      _fetchDoctors();
                    },
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),

          // Danh sách bác sĩ
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!))
                    : _doctors.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.person_search_outlined, size: 54, color: Color(0xFFCBD5E1)),
                                SizedBox(height: 12),
                                Text('Không tìm thấy bác sĩ nào phù hợp.', style: TextStyle(color: Color(0xFF64748B))),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16.0),
                            itemCount: _doctors.length,
                            separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                            itemBuilder: (ctx, i) {
                              final doctor = _doctors[i];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => DoctorDetailsScreen(
                                        doctorId: doctor.id,
                                        initialDoctor: doctor,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: AppTheme.cardShadow,
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 36,
                                        backgroundColor: AppTheme.primaryLight,
                                        backgroundImage: doctor.avatarUrl != null
                                            ? NetworkImage(doctor.avatarUrl!)
                                            : null,
                                        child: doctor.avatarUrl == null
                                            ? const Icon(Icons.person, size: 32, color: AppTheme.primaryColor)
                                            : null,
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              doctor.displayName,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              doctor.specialtyName ?? 'Chuyên khoa',
                                              style: const TextStyle(
                                                color: AppTheme.primaryColor,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
                                                const SizedBox(width: 3),
                                                Text(
                                                  '${doctor.rating}',
                                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                                ),
                                                const SizedBox(width: 6),
                                                const Text('•', style: TextStyle(color: Color(0xFFCBD5E1))),
                                                const SizedBox(width: 6),
                                                Text(
                                                  '${doctor.experienceYears} năm KN',
                                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    doctor.roomNumber,
                                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Text(
                                                  '${currencyFormat.format(doctor.basePrice)} đ',
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppTheme.primaryColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
