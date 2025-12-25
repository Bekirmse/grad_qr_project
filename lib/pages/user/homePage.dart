// ignore: duplicate_ignore
// ignore: file_names
// ignore_for_file: file_names

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:grad_qr_project/pages/user/resultPage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final User? user = FirebaseAuth.instance.currentUser;
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = "All";

  Future<String> _fetchUserName() async {
    if (user == null) return "Guest";
    try {
      DocumentSnapshot doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user!.uid)
              .get();
      if (doc.exists && doc.data() != null) {
        return doc.get('fullName') ?? "User";
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error: $e");
      }
    }
    return user?.email?.split('@')[0] ?? "User";
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      Navigator.pushNamed(context, '/scan');
    } else if (index == 2)
      // ignore: curly_braces_in_flow_control_structures
      Navigator.pushNamed(context, '/profile');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'PriceScanner',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationPage(),
                  ),
                ),
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Colors.black87,
              size: 28,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KULLANICI KARTI
            FutureBuilder<String>(
              future: _fetchUserName(),
              builder: (context, snapshot) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        // ignore: deprecated_member_use
                        color: const Color(0xFF2E7D32).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, ${snapshot.data ?? "Loading..."}!',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Ready to find the best deals today?',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          // ignore: deprecated_member_use
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // KATEGORİLER
            SizedBox(
              height: 40,
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('categories')
                        .orderBy('name')
                        .snapshots(),
                builder: (context, snapshot) {
                  List<String> cats = ["All"];
                  if (snapshot.hasData)
                    // ignore: curly_braces_in_flow_control_structures
                    for (var d in snapshot.data!.docs) {
                      cats.add(d['name']);
                    }

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: cats.length,
                    itemBuilder: (context, index) {
                      final category = cats[index];
                      final isSelected = _selectedCategory == category;
                      return GestureDetector(
                        onTap:
                            () => setState(() => _selectedCategory = category),
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? const Color(0xFF2E7D32)
                                    : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color:
                                  isSelected
                                      ? const Color(0xFF2E7D32)
                                      : Colors.grey.shade300,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              category,
                              style: TextStyle(
                                color:
                                    isSelected
                                        ? Colors.white
                                        : Colors.grey[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // ARAMA ÇUBUĞU
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() {}),
                decoration: InputDecoration(
                  hintText: "Search in $_selectedCategory...",
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF2E7D32),
                  ),
                  suffixIcon:
                      _searchController.text.isNotEmpty
                          ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed:
                                () => setState(() => _searchController.clear()),
                          )
                          : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // POPÜLER ÜRÜNLER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Popular Products',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AllProductsPage(),
                        ),
                      ),
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ÜRÜN LİSTESİ
            StreamBuilder<QuerySnapshot>(
              stream:
                  _selectedCategory == "All"
                      ? FirebaseFirestore.instance
                          .collection('products')
                          .limit(5)
                          .snapshots()
                      : FirebaseFirestore.instance
                          .collection('products')
                          .where('category', isEqualTo: _selectedCategory)
                          .limit(5)
                          .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No products found."));
                }

                var docs = snapshot.data!.docs;
                if (_searchController.text.isNotEmpty) {
                  docs =
                      docs.where((d) {
                        var data = d.data() as Map<String, dynamic>;
                        return (data['productName'] ?? '')
                            .toString()
                            .toLowerCase()
                            .contains(_searchController.text.toLowerCase());
                      }).toList();
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;

                    // --- KRİTİK NOKTA: DOKÜMAN ID'SİNİ KULLANIYORUZ ---
                    // Eğer veritabanında 'barcode' alanı boş bile olsa, ID asla boş olamaz.
                    // Senin veritabanında ID zaten barkod numarasıdır.
                    String realID = docs[index].id;

                    return ProductCard(data: data, barcode: realID);
                  },
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF2E7D32),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner, size: 30),
            label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// --- ÜRÜN KARTI WIDGET'I (Ana Sayfa İçin) ---
class ProductCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String barcode;

  const ProductCard({super.key, required this.data, required this.barcode});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              image:
                  (data['imageUrl'] != null &&
                          data['imageUrl'].toString().isNotEmpty)
                      ? DecorationImage(
                        image: NetworkImage(data['imageUrl']),
                        fit: BoxFit.contain,
                      )
                      : null,
            ),
            child:
                (data['imageUrl'] == null ||
                        data['imageUrl'].toString().isEmpty)
                    ? const Icon(Icons.image_not_supported, color: Colors.grey)
                    : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['productName'] ?? 'Unnamed',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    data['category'] ?? 'General',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Color(0xFF2E7D32)),
            onPressed: () {
              // --- DÜZELTİLDİ: Doğrudan ID'yi sayfaya gönderiyoruz ---
              if (kDebugMode) {
                print("Seçilen Ürün ID: $barcode");
              } // Kontrol için log
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ResultPage(barcode: barcode),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// --- GÜNCELLENMİŞ PREMIUM BİLDİRİM SAYFASI ---
class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Uygulama genel arka planı
      appBar: AppBar(
        title: const Text(
          "Notifications",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent, // Modern şeffaf görünüm
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Firestore'dan bildirimleri tarihe göre (en yeni en üstte) çekiyoruz
        stream:
            FirebaseFirestore.instance
                .collection('notifications')
                .orderBy('createdAt', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          // 1. Yükleniyor Durumu
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
            );
          }

          // 2. Veri Yok Durumu (Şık bir boş ekran tasarımı)
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      // ignore: deprecated_member_use
                      color: const Color(0xFFE8F5E9).withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_off_outlined,
                      size: 60,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "No notifications yet",
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "We'll let you know when there are updates.",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          var docs = snapshot.data!.docs;

          // 3. Bildirim Listesi
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var notification = docs[index].data() as Map<String, dynamic>;

              // Tarih Formatlama (Basit ve şık)
              Timestamp? ts = notification['createdAt'];
              String time = "";
              if (ts != null) {
                DateTime date = ts.toDate();
                // Örn: 25/12/2025 • 14:30
                time =
                    "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} • ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      // ignore: deprecated_member_use
                      color: Colors.grey.withOpacity(0.06),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  // Sol taraftaki ikon (Yeşil Temalı Daire)
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9), // Açık yeşil arka plan
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      color: Color(0xFF2E7D32), // Koyu yeşil ikon
                      size: 24,
                    ),
                  ),
                  // Başlık
                  title: Text(
                    notification['title'] ?? 'System Notification',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  // İçerik ve Tarih
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Text(
                        notification['body'] ?? '',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Tarih Gösterimi (Küçük ve gri)
                      if (time.isNotEmpty)
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              time,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// --- TÜM ÜRÜNLER SAYFASI (All Products) ---
class AllProductsPage extends StatelessWidget {
  const AllProductsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          "All Products",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;

              // --- BURASI DA DÜZELTİLDİ: Sadece doc.id kullanılıyor ---
              return ProductCard(data: data, barcode: doc.id);
            },
          );
        },
      ),
    );
  }
}
