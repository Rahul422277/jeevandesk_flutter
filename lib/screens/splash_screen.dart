import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:appwrite/appwrite.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _videoController;
  bool _initialized = false;

  final Client _client = Client()
    ..setEndpoint('https://cloud.appwrite.io/v1')
    ..setProject('68866a55002c3162f2fa');
  late Account _account;

  @override
  void initState() {
    super.initState();
    _account = Account(_client);
    _initVideo();
  }

  Future<void> _initVideo() async {
    _videoController = VideoPlayerController.asset('assets/splash.mp4');

    await _videoController.initialize();
    setState(() => _initialized = true);

    _videoController.play();
    _videoController.setLooping(false);

    _videoController.addListener(() async {
      if (!_videoController.value.isPlaying &&
          _videoController.value.position >= _videoController.value.duration) {
        await _handleRedirection();
      }
    });
  }

  Future<void> _handleRedirection() async {
    try {
      final session = await _account.getSession(sessionId: 'current');
      debugPrint("✅ Logged in as: ${session.userId}");

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      debugPrint("⚠️ Not logged in: $e");
      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getBool('seenOnboarding') ?? false;

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, seen ? '/auth' : '/onboarding');
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _initialized
          ? Stack(
              children: [
                SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _videoController.value.size.width,
                      height: _videoController.value.size.height,
                      child: VideoPlayer(_videoController),
                    ),
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
