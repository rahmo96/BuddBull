import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/core/locale/l10n_extension.dart';
import 'package:buddbull/features/games/providers/game_provider.dart';
import 'package:buddbull/features/rating/presentation/widgets/rating_stars.dart';
import 'package:buddbull/features/rating/providers/rating_provider.dart';
import 'package:buddbull/shared/widgets/bb_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  bool _isDismissing = false;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
                    Text(l10n.ratePlayerTitle, style: AppTextStyles.titleLarge),
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
          Text(l10n.ratingReliability,
              style: AppTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            l10n.ratingReliabilityHint,
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
          Text(l10n.ratingSportsmanship,
              style: AppTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            l10n.ratingSportsmanshipHint,
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
              hintText: l10n.ratingCommentHint,
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
                  Text(l10n.ratingSubmitAnonymously,
                      style: AppTextStyles.bodySmall),
                  Text(
                    l10n.ratingAnonymousHint,
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
            label: l10n.buttonSubmitRating,
            isLoading: rateState.isLoading,
            onPressed: (_reliability == 0 || _behavior == 0) ? null : _submit,
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: _isDismissing || rateState.isLoading ? null : _dismissEntireGame,
              child: Text(
                l10n.dontRateThisGame,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _dismissEntireGame() async {
    setState(() => _isDismissing = true);
    try {
      await dismissGameRatingQueue(ref, widget.gameId);
      if (!mounted) return;
      Navigator.pop(context, false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.snackWontPromptToRate),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isDismissing = false);
    }
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
      ref.invalidate(calendarGamesProvider);
      ref.invalidate(myGamesProvider);
      ref.invalidate(gameDetailProvider(widget.gameId));
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(context.l10n.snackRatingSubmitted),
            backgroundColor: AppColors.success),
      );
    }
  }
}
