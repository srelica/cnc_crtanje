import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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
  WebSocketChannel? channel;
  final TextEditingController ipInputController = TextEditingController();
  String? ipInput;
  String connectedState = "Poveži";

  final List<Offset?> _points = [];

  void posalji(int x, int y) {
    if (channel != null) {
      channel!.sink.add("$x/$y");
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const paddingSize = 10.0;
    final contWidth = screenWidth - paddingSize * 2;
    final contHeight = contWidth * 4 / 3;

    int x = 0;
    int y = 0;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
      child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
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
                  y = ((details.localPosition.dx * 23250) / contWidth).toInt();
                  x = ((details.localPosition.dy * 31000) / contHeight).toInt();
                  debugPrint("x: $x y: $y\n");
                  posalji(x, y);
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
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.black)),
                child: CustomPaint(
                  size: Size.infinite,
                  painter: LinePainter(_points),
                )),
          ),
        ),
        TextButton(
            onPressed: () {
              setState(() {
                _points.clear();
              });
            },
            child: const Text(
              "Reset",
              style: TextStyle(fontSize: 25),
            )),
        TextButton(
            onPressed:  () async {
              setState(() {
                connectedState = "Povezivanje...";
              });
              await Future.delayed(const Duration(milliseconds: 350));
              try {
                final uri = Uri.parse("ws://${ipInputController.text}/ws");
                final newChannel = WebSocketChannel.connect(uri);

                newChannel.stream.listen(
                  (event) {
                    debugPrint("Primljeno: $event");
                  },
                  onError: (error) {
                    debugPrint("Greška u vezi: $error");
                    setState(() {
                      connectedState = "Povezivanje neuspješno";
                    });
                  },
                  onDone: () {
                    debugPrint("Veza zatvorena.");
                  },
                );

                setState(() {
                  channel = newChannel;
                  connectedState = "Povezano";
                });
              } catch (error) {
                debugPrint("Try/catch error: $error");
                setState(() {
                  connectedState = "Povezivanje neuspješno";
                });
              }
            },
            child: Text(
              connectedState,
              style: const TextStyle(fontSize: 20),
            )),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            controller: ipInputController,
            decoration:
                const InputDecoration(labelText: "Unesi IP adresu uređaja"),
          ),
        ),
      ],
    ),
    ),
    );
  }

  @override
  void dispose() {
    ipInputController.dispose();
    channel?.sink.close();
    super.dispose();
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
