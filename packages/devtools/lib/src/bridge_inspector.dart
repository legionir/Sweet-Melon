import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/lib/src/bridge/message_bridge.dart';
import '../../../plugin_engine/lib/src/plugin_manager.dart';
import '../../../core/lib/src/utils/logger.dart';

// ============================================================
// BRIDGE INSPECTOR — ابزار دیباگ
// ============================================================

class BridgeInspector {
  final MessageBridge bridge;
  final PluginManager manager;
  
  final List<InspectorEntry> _log = [];
  final _logController = StreamController<InspectorEntry>.broadcast();
  
  Stream<InspectorEntry> get logStream => _logController.stream;
  List<InspectorEntry> get log => List.unmodifiable(_log);

  BridgeInspector({
    required this.bridge,
    required this.manager,
  }) {
    _attachListeners();
  }

  void _attachListeners() {
    bridge.messageStream.listen((message) {
      final entry = InspectorEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        direction: message.direction == BridgeMessageDirection.incoming
            ? EntryDirection.jsToFlutter
            : EntryDirection.flutterToJs,
        timestamp: message.timestamp,
        content: message.message.toJson(),
      );
      
      _log.add(entry);
      if (_log.length > 500) _log.removeAt(0);
      
      _logController.add(entry);
    });
    
    manager.traces.listen((trace) {
      BridgeLogger.debug(
        'Inspector',
        '${trace.plugin}.${trace.method} — '
        '${trace.processingTimeMs}ms '
        '${trace.success ? "✓" : "✗"}',
      );
    });
  }

  void clear() => _log.clear();

  Map<String, dynamic> getReport() {
    final stats = manager.stats;
    
    return {
      'totalRequests': _log.length,
      'pluginStats': stats.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'cacheStats': {}, // از cache manager بگیرید
      'recentErrors': _log
          .where((e) => e.isError)
          .take(10)
          .map((e) => e.toJson())
          .toList(),
    };
  }

  void dispose() => _logController.close();
}

// ============================================================
// INSPECTOR ENTRY
// ============================================================

enum EntryDirection { jsToFlutter, flutterToJs }

class InspectorEntry {
  final String id;
  final EntryDirection direction;
  final DateTime timestamp;
  final Map<String, dynamic> content;

  const InspectorEntry({
    required this.id,
    required this.direction,
    required this.timestamp,
    required this.content,
  });

  bool get isError => content['success'] == false;

  Map<String, dynamic> toJson() => {
        'id': id,
        'direction': direction.name,
        'timestamp': timestamp.toIso8601String(),
        'content': content,
        'isError': isError,
      };
}

// ============================================================
// INSPECTOR UI
// ============================================================

class BridgeInspectorWidget extends StatefulWidget {
  final BridgeInspector inspector;

  const BridgeInspectorWidget({
    super.key,
    required this.inspector,
  });

  @override
  State<BridgeInspectorWidget> createState() => 
      _BridgeInspectorWidgetState();
}

class _BridgeInspectorWidgetState extends State<BridgeInspectorWidget> {
  final List<InspectorEntry> _entries = [];
  late final StreamSubscription<InspectorEntry> _sub;
  String _filter = '';
  bool _showErrors = false;

  @override
  void initState() {
    super.initState();
    _entries.addAll(widget.inspector.log);
    _sub = widget.inspector.logStream.listen((entry) {
      setState(() => _entries.insert(0, entry));
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  List<InspectorEntry> get _filteredEntries {
    var list = List<InspectorEntry>.from(_entries);
    if (_showErrors) list = list.where((e) => e.isError).toList();
    if (_filter.isNotEmpty) {
      list = list.where((e) {
        final content = jsonEncode(e.content).toLowerCase();
        return content.contains(_filter.toLowerCase());
      }).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          'Bridge Inspector',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'monospace',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all, color: Colors.white),
            onPressed: () {
              widget.inspector.clear();
              setState(() => _entries.clear());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildToolbar(),
          Expanded(child: _buildList()),
          _buildStats(),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      color: const Color(0xFF16213E),
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              style: const TextStyle(color: Colors.white, fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Filter...',
                hintStyle: TextStyle(color: Colors.white38),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
              ),
              onChanged: (v) => setState(() => _filter = v),
            ),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text(
              'Errors',
              style: TextStyle(fontSize: 11),
            ),
            selected: _showErrors,
            onSelected: (v) => setState(() => _showErrors = v),
            backgroundColor: Colors.transparent,
            selectedColor: Colors.red.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    final entries = _filteredEntries;
    
    if (entries.isEmpty) {
      return const Center(
        child: Text(
          'No messages',
          style: TextStyle(color: Colors.white38),
        ),
      );
    }
    
    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (ctx, i) => _EntryTile(entry: entries[i]),
    );
  }

  Widget _buildStats() {
    final report = widget.inspector.getReport();
    
    return Container(
      color: const Color(0xFF0F3460),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            'Total: ${_entries.length}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Errors: ${_entries.where((e) => e.isError).length}',
            style: const TextStyle(
              color: Colors.redAccent,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryTile extends StatefulWidget {
  final InspectorEntry entry;
  const _EntryTile({required this.entry});

  @override
  State<_EntryTile> createState() => _EntryTileState();
}

class _EntryTileState extends State<_EntryTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isIncoming = 
        widget.entry.direction == EntryDirection.jsToFlutter;
    final isError = widget.entry.isError;
    
    return InkWell(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF16213E),
          border: Border.all(
            color: isError
                ? Colors.red.withOpacity(0.5)
                : isIncoming
                    ? Colors.blue.withOpacity(0.3)
                    : Colors.green.withOpacity(0.3),
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Icon(
                    isIncoming
                        ? Icons.arrow_downward
                        : Icons.arrow_upward,
                    size: 14,
                    color: isIncoming ? Colors.blue : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.entry.content['plugin'] ?? ''}.'
                    '${widget.entry.content['method'] ?? 
                       (widget.entry.content['success'] == true ? 'response' : 'error')}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${widget.entry.timestamp.hour}:'
                    '${widget.entry.timestamp.minute.toString().padLeft(2, '0')}:'
                    '${widget.entry.timestamp.second.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            if (_expanded)
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.black26,
                child: SelectableText(
                  const JsonEncoder.withIndent('  ')
                      .convert(widget.entry.content),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
