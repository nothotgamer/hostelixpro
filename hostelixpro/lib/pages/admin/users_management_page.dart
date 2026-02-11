import 'package:flutter/material.dart';
import 'package:hostelixpro/models/user.dart';
import 'package:hostelixpro/services/user_service.dart';
import 'package:hostelixpro/theme/colors.dart';
import 'package:hostelixpro/theme/typography.dart';
import 'package:hostelixpro/widgets/common/status_badge.dart';
import 'package:hostelixpro/widgets/data/data_table.dart';
import 'package:hostelixpro/widgets/forms/form_field.dart';
import 'package:hostelixpro/widgets/layout/app_shell.dart';

import 'package:hostelixpro/widgets/admin/user_approval_dialog.dart';

class UsersManagementPage extends StatefulWidget {
  const UsersManagementPage({super.key});

  @override
  State<UsersManagementPage> createState() => _UsersManagementPageState();
}

class _UsersManagementPageState extends State<UsersManagementPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<User> _activeUsers = [];
  List<User> _pendingUsers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final active = await UserService.getUsers(isApproved: true);
      final pending = await UserService.getUsers(isApproved: false);
      
      if (mounted) {
        setState(() {
          _activeUsers = active;
          _pendingUsers = pending;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _showUserDialog({User? user}) {
    showDialog(
      context: context,
      builder: (context) => _UserDialog(user: user),
    ).then((val) {
      if (val == true) _loadUsers();
    });
  }

  void _showApprovalDialog(User user) {
    showDialog(
      context: context,
      builder: (context) => UserApprovalDialog(
        user: user,
        onSuccess: _loadUsers,
      ),
    );
  }

  Future<void> _deleteUser(User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete ${user.displayName ?? user.email}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await UserService.deleteUser(user.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User deleted successfully')),
          );
          _loadUsers();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}')),
          );
        }
      }
    }
  }

  Future<void> _toggleLock(User user) async {
    try {
      final newLockState = await UserService.toggleLock(user.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User ${newLockState ? "locked" : "unlocked"} successfully')),
        );
        _loadUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isMobile = MediaQuery.of(context).size.width < 1100;
    
    return AppShell(
      title: 'User Management',
      floatingActionButton: isMobile 
          ? FloatingActionButton(
              onPressed: () => _showUserDialog(),
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              child: const Icon(Icons.add),
            )
          : null,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadUsers,
        ),
        if (!isMobile)
          ElevatedButton.icon(
            onPressed: () => _showUserDialog(),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
            icon: const Icon(Icons.person_add),
            label: const Text('Add User'),
          ),
      ],
      child: Column(
        children: [
          // Tab Bar
          Container(
            color: colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              tabs: [
                Tab(child: Text("Active Users (${_activeUsers.length})")),
                Tab(child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Pending Requests"),
                    if (_pendingUsers.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _pendingUsers.length.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ]
                  ],
                )),
              ],
            ),
          ),
          
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Text('Error: $_error', style: TextStyle(color: colorScheme.error)))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        // Tab 1: Active Users
                        isMobile ? _buildMobileList(_activeUsers, colorScheme) : _buildDesktopTable(_activeUsers, colorScheme),
                        
                        // Tab 2: Pending Users
                        _buildPendingList(colorScheme),
                      ],
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTable(List<User> users, ColorScheme colorScheme) {
    return SingleChildScrollView(
      child: AppDataTable(
        columns: const [
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Email')),
          DataColumn(label: Text('Role')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Actions')),
        ],
        rows: users.map((user) {
          final display = user.displayName ?? user.email.split('@')[0];
          return DataRow(cells: [
            DataCell(Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                  child: Text(
                    display.isNotEmpty ? display[0].toUpperCase() : '?',
                    style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Text(display, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            )),
            DataCell(Text(user.email)),
            DataCell(StatusBadge(
              label: user.role.toUpperCase(),
              type: user.role == 'admin' ? StatusType.info : StatusType.pending,
            )),
            DataCell(StatusBadge(
              label: user.isLocked ? 'LOCKED' : 'ACTIVE',
              type: user.isLocked ? StatusType.rejected : StatusType.approved,
            )),
            DataCell(Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  color: colorScheme.onSurfaceVariant,
                  onPressed: () => _showUserDialog(user: user),
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: Icon(user.isLocked ? Icons.lock_open : Icons.lock, size: 20),
                  color: user.isLocked ? AppColors.success : AppColors.warning,
                  onPressed: () => _toggleLock(user),
                  tooltip: user.isLocked ? 'Unlock' : 'Lock',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: AppColors.danger,
                  onPressed: () => _deleteUser(user),
                  tooltip: 'Delete',
                ),
              ],
            )),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildMobileList(List<User> users, ColorScheme colorScheme) {
    if (users.isEmpty) {
      return const Center(child: Text("No users found."));
    }
    return ListView.builder(
      itemCount: users.length,
      padding: const EdgeInsets.only(bottom: 80), // Space for FAB
      itemBuilder: (context, index) {
        final user = users[index];
        final display = user.displayName ?? user.email.split('@')[0];
        
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: colorScheme.primaryContainer,
                      child: Text(
                        display.isNotEmpty ? display[0].toUpperCase() : '?',
                        style: TextStyle(color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(display, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(user.email, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) {
                         if (value == 'edit') _showUserDialog(user: user);
                         if (value == 'lock') _toggleLock(user);
                         if (value == 'delete') _deleteUser(user);
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 8), Text('Edit')]),
                        ),
                        PopupMenuItem(
                          value: 'lock',
                          child: Row(children: [
                            Icon(user.isLocked ? Icons.lock_open : Icons.lock, size: 20, color: user.isLocked ? AppColors.success : AppColors.warning), 
                            const SizedBox(width: 8), 
                            Text(user.isLocked ? 'Unlock' : 'Lock')
                          ]),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(children: [Icon(Icons.delete, size: 20, color: AppColors.danger), SizedBox(width: 8), Text('Delete')]),
                        ),
                      ],
                    )
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    StatusBadge(
                      label: user.role.toUpperCase(),
                      type: user.role == 'admin' ? StatusType.info : StatusType.pending,
                    ),
                    StatusBadge(
                      label: user.isLocked ? 'LOCKED' : 'ACTIVE',
                      type: user.isLocked ? StatusType.rejected : StatusType.approved,
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPendingList(ColorScheme colorScheme) {
    if (_pendingUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: colorScheme.primaryContainer),
            const SizedBox(height: 16),
            const Text("No pending requests"),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingUsers.length,
      itemBuilder: (context, index) {
        final user = _pendingUsers[index];
        final display = user.displayName ?? user.email;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(child: Text(display[0].toUpperCase())),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(display, style:Theme.of(context).textTheme.titleMedium),
                      Text(user.email, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                
                // Actions
                ElevatedButton.icon(
                  onPressed: () => _showApprovalDialog(user),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Approve'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _UserDialog extends StatefulWidget {
  final User? user;

  const _UserDialog({this.user});

  @override
  State<_UserDialog> createState() => _UserDialogState();
}

class _UserDialogState extends State<_UserDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  
  // Student specific controllers
  late TextEditingController _admissionNoController;
  late TextEditingController _roomController;
  late TextEditingController _monthlyFeeController;
  int? _assignedTeacherId;
  
  String _role = 'student';
  bool _isSubmitting = false;
  
  List<User> _teachers = [];
  bool _isLoadingTeachers = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user?.displayName ?? '');
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _passwordController = TextEditingController();
    
    // Initialize with existing data if available
    final profile = widget.user?.studentProfile;
    _admissionNoController = TextEditingController(text: profile?['admission_no'] ?? '');
    _roomController = TextEditingController(text: profile?['room'] ?? '');
    _monthlyFeeController = TextEditingController(text: profile?['monthly_fee_amount']?.toString() ?? '');
    _assignedTeacherId = profile?['assigned_teacher_id'];
    
    _role = widget.user?.role ?? 'student';
    
    if (_role == 'student' || widget.user == null) {
      _fetchTeachers();
    }
  }
  
  Future<void> _fetchTeachers() async {
    setState(() => _isLoadingTeachers = true);
    try {
      final teachers = await UserService.getUsers(role: 'teacher');
      if (mounted) {
        setState(() {
          _teachers = teachers;
          _isLoadingTeachers = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingTeachers = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSubmitting = true);
    
    try {
      if (widget.user != null) {
        // Update existing user
        await UserService.updateUser(
          widget.user!.id,
          email: _emailController.text.trim(),
          displayName: _nameController.text.trim(),
          role: _role,
          admissionNo: _role == 'student' ? _admissionNoController.text.trim() : null,
          room: _role == 'student' ? _roomController.text.trim() : null,
          assignedTeacherId: _role == 'student' ? _assignedTeacherId : null,
          monthlyFeeAmount: _role == 'student' && _monthlyFeeController.text.isNotEmpty ? double.tryParse(_monthlyFeeController.text) : null,
        );
      } else {
        // Create new user
        await UserService.createUser(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          role: _role,
          displayName: _nameController.text.trim(),
          // Pass student specific fields only if role is student
          admissionNo: _role == 'student' ? _admissionNoController.text.trim() : null,
          room: _role == 'student' ? _roomController.text.trim() : null,
          assignedTeacherId: _role == 'student' ? _assignedTeacherId : null,
          monthlyFeeAmount: _role == 'student' && _monthlyFeeController.text.isNotEmpty ? double.tryParse(_monthlyFeeController.text) : null,
        );
      }
      
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User ${widget.user != null ? 'updated' : 'created'} successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}')),
        );
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.user != null;
    final colorScheme = Theme.of(context).colorScheme;
    
    return AlertDialog(
      title: Text(isEditing ? 'Edit User' : 'Create User', style: AppTypography.h3),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppFormField(
                  label: 'Full Name',
                  controller: _nameController,
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                AppFormField(
                  label: 'Email Address',
                  controller: _emailController,
                  validator: (v) => v?.contains('@') == false ? 'Invalid email' : null,
                ),
                const SizedBox(height: 16),
                if (!isEditing) ...[
                  AppFormField(
                    label: 'Password',
                    controller: _passwordController,
                    obscureText: true,
                    validator: (v) => (v?.length ?? 0) < 6 ? 'Min 6 characters' : null,
                  ),
                  const SizedBox(height: 16),
                ],
                
                DropdownButtonFormField<String>(
                  initialValue: _role,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'student', child: Text('Student')),
                    DropdownMenuItem(value: 'teacher', child: Text('Teacher')),
                    DropdownMenuItem(value: 'routine_manager', child: Text('Routine Manager')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  ],
                  onChanged: (v) {
                    setState(() => _role = v!);
                    if (v == 'student' && _teachers.isEmpty) {
                      _fetchTeachers();
                    }
                  },
                ),
                
                // Student Specific Fields
                if (_role == 'student') ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text("Student Details", style: AppTypography.label),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: AppFormField(
                          label: 'Admission No',
                          controller: _admissionNoController,
                          // Optional during creation? Or required? Let's make it optional but recommended
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AppFormField(
                          label: 'Room No',
                          controller: _roomController,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  if (_isLoadingTeachers)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: LinearProgressIndicator(minHeight: 2),
                    ),
                  DropdownButtonFormField<int>(
                    initialValue: _assignedTeacherId,
                    decoration: const InputDecoration(
                      labelText: 'Assign Teacher',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<int>(
                        value: null,
                        child: Text('None (Assign Later)'),
                      ),
                      ..._teachers.map((t) => DropdownMenuItem(
                        value: t.id,
                        child: Text(t.displayName ?? t.email),
                      )),
                    ],
                    onChanged: (v) => setState(() => _assignedTeacherId = v),
                    validator: null,
                  ),
                  const SizedBox(height: 16),
                  AppFormField(
                    label: 'Monthly Fee Amount (Optional)',
                    controller: _monthlyFeeController,
                    keyboardType: TextInputType.number,
                    hint: 'Default structure applies if empty',
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
          ),
          child: _isSubmitting
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(isEditing ? 'Save Changes' : 'Create Account'),
        ),
      ],
    );
  }
}
