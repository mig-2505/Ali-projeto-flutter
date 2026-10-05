import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const AliApp());

// Endereço da API (backend/). Emulador Android: --dart-define=API_URL=http://10.0.2.2:5000
const apiUrl = String.fromEnvironment('API_URL', defaultValue: 'http://localhost:5000');

Future<List<dynamic>> apiGet(String path) async {
  final res = await http.get(Uri.parse('$apiUrl$path'));
  if (res.statusCode != 200) throw Exception('GET $path falhou (${res.statusCode})');
  return jsonDecode(utf8.decode(res.bodyBytes)) as List;
}

// ─── Tokens de design (paleta original de src/index.css) ──────────────────

class AliColors {
  static const background = Color(0xFFF5F3EE);
  static const foreground = Color(0xFF12183A);
  static const card = Color(0xFFFFFFFF);
  static const primary = Color(0xFF1E2D6B);
  static const secondary = Color(0xFFE2E6F5);
  static const mutedForeground = Color(0xFF7880A4);
  static const accent = Color(0xFFE8940A);
  static const border = Color(0xFFDDD9D0);
}

String money(double v) => 'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

/// Botão pequeno (quadrado/pílula) reaproveitado pelos controles de "+ / -" e sino/coração.
Widget _iconBox({
  required double size,
  required Color background,
  required IconData icon,
  required Color iconColor,
  double iconSize = 14,
  double radius = 8,
  BoxShape shape = BoxShape.rectangle,
  VoidCallback? onTap,
}) {
  final child = Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: background,
      shape: shape,
      borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(radius),
    ),
    child: Icon(icon, size: iconSize, color: iconColor),
  );
  return onTap == null ? child : GestureDetector(onTap: onTap, child: child);
}

// ─── Dados ──────────────────────────────────────────────────────────────────

class AliCategory {
  final String id, label, emoji;
  const AliCategory(this.id, this.label, this.emoji);
  AliCategory.fromJson(Map<String, dynamic> j) : this(j['id'], j['label'], j['emoji']);
}

// Pseudo-categoria do filtro; as demais vêm da API.
const allCategory = AliCategory('all', 'Todos', '✦');

class Producer {
  final int id;
  final String name, specialty, avatar;
  final double rating;
  const Producer(this.id, this.name, this.specialty, this.avatar, this.rating);
  Producer.fromJson(Map<String, dynamic> j)
      : this(j['id'], j['name'], j['specialty'], j['avatar'], (j['rating'] as num).toDouble());
}


enum TagColor { primary, accent }

class AliProduct {
  final int id;
  final String name, producer, unit, category, image, tag;
  final double price;
  final TagColor tagColor;
  const AliProduct({
    required this.id,
    required this.name,
    required this.producer,
    required this.price,
    required this.unit,
    required this.category,
    required this.image,
    required this.tag,
    required this.tagColor,
  });
  AliProduct.fromJson(Map<String, dynamic> j)
      : this(
          id: j['id'],
          name: j['name'],
          producer: j['producer'],
          price: (j['price'] as num).toDouble(),
          unit: j['unit'],
          category: j['category'],
          image: j['image'],
          tag: j['tag'],
          tagColor: TagColor.values.byName(j['tag_color']),
        );
}


// ─── Aplicativo ─────────────────────────────────────────────────────────────

class AliApp extends StatelessWidget {
  const AliApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ali',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AliColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AliColors.primary,
          primary: AliColors.primary,
          secondary: AliColors.accent,
        ),
        textTheme: GoogleFonts.outfitTextTheme(),
      ),
      home: const AliHomePage(),
    );
  }
}

class AliHomePage extends StatefulWidget {
  const AliHomePage({super.key});

  @override
  State<AliHomePage> createState() => _AliHomePageState();
}

