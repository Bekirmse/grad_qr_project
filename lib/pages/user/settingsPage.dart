import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Switch durumlarını tutan değişkenler (Şimdilik göstermelik)
  bool _notificationsEnabled = true;
  bool _priceAlertsEnabled = true;
  bool _darkModeEnabled = false;

  @override
  Widget build(BuildContext context) {
    const Color appGreen = Color(0xFF2E7D32);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Settings", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // --- NOTIFICATIONS SECTION ---
          _buildSectionTitle("Notifications"),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.grey.shade100, blurRadius: 5),
              ],
            ),
            child: Column(
              children: [
                SwitchListTile(
                  activeColor: appGreen,
                  title: const Text(
                    "Push Notifications",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: const Text("Receive daily updates"),
                  value: _notificationsEnabled,
                  onChanged: (val) {
                    setState(() => _notificationsEnabled = val);
                  },
                ),
                Divider(height: 1, color: Colors.grey.shade100),
                SwitchListTile(
                  activeColor: appGreen,
                  title: const Text(
                    "Price Drops",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: const Text("Get alerted when prices go down"),
                  value: _priceAlertsEnabled,
                  onChanged: (val) {
                    setState(() => _priceAlertsEnabled = val);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // --- ACCOUNT SECTION ---
          _buildSectionTitle("Account & Security"),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.grey.shade100, blurRadius: 5),
              ],
            ),
            child: Column(
              children: [
                _buildListTile(
                  icon: Icons.lock_outline,
                  title: "Change Password",
                  onTap: () {
                    // Şifre değiştirme sayfasına veya dialog'una yönlendirme
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Password change flow coming soon..."),
                      ),
                    );
                  },
                ),
                Divider(height: 1, color: Colors.grey.shade100),
                _buildListTile(
                  icon: Icons.privacy_tip_outlined,
                  title: "Privacy Policy",
                  onTap: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // --- APP INFO ---
          Center(
            child: Text(
              "PriceScanner v1.0.0",
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // Yardımcı Widget: Başlıklar
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // Yardımcı Widget: Tıklanabilir Satırlar
  Widget _buildListTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF2E7D32), size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: onTap,
    );
  }
}
