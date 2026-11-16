import '../../../core/widgets/selection_tile.dart';
import '../../../core/widgets/app_layout.dart';
import '../../../core/widgets/app_icon.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/input/number_input.dart';
import '../domain/sales_repository.dart';
import 'financial_card.dart';
import 'sales_cubit.dart';
import 'sales_strings.dart';
import '../../chat/presentation/chat_page.dart';

class InputSpec {
  final String key, label;
  final int minimum, lines;
  final bool secret, number;
  const InputSpec(
    this.key,
    this.label, {
    this.minimum = 1,
    this.lines = 1,
    this.secret = false,
    this.number = false,
  });
}

Future<Map<String, String>?> salesForm(
  BuildContext context,
  String title,
  List<InputSpec> fields, {
  String? acknowledgement,
}) => showDialog<Map<String, String>>(
  context: context,
  builder: (_) => _SalesFormDialog(title, fields, acknowledgement),
);

class _SalesFormDialog extends StatefulWidget {
  final String title;
  final List<InputSpec> fields;
  final String? acknowledgement;
  const _SalesFormDialog(this.title, this.fields, this.acknowledgement);
  @override
  State<_SalesFormDialog> createState() => _SalesFormDialogState();
}

class _SalesFormDialogState extends State<_SalesFormDialog> {
  late final controllers = {
    for (final field in widget.fields) field.key: TextEditingController(),
  };
  final form = GlobalKey<FormState>();
  bool checked = false;
  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(salesText(context, widget.title)),
    content: SizedBox(
      width: 560,
      child: SingleChildScrollView(
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final spec in widget.fields)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextFormField(
                    key: ValueKey('sales-${spec.key}'),
                    controller: controllers[spec.key],
                    obscureText: spec.secret,
                    maxLines: spec.lines,
                    maxLength: spec.lines > 1 ? 20000 : 250,
                    keyboardType: spec.number
                        ? const TextInputType.numberWithOptions(decimal: true)
                        : TextInputType.text,
                    decoration: InputDecoration(
                      labelText: salesText(context, spec.label),
                      counterText: '',
                    ),
                    validator: (v) => (v?.trim().length ?? 0) < spec.minimum
                        ? '${salesText(context, spec.label)}: ${salesText(context, 'minimumCharacters')} ${spec.minimum}'
                        : null,
                  ),
                ),
              if (widget.acknowledgement != null)
                SelectionTile(
                  key: const Key('formAcknowledgement'),
                  artwork: 'consent',
                  selected: checked,
                  onChanged: (v) => setState(() => checked = v),
                  label: salesText(context, widget.acknowledgement!),
                ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(salesText(context, 'cancel')),
      ),
      FilledButton(
        key: const Key('salesSubmit'),
        onPressed: () {
          if (form.currentState!.validate() &&
              (widget.acknowledgement == null || checked)) {
            Navigator.pop(context, {
              for (final spec in widget.fields)
                spec.key: spec.number
                    ? latinDigits(controllers[spec.key]!.text.trim())
                    : controllers[spec.key]!.text.trim(),
            });
          }
        },
        child: Text(salesText(context, 'confirm')),
      ),
    ],
  );
}

Future<String?> chooseStaff(
  BuildContext context,
  SalesRepository repository,
  String specialty,
) async {
  try {
    final staff = (await repository.staff())
        .where((s) => s['active'] == true && s['specialty'] == specialty)
        .toList();
    if (!context.mounted) return null;
    return await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(salesText(context, specialty)),
        children: [
          if (staff.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(salesText(context, 'empty')),
            ),
          for (final worker in staff)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, worker['id']),
              child: Text(worker['name'] as String),
            ),
        ],
      ),
    );
  } catch (_) {
    return null;
  }
}

class SalesListPage extends StatefulWidget {
  final bool financialHistory;
  const SalesListPage({super.key, this.financialHistory = false});
  @override
  State<SalesListPage> createState() => _SalesListPageState();
}

