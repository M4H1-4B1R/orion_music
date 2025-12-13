import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:xml/xml.dart';
import 'package:http/http.dart' as http;

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

  // 1. Data Variables
  List<Map<String, String>> playlist = [];
  int currentIndex = 0;
  bool isPlaying = false;
  bool isLoading = true; // New variable to track loading state
  double sliderValue = 0.0;
  Duration? totalDuration;

  @override
  void initState() {
    super.initState();
    _fetchEpisodes(); // Fetch real data on start
    // LISTEN TO POSITION UPDATES (Auto-move slider)
    _audioPlayer.positionStream.listen((position) {
      setState(() {
        // Calculate slider value (Current Time / Total Time)
        if (totalDuration != null && totalDuration!.inMilliseconds > 0) {
          sliderValue = position.inMilliseconds / totalDuration!.inMilliseconds;

          // Clamp value to prevent errors (keep it between 0 and 1)
          if (sliderValue > 1.0) sliderValue = 1.0;
          if (sliderValue < 0.0) sliderValue = 0.0;
        }
      });
    });

    // LISTEN TO DURATION UPDATES (How long is the song?)
    _audioPlayer.durationStream.listen((duration) {
      setState(() {
        totalDuration = duration;
      });
    });
  }

  // 2. Fetch Data from RSS Feed
  Future<void> _fetchEpisodes() async {
    try {
      final response = await http.get(
        Uri.parse('https://musicforprogramming.net/rss.php'),
      );

      if (response.statusCode == 200) {
        final document = XmlDocument.parse(response.body);
        final items = document.findAllElements('item');

        setState(() {
          playlist = items.map((node) {
            return {
              'title': node.findElements('title').single.innerText,
              'artist':
                  'Music for Programming', // The feed doesn't split artist/title cleanly
              // We keep random images to maintain your cool UI look
              'image':
                  'https://images.unsplash.com/photo-1614149162883-504ce4d13909?q=80&w=600&auto=format&fit=crop',
              'url': node.findElements('guid').single.innerText,
            };
          }).toList();

          isLoading = false; // Data loaded!
        });

        // Load the first song automatically
        if (playlist.isNotEmpty) {
          _setupAudio();
        }
      }
    } catch (e) {
      print("Error fetching songs: $e");
    }
  }

  Future<void> _setupAudio() async {
    if (playlist.isNotEmpty) {
      await _audioPlayer.setUrl(playlist[currentIndex]['url']!);
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '--:--';
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF4B4B)),
            )
          : Center(
              // Only show UI when data is ready
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 1. Album Art
                  Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      image: DecorationImage(
                        image: NetworkImage(playlist[currentIndex]['image']!),
                        fit: BoxFit.cover,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF4B4B).withOpacity(0.4),
                          blurRadius: 60,
                          spreadRadius: -10,
                          offset: const Offset(0, 30),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // 2. Song Title (Dynamic)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      playlist[currentIndex]['title']!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24, // Slightly smaller to fit long titles
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 3. Artist Name
                  Text(
                    playlist[currentIndex]['artist']!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 18,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // 5. Controls
                  Column(
                    children: [
                      // A. The Slider (Top)
                      // We remove the Expanded because Column handles vertical space differently
                      Slider(
                        value: sliderValue,
                        min: 0.0,
                        max: 1.0,
                        onChanged: (newValue) {
                          setState(() {
                            sliderValue = newValue;
                          });
                          if (totalDuration != null) {
                            final milliseconds =
                                (totalDuration!.inMilliseconds * newValue)
                                    .round();
                            _audioPlayer.seek(
                              Duration(milliseconds: milliseconds),
                            );
                          }
                        },
                        activeColor: const Color(0xFFFF4B4B),
                        inactiveColor: Colors.white10,
                      ),

                      // B. The Timestamps (Bottom)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 25,
                        ), // Align with slider edges
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment
                              .spaceBetween, // <--- Your Solution!
                          children: [
                            // Current Time
                            Text(
                              _formatDuration(
                                Duration(
                                  milliseconds:
                                      (sliderValue *
                                              (totalDuration?.inMilliseconds ??
                                                  0))
                                          .round(),
                                ),
                              ),
                              style: const TextStyle(color: Colors.white70),
                            ),

                            // Total Duration
                            Text(
                              _formatDuration(totalDuration),
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 20,
                      ), // Spacing before the play buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.skip_previous_rounded,
                              size: 40,
                            ),
                            color: Colors.white,
                            onPressed: () {
                              setState(() {
                                if (currentIndex > 0)
                                  currentIndex--;
                                else
                                  currentIndex = playlist.length - 1;
                                isPlaying = false;
                              });
                              _setupAudio();
                              _audioPlayer.play();
                              setState(() => isPlaying = true);
                            },
                          ),
                          const SizedBox(width: 30),

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
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF4B4B),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFFF4B4B,
                                    ).withOpacity(0.5),
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
                            onPressed: () {
                              setState(() {
                                if (currentIndex < playlist.length - 1)
                                  currentIndex++;
                                else
                                  currentIndex = 0;
                                isPlaying = false;
                              });
                              _setupAudio();
                              _audioPlayer.play();
                              setState(() => isPlaying = true);
                            },
                          ),
                        ],
                      ),
                      // ... (Your Play/Pause Buttons Row goes here, kept the same) ...
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
