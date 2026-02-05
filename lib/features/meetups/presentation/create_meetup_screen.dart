import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/models/meetup_model.dart';
import '../../../core/models/location_data.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/meetup_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/places_service.dart';
import '../../../core/services/map_preferences_service.dart';

class CreateMeetupScreen extends StatefulWidget {
  const CreateMeetupScreen({super.key});

  @override
  State<CreateMeetupScreen> createState() => _CreateMeetupScreenState();
}

class _CreateMeetupScreenState extends State<CreateMeetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final PlacesService _placesService = PlacesService();
  final MapController _mapController = MapController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  DateTime _displayedMonth = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _startTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 8, minute: 30);
  MeetupType _selectedType = MeetupType.running;
  int _maxParticipants = 4;
  int _selectedSkillLevel = 1; // 0: Beginner, 1: Intermediate, 2: Advanced
  bool _isLoading = false;
  LocationData? _selectedLocation;
  LatLng? _mapCenter;

  // Autocomplete
  List<PlaceAutocompleteResult> _suggestions = [];
  Timer? _debounceTimer;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  // Theme colors
  static const Color primary = Color(0xFF13EC5B);
  static const Color backgroundLight = Color(0xFFF6F8F6);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color borderLight = Color(0xFFE2E8F0);

  // Sport types with icons
  static final List<_SportTypeData> _sportTypes = [
    _SportTypeData(MeetupType.running, Icons.directions_run, 'Koşu'),
    _SportTypeData(MeetupType.cycling, Icons.pedal_bike, 'Bisiklet'),
    _SportTypeData(MeetupType.fitness, Icons.fitness_center, 'Fitness'),
    _SportTypeData(MeetupType.yoga, Icons.self_improvement, 'Yoga'),
    _SportTypeData(MeetupType.tennis, Icons.sports_tennis, 'Tenis'),
    _SportTypeData(MeetupType.football, Icons.sports_soccer, 'Futbol'),
    _SportTypeData(MeetupType.basketball, Icons.sports_basketball, 'Basketbol'),
    _SportTypeData(MeetupType.volleyball, Icons.sports_volleyball, 'Voleybol'),
    _SportTypeData(MeetupType.swimming, Icons.pool, 'Yüzme'),
    _SportTypeData(MeetupType.hiking, Icons.terrain, 'Yürüyüş'),
    _SportTypeData(MeetupType.boxing, Icons.sports_mma, 'Boks'),
    _SportTypeData(MeetupType.other, Icons.sports, 'Diğer'),
  ];

  @override
  void initState() {
    super.initState();
    _mapCenter = LatLng(LocationService.defaultLatitude, LocationService.defaultLongitude);
    _searchFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _hideOverlay();
    _titleController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_searchFocusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 200), () {
        _hideOverlay();
      });
    }
  }

  // Autocomplete methods
  void _showOverlay() {
    if (_overlayEntry != null || _suggestions.isEmpty) return;

    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox?;
    final size = renderBox?.size ?? Size.zero;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width - 40,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 52),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderLight),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _suggestions[index];
                  return ListTile(
                    dense: true,
                    leading: Icon(Icons.location_on_outlined, color: textMuted, size: 20),
                    title: Text(
                      suggestion.mainText,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: suggestion.secondaryText.isNotEmpty
                        ? Text(
                            suggestion.secondaryText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: textMuted),
                          )
                        : null,
                    onTap: () => _selectPlace(suggestion),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _updateOverlay() {
    if (_suggestions.isEmpty) {
      _hideOverlay();
    } else if (_overlayEntry == null) {
      _showOverlay();
    } else {
      _overlayEntry!.markNeedsBuild();
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();

    if (query.length < 2) {
      setState(() => _suggestions = []);
      _hideOverlay();
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      final results = await _placesService.getAutocomplete(query);
      if (mounted) {
        setState(() => _suggestions = results);
        _updateOverlay();
      }
    });
  }

  Future<void> _selectPlace(PlaceAutocompleteResult place) async {
    _hideOverlay();
    setState(() {
      _suggestions = [];
      _isLoading = true;
    });
    _searchController.text = place.mainText;
    _searchFocusNode.unfocus();

    final details = await _placesService.getPlaceDetails(place.placeId);

    if (mounted && details != null) {
      final position = LatLng(details.latitude, details.longitude);
      setState(() {
        _mapCenter = position;
        _selectedLocation = details;
        _isLoading = false;
      });
      _mapController.move(position, 15);
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onMapTap(TapPosition tapPosition, LatLng position) async {
    setState(() {
      _mapCenter = position;
      _isLoading = true;
    });

    final locationService = context.read<LocationService>();
    final address = await locationService.getAddressFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (mounted) {
      setState(() {
        _selectedLocation = LocationData(
          latitude: position.latitude,
          longitude: position.longitude,
          address: address,
          name: address,
        );
        _isLoading = false;
      });
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
        final startMinutes = picked.hour * 60 + picked.minute;
        final endMinutes = _endTime.hour * 60 + _endTime.minute;
        if (endMinutes <= startMinutes) {
          _endTime = TimeOfDay(hour: (picked.hour + 1) % 24, minute: picked.minute);
        }
      });
    }
  }

  Future<void> _pickEndTime() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
      builder: (dialogContext, child) {
        return Theme(
          data: Theme.of(dialogContext).copyWith(
            colorScheme: const ColorScheme.light(primary: primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && context.mounted) {
      final startMinutes = _startTime.hour * 60 + _startTime.minute;
      final endMinutes = picked.hour * 60 + picked.minute;
      if (endMinutes <= startMinutes) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Bitiş saati başlangıç saatinden sonra olmalı'), backgroundColor: Colors.orange),
        );
        return;
      }
      setState(() => _endTime = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen konum seçin'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = context.read<AuthService>();
      final meetupService = context.read<MeetupService>();

      final user = await authService.getCurrentUser();
      if (user == null) throw Exception("Oturum açık değil");

      final meetupStartDateTime = DateTime(
        _selectedDate.year, _selectedDate.month, _selectedDate.day,
        _startTime.hour, _startTime.minute,
      );
      final meetupEndDateTime = DateTime(
        _selectedDate.year, _selectedDate.month, _selectedDate.day,
        _endTime.hour, _endTime.minute,
      );

      await meetupService.createMeetup(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        date: meetupStartDateTime,
        endDate: meetupEndDateTime,
        locationName: _selectedLocation?.name ?? _selectedLocation?.address ?? '',
        locationAddress: _selectedLocation?.address ?? '',
        maxParticipants: _maxParticipants,
        organizerId: user.id,
        organizerName: user.username,
        organizerImageUrl: user.profileImageUrl,
        latitude: _selectedLocation?.latitude,
        longitude: _selectedLocation?.longitude,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Etkinlik oluşturuldu!'), backgroundColor: primary),
        );
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        backgroundColor: backgroundLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textDark),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Etkinlik Oluştur',
          style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _buildSportSection(),
                  const SizedBox(height: 32),
                  _buildDateTimeSection(),
                  const SizedBox(height: 32),
                  _buildLocationSection(),
                  const SizedBox(height: 32),
                  _buildDetailsSection(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            Positioned(left: 0, right: 0, bottom: 0, child: _buildBottomButton()),
          ],
        ),
      ),
    );
  }

  Widget _buildSportSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Spor Seç',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textDark),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _sportTypes.length,
            itemBuilder: (context, index) {
              final sport = _sportTypes[index];
              final isSelected = _selectedType == sport.type;
              return Padding(
                padding: EdgeInsets.only(right: index < _sportTypes.length - 1 ? 16 : 0),
                child: _buildSportChip(sport, isSelected),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSportChip(_SportTypeData sport, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _selectedType = sport.type),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isSelected ? primary : surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: isSelected ? null : Border.all(color: const Color(0xFFF1F5F9)),
              boxShadow: isSelected
                  ? [BoxShadow(color: primary.withValues(alpha:0.3), blurRadius: 12, offset: const Offset(0, 4))]
                  : null,
            ),
            child: Icon(sport.icon, size: 30, color: isSelected ? Colors.black : textMuted),
          ),
          const SizedBox(height: 8),
          Text(
            sport.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? textDark : textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tarih & Saat',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textDark),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildMonthNavigation(),
                const SizedBox(height: 16),
                _buildCalendarGrid(),
                const SizedBox(height: 20),
                _buildTimeRange(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthNavigation() {
    final months = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: Icon(Icons.chevron_left, color: textMuted),
          onPressed: () {
            setState(() {
              _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1, 1);
            });
          },
        ),
        Text(
          '${months[_displayedMonth.month - 1]} ${_displayedMonth.year}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark),
        ),
        IconButton(
          icon: Icon(Icons.chevron_right, color: textMuted),
          onPressed: () {
            setState(() {
              _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 1);
            });
          },
        ),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    final days = ['P', 'S', 'Ç', 'P', 'C', 'C', 'P'];
    final firstDayOfMonth = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final daysInMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;
    final startWeekday = (firstDayOfMonth.weekday - 1) % 7;
    final today = DateTime.now();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: days.map((d) => SizedBox(
            width: 36,
            child: Text(d, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textMuted)),
          )).toList(),
        ),
        const SizedBox(height: 8),
        ...List.generate(6, (weekIndex) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (dayIndex) {
              final dayNum = weekIndex * 7 + dayIndex - startWeekday + 1;
              if (dayNum < 1 || dayNum > daysInMonth) {
                return const SizedBox(width: 36, height: 36);
              }

              final date = DateTime(_displayedMonth.year, _displayedMonth.month, dayNum);
              final isSelected = _selectedDate.year == date.year &&
                  _selectedDate.month == date.month &&
                  _selectedDate.day == date.day;
              final isPast = date.isBefore(DateTime(today.year, today.month, today.day));

              return GestureDetector(
                onTap: isPast ? null : () => setState(() => _selectedDate = date),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected ? primary : Colors.transparent,
                    shape: BoxShape.circle,
                    boxShadow: isSelected
                        ? [BoxShadow(color: primary.withValues(alpha:0.4), blurRadius: 8, offset: const Offset(0, 2))]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '$dayNum',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isPast ? textMuted.withValues(alpha:0.4) : (isSelected ? Colors.black : textDark),
                      ),
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      ],
    );
  }

  Widget _buildTimeRange() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _pickStartTime,
              child: Row(
                children: [
                  Icon(Icons.schedule, color: textMuted, size: 20),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('BAŞLANGIÇ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textMuted, letterSpacing: 0.5)),
                      const SizedBox(height: 2),
                      Text(_formatTime(_startTime), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(width: 1, height: 40, color: borderLight),
          Expanded(
            child: GestureDetector(
              onTap: _pickEndTime,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('BİTİŞ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textMuted, letterSpacing: 0.5)),
                      const SizedBox(height: 2),
                      Text(_formatTime(_endTime), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Widget _buildLocationSection() {
    final mapPrefs = context.watch<MapPreferencesService>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Konum', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textDark)),
          const SizedBox(height: 16),

          // Search field
          CompositedTransformTarget(
            link: _layerLink,
            child: Container(
              decoration: BoxDecoration(
                color: surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderLight),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                style: const TextStyle(fontSize: 14, color: textDark),
                decoration: InputDecoration(
                  hintText: 'Konum veya mekan ara...',
                  hintStyle: TextStyle(color: textMuted.withValues(alpha:0.6)),
                  prefixIcon: Icon(Icons.search, color: textMuted, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: textMuted, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _suggestions = []);
                            _hideOverlay();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onChanged: _onSearchChanged,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Map
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 192,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFF1F5F9)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _mapCenter ?? LatLng(LocationService.defaultLatitude, LocationService.defaultLongitude),
                      initialZoom: 14,
                      onTap: _onMapTap,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: mapPrefs.currentTileUrl,
                        subdomains: mapPrefs.currentSubdomains,
                        userAgentPackageName: 'com.sporsal.app',
                      ),
                    ],
                  ),

                  // Gradient overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withValues(alpha:0.1)],
                        ),
                      ),
                    ),
                  ),

                  // Center pin
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_on, color: primary, size: 48),
                        Container(
                          width: 12,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha:0.3),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Location name overlay
                  if (_selectedLocation != null)
                    Positioned(
                      bottom: 12,
                      left: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: surfaceLight,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.1), blurRadius: 8)],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.near_me, color: textMuted, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedLocation?.name ?? _selectedLocation?.address ?? '',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textDark),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Loading overlay
                  if (_isLoading)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black26,
                        child: const Center(child: CircularProgressIndicator(color: primary)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Detaylar', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textDark)),
          const SizedBox(height: 16),

          // Event Title
          _buildFloatingLabelField(
            label: 'Etkinlik Başlığı',
            child: TextFormField(
              controller: _titleController,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textDark),
              decoration: InputDecoration(
                hintText: 'Sabah Koşusu 5K',
                hintStyle: TextStyle(color: textMuted.withValues(alpha:0.5), fontWeight: FontWeight.normal),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              validator: (val) => val == null || val.isEmpty ? 'Başlık gerekli' : null,
            ),
          ),
          const SizedBox(height: 16),

          // Description
          _buildFloatingLabelField(
            label: 'Açıklama',
            child: TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              style: const TextStyle(fontSize: 14, color: textDark),
              decoration: InputDecoration(
                hintText: 'Etkinlik hakkında detay...',
                hintStyle: TextStyle(color: textMuted.withValues(alpha:0.5)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Participant Limit
          _buildFloatingLabelField(
            label: 'Katılımcı Sınırı',
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Maks. Katılımcı', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textDark)),
                  Row(
                    children: [
                      _buildCounterButton(Icons.remove, () {
                        if (_maxParticipants > 2) setState(() => _maxParticipants--);
                      }, false),
                      SizedBox(
                        width: 32,
                        child: Text('$_maxParticipants', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark)),
                      ),
                      _buildCounterButton(Icons.add, () {
                        if (_maxParticipants < 50) setState(() => _maxParticipants++);
                      }, true),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Skill Level
          _buildFloatingLabelField(
            label: 'Seviye',
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  _buildSkillButton('Başlangıç', 0),
                  const SizedBox(width: 8),
                  _buildSkillButton('Orta', 1),
                  const SizedBox(width: 8),
                  _buildSkillButton('İleri', 2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingLabelField({required String label, required Widget child}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD1D5DB)),
          ),
          child: child,
        ),
        Positioned(
          top: -10,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            color: backgroundLight,
            child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textMuted)),
          ),
        ),
      ],
    );
  }

  Widget _buildCounterButton(IconData icon, VoidCallback onTap, bool isPrimary) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isPrimary ? primary : const Color(0xFFE5E7EB),
          shape: BoxShape.circle,
          border: isPrimary ? null : Border.all(color: const Color(0xFFD1D5DB)),
          boxShadow: isPrimary ? [BoxShadow(color: primary.withValues(alpha:0.3), blurRadius: 8, offset: const Offset(0, 2))] : null,
        ),
        child: Icon(icon, size: 18, color: isPrimary ? Colors.black : const Color(0xFF374151)),
      ),
    );
  }

  Widget _buildSkillButton(String label, int level) {
    final isSelected = _selectedSkillLevel == level;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedSkillLevel = level),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? primary : const Color(0xFFE5E7EB)),
            boxShadow: isSelected ? [BoxShadow(color: primary.withValues(alpha:0.2), blurRadius: 8)] : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.black : textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundLight.withValues(alpha:0.8),
        border: Border(top: BorderSide(color: const Color(0xFFF1F5F9))),
      ),
      child: SafeArea(
        child: GestureDetector(
          onTap: _isLoading ? null : _submit,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: primary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: primary.withValues(alpha:0.2), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: _isLoading
                ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)))
                : const Text(
                    'Etkinliği Yayınla',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
          ),
        ),
      ),
    );
  }
}

class _SportTypeData {
  final MeetupType type;
  final IconData icon;
  final String label;
  const _SportTypeData(this.type, this.icon, this.label);
}
