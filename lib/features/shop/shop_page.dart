import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ============================================================
// APP COLORS — sesuai tema aplikasi
// ============================================================

class AppColors {
  static const Color primary = Color(0xFF2E7D32);
  static const Color primaryLight = Color(0xFF4CAF50);
  static const Color olive = Color(0xFF6B8E23);
  static const Color sage = Color(0xFFA5B68D);
  static const Color moss = Color(0xFF7A8B5B);

  static const Color background = Color(0xFFF5F7F2);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color softCard = Color(0xFFF0F5ED);
  static const Color softAccent = Color(0xFFE4EFE2);

  static const Color textPrimary = Color(0xFF1D2A1F);
  static const Color textSecondary = Color(0xFF617062);
  static const Color border = Color(0xFFD9E4D4);

  static const Color warning = Color(0xFFF9A825);
  static const Color error = Color(0xFFD32F2F);
  static const Color info = Color(0xFF2E7D32);
}

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
  final String emoji;
  final String category;
  final bool isPromo;
  final double? discountPercent;

  const ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.priceIdr,
    required this.rating,
    required this.stock,
    required this.emoji,
    required this.category,
    this.isPromo = false,
    this.discountPercent,
  });

  double get finalPrice =>
      isPromo && discountPercent != null
          ? priceIdr * (1 - discountPercent! / 100)
          : priceIdr;
}

class CartItem {
  final ProductModel product;
  int quantity;
  CartItem({required this.product, this.quantity = 1});
}

enum PaymentMethod { cod, qris, transfer, creditCard, ovo, gopay, dana }

extension PaymentMethodExt on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.cod:        return 'Cash on Delivery (COD)';
      case PaymentMethod.qris:       return 'QRIS';
      case PaymentMethod.transfer:   return 'Transfer Bank';
      case PaymentMethod.creditCard: return 'Kartu Kredit / Debit';
      case PaymentMethod.ovo:        return 'OVO';
      case PaymentMethod.gopay:      return 'GoPay';
      case PaymentMethod.dana:       return 'DANA';
    }
  }

  String get icon {
    switch (this) {
      case PaymentMethod.cod:        return '🚚';
      case PaymentMethod.qris:       return '📱';
      case PaymentMethod.transfer:   return '🏦';
      case PaymentMethod.creditCard: return '💳';
      case PaymentMethod.ovo:        return '🟣';
      case PaymentMethod.gopay:      return '🟢';
      case PaymentMethod.dana:       return '🔵';
    }
  }

  String get description {
    switch (this) {
      case PaymentMethod.cod:        return 'Bayar tunai saat barang tiba';
      case PaymentMethod.qris:       return 'Scan QR dari semua dompet digital';
      case PaymentMethod.transfer:   return 'Transfer via ATM / m-Banking';
      case PaymentMethod.creditCard: return 'Visa, Mastercard, JCB';
      case PaymentMethod.ovo:        return 'Bayar dengan saldo OVO';
      case PaymentMethod.gopay:      return 'Bayar dengan saldo GoPay';
      case PaymentMethod.dana:       return 'Bayar dengan saldo DANA';
    }
  }
}

// ============================================================
// 50 PRODUK
// ============================================================

