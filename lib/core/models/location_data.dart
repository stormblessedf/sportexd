class LocationData {
  final double latitude;
  final double longitude;
  final String? name;
  final String? address;

  const LocationData({
    required this.latitude,
    required this.longitude,
    this.name,
    this.address,
  });

  LocationData copyWith({
    double? latitude,
    double? longitude,
    String? name,
    String? address,
  }) {
    return LocationData(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      name: name ?? this.name,
      address: address ?? this.address,
    );
  }

  @override
  String toString() {
    return 'LocationData(lat: $latitude, lng: $longitude, name: $name, address: $address)';
  }
}
