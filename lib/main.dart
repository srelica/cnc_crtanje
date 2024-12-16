import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text("Crtanje linija")),
        body: const DrawingScreen(),
      ),
    );
  }
}

class DrawingScreen extends StatefulWidget {
  const DrawingScreen({super.key});

  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
  final List<Offset?> _points = []; // Pohranjuje točke koje korisnik nacrta

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        // Dodaje nove točke dok korisnik povlači prstom
        setState(() {
          _points.add(details.localPosition);
        });
      },
      onPanEnd: (details) {
        // Dodaje null kako bi se prekinula trenutna linija
        setState(() {
          _points.add(null);
        });
      },
      child: CustomPaint(
        size: Size.infinite,
        painter: LinePainter(_points),
      ),
    );
  }
}

class LinePainter extends CustomPainter {
  final List<Offset?> points;

  LinePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    // Crta linije spajanjem točaka
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // Ponovno crta kad se dodaju nove točke
  }
}
