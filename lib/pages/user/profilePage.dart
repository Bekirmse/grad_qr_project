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

  // Fetch user data from Firebase
  Future<void> _fetchUserData() async {
    currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      try {
        DocumentSnapshot userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser!.uid)
                .get();

        if (userDoc.exists) {
          if (mounted) {
            setState(() {
              userData = userDoc.data() as Map<String, dynamic>;
              isLoading = false;
            });
          }
        } else {
          if (mounted) setState(() => isLoading = false);
        }
      } catch (e) {
        debugPrint("Error fetching profile data: $e");
        if (mounted) setState(() => isLoading = false);
      }
    }
  }

  // Logout Function
  void _handleLogout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Theme Color (App Green)
    const Color appGreen = Color(0xFF2E7D32);

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
                    // 1. USER CARD (Header)
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
                          // Profile Picture (Avatar)
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
                                      userData != null &&
                                              userData!['name'] != null
                                          ? userData!['name'][0].toUpperCase()
                                          : "U",
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: appGreen,
                                      ),
                                    )
                                    : null,
                          ),
                          const SizedBox(width: 20),
                          // Name and Email
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userData?['name'] ?? "User",
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
                          // Edit Icon
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.grey),
                            onPressed: () async {
                              final result = await Navigator.pushNamed(
                                context,
                                '/edit-profile',
                              );
                              if (result == true) {
                                _fetchUserData(); // Refresh if updated
                              }
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // 2. MENU LIST
                    _buildSectionTitle("Account Settings"),
                    _buildMenuOption(
                      icon: Icons.history,
                      title: "Scan History",
                      subtitle: "See your recent product scans",
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("History Page Coming Soon..."),
                          ),
                        );
                      },
                    ),
                    _buildMenuOption(
                      icon: Icons.favorite_border,
                      title: "Saved Items",
                      subtitle: "Your price alerts & favorites",
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Favorites Page Coming Soon..."),
                          ),
                        );
                      },
                    ),
                    _buildMenuOption(
                      icon: Icons.settings_outlined,
                      title: "App Settings",
                      subtitle: "Notifications & Security",
                      onTap: () {
                        Navigator.pushNamed(context, '/settings');
                      },
                    ),

                    const SizedBox(height: 20),
                    _buildSectionTitle("Support"),
                    _buildMenuOption(
                      icon: Icons.help_outline,
                      title: "Help & FAQ",
                      subtitle: "Everything you need to know",
                      onTap: () {
                        showDialog(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                title: const Text("Help"),
                                content: const Text(
                                  "For support, please contact:\nsupport@pricescanner.com",
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("OK"),
                                  ),
                                ],
                              ),
                        );
                      },
                    ),

                    const SizedBox(height: 30),

                    // 3. LOGOUT BUTTON
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

  // Helper Widget: Menu Row
  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
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
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF2E7D32)),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }

  // Helper Widget: Section Title
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
