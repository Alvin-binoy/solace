import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  void _showPasswordDialog(BuildContext context, {required String title, required String action, required Function(String) onSubmit}) {
    String password = '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter encryption password'),
          onChanged: (val) => password = val,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (password.isNotEmpty) {
                Navigator.pop(ctx);
                onSubmit(password);
              }
            },
            child: Text(action),
          ),
        ],
      ),
    );
  }

  void _handleCreateBackup(BuildContext context) {
    _showPasswordDialog(
      context,
      title: 'Secure Your Backup',
      action: 'Create',
      onSubmit: (password) {
        context.read<SettingsBloc>().add(CreateBackupEvent(password));
      },
    );
  }

  void _handleRestoreBackup(BuildContext context) async {
    try {
      // Switched back to FileType.any to prevent Android from silently crashing the picker
      final result = await fp.FilePicker.platform.pickFiles(
        type: fp.FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null && context.mounted) {
        final path = result.files.single.path!;

        // Quick check to ensure they actually picked a .solace file
        if (!path.endsWith('.solace')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a valid .solace backup file.'), backgroundColor: Colors.red),
          );
          return;
        }

        final bytes = await File(path).readAsBytes();

        if (!context.mounted) return;
        _showPasswordDialog(
          context,
          title: 'Decrypt Backup',
          action: 'Restore',
          onSubmit: (password) {
            context.read<SettingsBloc>().add(RestoreBackupEvent(bytes, password));
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open file picker: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: BlocConsumer<SettingsBloc, SettingsState>(
        listener: (context, state) async {
          if (state is SettingsActionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          } else if (state is SettingsBackupReady) {
            final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
            final fileName = 'solace_backup_$dateStr.solace';

            // Show a sleek menu to let you choose where it goes
            showModalBottomSheet(
              context: context,
              builder: (sheetContext) {
                return SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const ListTile(
                        title: Text('Export Destination', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      ListTile(
                        leading: const Icon(Icons.folder_outlined),
                        title: const Text('Save to Phone Storage'),
                        subtitle: const Text('Pick a specific folder on this device'),
                        onTap: () async {
                          Navigator.pop(sheetContext); // Close the menu
                          try {
                            // Opens the native Android folder picker & writes securely
                            String? outputFile = await fp.FilePicker.platform.saveFile(
                              dialogTitle: 'Save Backup',
                              fileName: fileName,
                              type: fp.FileType.custom,
                              allowedExtensions: ['solace'],
                              bytes: state.bytes, // FIX: Let the plugin handle the file writing
                            );

                            if (outputFile != null && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Backup saved locally!'), backgroundColor: Colors.green),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Save failed: $e'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.cloud_upload_outlined),
                        title: const Text('Share to Cloud / App'),
                        subtitle: const Text('Google Drive, Email, WhatsApp, etc.'),
                        onTap: () async {
                          Navigator.pop(sheetContext); // Close the menu

                          // Write to a temp file so Android can share it properly
                          final tempDir = await getTemporaryDirectory();
                          final tempFile = File('${tempDir.path}/$fileName');
                          await tempFile.writeAsBytes(state.bytes);

                          final xFile = XFile(tempFile.path);
                          // ignore: deprecated_member_use
                          await Share.shareXFiles([xFile], text: 'My Solace Backup');
                        },
                      ),
                    ],
                  ),
                );
              },
            );

          } else if (state is SettingsRestoreSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Backup restored successfully! Please restart the app.'), backgroundColor: Colors.green),
            );
          }
        },
        buildWhen: (previous, current) => current is SettingsLoaded || current is SettingsLoading || current is SettingsInitial,
        builder: (context, state) {
          if (state is SettingsLoading || state is SettingsInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is SettingsLoaded) {
            final settings = state.settings;

            return ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('APPEARANCE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                ),
                ListTile(
                  leading: const Icon(Icons.brightness_6),
                  title: const Text('Theme'),
                  trailing: DropdownButton<String>(
                    value: settings.themeMode,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'system', child: Text('System')),
                      DropdownMenuItem(value: 'light', child: Text('Light')),
                      DropdownMenuItem(value: 'dark', child: Text('Dark')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        context.read<SettingsBloc>().add(
                            UpdateSettingsEvent(settings.copyWith(themeMode: val))
                        );
                      }
                    },
                  ),
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('DATA & BACKUP', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                ),
                ListTile(
                  leading: const Icon(Icons.download),
                  title: const Text('Export Local Backup'),
                  subtitle: const Text('Save an encrypted copy of your data'),
                  onTap: () => _handleCreateBackup(context),
                ),
                ListTile(
                  leading: const Icon(Icons.restore),
                  title: const Text('Restore Local Backup'),
                  subtitle: const Text('Load data from a .solace file'),
                  onTap: () => _handleRestoreBackup(context),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}