class Product {
  final int id;
  final String name;
  final String imageUrl;
  final double price;
  int stock;
  int quantity;

  Product({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.stock,
    this.quantity = 0,
  });
}
