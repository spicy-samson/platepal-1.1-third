import 'package:flutter/material.dart';
import 'package:platepal/models/Ingredient.dart';
import 'package:flutter_svg/flutter_svg.dart';

class IngredientItem extends StatelessWidget {
  final Ingredient ingredient;
  final bool isSelected;
  final VoidCallback onTap;

  const IngredientItem({
    super.key,
    required this.ingredient,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SvgPicture.asset('assets/icons/plate.svg', width: 80, height: 80),
              Image.asset(ingredient.image, width: 60, height: 60),
              if (isSelected)
                const Positioned(
                  right: 0,
                  top: 0,
                  child: Icon(Icons.check_circle, color: Colors.green),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(ingredient.name, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}