class _AliHomePageState extends State<AliHomePage> {
  int navIndex = 0;
  String activeCategory = 'all';
  final Set<int> liked = {};
  final Map<int, int> cart = {}; // id do produto -> quantidade
  bool orderPlaced = false;
  List<AliCategory> categories = [];
  List<Producer> producers = [];
  List<AliProduct> products = [];
  bool loading = true;
  String? loadError;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() {
      loading = true;
      loadError = null;
    });
    try {
      final [cats, prods, items] =
          await Future.wait([apiGet('/categories'), apiGet('/producers'), apiGet('/products')]);
      setState(() {
        categories = [allCategory, ...cats.map((j) => AliCategory.fromJson(j))];
        producers = prods.map((j) => Producer.fromJson(j)).toList();
        products = items.map((j) => AliProduct.fromJson(j)).toList();
        loading = false;
      });
    } catch (e) {
      setState(() {
        loadError = '$e';
        loading = false;
      });
    }
  }

  int get totalCartQty => cart.values.fold(0, (a, b) => a + b);

  List<AliProduct> get filteredProducts => activeCategory == 'all'
      ? products
      : products.where((p) => p.category == activeCategory).toList();

  void toggleLike(int id) => setState(() {
        liked.contains(id) ? liked.remove(id) : liked.add(id);
      });

  void addToCart(int id) => setState(() {
        cart.update(id, (q) => q + 1, ifAbsent: () => 1);
      });

  void updateQty(int id, int delta) => setState(() {
        final next = (cart[id] ?? 0) + delta;
        if (next <= 0) {
          cart.remove(id);
        } else {
          cart[id] = next;
        }
      });

  void removeFromCart(int id) => setState(() => cart.remove(id));

  Future<void> placeOrder() async {
    try {
      final res = await http.post(
        Uri.parse('$apiUrl/orders'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'items': [for (final e in cart.entries) {'product_id': e.key, 'qty': e.value}],
        }),
      );
      if (res.statusCode != 201) throw Exception(utf8.decode(res.bodyBytes));
      setState(() {
        orderPlaced = true;
        cart.clear();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Não foi possível enviar o pedido: $e')));
    }
  }

  void backFromSuccess() => setState(() {
        orderPlaced = false;
        navIndex = 0;
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(bottom: false, child: _body()),
      bottomNavigationBar: _bottomNav(),
    );
  }

  Widget _body() {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Não foi possível carregar os dados do servidor.', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: loadData, child: const Text('Tentar de novo')),
          ]),
        ),
      );
    }
    switch (navIndex) {
      case 0:
        return HomeTab(
          categories: categories,
          producers: producers,
          activeCategory: activeCategory,
          onCategory: (c) => setState(() => activeCategory = c),
          liked: liked,
          onToggleLike: toggleLike,
          cart: cart,
          onAdd: addToCart,
          onUpdateQty: updateQty,
          filteredProducts: filteredProducts,
        );
      case 2:
        return orderPlaced
            ? OrderSuccessView(onBack: backFromSuccess)
            : CartView(
                products: products,
                cart: cart,
                onUpdateQty: updateQty,
                onRemove: removeFromCart,
                onOrder: placeOrder,
              );
      default:
        return PlaceholderTab(isExplore: navIndex == 1);
    }
  }

  Widget _bottomNav() {
    final bagIcon = totalCartQty > 0
        ? Badge(label: Text('$totalCartQty'), child: const Icon(Icons.shopping_bag_outlined))
        : const Icon(Icons.shopping_bag_outlined);
    final bagIconSelected = totalCartQty > 0
        ? Badge(label: Text('$totalCartQty'), child: const Icon(Icons.shopping_bag))
        : const Icon(Icons.shopping_bag);

    return NavigationBar(
      selectedIndex: navIndex,
      onDestinationSelected: (i) => setState(() => navIndex = i),
      indicatorColor: AliColors.secondary,
      destinations: [
        const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Início'),
        const NavigationDestination(icon: Icon(Icons.search), label: 'Explorar'),
        NavigationDestination(icon: bagIcon, selectedIcon: bagIconSelected, label: 'Cesta'),
        const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
      ],
    );
  }
}

// ─── Aba Início ─────────────────────────────────────────────────────────────

class HomeTab extends StatelessWidget {
  final List<AliCategory> categories;
  final List<Producer> producers;
  final String activeCategory;
  final ValueChanged<String> onCategory;
  final Set<int> liked;
  final ValueChanged<int> onToggleLike;
  final Map<int, int> cart;
  final ValueChanged<int> onAdd;
  final void Function(int id, int delta) onUpdateQty;
  final List<AliProduct> filteredProducts;

