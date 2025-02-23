import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Product Management',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ProductListPage(),
    );
  }
}

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  _ProductListPageState createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  List products = [];
  final String apiUrl = 'http://localhost:3000/products';

  bool isLoading = false; // For loading state

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    setState(() {
      isLoading = true; // Show loading indicator
    });
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        setState(() {
          products = jsonDecode(response.body);
        });
      } else {
        showErrorSnackBar('Failed to fetch products: ${response.statusCode}');
      }
    } catch (e) {
      showErrorSnackBar('Error fetching products: $e');
    } finally {
      setState(() {
        isLoading = false; // Hide loading indicator
      });
    }
  }

  Future<void> deleteProduct(String id) async {
    setState(() {
      isLoading = true;
    });
    try {
      final response = await http.delete(Uri.parse('$apiUrl/$id'));
      if (response.statusCode == 200) {
        showSuccessSnackBar('Deleted successfully');
        fetchProducts();
      } else {
        showErrorSnackBar('Failed to delete: ${response.statusCode}');
      }
    } catch (e) {
      showErrorSnackBar('Error deleting: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> saveProduct({String? id, required String name, required String description, required double price}) async {
    if (name.isEmpty || description.isEmpty || price <= 0) {
      showErrorSnackBar('Please fill out all fields correctly');
      return;
    }
    final body = jsonEncode({'name': name, 'description': description, 'price': price});
    final headers = {'Content-Type': 'application/json'};
    setState(() {
      isLoading = true;
    });
    try {
      final response = id == null
          ? await http.post(Uri.parse(apiUrl), headers: headers, body: body)
          : await http.put(Uri.parse('$apiUrl/$id'), headers: headers, body: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        showSuccessSnackBar(id == null ? 'Product Added' : 'Product Updated');
        fetchProducts();
      } else {
        showErrorSnackBar('Failed to save: ${response.statusCode}');
      }
    } catch (e) {
      showErrorSnackBar('Error saving: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void showProductForm({String? id, String? name, String? description, double? price}) {
    TextEditingController nameController = TextEditingController(text: name ?? '');
    TextEditingController descController = TextEditingController(text: description ?? '');
    TextEditingController priceController = TextEditingController(text: price?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(id == null ? 'Add New Product' : 'Edit Product'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Product Name')),
            TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description')),
            TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              double parsedPrice = double.tryParse(priceController.text) ?? 0.0;
              saveProduct(id: id, name: nameController.text, description: descController.text, price: parsedPrice);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  void showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.green));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Product List')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator()) // Show loading spinner
          : ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                var product = products[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  elevation: 3,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(10),
                    leading: const Icon(Icons.shopping_bag, color: Colors.blue, size: 40),
                    title: Text(product['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product['description'], style: const TextStyle(fontSize: 14, color: Colors.black54)),
                        Text('Price: \$${product['price']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.orange),
                          onPressed: () => showProductForm(id: product['id'], name: product['name'], description: product['description'], price: (product['price'] as num).toDouble()),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => deleteProduct(product['id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showProductForm(),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
