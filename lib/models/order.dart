import 'cart_item.dart';
import 'product.dart';

enum OrderStatus { pending, shipping, delivered, cancelled }

class Order {
  final String id;
  final List<CartItem> items;
  final double totalAmount;
  final DateTime date;
  final OrderStatus status;
  final String address;
  final String paymentMethod;

  Order({
    required this.id,
    required this.items,
    required this.totalAmount,
    required this.date,
    required this.status,
    required this.address,
    required this.paymentMethod,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'items': items.map((item) => {
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
      }).toList(),
      'totalAmount': totalAmount,
      'date': date.toIso8601String(),
      'status': status.index,
      'address': address,
      'paymentMethod': paymentMethod,
    };
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      items: (json['items'] as List).map((i) => CartItem(
        product: Product.fromJson(i['product']),
        quantity: i['quantity'],
        variant: i['variant'],
      )).toList(),
      totalAmount: json['totalAmount'],
      date: DateTime.parse(json['date']),
      status: OrderStatus.values[json['status']],
      address: json['address'],
      paymentMethod: json['paymentMethod'],
    );
  }
}