  const HomeTab({
    super.key,
    required this.categories,
    required this.producers,
    required this.activeCategory,
    required this.onCategory,
    required this.liked,
    required this.onToggleLike,
    required this.cart,
    required this.onAdd,
    required this.onUpdateQty,
    required this.filteredProducts,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 4, bottom: 16),
      children: [
        _header(),
        const SizedBox(height: 8),
        _searchBar(),
        const SizedBox(height: 20),
        _hero(),
        const SizedBox(height: 20),
        _categoryChips(),
        const SizedBox(height: 20),
        _producersSection(),
        const SizedBox(height: 20),
        _productsSection(),
      ],
    );
  }

  Widget _header() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Bom dia, Ana ☀️', style: TextStyle(color: AliColors.mutedForeground, fontSize: 14)),
                Text('ali',
                    style: GoogleFonts.fraunces(
                        fontSize: 30, fontWeight: FontWeight.w700, color: AliColors.primary, letterSpacing: -0.5)),
              ],
            ),
            Stack(
              clipBehavior: Clip.none,
              children: [
                _iconBox(
                  size: 44,
                  background: AliColors.secondary,
                  icon: Icons.notifications_outlined,
                  iconColor: AliColors.primary,
                  iconSize: 20,
                  shape: BoxShape.circle,
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: AliColors.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: AliColors.background, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _searchBar() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AliColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AliColors.border, width: 1.5),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, size: 18, color: AliColors.mutedForeground),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Buscar produtos, produtores…',
                    style: TextStyle(color: AliColors.mutedForeground, fontSize: 14)),
              ),
              _iconBox(size: 32, background: AliColors.primary, icon: Icons.tune, iconColor: Colors.white, iconSize: 14, radius: 10),
            ],
          ),
        ),
      );

  Widget _hero() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          height: 156,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: AliColors.primary, borderRadius: BorderRadius.circular(22)),
          child: Stack(
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: 0.2,
                  child: Image.network(
                    'https://images.unsplash.com/photo-1488459716781-31db52582fe9?w=800&h=320&fit=crop&auto=format',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: -40,
                right: -30,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: AliColors.accent.withOpacity(0.18)),
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AliColors.accent, borderRadius: BorderRadius.circular(999)),
                      child: const Text('Destaque da semana',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 8),
                    Text('Do campo direto\nà sua mesa 🌿',
                        style: GoogleFonts.fraunces(
                            color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, height: 1.2)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _categoryChips() => SizedBox(
        height: 38,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, i) {
            final cat = categories[i];
            final active = cat.id == activeCategory;
            return GestureDetector(
              onTap: () => onCategory(cat.id),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? AliColors.primary : AliColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: active ? null : Border.all(color: AliColors.border, width: 1.5),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(cat.emoji),
                  const SizedBox(width: 6),
                  Text(cat.label,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: active ? Colors.white : AliColors.foreground)),
                ]),
              ),
            );
          },
        ),
      );

  Widget _producersSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Produtores perto de você',
                    style: GoogleFonts.fraunces(fontSize: 16, fontWeight: FontWeight.w600, color: AliColors.foreground)),
                const Text('Ver todos', style: TextStyle(color: AliColors.accent, fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 150,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: producers.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) => _producerCard(producers[i]),
            ),
          ),
        ],
      );

  Widget _producerCard(Producer p) => Container(
        width: 108,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AliColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AliColors.border, width: 1.5),
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AliColors.secondary, width: 2.5)),
              child: ClipOval(child: Image.network(p.avatar, width: 52, height: 52, fit: BoxFit.cover)),
            ),
            const SizedBox(height: 8),
            Text(p.name.split(' ').first,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AliColors.foreground),
                textAlign: TextAlign.center),
            const SizedBox(height: 2),
            Text(p.specialty,
                style: const TextStyle(fontSize: 11, color: AliColors.mutedForeground),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.star, size: 12, color: AliColors.accent),
              const SizedBox(width: 3),
              Text('${p.rating}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AliColors.foreground)),
            ]),
          ],
        ),
      );

  Widget _productsSection() {
    final title = activeCategory == 'all' ? 'Produtos frescos' : categories.firstWhere((c) => c.id == activeCategory).label;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: GoogleFonts.fraunces(fontSize: 16, fontWeight: FontWeight.w600, color: AliColors.foreground)),
              Text('${filteredProducts.length} itens', style: const TextStyle(fontSize: 12, color: AliColors.mutedForeground)),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredProducts.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.66,
            ),
            itemBuilder: (context, i) {
              final product = filteredProducts[i];
              return ProductCard(
                product: product,
                liked: liked.contains(product.id),
                qty: cart[product.id] ?? 0,
                onToggleLike: () => onToggleLike(product.id),
                onAdd: () => onAdd(product.id),
                onRemove: () => onUpdateQty(product.id, -1),
              );
            },
          ),
        ],
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final AliProduct product;
  final bool liked;
  final int qty;
  final VoidCallback onToggleLike;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const ProductCard({
    super.key,
    required this.product,
    required this.liked,
    required this.qty,
    required this.onToggleLike,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AliColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AliColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 118,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(product.image, fit: BoxFit.cover),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: product.tagColor == TagColor.accent ? AliColors.accent : AliColors.primary,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(product.tag, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: _iconBox(
                    size: 28,
                    background: Colors.white.withOpacity(0.9),
                    icon: liked ? Icons.favorite : Icons.favorite_border,
                    iconColor: liked ? AliColors.accent : AliColors.mutedForeground,
                    shape: BoxShape.circle,
                    onTap: onToggleLike,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AliColors.foreground),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(product.producer,
                          style: const TextStyle(fontSize: 11, color: AliColors.mutedForeground),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: RichText(
                          text: TextSpan(children: [
                            TextSpan(text: money(product.price), style: GoogleFonts.fraunces(fontSize: 15, fontWeight: FontWeight.w700, color: AliColors.primary)),
                            const TextSpan(text: ' /', style: TextStyle(fontSize: 11, color: AliColors.mutedForeground)),
                            TextSpan(text: product.unit, style: const TextStyle(fontSize: 11, color: AliColors.mutedForeground)),
                          ]),
                        ),
                      ),
                      qty > 0
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(color: AliColors.secondary, borderRadius: BorderRadius.circular(10)),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                _iconBox(size: 22, background: AliColors.primary, icon: Icons.remove, iconColor: Colors.white, iconSize: 13, radius: 6, onTap: onRemove),
                                SizedBox(width: 18, child: Text('$qty', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AliColors.foreground))),
                                _iconBox(size: 22, background: AliColors.accent, icon: Icons.add, iconColor: Colors.white, iconSize: 13, radius: 6, onTap: onAdd),
                              ]),
                            )
                          : _iconBox(size: 30, background: AliColors.accent, icon: Icons.add, iconColor: Colors.white, iconSize: 16, radius: 10, onTap: onAdd),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Aba Cesta ──────────────────────────────────────────────────────────────

