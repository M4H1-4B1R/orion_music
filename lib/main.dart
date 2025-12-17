import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:xml/xml.dart';
import 'package:http/http.dart' as http;
import 'dart:ui';

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

    // Helper to add a leading zero (e.g., 9 -> 09)
    String twoDigits(int n) => n.toString().padLeft(2, '0');

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    // If the song is over an hour, include the hour part
    if (duration.inHours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xff24243e),
                  const Color(0xff7303c0),
                  const Color(0xff03001e),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.black.withOpacity(0.4)),
            ),
          ),
          isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF7303c0)),
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
                            image: NetworkImage(
                              playlist[currentIndex]['image']!,
                            ),
                            fit: BoxFit.cover,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF121212).withOpacity(0.5),
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
                            activeColor: const Color(0xFFfdeff9),
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
                                                  (totalDuration
                                                          ?.inMilliseconds ??
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
                                    shape: BoxShape.circle,
                                    // 1. The Glass Gradient Fill
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.white.withOpacity(
                                          0.2,
                                        ), // Brighter at top left
                                        Colors.white.withOpacity(
                                          0.05,
                                        ), // Almost see-through at bottom right
                                      ],
                                    ),
                                    // 2. The Thin Glass Rim Border
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.4),
                                      width: 1.5,
                                    ),
                                    // 3. A subtle dark shadow for depth underneath the glass button
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 15,
                                        spreadRadius: 1,
                                        offset: const Offset(0, 5),
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
                                icon: const Icon(
                                  Icons.skip_next_rounded,
                                  size: 40,
                                ),
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
                        ],
                      ),
                    ],
                  ),
                ),
        ],
      ),
      // inside Scaffold
      floatingActionButton: GestureDetector(
        onTap: () {
          // This is your original Bottom Sheet logic
          showModalBottomSheet(
            context: context,
            isScrollControlled: true, // Make the sheet scrollable
            backgroundColor: Colors.transparent, // Match theme
            builder: (context) {
              return DraggableScrollableSheet(
                initialChildSize: 0.7,
                minChildSize: 0.5,
                maxChildSize: 0.9,
                expand: false,
                builder: (context, scrollController) {
                  return ClipRRect(
                    // Clip the blur to match our rounded corners
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                    child: BackdropFilter(
                      // The Blur Effect
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          // The Tint: Dark semi-transparent background
                          color: const Color(0xFF1E1E2C).withOpacity(0.7),

                          // use Border.all (Uniform) instead of Border
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1.0,
                          ),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(30),
                          ),
                        ),
                        child: Column(
                          children: [
                            // Little Handle Bar to show it's draggable
                            Center(
                              child: Container(
                                margin: const EdgeInsets.only(
                                  top: 10,
                                  bottom: 10,
                                ),
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),

                            // The List
                            Expanded(
                              child: ListView.builder(
                                controller:
                                    scrollController, // Crucial for scrolling!
                                itemCount: playlist.length,
                                itemBuilder: (context, index) {
                                  final song = playlist[index];
                                  return ListTile(
                                    leading: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        song['image']!,
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    title: Text(
                                      song['title']!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    subtitle: Text(
                                      song['artist']!,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.6),
                                      ),
                                    ),
                                    onTap: () {
                                      //  Play this song
                                      setState(() {
                                        currentIndex = index;
                                        isPlaying = true;
                                      });
                                      _setupAudio();
                                      _audioPlayer.play();

                                      Navigator.pop(context); // Close the sheet
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
        child: Container(
          width: 60, // Standard FAB size
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // 1. Glass Gradient
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.2),
                Colors.white.withOpacity(0.1),
              ],
            ),
            // 2. Glass Border
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
            // 3. Shadow for lift
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.queue_music_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}
