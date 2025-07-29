import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/medien_datei.dart';
import 'dart:io';

class AudioPlayerScreen extends StatefulWidget {
  final MedienDatei medienDatei;

  const AudioPlayerScreen({Key? key, required this.medienDatei}) : super(key: key);

  @override
  _AudioPlayerScreenState createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  late AudioPlayer _audioPlayer;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
  }

  Future<void> _initAudioPlayer() async {
    _audioPlayer = AudioPlayer();
    
    try {
      // Prüfen ob die Datei existiert
      final file = File(widget.medienDatei.dateipfad);
      if (!file.existsSync()) {
        setState(() {
          _error = 'Audio-Datei nicht gefunden';
          _isLoading = false;
        });
        return;
      }

      // Audio laden
      await _audioPlayer.setFilePath(widget.medienDatei.dateipfad);
      
      // Duration abrufen
      _duration = _audioPlayer.duration ?? Duration.zero;
      
      // Listener für Position und Status
      _audioPlayer.positionStream.listen((position) {
        setState(() {
          _position = position;
        });
      });

      _audioPlayer.playerStateStream.listen((state) {
        setState(() {
          _isPlaying = state.playing;
          _isLoading = false;
        });
      });

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Fehler beim Laden der Audio-Datei: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.medienDatei.dateiname),
        backgroundColor: Color(0xFF00847E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.playlist_play),
            onPressed: () => _showPlaylist(context),
          ),
          IconButton(
            icon: Icon(Icons.shuffle),
            onPressed: () => _toggleShuffle(),
          ),
          IconButton(
            icon: Icon(Icons.repeat),
            onPressed: () => _toggleRepeat(),
          ),
        ],
      ),
      body: _buildAudioPlayer(),
    );
  }

  Widget _buildAudioPlayer() {
    if (_error != null) {
      return _buildErrorState();
    }

    if (_isLoading) {
      return _buildLoadingState();
    }

    return _buildPlayerContent();
  }

  Widget _buildErrorState() {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            SizedBox(height: 16),
            Text(
              'Fehler beim Laden der Audio-Datei',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _error ?? 'Unbekannter Fehler',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _initAudioPlayer(),
              icon: Icon(Icons.refresh),
              label: Text('Erneut versuchen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF00847E),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00847E)),
            ),
            SizedBox(height: 16),
            Text(
              'Audio wird geladen...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerContent() {
    return Container(
      color: Colors.grey.shade100,
      child: Column(
        children: [
          // Album Art Placeholder
          Expanded(
            flex: 3,
            child: Container(
              margin: EdgeInsets.all(32.0),
              decoration: BoxDecoration(
                color: Color(0xFF00847E),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(
                Icons.music_note,
                size: 80,
                color: Colors.white,
              ),
            ),
          ),

          // Audio Info
          Expanded(
            flex: 2,
            child: Container(
              padding: EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Text(
                    widget.medienDatei.dateiname,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Audio-Datei',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 32),

                  // Progress Bar
                  _buildProgressBar(),
                  SizedBox(height: 16),

                  // Time Display
                  _buildTimeDisplay(),
                  SizedBox(height: 32),

                  // Controls
                  _buildControls(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        Slider(
          value: _position.inMilliseconds.toDouble(),
          min: 0,
          max: _duration.inMilliseconds.toDouble(),
          activeColor: Color(0xFF00847E),
          inactiveColor: Colors.grey.shade300,
          onChanged: (value) {
            _audioPlayer.seek(Duration(milliseconds: value.toInt()));
          },
        ),
      ],
    );
  }

  Widget _buildTimeDisplay() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _formatDuration(_position),
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
        Text(
          _formatDuration(_duration),
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: Icon(Icons.skip_previous, size: 32),
          onPressed: _previousTrack,
          color: Color(0xFF00847E),
        ),
        Container(
          decoration: BoxDecoration(
            color: Color(0xFF00847E),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              size: 32,
            ),
            onPressed: _togglePlayPause,
            color: Colors.white,
          ),
        ),
        IconButton(
          icon: Icon(Icons.skip_next, size: 32),
          onPressed: _nextTrack,
          color: Color(0xFF00847E),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  void _togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
  }

  void _previousTrack() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Vorheriger Track wird implementiert...'),
        backgroundColor: Color(0xFF00847E),
      ),
    );
  }

  void _nextTrack() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Nächster Track wird implementiert...'),
        backgroundColor: Color(0xFF00847E),
      ),
    );
  }

  void _toggleShuffle() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Shuffle wird implementiert...'),
        backgroundColor: Color(0xFF00847E),
      ),
    );
  }

  void _toggleRepeat() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Repeat wird implementiert...'),
        backgroundColor: Color(0xFF00847E),
      ),
    );
  }

  void _showPlaylist(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Playlist wird implementiert...'),
        backgroundColor: Color(0xFF00847E),
      ),
    );
  }
} 