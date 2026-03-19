import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/cart_item.dart';
import '../services/cart_service.dart';
import 'purchase_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool selectAll = false;
  final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');

  double getTotalPrice(List<CartItem> cartItems) {
    return cartItems.fold(0, (sum, item) {
      if (item.isSelected) {
        return sum + (item.product.price * item.quantity);
      }
      return sum;
    });
  }

  int getSelectedCount(List<CartItem> cartItems) {
    return cartItems.where((item) => item.isSelected).length;
  }

  void updateSelectAllStatus(List<CartItem> cartItems) {
    setState(() {
      selectAll =
          getSelectedCount(cartItems) == cartItems.length && cartItems.isNotEmpty;
    });
  }

  void toggleSelectAll(List<CartItem> cartItems, bool value) {
    setState(() {
      selectAll = value;
      for (var item in cartItems) {
        item.isSelected = value;
      }
    });
  }

  void toggleItemSelection(List<CartItem> cartItems, int index) {
    setState(() {
      cartItems[index].isSelected = !cartItems[index].isSelected;
      updateSelectAllStatus(cartItems);
    });
  }

  void increaseQuantity(BuildContext context, List<CartItem> cartItems, int index) {
    context.read<CartService>().updateQuantity(index, cartItems[index].quantity + 1);
  }

  void decreaseQuantity(BuildContext context, List<CartItem> cartItems, int index) {
    if (cartItems[index].quantity <= 1) {
      showDeleteDialog(context, cartItems, index);
    } else {
      context.read<CartService>().updateQuantity(index, cartItems[index].quantity - 1);
    }
  }

  void showDeleteDialog(BuildContext context, List<CartItem> cartItems, int index) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa sản phẩm'),
        content: Text(
          'Bạn có muốn xóa "${cartItems[index].product.title}" khỏi giỏ hàng?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<CartService>().removeItem(index);
              updateSelectAllStatus(context.read<CartService>().items);
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void dismissItem(BuildContext context, List<CartItem> cartItems, int index) {
    final removedItem = cartItems[index];
    final cartService = context.read<CartService>();
    cartService.removeItem(index);
    updateSelectAllStatus(cartService.items);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${removedItem.product.title} đã bị xóa'),
        action: SnackBarAction(
          label: 'Hoàn tác',
          onPressed: () {
            cartService.addToCart(removedItem.product, removedItem.quantity, removedItem.variant);
          },
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartService = context.watch<CartService>();
    final cartItems = cartService.items;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Giỏ hàng'),
        centerTitle: true,
        elevation: 0,
      ),
      body: cartItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Giỏ hàng trống',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                ListView.builder(
                  padding: const EdgeInsets.only(bottom: 200),
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    return Dismissible(
                      key: UniqueKey(),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) => dismissItem(context, cartItems, index),
                      child: CartItemWidget(
                        item: item,
                        isSelected: item.isSelected,
                        currencyFormat: currencyFormat,
                        onSelectionChanged: () => toggleItemSelection(cartItems, index),
                        onIncreaseQuantity: () => increaseQuantity(context, cartItems, index),
                        onDecreaseQuantity: () => decreaseQuantity(context, cartItems, index),
                      ),
                    );
                  },
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Checkbox(
                                value: selectAll,
                                onChanged: (value) =>
                                    toggleSelectAll(cartItems, value ?? false),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Chọn tất cả',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Số lượng: ${cartItems.where((item) => item.isSelected).fold(0, (sum, item) => sum + item.quantity)} sản phẩm',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    'Đã chọn: ${getSelectedCount(cartItems)}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.orange[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Tổng thanh toán:',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  Text(
                                    currencyFormat.format(getTotalPrice(cartItems)),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: getSelectedCount(cartItems) > 0
                                      ? () {
                                          final selectedItems = cartItems.where((item) => item.isSelected).toList();
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => PurchaseScreen(selectedItems: selectedItems),
                                            ),
                                          );
                                        }
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    disabledBackgroundColor: Colors.grey[300],
                                  ),
                                  child: const Text(
                                    'Tiến hành thanh toán',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
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

class CartItemWidget extends StatelessWidget {
  final CartItem item;
  final bool isSelected;
  final NumberFormat currencyFormat;
  final VoidCallback onSelectionChanged;
  final VoidCallback onIncreaseQuantity;
  final VoidCallback onDecreaseQuantity;

  const CartItemWidget({
    Key? key,
    required this.item,
    required this.isSelected,
    required this.currencyFormat,
    required this.onSelectionChanged,
    required this.onIncreaseQuantity,
    required this.onDecreaseQuantity,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected ? Colors.orange.withOpacity(0.05) : Colors.white,
      child: Row(
        children: [
          Checkbox(value: isSelected, onChanged: (_) => onSelectionChanged()),
          const SizedBox(width: 8),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[200],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.product.image,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.image_not_supported),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.variant,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  currencyFormat.format(item.product.price),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: onIncreaseQuantity,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.add, size: 16),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.quantity.toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: onDecreaseQuantity,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.remove, size: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}