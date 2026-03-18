import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product.dart';
import '../main.dart'; // Import để sử dụng CartManager

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  String selectedSize = 'M';
  String selectedColor = 'Đỏ';
  int quantity = 1;
  bool isDescriptionExpanded = false; // Trạng thái xem thêm/thu gọn

  // Giả định giá gốc cao hơn 20%
  double get originalPrice => widget.product.price * 1.2;

  // Danh sách ảnh để vuốt ngang (Slider)
  // DummyJSON thường có mảng images, nếu không có ta dùng ảnh chính làm list
  List<String> get images => [
    widget.product.image,
    "https://picsum.photos/id/20/500/500", // Ảnh phụ giả lập 1
    "https://picsum.photos/id/30/500/500", // Ảnh phụ giả lập 2
  ];

  void _showAddToCartSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(widget.product.image, width: 80, height: 80, fit: BoxFit.cover),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("\$${widget.product.price}",
                                style: const TextStyle(color: Colors.red, fontSize: 22, fontWeight: FontWeight.bold)),
                            const Text("Kho: Còn hàng", style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
                    ],
                  ),
                  const Divider(),
                  const Text("Kích thước", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    children: ['S', 'M', 'L', 'XL'].map((size) {
                      return ChoiceChip(
                        label: Text(size),
                        selected: selectedSize == size,
                        selectedColor: Colors.orange,
                        onSelected: (selected) => setSheetState(() => selectedSize = size),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text("Màu sắc", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    children: ['Xanh', 'Đỏ', 'Đen'].map((color) {
                      return ChoiceChip(
                        label: Text(color),
                        selected: selectedColor == color,
                        selectedColor: Colors.orange,
                        onSelected: (selected) => setSheetState(() => selectedColor = color),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Số lượng", style: TextStyle(fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => quantity > 1 ? setSheetState(() => quantity--) : null,
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text('$quantity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          IconButton(
                            onPressed: () => setSheetState(() => quantity++),
                            icon: const Icon(Icons.add_circle_outline, color: Colors.orange),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                      onPressed: () {
                        // Gọi CartManager để nảy số Badge
                        CartManager.addToCart(quantity);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Đã thêm vào giỏ hàng!")),
                        );
                        // Cập nhật lại màn hình để Badge hiện con số mới
                        setState(() {});
                      },
                      child: const Text("XÁC NHẬN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          _buildCartBadge(), // Widget hiển thị giỏ hàng kèm số nảy
          const SizedBox(width: 15),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. SLIDER ẢNH (PageView để vuốt ngang)
                  SizedBox(
                    height: 350,
                    child: Hero(
                      tag: widget.product.id.toString(),
                      child: PageView.builder(
                        itemCount: images.length,
                        itemBuilder: (context, index) {
                          return CachedNetworkImage(
                            imageUrl: images[index],
                            fit: BoxFit.contain,
                          );
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 2. KHỐI GIÁ & TÊN (Có giá gốc gạch bỏ)
                        Row(
                          children: [
                            Text("\$${widget.product.price}",
                                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.red)),
                            const SizedBox(width: 12),
                            Text("\$${originalPrice.toStringAsFixed(2)}",
                                style: const TextStyle(
                                    fontSize: 18, color: Colors.grey, decoration: TextDecoration.lineThrough)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(widget.product.title,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 20),
                            Text(" ${widget.product.rating}"),
                            const SizedBox(width: 10),
                            const Text("| Đã bán 1.2k", style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                        const Divider(height: 40),

                        // 3. KHỐI PHÂN LOẠI (Có mũi tên điều hướng)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text("Chọn Kích cỡ, Màu sắc", style: TextStyle(fontWeight: FontWeight.w500)),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: _showAddToCartSheet,
                        ),
                        const Divider(height: 40),

                        // 4. MÔ TẢ CHI TIẾT (Xem thêm/Thu gọn)
                        const Text("Mô tả sản phẩm", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Text(
                          widget.product.description + " " + widget.product.description + " " + widget.product.description,
                          maxLines: isDescriptionExpanded ? null : 4,
                          overflow: isDescriptionExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.5),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => isDescriptionExpanded = !isDescriptionExpanded),
                          child: Text(
                            isDescriptionExpanded ? "Thu gọn" : "Xem thêm",
                            style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildBottomActionButtons(),
        ],
      ),
    );
  }

  Widget _buildCartBadge() {
    return Stack(
      alignment: Alignment.center,
      children: [
        const Icon(Icons.shopping_cart_outlined, color: Colors.black, size: 28),
        if (CartManager.count > 0)
          Positioned(
            right: 0,
            top: 10,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text('${CartManager.count}',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)]),
      child: SafeArea(
        child: Row(
          children: [
            const Column(
              mainAxisSize: MainAxisSize.min,
              children: [Icon(Icons.chat_bubble_outline, color: Colors.orange), Text("Chat ngay", style: TextStyle(fontSize: 10))],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.orange)),
                onPressed: _showAddToCartSheet,
                child: const Text("Thêm vào giỏ", style: TextStyle(color: Colors.orange)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                onPressed: _showAddToCartSheet,
                child: const Text("Mua ngay", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}