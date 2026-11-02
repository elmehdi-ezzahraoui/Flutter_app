import 'package:flutter/material.dart';

// --- Couleurs Globales (Thème EcoCity) ---
const kPrimary = Color(0xFF059669);      // Vert Émeraude principal
const kPrimaryDark = Color(0xFF064E3B);  // Vert Forêt profond
const kAccent = Color(0xFF10B981);       // Vert menthe éclatant
const kBackground = Color(0xFFF9FAFB);   // Fond clair épuré

// --- Animation d'entrée ---
class AnimatedEntry extends StatelessWidget {
  final Widget child;
  final int delay;

  const AnimatedEntry({super.key, required this.child, this.delay = 0});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 24 * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

// --- En-tête EcoCity avec Logo / Avatar ---
class HeaderWidget extends StatelessWidget {
  final String? imagePath;
  final String title;
  final String subtitle;
  final double imageSize;
  final BoxFit fit;

  const HeaderWidget({
    super.key,
    this.imagePath,
    required this.title,
    required this.subtitle,
    this.imageSize = 100,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 24,
        bottom: 28,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF064E3B), Color(0xFF059669)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x33059669),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: AnimatedEntry(
        child: Column(
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.18),
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Text('🌿', style: TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'EcoCity',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// --- Carte d'Information Réutilisable ---
class InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool big;
  final bool copyable;
  final VoidCallback? onTap;

  const InfoCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.big = false,
    this.copyable = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kPrimary.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        kPrimary.withOpacity(0.15),
                        kAccent.withOpacity(0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: kPrimary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 3),
                      big
                          ? ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [kPrimary, kAccent],
                              ).createShader(bounds),
                              child: Text(
                                value,
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              value,
                              style: const TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF111827),
                              ),
                            ),
                    ],
                  ),
                ),
                if (copyable)
                  const Icon(
                    Icons.copy_rounded,
                    size: 18,
                    color: Color(0xFF9CA3AF),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
