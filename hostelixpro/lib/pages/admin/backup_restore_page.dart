import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hostelixpro/models/backup_meta.dart';
import 'package:hostelixpro/services/backup_service.dart';
import 'package:hostelixpro/theme/colors.dart';
import 'package:hostelixpro/theme/typography.dart';
import 'package:hostelixpro/widgets/layout/app_shell.dart';
// import 'package:url_launcher/url_launcher.dart'; // For downloading files

class BackupRestorePage extends StatefulWidget {
  const BackupRestorePage({super.key});

  @override
  State<BackupRestorePage> createState() => _BackupRestorePageState();
}

class _BackupRestorePageState extends State<BackupRestorePage> {
  List<BackupMeta> _backups = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    try {
      setState(() => _isLoading = true);
      final data = await BackupService.getBackups();
      setState(() {
        _backups = data;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createBackup() async {
    try {
      setState(() => _isLoading = true);
      final result = await BackupService.createBackup();
      final String key = result['key'];

      await _loadBackups();

      if (mounted) {
        _showKeyDialog(key);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create backup: $e')),
        );
      }
    }
  }

  void _showKeyDialog(String key) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Backup Created Successfully', style: AppTypography.h3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '⚠️ IMPORTANT: Save this encryption key immediately!',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.danger),
            ),
            const SizedBox(height: 16),
            const Text('You will need this key to restore this backup. We do not store it.'),
            const SizedBox(height: 16),
            SelectableText(
              key,
              style: const TextStyle(
                fontFamily: 'monospace',
                backgroundColor: AppColors.background,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: key));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Key copied to clipboard')),
                );
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copy Key'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
              )
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('I have saved the key'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadBackup(int id) async {
    ScaffoldMessenger.of(context).showSnackBar(
       const SnackBar(content: Text('Download functionality not implemented in MVP')),
    );
  }

  Future<void> _restoreBackup(int id) async {
    final keyController = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Restore Backup?', style: AppTypography.h3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the encryption key for this backup to verify it.'),
            const SizedBox(height: 16),
            TextField(
              controller: keyController,
              decoration: const InputDecoration(
                labelText: 'Encryption Key',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Verify & Restore'),
          ),
        ],
      ),
    );

    if (confirmed == true && keyController.text.isNotEmpty) {
      try {
        setState(() => _isLoading = true);
        final message = await BackupService.restoreBackup(id, keyController.text);
        
        if (mounted) {
          setState(() => _isLoading = false);
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Success'),
              content: Text(message),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
              ],
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Restore failed: $e')),
          );
        }
      }
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Backup & Restore',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadBackups,
        ),
      ],
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _createBackup,
              icon: const Icon(Icons.save),
              label: const Text('Create New Backup'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text('Error: $_error', style: TextStyle(color: AppColors.danger)))
                    : _backups.isEmpty
                        ? Center(child: Text('No backups found', style: AppTypography.body))
                        : ListView.builder(
                            itemCount: _backups.length,
                            itemBuilder: (context, index) {
                              final backup = _backups[index];
                              final date = DateTime.fromMillisecondsSinceEpoch(
                                  backup.createdAt);
                              
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 0, vertical: 8),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: AppColors.border),
                                ),
                                child: ListTile(
                                  leading: const Icon(Icons.backup, size: 40, color: AppColors.info),
                                  title: Text(backup.filename, style: AppTypography.h3),
                                  subtitle: Text(
                                    '${_formatSize(backup.fileSizeBytes)} • Created by ${backup.createdBy}\n${date.toString().substring(0, 16)}',
                                    style: AppTypography.caption,
                                  ),
                                  trailing: PopupMenuButton(
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'restore',
                                        child: Row(
                                          children: [
                                            Icon(Icons.restore),
                                            SizedBox(width: 8),
                                            Text('Restore/Verify'),
                                          ],
                                        ),
                                      ),
                                    ],
                                    onSelected: (value) {
                                      if (value == 'restore') {
                                        _restoreBackup(backup.id);
                                      } else if (value == 'download') {
                                        _downloadBackup(backup.id);
                                      }
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