class CartView extends StatelessWidget {
  final List<AliProduct> products;
  final Map<int, int> cart;
  final void Function(int id, int delta) onUpdateQty;
  final ValueChanged<int> onRemove;
  final VoidCallback onOrder;

  const CartView({
    super.key,
    required this.products,
    required this.cart,
    required this.onUpdateQty,
    required this.onRemove,
    required this.onOrder,
  });

  @override
  Widget build(BuildContext context) {
    if (cart.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.shopping_bag_outlined, size: 48, color: AliColors.mutedForeground),
              const SizedBox(height: 16),
              Text('Sua cesta está vazia', style: GoogleFonts.fraunces(fontSize: 18, fontWeight: FontWeight.w600, color: AliColors.foreground)),
              const SizedBox(height: 4),
              const Text('Adicione produtos frescos dos produtores perto de você.',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AliColors.mutedForeground)),
            ],
          ),
        ),
      );
    }

    final entries = cart.entries.map((e) => (product: products.firstWhere((p) => p.id == e.key), qty: e.value)).toList();
    final totalQty = cart.values.fold(0, (a, b) => a + b);
    final subtotal = entries.fold(0.0, (sum, e) => sum + e.product.price * e.qty);
    const delivery = 5.9;
    final total = subtotal + delivery;
    final producerCount = entries.map((e) => e.product.producer).toSet().length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Minha Cesta', style: GoogleFonts.fraunces(fontSize: 22, fontWeight: FontWeight.w700, color: AliColors.foreground)),
              const SizedBox(height: 2),
              Text('$totalQty ${totalQty == 1 ? 'item' : 'itens'} de $producerCount produtores',
                  style: const TextStyle(fontSize: 14, color: AliColors.mutedForeground)),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              ...entries.map((e) => _cartRow(e.product, e.qty)),
              _deliveryNote(),
              const SizedBox(height: 12),
              _summary(subtotal, delivery, total, totalQty),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: onOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: AliColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
              ),
              icon: const Icon(Icons.shopping_bag),
              label: Text('Finalizar Pedido · ${money(total)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _cartRow(AliProduct product, int qty) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AliColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AliColors.border, width: 1.5)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(product.image, width: 64, height: 64, fit: BoxFit.cover),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AliColors.foreground), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(product.producer, style: const TextStyle(fontSize: 12, color: AliColors.mutedForeground)),
                  const SizedBox(height: 4),
                  Text(money(product.price * qty), style: GoogleFonts.fraunces(fontSize: 14, fontWeight: FontWeight.w700, color: AliColors.accent)),
                ],
              ),
            ),
            Column(
              children: [
                _iconBox(size: 24, background: Colors.transparent, icon: Icons.delete_outline, iconColor: AliColors.mutedForeground, iconSize: 18, onTap: () => onRemove(product.id)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AliColors.secondary, borderRadius: BorderRadius.circular(10)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    _iconBox(
                      size: 22,
                      background: qty == 1 ? Colors.transparent : AliColors.primary,
                      icon: Icons.remove,
                      iconColor: qty == 1 ? AliColors.mutedForeground : Colors.white,
                      iconSize: 12,
                      radius: 6,
                      onTap: () => onUpdateQty(product.id, -1),
                    ),
                    SizedBox(width: 20, child: Text('$qty', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AliColors.foreground))),
                    _iconBox(size: 22, background: AliColors.primary, icon: Icons.add, iconColor: Colors.white, iconSize: 12, radius: 6, onTap: () => onUpdateQty(product.id, 1)),
                  ]),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _deliveryNote() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFE2E6F5), Color(0xFFEAE8F8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AliColors.border, width: 1.5),
        ),
        child: const Row(
          children: [
            Text('🛵', style: TextStyle(fontSize: 20)),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Entrega direta do produtor', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AliColors.primary)),
                  Text('Chegará amanhã entre 8h–12h', style: TextStyle(fontSize: 12, color: AliColors.mutedForeground)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _summary(double subtotal, double delivery, double total, int totalQty) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AliColors.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: AliColors.border, width: 1.5)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Resumo do pedido', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AliColors.foreground)),
            const SizedBox(height: 12),
            _summaryRow('Subtotal ($totalQty itens)', money(subtotal)),
            const SizedBox(height: 8),
            _summaryRow('Taxa de entrega', money(delivery)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1, color: AliColors.border)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: GoogleFonts.fraunces(fontSize: 16, fontWeight: FontWeight.w700, color: AliColors.foreground)),
                Text(money(total), style: GoogleFonts.fraunces(fontSize: 20, fontWeight: FontWeight.w700, color: AliColors.primary)),
              ],
            ),
          ],
        ),
      );

  Widget _summaryRow(String label, String value) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: AliColors.mutedForeground)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AliColors.foreground)),
        ],
      );
}

