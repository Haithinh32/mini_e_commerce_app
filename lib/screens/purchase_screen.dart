import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../services/cart_service.dart';

class PurchaseScreen extends StatefulWidget {
  final List<CartItem>? selectedItems;
  final int initialTabIndex;

  const PurchaseScreen({Key? key, this.selectedItems, this.initialTabIndex = 0}) : super(key: key);

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  final _addressController = TextEditingController();
  String _paymentMethod = 'COD';
  final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  void _placeOrder(BuildContext context) {
    if (_addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập địa chỉ nhận hàng')),
      );
      return;
    }

    final totalAmount = widget.selectedItems!.fold(0.0, (sum, item) => sum + (item.product.price * item.quantity));
    
    final newOrder = Order(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      items: List.from(widget.selectedItems!),
      totalAmount: totalAmount,
      date: DateTime.now(),
      status: OrderStatus.pending,
      address: _addressController.text,
      paymentMethod: _paymentMethod,
    );

    context.read<CartService>().addOrder(newOrder);
    context.read<CartService>().removeSelectedItems();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: const Text(
          'Đặt hàng thành công!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Về Trang Chủ', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<CartService>().orders;
    final hasCheckout = widget.selectedItems != null && widget.selectedItems!.isNotEmpty;

    return DefaultTabController(
      length: hasCheckout ? 5 : 4,
      initialIndex: widget.initialTabIndex,
      child: Scaffold(
        appBar: AppBar(
          title: Text(hasCheckout ? 'Thanh toán & Đơn mua' : 'Đơn mua'),
          centerTitle: true,
          bottom: TabBar(
            isScrollable: true,
            labelColor: Colors.orange,
            unselectedLabelColor: Colors.black,
            indicatorColor: Colors.orange,
            tabs: [
              if (hasCheckout) const Tab(text: 'Thanh toán'),
              const Tab(text: 'Chờ xác nhận'),
              const Tab(text: 'Đang giao'),
              const Tab(text: 'Đã giao'),
              const Tab(text: 'Đã hủy'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            if (hasCheckout) _buildCheckoutTab(context),
            _OrderList(orders: orders.where((o) => o.status == OrderStatus.pending).toList(), currencyFormat: currencyFormat),
            _OrderList(orders: orders.where((o) => o.status == OrderStatus.shipping).toList(), currencyFormat: currencyFormat),
            _OrderList(orders: orders.where((o) => o.status == OrderStatus.delivered).toList(), currencyFormat: currencyFormat),
            _OrderList(orders: orders.where((o) => o.status == OrderStatus.cancelled).toList(), currencyFormat: currencyFormat),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutTab(BuildContext context) {
    final totalAmount = widget.selectedItems!.fold(0.0, (sum, item) => sum + (item.product.price * item.quantity));
    
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Địa chỉ nhận hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                hintText: 'Nhập địa chỉ của bạn',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on, color: Colors.orange),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Sản phẩm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ...widget.selectedItems!.map((item) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Image.network(item.product.image, width: 50, height: 50, fit: BoxFit.contain),
              title: Text(item.product.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text('PL: ${item.variant} x${item.quantity}'),
              trailing: Text(currencyFormat.format(item.product.price * item.quantity)),
            )).toList(),
            const Divider(),
            const Text('Phương thức thanh toán', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            RadioListTile(
              title: const Text('Thanh toán khi nhận hàng (COD)'),
              value: 'COD',
              groupValue: _paymentMethod,
              activeColor: Colors.orange,
              onChanged: (value) => setState(() => _paymentMethod = value.toString()),
            ),
            RadioListTile(
              title: const Text('Ví Momo'),
              value: 'Momo',
              groupValue: _paymentMethod,
              activeColor: Colors.orange,
              onChanged: (value) => setState(() => _paymentMethod = value.toString()),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tổng thanh toán'),
                Text(
                  currencyFormat.format(totalAmount),
                  style: const TextStyle(color: Colors.orange, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(
              width: 150,
              height: 50,
              child: ElevatedButton(
                onPressed: () => _placeOrder(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('ĐẶT HÀNG', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  final List<Order> orders;
  final NumberFormat currencyFormat;

  const _OrderList({required this.orders, required this.currencyFormat});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Chưa có đơn hàng nào', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return Card(
          margin: const EdgeInsets.all(8),
          child: Column(
            children: [
              ListTile(
                title: Text('Mã đơn: ${order.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Ngày đặt: ${DateFormat('dd/MM/yyyy HH:mm').format(order.date)}'),
                trailing: Text(
                  _getStatusText(order.status),
                  style: const TextStyle(color: Colors.orange),
                ),
              ),
              const Divider(),
              ...order.items.map((item) => ListTile(
                leading: Image.network(item.product.image, width: 40, height: 40, fit: BoxFit.contain),
                title: Text(item.product.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('x${item.quantity} | ${item.variant}'),
                trailing: Text(currencyFormat.format(item.product.price)),
              )),
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${order.items.length} sản phẩm'),
                    Row(
                      children: [
                        const Text('Thành tiền: '),
                        Text(
                          currencyFormat.format(order.totalAmount),
                          style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return 'Chờ xác nhận';
      case OrderStatus.shipping: return 'Đang giao';
      case OrderStatus.delivered: return 'Đã giao';
      case OrderStatus.cancelled: return 'Đã hủy';
    }
  }
}