const List<ProductModel> allProducts = [
  // ── Kekuatan (8) ─────────────────────────────────────────────
  ProductModel(id:1,  name:'Smart Resistance Band',     description:'Elastic band graded untuk kekuatan dan rehabilitasi otot.', priceIdr:150000,  rating:4.7, stock:20, emoji:'🏋️', category:'Kekuatan', isPromo:true,  discountPercent:10),
  ProductModel(id:2,  name:'Adjustable Dumbbell Set',   description:'Dumbbell adjustable 2–24 kg, ideal untuk home workout.',   priceIdr:950000,  rating:4.5, stock:15, emoji:'💪', category:'Kekuatan'),
  ProductModel(id:3,  name:'Barbell Olympic 20 kg',     description:'Barbell baja 20 kg standar olimpiade, grip knurling.',     priceIdr:1800000, rating:4.6, stock:8,  emoji:'🏗️', category:'Kekuatan'),
  ProductModel(id:4,  name:'Pull-Up Bar Doorway',       description:'Bar pull-up multifungsi tanpa bor, kapasitas 120 kg.',    priceIdr:280000,  rating:4.4, stock:30, emoji:'🔧', category:'Kekuatan'),
  ProductModel(id:5,  name:'Kettlebell 16 kg',          description:'Kettlebell cast iron 16 kg dengan pelapis rubber.',        priceIdr:420000,  rating:4.5, stock:18, emoji:'⚫', category:'Kekuatan'),
  ProductModel(id:6,  name:'Weight Plate 10 kg (pair)', description:'Piringan besi 10 kg standar 50 mm, satu pasang.',         priceIdr:350000,  rating:4.3, stock:25, emoji:'🔘', category:'Kekuatan', isPromo:true,  discountPercent:5),
  ProductModel(id:7,  name:'Push-Up Board Multigrip',   description:'Board push-up 9 posisi untuk menarget otot berbeda.',     priceIdr:175000,  rating:4.4, stock:40, emoji:'🟦', category:'Kekuatan'),
  ProductModel(id:8,  name:'Gymnastic Rings Wood',      description:'Ring kayu 32 mm dengan tali nilon adjustable.',           priceIdr:310000,  rating:4.7, stock:12, emoji:'⭕', category:'Kekuatan'),

  // ── Olahraga (8) ─────────────────────────────────────────────
  ProductModel(id:9,  name:'Running Shoes Pro',         description:'Sepatu lari ringan 220 g dengan teknologi foam cushion.', priceIdr:580000,  rating:4.8, stock:30, emoji:'👟', category:'Olahraga', isPromo:true,  discountPercent:15),
  ProductModel(id:10, name:'Jump Rope Speed Cable',     description:'Skipping rope kabel baja dengan bearing presisi tinggi.', priceIdr:95000,   rating:4.5, stock:50, emoji:'🪢', category:'Olahraga'),
  ProductModel(id:11, name:'Agility Ladder 6 m',        description:'Tangga kelincahan 6 m untuk latihan footwork & speed.',  priceIdr:140000,  rating:4.3, stock:22, emoji:'🪜', category:'Olahraga'),
  ProductModel(id:12, name:'Boxing Gloves 12 oz',       description:'Sarung tinju kulit sintetis 12 oz, padding tebal.',      priceIdr:380000,  rating:4.6, stock:16, emoji:'🥊', category:'Olahraga'),
  ProductModel(id:13, name:'Speed Ball Boxing',         description:'Speed ball pantulan cepat untuk latihan reflex.',        priceIdr:265000,  rating:4.2, stock:14, emoji:'🟤', category:'Olahraga'),
  ProductModel(id:14, name:'Badminton Racket Pro',      description:'Raket karbon ringan 82 g, tension 26 lbs.',             priceIdr:450000,  rating:4.5, stock:20, emoji:'🏸', category:'Olahraga'),
  ProductModel(id:15, name:'Basketball Spalding',       description:'Bola basket ukuran 7, indoor/outdoor rubber.',          priceIdr:320000,  rating:4.4, stock:18, emoji:'🏀', category:'Olahraga'),
  ProductModel(id:16, name:'Soccer Cleats Turf',        description:'Sepatu futsal turf dengan sol karet multidirectional.',  priceIdr:420000,  rating:4.3, stock:25, emoji:'⚽', category:'Olahraga'),

  // ── Yoga & Pilates (7) ────────────────────────────────────────
  ProductModel(id:17, name:'Yoga Mat Premium 6 mm',    description:'Mat yoga TPE anti-slip 6 mm, ramah lingkungan.',        priceIdr:220000,  rating:4.7, stock:35, emoji:'🧘', category:'Yoga'),
  ProductModel(id:18, name:'Yoga Block Cork (pair)',   description:'Blok yoga gabus alami 1 pasang, density tinggi.',       priceIdr:120000,  rating:4.6, stock:40, emoji:'🟫', category:'Yoga', isPromo:true, discountPercent:10),
  ProductModel(id:19, name:'Yoga Strap 2.5 m',        description:'Tali yoga nilon 2,5 m dengan gesper logam tahan lama.', priceIdr:65000,   rating:4.4, stock:60, emoji:'🔵', category:'Yoga'),
  ProductModel(id:20, name:'Pilates Ring 38 cm',       description:'Ring pilates 38 cm dengan foam padded grip nyaman.',    priceIdr:145000,  rating:4.3, stock:28, emoji:'🔴', category:'Yoga'),
  ProductModel(id:21, name:'Balance Ball 65 cm',       description:'Bola gym 65 cm anti-burst untuk core dan pilates.',     priceIdr:195000,  rating:4.5, stock:22, emoji:'🟡', category:'Yoga'),
  ProductModel(id:22, name:'Meditation Cushion',       description:'Bantal meditasi kapas organik, ketebalan 15 cm.',       priceIdr:175000,  rating:4.6, stock:30, emoji:'🪷', category:'Yoga'),
  ProductModel(id:23, name:'Yoga Wheel 33 cm',         description:'Wheel yoga 33 cm untuk backbend dan fleksibilitas.',    priceIdr:240000,  rating:4.4, stock:18, emoji:'🎡', category:'Yoga'),

  // ── Teknologi (7) ─────────────────────────────────────────────
  ProductModel(id:24, name:'Smartwatch Fitness Pro',   description:'GPS built-in, monitor HR & SpO2, waterproof 5ATM.',     priceIdr:1500000, rating:4.9, stock:12, emoji:'⌚', category:'Teknologi', isPromo:true, discountPercent:20),
  ProductModel(id:25, name:'Fitness Tracker Band',     description:'Band fitness tipis dengan notifikasi & sleep tracking.', priceIdr:380000,  rating:4.5, stock:20, emoji:'📿', category:'Teknologi'),
  ProductModel(id:26, name:'Wireless Earbuds Sport',   description:'TWS earbuds IP68, ANC, latency rendah untuk workout.',  priceIdr:650000,  rating:4.7, stock:15, emoji:'🎧', category:'Teknologi'),
  ProductModel(id:27, name:'Smart Scale BMI',          description:'Timbangan pintar Bluetooth, ukur 13 parameter tubuh.',  priceIdr:420000,  rating:4.6, stock:18, emoji:'⚖️', category:'Teknologi'),
  ProductModel(id:28, name:'Pulse Oximeter Clip',      description:'Oximeter jari compact, baca SpO2 & BPM real-time.',    priceIdr:125000,  rating:4.4, stock:35, emoji:'🩺', category:'Teknologi'),
  ProductModel(id:29, name:'Blood Pressure Monitor',   description:'Tensimeter digital otomatis, memori 200 data.',        priceIdr:350000,  rating:4.5, stock:14, emoji:'💊', category:'Teknologi'),
  ProductModel(id:30, name:'Gym Timer LED',            description:'Timer interval LED 7-segment besar, remote control.',  priceIdr:280000,  rating:4.3, stock:10, emoji:'⏱️', category:'Teknologi'),

  // ── Nutrisi (5) ───────────────────────────────────────────────
  ProductModel(id:31, name:'Protein Shaker 700 ml',    description:'Shaker BPA-free dengan mixer ball stainless steel.',   priceIdr:85000,   rating:4.4, stock:60, emoji:'🥤', category:'Nutrisi'),
  ProductModel(id:32, name:'Gym Water Bottle 1 L',     description:'Botol vacuum insulated 1 L, keep cold 24 jam.',       priceIdr:145000,  rating:4.6, stock:45, emoji:'💧', category:'Nutrisi', isPromo:true, discountPercent:8),
  ProductModel(id:33, name:'Meal Prep Container Set',  description:'Set 5 wadah meal prep BPA-free, microwave safe.',     priceIdr:95000,   rating:4.3, stock:50, emoji:'🍱', category:'Nutrisi'),
  ProductModel(id:34, name:'Supplement Organizer',     description:'Kotak suplemen 7 hari, 4 kompartemen per hari.',      priceIdr:75000,   rating:4.2, stock:40, emoji:'🗂️', category:'Nutrisi'),
  ProductModel(id:35, name:'Digital Food Scale',       description:'Timbangan makanan digital presisi 1 g, maks 5 kg.',   priceIdr:110000,  rating:4.5, stock:35, emoji:'🍽️', category:'Nutrisi'),

  // ── Recovery (5) ─────────────────────────────────────────────
  ProductModel(id:36, name:'Foam Roller Deep Tissue',  description:'Foam roller tekstur bumps untuk deep tissue massage.', priceIdr:195000,  rating:4.6, stock:25, emoji:'🫀', category:'Recovery'),
  ProductModel(id:37, name:'Massage Gun Pro',          description:'Pistol pijat 6 kepala, 3200 RPM, baterai 8 jam.',     priceIdr:850000,  rating:4.8, stock:10, emoji:'🔫', category:'Recovery', isPromo:true, discountPercent:12),
  ProductModel(id:38, name:'Ice Pack Gel Reusable',    description:'Kompres gel reusable panas/dingin, isi 4 pack.',      priceIdr:65000,   rating:4.3, stock:55, emoji:'🧊', category:'Recovery'),
  ProductModel(id:39, name:'Compression Knee Sleeve',  description:'Sleeve lutut neoprene untuk support sendi lutut.',    priceIdr:115000,  rating:4.5, stock:38, emoji:'🦵', category:'Recovery'),
  ProductModel(id:40, name:'Lacrosse Ball Massage',    description:'Bola karet padat untuk trigger point myofascial.',    priceIdr:45000,   rating:4.4, stock:70, emoji:'⚪', category:'Recovery'),

  // ── Pakaian (5) ───────────────────────────────────────────────
  ProductModel(id:41, name:'Dry-Fit Training Shirt',   description:'Kaos latihan quick-dry moisture wicking, anti-bau.',  priceIdr:180000,  rating:4.5, stock:45, emoji:'👕', category:'Pakaian'),
  ProductModel(id:42, name:'Compression Leggings',     description:'Legging kompresi high-waist, 4-way stretch, UPF50.', priceIdr:245000,  rating:4.6, stock:30, emoji:'🩱', category:'Pakaian', isPromo:true, discountPercent:10),
  ProductModel(id:43, name:'Sports Bra High Impact',   description:'Sport bra high-impact tanpa wire, full coverage.',    priceIdr:195000,  rating:4.7, stock:28, emoji:'👙', category:'Pakaian'),
  ProductModel(id:44, name:'Gym Shorts 5 inch',        description:'Celana pendek gym dengan liner internal dan pocket.', priceIdr:160000,  rating:4.4, stock:40, emoji:'🩳', category:'Pakaian'),
  ProductModel(id:45, name:'Sweat Headband Set',       description:'Set 3 headband anti-keringat elastis, multicolor.',  priceIdr:55000,   rating:4.2, stock:65, emoji:'🎀', category:'Pakaian'),

  // ── Perlengkapan (5) ─────────────────────────────────────────
  ProductModel(id:46, name:'Gym Bag Duffel 40 L',      description:'Tas gym waterproof 40 L dengan kompartemen sepatu.',  priceIdr:320000,  rating:4.6, stock:20, emoji:'👜', category:'Perlengkapan'),
  ProductModel(id:47, name:'Weightlifting Belt Leather',description:'Sabuk angkat besi kulit asli 10 cm, lumbar support.', priceIdr:480000,  rating:4.7, stock:12, emoji:'🟤', category:'Perlengkapan', isPromo:true, discountPercent:8),
  ProductModel(id:48, name:'Gym Gloves Wrist Wrap',    description:'Sarung tangan gym + wrist wrap velcro, palm guard.',  priceIdr:140000,  rating:4.5, stock:35, emoji:'🧤', category:'Perlengkapan'),
  ProductModel(id:49, name:'Yoga Towel Microfiber',    description:'Handuk yoga microfiber anti-slip 63×183 cm.',        priceIdr:110000,  rating:4.4, stock:42, emoji:'🏖️', category:'Perlengkapan'),
  ProductModel(id:50, name:'Chalk Ball Magnesium',     description:'Bola kapur magnesium 56 g untuk grip barbel & pullup.',priceIdr:35000,   rating:4.6, stock:80, emoji:'⬜', category:'Perlengkapan'),
];

