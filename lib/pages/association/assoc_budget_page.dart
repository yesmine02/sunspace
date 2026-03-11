// ===============================================
// Page Budget & Utilisation (AssocBudgetPage)
// Design premium inspiré de la capture fournie
// ===============================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/booking_controller.dart';
import '../../controllers/payment_controller.dart';

class AssocBudgetPage extends StatefulWidget {
  const AssocBudgetPage({super.key});

  @override
  State<AssocBudgetPage> createState() => _AssocBudgetPageState();
}

class _AssocBudgetPageState extends State<AssocBudgetPage> {
  // Filtre de période pour le graphique d'activité
  String _selectedPeriod = 'Derniers 3 mois';
  final List<String> _periodOptions = ['Derniers 3 mois', 'Année 2026'];

  // Données fictives des mois
  static const _months3  = ['Jan', 'Fév', 'Mar'];
  static const _values3  = [0.4, 0.7, 0.3];
  static const _months12 = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
  static const _values12 = [0.4, 0.7, 0.3, 0.5, 0.6, 0.45, 0.8, 0.55, 0.35, 0.65, 0.5, 0.4];

  @override
  Widget build(BuildContext context) {
    final bookingController = Get.put(BookingController());
    final paymentController = Get.put(PaymentController());

    final bool isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16.0 : 32.0,
          vertical: isMobile ? 24.0 : 36.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── EN-TÊTE ──────────────────────────────────
            _buildHeader(context, isMobile),
            const SizedBox(height: 28),

            // ─── 3 GRANDES CARDS ──────────────────────────
            _buildTopCards(isMobile),
            const SizedBox(height: 28),

            // ─── ACTIVITÉ MENSUELLE + JOURNAL ─────────────
            isMobile
                ? Column(
                    children: [
                      _buildActivityCard(paymentController, isMobile),
                      const SizedBox(height: 20),
                      _buildJournalCard(paymentController, isMobile),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildActivityCard(paymentController, isMobile)),
                      const SizedBox(width: 24),
                      Expanded(child: _buildJournalCard(paymentController, isMobile)),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // EN-TÊTE : Titre + Bouton Ajuster le solde
  // ─────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, bool isMobile) {
    final titleSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BUDGET & UTILISATION',
          style: TextStyle(
            fontSize: isMobile ? 22 : 28,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF0F172A),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Gérez vos fonds et suivez la consommation d\'heures de votre association.',
          style: TextStyle(
            color: const Color(0xFF64748B),
            fontSize: isMobile ? 13 : 14,
            height: 1.5,
          ),
        ),
      ],
    );

    final addButton = ElevatedButton.icon(
      onPressed: () => _showAdjustBalanceDialog(context),
      icon: const Icon(Icons.add_rounded, size: 18),
      label: const Text(
        'AJUSTER LE SOLDE',
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
      ),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleSection,
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: addButton),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: titleSection),
        const SizedBox(width: 24),
        addButton,
      ],
    );
  }

  // ─────────────────────────────────────────────
  // 3 CARDS SUPÉRIEURES
  // ─────────────────────────────────────────────
  Widget _buildTopCards(bool isMobile) {
    if (isMobile) {
      return Column(
        children: [
          _buildSoldeCard(isMobile),
          const SizedBox(height: 16),
          _buildConsommationCard(isMobile),
          const SizedBox(height: 16),
          _buildEconomiesCard(isMobile),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: _buildSoldeCard(isMobile)),
        const SizedBox(width: 20),
        Expanded(child: _buildConsommationCard(isMobile)),
        const SizedBox(width: 20),
        Expanded(child: _buildEconomiesCard(isMobile)),
      ],
    );
  }

  // Card 1 : Solde actuel
  Widget _buildSoldeCard(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'SOLDE ACTUEL',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF2563EB), size: 20),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            '68,000 TND',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Fonds disponibles pour vos réservations',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  // Card 2 : Consommation heures
  Widget _buildConsommationCard(bool isMobile) {
    const int used = 0;
    const int total = 200;
    final double progress = used / total;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'CONSOMMATION',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.access_time_rounded, color: Color(0xFF2563EB), size: 20),
              ),
            ],
          ),
          const SizedBox(height: 20),
          RichText(
            text: const TextSpan(
              style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900),
              children: [
                TextSpan(text: '${used}h', style: TextStyle(fontSize: 28)),
                TextSpan(text: ' /${total}h', style: TextStyle(fontSize: 16, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
            ),
          ),
        ],
      ),
    );
  }

  // Card 3 : Économies
  Widget _buildEconomiesCard(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ÉCONOMIES',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bar_chart_rounded, color: Color(0xFF16A34A), size: 20),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            '0,000 TND',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Grâce aux tarifs préférentiels Sunspace',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // ACTIVITÉ MENSUELLE
  // ─────────────────────────────────────────────
  Widget _buildActivityCard(PaymentController controller, bool isMobile) {
    final months = _selectedPeriod == 'Derniers 3 mois' ? _months3  : _months12;
    final values = _selectedPeriod == 'Derniers 3 mois' ? _values3  : _values12;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ACTIVITÉ MENSUELLE',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: 0.5,
                ),
              ),
              // ─── Menu déroulant fonctionnel ───
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedPeriod,
                    isDense: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF475569)),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                    items: _periodOptions.map((option) {
                      return DropdownMenuItem(
                        value: option,
                        child: Text(option.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedPeriod = val);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ─── Graphique à barres ───
          _buildMiniBarChart(months, values),
          const SizedBox(height: 24),

          // Légendes résumé
          Row(
            children: [
              _buildLegendItem('Dépenses', '1 240 TND', const Color(0xFF2563EB)),
              const SizedBox(width: 24),
              _buildLegendItem('Économies', '0 TND', const Color(0xFF16A34A)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBarChart(List<String> months, List<double> values) {
    return SizedBox(
      height: 100,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(months.length, (i) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: months.length > 6 ? 3 : 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height: 80 * values[i],
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withOpacity(0.15 + values[i] * 0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    months[i],
                    style: TextStyle(
                      fontSize: months.length > 6 ? 9 : 11,
                      color: const Color(0xFF94A3B8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildLegendItem(String label, String value, Color color) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          ],
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // JOURNAL FINANCIER
  // ─────────────────────────────────────────────
  Widget _buildJournalCard(PaymentController controller, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'JOURNAL FINANCIER',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: 0.5,
                ),
              ),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.filter_alt_outlined, size: 16, color: Color(0xFF475569)),
                label: const Text('Tout voir', style: TextStyle(color: Color(0xFF475569), fontSize: 13, fontWeight: FontWeight.w600)),
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Obx(() {
            if (controller.isLoading.value && controller.payments.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator(color: Color(0xFF2563EB))),
              );
            }

            if (controller.payments.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey[200]),
                      const SizedBox(height: 12),
                      const Text('Aucune transaction', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
                    ],
                  ),
                ),
              );
            }

            final items = controller.payments.take(5).toList();
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (ctx, i) {
                final payment = items[i];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.red[50], shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_upward_rounded, color: Color(0xFFEF4444), size: 18),
                  ),
                  title: Text(payment.relatedType, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                  subtitle: Text(payment.formattedDate, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                  trailing: Text(
                    '- ${payment.amount} TND',
                    style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFEF4444), fontSize: 14),
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // UTILITAIRES
  // ─────────────────────────────────────────────
  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE2E8F0)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  void _showAdjustBalanceDialog(BuildContext context) {
    final TextEditingController amountCtrl = TextEditingController();
    // State for the dialog: true for "Ajouter", false for "Retirer"
    bool isAdding = true;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: StatefulBuilder( // Use StatefulBuilder to manage dialog's internal state
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              width: 400,
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('GESTION DU SOLDE', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.close)),
                    ],
                  ),
                  const Divider(height: 28),

                  // Ajouter / Retirer Toggle
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => isAdding = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isAdding ? const Color(0xFF2563EB) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Ajouter',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isAdding ? Colors.white : const Color(0xFF475569),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => isAdding = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !isAdding ? const Color(0xFF2563EB) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Retirer',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: !isAdding ? Colors.white : const Color(0xFF475569),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // MONTANT field
                  const Text('MONTANT (TND)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF475569))),
                  const SizedBox(height: 10),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: 'Ex: 5000',
                      prefixText: 'TND ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Quick amount chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['10', '50', '100'].map((amount) {
                      return GestureDetector(
                        onTap: () => setState(() {
                          amountCtrl.text = amount;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Text(
                            '$amount TND',
                            style: const TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Get.back(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Annuler', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Get.back();
                            Get.snackbar('Succès', 'Solde ajusté avec succès.',
                              backgroundColor: const Color(0xFFDCFCE7),
                              colorText: const Color(0xFF166534),
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('VALIDER', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
