import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../constants/app_assets.dart';

class AppIllustrations {
  AppIllustrations._();

  // Splash screen illustration - floating stack of books
  static Widget splashIllustration({double size = 200}) =>
      _lottie(AppAssets.splashBooks, size);

  // Login/Signup illustration - open book
  static Widget readingIllustration({double size = 180}) =>
      _lottie(AppAssets.openBook, size);

  // Library illustration - shelf of books
  static Widget libraryIllustration({double size = 180}) =>
      _lottie(AppAssets.libraryShelf, size);

  // Book open illustration
  static Widget openBookIllustration({double size = 150}) =>
      _lottie(AppAssets.openBook, size);

  static Widget _lottie(String asset, double size) {
    return SizedBox(
      width: size,
      height: size,
      child: Lottie.asset(
        asset,
        fit: BoxFit.contain,
        repeat: true,
        animate: true,
      ),
    );
  }
}