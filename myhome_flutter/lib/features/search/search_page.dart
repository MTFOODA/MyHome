import '../../core/widgets/app_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/config/marketplace_strings.dart';
import '../auth/presentation/auth_cubit.dart';
import '../properties/domain/property_repository.dart';

class SearchPage extends StatefulWidget {
  final PropertyRepository repository;
  const SearchPage({super.key, required this.repository});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late Future<List<Map<String, dynamic>>> _results;
  @override
  void initState() {
    super.initState();
    _results = widget.repository.roommates();
  }

  @override
  Widget build(BuildContext context) {
    if (!(context.watch<AuthCubit>().state.account?.canFindRoommates ??
        false)) {
      return const SizedBox.shrink();
    }
    return FutureBuilder(
      future: _results,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: TextButton(
              onPressed: () =>
                  setState(() => _results = widget.repository.roommates()),
              child: Text(words(context, 'retry')),
            ),
          );
        }
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcon(
                  Icons.people_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  words(context, 'roommates'),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Text(words(context, 'roommatesEmpty')),
              ],
            ),
          ),
        );
      },
    );
  }
}
