import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../constants/resources.dart';
import '../utils/extension/extension.dart';
import '../utils/hook.dart';

class MessageStatusIcon extends StatelessWidget {
  const MessageStatusIcon({
    super.key,
    required this.status,
    this.color,
  });

  final MessageStatus? status;

  final Color? color;

  @override
  Widget build(BuildContext context) {
    var color = this.color ?? context.theme.secondaryText;
    String icon;
    switch (status) {
      case MessageStatus.sent:
        icon = Resources.assetsImagesSentSvg;
        break;
      case MessageStatus.delivered:
        icon = Resources.assetsImagesDeliveredSvg;
        break;
      case MessageStatus.read:
        icon = Resources.assetsImagesReadSvg;
        color = context.theme.accent;
        break;
      case MessageStatus.sending:
      case MessageStatus.failed:
      case MessageStatus.unknown:
      case null:
        return _VisibilityAwareAnimatedSendingIcon(color: color);
    }
    return SvgPicture.asset(
      icon,
      color: color,
    );
  }
}

class _VisibilityAwareAnimatedSendingIcon extends HookWidget {
  const _VisibilityAwareAnimatedSendingIcon({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final visible = useState(false);
    final key = useMemoized(UniqueKey.new);
    return VisibilityDetector(
      onVisibilityChanged: (info) {
        visible.value = info.visibleFraction > 0;
      },
      key: key,
      child: _AnimatedMessageSendingIcon(
        color: color,
        play: visible.value,
      ),
    );
  }
}

class _AnimatedMessageSendingIcon extends HookWidget {
  const _AnimatedMessageSendingIcon({
    required this.color,
    required this.play,
  });

  final Color color;
  final bool play;

  @override
  Widget build(BuildContext context) {
    final time = useState(0);

    final play = useValueListenable(useImagePlaying(context)) && this.play;
    useEffect(() {
      Timer? timer;
      if (play) {
        const periodic = 40;
        timer = Timer.periodic(const Duration(milliseconds: periodic), (timer) {
          time.value = time.value + periodic;
        });
      }
      return () {
        timer?.cancel();
      };
    }, [play]);

    // small is slow, big is fast
    const scale = 1 / 10;
    final hour = (time.value * scale) / 20 % 12;
    final minute = (time.value * scale) % 60;
    return CustomPaint(
      painter: _MessageSendingIconPainter(
        color: color,
        hour: hour,
        minute: minute,
      ),
      child: const SizedBox.square(dimension: 14),
    );
  }
}

class _MessageSendingIconPainter extends CustomPainter {
  _MessageSendingIconPainter({
    required this.color,
    required this.hour,
    required this.minute,
  });

  final Color color;

  final double hour;

  final double minute;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1;

    final center = Offset(size.width / 2, size.height / 2);

    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: 11, height: 9),
      const Radius.circular(2.15),
    );
    canvas.drawRRect(rect, paint);

    // draw hour hand
    const hourHandLength = 3;
    final hourAngle = math.pi * 2 * (1 - hour / 12);
    final hourHand = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(
        center.dx + math.sin(hourAngle) * hourHandLength,
        center.dy + math.cos(hourAngle) * hourHandLength,
      );
    canvas.drawPath(hourHand, paint);

    // draw minute hand
    const minuteHandLength = 4;
    final minuteAngle = math.pi * 2 * (1 - minute / 60);
    final minuteHand = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(
        center.dx + math.sin(minuteAngle) * minuteHandLength,
        center.dy + math.cos(minuteAngle) * minuteHandLength,
      );
    canvas.drawPath(minuteHand, paint);
  }

  @override
  bool shouldRepaint(covariant _MessageSendingIconPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.hour != hour ||
      oldDelegate.minute != minute;
}
