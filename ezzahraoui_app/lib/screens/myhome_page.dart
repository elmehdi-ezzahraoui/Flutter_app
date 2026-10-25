import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_design.dart';
import 'chatbot_page.dart';
import 'map_page.dart';

// Définition de la page de profil utilisateur (Widget sans état)
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  // Fonction utilitaire pour copier du texte dans le presse-papiers et afficher une notification (SnackBar)
  void _copy(BuildContext context, String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copié'),
        backgroundColor: kPrimaryDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Permet au contenu de passer derrière l'AppBar transparente
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Mon Profil',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.location_on_rounded, color: Colors.white),
              tooltip: 'Ma Position (Google Maps)',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MapPage()),
                );
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.smart_toy_rounded, color: Colors.white),
              tooltip: 'Assistant Chatbot IA',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChatbotPage()),
                );
              },
            ),
          ),
        ],
      ),
      // Corps de la page avec défilement vertical
      body: SingleChildScrollView(
        child: Column(
          children: [
            // En-tête affichant la photo, le nom et le sous-titre (ex: Étudiant)
            const HeaderWidget(
              imagePath: 'assets/image.webp',
              title: 'EZ-ZAHRAOUI El-Mehdi',
              subtitle: 'Étudiant en Génie Informatique',
              imageSize: 150,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 24),
            // Animation d'entrée pour la section des informations personnelles
            AnimatedEntry(
              delay: 200,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre de la section
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 12),
                      child: Text(
                        'INFORMATIONS PERSONNELLES',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                    // Carte pour le Nom
                    const InfoCard(
                      icon: Icons.badge_outlined,
                      label: 'Nom',
                      value: 'EZ-ZAHRAOUI',
                    ),
                    // Carte pour le Prénom
                    const InfoCard(
                      icon: Icons.person_outline,
                      label: 'Prénom',
                      value: 'El-Mehdi',
                    ),
                    // Carte pour l'Email (avec option de copie au clic)
                    InfoCard(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: 'mehdiezzahraoui35@gmail.com',
                      copyable: true,
                      onTap: () => _copy(
                        context,
                        'mehdiezzahraoui35@gmail.com',
                        'Email',
                      ),
                    ),
                    // Carte pour le Téléphone (avec option de copie au clic)
                    InfoCard(
                      icon: Icons.phone_outlined,
                      label: 'Téléphone',
                      value: '0694631607',
                      copyable: true,
                      onTap: () => _copy(context, '0694631607', 'Téléphone'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
