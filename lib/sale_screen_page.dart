import 'package:flutter/material.dart';
import 'package:ims_pos/login_page.dart';
import 'theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ims_pos/helpers/user_manager.dart';

class SaleScreenPage extends StatefulWidget {
  const SaleScreenPage({super.key});

  @override
  State<SaleScreenPage> createState() => _SaleScreenPageState();
}

class _SaleScreenPageState extends State<SaleScreenPage> {
  String userName = '';
  String userRole = '';
  String userImageUrl = '';
  final List<String> categories = [
    'All',
    'Foods',
    'Beverages',
    'Desserts',
    'Fruits',
    'Vegetables',
    'Soft Drinks',
    'Snack',
  ];
  String selectedCategory = 'All';
  String search = '';
  String paymentMethod = 'CASH';

  final List<Map<String, dynamic>> products = [
    {'name': 'Burger', 'category': 'Foods', 'price': 6.0, 'discount': 20},
    {'name': 'Pizza', 'category': 'Foods', 'price': 8.0, 'discount': 0},
    {'name': 'Coffee', 'category': 'Beverages', 'price': 3.5, 'discount': 10},
    {'name': 'Milk Tea', 'category': 'Beverages', 'price': 4.0, 'discount': 0},
    {'name': 'Cake', 'category': 'Desserts', 'price': 5.0, 'discount': 15},
    {'name': 'Apple', 'category': 'Fruits', 'price': 5.0, 'discount': 15},
    {'name': 'Orange', 'category': 'Fruits', 'price': 5.0, 'discount': 15},
    {'name': 'Pinaple', 'category': 'Fruits', 'price': 5.0, 'discount': 15},
    {'name': 'Tomato', 'category': 'Vegetables', 'price': 5.0, 'discount': 15},
    {
      'name': 'Coca-Cola',
      'category': 'Soft Drinks',
      'price': 5.0,
      'discount': 15,
    },
    {'name': 'Lays', 'category': 'Snack', 'price': 5.0, 'discount': 15},
  ];

  final Map<String, int> cart = {};

  /* ================= LOGIC ================= */

  void addToCart(String name) =>
      setState(() => cart[name] = (cart[name] ?? 0) + 1);

  void removeOne(String name) =>
      setState(() => cart[name]! > 1 ? cart[name] = cart[name]! - 1 : null);

  void deleteItem(String name) => setState(() => cart.remove(name));

  double get originalTotal => cart.entries.fold(
    0,
    (t, e) =>
        t + products.firstWhere((p) => p['name'] == e.key)['price'] * e.value,
  );

  double get discountTotal => cart.entries.fold(0, (t, e) {
    final p = products.firstWhere((x) => x['name'] == e.key);
    return t + (p['price'] * p['discount'] / 100) * e.value;
  });

