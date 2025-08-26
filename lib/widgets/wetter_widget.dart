import 'package:flutter/material.dart';
import '../models/wetter_daten.dart';

class WetterWidget extends StatelessWidget {
  final WetterDaten? wetterDaten;
  final bool isLoading;
  final String? errorMessage;
  final bool compact;
  final VoidCallback? onRefresh;

  const WetterWidget({
    Key? key,
    this.wetterDaten,
    this.isLoading = false,
    this.errorMessage,
    this.compact = false,
    this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingWidget();
    }

    if (errorMessage != null) {
      return _buildErrorWidget(context);
    }

    if (wetterDaten == null) {
      return _buildNoDataWidget(context);
    }

    return compact ? _buildCompactWidget(context) : _buildFullWidget(context);
  }

  Widget _buildLoadingWidget() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF45A173)),
            ),
          ),
          SizedBox(width: 12),
          Text(
            'Wetterdaten werden geladen...',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.red.shade600,
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              errorMessage!,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 14,
              ),
            ),
          ),
          if (onRefresh != null)
            IconButton(
              icon: Icon(Icons.refresh, size: 20),
              onPressed: onRefresh,
              color: Colors.red.shade600,
            ),
        ],
      ),
    );
  }

  Widget _buildNoDataWidget(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(
            Icons.cloud_off,
            color: Colors.grey.shade500,
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Keine Wetterdaten verfügbar',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          if (onRefresh != null)
            IconButton(
              icon: Icon(Icons.refresh, size: 20),
              onPressed: onRefresh,
              color: Colors.grey.shade600,
            ),
        ],
      ),
    );
  }

  Widget _buildCompactWidget(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Color(0xFF45A173).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFF45A173).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            wetterDaten!.wetterEmoji,
            style: TextStyle(fontSize: 14),
          ),
          SizedBox(width: 6),
          Text(
            wetterDaten!.formatierteTemperatur,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF45A173),
            ),
          ),
          if (onRefresh != null) ...[
            SizedBox(width: 6),
            GestureDetector(
              onTap: onRefresh,
              child: Icon(
                Icons.refresh,
                size: 16,
                color: Color(0xFF45A173).withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFullWidget(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF45A173).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF45A173).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header mit Emoji und Temperatur
          Row(
            children: [
              Text(
                wetterDaten!.wetterEmoji,
                style: TextStyle(fontSize: 32),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wetterDaten!.formatierteTemperatur,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF45A173),
                      ),
                    ),
                    Text(
                      wetterDaten!.beschreibung,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    if (wetterDaten!.ort != null)
                      Text(
                        wetterDaten!.ort!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
              if (onRefresh != null)
                IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: onRefresh,
                  color: Color(0xFF45A173),
                ),
            ],
          ),

          SizedBox(height: 16),

          // Nur die wichtigsten Details
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  Icons.thermostat,
                  'Gefühlt',
                  wetterDaten!.formatierteGefuehlteTemperatur,
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  Icons.air,
                  'Wind',
                  wetterDaten!.formatierteWindgeschwindigkeit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: Colors.grey.shade600,
            ),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }
}

class WetterWarnungWidget extends StatelessWidget {
  final String warnung;

  const WetterWarnungWidget({
    Key? key,
    required this.warnung,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange.shade700,
            size: 20,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              warnung,
              style: TextStyle(
                color: Colors.orange.shade800,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
