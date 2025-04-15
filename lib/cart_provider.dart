import 'package:cloud_firestore/cloud_firestore.dart';
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

  // Method to update the cart and sync it with Firestore
  void updateItem(
    String id,
    String name,
    int price,
    String imageUrl,
    int stock,
    bool increase,
    BuildContext context,
  ) async {
    // Check early for out-of-stock scenario
    if (increase && stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Out of stock!")),
      );
      return;
    }

    // Update local cart state
    if (increase) {
      if (_items.containsKey(id)) {
        if (_items[id]!.quantity < stock) {
          _items[id] = _items[id]!.copyWith(quantity: _items[id]!.quantity + 1);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Cannot add more than available stock!")),
          );
          return;
        }
      } else {
        _items[id] = CartItem(
          id: id,
          name: name,
          price: price,
          quantity: 1,
          imageUrl: imageUrl,
        );
      }
    } else {
      if (_items.containsKey(id)) {
        if (_items[id]!.quantity > 1) {
          _items[id] = _items[id]!.copyWith(quantity: _items[id]!.quantity - 1);
        } else {
          _items.remove(id);
        }
      }
    }

    // Attempt Firestore sync
    try {
      final productRef = FirebaseFirestore.instance.collection('products').doc(id);
      final docSnapshot = await productRef.get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        int currentStock = (data['stock'] as num?)?.toInt() ?? 0;
        int updatedStock = increase ? currentStock - 1 : currentStock + 1;

        if (updatedStock >= 0) {
          await productRef.update({'stock': updatedStock});

          // Show feedback after successful stock update
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(increase ? "Item added to cart" : "Item removed from cart")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Insufficient stock!")),
          );
        }
      }
    } catch (e) {
      debugPrint("Error syncing stock: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error syncing with Firestore!")),
      );
    }

    // Finally notify UI
    notifyListeners();
  }
}

class CartItem {
  final String id;
  final String name;
  final int price;
  final int quantity;
  final String imageUrl;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.imageUrl,
  });

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