class _SalesListPageState extends State<SalesListPage> {
  late Future<List<Map<String, dynamic>>> _data;
  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _data = context.read<SalesRepository>().listDeals();
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
    appBar: AppBar(
      title: Text(
        salesText(
          context,
          widget.financialHistory ? 'financeHistory' : 'deals',
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => setState(_reload),
          icon: const AppIcon(Icons.refresh),
        ),
      ],
    ),
    body: FutureBuilder(
      future: _data,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: TextButton(
              onPressed: () => setState(_reload),
              child: Text(salesText(context, 'retry')),
            ),
          );
        }
        final rows = snapshot.data!
            .where(
              (row) => !widget.financialHistory || row['stage'] == 'completed',
            )
            .toList();
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (rows.isEmpty) Text(salesText(context, 'empty')),
            for (final row in rows)
              Card(
                child: ListTile(
                  leading: const AppIcon(Icons.handshake_outlined),
                  title: Text(row['title'] as String),
                  subtitle: Text(salesText(context, row['stage'] as String)),
                  trailing: const AppIcon(Icons.chevron_right),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            SalesDetailPage(id: row['id'] as String),
                      ),
                    );
                    if (mounted) setState(_reload);
                  },
                ),
              ),
          ],
        );
      },
    ),
  );
}

class SalesDetailPage extends StatefulWidget {
  final String id;
  const SalesDetailPage({super.key, required this.id});
  @override
  State<SalesDetailPage> createState() => _SalesDetailPageState();
}

