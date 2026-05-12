import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../routing/app_routes.dart';

class LoginPage extends StatelessWidget {
  // Contrôleurs pour récupérer le texte saisi par l'utilisateur
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    // On crée ou récupère le AuthController pour gérer la connexion
    final AuthController authController = Get.put(AuthController());

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ConstrainedBox(
          // Limite la largeur pour que ça soit joli sur grand écran
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 🔹 Logo de l'application
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
                        'S', // Lettre du logo
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 🔹 Nom de l'application
                const Text(
                  'SUNSPACE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    letterSpacing: 1.5,
                  ),
                ),

                const SizedBox(height: 8),

                // 🔹 Petit texte sous le nom
                Text(
                  'Connexion à votre compte',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),

                const SizedBox(height: 48),

                // 🔹 Champ Email
                const Text('Adresse email',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
                const SizedBox(height: 8),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'vous@exemple.com',
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.mail_outline, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),

                const SizedBox(height: 24),

                // 🔹 Champ Mot de passe
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Mot de passe',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
                    GestureDetector(
                      onTap: () {
                        // TODO: Implémenter la logique de récupération de mot de passe
                        Get.snackbar('Infos', 'Fonctionnalité bientôt disponible',
                            snackPosition: SnackPosition.BOTTOM);
                      },
                      child: const Text(
                        'Mot de passe oublié?',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: passwordController,
                  obscureText: true, // masque le mot de passe
                  decoration: InputDecoration(
                    hintText: '........',
                    hintStyle: const TextStyle(color: Colors.grey, letterSpacing: 2),
                    prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),

                const SizedBox(height: 32),

                // 🔹 Bouton de connexion
                ElevatedButton(
                  onPressed: () async { // BOUTON : Se connecter
                    final email = emailController.text.trim();
                    final password = passwordController.text.trim();

                    // Vérifie que les champs ne sont pas vides
                    if (email.isEmpty || password.isEmpty) {
                      Get.snackbar('Erreur', 'Veuillez remplir tous les champs',
                          snackPosition: SnackPosition.BOTTOM);
                      return;
                    }

                    // Appel de la fonction login dans AuthController
                    final success = await authController.login(email, password);

                    if (success) {
                      // Si connexion réussie, va vers le Dashboard
                      Get.offAllNamed(AppRoutes.DASHBOARD);
                    } else {
                      // Sinon affiche un message d'erreur
                      Get.snackbar('Erreur', 'Email ou mot de passe incorrect',
                          snackPosition: SnackPosition.BOTTOM);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
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
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text('Se connecter',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 20),
                          ],
                        )),
                ),

                const SizedBox(height: 32),

                // 🔹 Lien pour aller à la page d'inscription
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Pas encore de compte? ', style: TextStyle(color: Colors.grey)),
                    GestureDetector(
                      onTap: () => Get.toNamed(AppRoutes.REGISTER), // BOUTON : S'inscrire (Redirection)
                      child: const Text(
                        "S'inscrire",
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
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
}
