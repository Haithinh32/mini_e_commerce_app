import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../models/order.dart';

class CartService extends ChangeNotifier {
  List<CartItem> _items = [];
  List<Order> _orders = [];

  CartService() {
    _loadData();
  }

  List<CartItem> get items => _items;
  List<Order> get orders => _orders;

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  void addToCart(Product product, int quantity, String variant) {
    int index = _items.indexWhere((item) => item.product.id == product.id && item.variant == variant);
    
    if (index != -1) {
      _items[index].quantity += quantity;
    } else {
      _items.add(CartItem(product: product, quantity: quantity, variant: variant));
    }
    _saveData();
    notifyListeners();
  }

  void removeItem(int index) {
    _items.removeAt(index);
    _saveData();
    notifyListeners();
  }

  void updateQuantity(int index, int quantity) {
    if (index >= 0 && index < _items.length && quantity > 0) {
      _items[index].quantity = quantity;
      _saveData();
      notifyListeners();
    }
  }

  double get totalAmount {
    return _items.fold(0.0, (sum, item) => sum + (item.product.price * item.quantity));
  }

  void clearCart() {
    _items.clear();
    _saveData();
    notifyListeners();
  }

  void removeSelectedItems() {
    _items.removeWhere((item) => item.isSelected);
    _saveData();
    notifyListeners();
  }

  // Order methods
  void addOrder(Order order) {
    _orders.insert(0, order);
    _saveOrderData();
    notifyListeners();
  }

  // Persistence methods
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(_items.map((item) => {
      'product': {
        'id': item.product.id,
        'title': item.product.title,
        'price': item.product.price,
        'description': item.product.description,
        'category': item.product.category,
        'image': item.product.image,
        'rating': {
          'rate': item.product.rating.rate,
          'count': item.product.rating.count,
        },
      },
      'quantity': item.quantity,
      'variant': item.variant,
      'isSelected': item.isSelected,
    }).toList());
    await prefs.setString('cart_items', encodedData);
  }

  Future<void> _saveOrderData() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(_orders.map((o) => o.toJson()).toList());
    await prefs.setString('order_history', encodedData);
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load Cart
    final String? cartData = prefs.getString('cart_items');
    if (cartData != null) {
      final List<dynamic> decodedData = jsonDecode(cartData);
      _items = decodedData.map((item) => CartItem(
        product: Product.fromJson(item['product']),
        quantity: item['quantity'],
        variant: item['variant'],
        isSelected: item['isSelected'] ?? false,
      )).toList();
    }

    // Load Orders
    final String? orderData = prefs.getString('order_history');
    if (orderData != null) {
      final List<dynamic> decodedData = jsonDecode(orderData);
      _orders = decodedData.map((o) => Order.fromJson(o)).toList();
    }
    
    notifyListeners();
  }
}
