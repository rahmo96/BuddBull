import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/core/locale/l10n_extension.dart';
import 'package:buddbull/features/auth/providers/auth_provider.dart';
import 'package:buddbull/features/chat/presentation/widgets/chat_tile.dart';
import 'package:buddbull/features/chat/providers/chat_provider.dart';
import 'package:buddbull/features/home/home_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final chatListAsync = ref.watch(chatListProvider);
    final authState = ref.watch(authProvider);
    final currentUserId = authState.user?.id ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(l10n.messagesTitle, style: AppTextStyles.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: l10n.tooltipNewMessage,
            onPressed: () => context.push('/chats/new'),
          ),
        ],
      ),
      body: chatListAsync.when(
        loading: _buildShimmer,
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.chat_bubble_outline, size: 64, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              Text(l10n.failedToLoadChats, style: AppTextStyles.bodyMedium),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(chatListProvider),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
        data: (chats) {
          if (chats.isEmpty) {
            return _emptyState(context);
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(chatListProvider.future),
            child: ListView.separated(
              padding: HomeScaffold.scrollPadding(context),
              itemCount: chats.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                indent: 72,
                color: AppColors.border,
              ),
              itemBuilder: (ctx, i) {
                final chat = chats[i];
                return ChatTile(
                  chat: chat,
                  currentUserId: currentUserId,
                  onTap: () => context.push('/chats/${chat.id}'),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_bubble_outline, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.emptyNoConversations,
              style: AppTextStyles.titleLarge.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.emptyConversationsHint,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.border,
      child: ListView.builder(
        itemCount: 8,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const CircleAvatar(radius: 26, backgroundColor: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 14, width: 120, color: Colors.white),
                    const SizedBox(height: 6),
                    Container(height: 12, width: 200, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
