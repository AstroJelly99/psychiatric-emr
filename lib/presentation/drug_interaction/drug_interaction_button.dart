import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:emr_homemade/domain/drug_interaction/drug_interaction_provider.dart';

class DrugInteractionButton extends StatefulWidget {
  const DrugInteractionButton({super.key});

  @override
  State<DrugInteractionButton> createState() => _DrugInteractionButtonState();
}

class _DrugInteractionButtonState extends State<DrugInteractionButton> {
  double _left = 40;
  double _top = 40;
  bool _isDragging = false;
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DrugInteractionProvider>();
    final screen = MediaQuery.of(context).size;

    final isNearTop = _top < 100;
    final isNearBottom = _top > screen.height - 140;
    final isNearLeft = _left < 100;
    final isNearRight = _left > screen.width - 200;

    Alignment tooltipAlign = Alignment.topCenter;
    EdgeInsets tooltipMargin = const EdgeInsets.only(bottom: 80);
    if (isNearTop) {
      tooltipAlign = Alignment.bottomCenter;
      tooltipMargin = const EdgeInsets.only(top: 80);
    } else if (isNearBottom) {
      tooltipAlign = Alignment.topCenter;
      tooltipMargin = const EdgeInsets.only(bottom: 80);
    }
    if (isNearLeft) tooltipAlign = Alignment.centerRight;
    if (isNearRight) tooltipAlign = Alignment.centerLeft;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 100),
      left: _left,
      top: _top,
      child: Listener(
        onPointerDown: (_) => setState(() => _isDragging = true),
        onPointerUp: (_) => setState(() => _isDragging = false),
        child: GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              _left = (_left + details.delta.dx)
                  .clamp(0.0, screen.width - 80);
              _top = (_top + details.delta.dy)
                  .clamp(0.0, screen.height - 80);
            });
          },
          child: MouseRegion(
            onEnter: (_) => setState(() => _isHovering = true),
            onExit: (_) => setState(() => _isHovering = false),
            cursor: SystemMouseCursors.click,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  opacity: _isHovering && !_isDragging ? 1 : 0,
                  curve: Curves.easeOutCubic,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    alignment: tooltipAlign,
                    margin: tooltipMargin,
                    child: IgnorePointer(
                      ignoring: true,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 1,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 6,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Text(
                              "Tap to Analyze Drug Interactions",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(60),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent
                            .withValues(alpha: _isHovering ? 0.4 : 0.25),
                        blurRadius: _isHovering ? 16 : 10,
                        offset: Offset(0, _isHovering ? 6 : 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(60),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                      child: Material(
                        color: Colors.blue.shade700.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(60),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(60),
                          splashColor: Colors.white.withValues(alpha: 0.2),
                          highlightColor: Colors.white.withValues(alpha: 0.1),
                          onTap: () => provider.setShowDialog(true),
                          child: const SizedBox(
                            width: 65,
                            height: 65,
                            child: Center(
                              child: Icon(
                                Icons.medication_outlined,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
