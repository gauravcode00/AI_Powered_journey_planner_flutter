import 'package:flutter/material.dart';

class TopSearchBar extends StatelessWidget {
  const TopSearchBar({super.key});
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 50,
      left: 15,
      right: 15,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 3))
          ],
        ),
        child: const TextField(
          decoration: InputDecoration(
            hintText: 'Search here',
            prefixIcon: Icon(Icons.search, color: Colors.grey),
            suffixIcon: Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: CircleAvatar(
                  radius: 15,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, color: Colors.white, size: 20)),
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }
}
