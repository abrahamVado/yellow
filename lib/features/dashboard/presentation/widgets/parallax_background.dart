import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class ParallaxBackground extends StatefulWidget {
  const ParallaxBackground({super.key});

  @override
  State<ParallaxBackground> createState() => _ParallaxBackgroundState();
}

class _ParallaxBackgroundState extends State<ParallaxBackground> {
  double _x = 0;
  double _y = 0;
  StreamSubscription<GyroscopeEvent>? _streamSubscription;

  @override
  void initState() {
    super.initState();
    _streamSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
      setState(() {
        _x += event.y * 2;
        _y += event.x * 2;
      });
    });
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: -50 - _x,
          top: -50 - _y,
          right: -50 - _x,
          bottom: -50 - _y,
          child: Image.asset(
            'assets/images/map_bg.png', // Local map image
            fit: BoxFit.cover,
          ),
        ),
        Container(
          color: Colors.black.withOpacity(0.3), // Overlay for better text visibility
        ),
      ],
    );
  }
}