class _SalesDetailPageState extends State<SalesDetailPage> {
  late final SalesRepository _repo;
  late final SalesCubit _cubit;
  bool _consent = false;
  String? _checkedDigest;
  @override
  void initState() {
    super.initState();
    _repo = context.read<SalesRepository>();
    _cubit = SalesCubit(_repo, widget.id)..load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Widget section(String title, List<Widget> children) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            salesText(context, title),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    ),
  );
  Widget action(
    String label,
    VoidCallback? run, {
    IconData icon = Icons.chevron_right,
  }) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: OutlinedButton.icon(
      onPressed: _cubit.state.busy ? null : run,
      icon: AppIcon(icon),
      label: Text(salesText(context, label)),
    ),
  );
  Future<void> _book() async {
    final today = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: today.add(const Duration(days: 1)),
      firstDate: today,
      lastDate: today.add(const Duration(days: 179)),
    );
    if (date == null || !mounted) return;
    var hour = 12;
    final chosen = await showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text(salesText(context, 'hour')),
          content: DropdownButtonFormField<int>(
            initialValue: hour,
            items: [
              for (var h = 0; h < 24; h++)
                DropdownMenuItem(
                  value: h,
                  child: Text('${h.toString().padLeft(2, '0')}:00'),
                ),
            ],
            onChanged: (v) => update(() => hour = v ?? 12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(salesText(context, 'cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, hour),
              child: Text(salesText(context, 'confirm')),
            ),
          ],
        ),
      ),
    );
    if (chosen != null) {
      await _cubit.act(
        () => _repo.book(
          widget.id,
          DateTime(date.year, date.month, date.day, chosen),
        ),
      );
    }
  }

  Future<void> _review() async {
    final values = await salesForm(context, 'recordReview', const [
      InputSpec('reference', 'reference', minimum: 6),
      InputSpec('note', 'note', minimum: 20, lines: 4),
    ]);
    if (values == null || !mounted) return;
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(salesText(context, 'recordReview')),
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
    if (approved != null) {
      await _cubit.act(
        () => _repo.reviewContract(
          widget.id,
          approved,
          values['reference']!,
          values['note']!,
        ),
      );
    }
  }

  Future<void> _pay(Map<String, dynamic> invoice) async {
    final qr = _repo.paymentQr(widget.id);
    final report = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(salesText(context, 'payment')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${invoice['amount']} EGP',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text('${_cubit.state.deal?['payment_recipient'] ?? ''}'),
              const SizedBox(height: 12),
              SizedBox(
                width: 260,
                height: 260,
                child: FutureBuilder(
                  future: qr,
                  builder: (context, snapshot) => snapshot.hasData
                      ? Image.memory(
                          Uint8List.fromList(snapshot.data!),
                          fit: BoxFit.contain,
                        )
                      : snapshot.hasError
                      ? Text(salesText(context, 'PAYMENT_NOT_READY'))
                      : const Center(child: CircularProgressIndicator()),
                ),
              ),
              const SizedBox(height: 12),
              Text(salesText(context, 'paymentCredit')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(salesText(context, 'cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(salesText(context, 'reportTransfer')),
          ),
        ],
      ),
    );
    if (!mounted || report != true) return;
    final values = await salesForm(context, 'reportTransfer', const [
      InputSpec('reference', 'transferReference', minimum: 6),
    ]);
    if (values != null) {
      await _cubit.act(
        () => _repo.reportPayment(widget.id, values['reference']!),
      );
    }
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<SalesCubit, SalesState>(
    bloc: _cubit,
    builder: (context, state) {
      final data = state.deal;
      if (data == null) {
        return AppScaffold(
          appBar: AppBar(title: Text(salesText(context, 'deals'))),
          body: Center(
            child: state.busy
                ? const CircularProgressIndicator()
                : TextButton(
                    onPressed: _cubit.load,
                    child: Text(salesText(context, state.error ?? 'retry')),
                  ),
          ),
        );
      }
      final side = data['my_side'] as String;
      final participant = ['buyer', 'seller'].contains(side),
          admin = side == 'admin';
      final terms = data['terms'] as Map?;
      final agreed = side == 'buyer'
          ? data['buyer_consented'] == true
          : data['seller_consented'] == true;
      return AppScaffold(
        appBar: AppBar(
          title: Text(data['title'] as String),
          actions: [
            IconButton(
              onPressed: state.busy ? null : _cubit.load,
              icon: const AppIcon(Icons.refresh),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: AppLayout.formWidth(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (state.busy) const LinearProgressIndicator(),
                  if (state.error != null)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        salesText(context, state.error!),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  Chip(
                    label: Text(salesText(context, data['stage'] as String)),
                  ),
                  FinancialCard(
                    snapshot: Map<String, dynamic>.from(
                      data['financial'] as Map,
                    ),
                  ),
                  section('chat', [
                    action(
                      'chat',
                      () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => ChatPage(dealId: widget.id),
                        ),
                      ),
                      icon: Icons.chat_outlined,
                    ),
                  ]),
                  section('viewing', [
                    for (final value in data['viewings'] as List) ...[
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(value['reference'] as String),
                        subtitle: Text(
                          '${DateTime.parse(value['scheduled_at'] as String).toLocal()} · ${salesText(context, value['status'] as String)}',
                        ),
                      ),
                      if (side == 'seller' &&
                          value['owner_confirmed'] == false &&
                          value['status'] == 'requested')
                        action(
                          'confirmViewing',
                          () => _cubit.act(
                            () => _repo.ownerConfirm(value['id'] as String),
                          ),
                        ),
                      if (admin &&
                          value['owner_confirmed'] == true &&
                          value['status'] == 'requested')
                        action('assignAgent', () async {
                          final staff = await chooseStaff(
                            context,
                            _repo,
                            'field_agent',
                          );
                          if (staff != null) {
                            await _cubit.act(
                              () => _repo.assignViewing(
                                value['id'] as String,
                                staff,
                              ),
                            );
                          }
                        }),
                      if ((value['my_assignment'] == true || admin) &&
                          value['status'] == 'confirmed')
                        action('completeViewing', () async {
                          final v = await salesForm(
                            context,
                            'completeViewing',
                            const [
                              InputSpec('note', 'note', minimum: 10, lines: 3),
                            ],
                          );
                          if (v != null) {
                            await _cubit.act(
                              () => _repo.completeViewing(
                                value['id'] as String,
                                v['note']!,
                              ),
                            );
                          }
                        }),
                    ],
                    if (side == 'buyer' && data['stage'] == 'open')
                      action('book', _book, icon: Icons.event_outlined),
                  ]),
                  section('offers', [
                    for (final value in data['offers'] as List)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                '${value['amount']} EGP · ${salesText(context, value['status'] as String)}',
                              ),
                              if (value['can_respond'] == true)
                                Wrap(
                                  spacing: 12,
                                  children: [
                                    TextButton(
                                      onPressed: state.busy
                                          ? null
                                          : () => _cubit.act(
                                              () => _repo.decide(
                                                value['id'] as String,
                                                false,
                                              ),
                                            ),
                                      child: Text(salesText(context, 'reject')),
                                    ),
                                    FilledButton(
                                      onPressed: state.busy
                                          ? null
                                          : () => _cubit.act(
                                              () => _repo.decide(
                                                value['id'] as String,
                                                true,
                                              ),
                                            ),
                                      child: Text(salesText(context, 'accept')),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    if (participant && data['stage'] == 'open')
                      action('newOffer', () async {
                        final value = await salesForm(
                          context,
                          'newOffer',
                          const [
                            InputSpec('amount', 'offerAmount', number: true),
                          ],
                        );
                        if (value != null) {
                          await _cubit.act(
                            () => _repo.offer(widget.id, value['amount']!),
                          );
                        }
                      }),
                  ]),
                  section('agreement', [
                    Text(salesText(context, 'policy')),
                    if (terms != null) ...[
                      const Divider(),
                      Text('${terms['version']}'),
                      Text(
                        (Localizations.localeOf(context).languageCode == 'ar'
                                ? terms['body_ar']
                                : terms['body_en'])
                            as String,
                      ),
                      Text('${terms['due_condition']}'),
                      const SizedBox(height: 12),
                      Text(salesText(context, 'consentNotice')),
                      Text(
                        '${salesText(context, 'buyerConsent')}: ${data['buyer_consented'] == true ? '✓' : '—'}',
                      ),
                      Text(
                        '${salesText(context, 'sellerConsent')}: ${data['seller_consented'] == true ? '✓' : '—'}',
                      ),
                      if (participant &&
                          !agreed &&
                          data['stage'] == 'accepted') ...[
                        SelectionTile(
                          key: const Key('dealConsent'),
                          artwork: 'consent',
                          selected:
                              _consent && _checkedDigest == terms['digest'],
                          onChanged: state.busy
                              ? null
                              : (value) => setState(() {
                                  _consent = value;
                                  _checkedDigest = terms['digest'] as String;
                                }),
                          label: salesText(context, 'explicitConsent'),
                        ),
                        action(
                          'recordConsent',
                          _consent && _checkedDigest == terms['digest']
                              ? () => _cubit.act(
                                  () => _repo.consent(
                                    widget.id,
                                    terms['digest'] as String,
                                  ),
                                )
                              : null,
                        ),
                      ],
                    ],
                  ]),
                  if ((data['special_fee_proposals'] as List).isNotEmpty)
                    section('specialFee', [
                      for (final proposal
                          in data['special_fee_proposals'] as List) ...[
                        Text(
                          '${proposal['total']} EGP · ${salesText(context, proposal['status'] as String)}',
                        ),
                        Text(proposal['reason'] as String),
                        FinancialCard(
                          snapshot: Map<String, dynamic>.from(
                            proposal['financial'] as Map,
                          ),
                        ),
                        if (participant && proposal['status'] == 'pending')
                          Wrap(
                            spacing: 12,
                            children: [
                              TextButton(
                                onPressed: state.busy
                                    ? null
                                    : () => _cubit.act(
                                        () => _repo.consentSpecialFee(
                                          proposal['id'] as String,
                                          proposal['digest'] as String,
                                          false,
                                        ),
                                      ),
                                child: Text(salesText(context, 'reject')),
                              ),
                              FilledButton(
                                onPressed: state.busy
                                    ? null
                                    : () => _cubit.act(
                                        () => _repo.consentSpecialFee(
                                          proposal['id'] as String,
                                          proposal['digest'] as String,
                                          true,
                                        ),
                                      ),
                                child: Text(salesText(context, 'accept')),
                              ),
                            ],
                          ),
                      ],
                    ]),
                  if (admin &&
                      data['stage'] == 'open' &&
                      (data['financial'] as Map)['old_rent'] == true)
                    action('proposeFee', () async {
                      final v = await salesForm(context, 'specialFee', const [
                        InputSpec('total', 'specialTotal', number: true),
                        InputSpec('reason', 'reason', minimum: 20, lines: 3),
                        InputSpec('reference', 'reference', minimum: 6),
                      ]);
                      if (v != null) {
                        await _cubit.act(
                          () => _repo.proposeSpecialFee(
                            widget.id,
                            v['total']!,
                            v['reason']!,
                            v['reference']!,
                          ),
                        );
                      }
                    }),
                  section('legalReview', [
                    Text(salesText(context, data['review_status'] as String)),
                    if (admin && data['stage'] == 'accepted')
                      action('assignReviewer', () async {
                        final staff = await chooseStaff(
                          context,
                          _repo,
                          'document_reviewer',
                        );
                        if (staff != null) {
                          await _cubit.act(
                            () => _repo.assignReviewer(widget.id, staff),
                          );
                        }
                      }),
                    if (side == 'document_reviewer' || admin)
                      action(
                        'documents',
                        () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => ReviewDocumentsPage(id: widget.id),
                          ),
                        ),
                      ),
                    if (side == 'document_reviewer' &&
                        data['stage'] == 'accepted' &&
                        data['review_status'] != 'approved')
                      action('recordReview', () => _review()),
                  ]),
                  section('payment', [
                    Text(salesText(context, 'paymentCredit')),
                    Text(
                      '${salesText(context, 'paidPlatform')}: ${data['buyer_platform_paid']} EGP',
                    ),
                    Text(
                      '${salesText(context, 'remaining')}: ${data['buyer_remaining_total']} EGP',
                    ),
                    for (final invoice in data['invoices'] as List)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '${salesText(context, invoice['side'] == 'buyer' ? 'buyerFee' : 'sellerFee')}: ${invoice['amount']} EGP',
                        ),
                        subtitle: Text(
                          salesText(context, invoice['status'] as String),
                        ),
                        trailing:
                            invoice['mine'] == true &&
                                [
                                  'unpaid',
                                  'rejected',
                                ].contains(invoice['status']) &&
                                data['qr_ready'] == true
                            ? IconButton(
                                onPressed: state.busy
                                    ? null
                                    : () => _pay(
                                        Map<String, dynamic>.from(
                                          invoice as Map,
                                        ),
                                      ),
                                icon: const AppIcon(Icons.qr_code),
                                tooltip: salesText(context, 'pay'),
                              )
                            : null,
                      ),
                    if (admin &&
                        data['review_status'] == 'approved' &&
                        data['qr_ready'] == false)
                      action(
                        'preparePayment',
                        () => _cubit.act(() => _repo.preparePayment(widget.id)),
                      ),
                    if (admin)
                      for (final claim in data['claims'] as List)
                        if (claim['status'] == 'reported')
                          action('verifyTransfer', () async {
                            final v = await salesForm(
                              context,
                              'verifyTransfer',
                              const [
                                InputSpec(
                                  'note',
                                  'note',
                                  minimum: 20,
                                  lines: 3,
                                ),
                              ],
                            );
                            if (v == null || !context.mounted) return;
                            final decision = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(
                                  '${salesText(context, 'transferReference')}: ${claim['reference']}',
                                ),
                                content: Text(
                                  salesText(context, 'verifyTransfer'),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: Text(salesText(context, 'reject')),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: Text(salesText(context, 'accept')),
                                  ),
                                ],
                              ),
                            );
                            if (decision != null) {
                              await _cubit.act(
                                () => _repo.reviewPayment(
                                  claim['id'] as String,
                                  decision,
                                  v['note']!,
                                ),
                              );
                            }
                          }),
                    if (admin && data['stage'] == 'accepted')
                      action(
                        'completeDeal',
                        () => _cubit.act(() => _repo.complete(widget.id)),
                      ),
                  ]),
                  if (data['stage'] == 'open' ||
                      (admin && data['stage'] == 'accepted'))
                    action('cancel', () async {
                      final v = await salesForm(context, 'cancel', const [
                        InputSpec('note', 'note', minimum: 10, lines: 3),
                      ]);
                      if (v != null) {
                        await _cubit.act(
                          () => _repo.cancel(widget.id, v['note']!),
                        );
                      }
                    }),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class ReviewDocumentsPage extends StatefulWidget {
  final String id;
  final bool eligibility;
  const ReviewDocumentsPage({
    super.key,
    required this.id,
    this.eligibility = false,
  });
  @override
  State<ReviewDocumentsPage> createState() => _ReviewDocumentsPageState();
}

class _ReviewDocumentsPageState extends State<ReviewDocumentsPage> {
  late Future<List<Map<String, dynamic>>> _documents;
  final _images = <String, Future<List<int>>>{};
  @override
  void initState() {
    super.initState();
    _documents = context.read<SalesRepository>().documents(
      widget.id,
      eligibility: widget.eligibility,
    );
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
    appBar: AppBar(title: Text(salesText(context, 'documents'))),
    body: FutureBuilder(
      future: _documents,
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
            for (final document in snapshot.data!)
              SizedBox(
                height: 420,
                child: FutureBuilder(
                  future: _images.putIfAbsent(
                    document['id'] as String,
                    () => context.read<SalesRepository>().documentImage(
                      widget.id,
                      document['id'] as String,
                      eligibility: widget.eligibility,
                    ),
                  ),
                  builder: (context, image) => image.hasData
                      ? Image.memory(
                          Uint8List.fromList(image.data!),
                          fit: BoxFit.contain,
                        )
                      : image.hasError
                      ? Text(salesText(context, 'NETWORK_ERROR'))
                      : const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        );
      },
    ),
  );
}
