import 'package:flutter/material.dart';
import 'package:emr_homemade/utils/widgets/constant.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

Widget defaultLoading() => Center(
      child: Column(
        children: [
          LoadingAnimationWidget.progressiveDots(
            color: blackPrimary,
            size: 48,
          ),
          FutureBuilder(
            future: Future.delayed(const Duration(milliseconds: 5000)),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return Text(
                  "Please Wait. This Might Take a While...",
                  style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w300, color: blackPrimary),
                );
              } else {
                return const SizedBox();
              }
            },
          ),
        ],
      ),
    );

/// Bikin [child] berdenyut pelan (opacity naik-turun) — dipakai membungkus
/// kotak-kotak abu-abu skeleton supaya layar loading terasa "hidup", bukan
/// diam kosong menunggu spinner. Satu [AnimationController] untuk seluruh
/// subtree yang dibungkus, jadi 1 skeleton list dengan banyak kartu tetap
/// cuma butuh satu animasi, bukan satu per kartu.
class SkeletonPulse extends StatefulWidget {
  final Widget child;
  const SkeletonPulse({super.key, required this.child});

  @override
  State<SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<SkeletonPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: widget.child,
    );
  }
}

/// Satu kotak abu-abu skeleton — potongan dasar buat menyusun bentuk kartu
/// apa pun (dikombinasikan di halaman masing-masing, karena bentuk kartu
/// tiap halaman beda-beda).
Widget skeletonBox({double? width, double height = 12, double radius = 6}) {
  return Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: Colors.grey.shade300,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

Widget panelLoading() => Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LoadingAnimationWidget.staggeredDotsWave(
            color: blueHighlight,
            size: 128,
          ),
          Text(
            'Reloading Configuration...',
            style: GoogleFonts.nunito(
                fontWeight: FontWeight.w300, color: blackPrimary),
          )
        ],
      ),
    );
