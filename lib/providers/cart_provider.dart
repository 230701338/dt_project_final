import 'package:flutter/material.dart';

class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => _items;

  int getQuantity(String productId) {
    return _items[productId]?.quantity ?? 0;
  }

  double get totalPrice {
    return _items.values.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }

  void updateItem(String id, String name, int price, String imageUrl, int stock, bool increase, BuildContext context) {
    if (increase) {
      if (_items.containsKey(id)) {
        if (_items[id]!.quantity < stock) {
          _items[id] = _items[id]!.copyWith(quantity: _items[id]!.quantity + 1);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Cannot add more than available stock!")),
          );
        }
      } else {
        if (stock > 0) {
          _items[id] = CartItem(id: id, name: name, price: price, quantity: 1, imageUrl: imageUrl);
        }
      }
    } else {
      if (_items.containsKey(id) && _items[id]!.quantity > 1) {
        _items[id] = _items[id]!.copyWith(quantity: _items[id]!.quantity - 1);
      } else {
        _items.remove(id);
      }
    }

    notifyListeners();
  }
}

class CartItem {
  final String id;
  final String name;
  final int price;
  final int quantity;
  final String imageUrl;

  CartItem({required this.id, required this.name, required this.price, required this.quantity, required this.imageUrl});

  CartItem copyWith({int? quantity}) {
    return CartItem(
      id: id,
      name: name,
      price: price,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl,
    );
  }
}
