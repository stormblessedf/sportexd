import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/location_data.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/places_service.dart';
import '../../../../core/utils/map_style.dart';

class LocationPickerWidget extends StatefulWidget {
  final LocationData? initialLocation;
  final ValueChanged<LocationData> onLocationSelected;
  final double height;

  const LocationPickerWidget({
    super.key,
    this.initialLocation,
    required this.onLocationSelected,
    this.height = 300,
  });

  @override
  State<LocationPickerWidget> createState() => _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends State<LocationPickerWidget> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final PlacesService _placesService = PlacesService();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  LatLng? _selectedPosition;
  String? _selectedAddress;
  String? _selectedName;
  bool _isLoading = false;
  bool _mapError = false;
  bool _mapLoading = true;

  // Autocomplete
  List<PlaceAutocompleteResult> _suggestions = [];
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _initializePosition();
    _searchFocusNode.addListener(_onFocusChange);

    // Set a timeout for map loading
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && _mapLoading) {
        setState(() {
          _mapLoading = false;
          _mapError = true;
        });
      }
    });
  }

  void _initializePosition() {
    if (widget.initialLocation != null) {
      _selectedPosition = LatLng(
        widget.initialLocation!.latitude,
        widget.initialLocation!.longitude,
      );
      _selectedAddress = widget.initialLocation!.address;
      _selectedName = widget.initialLocation!.name;
    } else {
      _selectedPosition = const LatLng(
        LocationService.defaultLatitude,
        LocationService.defaultLongitude,
      );
    }
  }

  void _onFocusChange() {
    if (!_searchFocusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 200), () {
        _hideOverlay();
      });
    }
  }

  @override
  void dispose() {
    _hideOverlay();
    _mapController?.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _showOverlay() {
    if (_overlayEntry != null || _suggestions.isEmpty) return;

    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox?;
    final size = renderBox?.size ?? Size.zero;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 56),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 250),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _suggestions[index];
                  return ListTile(
                    leading: const Icon(Icons.location_on_outlined),
                    title: Text(
                      suggestion.mainText,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: suggestion.secondaryText.isNotEmpty
                        ? Text(
                            suggestion.secondaryText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
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
      setState(() {
        _suggestions = [];
      });
      _hideOverlay();
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      final results = await _placesService.getAutocomplete(query);
      if (mounted) {
        setState(() {
          _suggestions = results;
        });
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
        _selectedPosition = position;
        _selectedAddress = details.address;
        _selectedName = details.name;
        _isLoading = false;
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(position, 16),
      );

      _notifyLocationSelected();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onMapTap(LatLng position) async {
    _hideOverlay();
    setState(() {
      _selectedPosition = position;
      _isLoading = true;
      _suggestions = [];
    });

    final locationService = context.read<LocationService>();
    final address = await locationService.getAddressFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (mounted) {
      setState(() {
        _selectedAddress = address;
        _selectedName = null;
        _isLoading = false;
      });

      _notifyLocationSelected();
    }
  }

  Future<void> _goToCurrentLocation() async {
    setState(() => _isLoading = true);

    final locationService = context.read<LocationService>();
    final currentLocation = await locationService.getCurrentLocation();

    if (mounted) {
      if (currentLocation != null) {
        final position = LatLng(
          currentLocation.latitude,
          currentLocation.longitude,
        );
        setState(() {
          _selectedPosition = position;
          _selectedAddress = currentLocation.address;
          _selectedName = null;
          _isLoading = false;
        });

        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(position, 16),
        );

        _notifyLocationSelected();
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Konumunuz alınamadı')),
          );
        }
      }
    }
  }

  void _notifyLocationSelected() {
    if (_selectedPosition == null) return;

    widget.onLocationSelected(
      LocationData(
        latitude: _selectedPosition!.latitude,
        longitude: _selectedPosition!.longitude,
        address: _selectedAddress,
        name: _selectedName ?? _searchController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Bar with Autocomplete
        CompositedTransformTarget(
          link: _layerLink,
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            decoration: InputDecoration(
              hintText: 'Konum veya mekan ara...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _suggestions = [];
                        });
                        _hideOverlay();
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: _onSearchChanged,
          ),
        ),
        const SizedBox(height: 12),

        // Map
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: widget.height,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: _mapError
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.map_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Harita yüklenemedi',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Lütfen konum adını manuel olarak girin',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  )
                : Stack(
                    children: [
                      GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _selectedPosition ?? const LatLng(
                            LocationService.defaultLatitude,
                            LocationService.defaultLongitude,
                          ),
                          zoom: 14,
                        ),
                        onMapCreated: (controller) {
                          _mapController = controller;
                          setState(() {
                            _mapError = false;
                            _mapLoading = false;
                          });
                        },
                        onTap: _onMapTap,
                        markers: _selectedPosition != null
                            ? {
                                Marker(
                                  markerId: const MarkerId('selected'),
                                  position: _selectedPosition!,
                                  draggable: true,
                                  onDragEnd: _onMapTap,
                                ),
                              }
                            : {},
                        style: MapStyle.lightStyle,
                        zoomControlsEnabled: false,
                        mapToolbarEnabled: false,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                      ),

                      // Map Loading Overlay
                      if (_mapLoading)
                        Positioned.fill(
                          child: Container(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const CircularProgressIndicator(),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Harita yükleniyor...',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // Loading Overlay
                      if (_isLoading && !_mapLoading)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black26,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        ),

                      // Current Location Button
                      if (!_mapLoading)
                        Positioned(
                          right: 12,
                          bottom: 12,
                          child: FloatingActionButton.small(
                            onPressed: _isLoading ? null : _goToCurrentLocation,
                            backgroundColor: Theme.of(context).colorScheme.surface,
                            child: Icon(
                              Icons.my_location,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ),

        // Selected Location Display
        if (_selectedAddress != null || _selectedName != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_selectedName != null && _selectedName!.isNotEmpty)
                        Text(
                          _selectedName!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      if (_selectedAddress != null)
                        Text(
                          _selectedAddress!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 8),
        Text(
          'Arama yapın veya haritaya tıklayarak konum seçin',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ],
    );
  }
}
