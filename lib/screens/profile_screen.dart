import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/profile_provider.dart';
import '../widgets/status_box.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  // Local UI state (setState). Only this screen uses it.
  File? _photo; // null = show initials placeholder
  bool _isSaving = false;
  bool _showSaved = false;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    // read (not watch): we only need the saved name ONCE to fill the field.
    _nameController.text = context.read<ProfileProvider>().name;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800, // smaller image = less memory
      );
      if (picked == null) return; // cancelled: keep the existing photo
      if (!mounted) return;
      setState(() {
        _photo = File(picked.path);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the gallery')),
      );
    }
  }

  Future<void> _saveName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Please enter a name');
      return;
    }

    FocusScope.of(context).unfocus(); // close the keyboard
    setState(() {
      _isSaving = true;
      _showSaved = false;
      _nameError = null;
    });

    // Provider updates Home's greeting + writes to storage.
    await context.read<ProfileProvider>().saveName(name);

    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _showSaved = true;
    });
  }

  // "Aslam Ali" -> "AA", "Aslam" -> "A"
  String _initials(String name) {
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final savedName = context.watch<ProfileProvider>().name;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        // Scrollable, so an open keyboard can't cause an overflow.
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'My profile',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              // ---------- Avatar + camera button (Stack + Positioned) ----------
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 56,
                      backgroundColor: colors.primaryContainer,
                      backgroundImage:
                          _photo != null ? FileImage(_photo!) : null,
                      child: _photo == null
                          ? Text(
                              _initials(savedName),
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: colors.primary,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: IconButton.filled(
                        onPressed: _pickPhoto,
                        icon: const Icon(Icons.camera_alt, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: _pickPhoto,
                  child: const Text('Change profile photo'),
                ),
              ),
              const SizedBox(height: 16),

              // ---------- Name form ----------
              const Text(
                'Display name',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                onChanged: (_) {
                  // hide old messages once the user edits again
                  if (_showSaved || _nameError != null) {
                    setState(() {
                      _showSaved = false;
                      _nameError = null;
                    });
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Your name',
                  errorText: _nameError,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _saveName, // null = disabled
                  child: Text(_isSaving ? 'Saving...' : 'Save profile'),
                ),
              ),
              if (_showSaved) ...[
                const SizedBox(height: 16),
                const StatusBox(
                  type: StatusType.success,
                  title: 'Profile saved',
                ),
              ],
              const SizedBox(height: 16),
              const Text(
                'Name is saved on this device.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
