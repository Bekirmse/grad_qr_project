import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  User? currentUser;
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        DocumentSnapshot userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser!.uid)
                .get();

        if (userDoc.exists && mounted) {
          setState(() {
            userData = userDoc.data() as Map<String, dynamic>;
            isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => isLoading = false);
      }
    }
  }

  void _handleLogout() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  void _deleteAccount() async {
    // 1. Kullanıcıdan onay al
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Account Permanently"),
          content: const Text(
            "This will permanently delete your profile data and your authentication account. This action cannot be undone.",
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text(
                "Delete Everything",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    // 2. Yükleniyor göster
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const Center(
            child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
          ),
    );

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final String uid = user.uid;

        // ADIM A: Firestore'daki 'users' koleksiyonundan dökümanı sil
        // Not: Önce Firestore'u silmek daha iyidir, çünkü Auth silindikten sonra
        // güvenlik kuralları nedeniyle Firestore'a erişiminiz kesilebilir.
        await FirebaseFirestore.instance.collection('users').doc(uid).delete();

        // ADIM B: Firebase Auth üzerindeki hesabı sil
        await user.delete();

        // 3. Başarılı İşlem Sonrası Yönlendirme
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop(); // Loading kapat

          // Tüm geçmişi temizle ve Login'e at
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "All your data and account have been permanently removed.",
              ),
              backgroundColor: Colors.black87,
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();

      // Eğer kullanıcı uzun süredir login ise 'requires-recent-login' hatası verir.
      if (e.code == 'requires-recent-login') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Please log out and log in again to delete your account for security.",
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: ${e.message}")));
      }
    } catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("An unexpected error occurred.")),
      );
    }
  }

  // Privacy Policy Metni
  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            "Privacy Policy",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Last Updated: 2025\n\n"
                  "1. Overview\n"
                  "ScanWiser (\"we\", \"our\", or \"us\") respects your privacy. This Privacy Policy explains how we collect, use, and safeguard your information.\n\n"
                  "2. Data Collection\n"
                  "• Account Information: We collect your name and email address during registration.\n"
                  "• Usage Data: We may process data related to barcodes scanned to provide price comparisons.\n\n"
                  "3. Use of Information\n"
                  "We use data for authenticating users and providing product price comparisons.\n\n"
                  "4. Third-Party Services\n"
                  "We utilize Google Firebase for authentication and database storage.\n\n"
                  "5. Account Deletion\n"
                  "You can delete your account via Profile settings. Your data will be removed permanently.\n\n"
                  "6. Contact\n"
                  "For questions, please contact the development team.",
                  style: TextStyle(fontSize: 14, height: 1.4),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Close",
                style: TextStyle(color: Color(0xFF2E7D32)),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color appGreen = Color(0xFF2E7D32);
    String initial = "U";
    if (userData != null &&
        userData!['name'] != null &&
        userData!['name'].toString().isNotEmpty) {
      initial = userData!['name'][0].toUpperCase();
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("My Profile", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator(color: appGreen))
              : SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // 1. KULLANICI KARTI
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 35,
                            backgroundColor: appGreen.withOpacity(0.1),
                            backgroundImage:
                                (userData != null &&
                                        userData!['profile_image'] != null)
                                    ? NetworkImage(userData!['profile_image'])
                                    : null,
                            child:
                                (userData == null ||
                                        userData!['profile_image'] == null)
                                    ? Text(
                                      initial,
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: appGreen,
                                      ),
                                    )
                                    : null,
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userData?['fullName'] ?? "User",
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  currentUser?.email ?? "no-email@domain.com",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.grey),
                            onPressed: () async {
                              final result = await Navigator.pushNamed(
                                context,
                                '/edit-profile',
                              );
                              if (result == true) _fetchUserData();
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // 2. ACCOUNT
                    _buildSectionTitle("Account"),

                    _buildMenuOption(
                      icon: Icons.lock_outline_rounded,
                      title: "Change Password",
                      subtitle: "Update your password",
                      onTap: () {
                        Navigator.pushNamed(context, '/change-password');
                      },
                    ),

                    _buildMenuOption(
                      icon: Icons.delete_outline_rounded,
                      title: "Delete Account",
                      subtitle: "Permanently remove your data",
                      isDestructive: true,
                      onTap: _deleteAccount, // Yeni fonksiyonumuz burada
                    ),

                    const SizedBox(height: 10),
                    _buildSectionTitle("Legal & About"),

                    _buildMenuOption(
                      icon: Icons.privacy_tip_outlined,
                      title: "Privacy Policy",
                      subtitle: "Terms & Conditions",
                      onTap: () => _showPrivacyPolicy(context),
                    ),

                    _buildMenuOption(
                      icon: Icons.info_outline_rounded,
                      title: "Version",
                      subtitle: "1.0.0",
                      onTap: null,
                      showArrow: false,
                    ),

                    _buildMenuOption(
                      icon: Icons.copyright_rounded,
                      title: "License",
                      subtitle: "©️ 2025 ScanWiser. All rights reserved.",
                      onTap: null,
                      showArrow: false,
                    ),

                    const SizedBox(height: 30),

                    // 3. LOGOUT
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ElevatedButton.icon(
                        onPressed: _handleLogout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFEBEE),
                          foregroundColor: Colors.red[700],
                          elevation: 0,
                          minimumSize: const Size(double.infinity, 55),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.logout),
                        label: const Text(
                          "Log Out",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
    );
  }

  // Yardımcı Widget: Menü Satırı
  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    bool isDestructive = false,
    bool showArrow = true,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDestructive ? Colors.red[50] : const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: isDestructive ? Colors.red : const Color(0xFF2E7D32),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: isDestructive ? Colors.red : Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing:
            showArrow
                ? const Icon(Icons.chevron_right, color: Colors.grey)
                : null,
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, bottom: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
