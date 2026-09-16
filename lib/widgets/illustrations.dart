import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppIllustrations {
  AppIllustrations._();

  // Splash screen illustration - elegant stack of books
  static Widget splashIllustration({double size = 200}) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: SplashIllustrationPainter(),
      ),
    );
  }

  // Login/Signup illustration - reading person
  static Widget readingIllustration({double size = 180}) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: ReadingIllustrationPainter(),
      ),
    );
  }

  // Library illustration
  static Widget libraryIllustration({double size = 180}) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: LibraryIllustrationPainter(),
      ),
    );
  }

  // Book open illustration
  static Widget openBookIllustration({double size = 150}) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: OpenBookIllustrationPainter(),
      ),
    );
  }
}

class SplashIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Soft background circle
    final bgPaint = Paint()
      ..color = AppColors.white.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, bgPaint);

    // Book stack
    final bookColors = [
      AppColors.white,
      AppColors.accentGreen,
      AppColors.lightGreen,
      AppColors.paleGreen,
    ];

    final bookWidth = radius * 0.9;
    final bookHeight = radius * 0.25;

    for (var i = 0; i < bookColors.length; i++) {
      final color = bookColors[i];
      final y = center.dy - bookHeight + 8 - (i * (bookHeight * 0.62));
      final nearby = i < bookColors.length - 1;

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      final rect = RRect.fromRectAndCorners(
        Rect.fromCenter(
          center: Offset(center.dx + (nearby ? -bookWidth * 0.12 : bookWidth * 0.12), y),
          width: bookWidth,
          height: bookHeight,
        ),
        topLeft: Radius.circular(bookHeight * 0.2),
        topRight: Radius.circular(bookHeight * 0.05),
        bottomLeft: Radius.circular(bookHeight * 0.3),
        bottomRight: Radius.circular(bookHeight * 0.1),
      );

      canvas.drawRRect(rect, paint);

      // Book spine line
      if (i == 0) {
        final spinePaint = Paint()
          ..color = AppColors.primaryGreen
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        final spineRect = Rect.fromCenter(
          center: Offset(center.dx + bookWidth * 0.1, y),
          width: bookWidth * 0.6,
          height: bookHeight * 0.5,
        );
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            spineRect,
            topLeft: Radius.circular(bookHeight * 0.1),
            bottomRight: Radius.circular(bookHeight * 0.1),
          ),
          spinePaint,
        );
      }
    }

    // Bookmark ribbon
    final ribbonPaint = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(center.dx - 8, center.dy - bookHeight * 2.5)
      ..lineTo(center.dx + 8, center.dy - bookHeight * 2.5)
      ..lineTo(center.dx + 8, center.dy - bookHeight * 2.5 - 30)
      ..lineTo(center.dx, center.dy - bookHeight * 2.5 - 20)
      ..lineTo(center.dx - 8, center.dy - bookHeight * 2.5 - 30)
      ..close();

    canvas.drawPath(path, ribbonPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ReadingIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;

    // Backdrop circle
    paint.color = AppColors.paleGreen.withOpacity(0.4);
    canvas.drawCircle(center, size.width * 0.48, paint);

    // Body - sitting silhouette
    // Head
    paint.color = AppColors.primaryGreen.withOpacity(0.85);
    canvas.drawCircle(
      Offset(center.dx, center.dy - 35),
      18,
      paint,
    );

    // Upper body leaning forward reading
    final bodyPaint = Paint()..color = AppColors.primaryGreen.withOpacity(0.85);
    final bodyPath = Path()
      ..moveTo(center.dx - 20, center.dy - 20)
      ..quadraticBezierTo(
        center.dx - 30,
        center.dy + 25,
        center.dx - 5,
        center.dy + 40,
      )
      ..quadraticBezierTo(
        center.dx + 25,
        center.dy + 30,
        center.dx + 20,
        center.dy - 18,
      )
      ..close();
    canvas.drawPath(bodyPath, bodyPaint);

    // Open book in front
    final bookPaint = Paint()..color = AppColors.white;

    final bookPath = Path()
      ..moveTo(center.dx - 22, center.dy - 5)
      ..quadraticBezierTo(
        center.dx,
        center.dy - 15,
        center.dx + 22,
        center.dy - 5,
      )
      ..quadraticBezierTo(
        center.dx + 22,
        center.dy + 15,
        center.dx + 8,
        center.dy + 15,
      )
      ..quadraticBezierTo(
        center.dx + 2,
        center.dy + 25,
        center.dx,
        center.dy + 22,
      )
      ..quadraticBezierTo(
        center.dx - 2,
        center.dy + 25,
        center.dx - 8,
        center.dy + 15,
      )
      ..quadraticBezierTo(
        center.dx - 22,
        center.dy + 15,
        center.dx - 22,
        center.dy - 5,
      )
      ..close();

    canvas.drawPath(bookPath, bookPaint);

    // Book center line
    final centerLinePaint = Paint()
      ..color = AppColors.primaryGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final centerLine = Path()
      ..moveTo(center.dx, center.dy - 8)
      ..quadraticBezierTo(
        center.dx,
        center.dy + 10,
        center.dx,
        center.dy + 22,
      );
    canvas.drawPath(centerLine, centerLinePaint);

    // Small decorative elements
    final dotPaint = Paint()..color = AppColors.accentGreen;

    final positions = [
      Offset(center.dx - size.width * 0.3, center.dy - size.height * 0.3),
      Offset(center.dx + size.width * 0.25, center.dy - size.height * 0.35),
      Offset(center.dx + size.width * 0.3, center.dy + size.height * 0.25),
      Offset(center.dx - size.width * 0.32, center.dy + size.height * 0.3),
    ];

    for (final pos in positions) {
      canvas.drawCircle(pos, 4, dotPaint);
    }

    // Sparkle
    final sparklePaint = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.fill;
    final sparklePath = Path()
      ..moveTo(center.dx - size.width * 0.38, center.dy - size.height * 0.38)
      ..lineTo(center.dx - size.width * 0.36, center.dy - size.height * 0.35)
      ..lineTo(center.dx - size.width * 0.33, center.dy - size.height * 0.38)
      ..lineTo(center.dx - size.width * 0.36, center.dy - size.height * 0.41)
      ..close();
    canvas.drawPath(sparklePath, sparklePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LibraryIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Backdrop
    paint.color = AppColors.paleGreen.withOpacity(0.5);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(20, 10, size.width - 40, size.height - 20),
        topLeft: const Radius.circular(12),
        topRight: const Radius.circular(12),
        bottomLeft: const Radius.circular(12),
        bottomRight: const Radius.circular(12),
      ),
      paint,
    );

    // Bookshelf rows
    for (var row = 0; row < 3; row++) {
      final shelfY = 30 + row * (size.height * 0.25);
      final shelfPaint = Paint()
        ..color = AppColors.primaryGreen.withOpacity(0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawLine(
        Offset(32, shelfY),
        Offset(size.width - 32, shelfY),
        shelfPaint,
      );

      // Books on shelf
      for (var i = 0; i < 7; i++) {
        final bookWidth = 12.0 + (i % 3) * 4;
        final bookHeight = 30.0 + (i % 2) * 10;
        final x = 35 + i * (bookWidth + 6);
        final y = shelfY - bookHeight;

        final bookColor = i.isEven
            ? [AppColors.primaryGreen, AppColors.accentGreen, AppColors.darkGreen][i % 3]
            : [AppColors.white, AppColors.lightGreen, AppColors.paleGreen][i % 3];

        paint.color = bookColor;
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(x, y, bookWidth, bookHeight),
            bottomLeft: const Radius.circular(1),
            bottomRight: const Radius.circular(1),
          ),
          paint,
        );
      }
    }

    // Gold accents
    paint.color = AppColors.gold;
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(32, 25, size.width - 64, 3),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class OpenBookIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;

    // Backdrop circle
    paint.color = AppColors.paleGreen.withOpacity(0.4);
    canvas.drawCircle(center, size.width * 0.45, paint);

    // Left page
    paint.color = AppColors.white;
    final leftPage = Path()
      ..moveTo(center.dx, center.dy - 20)
      ..cubicTo(
        center.dx - 20, center.dy - 30,
        center.dx - 50, center.dy - 12,
        center.dx - 55, center.dy + 15,
      )
      ..cubicTo(
        center.dx - 50, center.dy + 20,
        center.dx - 25, center.dy + 22,
        center.dx, center.dy + 12,
      )
      ..close();
    canvas.drawPath(leftPage, paint);

    // Right page
    final rightPage = Path()
      ..moveTo(center.dx, center.dy - 20)
      ..cubicTo(
        center.dx + 20, center.dy - 30,
        center.dx + 50, center.dy - 12,
        center.dx + 55, center.dy + 15,
      )
      ..cubicTo(
        center.dx + 50, center.dy + 20,
        center.dx + 25, center.dy + 22,
        center.dx, center.dy + 12,
      )
      ..close();
    canvas.drawPath(rightPage, paint);

    // Page lines
    final linePaint = Paint()
      ..color = AppColors.lightGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (var i = 0; i < 3; i++) {
      final y = center.dy - 5 + i * 7;
      canvas.drawLine(
        Offset(center.dx - 40, y),
        Offset(center.dx - 10, y),
        linePaint,
      );
      canvas.drawLine(
        Offset(center.dx + 10, y),
        Offset(center.dx + 40, y),
        linePaint,
      );
    }

    // Center fold
    final foldPaint = Paint()
      ..color = AppColors.primaryGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(center.dx, center.dy - 20),
      Offset(center.dx, center.dy + 16),
      foldPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}