import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/journal_entry.dart';

/// Formats and shares journal entries as plain text or files.
///
/// Supports:
/// - Single entry export (text or .txt file)
/// - Multi-entry export (for family sharing bundles)
/// - Safe family sharing (strips private metadata)
class JournalExportService {
  JournalExportService._();
  static final JournalExportService instance = JournalExportService._();

  static final DateFormat _dateFormat = DateFormat('MMMM d, yyyy');
  static final DateFormat _fileDateFormat = DateFormat('yyyy-MM-dd');

  // ─── Format a single entry as readable text ──────────────────────

  /// Format an entry for display/export.
  ///
  /// If [safeForSharing] is true, AI prompts are omitted and the
  /// output is simplified for external sharing.
  String formatEntry(JournalEntry entry, {bool safeForSharing = false}) {
    final buf = StringBuffer();

    // Title
    final title = entry.title.isNotEmpty ? entry.title : 'Journal Entry';
    buf.writeln(title);
    buf.writeln('=' * title.length);
    buf.writeln();

    // Date
    buf.writeln(_dateFormat.format(entry.createdAt));
    buf.writeln();

    // Scripture references
    if (entry.scriptureReferences.isNotEmpty) {
      buf.writeln('Scriptures: ${entry.scriptureReferences.join(', ')}');
      buf.writeln();
    }

    // AI prompt (only in personal export, not family sharing)
    if (!safeForSharing && entry.hasPrompt) {
      buf.writeln('Reflection prompt: ${entry.prompt}');
      buf.writeln();
    }

    // Content
    buf.writeln(entry.content);

    return buf.toString().trimRight();
  }

  // ─── Format multiple entries ─────────────────────────────────────

  /// Format multiple entries into a single document.
  String formatEntries(
    List<JournalEntry> entries, {
    bool safeForSharing = false,
    String? headerNote,
  }) {
    final buf = StringBuffer();

    if (headerNote != null && headerNote.isNotEmpty) {
      buf.writeln(headerNote);
      buf.writeln();
    }

    buf.writeln('Seminary Sidekick — Journal Entries');
    buf.writeln('===================================');
    buf.writeln();

    for (var i = 0; i < entries.length; i++) {
      if (i > 0) {
        buf.writeln();
        buf.writeln('---');
        buf.writeln();
      }
      buf.writeln(formatEntry(entries[i], safeForSharing: safeForSharing));
    }

    return buf.toString().trimRight();
  }

  // ─── Share via system share sheet ────────────────────────────────

  /// Share a single entry as text via the system share sheet.
  Future<void> shareEntry(JournalEntry entry) async {
    final text = formatEntry(entry);
    await Share.share(
      text,
      subject: entry.title.isNotEmpty ? entry.title : 'Journal Entry',
    );
  }

  /// Share multiple entries (family sharing mode).
  ///
  /// Uses [safeForSharing] to strip AI prompt metadata.
  /// Optionally includes a [personalNote] header like
  /// "Shared with love from [name]".
  Future<void> shareWithFamily({
    required List<JournalEntry> entries,
    String? personalNote,
  }) async {
    if (entries.isEmpty) return;

    final text = formatEntries(
      entries,
      safeForSharing: true,
      headerNote: personalNote,
    );

    final subject = entries.length == 1
        ? entries.first.title.isNotEmpty
            ? entries.first.title
            : 'A journal reflection'
        : '${entries.length} journal reflections';

    await Share.share(text, subject: subject);
  }

  // ─── Export as .txt file ─────────────────────────────────────────

  /// Export entries as a .txt file and share via the system share sheet.
  Future<void> exportAsTextFile(List<JournalEntry> entries) async {
    if (entries.isEmpty) return;

    final text = formatEntries(entries);
    final dateStr = _fileDateFormat.format(DateTime.now());
    final fileName = 'journal_export_$dateStr.txt';

    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(text);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Seminary Sidekick Journal Export',
      );
    } catch (e) {
      debugPrint('JournalExportService: export failed — $e');
      // Fall back to plain text share
      await Share.share(text, subject: 'Seminary Sidekick Journal Export');
    }
  }
}
