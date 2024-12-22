import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'dart:convert' show utf8;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
      appBar: AppBar(title: const Text("CNC crtanje")),
      body: const Center(
        child: DrawingScreen(),
      ),
    ));
  }
}

class DrawingScreen extends StatefulWidget {
  const DrawingScreen({super.key});

  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
  late BluetoothConnection _connection;

  String uspjeh = "";

  @override
  void initState() {
    super.initState();
    _povezi();
  }

  Future<void> _povezi() async {
    try {
      String macAdresa = "E4:65:B8:4C:79:E2";
      _connection = await BluetoothConnection.toAddress(macAdresa);
      debugPrint("Povezano na $macAdresa");
      setState(() {
        uspjeh = "Povezivanje uspjesno";
      });
    } catch (error) {
      debugPrint("Kurcina $error");
      setState(() {
        uspjeh = "Povezivanje neuspjesno";
      });
    }
  }

  Future<void> salji(String data) async {
    _connection.output.add(utf8.encode('$data\n'));
    await _connection.output.allSent;
  }

  final List<Offset?> _points = [];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const paddingSize = 10.0;
    final contWidth = screenWidth - paddingSize * 2;
    final contHeight = contWidth * 4 / 3;
    int x = 0;
    int y = 0;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(onPressed: _povezi, child: Text("povezi")),
        Text("Uspjeh: $uspjeh"),
        Padding(
          padding: const EdgeInsets.all(paddingSize),
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                if (details.localPosition.dx >= 0 &&
                    details.localPosition.dx <= contWidth &&
                    details.localPosition.dy >= 0 &&
                    details.localPosition.dy <= contHeight) {
                  _points.add(details.localPosition);
                  x = ((details.localPosition.dx * 14000) / contWidth).toInt();
                  y = ((details.localPosition.dy * 19000) / contHeight).toInt();
                  debugPrint("x: $x y: $y\n");
                  salji(
                      "$x/$y");
                } else {
                  _points.add(null);
                }
              });
            },
            onPanEnd: (details) {
              setState(() {
                _points.add(null);
              });
            },
            child: Container(
                width: contWidth,
                height: contHeight,
                decoration:
                    BoxDecoration(border: Border.all(color: Colors.black)),
                child: CustomPaint(
                  size: Size.infinite,
                  painter: LinePainter(_points),
                )),
          ),
        ),
        TextButton(
            onPressed: _points.clear,
            child: const Text(
              "Reset",
              style: TextStyle(fontSize: 25),
            ))
      ],
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

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
