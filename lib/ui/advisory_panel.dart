import 'official_match.dart';
import 'threat_panel.dart';
import '../core/advisory_rules.dart';
import '../l10n/strings.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../core/advisories.dart';
import 'report_view.dart';

class AdvisoryPanel extends StatefulWidget {
  const AdvisoryPanel({
    super.key,
    required this.model,
    required this.firmware,
    required this.open,
  });
  final TextEditingController model, firmware;
  final void Function(Uri) open;
  @override
  State<AdvisoryPanel> createState() => _AdvisoryPanelState();
}

class _AdvisoryPanelState extends State<AdvisoryPanel> {
  bool _allow = false, _busy = false;
  int _cooldown = 0;
  Timer? _timer;
  AdvisorySearch? _results;
  String? _error;
  String _query = '';
  RuleMatch? _match;
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _search() async {
    final query = widget.model.text.trim();
    if (query.length < 3) {
      setState(() => _error = tr(context, 'advisory.invalid'));
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _results = null;
      _cooldown = 30;
    });
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _cooldown--);
      if (_cooldown == 0) timer.cancel();
    });
    try {
      final found = await searchAdvisories(query);
      if (mounted) {
        setState(() {
          _results = found;
          _query = query;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'advisory.error');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(height: 32),
      Text(
        tr(context, 'advisory.title'),
        style: Theme.of(context).textTheme.titleLarge,
      ),
      SizedBox(height: 12),
      Text(tr(context, 'advisory.instructions')),
      SizedBox(height: 16),
      TextField(
        controller: widget.model,
        maxLength: 100,
        enabled: !_busy,
        decoration: InputDecoration(labelText: tr(context, 'advisory.model')),
      ),
      SizedBox(height: 12),
      TextField(
        controller: widget.firmware,
        maxLength: 80,
        decoration: InputDecoration(
          labelText: tr(context, 'advisory.firmware'),
        ),
      ),
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        title: Text(tr(context, 'advisory.allow')),
        subtitle: Text(tr(context, 'advisory.privacy')),
        value: _allow,
        onChanged: _busy ? null : (v) => setState(() => _allow = v ?? false),
      ),
      OutlinedButton.icon(
        onPressed: _allow && !_busy && _cooldown == 0 ? _search : null,
        icon: Icon(Icons.search),
        label: Text(
          _busy
              ? tr(context, 'advisory.running')
              : _cooldown > 0
              ? tr(context, 'advisory.cooldown', {'seconds': _cooldown})
              : tr(context, 'advisory.search'),
        ),
      ),
      if (_busy)
        Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: LinearProgressIndicator(),
        ),
      if (_error != null) StatusText(_error!),
      if (_results != null) ...[
        Text(tr(context, 'advisory.attribution')),
        SizedBox(height: 16),
        Text(
          tr(context, 'advisory.results', {
            'total': _results!.total,
            'query': _query,
            'shown': _results!.items.length,
          }),
        ),
        StatusText(tr(context, 'advisory.candidates')),
        for (final item in _results!.items)
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(item.id),
            subtitle: Text(tr(context, 'advisory.candidate')),
            children: [
              SelectableText(item.description),
              TextButton(
                onPressed: () => widget.open(item.url),
                child: Text(tr(context, 'advisory.source')),
              ),
            ],
          ),
      ],
      OfficialMatch(
        model: widget.model,
        firmware: widget.firmware,
        open: widget.open,
        onMatch: (value) => setState(() => _match = value),
      ),
      if (_results != null || _match?.cve != null)
        ThreatPanel(
          ids: {
            ...?_results?.items.map((item) => item.id),
            if (_match?.cve != null) _match!.cve!,
          }.toList(),
        ),
    ],
  );
}
