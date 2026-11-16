import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/operator_strings.dart';
import '../domain/sales_repository.dart';

class AdminDashboardState {
  final Map<String, int> counts;
  final bool loading, failed;
  const AdminDashboardState({
    this.counts = const {},
    this.loading = false,
    this.failed = false,
  });
}

class AdminDashboardCubit extends Cubit<AdminDashboardState> {
  final SalesRepository repository;
  Timer? _timer;
  AdminDashboardCubit(this.repository) : super(const AdminDashboardState());
  void start() {
    load();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => load());
  }

  Future<void> load() async {
    if (isClosed || state.loading) return;
    emit(AdminDashboardState(counts: state.counts, loading: true));
    try {
      final values = await repository.dashboard();
      if (!isClosed) {
        emit(
          AdminDashboardState(
            counts: {
              for (final entry in values.entries)
                entry.key: (entry.value as num).toInt(),
            },
          ),
        );
      }
    } catch (_) {
      if (!isClosed) emit(const AdminDashboardState(failed: true));
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}

class ReviewBadge extends StatelessWidget {
  final int count;
  const ReviewBadge(this.count, {super.key});
  @override
  Widget build(BuildContext context) => count <= 0
      ? const SizedBox.shrink()
      : Semantics(
          label: '${operatorText(context, 'pending')}: $count',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.red.shade700,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
}

class AdminDashboard extends StatelessWidget {
  final AdminDashboardCubit cubit;
  final void Function(String queue) onQueue;
  const AdminDashboard({super.key, required this.cubit, required this.onQueue});
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
        bloc: cubit,
        builder: (context, state) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      operatorText(context, 'dashboard'),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  IconButton(
                    onPressed: cubit.load,
                    tooltip: operatorText(context, 'refresh'),
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              if (state.loading) const LinearProgressIndicator(),
              if (state.failed)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(operatorText(context, 'dashboardFailed')),
                ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 900
                      ? 4
                      : constraints.maxWidth >= 550
                      ? 3
                      : 2;
                  final width =
                      (constraints.maxWidth - (columns - 1) * 14) / columns;
                  return Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: [
                      for (final entry in [
                        ('properties', Icons.apartment_outlined),
                        ('owners', Icons.home_work_outlined),
                        ('buyers', Icons.real_estate_agent_outlined),
                        ('renters', Icons.people_outline),
                        ('published_properties', Icons.public),
                        ('pending_total', Icons.pending_actions),
                      ])
                        SizedBox(
                          width: width,
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  Icon(
                                    entry.$2,
                                    size: 32,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    state.failed ||
                                            !state.counts.containsKey(entry.$1)
                                        ? '—'
                                        : '${state.counts[entry.$1]}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.headlineLarge,
                                  ),
                                  Text(
                                    operatorText(context, entry.$1),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              Text(operatorText(context, 'roleCountNote')),
              const SizedBox(height: 24),
              for (final key in [
                'property_reviews',
                'eligibility_reviews',
                'payment_reviews',
                'contract_reviews',
                'viewing_assignments',
              ])
                Card(
                  child: ListTile(
                    onTap: () => onQueue(key),
                    leading: const Icon(Icons.task_alt),
                    title: Text(operatorText(context, key)),
                    trailing: ReviewBadge(state.counts[key] ?? 0),
                  ),
                ),
            ],
          ),
        ),
      );
}
