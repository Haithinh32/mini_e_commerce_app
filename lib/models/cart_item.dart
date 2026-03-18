
import '../models/product.dart';

class CartItem {
  final Product product;
  int quantity;
  String variant; 
  bool isSelected;

  CartItem({
    required this.product,
    required this.quantity,
    required this.variant,
    this.isSelected = false,
  });
}
