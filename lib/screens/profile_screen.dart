import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final Client _client = Client()
    ..setEndpoint('https://cloud.appwrite.io/v1')
    ..setProject('68866a55002c3162f2fa');

  late final Account _account = Account(_client);
  late final Databases _db = Databases(_client);

  final TextEditingController _usernameController = TextEditingController();
  String? _selectedAvatar;
  bool _isLoading = true;
  bool _profileExists = false;
  String? _username;

  final List<String> _avatars = [
    'assets/avatars/avatar1.jpg',
    'assets/avatars/avatar2.jpg',
    'assets/avatars/avatar3.jpg',
    'assets/avatars/avatar4.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final session = await _account.get();
      final result = await _db.getDocument(
        databaseId: '68866b21003441437542',
        collectionId: '68866b2d00325921842a',
        documentId: session.$id,
      );

      final data = result.data;
      final username = data['username'];
      final avatar = data['avatar'];

      if (username != null && avatar != null) {
        setState(() {
          _username = username;
          _selectedAvatar = avatar;
          _profileExists = true;
          _isLoading = false;
        });

        // Wait 2 seconds before redirecting to home
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.pushReplacementNamed(context, '/home');
        return;
      }

      // If fields missing, show form
      setState(() {
        _usernameController.text = username ?? '';
        _selectedAvatar = avatar ?? _avatars[0];
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
        _selectedAvatar = _avatars[0];
      });
    }
  }

  Future<void> _submitProfile() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty || _selectedAvatar == null) return;

    setState(() => _isLoading = true);

    try {
      final user = await _account.get();

      // Try to create first
      try {
        await _db.createDocument(
          databaseId: '68866b21003441437542',
          collectionId: '68866b2d00325921842a',
          documentId: user.$id,
          data: {
            'username': username,
            'avatar': _selectedAvatar!,
          },
        );
      } catch (_) {
        await _db.updateDocument(
          databaseId: '68866b21003441437542',
          collectionId: '68866b2d00325921842a',
          documentId: user.$id,
          data: {
            'username': username,
            'avatar': _selectedAvatar!,
          },
        );
      }

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_profileExists && _username != null)
                Text(
                  'Logging in as $_username...',
                  style:
                      const TextStyle(color: Colors.cyanAccent, fontSize: 18),
                ),
              const SizedBox(height: 20),
              Image.asset('assets/logo.png', height: 100),
              const SizedBox(height: 30),
              const CircularProgressIndicator(color: Colors.cyanAccent),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Complete Profile'),
        backgroundColor: Colors.black,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter username',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Choose Your Avatar',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: GridView.builder(
                itemCount: _avatars.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  final avatar = _avatars[index];
                  final isSelected = avatar == _selectedAvatar;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedAvatar = avatar),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? Colors.cyanAccent
                              : Colors.transparent,
                          width: 4,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  // ignore: deprecated_member_use
                                  color: Colors.cyanAccent.withOpacity(0.6),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ]
                            : [],
                      ),
                      padding: const EdgeInsets.all(4),
                      child: ClipOval(
                        child: Image.asset(
                          avatar,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: _submitProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 30),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Save & Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
