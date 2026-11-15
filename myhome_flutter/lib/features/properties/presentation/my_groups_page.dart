import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/marketplace_strings.dart';
import '../../auth/presentation/auth_cubit.dart';
import '../domain/property_repository.dart';
import '../../chat/presentation/chat_page.dart';
import '../../sales/presentation/sales_strings.dart';

class MyGroupsPage extends StatefulWidget {
  final PropertyRepository repository;
  const MyGroupsPage({super.key, required this.repository});
  @override
  State<MyGroupsPage> createState() => _MyGroupsPageState();
}

class _MyGroupsPageState extends State<MyGroupsPage> {
  late Future<List<Map<String, dynamic>>> _groups;
  @override
  void initState() {
    super.initState();
    _groups = widget.repository.groups();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(words(context, 'myGroups'))),
    body: FutureBuilder(
      future: _groups,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: TextButton(
              onPressed: () =>
                  setState(() => _groups = widget.repository.groups()),
              child: Text(words(context, 'retry')),
            ),
          );
        }
        final account = context.watch<AuthCubit>().state.account;
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (snapshot.data!.isEmpty) Text(words(context, 'empty')),
            for (final group in snapshot.data!)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.groups_outlined, size: 40),
                      const SizedBox(height: 12),
                      Text(
                        group['title'] as String,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        words(
                          context,
                          group['owner_id'] == account?.id
                              ? 'groupOwner'
                              : group['tenant_admin_id'] == account?.id
                              ? 'groupCoAdmin'
                              : 'groupMember',
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (group['messagingReady'] == true)
                        FilledButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  ChatPage(groupId: group['id'] as String),
                            ),
                          ),
                          icon: const Icon(Icons.chat_outlined),
                          label: Text(salesText(context, 'chat')),
                        )
                      else
                        Text(words(context, 'communicationPending')),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}
