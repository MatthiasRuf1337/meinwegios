import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class MediathekLoginScreen extends StatefulWidget {
  @override
  _MediathekLoginScreenState createState() => _MediathekLoginScreenState();
}

class _MediathekLoginScreenState extends State<MediathekLoginScreen> {
  final TextEditingController _pinController = TextEditingController();
  final List<TextEditingController> _digitControllers =
      List.generate(4, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());

  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _pinController.dispose();
    for (var controller in _digitControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF5A7D7D).withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Header
                _buildHeader(),
                SizedBox(height: 48),

                // PIN Eingabe
                _buildPINInput(),
                SizedBox(height: 24),

                // Fehlermeldung
                if (_errorMessage.isNotEmpty) _buildErrorMessage(),

                SizedBox(height: 32),

                // Login Button
                _buildLoginButton(),
                SizedBox(height: 16),

                // Info Text
                _buildInfoText(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Color(0xFF5A7D7D),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.lock,
            size: 40,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 16),
        Text(
          'Mediathek-Zugriff',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5A7D7D),
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Bitte gib deinen PIN-Code ein',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildPINInput() {
    return Column(
      children: [
        Text(
          'PIN-Code',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(4, (index) {
            return Container(
              width: 60,
              height: 60,
              child: TextField(
                controller: _digitControllers[index],
                focusNode: _focusNodes[index],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(1),
                ],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFF5A7D7D), width: 2),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (value) {
                  if (value.isNotEmpty && index < 3) {
                    _focusNodes[index + 1].requestFocus();
                  }
                  _updatePIN();
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, color: Colors.red, size: 16),
          SizedBox(width: 8),
          Text(
            _errorMessage,
            style: TextStyle(
              color: Colors.red.shade700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _validatePIN,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF5A7D7D),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Anmelden',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildInfoText() {
    return Text(
      'Standard PIN: 1234',
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey.shade500,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  void _updatePIN() {
    String pin = '';
    for (var controller in _digitControllers) {
      pin += controller.text;
    }
    _pinController.text = pin;
  }

  Future<void> _validatePIN() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    // Simuliere Netzwerk-Verzögerung
    await Future.delayed(Duration(milliseconds: 500));

    final settingsProvider =
        Provider.of<SettingsProvider>(context, listen: false);
    final enteredPIN = _pinController.text;

    if (settingsProvider.validateMediathekPIN(enteredPIN)) {
      // Erfolgreiche Anmeldung
      await settingsProvider.setLastMediathekLogin(DateTime.now());

      // PIN-Felder zurücksetzen
      for (var controller in _digitControllers) {
        controller.clear();
      }
      _focusNodes[0].requestFocus();
    } else {
      // Fehlgeschlagene Anmeldung
      setState(() {
        _errorMessage = 'Falscher PIN-Code. Bitte versuche es erneut.';
      });

      // PIN-Felder zurücksetzen
      for (var controller in _digitControllers) {
        controller.clear();
      }
      _focusNodes[0].requestFocus();
    }

    setState(() {
      _isLoading = false;
    });
  }
}
