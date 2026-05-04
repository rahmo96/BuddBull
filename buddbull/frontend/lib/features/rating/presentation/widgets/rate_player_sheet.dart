import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/shared/widgets/bb_button.dart';
import 'package:buddbull/features/rating/providers/rating_provider.dart';
import 'package:buddbull/features/rating/presentation/widgets/rating_stars.dart';

/// Bottom sheet for submitting a post-game rating.
///
/// Usage:
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   isScrollControlled: true,
///   builder: (_) => RatePlayerSheet(
///     rateeId: player.userId,
///     rateeDisplayName: player.displayName,
///     gameId: game.id,
///   ),
/// );
/// ```
class RatePlayerSheet extends ConsumerStatefulWidget {
  final String rateeId;
  final String rateeDisplayName;
  final String gameId;

  const RatePlayerSheet({
    super.key,
    required this.rateeId,
    required this.rateeDisplayName,
    required this.gameId,
  });

  @override
  ConsumerState<RatePlayerSheet> createState() => _RatePlayerSheetState();
}

class _RatePlayerSheetState extends ConsumerState<RatePlayerSheet> {
  int _reliability = 0;
  int _behavior = 0;
  bool _isAnonymous = false;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rateState = ref.watch(ratePlayerProvider);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Rate Player', style: AppTextStyles.titleLarge),
                    Text(
                      widget.rateeDisplayName,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 24),

          // ── Reliability score ────────────────────────────────────
          Text('Reliability',
              style: AppTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            'Did they show up on time and follow through?',
            style:
                AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          RatingStars(
            rating: _reliability.toDouble(),
            size: 36,
            interactive: true,
            onChanged: (v) => setState(() => _reliability = v),
          ),
          const SizedBox(height: 20),

          // ── Behavior score ────────────────────────────────────────
          Text('Sportsmanship',
              style: AppTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            'Were they fair, respectful, and fun to play with?',
            style:
                AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          RatingStars(
            rating: _behavior.toDouble(),
            size: 36,
            interactive: true,
            onChanged: (v) => setState(() => _behavior = v),
          ),
          const SizedBox(height: 20),

          // ── Comment ───────────────────────────────────────────────
          TextField(
            controller: _commentController,
            maxLines: 3,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: 'Leave a comment (optional)...',
              hintStyle: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: AppColors.surface,
            ),
          ),
          const SizedBox(height: 12),

          // ── Anonymous toggle ──────────────────────────────────────
          Row(
            children: [
              Switch(
                value: _isAnonymous,
                onChanged: (v) => setState(() => _isAnonymous = v),
                activeThumbColor: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Submit anonymously',
                      style: AppTextStyles.bodySmall),
                  Text(
                    'Your name will not be shown to this player',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Error message ─────────────────────────────────────────
          if (rateState.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                rateState.error!,
                style: AppTextStyles.caption.copyWith(color: Colors.red),
              ),
            ),

          // ── Submit button ─────────────────────────────────────────
          BbButton(
            label: 'Submit Rating',
            isLoading: rateState.isLoading,
            onPressed: (_reliability == 0 || _behavior == 0) ? null : _submit,
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final success = await ref.read(ratePlayerProvider.notifier).rate(
          rateeId: widget.rateeId,
          gameId: widget.gameId,
          reliabilityScore: _reliability,
          behaviorScore: _behavior,
          comment: _commentController.text.trim(),
          isAnonymous: _isAnonymous,
        );

    if (success && mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Rating submitted!'),
            backgroundColor: AppColors.success),
      );
    }
  }
}
