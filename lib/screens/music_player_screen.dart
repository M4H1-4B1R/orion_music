import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:xml/xml.dart';
import 'package:http/http.dart' as http;
import 'dart:ui'; // For ImageFilter
import '../widgets/liquid_backgrounds.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/glass_button.dart';

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
  bool isLoading = true; // variable to track loading state
  double sliderValue = 0.0;
  Duration? totalDuration;

  @override
  void initState() {
    super.initState();
    _fetchEpisodes(); // Fetch real data on start
    // (Auto-move slider)
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

    // listen to duration updates
    _audioPlayer.durationStream.listen((duration) {
      setState(() {
        totalDuration = duration;
      });
    });
  }

  //  Save the current song index to phone storage
  Future<void> _saveLastPlayed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_played_index', currentIndex);
  }

  void _showMenuWindow(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        // Reuse the same Glass Sheet logic!
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2C).withOpacity(0.7),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.0,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min, // Wrap content only
                children: [
                  // Handle Bar
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  // Menu Title
                  const Text(
                    "Menu",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Option 1: Local Music
                  _buildMenuOption(
                    icon: Icons.sd_storage_rounded,
                    title: "Local Music",
                    onTap: () {
                      Navigator.pop(context); // Close menu
                      // Navigate to Local Music Screen (Create this later)
                      // Navigator.push(context, MaterialPageRoute(builder: (c) => const LocalMusicScreen()));
                    },
                  ),

                  // Option 2: Timer
                  _buildMenuOption(
                    icon: Icons.timer_rounded,
                    title: "Sleep Timer",
                    onTap: () {
                      Navigator.pop(context);
                      // Navigate to Timer logic
                    },
                  ),

                  // Option 3: Settings
                  _buildMenuOption(
                    icon: Icons.settings_rounded,
                    title: "Settings",
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),

                  const SizedBox(height: 20), // Bottom spacing
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper widget for menu items
  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        color: Colors.white54,
        size: 16,
      ),
      onTap: onTap,
    );
  }

  // The missing function!
  void _showPlaylistWindow(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E2C).withOpacity(0.7),
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
                      // Handle Bar
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 10, bottom: 10),
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
                          controller: scrollController,
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
                                  cacheWidth: 100, // Optimized!
                                ),
                              ),
                              title: Text(
                                song['title']!,
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                song['artist']!,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                ),
                              ),
                              onTap: () {
                                setState(() {
                                  currentIndex = index;
                                  isPlaying = true;
                                });
                                _saveLastPlayed(); // Remember to save!
                                _setupAudio();
                                _audioPlayer.play();
                                Navigator.pop(context);
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
  }

  //  Fetch Data from RSS Feed
  Future<void> _fetchEpisodes() async {
    try {
      final response = await http.get(
        Uri.parse('https://musicforprogramming.net/rss.php'),
      );

      if (response.statusCode == 200) {
        final document = XmlDocument.parse(response.body);
        final items = document.findAllElements('item');

        // parse the playlist
        final newPlaylist = items.map((node) {
          return {
            'title': node.findElements('title').single.innerText,
            'artist': 'Music for Programming',
            'image':
                'https://images.unsplash.com/photo-1614149162883-504ce4d13909?q=80&w=600&auto=format&fit=crop',
            'url': node.findElements('guid').single.innerText,
          };
        }).toList();

        // Load the Saved Index from Storage
        final prefs = await SharedPreferences.getInstance();
        int savedIndex =
            prefs.getInt('last_played_index') ??
            0; // Default to 0 (First song) if nothing saved

        setState(() {
          playlist = newPlaylist;
          isLoading = false;

          // Validation: Make sure saved index still exists in the list
          if (savedIndex >= 0 && savedIndex < playlist.length) {
            currentIndex = savedIndex;
          } else {
            currentIndex = 0;
          }
        });

        // 4. Load the song
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
          RepaintBoundary(
            child: Stack(children: [LiquidBackground(isPlaying: isPlaying)]),
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

                      // Song Title
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

                      // Artist Name
                      Text(
                        playlist[currentIndex]['artist']!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 18,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Controls
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
                                  _saveLastPlayed();
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
                                  _saveLastPlayed();
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
      // 1. Position the buttons at the bottom center so our Row can stretch
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      // 2. The Buttons
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 24.0,
        ), // Spacing from screen edges
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween, // Push to Left and Right
          children: [
            // LEFT: The New Menu Button
            GlassButton(
              icon: Icons.grid_view_rounded, // "Menu" icon
              onTap: () {
                _showMenuWindow(context); // We will write this function next!
              },
            ),

            // RIGHT: The Existing Playlist Button
            GlassButton(
              icon: Icons.queue_music_rounded,
              onTap: () {
                // Paste your existing showModalBottomSheet logic here
                _showPlaylistWindow(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
