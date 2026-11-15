import '../../../core/widgets/property_illustration.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/presentation/auth_cubit.dart';
import '../../properties/domain/property_repository.dart' show UploadImage;
import '../domain/sales_repository.dart';
import 'sales_pages.dart';
import 'sales_strings.dart';

class SalesAdminPage extends StatefulWidget {
  const SalesAdminPage({super.key});
  @override
  State<SalesAdminPage> createState() => _SalesAdminPageState();
}

class _SalesAdminPageState extends State<SalesAdminPage> {
  late final SalesRepository _repo;
  late Future<List<Map<String, dynamic>>> _staff;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _repo = context.read<SalesRepository>();
    _staff = _repo.staff();
  }

  Future<void> _act(Future<void> Function() run) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await run();
      if (mounted) {
        setState(() => _staff = _repo.staff());
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(salesText(context, 'success'))));
      }
    } on SalesFailure catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(salesText(context, e.code))));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(salesText(context, 'NETWORK_ERROR'))),
        );
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _newStaff() async {
    final kind = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(salesText(context, 'newStaff')),
        children: [
          for (final role in ['field_agent', 'document_reviewer'])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, role),
              child: Text(salesText(context, role)),
            ),
        ],
      ),
    );
    if (kind == null || !mounted) return;
    final values = await salesForm(context, 'newStaff', [
      const InputSpec('name', 'name', minimum: 2),
      const InputSpec('email', 'email', minimum: 5),
      const InputSpec('password', 'password', minimum: 12, secret: true),
      if (kind == 'document_reviewer')
        const InputSpec(
          'professional_reference',
          'professionalRef',
          minimum: 5,
        ),
    ]);
    if (values != null) {
      await _act(() => _repo.createStaff({...values, 'specialty': kind}));
    }
  }

  Future<void> _terms() async {
    final values = await salesForm(context, 'terms', const [
      InputSpec('version', 'version', minimum: 3),
      InputSpec('body_ar', 'termsAr', minimum: 100, lines: 6),
      InputSpec('body_en', 'termsEn', minimum: 100, lines: 6),
      InputSpec('due_condition', 'dueCondition', minimum: 20, lines: 3),
      InputSpec('legal_reference', 'professionalRef', minimum: 5),
    ], acknowledgement: 'legalReviewed');
    if (values != null) {
      await _act(() => _repo.publishTerms({...values, 'legal_reviewed': true}));
    }
  }

  Future<void> _qr() async {
    final values = await salesForm(context, 'qrSettings', const [
      InputSpec('recipient', 'recipient', minimum: 3),
    ]);
    if (values == null) return;
    final file = await openFile(
      acceptedTypeGroups: [
        const XTypeGroup(
          label: 'QR image',
          extensions: ['png', 'jpg', 'jpeg', 'webp'],
        ),
      ],
    );
    if (file == null) return;
    if (await file.length() > 2 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(salesText(context, 'QR_MAX_2MB'))),
        );
      }
      return;
    }
    final bytes = await file.readAsBytes();
    await _act(
      () => _repo.uploadQr(values['recipient']!, UploadImage(file.name, bytes)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (context.watch<AuthCubit>().state.account?.role != 'admin') {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(salesText(context, 'NETWORK_ERROR'))),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(salesText(context, 'salesAdmin'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_busy) const LinearProgressIndicator(),
                FilledButton.icon(
                  onPressed: _busy ? null : _newStaff,
                  icon: const AppImageIcon(Icons.person_add_outlined),
                  label: Text(salesText(context, 'newStaff')),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _terms,
                  icon: const AppImageIcon(Icons.description_outlined),
                  label: Text(salesText(context, 'terms')),
                ),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _qr,
                  icon: const AppImageIcon(Icons.qr_code),
                  label: Text(salesText(context, 'qrSettings')),
                ),
                const SizedBox(height: 20),
                Text(
                  salesText(context, 'staff'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                FutureBuilder(
                  future: _staff,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Text(salesText(context, 'NETWORK_ERROR'));
                    }
                    return Column(
                      children: [
                        for (final worker in snapshot.data!)
                          Card(
                            child: ListTile(
                              title: Text(worker['name'] as String),
                              subtitle: Text(
                                salesText(
                                  context,
                                  worker['specialty'] as String,
                                ),
                              ),
                              trailing: Switch(
                                value: worker['active'] as bool,
                                onChanged: _busy
                                    ? null
                                    : (value) => _act(
                                        () => _repo.staffState(
                                          worker['id'] as String,
                                          value,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EligibilityReviewsPage extends StatefulWidget {
  const EligibilityReviewsPage({super.key});
  @override
  State<EligibilityReviewsPage> createState() => _EligibilityReviewsPageState();
}

class _EligibilityReviewsPageState extends State<EligibilityReviewsPage> {
  late final SalesRepository _repo;
  late Future<List<Map<String, dynamic>>> _rows;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _repo = context.read<SalesRepository>();
    _rows = _repo.eligibilityReviews();
  }

  Future<void> _act(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) setState(() => _rows = _repo.eligibilityReviews());
    } on SalesFailure catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(salesText(context, e.code))));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(salesText(context, 'NETWORK_ERROR'))),
        );
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _review(String id) async {
    final data = await salesForm(context, 'recordReview', const [
      InputSpec('reference', 'reference', minimum: 6),
      InputSpec('note', 'note', minimum: 20, lines: 5),
    ]);
    if (data == null || !mounted) return;
    final eligible = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(salesText(context, 'eligibility')),
        content: Text(salesText(context, 'oldReference')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(salesText(context, 'reject')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(salesText(context, 'accept')),
          ),
        ],
      ),
    );
    if (eligible != null) {
      await _act(
        () => _repo.reviewEligibility(
          id,
          eligible,
          data['reference']!,
          data['note']!,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = context.watch<AuthCubit>().state.account;
    return Scaffold(
      appBar: AppBar(
        title: Text(salesText(context, 'eligibility')),
        actions: [
          IconButton(
            onPressed: () => setState(() => _rows = _repo.eligibilityReviews()),
            icon: const AppImageIcon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder(
        future: _rows,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(salesText(context, 'NETWORK_ERROR')));
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(salesText(context, 'oldReference')),
              if (_busy) const LinearProgressIndicator(),
              for (final row in snapshot.data!)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          row['title'] as String,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(salesText(context, row['eligibility'] as String)),
                        if (account?.role == 'admin')
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () async {
                                    final staff = await chooseStaff(
                                      context,
                                      _repo,
                                      'document_reviewer',
                                    );
                                    if (staff != null) {
                                      await _act(
                                        () => _repo.assignEligibility(
                                          row['id'] as String,
                                          staff,
                                        ),
                                      );
                                    }
                                  },
                            child: Text(salesText(context, 'assignReviewer')),
                          ),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => ReviewDocumentsPage(
                                id: row['id'] as String,
                                eligibility: true,
                              ),
                            ),
                          ),
                          child: Text(salesText(context, 'documents')),
                        ),
                        if (account?.staffRole == 'document_reviewer')
                          FilledButton(
                            onPressed: _busy
                                ? null
                                : () => _review(row['id'] as String),
                            child: Text(salesText(context, 'recordReview')),
                          ),
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
}
