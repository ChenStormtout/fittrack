import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

// ============================================================
// MODELS
// ============================================================

class ProductModel {
  final int id;
  final String name;
  final String description;
  final double priceIdr;
  final double rating;
  final int stock;
  final String imageUrl;
  final List<String> categories;
  final String emoji;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.priceIdr,
    required this.rating,
    required this.stock,
    required this.imageUrl,
    required this.categories,
    required this.emoji,
  });
}

class CartItem {
  final ProductModel product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});
}

// ============================================================
// SAMPLE DATA
// ============================================================

final List<ProductModel> dummyProducts = [
  ProductModel(
    id: 1,
    name: 'Smart Resistance Band',
    description: 'Elastic band untuk latihan kekuatan dan rehabilitasi otot.',
    priceIdr: 150000,
    rating: 4.7,
    stock: 20,
    imageUrl: '',
    categories: ['Kekuatan'],
    emoji: '🏋️',
  ),
  ProductModel(
    id: 2,
    name: 'Adjustable Dumbbell Set',
    description: 'Dumbbell adjustable cocok untuk home workout setiap hari.',
    priceIdr: 950000,
    rating: 4.5,
    stock: 15,
    imageUrl: '',
    categories: ['Kekuatan'],
    emoji: '💪',
  ),
  ProductModel(
    id: 3,
    name: 'Running Shoes',
    description: 'Sepatu lari nyaman, ringan, dan cocok untuk semua medan.',
    priceIdr: 450000,
    rating: 4.8,
    stock: 30,
    imageUrl: '',
    categories: ['Olahraga'],
    emoji: '👟',
  ),
  ProductModel(
    id: 4,
    name: 'Yoga Mat Premium',
    description: 'Mat anti-slip tebal untuk yoga, pilates, dan meditasi.',
    priceIdr: 200000,
    rating: 4.6,
    stock: 25,
    imageUrl: '',
    categories: ['Yoga'],
    emoji: '🧘',
  ),
  ProductModel(
    id: 5,
    name: 'Smartwatch Fitness',
    description: 'Monitor detak jantung, langkah kaki, dan kalori secara real-time.',
    priceIdr: 1200000,
    rating: 4.9,
    stock: 12,
    imageUrl: '',
    categories: ['Teknologi'],
    emoji: '⌚',
  ),
  ProductModel(
    id: 6,
    name: 'Jump Rope Speed',
    description: 'Skipping rope profesional dengan bearing perputaran cepat.',
    priceIdr: 85000,
    rating: 4.4,
    stock: 40,
    imageUrl: '',
    categories: ['Olahraga'],
    emoji: '🪢',
  ),
  ProductModel(
    id: 7,
    name: 'Protein Shaker Bottle',
    description: 'Botol shaker 700ml BPA-free dengan mixer ball stainless.',
    priceIdr: 75000,
    rating: 4.3,
    stock: 50,
    imageUrl: '',
    categories: ['Aksesoris'],
    emoji: '🥤',
  ),
  ProductModel(
    id: 8,
    name: 'Foam Roller Massage',
    description: 'Foam roller untuk pemulihan otot dan mengurangi nyeri badan.',
    priceIdr: 180000,
    rating: 4.5,
    stock: 18,
    imageUrl: '',
    categories: ['Aksesoris'],
    emoji: '🫀',
  ),
];

// ============================================================
// CURRENCY SERVICE
// ============================================================

class CurrencyConverterService {
  static const Map<String, double> _rates = {
    'IDR': 1.0,
    'USD': 0.000065,
    'EUR': 0.000060,
    'GBP': 0.000052,
  };

  static const Map<String, String> _symbols = {
    'IDR': 'Rp',
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
  };

  String formatPrice(double priceIdr, String currency) {
    final rate = _rates[currency] ?? 1.0;
    final symbol = _symbols[currency] ?? 'Rp';
    final converted = priceIdr * rate;

    if (currency == 'IDR') {
      return '$symbol ${_formatNumber(converted.round())}';
    } else {
      return '$symbol ${converted.toStringAsFixed(2)}';
    }
  }

  String _formatNumber(int number) {
    final str = number.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
      count++;
    }
    return buffer.toString().split('').reversed.join('');
  }
}

