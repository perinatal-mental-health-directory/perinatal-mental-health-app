import 'package:flutter/material.dart';

class PerinatalLogo extends StatelessWidget {
  final double size;

  const PerinatalLogo({Key? key, this.size = 50}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Color(0xFF3A7BD5),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          Icons.psychology,  // Heart symbol
          size: size * 0.6,
          color: Colors.white,
        ),
      ),
    );
  }
}
