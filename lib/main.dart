import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Removes the debug ribbon
      theme: ThemeData.dark(),
      home: const MusicPlayerScreen(),
    );
  }
}

class MusicPlayerScreen extends StatefulWidget {
  const MusicPlayerScreen({super.key});

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  // state variables
  bool isPlaying = false;
  double sliderValue = 0.0;

  @override
  void initState() {
    super.initState();
    // load song when app starts
    _setupAudio();
  }

  Future<void> _setupAudio() async {
    // song url (mp3)
    await _audioPlayer.setUrl(
      'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
    );
  }

  @override
  void dispose() {
    // releas memory when closed
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. The Background Color
    // We use a Scaffold with a specific deep dark blue-grey color
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 2. The Glowing Album Art Container
            Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  30,
                ), // Smooth rounded corners
                // A. The Image
                image: const DecorationImage(
                  image: NetworkImage(
                    'https://images.unsplash.com/photo-1614149162883-504ce4d13909?q=80&w=600&auto=format&fit=crop',
                  ),
                  fit: BoxFit.cover,
                ),
                // B. The Glow Effect (BoxShadow)
                boxShadow: [
                  BoxShadow(
                    color: const Color(
                      0xFFFF4B4B,
                    ).withOpacity(0.4), // Reddish-orange glow
                    blurRadius: 60, // How "soft" the light is (Higher = softer)
                    spreadRadius:
                        -10, // Negative spread keeps the glow from getting too huge
                    offset: const Offset(
                      0,
                      30,
                    ), // Moves the shadow down to look like a backlight
                  ),
                ],
              ),
            ),

            // ... (Your existing Album Art Container is above here) ...
            const SizedBox(height: 40), // Spacing
            // 3. Song Title
            const Text(
              'Nightcall',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: 8),

            // 4. Artist Name
            Text(
              'Kavinsky',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6), // Dimmer text
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 40),

            // 5. The Slider (Visual only for now)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Slider(
                value: sliderValue,
                min: 0.0,
                max: 1.0,
                onChanged: (value) {
                  setState(() {
                    sliderValue = value;
                  });
                },
                activeColor: const Color(0xFFFF4B4B), // Matches the glow
                inactiveColor: Colors.white10,
              ),
            ),

            const SizedBox(height: 20),

            // 6. Playback Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous_rounded, size: 40),
                  color: Colors.white,
                  onPressed: () {},
                ),
                const SizedBox(width: 30),

                // Custom Glowing Play Button
                GestureDetector(
                  onTap: () {
                    if (isPlaying) {
                      _audioPlayer.pause();
                    } else {
                      _audioPlayer.play();
                    }
                    setState(() {
                      isPlaying = !isPlaying;
                    });
                  },

                  child: Container(
                    padding: const EdgeInsets.all(15), // Size of the button
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4B4B),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF4B4B).withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),

                const SizedBox(width: 30),
                IconButton(
                  icon: const Icon(Icons.skip_next_rounded, size: 40),
                  color: Colors.white,
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
