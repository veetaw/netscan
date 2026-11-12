import 'package:flutter/material.dart';
import '../core/advisory_rules.dart';
import '../l10n/strings.dart';

class OfficialMatch extends StatefulWidget {
  const OfficialMatch({
    super.key,
    required this.model,
    required this.firmware,
    required this.open,
    required this.onMatch,
  });
  final TextEditingController model, firmware;
  final void Function(Uri) open;
  final ValueChanged<RuleMatch> onMatch;
  @override
  State<OfficialMatch> createState() => _OfficialMatchState();
}

class _OfficialMatchState extends State<OfficialMatch> {
  final _hardware = TextEditingController();
  bool _confirmed = false;
  String _region = 'Unknown';
  RuleMatch? _match;
  String _evaluatedModel = '', _evaluatedFirmware = '';
  @override
  void initState() {
    super.initState();
    widget.model.addListener(_detailsChanged);
    widget.firmware.addListener(_detailsChanged);
    _hardware.addListener(_detailsChanged);
  }

  void _detailsChanged() {
    if (_match == null && !_confirmed) return;
    _clearResult(resetConfirmation: true);
  }

  void _clearResult({bool resetConfirmation = false}) {
    final hadResult = _match != null;
    setState(() {
      _match = null;
      if (resetConfirmation) _confirmed = false;
    });
    if (hadResult) widget.onMatch(const RuleMatch(Applicability.unsupported));
  }

  @override
  void dispose() {
    widget.model.removeListener(_detailsChanged);
    widget.firmware.removeListener(_detailsChanged);
    _hardware.removeListener(_detailsChanged);
    _hardware.dispose();
    super.dispose();
  }

  void _run() {
    final result = matchOfficialAdvisory(
      model: widget.model.text,
      hardware: _hardware.text,
      firmware: widget.firmware.text,
      region: _region,
      detailsConfirmed: _confirmed,
    );
    setState(() {
      _match = result;
      _evaluatedModel = widget.model.text;
      _evaluatedFirmware = widget.firmware.text;
    });
    widget.onMatch(result);
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 16),
      ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(tr(context, 'match.title')),
        subtitle: Text(tr(context, 'match.coverage')),
        children: [
          TextField(
            controller: _hardware,
            decoration: InputDecoration(
              labelText: tr(context, 'advisory.hardware'),
            ),
          ),
          DropdownButtonFormField<String>(
            initialValue: _region,
            decoration: InputDecoration(
              labelText: tr(context, 'advisory.region'),
            ),
            items: [
              for (final value in ['Unknown', 'US', 'EU', 'Global'])
                DropdownMenuItem(
                  value: value,
                  child: Text(
                    value == 'Unknown' ? tr(context, 'common.unknown') : value,
                  ),
                ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _region = value);
                _clearResult(resetConfirmation: true);
              }
            },
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _confirmed,
            title: Text(tr(context, 'match.confirm')),
            onChanged: (v) {
              _clearResult();
              setState(() => _confirmed = v ?? false);
            },
          ),
          OutlinedButton(
            onPressed: _run,
            child: Text(tr(context, 'match.run')),
          ),
        ],
      ),
      if (_match != null) ...[
        Text(
          tr(context, 'match.evaluated', {
            'model': _evaluatedModel,
            'firmware': _evaluatedFirmware,
          }),
        ),
        Text(
          tr(context, 'match.${_match!.status.name}'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (_match!.cve != null) Text(_match!.cve!),
        if (_match!.actionKey != null) Text(tr(context, _match!.actionKey!)),
        if (_match!.source != null)
          TextButton(
            onPressed: () => widget.open(Uri.parse(_match!.source!)),
            child: Text(tr(context, 'match.source')),
          ),
        if (_match!.support != null)
          TextButton(
            onPressed: () => widget.open(Uri.parse(_match!.support!)),
            child: Text(tr(context, 'match.support')),
          ),
        Text(tr(context, 'match.scope')),
      ],
    ],
  );
}
