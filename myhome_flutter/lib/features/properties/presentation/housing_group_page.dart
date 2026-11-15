import '../../../core/widgets/app_layout.dart';
import 'package:flutter/material.dart';
import '../../../core/config/marketplace_strings.dart';
import '../domain/property_repository.dart';

class HousingGroupPage extends StatefulWidget {
  final String propertyId;
  final PropertyRepository repository;
  const HousingGroupPage({
    super.key,
    required this.propertyId,
    required this.repository,
  });
  @override
  State<HousingGroupPage> createState() => _HousingGroupPageState();
}

class _HousingGroupPageState extends State<HousingGroupPage> {
  late Future<List<Map<String, dynamic>>> _applications;
  String? _tenant;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _applications = widget.repository.applications(widget.propertyId);
  }

  Future<void> _action(
    Future<void> Function() run, {
    bool group = false,
  }) async {
    setState(() => _busy = true);
    try {
      await run();
      if (mounted) {
        setState(
          () =>
              _applications = widget.repository.applications(widget.propertyId),
        );
        if (group) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(words(context, 'groupPrepared'))),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(words(context, 'saveError'))));
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
    appBar: AppBar(title: Text(words(context, 'applications'))),
    body: FutureBuilder(
      future: _applications,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: TextButton(
              onPressed: () => setState(
                () => _applications = widget.repository.applications(
                  widget.propertyId,
                ),
              ),
              child: Text(words(context, 'retry')),
            ),
          );
        }
        final applicants = snapshot.data!,
            accepted = applicants
                .where((value) => value['status'] == 'accepted')
                .toList();
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final applicant in applicants)
                Card(
                  child: ListTile(
                    title: Text(applicant['name'] as String),
                    subtitle: Text(
                      words(context, applicant['status'] as String),
                    ),
                    trailing: applicant['status'] == 'pending'
                        ? TextButton(
                            onPressed: _busy
                                ? null
                                : () => _action(
                                    () => widget.repository.accept(
                                      applicant['id'] as String,
                                    ),
                                  ),
                            child: Text(words(context, 'acceptTenant')),
                          )
                        : null,
                  ),
                ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                initialValue: _tenant,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: words(context, 'tenantAdmin'),
                ),
                items: accepted
                    .map(
                      (a) => DropdownMenuItem(
                        value: a['user_id'] as String,
                        child: Text(a['name'] as String),
                      ),
                    )
                    .toList(),
                onChanged: _busy
                    ? null
                    : (value) => setState(() => _tenant = value),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _busy || _tenant == null
                    ? null
                    : () => _action(
                        () => widget.repository.createGroup(
                          widget.propertyId,
                          _tenant!,
                        ),
                        group: true,
                      ),
                child: Text(words(context, 'createGroup')),
              ),
              const SizedBox(height: 24),
              Text(words(context, 'communicationPending')),
            ],
          ),
        );
      },
    ),
  );
}
