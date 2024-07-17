import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const CustomAppBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color.fromRGBO(19,49,92,1),
      automaticallyImplyLeading: false,
      title: Align(
        alignment: const AlignmentDirectional(-1, 1),
        child: Text(
          title,
          textAlign: TextAlign.start,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 32,
            letterSpacing: 0,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      elevation: 2,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
