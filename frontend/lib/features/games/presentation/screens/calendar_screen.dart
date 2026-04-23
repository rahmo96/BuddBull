import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/features/games/data/models/game_model.dart';
import 'package:buddbull/features/games/presentation/widgets/game_card.dart';
import 'package:buddbull/features/games/providers/game_provider.dart';
import 'package:buddbull/shared/widgets/error_view.dart';
import 'package:buddbull/shared/widgets/loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() =>
      _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  List<GameModel> _eventsForDay(
      List<GameModel> allGames, DateTime day) {
    return allGames
        .where((g) => isSameDay(g.scheduledAt, day))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final gamesAsync = ref.watch(calendarGamesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today_rounded),
            onPressed: () =>
                setState(() => _focusedDay = DateTime.now()),
            tooltip: 'Today',
          ),
        ],
      ),
      body: gamesAsync.when(
        loading: () =>
            const Center(child: BbLoadingIndicator()),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () =>
              ref.invalidate(calendarGamesProvider),
        ),
        data: (games) {
          final selectedGames = _selectedDay != null
              ? _eventsForDay(games, _selectedDay!)
              : _eventsForDay(games, _focusedDay);

          return Column(
            children: [
              // ── Calendar ──────────────────────────────────
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.grey200),
                ),
                child: TableCalendar<GameModel>(
                  firstDay: DateTime.utc(2024, 1, 1),
                  lastDay:
                      DateTime.utc(2027, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) =>
                      isSameDay(_selectedDay, day),
                  eventLoader: (day) =>
                      _eventsForDay(games, day),
                  startingDayOfWeek:
                      StartingDayOfWeek.monday,
                  onDaySelected:
                      (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onFormatChanged: (format) =>
                      setState(
                          () => _calendarFormat = format),
                  onPageChanged: (focusedDay) =>
                      _focusedDay = focusedDay,
                  calendarStyle: CalendarStyle(
                    selectedDecoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: AppColors.primary
                          .withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: const BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                    weekendTextStyle: AppTextStyles.bodyMedium,
                    outsideDaysVisible: false,
                    selectedTextStyle:
                        AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                    todayTextStyle:
                        AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                    defaultTextStyle:
                        AppTextStyles.bodyMedium,
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonShowsNext: false,
                    titleCentered: true,
                    titleTextStyle:
                        AppTextStyles.titleMedium,
                    formatButtonDecoration: BoxDecoration(
                      color: AppColors.primary
                          .withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.primary
                              .withOpacity(0.3)),
                    ),
                    formatButtonTextStyle:
                        AppTextStyles.labelMedium.copyWith(
                      color: AppColors.primary,
                    ),
                    leftChevronIcon: const Icon(
                      Icons.chevron_left_rounded,
                      color: AppColors.primary,
                    ),
                    rightChevronIcon: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: AppTextStyles.labelSmall
                        .copyWith(
                            fontWeight: FontWeight.w600),
                    weekendStyle: AppTextStyles.labelSmall
                        .copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.error),
                  ),
                ),
              ),

              // ── Day label ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      selectedGames.isEmpty
                          ? 'No games'
                          : '${selectedGames.length} game${selectedGames.length > 1 ? 's' : ''}',
                      style: AppTextStyles.titleSmall
                          .copyWith(
                              color: AppColors.textSecondary),
                    ),
                    const Spacer(),
                    if (_selectedDay != null)
                      Text(
                        '${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}',
                        style: AppTextStyles.labelMedium
                            .copyWith(
                                color: AppColors.primary),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // ── Games for selected day ─────────────────────
              Expanded(
                child: selectedGames.isEmpty
                    ? _EmptyDay()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                            16, 0, 16, 100),
                        itemCount: selectedGames.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (_, i) {
                          final game = selectedGames[i];
                          return GameCard(
                            game: game,
                            onTap: () => context
                                .push('/games/${game.id}'),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EmptyDay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📅', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            'No games on this day',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
