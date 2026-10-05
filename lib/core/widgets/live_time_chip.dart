import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';

class LiveTimeChip extends StatefulWidget {
  final TimeOfDay? selectedTime;
  final bool isLiveTime;
  final bool isMobile;
  final ValueChanged<TimeOfDay> onTimeChanged;
  final VoidCallback onResetToLive;

  const LiveTimeChip({
    super.key,
    this.selectedTime,
    this.isLiveTime = true,
    this.isMobile = false,
    required this.onTimeChanged,
    required this.onResetToLive,
  });

  @override
  State<LiveTimeChip> createState() => _LiveTimeChipState();
}

class _LiveTimeChipState extends State<LiveTimeChip> {
  Timer? _timer;
  late DateTime _currentTime;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final initial = widget.selectedTime ?? TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      widget.onTimeChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLive = widget.isLiveTime;
    final displayTime = isLive
        ? DateFormat('hh:mm:ss a').format(_currentTime)
        : (widget.selectedTime ?? TimeOfDay.now()).format(context);

    return InkWell(
      onTap: _pickTime,
      borderRadius: BorderRadius.circular(widget.isMobile ? 8 : 9),
      child: Container(
        height: 48,
        padding: EdgeInsets.symmetric(
          horizontal: widget.isMobile ? 10 : 14,
        ),
        decoration: BoxDecoration(
          color: isLive ? const Color(0xFFF9FDFB) : Colors.white,
          borderRadius: BorderRadius.circular(widget.isMobile ? 8 : 9),
          border: Border.all(
            color: isLive ? const Color(0xFF86EFAC) : AppColors.cardBorder,
            width: isLive ? 1.4 : 1.2,
          ),
          boxShadow: isLive
              ? [
                  BoxShadow(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              isLive ? Icons.access_time_filled_rounded : Icons.access_time_rounded,
              size: widget.isMobile ? 16 : 17,
              color: isLive ? const Color(0xFF16A34A) : AppColors.primary,
            ),
            SizedBox(width: widget.isMobile ? 8 : 10),
            Expanded(
              child: Text(
                displayTime,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: widget.isMobile ? AppTextSizes.caption : AppTextSizes.body,
                  color: isLive ? const Color(0xFF0F2448) : AppColors.primaryDark,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(width: 6),
            if (isLive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Color(0xFF16A34A),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Text(
                      'LIVE',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF16A34A),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              )
            else
              InkWell(
                onTap: widget.onResetToLive,
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.replay_rounded, size: 12, color: AppColors.primary),
                      SizedBox(width: 3),
                      Text(
                        'RESET',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
