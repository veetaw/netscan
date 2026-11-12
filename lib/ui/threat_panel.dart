import 'package:flutter/material.dart';
import '../core/threat_context.dart';
import '../l10n/strings.dart';

class ThreatPanel extends StatefulWidget {
  const ThreatPanel({super.key, required this.ids});
  final List<String> ids;
  @override
  State<ThreatPanel> createState() => _ThreatPanelState();
}

class _ThreatPanelState extends State<ThreatPanel> {
  bool _allowed = false, _busy = false;
  Map<String, ThreatContext>? _data;
  Future<void> _fetch() async {
    final requested = widget.ids.join(',');
    setState(() => _busy = true);
    try {
      final data = await fetchThreatContext(widget.ids);
      if (mounted && requested == widget.ids.join(',')) {
        setState(() => _data = data);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void didUpdateWidget(ThreatPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ids.join(',') != widget.ids.join(',')) _data = null;
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 16),
      Text(
        tr(context, 'threat.title'),
        style: Theme.of(context).textTheme.titleMedium,
      ),
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        value: _allowed,
        title: Text(tr(context, 'threat.allow')),
        subtitle: Text(tr(context, 'threat.privacy')),
        onChanged: _busy ? null : (v) => setState(() => _allowed = v ?? false),
      ),
      OutlinedButton(
        onPressed: _allowed && !_busy ? _fetch : null,
        child: Text(tr(context, _busy ? 'advisory.running' : 'threat.run')),
      ),
      if (_data != null) ...[
        Text(tr(context, 'threat.scope')),
        for (final entry in _data!.entries)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(entry.key),
            subtitle: Text(
              '${tr(context, entry.value.kev == true
                  ? 'threat.kevYes'
                  : entry.value.kev == false
                  ? 'threat.kevNo'
                  : 'threat.kevUnknown')}\n'
              '${tr(context, 'threat.epss')}: ${entry.value.epss == null ? tr(context, 'common.unknown') : '${(entry.value.epss! * 100).toStringAsFixed(2)}%'} '
              '${entry.value.epssDate ?? ''}\n${tr(context, 'threat.kevDate')}: ${entry.value.kevDate ?? tr(context, 'common.unknown')}',
            ),
          ),
      ],
    ],
  );
}
