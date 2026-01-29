import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';

class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _ageController = TextEditingController();

  bool _isLoading = false;
  Uint8List? _imageBytes;
  String? _selectedGender;
  Level _selectedLevel = Level.beginner;
  PlayStyle _selectedPlayStyle = PlayStyle.casual;
  final Set<SportType> _selectedSports = {};

  final List<String> _genderOptions = ['Erkek', 'Kadın', 'Belirtmek İstemiyorum'];

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 75,
    );
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() => _imageBytes = bytes);
    }
  }

  Future<String?> _uploadImage(String userId) async {
    if (_imageBytes == null) return null;

    try {
      final ref = FirebaseStorage.instance.ref('profile_pictures/$userId.jpg');
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'uploadedBy': userId},
      );
      final uploadTask = ref.putData(_imageBytes!, metadata);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Resim yükleme hatası: $e');
      return null;
    }
  }

  DateTime? _calculateBirthDate() {
    final age = int.tryParse(_ageController.text);
    if (age == null) return null;
    final now = DateTime.now();
    return DateTime(now.year - age, now.month, now.day);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSports.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('En az bir spor dalı seçmelisiniz'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = context.read<AuthService>();
      final userId = authService.currentUserId;

      if (userId == null) {
        throw Exception('Oturum bulunamadı. Lütfen tekrar giriş yapın.');
      }

      // Upload image if selected
      String? profileImageUrl;
      if (_imageBytes != null) {
        profileImageUrl = await _uploadImage(userId);
      }

      // Create profile
      await authService.createUserProfile(
        username: _usernameController.text.trim(),
        bio: _bioController.text.trim().isNotEmpty ? _bioController.text.trim() : null,
        location: _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : null,
        gender: _selectedGender,
        birthDate: _calculateBirthDate(),
        height: int.tryParse(_heightController.text),
        weight: int.tryParse(_weightController.text),
        interestedSports: _selectedSports.map((s) => s.name).toList(),
        profileImageUrl: profileImageUrl,
        level: _selectedLevel,
        playStyle: _selectedPlayStyle,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil başarıyla oluşturuldu!'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Oluştur'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Picture
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                        backgroundImage: _imageBytes != null ? MemoryImage(_imageBytes!) : null,
                        child: _imageBytes == null
                            ? Icon(
                                Icons.person,
                                size: 60,
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Profil Fotoğrafı Ekle',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 32),

              // Username
              _buildSectionTitle('Kullanıcı Adı *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _usernameController,
                decoration: _inputDecoration('Kullanıcı adınız', Icons.person_outline),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Kullanıcı adı gerekli';
                  if (val.length < 3) return 'En az 3 karakter olmalı';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Bio
              _buildSectionTitle('Hakkında'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bioController,
                maxLines: 3,
                decoration: _inputDecoration('Kendinizden bahsedin...', Icons.info_outline),
              ),
              const SizedBox(height: 24),

              // Personal Info Row
              _buildSectionTitle('Kişisel Bilgiler'),
              const SizedBox(height: 8),
              Row(
                children: [
                  // Age
                  Expanded(
                    child: TextFormField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('Yaş', Icons.cake_outlined),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Gerekli';
                        final age = int.tryParse(val);
                        if (age == null || age < 13 || age > 100) return 'Geçersiz';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Height
                  Expanded(
                    child: TextFormField(
                      controller: _heightController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('Boy (cm)', Icons.height),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Weight
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('Kilo (kg)', Icons.fitness_center),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Gender
              _buildSectionTitle('Cinsiyet'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: _inputDecoration('Seçiniz', Icons.wc),
                items: _genderOptions.map((gender) {
                  return DropdownMenuItem(value: gender, child: Text(gender));
                }).toList(),
                onChanged: (value) => setState(() => _selectedGender = value),
              ),
              const SizedBox(height: 24),

              // Location
              _buildSectionTitle('Konum'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _locationController,
                decoration: _inputDecoration('Şehir', Icons.location_city),
              ),
              const SizedBox(height: 24),

              // Level
              _buildSectionTitle('Seviye'),
              const SizedBox(height: 8),
              SegmentedButton<Level>(
                segments: const [
                  ButtonSegment(
                    value: Level.beginner,
                    label: Text('Başlangıç'),
                    icon: Icon(Icons.sports_outlined),
                  ),
                  ButtonSegment(
                    value: Level.intermediate,
                    label: Text('Orta'),
                    icon: Icon(Icons.sports),
                  ),
                  ButtonSegment(
                    value: Level.advanced,
                    label: Text('İleri'),
                    icon: Icon(Icons.emoji_events),
                  ),
                ],
                selected: {_selectedLevel},
                onSelectionChanged: (Set<Level> newSelection) {
                  setState(() => _selectedLevel = newSelection.first);
                },
              ),
              const SizedBox(height: 24),

              // Play Style
              _buildSectionTitle('Oyun Stili'),
              const SizedBox(height: 8),
              SegmentedButton<PlayStyle>(
                segments: const [
                  ButtonSegment(
                    value: PlayStyle.casual,
                    label: Text('Rahat'),
                    icon: Icon(Icons.self_improvement),
                  ),
                  ButtonSegment(
                    value: PlayStyle.competitive,
                    label: Text('Rekabetçi'),
                    icon: Icon(Icons.sports_kabaddi),
                  ),
                ],
                selected: {_selectedPlayStyle},
                onSelectionChanged: (Set<PlayStyle> newSelection) {
                  setState(() => _selectedPlayStyle = newSelection.first);
                },
              ),
              const SizedBox(height: 24),

              // Interested Sports
              _buildSectionTitle('İlgilendiğin Spor Dalları *'),
              const SizedBox(height: 8),
              Text(
                'En az bir tane seç',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: SportType.values.map((sport) {
                  final isSelected = _selectedSports.contains(sport);
                  return FilterChip(
                    label: Text(sport.displayName),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedSports.add(sport);
                        } else {
                          _selectedSports.remove(sport);
                        }
                      });
                    },
                    selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                    checkmarkColor: Theme.of(context).colorScheme.primary,
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Profili Tamamla',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
