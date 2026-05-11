import 'dart:io' as io;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/utils/formatters.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/app_card.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _isBackingUp = false;
  bool _isRestoring = false;
  String? _backupStatus;
  List<io.FileSystemEntity> _backups = [];

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    try {
      final backups = await ref.read(backupRepoProvider).listBackups();
      if (mounted) setState(() => _backups = backups);
    } catch (_) {}
  }

  Future<void> _backupNow() async {
    setState(() {
      _isBackingUp = true;
      _backupStatus = null;
    });
    try {
      final path = await ref.read(backupRepoProvider).createBackup();
      setState(() => _backupStatus = 'Backup saved to:\n$path');
      await _loadBackups();
    } catch (e) {
      setState(() => _backupStatus = 'Backup failed: $e');
    } finally {
      setState(() => _isBackingUp = false);
    }
  }

  Future<void> _exportCsv() async {
    try {
      final path = await ref.read(backupRepoProvider).exportToCsv();
      await SharePlus.instance
          .share(ShareParams(files: [XFile(path)], text: 'MithMoney Export'));
    } catch (e) {
      _showError('CSV export failed: $e');
    }
  }

  Future<void> _restore() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.single.path == null) return;

    final confirm = await _confirmRestore();
    if (!confirm) return;

    setState(() => _isRestoring = true);
    try {
      await ref
          .read(backupRepoProvider)
          .restoreFromFile(result.files.single.path!);
      ref.read(transactionProvider.notifier).refresh();
      ref.read(categoryProvider.notifier).refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Restore complete!')),
        );
      }
    } catch (e) {
      _showError('Restore failed: $e');
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  Future<void> _importData() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx'],
    );
    if (result == null || result.files.single.path == null) return;

    final path = result.files.single.path!;
    final extension = path.split('.').last.toLowerCase();

    setState(() => _isRestoring = true);
    try {
      int count = 0;
      if (extension == 'csv') {
        count = await ref.read(importRepoProvider).importFromCsv(path);
      } else if (extension == 'xlsx') {
        count = await ref.read(importRepoProvider).importFromExcel(path);
      }

      ref.read(transactionProvider.notifier).refresh();
      ref.read(accountProvider.notifier).refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('✅ Successfully imported $count transactions!')),
        );
      }
    } catch (e) {
      _showError('Import failed: $e');
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  Future<bool> _confirmRestore() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Restore Backup?',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: const Text(
            'This will replace ALL current data with the backup. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE8365D)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Backup & Restore'),
        leading: const BackButton(),
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Backup now card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C63FF)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.backup_rounded,
                                color: Color(0xFF6C63FF)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Manual Backup',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (settings.lastBackupAt != null)
                                  Text(
                                    'Last: ${AppFormatters.formatDateTime(settings.lastBackupAt!)}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_backupStatus != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            _backupStatus!,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: _backupStatus!.contains('failed')
                                  ? const Color(0xFFE8365D)
                                  : const Color(0xFF00B87C),
                            ),
                          ),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isBackingUp ? null : _backupNow,
                              icon: _isBackingUp
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.save_rounded),
                              label: Text(_isBackingUp
                                  ? 'Backing up...'
                                  : 'Backup Now'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _exportCsv,
                            icon: const Icon(Icons.table_chart_rounded),
                            label: const Text('CSV'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00B87C),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms),
            ),

            // Restore card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0984E3)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.restore_rounded,
                                color: Color(0xFF0984E3)),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Restore from File',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Select a .json backup file',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isRestoring ? null : _restore,
                          icon: _isRestoring
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.folder_open_rounded),
                          label: Text(_isRestoring
                              ? 'Restoring...'
                              : 'Choose Backup File'),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate(delay: 100.ms).fadeIn(duration: 400.ms),
            ),

            // Import card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF9F43)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.upload_file_rounded,
                                color: Color(0xFFFF9F43)),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Import Transactions',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Import from CSV or XLSX',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isRestoring ? null : _importData,
                          icon: const Icon(Icons.file_open_rounded),
                          label: const Text('Choose CSV/XLSX File'),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate(delay: 150.ms).fadeIn(duration: 400.ms),
            ),

            // Backup history
            if (_backups.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Text(
                    'Backup History',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final f = _backups[i];
                      final name = f.path.split('/').last.split('\\').last;
                      return ListTile(
                        leading: const Icon(Icons.description_rounded,
                            color: Color(0xFF6C63FF)),
                        title: Text(
                          name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.share_rounded, size: 18),
                              onPressed: () async {
                                await SharePlus.instance
                                    .share(ShareParams(files: [XFile(f.path)]));
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded,
                                  size: 18, color: Color(0xFFE8365D)),
                              onPressed: () async {
                                await ref
                                    .read(backupRepoProvider)
                                    .deleteBackup(f.path);
                                _loadBackups();
                              },
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: _backups.length,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