// ============================================================
// SHOP PAGE (STATEFUL WIDGET)
// ============================================================

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> with TickerProviderStateMixin {
  // ---- State ----
  final List<ProductModel> _products = dummyProducts;
  final List<CartItem> _cart = [];
  final TextEditingController _searchController = TextEditingController();
  final CurrencyConverterService _currencyService = CurrencyConverterService();

  String _selectedCurrency = 'IDR';
  String _selectedCategory = 'Semua';
  bool _showCart = false;
  String _sortOption = 'Relevan';

  late AnimationController _cartBounceController;
  late Animation<double> _cartBounceAnim;

  static const _darkBlue = Color(0xFF1A1A2E);
  static const _accentOrange = Color(0xFFF97316);
  static const _accentGreen = Color(0xFF16A34A);

  final List<String> _categories = [
    'Semua',
    'Kekuatan',
    'Olahraga',
    'Yoga',
    'Teknologi',
    'Aksesoris',
  ];

  final List<String> _currencies = ['IDR', 'USD', 'EUR', 'GBP'];
  final List<String> _sortOptions = [
    'Relevan',
    'Harga ↑',
    'Harga ↓',
    'Rating ↓',
  ];

  @override
  void initState() {
    super.initState();
    _cartBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _cartBounceAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _cartBounceController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cartBounceController.dispose();
    super.dispose();
  }

  // ---- Cart Logic ----

  int get _cartTotalItems =>
      _cart.fold(0, (sum, item) => sum + item.quantity);

  double get _cartTotalPrice =>
      _cart.fold(0.0, (sum, item) => sum + item.product.priceIdr * item.quantity);

  void _addToCart(ProductModel product) {
    HapticFeedback.lightImpact();
    setState(() {
      final existing = _cart.indexWhere((i) => i.product.id == product.id);
      if (existing >= 0) {
        _cart[existing].quantity++;
      } else {
        _cart.add(CartItem(product: product));
      }
    });
    _cartBounceController.forward(from: 0);
    _showSnack('${product.name} ditambahkan ke keranjang', icon: Icons.check_circle, color: _accentGreen);
  }

  void _removeFromCart(ProductModel product) {
    HapticFeedback.lightImpact();
    setState(() {
      final existing = _cart.indexWhere((i) => i.product.id == product.id);
      if (existing >= 0) {
        if (_cart[existing].quantity > 1) {
          _cart[existing].quantity--;
        } else {
          _cart.removeAt(existing);
        }
      }
    });
  }

  void _clearCart() {
    setState(() => _cart.clear());
  }

  void _checkout() {
    if (_cart.isEmpty) {
      _showSnack('Keranjang masih kosong!', icon: Icons.warning_amber, color: Colors.orange);
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi Checkout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total: ${_currencyService.formatPrice(_cartTotalPrice, _selectedCurrency)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('${_cartTotalItems} item akan dibeli.', style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _clearCart();
              setState(() => _showCart = false);
              _showSnack('Checkout berhasil! Terima kasih 🎉', icon: Icons.celebration, color: _accentGreen);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _darkBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Bayar Sekarang'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, {required IconData icon, required Color color}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(msg, style: const TextStyle(fontSize: 13))),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  // ---- Filter & Sort ----

  List<ProductModel> get _filteredProducts {
    final query = _searchController.text.toLowerCase();
    var list = _products.where((p) {
      final matchCat = _selectedCategory == 'Semua' || p.categories.contains(_selectedCategory);
      final matchQuery = query.isEmpty ||
          p.name.toLowerCase().contains(query) ||
          p.description.toLowerCase().contains(query);
      return matchCat && matchQuery;
    }).toList();

    switch (_sortOption) {
      case 'Harga ↑':
        list.sort((a, b) => a.priceIdr.compareTo(b.priceIdr));
        break;
      case 'Harga ↓':
        list.sort((a, b) => b.priceIdr.compareTo(a.priceIdr));
        break;
      case 'Rating ↓':
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
    }
    return list;
  }

  int _cartQty(int productId) {
    final idx = _cart.indexWhere((i) => i.product.id == productId);
    return idx >= 0 ? _cart[idx].quantity : 0;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredProducts;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F8),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildTimeZoneStrip(),
            Expanded(
              child: _showCart ? _buildCartView() : _buildShopView(filtered),
            ),
          ],
        ),
      ),
    );
  }

  // ---- TOP BAR ----

  Widget _buildTopBar() {
    return Container(
      color: _darkBlue,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Logo / Title
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'FitLife Shop',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                '${_filteredProducts.length} produk tersedia',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
              ),
            ],
          ),
          const Spacer(),
          // Cart Button
          GestureDetector(
            onTap: () => setState(() => _showCart = !_showCart),
            child: ScaleTransition(
              scale: _cartBounceAnim,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(21),
                ),
                child: Stack(
                  children: [
                    const Center(
                      child: Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20),
                    ),
                    if (_cartTotalItems > 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: _accentOrange,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '$_cartTotalItems',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- TIME ZONE STRIP ----

  Widget _buildTimeZoneStrip() {
    final now = DateTime.now().toUtc();
    final zones = {
      'WIB': now.add(const Duration(hours: 7)),
      'WITA': now.add(const Duration(hours: 8)),
      'WIT': now.add(const Duration(hours: 9)),
      'London': now.add(const Duration(hours: 1)),
    };

    return Container(
      color: _darkBlue.withOpacity(0.85),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: zones.entries.map((e) {
          final t = e.value;
          final h = t.hour.toString().padLeft(2, '0');
          final m = t.minute.toString().padLeft(2, '0');
          return Column(
            children: [
              Text(
                e.key,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 9,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$h:$m',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ============================================================
  // SHOP VIEW
  // ============================================================

  Widget _buildShopView(List<ProductModel> products) {
    return Column(
      children: [
        _buildSearchBar(),
        _buildCategoryFilter(),
        _buildCurrencySortRow(),
        Expanded(
          child: products.isEmpty
              ? _buildEmptyState()
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.70,
                  ),
                  itemCount: products.length,
                  itemBuilder: (ctx, i) => _buildProductCard(products[i]),
                ),
        ),
      ],
    );
  }

  // ---- SEARCH BAR ----

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Cari produk fitness...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close, color: Colors.grey.shade400, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
          filled: true,
          fillColor: const Color(0xFFF4F4F8),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // ---- CATEGORY FILTER CHIPS ----

  Widget _buildCategoryFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final cat = _categories[i];
          final active = cat == _selectedCategory;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: active ? _darkBlue : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active ? _darkBlue : Colors.grey.shade300,
                  width: 0.8,
                ),
              ),
              child: Text(
                cat,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: active ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ---- CURRENCY + SORT ROW ----

  Widget _buildCurrencySortRow() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
      child: Row(
        children: [
          // Currency Selector
          Text('Mata uang:', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          const SizedBox(width: 8),
          ...(_currencies.map((cur) {
            final active = cur == _selectedCurrency;
            return GestureDetector(
              onTap: () => setState(() => _selectedCurrency = cur),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: active ? _darkBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: active ? _darkBlue : Colors.grey.shade300, width: 0.8),
                ),
                child: Text(
                  cur,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: active ? Colors.white : Colors.grey.shade600,
                  ),
                ),
              ),
            );
          })),
          const Spacer(),
          // Sort dropdown
          GestureDetector(
            onTap: _showSortMenu,
            child: Row(
              children: [
                Icon(Icons.sort, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  _sortOption,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSortMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          const Text('Urutkan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const Divider(),
          ..._sortOptions.map((opt) => ListTile(
                title: Text(opt, style: const TextStyle(fontSize: 14)),
                trailing: opt == _sortOption ? Icon(Icons.check, color: _darkBlue, size: 18) : null,
                onTap: () {
                  setState(() => _sortOption = opt);
                  Navigator.pop(ctx);
                },
              )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ---- PRODUCT CARD ----

  Widget _buildProductCard(ProductModel product) {
    final qty = _cartQty(product.id);
    final formattedPrice = _currencyService.formatPrice(product.priceIdr, _selectedCurrency);

    return GestureDetector(
      onTap: () => _showProductDetail(product),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade100, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Area
            Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _cardGradient(product.id),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Center(
                child: Text(product.emoji, style: const TextStyle(fontSize: 40)),
              ),
            ),
            // Body
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Rating
                  Row(
                    children: [
                      const Icon(Icons.star, color: Color(0xFFF59E0B), size: 12),
                      const SizedBox(width: 3),
                      Text(
                        product.rating.toString(),
                        style: const TextStyle(fontSize: 10, color: Color(0xFFF59E0B), fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Stok: ${product.stock}',
                        style: TextStyle(fontSize: 9, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formattedPrice,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _darkBlue,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Add to Cart
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: qty == 0
                  ? SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _addToCart(product),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _darkBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        child: const Text('+ Keranjang'),
                      ),
                    )
                  : Row(
                      children: [
                        _qtyButton(Icons.remove, () => _removeFromCart(product)),
                        Expanded(
                          child: Center(
                            child: Text(
                              '$qty',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _darkBlue,
                              ),
                            ),
                          ),
                        ),
                        _qtyButton(Icons.add, () => _addToCart(product)),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: _darkBlue,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 14),
      ),
    );
  }

  List<Color> _cardGradient(int id) {
    final gradients = [
      [const Color(0xFFE8EAF6), const Color(0xFFC5CAE9)],
      [const Color(0xFFE0F2F1), const Color(0xFFB2DFDB)],
      [const Color(0xFFFCE4EC), const Color(0xFFF8BBD0)],
      [const Color(0xFFF3E5F5), const Color(0xFFE1BEE7)],
      [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)],
      [const Color(0xFFFFF3E0), const Color(0xFFFFE0B2)],
      [const Color(0xFFE3F2FD), const Color(0xFFBBDEFB)],
      [const Color(0xFFF1F8E9), const Color(0xFFDCEDC8)],
    ];
    return gradients[id % gradients.length].cast<Color>();
  }

  // ---- EMPTY STATE ----

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Produk tidak ditemukan',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 8),
          Text(
            'Coba kata kunci lain atau pilih kategori berbeda',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  // ---- PRODUCT DETAIL BOTTOM SHEET ----

  void _showProductDetail(ProductModel product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, sc) => SingleChildScrollView(
          controller: sc,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Emoji banner
                Container(
                  width: double.infinity,
                  height: 140,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _cardGradient(product.id),
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(product.emoji, style: const TextStyle(fontSize: 64)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(product.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, color: Color(0xFFF59E0B), size: 16),
                    const SizedBox(width: 4),
                    Text('${product.rating}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 12),
                    Icon(Icons.inventory_2_outlined, size: 14, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text('Stok: ${product.stock}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EAF6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        product.categories.first,
                        style: const TextStyle(fontSize: 10, color: _darkBlue, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(product.description, style: TextStyle(color: Colors.grey.shade600, height: 1.5, fontSize: 13)),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text('Harga dalam berbagai mata uang', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: ['IDR', 'USD', 'EUR', 'GBP'].map((cur) {
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F4F8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(cur, style: TextStyle(fontSize: 9, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            FittedBox(
                              child: Text(
                                _currencyService.formatPrice(product.priceIdr, cur),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _darkBlue),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _addToCart(product);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _darkBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Tambah ke Keranjang', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CART VIEW
  // ============================================================

  Widget _buildCartView() {
    return Column(
      children: [
        // Header
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _showCart = false),
                child: const Icon(Icons.arrow_back_ios_new, size: 16),
              ),
              const SizedBox(width: 12),
              const Text('Keranjang Belanja', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const Spacer(),
              if (_cart.isNotEmpty)
                GestureDetector(
                  onTap: () => showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Kosongkan Keranjang?', style: TextStyle(fontSize: 15)),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
                        TextButton(
                          onPressed: () {
                            _clearCart();
                            Navigator.pop(ctx);
                          },
                          child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ),
                  child: Text('Hapus Semua', style: TextStyle(fontSize: 12, color: Colors.red.shade400)),
                ),
            ],
          ),
        ),
        // Cart Items
        Expanded(
          child: _cart.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_bag_outlined, size: 72, color: Colors.grey.shade200),
                      const SizedBox(height: 16),
                      Text('Keranjang kosong', style: TextStyle(color: Colors.grey.shade400, fontSize: 15)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => setState(() => _showCart = false),
                        child: Text('Mulai belanja →', style: const TextStyle(color: _darkBlue, fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(14),
                  itemCount: _cart.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) => _buildCartItemCard(_cart[i]),
                ),
        ),
        // Summary + Checkout
        if (_cart.isNotEmpty) _buildCartSummary(),
      ],
    );
  }

  Widget _buildCartItemCard(CartItem item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: _cardGradient(item.product.id)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Text(item.product.emoji, style: const TextStyle(fontSize: 26))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(
                  _currencyService.formatPrice(item.product.priceIdr, _selectedCurrency),
                  style: const TextStyle(fontSize: 12, color: _darkBlue, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  'Subtotal: ${_currencyService.formatPrice(item.product.priceIdr * item.quantity, _selectedCurrency)}',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
          // Qty control
          Row(
            children: [
              _qtyButton(Icons.remove, () => _removeFromCart(item.product)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text('${item.quantity}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ),
              _qtyButton(Icons.add, () => _addToCart(item.product)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCartSummary() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$_cartTotalItems item', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              Text(
                _currencyService.formatPrice(_cartTotalPrice, _selectedCurrency),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _darkBlue),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _checkout,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Checkout Sekarang', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// MAIN
// ============================================================

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'FitLife Shop',
    home: ShopPage(),
  ));
}