// ─── Pedido confirmado ──────────────────────────────────────────────────────

class OrderSuccessView extends StatelessWidget {
  final VoidCallback onBack;
  const OrderSuccessView({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _iconBox(size: 88, background: AliColors.secondary, icon: Icons.check_circle_outline, iconColor: AliColors.primary, iconSize: 48, shape: BoxShape.circle),
            const SizedBox(height: 20),
            Text('Pedido confirmado!', style: GoogleFonts.fraunces(fontSize: 24, fontWeight: FontWeight.w700, color: AliColors.foreground)),
            const SizedBox(height: 8),
            const Text.rich(
              TextSpan(children: [
                TextSpan(text: 'Os produtores já receberam seu pedido. A entrega chegará amanhã entre '),
                TextSpan(text: '8h e 12h', style: TextStyle(fontWeight: FontWeight.w700)),
                TextSpan(text: '.'),
              ]),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AliColors.mutedForeground, height: 1.5),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(color: AliColors.secondary, borderRadius: BorderRadius.circular(12)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Text('🌱'),
                SizedBox(width: 8),
                Text('Você apoiou 2 produtores locais', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AliColors.primary)),
              ]),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: onBack,
              child: const Text('Voltar para o início',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AliColors.accent, decoration: TextDecoration.underline)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Telas provisórias de Explorar / Perfil ─────────────────────────────────

class PlaceholderTab extends StatelessWidget {
  final bool isExplore;
  const PlaceholderTab({super.key, required this.isExplore});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _iconBox(
              size: 72,
              background: AliColors.secondary,
              icon: isExplore ? Icons.search : Icons.person_outline,
              iconColor: AliColors.primary,
              iconSize: 28,
              shape: BoxShape.circle,
            ),
            const SizedBox(height: 16),
            Text('Em breve', style: GoogleFonts.fraunces(fontSize: 18, fontWeight: FontWeight.w700, color: AliColors.foreground)),
            const SizedBox(height: 6),
            Text(
              isExplore ? 'Explore produtores e mercados da sua região.' : 'Gerencie seus dados, pedidos e endereços.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AliColors.mutedForeground),
            ),
          ],
        ),
      ),
    );
  }
}
