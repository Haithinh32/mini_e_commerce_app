import 'package:flutter/material.dart' hide CarouselController;
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  int _limit = 10;
  int _currentBannerIndex = 0;
  String _searchQuery = '';

  final List<String> _banners = [
    'https://img.freepik.com/free-vector/horizontal-sale-banner-template_23-2148897328.jpg',
    'https://img.freepik.com/free-vector/flat-style-shopping-sale-background_23-2147753234.jpg',
    'https://img.freepik.com/free-vector/shopping-center-promotion-banner_23-2148334469.jpg',
  ];

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Thời trang', 'icon': Icons.checkroom},
    {'name': 'Điện thoại', 'icon': Icons.smartphone},
    {'name': 'Mỹ phẩm', 'icon': Icons.face},
    {'name': 'Điện tử', 'icon': Icons.tv},
    {'name': 'Gia dụng', 'icon': Icons.home_repair_service},
    {'name': 'Sách', 'icon': Icons.book},
    {'name': 'Thể thao', 'icon': Icons.sports_soccer},
    {'name': 'Đồ chơi', 'icon': Icons.toys},
    {'name': 'Sức khỏe', 'icon': Icons.health_and_safety},
    {'name': 'Giày dép', 'icon': Icons.ice_skating},
  ];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts({bool isRefresh = false}) async {
    if (isRefresh) {
      _limit = 10;
    }
    setState(() {
      if (isRefresh) _isLoading = true;
      else _isLoadingMore = true;
    });

    try {
      final products = await ApiService.getProducts(limit: isRefresh ? 10 : _limit);
      setState(() {
        _allProducts = products;
        _applySearch();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _applySearch() {
    if (_searchQuery.isEmpty) {
      _filteredProducts = _allProducts;
    } else {
      _filteredProducts = _allProducts
          .where((p) => p.title.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _applySearch();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore && _searchQuery.isEmpty) {
      _limit += 10;
      _fetchProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => _fetchProducts(isRefresh: true),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            _buildAppBar(),
            if (_searchQuery.isEmpty) ...[
              SliverToBoxAdapter(child: _buildBanner()),
              SliverToBoxAdapter(child: _buildCategories()),
            ],
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Container(width: 4, height: 20, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text(
                      _searchQuery.isEmpty ? 'GỢI Ý HÔM NAY' : 'KẾT QUẢ TÌM KIẾM',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange),
                    ),
                  ],
                ),
              ),
            ),
            _buildProductGrid(),
            if (_isLoadingMore && _searchQuery.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 120,
      backgroundColor: Colors.orange,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange, Colors.deepOrange],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Row(
          children: [
            Expanded(
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        style: const TextStyle(fontSize: 12),
                        decoration: const InputDecoration(
                          hintText: 'Tìm kiếm trên Mini Shop',
                          hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                        child: const Icon(Icons.close, size: 18, color: Colors.grey),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      title: const Text(
        'TH4 - Nhóm G15_C3',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.shopping_cart, color: Colors.white),
          onPressed: () {
            // Navigate to Cart
          },
        ),
      ],
    );
  }

  Widget _buildBanner() {
    return Column(
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: 180,
            autoPlay: true,
            viewportFraction: 1.0,
            onPageChanged: (index, reason) {
              setState(() => _currentBannerIndex = index);
            },
          ),
          items: _banners.map((url) {
            return Builder(
              builder: (BuildContext context) {
                return Container(
                  width: MediaQuery.of(context).size.width,
                  margin: const EdgeInsets.symmetric(horizontal: 0),
                  child: CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                  ),
                );
              },
            );
          }).toList(),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _banners.asMap().entries.map((entry) {
            return Container(
              width: 8.0,
              height: 8.0,
              margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.orange)
                    .withOpacity(_currentBannerIndex == entry.key ? 0.9 : 0.4),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategories() {
    return Container(
      height: 180,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.0,
        ),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_categories[index]['icon'], color: Colors.orange),
              ),
              const SizedBox(height: 4),
              Text(
                _categories[index]['name'],
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProductGrid() {
    if (_isLoading && _filteredProducts.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_filteredProducts.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: Text('Không tìm thấy sản phẩm nào.')),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.7,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final product = _filteredProducts[index];
            return ProductCard(
              product: product,
              onTap: () {
                // Navigate to Product Detail
              },
            );
          },
          childCount: _filteredProducts.length,
        ),
      ),
    );
  }
}
