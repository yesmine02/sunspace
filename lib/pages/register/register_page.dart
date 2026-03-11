import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../routing/app_routes.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // 🔹 Contrôleurs pour récupérer le texte saisi
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  // 🔹 Booléen pour savoir si l'utilisateur a accepté les conditions
  bool _acceptTerms = false;

  @override
  Widget build(BuildContext context) {
    // 🔹 Récupération ou création du AuthController
    final AuthController authController = Get.put(AuthController());

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ConstrainedBox(
          // 🔹 Limite la largeur pour que ça reste joli sur grand écran
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                // 🔷 LOGO IDENTIQUE AU LOGIN
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade400, Colors.blue.shade200],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: Text(
                        'S',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 🔹 Titre "Créer votre compte"
                const Center(
                  child: Text(
                    'Créer votre compte',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 40),

                // 🔹 Champ Nom d'utilisateur
                _buildLabel('Nom d\'utilisateur'),
                _buildTextField(usernameController, 'Jean Dupont', Icons.person_outline),
                const SizedBox(height: 20),

                // 🔹 Champ Email
                _buildLabel('Adresse email'),
                _buildTextField(emailController, 'vous@exemple.com', Icons.mail_outline),
                const SizedBox(height: 20),

                // 🔹 Champ Mot de passe
                _buildLabel('Mot de passe'),
                _buildTextField(passwordController, '........', Icons.lock_outline, obscureText: true),
                const SizedBox(height: 20),

                // 🔹 Champ Confirmer le mot de passe
                _buildLabel('Confirmer le mot de passe'),
                _buildTextField(confirmPasswordController, '........', Icons.lock_outline, obscureText: true),
                const SizedBox(height: 24),

                // 🔹 Checkbox pour accepter les conditions
                Row(
                  children: [
                    Checkbox(
                      value: _acceptTerms,
                      onChanged: (val) => setState(() => _acceptTerms = val ?? false),
                    ),
                    const Expanded(
                      child: Text(
                        'J\'accepte les conditions d\'utilisation',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // 🔹 Bouton "S'inscrire"
                ElevatedButton(
                  onPressed: () async {
                    // 🔹 Vérifications avant de lancer l'inscription
                    if (usernameController.text.isEmpty ||
                        emailController.text.isEmpty ||
                        passwordController.text.isEmpty ||
                        confirmPasswordController.text.isEmpty) {
                      Get.snackbar('Erreur', 'Veuillez remplir tous les champs');
                      return;
                    }

                    if (passwordController.text != confirmPasswordController.text) {
                      Get.snackbar('Erreur', 'Les mots de passe ne correspondent pas');
                      return;
                    }

                    if (!_acceptTerms) {
                      Get.snackbar('Erreur', 'Veuillez accepter les conditions');
                      return;
                    }

                    // 🔹 Appel de la fonction register du AuthController
                    final success = await authController.register(
                      usernameController.text.trim(),
                      emailController.text.trim(),
                      passwordController.text.trim(),
                    );

                    // 🔹 Si inscription réussie, redirection vers Login
                    if (success) {
                      Get.offAllNamed(AppRoutes.LOGIN);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Obx(() => authController.isLoading.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "S'inscrire",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        )),
                ),

                const SizedBox(height: 32),

                // 🔹 Divider "Ou"
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[300])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Ou', style: TextStyle(color: Colors.grey[600])),
                    ),
                    Expanded(child: Divider(color: Colors.grey[300])),
                  ],
                ),
                const SizedBox(height: 32),

                // 🔹 Lien vers la page de connexion
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Déjà inscrit? ', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    GestureDetector(
                      onTap: () => Get.offAllNamed(AppRoutes.LOGIN),
                      child: const Text(
                        'Se connecter',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
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

  // 🔹 Fonction pour créer un label
  Widget _buildLabel(String text) =>
      Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14));

  // 🔹 Fonction pour créer un champ texte avec icône
  Widget _buildTextField(
    TextEditingController controller,
    String hintText,
    IconData icon, {
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText, // Masque le texte si c'est un mot de passe
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }
}