// ============================================================
// CURRENCY SERVICE
// ============================================================

class CurrencyService {
  static const _rates   = {'IDR': 1.0,    'USD': 0.000065, 'EUR': 0.000060, 'GBP': 0.000052};
  static const _symbols = {'IDR': 'Rp',   'USD': '\$',     'EUR': '€',      'GBP': '£'};

  String format(double priceIdr, String cur) {
    final v   = priceIdr * (_rates[cur] ?? 1.0);
    final sym = _symbols[cur] ?? 'Rp';
    return cur == 'IDR' ? '$sym ${_fmt(v.round())}' : '$sym ${v.toStringAsFixed(2)}';
  }

  String _fmt(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    int c = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      if (c > 0 && c % 3 == 0) buf.write('.');
      buf.write(s[i]);
      c++;
    }
    return buf.toString().split('').reversed.join('');
  }
}

// ============================================================
// SHOP PAGE
// ============================================================

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});
  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> with SingleTickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────
  final List<CartItem> _cart = [];
  final _searchCtrl = TextEditingController();
  final _currency   = CurrencyService();

  late final AnimationController _cartAnim;
  late final Animation<double>   _cartScale;

  String _selCur  = 'IDR';
  String _selCat  = 'Semua';
  String _sort    = 'Relevan';
  bool   _showCart = false;
  bool   _gridView = true;

  static const _categories = [
    'Semua','Kekuatan','Olahraga','Yoga','Teknologi',
    'Nutrisi','Recovery','Pakaian','Perlengkapan',
  ];
  static const _currencies = ['IDR','USD','EUR','GBP'];
  static const _sorts      = ['Relevan','Harga ↑','Harga ↓','Rating ↓','Promo'];

  @override
  void initState() {
    super.initState();
    _cartAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    _cartScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.45), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.45, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _cartAnim, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _cartAnim.dispose(); _searchCtrl.dispose(); super.dispose(); }

  // ── Cart ───────────────────────────────────────────────────
  int    get _totalItems => _cart.fold(0,    (s, i) => s + i.quantity);
  double get _totalPrice => _cart.fold(0.0,  (s, i) => s + i.product.finalPrice * i.quantity);

  void _add(ProductModel p) {
    HapticFeedback.lightImpact();
    setState(() {
      final i = _cart.indexWhere((x) => x.product.id == p.id);
      if (i >= 0) _cart[i].quantity++; else _cart.add(CartItem(product: p));
    });
    _cartAnim.forward(from: 0);
  }

  void _remove(ProductModel p) {
    HapticFeedback.lightImpact();
    setState(() {
      final i = _cart.indexWhere((x) => x.product.id == p.id);
      if (i >= 0) { if (_cart[i].quantity > 1) _cart[i].quantity--; else _cart.removeAt(i); }
    });
  }

  int _qty(int id) {
    final i = _cart.indexWhere((x) => x.product.id == id);
    return i >= 0 ? _cart[i].quantity : 0;
  }

  // ── Filter / Sort ──────────────────────────────────────────
  List<ProductModel> get _filtered {
    final q = _searchCtrl.text.toLowerCase();
    var list = allProducts.where((p) {
      final matchCat = _selCat == 'Semua' || p.category == _selCat;
      final matchQ   = q.isEmpty || p.name.toLowerCase().contains(q) || p.description.toLowerCase().contains(q);
      return matchCat && matchQ;
    }).toList();
    switch (_sort) {
      case 'Harga ↑': list.sort((a,b) => a.finalPrice.compareTo(b.finalPrice)); break;
      case 'Harga ↓': list.sort((a,b) => b.finalPrice.compareTo(a.finalPrice)); break;
      case 'Rating ↓':list.sort((a,b) => b.rating.compareTo(a.rating));         break;
      case 'Promo':   list = list.where((p) => p.isPromo).toList();             break;
    }
    return list;
  }

  // ── Gradient per kategori ──────────────────────────────────
  List<Color> _grad(String cat) {
    const m = {
      'Kekuatan':    [Color(0xFFE8EAF6), Color(0xFFC5CAE9)],
      'Olahraga':    [Color(0xFFFCE4EC), Color(0xFFF8BBD0)],
      'Yoga':        [Color(0xFFF3E5F5), Color(0xFFE1BEE7)],
      'Teknologi':   [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
      'Nutrisi':     [Color(0xFFF1F8E9), Color(0xFFDCEDC8)],
      'Recovery':    [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
      'Pakaian':     [Color(0xFFE0F2F1), Color(0xFFB2DFDB)],
      'Perlengkapan':[Color(0xFFFBE9E7), Color(0xFFFFCCBC)],
    };
    return (m[cat] ?? [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)]).cast<Color>();
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: Column(children: [
        _topBar(),
        _timeStrip(),
        Expanded(child: _showCart ? _cartView() : _shopView()),
      ])),
    );
  }

  // ── TOP BAR ───────────────────────────────────────────────
  Widget _topBar() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft, end: Alignment.bottomRight)),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('FitLife Shop', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -.5)),
        Text('${_filtered.length} produk • ${allProducts.where((p)=>p.isPromo).length} promo',
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
      ]),
      const Spacer(),
      IconButton(
        icon: Icon(_gridView ? Icons.view_list : Icons.grid_view, color: Colors.white, size: 20),
        onPressed: () => setState(() => _gridView = !_gridView),
        padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth:36,minHeight:36),
      ),
      const SizedBox(width: 4),
      GestureDetector(
        onTap: () => setState(() => _showCart = !_showCart),
        child: ScaleTransition(scale: _cartScale,
          child: Container(
            width:40, height:40,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(20)),
            child: Stack(children: [
              const Center(child: Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20)),
              if (_totalItems > 0) Positioned(right:5, top:5,
                child: Container(
                  width:16, height:16,
                  decoration: const BoxDecoration(color: AppColors.warning, shape: BoxShape.circle),
                  child: Center(child: Text('$_totalItems', style: const TextStyle(color:Colors.white, fontSize:9, fontWeight:FontWeight.bold))),
                )),
            ]),
          )),
      ),
    ]),
  );

  // ── TIME ZONE STRIP ────────────────────────────────────────
  Widget _timeStrip() {
    final now = DateTime.now().toUtc();
    final zones = {
      'WIB':    now.add(const Duration(hours: 7)),
      'WITA':   now.add(const Duration(hours: 8)),
      'WIT':    now.add(const Duration(hours: 9)),
      'London': now.add(const Duration(hours: 1)),
    };
    return Container(
      color: AppColors.primary.withOpacity(0.82),
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: zones.entries.map((e) {
          final h = e.value.hour.toString().padLeft(2,'0');
          final m = e.value.minute.toString().padLeft(2,'0');
          return Column(children: [
            Text(e.key, style: TextStyle(color:Colors.white.withOpacity(0.6), fontSize:9, letterSpacing:.8)),
            const SizedBox(height:2),
            Text('$h:$m', style: const TextStyle(color:Colors.white, fontSize:12, fontWeight:FontWeight.w700)),
          ]);
        }).toList()),
    );
  }

  // ============================================================
  // SHOP VIEW
  // ============================================================
  Widget _shopView() {
    final products = _filtered;
    return Column(children: [
      _searchBar(),
      _filtersRow(),
      Expanded(child: products.isEmpty ? _emptyState()
          : _gridView ? _grid(products) : _list(products)),
    ]);
  }

  Widget _searchBar() => Container(
    color: AppColors.surface,
    padding: const EdgeInsets.fromLTRB(14,10,14,8),
    child: TextField(
      controller: _searchCtrl,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(fontSize:14, color:AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: 'Cari produk fitness...',
        hintStyle: const TextStyle(color:AppColors.textSecondary, fontSize:13),
        prefixIcon: const Icon(Icons.search, color:AppColors.textSecondary, size:20),
        suffixIcon: _searchCtrl.text.isNotEmpty
            ? IconButton(icon: const Icon(Icons.close, color:AppColors.textSecondary, size:18),
                onPressed: () { _searchCtrl.clear(); setState((){}); })
            : null,
        filled: true, fillColor: AppColors.softCard,
        contentPadding: const EdgeInsets.symmetric(vertical:10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    ),
  );

  Widget _filtersRow() => Container(
    color: AppColors.surface,
    child: Column(children: [
      // Category chips
      SizedBox(height:42, child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal:14, vertical:5),
        itemCount: _categories.length,
        separatorBuilder: (_,__) => const SizedBox(width:8),
        itemBuilder: (_,i) {
          final cat = _categories[i]; final active = cat == _selCat;
          return GestureDetector(
            onTap: () => setState(() => _selCat = cat),
            child: AnimatedContainer(duration: const Duration(milliseconds:200),
              padding: const EdgeInsets.symmetric(horizontal:14, vertical:5),
              decoration: BoxDecoration(
                color: active ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: active ? AppColors.primary : AppColors.border, width:.9),
              ),
              child: Text(cat, style: TextStyle(fontSize:12, fontWeight:FontWeight.w600,
                  color: active ? Colors.white : AppColors.textSecondary))),
          );
        },
      )),
      // Currency + sort
      Padding(
        padding: const EdgeInsets.fromLTRB(14,0,14,8),
        child: Row(children: [
          const Text('Kurs:', style: TextStyle(fontSize:11, color:AppColors.textSecondary)),
          const SizedBox(width:6),
          ..._currencies.map((cur) {
            final active = cur == _selCur;
            return GestureDetector(
              onTap: () => setState(() => _selCur = cur),
              child: AnimatedContainer(duration: const Duration(milliseconds:180),
                margin: const EdgeInsets.only(right:5),
                padding: const EdgeInsets.symmetric(horizontal:8, vertical:3),
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: active ? AppColors.primary : AppColors.border, width:.8),
                ),
                child: Text(cur, style: TextStyle(fontSize:11, fontWeight:FontWeight.w700,
                    color: active ? Colors.white : AppColors.textSecondary))),
            );
          }),
          const Spacer(),
          GestureDetector(
            onTap: _sortSheet,
            child: Row(children: [
              const Icon(Icons.sort_rounded, size:14, color:AppColors.textSecondary),
              const SizedBox(width:4),
              Text(_sort, style: const TextStyle(fontSize:11, color:AppColors.textSecondary, fontWeight:FontWeight.w500)),
            ]),
          ),
        ]),
      ),
      const Divider(height:1, color:AppColors.border),
    ]),
  );

  void _sortSheet() => showModalBottomSheet(context: context,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
      const SizedBox(height:10),
      Container(width:36, height:4, decoration: BoxDecoration(color:AppColors.border, borderRadius: BorderRadius.circular(2))),
      const SizedBox(height:12),
      const Text('Urutkan produk', style: TextStyle(fontSize:15, fontWeight:FontWeight.w700, color:AppColors.textPrimary)),
      const Divider(),
      ..._sorts.map((opt) => ListTile(
        title: Text(opt, style: const TextStyle(fontSize:14, color:AppColors.textPrimary)),
        trailing: opt == _sort ? const Icon(Icons.check, color:AppColors.primary, size:18) : null,
        onTap: () { setState(() => _sort = opt); Navigator.pop(context); },
      )),
      const SizedBox(height:12),
    ]),
  );

  // ── GRID ──────────────────────────────────────────────────
  Widget _grid(List<ProductModel> products) => GridView.builder(
    padding: const EdgeInsets.fromLTRB(12,10,12,16),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:2, crossAxisSpacing:10, mainAxisSpacing:10, childAspectRatio:.68),
    itemCount: products.length,
    itemBuilder: (_,i) => _prodCard(products[i]),
  );

  // ── LIST ──────────────────────────────────────────────────
  Widget _list(List<ProductModel> products) => ListView.separated(
    padding: const EdgeInsets.fromLTRB(12,10,12,16),
    itemCount: products.length,
    separatorBuilder: (_,__) => const SizedBox(height:8),
    itemBuilder: (_,i) => _prodTile(products[i]),
  );

  // ── PRODUCT CARD (grid) ────────────────────────────────────
  Widget _prodCard(ProductModel p) {
    final qty = _qty(p.id);
    return GestureDetector(
      onTap: () => _detail(p),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width:.8),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius:8, offset: const Offset(0,2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Stack(children: [
            Container(height:98,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: _grad(p.category), begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
              child: Center(child: Text(p.emoji, style: const TextStyle(fontSize:38)))),
            if (p.isPromo) Positioned(top:8, left:8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal:7, vertical:3),
                decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(6)),
                child: Text('-${p.discountPercent!.toInt()}%', style: const TextStyle(color:Colors.white, fontSize:10, fontWeight:FontWeight.w800)))),
          ]),
          Padding(padding: const EdgeInsets.fromLTRB(10,8,10,0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.name, style: const TextStyle(fontSize:12, fontWeight:FontWeight.w700, color:AppColors.textPrimary, height:1.3), maxLines:2, overflow:TextOverflow.ellipsis),
            const SizedBox(height:4),
            Row(children: [
              const Icon(Icons.star_rounded, color:AppColors.warning, size:12),
              const SizedBox(width:2),
              Text('${p.rating}', style: const TextStyle(fontSize:10, color:AppColors.warning, fontWeight:FontWeight.w700)),
              const SizedBox(width:6),
              Text('Stok ${p.stock}', style: const TextStyle(fontSize:9, color:AppColors.textSecondary)),
            ]),
            const SizedBox(height:5),
            if (p.isPromo && p.discountPercent != null) ...[
              Text(_currency.format(p.priceIdr, _selCur),
                  style: const TextStyle(fontSize:10, color:AppColors.textSecondary, decoration: TextDecoration.lineThrough)),
              Text(_currency.format(p.finalPrice, _selCur),
                  style: const TextStyle(fontSize:13, fontWeight:FontWeight.w800, color:AppColors.primary)),
            ] else
              Text(_currency.format(p.finalPrice, _selCur),
                  style: const TextStyle(fontSize:13, fontWeight:FontWeight.w800, color:AppColors.primary)),
          ])),
          const Spacer(),
          Padding(padding: const EdgeInsets.fromLTRB(8,0,8,8),
            child: qty == 0
                ? SizedBox(width: double.infinity,
                    child: ElevatedButton(onPressed: () => _add(p),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical:7),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)), elevation:0,
                        textStyle: const TextStyle(fontSize:11, fontWeight:FontWeight.w700)),
                      child: const Text('+ Keranjang')))
                : Row(children: [
                    _qBtn(Icons.remove_rounded, () => _remove(p)),
                    Expanded(child: Center(child: Text('$qty', style: const TextStyle(fontSize:14, fontWeight:FontWeight.bold, color:AppColors.textPrimary)))),
                    _qBtn(Icons.add_rounded, () => _add(p)),
                  ]),
          ),
        ]),
      ),
    );
  }

  // ── PRODUCT LIST TILE ──────────────────────────────────────
  Widget _prodTile(ProductModel p) {
    final qty = _qty(p.id);
    return GestureDetector(
      onTap: () => _detail(p),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width:.8)),
        child: Row(children: [
          Stack(children: [
            Container(width:68, height:68,
              decoration: BoxDecoration(gradient: LinearGradient(colors: _grad(p.category)), borderRadius: BorderRadius.circular(12)),
              child: Center(child: Text(p.emoji, style: const TextStyle(fontSize:28)))),
            if (p.isPromo) Positioned(top:4, left:4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal:5, vertical:2),
                decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(4)),
                child: Text('-${p.discountPercent!.toInt()}%', style: const TextStyle(color:Colors.white, fontSize:8, fontWeight:FontWeight.w800)))),
          ]),
          const SizedBox(width:12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.name, style: const TextStyle(fontSize:13, fontWeight:FontWeight.w700, color:AppColors.textPrimary), maxLines:1, overflow:TextOverflow.ellipsis),
            const SizedBox(height:3),
            Text(p.description, style: const TextStyle(fontSize:11, color:AppColors.textSecondary), maxLines:1, overflow:TextOverflow.ellipsis),
            const SizedBox(height:5),
            Row(children: [
              const Icon(Icons.star_rounded, color:AppColors.warning, size:12),
              const SizedBox(width:2),
              Text('${p.rating}', style: const TextStyle(fontSize:10, color:AppColors.warning, fontWeight:FontWeight.w700)),
              const Spacer(),
              Text(_currency.format(p.finalPrice, _selCur),
                  style: const TextStyle(fontSize:13, fontWeight:FontWeight.w800, color:AppColors.primary)),
            ]),
          ])),
          const SizedBox(width:8),
          qty == 0
              ? GestureDetector(onTap: () => _add(p),
                  child: Container(width:32, height:32,
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(9)),
                    child: const Icon(Icons.add, color:Colors.white, size:18)))
              : Column(children: [
                  _qBtn(Icons.add_rounded, () => _add(p)),
                  Padding(padding: const EdgeInsets.symmetric(vertical:4),
                    child: Text('$qty', style: const TextStyle(fontSize:13, fontWeight:FontWeight.bold))),
                  _qBtn(Icons.remove_rounded, () => _remove(p)),
                ]),
        ]),
      ),
    );
  }

  Widget _qBtn(IconData icon, VoidCallback onTap) => GestureDetector(onTap: onTap,
    child: Container(width:26, height:26,
      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color:Colors.white, size:14)));

  Widget _emptyState() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.search_off_rounded, size:64, color:AppColors.sage),
    const SizedBox(height:16),
    const Text('Produk tidak ditemukan', style: TextStyle(fontSize:15, fontWeight:FontWeight.w600, color:AppColors.textSecondary)),
    const SizedBox(height:6),
    const Text('Coba kata kunci atau kategori lain', style: TextStyle(fontSize:12, color:AppColors.textSecondary)),
  ]));

  void _detail(ProductModel p) => showModalBottomSheet(
    context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
    builder: (_) => _DetailSheet(product:p, currency:_currency, selCur:_selCur, qty:_qty(p.id),
        onAdd: () { Navigator.pop(context); _add(p); }, grad: _grad(p.category)),
  );

  // ============================================================
  // CART VIEW
  // ============================================================
  Widget _cartView() => Column(children: [
    Container(color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16,12,16,12),
      child: Row(children: [
        GestureDetector(onTap: () => setState(() => _showCart = false),
          child: const Icon(Icons.arrow_back_ios_new_rounded, size:16, color:AppColors.textPrimary)),
        const SizedBox(width:12),
        const Text('Keranjang Belanja', style: TextStyle(fontSize:16, fontWeight:FontWeight.w700, color:AppColors.textPrimary)),
        const Spacer(),
        if (_cart.isNotEmpty) GestureDetector(onTap: _confirmClear,
          child: const Text('Hapus Semua', style: TextStyle(fontSize:12, color:AppColors.error))),
      ])),
    const Divider(height:1, color:AppColors.border),
    Expanded(child: _cart.isEmpty
        ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.shopping_bag_outlined, size:72, color:AppColors.sage),
            const SizedBox(height:16),
            const Text('Keranjang masih kosong', style: TextStyle(color:AppColors.textSecondary, fontSize:15)),
            const SizedBox(height:10),
            GestureDetector(onTap: () => setState(() => _showCart = false),
              child: const Text('Mulai belanja →', style: TextStyle(color:AppColors.primary, fontSize:13, fontWeight:FontWeight.w700))),
          ]))
        : ListView.separated(
            padding: const EdgeInsets.all(14),
            itemCount: _cart.length,
            separatorBuilder: (_,__) => const SizedBox(height:10),
            itemBuilder: (_,i) => _cartCard(_cart[i]))),
    if (_cart.isNotEmpty) _cartSummary(),
  ]);

  Widget _cartCard(CartItem item) {
    final p = item.product;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width:.8)),
      child: Row(children: [
        Container(width:56, height:56,
          decoration: BoxDecoration(gradient: LinearGradient(colors: _grad(p.category)), borderRadius: BorderRadius.circular(10)),
          child: Center(child: Text(p.emoji, style: const TextStyle(fontSize:24)))),
        const SizedBox(width:12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(p.name, style: const TextStyle(fontSize:13, fontWeight:FontWeight.w700, color:AppColors.textPrimary), maxLines:1, overflow:TextOverflow.ellipsis),
          const SizedBox(height:3),
          Text(_currency.format(p.finalPrice, _selCur), style: const TextStyle(fontSize:12, color:AppColors.primary, fontWeight:FontWeight.w600)),
          const SizedBox(height:2),
          Text('Subtotal: ${_currency.format(p.finalPrice * item.quantity, _selCur)}',
              style: const TextStyle(fontSize:10, color:AppColors.textSecondary)),
        ])),
        Row(children: [
          _qBtn(Icons.remove_rounded, () => _remove(p)),
          Padding(padding: const EdgeInsets.symmetric(horizontal:10),
            child: Text('${item.quantity}', style: const TextStyle(fontSize:14, fontWeight:FontWeight.bold, color:AppColors.textPrimary))),
          _qBtn(Icons.add_rounded, () => _add(p)),
        ]),
      ]),
    );
  }

  Widget _cartSummary() => Container(
    color: AppColors.surface,
    padding: const EdgeInsets.fromLTRB(16,12,16,20),
    child: Column(children: [
      const Divider(color:AppColors.border),
      const SizedBox(height:6),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('$_totalItems item', style: const TextStyle(fontSize:13, color:AppColors.textSecondary)),
        Text(_currency.format(_totalPrice, _selCur),
            style: const TextStyle(fontSize:18, fontWeight:FontWeight.w800, color:AppColors.textPrimary)),
      ]),
      const SizedBox(height:12),
      SizedBox(width: double.infinity,
        child: ElevatedButton(
          onPressed: _openCheckout,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical:14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation:0),
          child: const Text('Pilih Pembayaran & Checkout', style: TextStyle(fontSize:15, fontWeight:FontWeight.w700)))),
    ]),
  );

  void _confirmClear() => showDialog(context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Kosongkan Keranjang?', style: TextStyle(fontSize:15, fontWeight:FontWeight.w700)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        TextButton(onPressed: () { setState(() => _cart.clear()); Navigator.pop(context); },
          child: const Text('Hapus', style: TextStyle(color:AppColors.error))),
      ],
    ));

  void _openCheckout() => showModalBottomSheet(
    context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
    builder: (_) => _CheckoutSheet(
      totalPrice: _totalPrice, totalItems: _totalItems,
      currency: _currency, selCur: _selCur,
      onConfirm: () {
        setState(() { _cart.clear(); _showCart = false; });
        _snack('Pesanan berhasil dibuat! 🎉', AppColors.primary);
      },
    ),
  );

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(msg, style: const TextStyle(fontSize:13)),
        backgroundColor: color, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12), duration: const Duration(seconds:3),
      ));
  }
}

