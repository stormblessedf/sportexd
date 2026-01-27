import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
  
  String? _selectedGender;
  Level? _selectedLevel;
  PlayStyle? _selectedPlayStyle;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user.username);
    _bioController = TextEditingController(text: widget.user.bio ?? '');
    _locationController = TextEditingController(text: widget.user.location ?? '');
    _selectedGender = widget.user.gender;
    _selectedLevel = widget.user.level;
    _selectedPlayStyle = widget.user.playStyle;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authService.updateUser(
        userId: widget.user.id,
        username: _usernameController.text.trim(),
        bio: _bioController.text.trim(),
        location: _locationController.text.trim(),
        gender: _selectedGender,
        level: _selectedLevel,
        playStyle: _selectedPlayStyle,
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
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
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
                : const Text('Kaydet', style: TextStyle(fontWeight: FontWeight.bold)),
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
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      backgroundImage: widget.user.profileImageUrl != null
                          ? NetworkImage(widget.user.profileImageUrl!)
                          : null,
                      child: widget.user.profileImageUrl == null
                          ? const Icon(Icons.person, size: 50)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, size: 18),
                          onPressed: () {
                            // TODO: Implement image picker
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Fotoğraf değiştirme yakında!')),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
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

              // Gender
              _buildSectionTitle('Cinsiyet'),
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: _inputDecoration('Seçiniz'),
                items: const [
                  DropdownMenuItem(value: 'erkek', child: Text('Erkek')),
                  DropdownMenuItem(value: 'kadın', child: Text('Kadın')),
                  DropdownMenuItem(value: 'belirtmek_istemiyorum', child: Text('Belirtmek İstemiyorum')),
                ],
                onChanged: (value) => setState(() => _selectedGender = value),
              ),
              const SizedBox(height: 20),

              // Level
              _buildSectionTitle('Seviye'),
              DropdownButtonFormField<Level>(
                value: _selectedLevel,
                decoration: _inputDecoration('Spor seviyeniz'),
                items: const [
                  DropdownMenuItem(value: Level.beginner, child: Text('Başlangıç')),
                  DropdownMenuItem(value: Level.intermediate, child: Text('Orta')),
                  DropdownMenuItem(value: Level.advanced, child: Text('İleri')),
                ],
                onChanged: (value) => setState(() => _selectedLevel = value),
              ),
              const SizedBox(height: 20),

              // Play Style
              _buildSectionTitle('Oyun Tarzı'),
              DropdownButtonFormField<PlayStyle>(
                value: _selectedPlayStyle,
                decoration: _inputDecoration('Nasıl oynamayı seversiniz?'),
                items: const [
                  DropdownMenuItem(value: PlayStyle.casual, child: Text('Eğlence Amaçlı')),
                  DropdownMenuItem(value: PlayStyle.competitive, child: Text('Rekabetçi')),
                ],
                onChanged: (value) => setState(() => _selectedPlayStyle = value),
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
                      : const Text('Değişiklikleri Kaydet', style: TextStyle(fontSize: 16)),
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
