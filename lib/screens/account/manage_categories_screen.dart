import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../widgets/glassmorphic_card.dart';
import '../../theme/app_theme.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  // Default common items organized by category
  final Map<String, List<Map<String, dynamic>>> _categoryItems = {
    'Dairy': [
      {'name': 'Eggs', 'unit': 'dozen', 'price': 120.0, 'icon': '🥚'},
      {'name': 'Milk', 'unit': 'L', 'price': 90.0, 'icon': '🥛'},
      {'name': 'Butter', 'unit': 'pack', 'price': 120.0, 'icon': '🧈'},
      {'name': 'Cheese', 'unit': 'pack', 'price': 150.0, 'icon': '🧀'},
      {'name': 'Yogurt', 'unit': 'pack', 'price': 80.0, 'icon': '🥛'},
    ],
    'Vegetables': [
      {'name': 'Tomatoes', 'unit': 'kg', 'price': 60.0, 'icon': '🍅'},
      {'name': 'Onions', 'unit': 'kg', 'price': 80.0, 'icon': '🧅'},
      {'name': 'Potatoes', 'unit': 'kg', 'price': 70.0, 'icon': '🥔'},
      {'name': 'Carrots', 'unit': 'kg', 'price': 65.0, 'icon': '🥕'},
      {'name': 'Cabbage', 'unit': 'kg', 'price': 55.0, 'icon': '🥬'},
      {'name': 'Lettuce', 'unit': 'pcs', 'price': 40.0, 'icon': '🥗'},
    ],
    'Fruits': [
      {'name': 'Banana', 'unit': 'kg', 'price': 70.0, 'icon': '🍌'},
      {'name': 'Apple', 'unit': 'kg', 'price': 150.0, 'icon': '🍎'},
      {'name': 'Orange', 'unit': 'kg', 'price': 120.0, 'icon': '🍊'},
      {'name': 'Mango', 'unit': 'kg', 'price': 100.0, 'icon': '🥭'},
      {'name': 'Watermelon', 'unit': 'pcs', 'price': 80.0, 'icon': '🍉'},
    ],
    'Meat': [
      {'name': 'Chicken', 'unit': 'kg', 'price': 200.0, 'icon': '🍗'},
      {'name': 'Pork', 'unit': 'kg', 'price': 250.0, 'icon': '🥓'},
    ],
    'Seafood': [
      {'name': 'Fish', 'unit': 'kg', 'price': 180.0, 'icon': '🐟'},
    ],
    'Pantry': [
      {'name': 'Rice', 'unit': 'kg', 'price': 50.0, 'icon': '🌾'},
      {'name': 'Cooking Oil', 'unit': 'L', 'price': 150.0, 'icon': '🛢️'},
      {'name': 'Sugar', 'unit': 'kg', 'price': 80.0, 'icon': '🍬'},
      {'name': 'Salt', 'unit': 'pack', 'price': 20.0, 'icon': '🧂'},
      {'name': 'Soy Sauce', 'unit': 'bottle', 'price': 45.0, 'icon': '🥫'},
      {'name': 'Vinegar', 'unit': 'bottle', 'price': 35.0, 'icon': '🧴'},
    ],
    'Beverages': [
      {'name': 'Coffee', 'unit': 'pack', 'price': 150.0, 'icon': '☕'},
      {'name': 'Tea', 'unit': 'pack', 'price': 100.0, 'icon': '🍵'},
    ],
    'Bakery': [
      {'name': 'Bread', 'unit': 'pcs', 'price': 50.0, 'icon': '🍞'},
    ],
  };

  final Map<String, IconData> _categoryIcons = {
    'Dairy': Icons.egg,
    'Vegetables': Icons.eco,
    'Fruits': Icons.apple,
    'Meat': Icons.restaurant,
    'Seafood': Icons.set_meal,
    'Pantry': Icons.kitchen,
    'Beverages': Icons.local_cafe,
    'Bakery': Icons.bakery_dining,
  };

  final Map<String, Color> _categoryColors = {
    'Dairy': Colors.orange,
    'Vegetables': Colors.green,
    'Fruits': Colors.red,
    'Meat': Colors.brown,
    'Seafood': Colors.blue,
    'Pantry': Colors.purple,
    'Beverages': Colors.amber,
    'Bakery': Colors.pink,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: Theme.of(context).brightness == Brightness.dark
                ? [const Color(0xFF0A0E21), const Color(0xFF1D1F33)]
                : [const Color(0xFFF5F7FA), const Color(0xFFE8EAF6)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Categories',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              // Categories Grid
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.0,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _categoryItems.keys.length,
                  itemBuilder: (context, index) {
                    final category = _categoryItems.keys.elementAt(index);
                    final items = _categoryItems[category]!;
                    final icon = _categoryIcons[category] ?? Icons.category;
                    final color = _categoryColors[category] ?? Colors.grey;

                    return _buildCategoryCard(
                      category: category,
                      itemCount: items.length,
                      icon: icon,
                      color: color,
                      index: index,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard({
    required String category,
    required int itemCount,
    required IconData icon,
    required Color color,
    required int index,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showCategoryItems(category, color, icon);
      },
      child: GlassmorphicCard(
        margin: EdgeInsets.zero,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                size: 36,
                color: color,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              category,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '$itemCount items',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: index * 50)).scale(
          begin: const Offset(0.8, 0.8),
          delay: Duration(milliseconds: index * 50),
        );
  }

  void _showCategoryItems(String category, Color color, IconData icon) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          final items = _categoryItems[category]!;
          
          return GlassmorphicCard(
            borderRadius: 30,
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Header
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          Text(
                            '${items.length} items',
                            style: TextStyle(
                              color: color,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle),
                      color: AppTheme.primaryGreen,
                      iconSize: 32,
                      onPressed: () {
                        Navigator.pop(context);
                        _showAddItemDialog(category);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Items list
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _buildItemTile(
                        item: item,
                        color: color,
                        onEdit: () {
                          Navigator.pop(context);
                          _showEditItemDialog(category, index, item);
                        },
                        onDelete: () {
                          HapticFeedback.mediumImpact();
                          setState(() {
                            items.removeAt(index);
                          });
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${item['name']} removed'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          // Reopen with updated data
                          Future.delayed(const Duration(milliseconds: 100), () {
                            _showCategoryItems(category, color, icon);
                          });
                        },
                        index: index,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildItemTile({
    required Map<String, dynamic> item,
    required Color color,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
    required int index,
  }) {
    return Dismissible(
      key: Key('${item['name']}_$index'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(15),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      child: GlassmorphicCard(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                item['icon'] as String,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          title: Text(
            item['name'] as String,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            '₱${(item['price'] as double).toStringAsFixed(2)} / ${item['unit']}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                color: color,
                onPressed: onEdit,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                color: Colors.red,
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      )
          .animate()
          .fadeIn(delay: Duration(milliseconds: index * 30))
          .slideX(begin: 0.2, delay: Duration(milliseconds: index * 30)),
    );
  }

  void _showEditItemDialog(
    String category,
    int itemIndex,
    Map<String, dynamic> item,
  ) {
    final nameController = TextEditingController(text: item['name']);
    final priceController =
        TextEditingController(text: (item['price'] as double).toString());
    final iconController = TextEditingController(text: item['icon']);
    String selectedUnit = item['unit'] as String;
    
    final color = _categoryColors[category] ?? Colors.grey;
    final icon = _categoryIcons[category] ?? Icons.category;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Item Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: iconController,
                decoration: const InputDecoration(
                  labelText: 'Emoji Icon',
                  border: OutlineInputBorder(),
                  hintText: '🍎',
                ),
                maxLength: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Price (₱)',
                  prefixText: '₱ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedUnit,
                decoration: const InputDecoration(
                  labelText: 'Unit',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'pcs', child: Text('pcs')),
                  DropdownMenuItem(value: 'kg', child: Text('kg')),
                  DropdownMenuItem(value: 'g', child: Text('g')),
                  DropdownMenuItem(value: 'L', child: Text('L')),
                  DropdownMenuItem(value: 'mL', child: Text('mL')),
                  DropdownMenuItem(value: 'pack', child: Text('pack')),
                  DropdownMenuItem(value: 'box', child: Text('box')),
                  DropdownMenuItem(value: 'dozen', child: Text('dozen')),
                  DropdownMenuItem(value: 'bottle', child: Text('bottle')),
                ],
                onChanged: (value) {
                  selectedUnit = value!;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Reopen category modal
              _showCategoryItems(category, color, icon);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  priceController.text.isNotEmpty &&
                  iconController.text.isNotEmpty) {
                HapticFeedback.mediumImpact();

                setState(() {
                  _categoryItems[category]![itemIndex] = {
                    'name': nameController.text,
                    'unit': selectedUnit,
                    'price': double.parse(priceController.text),
                    'icon': iconController.text,
                  };
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${nameController.text} updated!'),
                    backgroundColor: AppTheme.primaryGreen,
                  ),
                );
                
                // Reopen category modal with updated data
                Future.delayed(const Duration(milliseconds: 100), () {
                  _showCategoryItems(category, color, icon);
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Save',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog(String category) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final iconController = TextEditingController();
    String selectedUnit = 'pcs';
    
    final color = _categoryColors[category] ?? Colors.grey;
    final icon = _categoryIcons[category] ?? Icons.category;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Item to $category'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Item Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: iconController,
                decoration: const InputDecoration(
                  labelText: 'Emoji Icon',
                  border: OutlineInputBorder(),
                  hintText: '🍎',
                ),
                maxLength: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Price (₱)',
                  prefixText: '₱ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedUnit,
                decoration: const InputDecoration(
                  labelText: 'Unit',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'pcs', child: Text('pcs')),
                  DropdownMenuItem(value: 'kg', child: Text('kg')),
                  DropdownMenuItem(value: 'g', child: Text('g')),
                  DropdownMenuItem(value: 'L', child: Text('L')),
                  DropdownMenuItem(value: 'mL', child: Text('mL')),
                  DropdownMenuItem(value: 'pack', child: Text('pack')),
                  DropdownMenuItem(value: 'box', child: Text('box')),
                  DropdownMenuItem(value: 'dozen', child: Text('dozen')),
                  DropdownMenuItem(value: 'bottle', child: Text('bottle')),
                ],
                onChanged: (value) {
                  selectedUnit = value!;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Reopen category modal
              _showCategoryItems(category, color, icon);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  priceController.text.isNotEmpty &&
                  iconController.text.isNotEmpty) {
                HapticFeedback.mediumImpact();

                setState(() {
                  _categoryItems[category]!.add({
                    'name': nameController.text,
                    'unit': selectedUnit,
                    'price': double.parse(priceController.text),
                    'icon': iconController.text,
                  });
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${nameController.text} added!'),
                    backgroundColor: AppTheme.primaryGreen,
                  ),
                );
                
                // Reopen category modal with updated data
                Future.delayed(const Duration(milliseconds: 100), () {
                  _showCategoryItems(category, color, icon);
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Add',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
