import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../data/models/course.dart';
import '../../../controllers/courses_controller.dart'; // Import manquant

class SecurePaymentDialog extends StatelessWidget {
  final Course course;

  const SecurePaymentDialog({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 700;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: 600,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 40, offset: const Offset(0, 20)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 🔷 HEADER
            _buildHeader(context),

            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 24 : 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔷 AMOUNT & CARTE BOX
                    _buildTopSection(isMobile),
                    const SizedBox(height: 32),

                    // 🔷 FORM FIELDS
                    _buildTextField("NOM SUR LA CARTE", "M. Jean Dupont"),
                    const SizedBox(height: 24),
                    _buildTextField(
                      "NUMÉRO DE CARTE", 
                      "0000 0000 0000 0000", 
                      icon: Icons.credit_card_rounded,
                      keyboardType: TextInputType.number,
                      maxLength: 16,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(
                          "EXPIRATION", 
                          "MM/AA", 
                          maxLength: 5, 
                          keyboardType: TextInputType.number,
                          inputFormatters: [ExpirationDateFormatter()],
                        )),
                        const SizedBox(width: 24),
                        Expanded(child: _buildTextField(
                          "CVC", 
                          "***", 
                          keyboardType: TextInputType.number, 
                          maxLength: 3,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        )),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // 🔷 FOOTER BANNER
                    _buildFooterBanner(isMobile),
                    const SizedBox(height: 48),

                    // 🔷 PAY BUTTON
                    _buildPayButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24), // Reduced padding for mobile
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "PAIEMENT SÉCURISÉ",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5),
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                    children: [
                      const TextSpan(text: "Inscription : "),
                      TextSpan(
                        text: course.title,
                        style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF007AFF)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
             width: 48,
             height: 48,
             decoration: BoxDecoration(
               color: const Color(0xFFDBEAFE).withOpacity(0.5),
               borderRadius: BorderRadius.circular(12),
             ),
             child: const Icon(Icons.shield_rounded, color: Color(0xFF007AFF), size: 24),
          ),
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSection(bool isMobile) {
    final bool stackLayout = isMobile;

    if (stackLayout) {
      return Column(
        children: [
          _buildAmountBox(),
          const SizedBox(height: 20),
          _buildCardBox(),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 1, child: _buildAmountBox()),
        const SizedBox(width: 20),
        Expanded(flex: 1, child: _buildCardBox()),
      ],
    );
  }

  Widget _buildAmountBox() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("MONTANT À RÉGLER", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 1.0)),
          const SizedBox(height: 12),
          Text(
            "${course.price.toInt()} DT",
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF007AFF)),
          ),
        ],
      ),
    );
  }

  Widget _buildCardBox() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF007AFF), width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFF007AFF), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.credit_card_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Carte Bancaire", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                Text("VISA, MASTERCARD", style: TextStyle(fontSize: 10, color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const Icon(Icons.radio_button_checked_rounded, color: Color(0xFF007AFF), size: 20),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String hint, {
    IconData? icon, 
    TextInputType keyboardType = TextInputType.text, 
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF475569), letterSpacing: 0.5),
        ),
        const SizedBox(height: 12),
        TextField(
          maxLength: maxLength,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
          decoration: InputDecoration(
            counterText: "", // Masquer le compteur de caractères
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontWeight: FontWeight.w500),
            prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF94A3B8), size: 20) : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF007AFF), width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterBanner(bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.credit_card_rounded, color: Color(0xFFEF4444), size: 20),
          const SizedBox(width: 8),
          const Icon(Icons.credit_card_rounded, color: Color(0xFF2563EB), size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              "PAIEMENT SÉCURISÉ SSL 256 BITS",
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 0.5),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton() {
    return ElevatedButton(
      onPressed: () async {
        final controller = Get.find<CoursesController>();
        final success = await controller.enrollInCourse(course);
        
        if (success) {
          Get.back();
          Get.snackbar(
            "Succès", 
            "Félicitations ! Vous êtes inscrit au cours ${course.title}", 
            backgroundColor: const Color(0xFF10B981), 
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP,
          );
        } else {
          Get.snackbar(
            "Erreur", 
            "Échec de l'inscription. Veuillez réessayer.", 
            backgroundColor: Colors.redAccent, 
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP,
          );
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF007AFF),
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 64),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
      ),
      child: const Text("Confirmer le paiement", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
    );
  }
}

// 🔷 FORMATEUR POUR DATE D'EXPIRATION (MM/AA)
class ExpirationDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;

    if (newValue.selection.baseOffset == 0) return newValue;

    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      // Garder uniquement les chiffres
      if (RegExp(r'[0-9]').hasMatch(text[i])) {
        buffer.write(text[i]);
        
        // Ajouter le slash après le mois (position 2)
        final nonSlashText = buffer.toString().replaceFirst('/', '');
        if (nonSlashText.length == 2 && !buffer.toString().contains('/')) {
          // Valider le mois complet (01-12)
          int month = int.parse(nonSlashText);
          if (month > 12 || month == 0) return oldValue; // Bloquer si invalide
          buffer.write('/');
        }
      }
    }

    final string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}
