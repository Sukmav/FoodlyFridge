// screens/riwayat_page.dart
import 'package:flutter/material.dart';
import '../helpers/riwayat_service.dart';
import '../theme/app_colors.dart';
import '../theme/text_styles.dart';

class RiwayatPage extends StatefulWidget {
  final String userId;
  final String userName;

  const RiwayatPage({super.key, required this.userId, required this.userName});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  final SimpleRiwayatService _service = SimpleRiwayatService();
  final List<String> _activityTypes = [
    'Semua',
    'stok_keluar',
    'stok_masuk',
    'waste_food',
    'menu',
    'bahan_baku',
    'staff',
    'vendor',
  ];

  final Map<String, String> _typeLabels = {
    'Semua': 'Semua Aktivitas',
    'stok_keluar': 'Stok Keluar',
    'stok_masuk': 'Stok Masuk',
    'waste_food': 'Sampah Bahan Baku',
    'menu': 'Menu',
    'bahan_baku': 'Bahan Baku',
    'staff': 'Staff',
    'vendor': 'Vendor',
  };

  List<Map<String, dynamic>> _activities = [];
  List<Map<String, dynamic>> _filteredActivities = [];
  String _selectedType = 'Semua';
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final activities = await _service.getAllUserActivities(widget.userId);

      if (mounted) {
        setState(() {
          _activities = activities;
          _filteredActivities = activities;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _filterByType(String type) {
    setState(() {
      _selectedType = type;
      if (type == 'Semua') {
        _filteredActivities = _activities;
      } else {
        _filteredActivities = _activities
            .where((activity) => activity['type'] == type)
            .toList();
      }
    });
  }

  void _searchActivities(String query) {
    if (query.isEmpty) {
      _filterByType(_selectedType);
      return;
    }

    final lowercaseQuery = query.toLowerCase();
    setState(() {
      _filteredActivities = _activities.where((activity) {
        final title = activity['title']?.toString().toLowerCase() ?? '';
        final desc = activity['description']?.toString().toLowerCase() ?? '';
        final userName = activity['user_name']?.toString().toLowerCase() ?? '';
        return title.contains(lowercaseQuery) ||
            desc.contains(lowercaseQuery) ||
            userName.contains(lowercaseQuery);
      }).toList();
    });
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    Color color;
    try {
      color = Color(
        int.parse(activity['color']?.replaceAll('#', '0xff') ?? '0xff667eea'),
      );
    } catch (e) {
      color = const Color(0xff667eea);
    }
    IconData icon = _getIconData(activity['icon'] ?? 'history');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Activity Icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.8), color.withOpacity(0.4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),

            // Activity Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + small badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          activity['title']?.toString() ?? 'Aktivitas',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: color.withOpacity(0.3)),
                        ),
                        child: Text(
                          'Ditambahkan',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Description
                  Text(
                    activity['description']?.toString() ?? '',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // Metadata and Time
                  Row(
                    children: [
                      // Left flexible area contains user and time (so badge won't cause overflow)
                      Expanded(
                        child: Row(
                          children: [
                            // User
                            if (activity['user_name'] != null) ...[
                              Icon(
                                Icons.person_outline,
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                fit: FlexFit.loose,
                                child: Text(
                                  activity['user_name']?.toString() ?? '',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],

                            // Time
                            if (activity['timestamp'] != null) ...[
                              Icon(
                                Icons.access_time_outlined,
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                fit: FlexFit.loose,
                                child: Text(
                                  _formatDate(
                                    activity['timestamp']?.toString() ?? '',
                                  ),
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Type badge (fixed at end)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _typeLabels[activity['type']] ??
                              activity['type']?.toString() ??
                              '',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: color,
                            fontWeight: FontWeight.w500,
                          ),
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
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'shopping_basket':
        return Icons.shopping_basket_outlined;
      case 'restaurant_menu':
        return Icons.restaurant_menu_outlined;
      case 'download':
        return Icons.download_outlined;
      case 'delete':
        return Icons.delete_outline;
      case 'upload':
        return Icons.upload_outlined;
      case 'people':
        return Icons.people_outline;
      case 'business':
        return Icons.business_outlined;
      default:
        return Icons.history_outlined;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_outlined,
            size: 80,
            color: AppColors.textSecondary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum Ada Aktivitas',
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mulai lakukan transaksi untuk melihat riwayat',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _searchActivities,
                  decoration: InputDecoration(
                    hintText: 'Cari aktivitas...',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary.withOpacity(0.5),
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: AppColors.textSecondary.withOpacity(0.5),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        _searchActivities('');
                      },
                      icon: Icon(
                        Icons.clear,
                        color: AppColors.textSecondary.withOpacity(0.5),
                      ),
                    )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),

            // Filter Chips
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _activityTypes.length,
                itemBuilder: (context, index) {
                  final type = _activityTypes[index];
                  final isSelected = _selectedType == type;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_typeLabels[type] ?? type),
                      selected: isSelected,
                      onSelected: (_) => _filterByType(type),
                      backgroundColor: AppColors.surface,
                      selectedColor: AppColors.primary.withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  );
                },
              ),
            ),

            // Activity Count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'Total: ${_filteredActivities.length} aktivitas',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Activities List
            Expanded(
              child: _isLoading
                  ? Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              )
                  : _filteredActivities.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                onRefresh: _loadActivities,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredActivities.length,
                  itemBuilder: (context, index) {
                    return _buildActivityItem(_filteredActivities[index]);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}