// ============================================================
// PRODUCT DETAIL BOTTOM SHEET
// ============================================================
class _DetailSheet extends StatelessWidget {
  final ProductModel product;
  final CurrencyService currency;
  final String selCur;
  final int qty;
  final VoidCallback onAdd;
  final List<Color> grad;

  const _DetailSheet({required this.product, required this.currency, required this.selCur,
      required this.qty, required this.onAdd, required this.grad});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(initialChildSize:.7, maxChildSize:.92, minChildSize:.45, expand:false,
      builder: (_,sc) => Container(
        decoration: const BoxDecoration(color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
        child: SingleChildScrollView(controller: sc, child: Padding(padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width:36, height:4, margin: const EdgeInsets.only(bottom:16),
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
            Stack(children: [
              Container(width: double.infinity, height:150,
                decoration: BoxDecoration(gradient: LinearGradient(colors: grad, begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(16)),
                child: Center(child: Text(product.emoji, style: const TextStyle(fontSize:68)))),
              if (product.isPromo) Positioned(top:12, left:12,
                child: Container(padding: const EdgeInsets.symmetric(horizontal:10, vertical:4),
                  decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(8)),
                  child: Text('PROMO ${product.discountPercent!.toInt()}% OFF',
                      style: const TextStyle(color:Colors.white, fontSize:11, fontWeight:FontWeight.w800)))),
            ]),
            const SizedBox(height:16),
            Text(product.name, style: const TextStyle(fontSize:19, fontWeight:FontWeight.w800, color:AppColors.textPrimary)),
            const SizedBox(height:6),
            Row(children: [
              const Icon(Icons.star_rounded, color:AppColors.warning, size:16),
              const SizedBox(width:4),
              Text('${product.rating}', style: const TextStyle(fontWeight:FontWeight.w700, color:AppColors.warning)),
              const SizedBox(width:10),
              Container(padding: const EdgeInsets.symmetric(horizontal:8, vertical:2),
                decoration: BoxDecoration(color: AppColors.softAccent, borderRadius: BorderRadius.circular(6)),
                child: Text(product.category, style: const TextStyle(fontSize:10, color:AppColors.primary, fontWeight:FontWeight.w700))),
              const Spacer(),
              Text('Stok: ${product.stock}', style: const TextStyle(fontSize:12, color:AppColors.textSecondary)),
            ]),
            const SizedBox(height:12),
            Text(product.description, style: const TextStyle(color:AppColors.textSecondary, height:1.6, fontSize:13)),
            const SizedBox(height:16),
            const Divider(color:AppColors.border),
            const SizedBox(height:10),
            const Text('Harga dalam berbagai kurs', style: TextStyle(fontSize:12, fontWeight:FontWeight.w700, color:AppColors.textPrimary)),
            const SizedBox(height:8),
            Row(children: ['IDR','USD','EUR','GBP'].map((cur) => Expanded(child: Container(
              margin: const EdgeInsets.only(right:6),
              padding: const EdgeInsets.symmetric(vertical:8, horizontal:4),
              decoration: BoxDecoration(color: AppColors.softCard, borderRadius: BorderRadius.circular(8)),
              child: Column(children: [
                Text(cur, style: const TextStyle(fontSize:9, color:AppColors.textSecondary, fontWeight:FontWeight.w700)),
                const SizedBox(height:4),
                FittedBox(child: Text(currency.format(product.finalPrice, cur),
                    style: const TextStyle(fontSize:11, fontWeight:FontWeight.bold, color:AppColors.primary))),
              ]),
            ))).toList()),
            const SizedBox(height:20),
            SizedBox(width: double.infinity,
              child: ElevatedButton(onPressed: onAdd,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical:14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation:0),
                child: Text(qty > 0 ? 'Tambah Lagi  (di keranjang: $qty)' : '+ Tambah ke Keranjang',
                    style: const TextStyle(fontSize:15, fontWeight:FontWeight.w700)))),
            const SizedBox(height:8),
          ]),
        )),
      ),
    );
  }
}

