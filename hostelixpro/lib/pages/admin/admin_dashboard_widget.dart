import 'package:flutter/material.dart';
import 'package:hostelixpro/models/fee.dart';
import 'package:hostelixpro/services/fee_service.dart';
import 'package:hostelixpro/services/user_service.dart';
import 'package:hostelixpro/theme/colors.dart';
import 'package:hostelixpro/theme/typography.dart';
import 'package:intl/intl.dart';

class AdminDashboardWidget extends StatefulWidget {
  const AdminDashboardWidget({super.key});

  @override
  State<AdminDashboardWidget> createState() => _AdminDashboardWidgetState();
}

class _AdminDashboardWidgetState extends State<AdminDashboardWidget> {
  List<Fee> _pendingFees = [];
  bool _isLoading = true;
  int _totalStudents = 0;
  int _pendingApprovals = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        FeeService.getFees(status: 'PENDING_ADMIN'),
        UserService.getUsers(role: 'STUDENT'),
        UserService.getUsers(role: 'STUDENT', isApproved: false),
      ]);
      
      if (mounted) {
        setState(() {
          _pendingFees = results[0] as List<Fee>;
          _totalStudents = (results[1] as List).length;
          _pendingApprovals = (results[2] as List).length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _approveFee(int feeId) async {
    // Optimistic removal — store original list for rollback
    final originalFees = List<Fee>.from(_pendingFees);
    setState(() {
      _pendingFees.removeWhere((f) => f.id == feeId);
    });

    try {
      final transactions = await FeeService.getTransactions(feeId);
      final pending = transactions.where((t) => t.status == 'PENDING');
      
      if (pending.isEmpty) {
        // Restore if nothing to approve
        if (mounted) {
          setState(() => _pendingFees = originalFees);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No pending transactions found')),
          );
        }
        return;
      }

      for (final t in pending) {
        await FeeService.approveTransaction(t.id);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${pending.length} transaction(s) approved ✓'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadDashboardData();
      }
    } catch (e) {
      // Rollback on failure
      if (mounted) {
        setState(() => _pendingFees = originalFees);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _rejectFee(int feeId) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Payment'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Reason for rejection',
            hintText: 'Explain why this payment is being rejected',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    // Optimistic removal
    final originalFees = List<Fee>.from(_pendingFees);
    setState(() {
      _pendingFees.removeWhere((f) => f.id == feeId);
    });
    
    try {
      final transactions = await FeeService.getTransactions(feeId);
      final pending = transactions.where((t) => t.status == 'PENDING');
      
      for (final t in pending) {
        await FeeService.rejectTransaction(t.id, controller.text.trim());
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment rejected'),
            backgroundColor: AppColors.warning,
          ),
        );
        _loadDashboardData();
      }
    } catch (e) {
      // Rollback on failure
      if (mounted) {
        setState(() => _pendingFees = originalFees);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _viewProof(String? path) {
    if (path == null) return;
    
    const String baseUrl = 'http://127.0.0.1:3000';
    final url = '$baseUrl$path';
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 500),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.hardEdge,
          child: Stack(
            children: [
              InteractiveViewer(
                child: Center(
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stack) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.broken_image_outlined, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text("Could not load image", style: Theme.of(context).textTheme.bodyLarge),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.black54,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    customBorder: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.close, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildStatCard(
                    icon: Icons.people,
                    label: 'Total Students',
                    value: _totalStudents.toString(),
                    color: colors.primary,
                    width: isMobile ? constraints.maxWidth : 200,
                  ),
                  _buildStatCard(
                    icon: Icons.pending_actions,
                    label: 'Pending Approvals',
                    value: _pendingApprovals.toString(),
                    color: AppColors.warning,
                    width: isMobile ? constraints.maxWidth : 200,
                  ),
                  _buildStatCard(
                    icon: Icons.payment,
                    label: 'Pending Fees',
                    value: _pendingFees.length.toString(),
                    color: AppColors.info,
                    width: isMobile ? constraints.maxWidth : 200,
                  ),
                ],
              );
            },
          ),
          
          const SizedBox(height: 24),
          
          // Pending Fee Approvals Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Pending Fee Approvals', style: AppTypography.h3),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadDashboardData,
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Fee Approval Cards
          _pendingFees.isEmpty
            ? Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: isDark ? colors.surfaceContainerHigh : colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.check_circle_outline, size: 48, color: AppColors.success),
                      const SizedBox(height: 8),
                      Text('No pending fees', style: TextStyle(color: colors.onSurfaceVariant)),
                    ],
                  ),
                ),
              )
            : _buildFeesList(),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required double width,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value, style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                )),
                Text(label, style: TextStyle(
                  fontSize: 11,
                  color: colors.onSurfaceVariant,
                ), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeesList() {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const baseUrl = 'http://127.0.0.1:3000'; // Base URL for images
    
    return Column(
      children: _pendingFees.map((fee) {
        final date = DateFormat('MMM yyyy').format(DateTime(fee.year, fee.month));
        final studentName = fee.studentName ?? 'Student #${fee.studentId}';
        final admissionNo = fee.studentAdmissionNo ?? 'N/A';
        final room = fee.studentRoom ?? 'N/A';
        final pendingAmount = fee.pendingAmount ?? (fee.expectedAmount ?? 0);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? colors.surfaceContainerHigh : colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Student Details
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Image
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.outlineVariant, width: 2),
                      image: fee.studentImage != null
                          ? DecorationImage(
                              image: NetworkImage('$baseUrl${fee.studentImage}'),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: fee.studentImage == null
                        ? Center(
                            child: Text(
                              studentName.isNotEmpty ? studentName[0].toUpperCase() : 'S',
                              style: TextStyle(
                                  color: colors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  
                  // Name and Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(studentName, style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: colors.onSurface,
                        )),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildInfoBadge(Icons.badge_outlined, admissionNo, colors),
                            const SizedBox(width: 8),
                            _buildInfoBadge(Icons.meeting_room_outlined, room, colors),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Date Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(date, style: TextStyle(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    )),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              
              // Financial & Proof Section
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pending Amount (Primary Focus)
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PENDING AMOUNT', style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: colors.onSurfaceVariant,
                        )),
                        const SizedBox(height: 4),
                        Text('\$${pendingAmount.toStringAsFixed(0)}', style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        )),
                        const SizedBox(height: 4),
                        Text(
                          'of \$${(fee.expectedAmount ?? 0).toStringAsFixed(0)} expected',
                          style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),

                  // Proofs
                  if (fee.pendingProofs != null && fee.pendingProofs!.isNotEmpty)
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('PAYMENT PROOF', style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: colors.onSurfaceVariant,
                          )),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: fee.pendingProofs!.map((path) => 
                              GestureDetector(
                                onTap: () => _viewProof(path),
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: colors.outlineVariant),
                                    image: DecorationImage(
                                      image: NetworkImage('$baseUrl$path'),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              )
                            ).toList(),
                          ),
                        ],
                      ),
                    )
                  else if (fee.proofPath != null)
                     // Legacy proof support
                    ElevatedButton.icon(
                      onPressed: () => _viewProof(fee.proofPath),
                      icon: const Icon(Icons.receipt_long, size: 18),
                      label: const Text('View Proof'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.surfaceContainerHighest,
                        foregroundColor: colors.onSurface,
                        elevation: 0,
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectFee(fee.id),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveFee(fee.id),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInfoBadge(IconData icon, String label, ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colors.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(
            fontSize: 12,
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          )),
        ],
      ),
    );
  }
}
