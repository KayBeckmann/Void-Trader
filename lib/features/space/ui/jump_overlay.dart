import 'package:flutter/material.dart';

class JumpOverlay extends StatefulWidget {
  final String targetSystem;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const JumpOverlay({
    super.key,
    required this.targetSystem,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<JumpOverlay> createState() => _JumpOverlayState();
}

class _JumpOverlayState extends State<JumpOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: Material(
        color: Colors.black.withValues(alpha: 0.72),
        child: Center(
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF0D0D2B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF7C4DFF), width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.blur_on, color: Color(0xFF7C4DFF), size: 48),
                const SizedBox(height: 16),
                const Text(
                  'SPRUNGTOR',
                  style: TextStyle(
                    color: Color(0xFFCE93D8),
                    fontSize: 12,
                    letterSpacing: 4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '→ ${widget.targetSystem.toUpperCase()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: widget.onCancel,
                      child: const Text(
                        'ABBRUCH',
                        style: TextStyle(color: Color(0xFF90A4AE)),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C4DFF),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: widget.onConfirm,
                      child: const Text('SPRINGEN'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