// ============================================================
// CHECKOUT SHEET  (Alamat GPS → Pembayaran → Konfirmasi)
// ============================================================
class _CheckoutSheet extends StatefulWidget {
  final double totalPrice;
  final int totalItems;
  final CurrencyService currency;
  final String selCur;
  final VoidCallback onConfirm;

  const _CheckoutSheet({required this.totalPrice, required this.totalItems,
      required this.currency, required this.selCur, required this.onConfirm});

  @override
  State<_CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<_CheckoutSheet> {
  PaymentMethod? _method;
  int  _step        = 0;   // 0=Alamat  1=Pembayaran  2=Konfirmasi
  bool _gpsLoading  = false;
  bool _gpsDetected = false;

  final _nameCtrl    = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _noteCtrl    = TextEditingController();

  // Lokasi simulasi GPS/LBS berdasarkan koordinat Yogyakarta sekitarnya
  static const _dummyLocs = [
    'Jl. Malioboro No. 12, Gedongtengen, Yogyakarta 55271',
    'Jl. Solo KM 5, Maguwoharjo, Sleman, DIY 55282',
    'Jl. Parangtritis No. 88, Bantul, DIY 55188',
    'Jl. Kaliurang KM 8, Ngaglik, Sleman, DIY 55581',
    'Jl. Colombo No. 1, Gondokusuman, Yogyakarta 55222',
    'Jl. Tentara Pelajar No. 7, Wirobrajan, Yogyakarta 55253',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose(); _phoneCtrl.dispose();
    _addressCtrl.dispose(); _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _detectGPS() async {
    setState(() { _gpsLoading = true; _gpsDetected = false; });
    await Future.delayed(const Duration(milliseconds: 2200)); // simulasi GPS
    final loc = _dummyLocs[DateTime.now().second % _dummyLocs.length];
    setState(() { _gpsLoading = false; _gpsDetected = true; _addressCtrl.text = loc; });
  }

  bool get _addrOk =>
      _nameCtrl.text.trim().isNotEmpty &&
      _phoneCtrl.text.trim().length >= 10 &&
      _addressCtrl.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(initialChildSize:.86, maxChildSize:.97, minChildSize:.5, expand:false,
      builder: (_,sc) => Container(
        decoration: const BoxDecoration(color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
        child: Column(children: [
          const SizedBox(height:10),
          Container(width:36, height:4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height:10),
          _stepBar(),
          const Divider(color:AppColors.border),
          Expanded(child: SingleChildScrollView(controller: sc, padding: const EdgeInsets.fromLTRB(20,16,20,20),
            child: _step == 0 ? _addrStep() : _step == 1 ? _payStep() : _confirmStep())),
          _bottomBtn(),
        ]),
      ),
    );
  }

  // ── Step Indicator ─────────────────────────────────────────
  Widget _stepBar() {
    const steps = ['Alamat','Pembayaran','Konfirmasi'];
    return Padding(padding: const EdgeInsets.symmetric(horizontal:20, vertical:2),
      child: Row(children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) return Expanded(child: Container(height:1.5, color: i ~/ 2 < _step ? AppColors.primary : AppColors.border));
        final idx = i ~/ 2; final done = idx < _step; final active = idx == _step;
        return Column(children: [
          Container(width:28, height:28,
            decoration: BoxDecoration(
              color: done ? AppColors.primary : active ? AppColors.softAccent : AppColors.softCard,
              shape: BoxShape.circle,
              border: Border.all(color: active ? AppColors.primary : done ? AppColors.primary : AppColors.border, width:1.5)),
            child: Center(child: done
                ? const Icon(Icons.check, color:Colors.white, size:14)
                : Text('${idx+1}', style: TextStyle(fontSize:12, fontWeight:FontWeight.w700,
                    color: active ? AppColors.primary : AppColors.textSecondary)))),
          const SizedBox(height:4),
          Text(steps[idx], style: TextStyle(fontSize:9, fontWeight:FontWeight.w700,
              color: active ? AppColors.primary : AppColors.textSecondary)),
        ]);
      })),
    );
  }

  // ── STEP 0: ALAMAT ─────────────────────────────────────────
  Widget _addrStep() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Alamat Pengiriman', style: TextStyle(fontSize:16, fontWeight:FontWeight.w800, color:AppColors.textPrimary)),
    const SizedBox(height:16),
    _tf('Nama Penerima', _nameCtrl, Icons.person_outline, 'Nama lengkap penerima'),
    const SizedBox(height:12),
    _tf('Nomor HP', _phoneCtrl, Icons.phone_outlined, '08xxxxxxxxxx', type: TextInputType.phone),
    const SizedBox(height:12),
    // GPS Button
    Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.softAccent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3))),
      child: Material(color: Colors.transparent,
        child: InkWell(borderRadius: BorderRadius.circular(12),
          onTap: _gpsLoading ? null : _detectGPS,
          child: Padding(padding: const EdgeInsets.symmetric(horizontal:16, vertical:13),
            child: Row(children: [
              _gpsLoading
                  ? const SizedBox(width:20, height:20, child: CircularProgressIndicator(strokeWidth:2, color:AppColors.primary))
                  : Icon(_gpsDetected ? Icons.location_on : Icons.my_location_rounded, color:AppColors.primary, size:20),
              const SizedBox(width:12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_gpsLoading ? 'Mendeteksi lokasi GPS...'
                    : _gpsDetected ? 'Lokasi berhasil dideteksi ✓'
                    : 'Deteksi lokasi otomatis (GPS/LBS)',
                    style: const TextStyle(fontSize:13, fontWeight:FontWeight.w700, color:AppColors.primary)),
                Text(_gpsLoading ? 'Harap tunggu sebentar...'
                    : 'Isi alamat otomatis dari GPS / lokasi jaringan',
                    style: const TextStyle(fontSize:10, color:AppColors.textSecondary)),
              ])),
              if (!_gpsLoading) const Icon(Icons.chevron_right, color:AppColors.primary, size:18),
            ])))),
    ),
    const SizedBox(height:12),
    // Alamat field
    TextField(controller: _addressCtrl, maxLines:3,
      style: const TextStyle(fontSize:13, color:AppColors.textPrimary),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: 'Alamat Lengkap',
        hintText: 'Jl. Nama Jalan No. xx, Kelurahan, Kecamatan...',
        hintStyle: const TextStyle(fontSize:12, color:AppColors.textSecondary),
        labelStyle: const TextStyle(fontSize:13, color:AppColors.textSecondary),
        prefixIcon: const Icon(Icons.home_outlined, color:AppColors.primary, size:20),
        filled: true, fillColor: AppColors.softCard,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color:AppColors.border, width:.8)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color:AppColors.primary, width:1.2)),
      )),
    const SizedBox(height:12),
    _tf('Catatan untuk kurir (opsional)', _noteCtrl, Icons.note_outlined, 'Contoh: titipkan ke satpam'),
  ]);

  Widget _tf(String label, TextEditingController ctrl, IconData icon, String hint,
      {TextInputType type = TextInputType.text}) =>
      TextField(controller: ctrl, keyboardType: type,
        style: const TextStyle(fontSize:13, color:AppColors.textPrimary),
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: label, hintText: hint,
          hintStyle: const TextStyle(fontSize:12, color:AppColors.textSecondary),
          labelStyle: const TextStyle(fontSize:13, color:AppColors.textSecondary),
          prefixIcon: Icon(icon, color:AppColors.primary, size:20),
          filled: true, fillColor: AppColors.softCard,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color:AppColors.border, width:.8)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color:AppColors.primary, width:1.2)),
        ));

  // ── STEP 1: PEMBAYARAN ─────────────────────────────────────
  Widget _payStep() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Metode Pembayaran', style: TextStyle(fontSize:16, fontWeight:FontWeight.w800, color:AppColors.textPrimary)),
    const SizedBox(height:4),
    Text('Total: ${widget.currency.format(widget.totalPrice, widget.selCur)}',
        style: const TextStyle(fontSize:13, color:AppColors.textSecondary)),
    const SizedBox(height:16),
    _secLabel('Bayar di Tempat'),
    _payTile(PaymentMethod.cod),
    const SizedBox(height:12),
    _secLabel('Dompet Digital'),
    _payTile(PaymentMethod.qris),
    _payTile(PaymentMethod.ovo),
    _payTile(PaymentMethod.gopay),
    _payTile(PaymentMethod.dana),
    const SizedBox(height:12),
    _secLabel('Transfer & Kartu'),
    _payTile(PaymentMethod.transfer),
    _payTile(PaymentMethod.creditCard),
    if (_method == PaymentMethod.qris) ...[
      const SizedBox(height:16),
      _qrisMock(),
    ],
  ]);

  Widget _secLabel(String s) => Padding(padding: const EdgeInsets.only(bottom:8),
    child: Text(s, style: const TextStyle(fontSize:11, fontWeight:FontWeight.w700, color:AppColors.textSecondary, letterSpacing:.5)));

  Widget _payTile(PaymentMethod m) {
    final sel = _method == m;
    return GestureDetector(
      onTap: () => setState(() => _method = m),
      child: AnimatedContainer(duration: const Duration(milliseconds:180),
        margin: const EdgeInsets.only(bottom:8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: sel ? AppColors.softAccent : AppColors.softCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: sel ? AppColors.primary : AppColors.border, width: sel ? 1.5 : .8)),
        child: Row(children: [
          Text(m.icon, style: const TextStyle(fontSize:22)),
          const SizedBox(width:14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.label, style: const TextStyle(fontSize:13, fontWeight:FontWeight.w700, color:AppColors.textPrimary)),
            Text(m.description, style: const TextStyle(fontSize:11, color:AppColors.textSecondary)),
          ])),
          Container(width:20, height:20,
            decoration: BoxDecoration(shape: BoxShape.circle,
              border: Border.all(color: sel ? AppColors.primary : AppColors.border, width:1.5),
              color: sel ? AppColors.primary : Colors.transparent),
            child: sel ? const Icon(Icons.check, color:Colors.white, size:12) : null),
        ])),
    );
  }

  Widget _qrisMock() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius:12)]),
    child: Column(children: [
      const Text('Scan QRIS untuk Membayar', style: TextStyle(fontSize:13, fontWeight:FontWeight.w700, color:AppColors.textPrimary)),
      const SizedBox(height:12),
      SizedBox(width:160, height:160, child: CustomPaint(painter: _QRPainter())),
      const SizedBox(height:10),
      const Text('FITLIFE-SHOP-2024', style: TextStyle(fontSize:11, color:AppColors.textSecondary, letterSpacing:1)),
      const SizedBox(height:4),
      Text(widget.currency.format(widget.totalPrice, widget.selCur),
          style: const TextStyle(fontSize:14, fontWeight:FontWeight.w800, color:AppColors.primary)),
      const SizedBox(height:6),
      Text('QR berlaku 15 menit', style: TextStyle(fontSize:10, color:AppColors.textSecondary.withOpacity(0.7))),
    ]),
  );

  // ── STEP 2: KONFIRMASI ─────────────────────────────────────
  Widget _confirmStep() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Ringkasan Pesanan', style: TextStyle(fontSize:16, fontWeight:FontWeight.w800, color:AppColors.textPrimary)),
    const SizedBox(height:16),
    _row('Penerima',   _nameCtrl.text),
    _row('No. HP',     _phoneCtrl.text),
    _row('Alamat',     _addressCtrl.text),
    if (_noteCtrl.text.isNotEmpty) _row('Catatan', _noteCtrl.text),
    const Divider(color:AppColors.border, height:24),
    _row('Metode',     _method?.label ?? '-'),
    _row('Jumlah',     '${widget.totalItems} produk'),
    const SizedBox(height:8),
    Container(padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.softAccent, borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Total Pembayaran', style: TextStyle(fontSize:14, fontWeight:FontWeight.w700, color:AppColors.textPrimary)),
        Text(widget.currency.format(widget.totalPrice, widget.selCur),
            style: const TextStyle(fontSize:16, fontWeight:FontWeight.w800, color:AppColors.primary)),
      ])),
    if (_method == PaymentMethod.cod) ...[
      const SizedBox(height:12),
      Container(padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.warning.withOpacity(0.4))),
        child: const Row(children: [
          Icon(Icons.info_outline, color:AppColors.warning, size:16),
          SizedBox(width:8),
          Expanded(child: Text('Siapkan uang pas saat kurir tiba di lokasi Anda.',
              style: TextStyle(fontSize:12, color:AppColors.textSecondary))),
        ])),
    ],
  ]);

  Widget _row(String label, String val) => Padding(padding: const EdgeInsets.only(bottom:10),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width:100, child: Text(label, style: const TextStyle(fontSize:12, color:AppColors.textSecondary))),
      Expanded(child: Text(val, style: const TextStyle(fontSize:12, fontWeight:FontWeight.w600, color:AppColors.textPrimary))),
    ]));

  // ── BOTTOM BUTTON ──────────────────────────────────────────
  Widget _bottomBtn() {
    final String label;
    final bool enabled;
    final VoidCallback? onTap;

    if (_step == 0) {
      label   = 'Lanjut ke Pembayaran →';
      enabled = _addrOk;
      onTap   = enabled ? () => setState(() => _step = 1) : null;
    } else if (_step == 1) {
      label   = 'Lanjut ke Konfirmasi →';
      enabled = _method != null;
      onTap   = enabled ? () => setState(() => _step = 2) : null;
    } else {
      label   = 'Konfirmasi & Pesan Sekarang';
      enabled = true;
      onTap   = () { Navigator.pop(context); widget.onConfirm(); };
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20,10,20,20),
      decoration: const BoxDecoration(color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width:.8))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (_step > 0) Padding(padding: const EdgeInsets.only(bottom:8),
          child: GestureDetector(onTap: () => setState(() => _step--),
            child: const Text('← Kembali', style: TextStyle(fontSize:13, color:AppColors.primary, fontWeight:FontWeight.w700)))),
        SizedBox(width: double.infinity,
          child: ElevatedButton(onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: enabled ? AppColors.primary : AppColors.sage,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical:14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation:0),
            child: Text(label, style: const TextStyle(fontSize:15, fontWeight:FontWeight.w700)))),
      ]),
    );
  }
}

