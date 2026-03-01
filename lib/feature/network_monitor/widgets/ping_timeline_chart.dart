import 'dart:math';

import 'package:flutter/material.dart';
import 'package:trusttunnel/common/extensions/context_extensions.dart';
import 'package:trusttunnel/data/model/ping_sample.dart';

class PingTimelineChart extends StatelessWidget {
  final List<PingSample> samples;

  const PingTimelineChart({
    required this.samples,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Text(
              'Tunnel Ping',
              style: context.textTheme.titleSmall,
            ),
            const SizedBox(width: 12),
            if (samples.isNotEmpty)
              Text(
                '${samples.last.rttMs.toStringAsFixed(1)} ms',
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CustomPaint(
              size: Size.infinite,
              painter: _PingTimelinePainter(
                samples: samples,
                lineColor: context.colors.background != const Color(0xFFFFFFFF)
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFF2E7D32),
                gridColor: context.theme.dividerColor,
                textColor: context.textTheme.bodySmall?.color ?? Colors.grey,
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

class _PingTimelinePainter extends CustomPainter {
  final List<PingSample> samples;
  final Color lineColor;
  final Color gridColor;
  final Color textColor;

  _PingTimelinePainter({
    required this.samples,
    required this.lineColor,
    required this.gridColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.isEmpty) return;

    final chartRect = Rect.fromLTWH(40, 4, size.width - 48, size.height - 20);

    _drawGrid(canvas, chartRect);
    _drawLine(canvas, chartRect);
  }

  void _drawGrid(Canvas canvas, Rect rect) {
    final maxRtt = samples.map((s) => s.rttMs).reduce(max);
    final gridMax = ((maxRtt / 20).ceil() * 20).clamp(20, 500).toDouble();

    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.3)
      ..strokeWidth = 0.5;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Draw 4 horizontal grid lines with labels.
    for (var i = 0; i <= 4; i++) {
      final y = rect.top + rect.height * (1 - i / 4);
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), gridPaint);

      final label = '${(gridMax * i / 4).toInt()}';
      textPainter
        ..text = TextSpan(
          text: label,
          style: TextStyle(color: textColor, fontSize: 10),
        )
        ..layout();
      textPainter.paint(canvas, Offset(rect.left - textPainter.width - 4, y - textPainter.height / 2));
    }
  }

  void _drawLine(Canvas canvas, Rect rect) {
    if (samples.length < 2) return;

    final maxRtt = samples.map((s) => s.rttMs).reduce(max);
    final gridMax = ((maxRtt / 20).ceil() * 20).clamp(20, 500).toDouble();

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [lineColor.withValues(alpha: 0.3), lineColor.withValues(alpha: 0.0)],
      ).createShader(rect);

    final path = Path();
    final fillPath = Path();

    for (var i = 0; i < samples.length; i++) {
      final x = rect.left + rect.width * i / (samples.length - 1);
      final y = rect.bottom - rect.height * (samples[i].rttMs / gridMax).clamp(0.0, 1.0);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, rect.bottom);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    // Close fill path.
    fillPath.lineTo(rect.right, rect.bottom);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(_PingTimelinePainter oldDelegate) =>
      samples.length != oldDelegate.samples.length ||
      (samples.isNotEmpty &&
          oldDelegate.samples.isNotEmpty &&
          samples.last != oldDelegate.samples.last);
}
