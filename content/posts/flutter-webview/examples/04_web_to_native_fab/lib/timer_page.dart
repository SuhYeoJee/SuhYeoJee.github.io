import "dart:async";

import "package:flutter/material.dart";

class TimerPage extends StatefulWidget {
  const TimerPage({super.key});

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  static const _initialSeconds = 60;

  int _seconds = _initialSeconds;
  bool _running = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggle() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_seconds <= 0) {
        _timer?.cancel();
        setState(() => _running = false);
        return;
      }
      setState(() => _seconds--);
    });
    setState(() => _running = true);
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _seconds = _initialSeconds;
      _running = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("타이머")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "${_seconds}s",
              style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton(
                  onPressed: _toggle,
                  child: Text(_running ? "일시정지" : "시작"),
                ),
                const SizedBox(width: 12),
                OutlinedButton(onPressed: _reset, child: const Text("리셋")),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
