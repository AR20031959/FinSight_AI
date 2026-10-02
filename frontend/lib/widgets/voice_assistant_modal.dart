import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import '../core/constants.dart';
import 'pdf_report_modal.dart';

class VoiceAssistantModal extends StatefulWidget {
  const VoiceAssistantModal({super.key});

  @override
  State<VoiceAssistantModal> createState() => _VoiceAssistantModalState();
}

class _VoiceAssistantModalState extends State<VoiceAssistantModal> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _isListening = false;
  String _spokenText = "Listening for your financial command...";
  String _aiReplyText = "";

  @override
  void initState() {
    super.initState();
    _initVoice();
  }

  void _initVoice() async {
    bool available = await _speech.initialize();
    if (available) {
      _startListening();
    } else {
      setState(() {
        _spokenText = "Voice recognition initialized. Tap mic to speak.";
      });
    }
  }

  void _startListening() async {
    setState(() {
      _isListening = true;
      _spokenText = "Listening...";
    });
    await _speech.listen(
      onResult: (val) {
        setState(() {
          _spokenText = val.recognizedWords;
        });
        if (val.finalResult) {
          _processCommand(val.recognizedWords);
        }
      },
    );
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() {
      _isListening = false;
    });
  }

  void _processCommand(String text) async {
    _stopListening();
    String reply = "You asked about '$text'. Your monthly spending is on track at ₹75,000 with a health score of 82 out of 100!";
    setState(() {
      _aiReplyText = reply;
    });
    await _tts.speak(reply);
  }

  @override
  void dispose() {
    _speech.cancel();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28.0),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "FinSight Voice Assistant",
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Speak quick queries e.g. 'Show my monthly spending' or 'Can I afford a bike?'",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white60,
            ),
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: _isListening ? _stopListening : _startListening,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isListening ? AppColors.danger : AppColors.primary,
                boxShadow: [
                  BoxShadow(
                    color: (_isListening ? AppColors.danger : AppColors.primary).withOpacity(0.5),
                    blurRadius: 30,
                    spreadRadius: 6,
                  ),
                ],
              ),
              child: Icon(
                _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                size: 40,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _spokenText,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.secondary,
            ),
          ),
          if (_aiReplyText.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _aiReplyText,
                style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
              ),
            ),
          ],
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (ctx) => const PdfReportModal(),
              );
            },
            icon: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.secondary, size: 18),
            label: Text("Generate Date-Range PDF Report", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.secondary),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