// ============================================================
// FAKE QR CODE PAINTER
// ============================================================
class _QRPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint  = Paint()..color = AppColors.textPrimary;
    final border = Paint()..color = AppColors.textPrimary..style = PaintingStyle.stroke..strokeWidth = 2;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), border);

    final rand = Random(99);
    final cell = size.width / 21;

    for (int r = 0; r < 21; r++) {
      for (int c = 0; c < 21; c++) {
        final isFinder = (r < 7 && c < 7) || (r < 7 && c >= 14) || (r >= 14 && c < 7);
        final draw = isFinder ? _finder(r, c) : rand.nextBool();
        if (draw) canvas.drawRect(Rect.fromLTWH(c * cell, r * cell, cell - .5, cell - .5), paint);
      }
    }
  }

  bool _finder(int r, int c) {
    int row = r < 7 ? r : r - 14;
    int col = c < 7 ? c : c - 14;
    if (row < 0 || row > 6 || col < 0 || col > 6) return false;
    if (row == 0 || row == 6 || col == 0 || col == 6) return true;
    if (row >= 2 && row <= 4 && col >= 2 && col <= 4) return true;
    return false;
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ============================================================
// MAIN
// ============================================================
void main() => runApp(const MaterialApp(
  debugShowCheckedModeBanner: false,
  title: 'FitLife Shop',
  home: ShopPage(),
));