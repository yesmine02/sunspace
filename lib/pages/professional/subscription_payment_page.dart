// ============================================
// Page Abonnements & Paiements (Professionnel)
// Redésignée selon les nouvelles maquettes
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../widgets/notification_bell.dart';

class SubscriptionPaymentPage extends StatefulWidget {
  const SubscriptionPaymentPage({super.key});

  @override
  State<SubscriptionPaymentPage> createState() => _SubscriptionPaymentPageState();
}

class _SubscriptionPaymentPageState extends State<SubscriptionPaymentPage> {
  bool isAnnual = false;
  
  // Controllers pour le formulaire
  final nameController = TextEditingController();
  final cardController = TextEditingController();
  final expiryController = TextEditingController();
  final cvcController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    cardController.dispose();
    expiryController.dispose();
    cvcController.dispose();
    super.dispose();
  }

  bool _validateFields() {
    if (nameController.text.isEmpty ||
        cardController.text.isEmpty ||
        expiryController.text.isEmpty ||
        cvcController.text.isEmpty) {
      Get.snackbar('Erreur', 'Veuillez remplir tous les champs', 
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
    if (cardController.text.replaceAll(' ', '').length != 16) {
       Get.snackbar('Erreur', 'Numéro de carte invalide (16 chiffres)', 
          backgroundColor: Colors.red, colorText: Colors.white);
       return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 1100;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. TOP BAR (Search & Notifications)
            _buildTopBar(),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 40, vertical: 40),
              child: Column(
                children: [
                  // 2. HEADER
                  _buildHeader(isMobile),
                  const SizedBox(height: 32),

                  // 3. SWITCH MENSUEL/ANNUEL
                  _buildBillingSwitch(),
                  const SizedBox(height: 48),

                  // 4. PRICING CARDS
                  isMobile
                      ? Column(
                          children: [
                            _buildPlanCard(
                              title: "Starter",
                              description: "Idéal pour les freelances et indépendants",
                              monthlyPrice: "49",
                              annualPrice: "490",
                              savings: "98",
                              icon: Icons.bolt_outlined,
                              features: [
                                "5 jours/mois d'accès coworking",
                                "2 heures de salle de réunion",
                                "Accès Wi-Fi haut débit",
                                "Espace café inclus",
                                "Adresse postale professionnelle",
                              ],
                              secondaryFeatures: ["Support par email"],
                              color: Colors.blue,
                            ),
                            const SizedBox(height: 24),
                            _buildPlanCard(
                              title: "Business",
                              description: "Pour les professionnels actifs",
                              monthlyPrice: "129",
                              annualPrice: "1290",
                              savings: "258",
                              icon: Icons.apartment_outlined,
                              features: [
                                "Accès illimité coworking",
                                "10 heures de salle de réunion",
                                "Accès Wi-Fi haut débit",
                                "Café & boissons illimités",
                                "Adresse postale professionnelle",
                                "Casier personnel sécurisé",
                                "Impression (100 pages/mois)",
                              ],
                              secondaryFeatures: ["Support prioritaire", "Accès formations continues"],
                              isPopular: true,
                              color: const Color(0xFF007AFF),
                            ),
                            const SizedBox(height: 24),
                            _buildPlanCard(
                              title: "Premium",
                              description: "L'expérience coworking complète",
                              monthlyPrice: "249",
                              annualPrice: "2490",
                              savings: "498",
                              icon: Icons.workspace_premium_outlined,
                              features: [
                                "Accès illimité 24h/24 7j/7",
                                "Salles de réunion illimitées",
                                "Wi-Fi fibre dédiée",
                                "Café, thé & snacks illimités",
                                "Adresse postale + domiciliation",
                                "Bureau privé dédié",
                                "Impression illimitée",
                                "Accès à tous les équipements",
                              ],
                              secondaryFeatures: ["Support VIP dédié", "Accès formations continues", "Invités gratuits (2/mois)", "Parking inclus"],
                              isValue: true,
                              color: Colors.orange,
                            ),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildPlanCard(
                              title: "Starter",
                              description: "Idéal pour les freelances et indépendants",
                              monthlyPrice: "49",
                              annualPrice: "490",
                              savings: "98",
                              icon: Icons.bolt_outlined,
                              features: [
                                "5 jours/mois d'accès coworking",
                                "2 heures de salle de réunion",
                                "Accès Wi-Fi haut débit",
                                "Espace café inclus",
                                "Adresse postale professionnelle",
                              ],
                              secondaryFeatures: ["Support par email"],
                              color: Colors.blue,
                            )),
                            const SizedBox(width: 24),
                            Expanded(child: _buildPlanCard(
                              title: "Business",
                              description: "Pour les professionnels actifs",
                              monthlyPrice: "129",
                              annualPrice: "1290",
                              savings: "258",
                              icon: Icons.apartment_outlined,
                              features: [
                                "Accès illimité coworking",
                                "10 heures de salle de réunion",
                                "Accès Wi-Fi haut débit",
                                "Café & boissons illimités",
                                "Adresse postale professionnelle",
                                "Casier personnel sécurisé",
                                "Impression (100 pages/mois)",
                              ],
                              secondaryFeatures: ["Support prioritaire", "Accès formations continues"],
                              isPopular: true,
                              color: const Color(0xFF007AFF),
                            )),
                            const SizedBox(width: 24),
                            Expanded(child: _buildPlanCard(
                              title: "Premium",
                              description: "L'expérience coworking complète",
                              monthlyPrice: "249",
                              annualPrice: "2490",
                              savings: "498",
                              icon: Icons.workspace_premium_outlined,
                              features: [
                                "Accès illimité 24h/24 7j/7",
                                "Salles de réunion illimitées",
                                "Wi-Fi fibre dédiée",
                                "Café, thé & snacks illimités",
                                "Adresse postale + domiciliation",
                                "Bureau privé dédié",
                                "Impression illimitée",
                                "Accès à tous les équipements",
                              ],
                              secondaryFeatures: ["Support VIP dédié", "Accès formations continues", "Invités gratuits (2/mois)", "Parking inclus"],
                              isValue: true,
                              color: Colors.orange,
                            )),
                          ],
                        ),
                  
                  const SizedBox(height: 60),

                  // 5. FOOTER TRUST BADGES
                  Wrap(
                    spacing: 40,
                    runSpacing: 20,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildTrustBadge(Icons.verified_user_outlined, "Paiement 100% sécurisé"),
                      _buildTrustBadge(Icons.check_circle_outline, "Sans engagement"),
                      _buildTrustBadge(Icons.history_outlined, "Annulation à tout moment"),
                      _buildTrustBadge(Icons.receipt_long_outlined, "Facture mensuelle automatique"),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: "Rechercher...",
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          const NotificationBell(iconColor: Color(0xFF1E293B)),
          const SizedBox(width: 20),
          const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFFE2E8F0),
            child: Icon(Icons.person, color: Color(0xFF64748B), size: 20),
          ),
          const SizedBox(width: 8),
          const Text("intern", style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFE0F2FE),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.auto_awesome, color: Color(0xFF007AFF), size: 16),
              SizedBox(width: 8),
              Text("Abonnements Professionnels", style: TextStyle(color: Color(0xFF007AFF), fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          "Choisissez votre espace de travail",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: isMobile ? 28 : 48, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B)),
        ),
        const SizedBox(height: 16),
        Text(
          "Des formules flexibles adaptées à votre activité. Changez ou annulez à tout moment.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: isMobile ? 15 : 18, color: const Color(0xFF64748B), height: 1.5),
        ),
      ],
    );
  }

  Widget _buildBillingSwitch() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Mensuel",
          style: TextStyle(
            fontSize: 16,
            fontWeight: isAnnual ? FontWeight.w500 : FontWeight.w700,
            color: isAnnual ? const Color(0xFF64748B) : const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () => setState(() => isAnnual = !isAnnual),
          child: Container(
            width: 48,
            height: 24,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: const Color(0xFF007AFF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              alignment: isAnnual ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          "Annuel",
          style: TextStyle(
            fontSize: 16,
            fontWeight: isAnnual ? FontWeight.w700 : FontWeight.w500,
            color: isAnnual ? const Color(0xFF1E293B) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            "-17%",
            style: TextStyle(
              color: Color(0xFF166534),
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String description,
    required String monthlyPrice,
    required String annualPrice,
    required String savings,
    required IconData icon,
    required List<String> features,
    required List<String> secondaryFeatures,
    bool isPopular = false,
    bool isValue = false,
    required Color color,
  }) {
    final bool isMobile = MediaQuery.of(context).size.width < 1100;
    final String price = isAnnual ? annualPrice : monthlyPrice;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: isPopular ? Border.all(color: const Color(0xFF007AFF), width: 2) : null,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header of Card
          Padding(
            padding: EdgeInsets.all(isMobile ? 20 : 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: isMobile ? 48 : 56, height: isMobile ? 48 : 56,
                      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                      child: Icon(icon, color: color, size: isMobile ? 24 : 28),
                    ),
                    if (isPopular)
                      _buildBadge("Populaire", const Color(0xFF007AFF)),
                    if (isValue)
                      _buildBadge("Meilleure valeur", const Color(0xFFF97316)),
                  ],
                ),
                const SizedBox(height: 20),
                Text(title, style: TextStyle(fontSize: isMobile ? 24 : 28, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B))),
                const SizedBox(height: 8),
                Text(description, style: TextStyle(color: const Color(0xFF64748B), fontSize: isMobile ? 13 : 14)),
                const SizedBox(height: 32),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(price, style: TextStyle(fontSize: isMobile ? 40 : 48, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B))),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        isAnnual ? "DT / an" : "DT / mois",
                        style: TextStyle(
                          color: const Color(0xFF64748B),
                          fontSize: isMobile ? 14 : 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                if (isAnnual) ...[
                  const SizedBox(height: 8),
                  Text(
                    "Économisez $savings DT/an",
                    style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          const Divider(height: 1),

          // Features
          Padding(
            padding: EdgeInsets.all(isMobile ? 20 : 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...features.map((f) => _buildFeatureItem(f, color)),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 24),
                ...secondaryFeatures.map((f) => _buildSecondaryFeatureItem(f, color)),
                
                const SizedBox(height: 32),

                // Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _showConfirmationDialog(title, price),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPopular ? const Color(0xFF007AFF) : const Color(0xFFE2E8F0),
                      foregroundColor: isPopular ? Colors.white : const Color(0xFF1E293B),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Text("Choisir $title", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildFeatureItem(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, color: color, size: 20),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSecondaryFeatureItem(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(Icons.star_outline_rounded, color: color, size: 20),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 15, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildTrustBadge(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFF10B981), size: 18),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
      ],
    );
  }

  void _showConfirmationDialog(String plan, String price) {
    final bool isMobile = MediaQuery.of(context).size.width < 1100;
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isMobile ? 24 : 32)),
        insetPadding: EdgeInsets.all(isMobile ? 12 : 20),
        child: Container(
          width: isMobile ? double.infinity : 500,
          padding: EdgeInsets.all(isMobile ? 20 : 40),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Confirmer l'abonnement", style: TextStyle(fontSize: isMobile ? 22 : 32, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B))),
                          const SizedBox(height: 8),
                          Text("Plan $plan · $price DT /mois", style: TextStyle(fontSize: isMobile ? 14 : 18, color: const Color(0xFF64748B))),
                        ],
                      ),
                    ),
                    Container(
                      width: isMobile ? 40 : 56, height: isMobile ? 40 : 56,
                      decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(12)),
                      child: Icon(Icons.verified_user_outlined, color: const Color(0xFF007AFF), size: isMobile ? 24 : 32),
                    ),
                  ],
                ),
                SizedBox(height: isMobile ? 24 : 48),

                // Plan Summary Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.bolt_outlined, color: Colors.blue),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(plan, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                            const Text("Facturation mensuelle", style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                          ],
                        ),
                      ),
                      Text("$price DT", style: TextStyle(fontSize: isMobile ? 20 : 28, fontWeight: FontWeight.w900, color: const Color(0xFF007AFF))),
                    ],
                  ),
                ),
                SizedBox(height: isMobile ? 24 : 40),

                // Form
                _buildDialogInputField("NOM SUR LA CARTE", "Jean Dupont", isMobile, controller: nameController),
                const SizedBox(height: 16),
                _buildDialogInputField(
                  "NUMÉRO DE CARTE", 
                  "0000 0000 0000 0000", 
                  isMobile, 
                  icon: Icons.credit_card,
                  controller: cardController,
                  formatters: [CardNumberFormatter()],
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildDialogInputField(
                      "EXPIRATION", 
                      "MM / AA", 
                      isMobile,
                      controller: expiryController,
                      formatters: [CardExpiryFormatter()],
                      keyboardType: TextInputType.number,
                    )),
                    const SizedBox(width: 16),
                    Expanded(child: _buildDialogInputField(
                      "CVC", 
                      "...", 
                      isMobile,
                      controller: cvcController,
                      keyboardType: TextInputType.number,
                      limit: 3,
                    )),
                  ],
                ),
                const SizedBox(height: 24),

                // Payment Icons
                Row(
                  children: [
                    const Icon(Icons.credit_card, size: 24, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 12),
                    const Spacer(),
                    const Text("SSL 256 BITS", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: isMobile ? 32 : 48),

                // Actions
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_validateFields()) {
                            Get.back();
                            Get.snackbar('Succès', 'Abonnement activé avec succès !', backgroundColor: Colors.green, colorText: Colors.white);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7CB9FF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: Text("Payer $price DT", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text("Annuler", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
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

  Widget _buildDialogInputField(
    String label, 
    String placeholder, 
    bool isMobile, {
    IconData? icon,
    TextEditingController? controller,
    List<TextInputFormatter>? formatters,
    TextInputType keyboardType = TextInputType.text,
    int? limit,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 0.5)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          inputFormatters: formatters,
          keyboardType: keyboardType,
          maxLength: limit,
          decoration: InputDecoration(
            counterText: "",
            hintText: placeholder,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
            prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF94A3B8), size: 20) : null,
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF007AFF), width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: isMobile ? 14 : 18),
          ),
        ),
      ],
    );
  }
}

// ============================================
// Formatters pour le Paiement
// ============================================

class CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll(' ', '');
    if (text.length > 16) text = text.substring(0, 16);
    
    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
        buffer.write(text[i]);
        var nonZeroIndex = i + 1;
        if (nonZeroIndex % 4 == 0 && nonZeroIndex != text.length) {
            buffer.write(' ');
        }
    }
    
    var string = buffer.toString();
    return newValue.copyWith(
        text: string,
        selection: TextSelection.collapsed(offset: string.length)
    );
  }
}

class CardExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll('/', '').replaceAll(' ', '');
    if (text.length > 4) text = text.substring(0, 4);
    
    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
        buffer.write(text[i]);
        if (i == 1 && text.length > 2) {
            buffer.write(' / ');
        }
    }
    
    var string = buffer.toString();
    return newValue.copyWith(
        text: string,
        selection: TextSelection.collapsed(offset: string.length)
    );
  }
}
