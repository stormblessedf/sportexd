import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  late TextEditingController _locationController;
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;

  String? _selectedGender;
  Level? _selectedLevel;
  PlayStyle? _selectedPlayStyle;
  Set<SportType> _selectedSports = {};
  Uint8List? _imageBytes;
  String? _currentImageUrl;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user.username);
    _bioController = TextEditingController(text: widget.user.bio ?? '');
    _locationController = TextEditingController(
      text: widget.user.location ?? '',
    );

    // Calculate age from birthDate
    int? age;
    if (widget.user.birthDate != null) {
      final now = DateTime.now();
      age = now.year - widget.user.birthDate!.year;
      if (now.month < widget.user.birthDate!.month ||
          (now.month == widget.user.birthDate!.month &&
              now.day < widget.user.birthDate!.day)) {
        age--;
      }
    }
    _ageController = TextEditingController(text: age?.toString() ?? '');
    _heightController = TextEditingController(
      text: widget.user.height?.toString() ?? '',
    );
    _weightController = TextEditingController(
      text: widget.user.weight?.toString() ?? '',
    );

    _selectedGender = widget.user.gender;
    _selectedLevel = widget.user.level;
    _selectedPlayStyle = widget.user.playStyle;
    _selectedSports = widget.user.interestedSports?.toSet() ?? {};
    _currentImageUrl = widget.user.profileImageUrl;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() => _imageBytes = bytes);
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageBytes == null) return _currentImageUrl;

    try {
      final ref = FirebaseStorage.instance.ref(
        'profile_images/${widget.user.id}/${widget.user.id}.jpg',
      );
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'uploadedBy': widget.user.id},
      );
      final uploadTask = ref.putData(_imageBytes!, metadata);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Görsel yükleme hatası: $e');
      return _currentImageUrl;
    }
  }

  DateTime? _calculateBirthDate() {
    final age = int.tryParse(_ageController.text);
    if (age == null) return widget.user.birthDate;
    final now = DateTime.now();
    return DateTime(now.year - age, now.month, now.day);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Upload image if new image selected
      String? profileImageUrl;
      if (_imageBytes != null) {
        profileImageUrl = await _uploadImage();
      }

      await _authService.updateUser(
        userId: widget.user.id,
        username: _usernameController.text.trim(),
        bio: _bioController.text.trim(),
        location: _locationController.text.trim(),
        gender: _selectedGender,
        level: _selectedLevel,
        playStyle: _selectedPlayStyle,
        profileImageUrl: profileImageUrl,
        birthDate: _calculateBirthDate(),
        height: int.tryParse(_heightController.text),
        weight: int.tryParse(_weightController.text),
        interestedSports: _selectedSports.isNotEmpty
            ? _selectedSports.map((s) => s.name).toList()
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil başarıyla güncellendi!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profili Düzenle'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Kaydet',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Photo Section
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        backgroundImage: _imageBytes != null
                            ? MemoryImage(_imageBytes!)
                            : (widget.user.profileImageUrl != null
                                      ? NetworkImage(
                                          widget.user.profileImageUrl!,
                                        )
                                      : null)
                                  as ImageProvider?,
                        child:
                            widget.user.profileImageUrl == null &&
                                _imageBytes == null
                            ? const Icon(Icons.person, size: 50)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          child: const Icon(Icons.camera_alt, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Profil fotoğrafını değiştirmek için tıklayın',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 32),

              // Username
              _buildSectionTitle('Kullanıcı Adı'),
              TextFormField(
                controller: _usernameController,
                decoration: _inputDecoration('Kullanıcı adınızı girin'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Kullanıcı adı gerekli';
                  }
                  if (value.trim().length < 3) {
                    return 'En az 3 karakter olmalı';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Bio
              _buildSectionTitle('Hakkında'),
              TextFormField(
                controller: _bioController,
                decoration: _inputDecoration('Kendinizden bahsedin...'),
                maxLines: 3,
                maxLength: 200,
              ),
              const SizedBox(height: 20),

              // Location
              _buildSectionTitle('Konum'),
              TextFormField(
                controller: _locationController,
                decoration: _inputDecoration('Şehir, İlçe'),
              ),
              const SizedBox(height: 20),

              // Personal Info Row (Age, Height, Weight)
              _buildSectionTitle('Kişisel Bilgiler'),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('Yaş'),
                      validator: (val) {
                        if (val == null || val.isEmpty) return null;
                        final age = int.tryParse(val);
                        if (age == null || age < 13 || age > 100) {
                          return 'Geçersiz';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _heightController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('Boy (cm)'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('Kilo (kg)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Gender
              _buildSectionTitle('Cinsiyet'),
              DropdownButtonFormField<String>(
                initialValue: _selectedGender,
                decoration: _inputDecoration('Seçiniz'),
                items: const [
                  DropdownMenuItem(value: 'erkek', child: Text('Erkek')),
                  DropdownMenuItem(value: 'kadın', child: Text('Kadın')),
                  DropdownMenuItem(
                    value: 'belirtmek_istemiyorum',
                    child: Text('Belirtmek İstemiyorum'),
                  ),
                ],
                onChanged: (value) => setState(() => _selectedGender = value),
              ),
              const SizedBox(height: 20),

              // Level
              _buildSectionTitle('Seviye'),
              DropdownButtonFormField<Level>(
                initialValue: _selectedLevel,
                decoration: _inputDecoration('Spor seviyeniz'),
                items: const [
                  DropdownMenuItem(
                    value: Level.beginner,
                    child: Text('Başlangıç'),
                  ),
                  DropdownMenuItem(
                    value: Level.intermediate,
                    child: Text('Orta'),
                  ),
                  DropdownMenuItem(value: Level.advanced, child: Text('İleri')),
                ],
                onChanged: (value) => setState(() => _selectedLevel = value),
              ),
              const SizedBox(height: 20),

              // Play Style
              _buildSectionTitle('Oyun Tarzı'),
              DropdownButtonFormField<PlayStyle>(
                initialValue: _selectedPlayStyle,
                decoration: _inputDecoration('Nasıl oynamayı seversiniz?'),
                items: const [
                  DropdownMenuItem(
                    value: PlayStyle.casual,
                    child: Text('Eğlence Amaçlı'),
                  ),
                  DropdownMenuItem(
                    value: PlayStyle.competitive,
                    child: Text('Rekabetçi'),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _selectedPlayStyle = value),
              ),
              const SizedBox(height: 20),

              // Interested Sports
              _buildSectionTitle('İlgilendiğin Spor Dalları'),
              Text(
                'Birden fazla seçebilirsiniz',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey),
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
                    selectedColor: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.3),
                    checkmarkColor: Theme.of(context).colorScheme.primary,
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text(
                          'Değişiklikleri Kaydet',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Colors.grey,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}