  double get grandTotal => originalTotal - discountTotal;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final name = await UserManager.getName() ?? '';
    final role = await UserManager.getRole() ?? '';
    final image = await UserManager.getImageUrl() ?? '';
    setState(() {
      userName = name;
      userRole = role;
      userImageUrl = image;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = products.where((p) {
      return (selectedCategory == 'All' || p['category'] == selectedCategory) &&
          p['name'].toLowerCase().contains(search.toLowerCase());
    }).toList();

    return Scaffold(
      body: Row(
        children: [
          _sidebar(
            name: userName,
            role: userRole,
            image: userImageUrl,
            context: context,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(flex: 7, child: _products(filtered)),
                  const SizedBox(width: 16),
                  Expanded(flex: 3, child: _orderDetail()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /* ================= SIDEBAR ================= */

  Widget _sidebar({
    required String name,
    required String role,
    required String image,
    required BuildContext context,
  }) => Container(
    width: 200,
    color: kDarkBrown,
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment:
          CrossAxisAlignment.center, // center everything horizontally
      children: [
        const Text(
          'KA POS',
          style: TextStyle(color: Colors.white, fontSize: 22),
        ),
        const SizedBox(height: 32),
        const _MenuItem(Icons.shopping_cart, 'Sales', true),
        const _MenuItem(Icons.settings, 'Settings', false),

        const Spacer(),

        // User profile avatar (larger)
        CircleAvatar(
          radius: 40,
          backgroundColor: Colors.white,
          child: ClipOval(
            child: Image.network(
              image,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(
                  child: CircularProgressIndicator(color: Colors.orange),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                // fallback to initials
                final parts = name.trim().split(' ');
                final initials = (parts.length >= 2)
                    ? '${parts[0][0]}${parts[1][0]}'
                    : (parts.isNotEmpty ? parts[0][0] : '');
                return Center(
                  child: Text(
                    initials.toUpperCase(),
                    style: const TextStyle(
                      color: kDarkBrown,
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Name & Role
        Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(role, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 12),

        // Logout button (centered)
        TextButton.icon(
          onPressed: () async {
            final prefs = await SharedPreferences.getInstance();
            final token = prefs.getString('token') ?? '';

            try {
              final response = await http.post(
                Uri.parse('https://www.laravel-imsonline.online/api/v1/logout'),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $token',
                },
              );

              final data = jsonDecode(response.body);
              final message = data['message'] ?? 'Logout failed';

              if (response.statusCode == 200 && data['success'] == true) {
                await prefs.clear();
                if (!context.mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              } else {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(message)));
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Logout failed. Please try again.'),
                ),
              );
            }
          },
          icon: const Icon(Icons.logout, color: Colors.white),
          label: const Text('Logout', style: TextStyle(color: Colors.white)),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
      ],
    ),
  );

  /* ================= PRODUCTS ================= */

  Widget _products(List<Map<String, dynamic>> list) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 12),

      SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: categories
              .map(
                (c) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(c),
                    selected: selectedCategory == c,
                    selectedColor: kPrimaryGold,
                    onSelected: (_) => setState(() => selectedCategory = c),
                  ),
                ),
              )
              .toList(),
        ),
      ),

      const SizedBox(height: 12),
      TextField(
        cursorColor: kPrimaryOrange,
        onChanged: (v) => setState(() => search = v),
        decoration: const InputDecoration(
          hintText: 'Search product',
          prefixIcon: Icon(Icons.search),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: kPrimaryOrange, width: 2),
          ),
        ),
      ),

      const SizedBox(height: 12),
      Expanded(
        child: GridView.builder(
          itemCount: list.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          itemBuilder: (_, i) => _productCard(list[i]),
        ),
      ),
    ],
  );

  Widget _productCard(Map<String, dynamic> p) {
    final discounted = p['price'] * (1 - p['discount'] / 100);
    return GestureDetector(
      onTap: () => addToCart(p['name']),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: const Center(child: Icon(Icons.fastfood, size: 48)),
                  ),
                  if (p['discount'] > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: kPrimaryGold,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '-${p['discount']}%',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p['name']),
                  if (p['discount'] > 0) ...[
                    Text(
                      '\$${p['price']}',
                      style: const TextStyle(
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    Text(
                      '\$${discounted.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: kPrimaryOrange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ] else
                    Text(
                      '\$${p['price']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /* ================= ORDER DETAIL ================= */

  Widget _orderDetail() => Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'Order Detail',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // List of cart items
          Expanded(
            child: ListView(
              children: cart.entries.map((e) {
                final p = products.firstWhere((x) => x['name'] == e.key);
                final quantity = e.value;
                final price = p['price'] * quantity;
                final discountAmount = p['discount'] > 0
                    ? price * (p['discount'] / 100)
                    : 0;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Stack(
                      children: [
                        // Remove button top-right
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () => removeOne(e.key),
                                iconSize: 20,
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => deleteItem(e.key),
                                iconSize: 20,
                              ),
                            ],
                          ),
                        ),
                        // Item info
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${quantity}x ${e.key}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '\$${price.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            if (discountAmount > 0)
                              Text(
                                '-\$${discountAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: kPrimaryOrange,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Totals
          _row('Subtotal', grandTotal),
          _row('Discount', discountTotal),
          _row('Grand Total', grandTotal - discountTotal, bold: true),

          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: paymentMethod,
            decoration: InputDecoration(
              labelText: 'Payment Method',
              labelStyle: const TextStyle(
                color: kPrimaryOrange,
              ), // label color orange
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: kPrimaryOrange, width: 2),
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'CASH', child: Text('CASH')),
              DropdownMenuItem(value: 'ABA', child: Text('ABA')),
              DropdownMenuItem(value: 'ACLEDA', child: Text('ACLEDA')),
              DropdownMenuItem(value: 'WING', child: Text('WING')),
              DropdownMenuItem(value: 'FTB', child: Text('FTB')),
              DropdownMenuItem(value: 'SATHAPANA', child: Text('SATHAPANA')),
            ],
            onChanged: (v) => setState(() => paymentMethod = v!),
          ),

          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: cart.isEmpty ? null : () {},
              child: const Text('Make Order'),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _row(String label, double value, {bool bold = false}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label),
      Text(
        value < 0
            ? '-\$${value.abs().toStringAsFixed(2)}'
            : '\$${value.toStringAsFixed(2)}',
        style: TextStyle(
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          color: label == 'Discount' ? kPrimaryOrange : null,
        ),
      ),
    ],
  );
}

/* ================= MENU ITEM ================= */

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;

  const _MenuItem(this.icon, this.label, this.active);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: active ? kPrimaryOrange : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(label, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}
