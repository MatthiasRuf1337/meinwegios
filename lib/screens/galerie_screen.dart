import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bilder_provider.dart';
import '../models/bild.dart';
import 'bild_detail_screen.dart';
import 'dart:io';

class GalerieScreen extends StatefulWidget {
  @override
  _GalerieScreenState createState() => _GalerieScreenState();
}

class _GalerieScreenState extends State<GalerieScreen> {
  bool _isGridView = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BilderProvider>(context, listen: false).loadBilder();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Galerie'),
        backgroundColor: Color(0xFF00847E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildStatistics(),
          Expanded(
            child: Consumer<BilderProvider>(
              builder: (context, bilderProvider, child) {
                final bilder = bilderProvider.bilder
                    .where((bild) => bild.dateiname.toLowerCase().contains(_searchQuery.toLowerCase()))
                    .toList();

                if (bilder.isEmpty) {
                  return _buildEmptyState();
                }

                return _isGridView ? _buildGridView(bilder) : _buildListView(bilder);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Bilder durchsuchen...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildStatistics() {
    return Consumer<BilderProvider>(
      builder: (context, bilderProvider, child) {
        final totalBilder = bilderProvider.bilder.length;
                 final bilderMitGPS = bilderProvider.bilder.where((b) => b.hatGPS).length;
        final bilderHeute = bilderProvider.bilder
            .where((b) => b.aufnahmeZeit.isAfter(DateTime.now().subtract(Duration(days: 1))))
            .length;

        return Container(
          padding: EdgeInsets.all(16.0),
          margin: EdgeInsets.symmetric(horizontal: 16.0),
          decoration: BoxDecoration(
            color: Color(0xFF00847E).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Color(0xFF00847E).withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Gesamt', totalBilder.toString(), Icons.photo_library),
              _buildStatItem('Mit GPS', bilderMitGPS.toString(), Icons.location_on),
              _buildStatItem('Heute', bilderHeute.toString(), Icons.today),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Color(0xFF00847E), size: 20),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF00847E),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            'Keine Bilder gefunden',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Nehmen Sie Fotos während Ihrer Etappen auf',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(List<Bild> bilder) {
    return GridView.builder(
      padding: EdgeInsets.all(16.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: bilder.length,
      itemBuilder: (context, index) {
        final bild = bilder[index];
        return _buildImageTile(bild);
      },
    );
  }

  Widget _buildListView(List<Bild> bilder) {
    return ListView.builder(
      padding: EdgeInsets.all(16.0),
      itemCount: bilder.length,
      itemBuilder: (context, index) {
        final bild = bilder[index];
        return _buildImageListTile(bild);
      },
    );
  }

  Widget _buildImageTile(Bild bild) {
    return GestureDetector(
      onTap: () => _openImageDetail(bild),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _buildImageWidget(bild),
        ),
      ),
    );
  }

  Widget _buildImageListTile(Bild bild) {
    return Card(
      margin: EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: Container(
          width: 60,
          height: 60,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _buildImageWidget(bild),
          ),
        ),
        title: Text(
          bild.dateiname,
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
                 subtitle: Text(
           bild.formatierteAufnahmeZeit,
           style: TextStyle(color: Colors.grey.shade600),
         ),
                 trailing: bild.hatGPS
             ? Icon(Icons.location_on, color: Color(0xFF00847E))
             : null,
        onTap: () => _openImageDetail(bild),
      ),
    );
  }

  Widget _buildImageWidget(Bild bild) {
    try {
      final file = File(bild.dateipfad);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholderImage();
          },
        );
      } else {
        return _buildPlaceholderImage();
      }
    } catch (e) {
      return _buildPlaceholderImage();
    }
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey.shade200,
      child: Icon(
        Icons.image,
        color: Colors.grey.shade400,
        size: 32,
      ),
    );
  }

  void _openImageDetail(Bild bild) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BildDetailScreen(bild: bild),
      ),
    );
  }
} 