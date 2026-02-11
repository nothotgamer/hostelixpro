import 'package:flutter/material.dart';
import 'package:hostelixpro/models/fee.dart';
import 'package:hostelixpro/models/transaction.dart';
import 'package:hostelixpro/services/fee_service.dart';
import 'package:hostelixpro/services/file_service.dart';
import 'package:hostelixpro/theme/colors.dart';
import 'package:hostelixpro/theme/typography.dart';
import 'package:hostelixpro/widgets/common/status_badge.dart';
import 'package:hostelixpro/widgets/forms/form_field.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:hostelixpro/widgets/layout/app_shell.dart';
import 'package:intl/intl.dart';

class FeePage extends StatefulWidget {
  const FeePage({super.key});

  @override
  State<FeePage> createState() => _FeePageState();
}

class _FeePageState extends State<FeePage> {
  List<Fee> _fees = [];
  bool _isLoading = true;
  String? _error;
  List<dynamic> _feeCalendar = [];
  
  // Submit Form state
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  File? _proofFile;


  final _scrollController = ScrollController(); // Added controller

  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  @override
  void dispose() {
    _amountController.dispose();
    _scrollController.dispose(); // Dispose controller
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get Fees for current student
      final fees = await FeeService.getFees();
      final calendar = await FeeService.getFeeCalendar(year: DateTime.now().year);
      
      setState(() {
        _fees = fees;
        _feeCalendar = calendar;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll("Exception: ", "");
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickProof() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );
      if (result != null && result.files.single.path != null) {
        setState(() => _proofFile = File(result.files.single.path!));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
      }
    }
  }

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Validate if month already paid
    bool isPaid = false;
    if (_feeCalendar.isNotEmpty) {
       try {
         final data = _feeCalendar.first as Map<String, dynamic>;
         final fees = data['fees']; // Should be Map<String, dynamic> but coming from JSON
         final monthKey = _selectedMonth.toString();
         
         if (fees != null && fees is Map && fees.containsKey(monthKey)) {
           final mData = fees[monthKey];
           final status = mData['status'];
           final remaining = (mData['remaining_amount'] ?? 0);
           
           if ((status == 'PAID' || status == 'APPROVED') && remaining <= 0) {
              isPaid = true;
           }
         }
       } catch (e) {
         // Ignore parsing error, proceed
       }
    }
    
    if (isPaid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This month is already fully paid'), backgroundColor: AppColors.warning),
        );
      }
      return;
    }
    
    if (_proofFile == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please upload a proof of payment'), backgroundColor: AppColors.warning),
        );
      }
      return;
    }
    
    try {
      await FeeService.addTransaction(
        month: _selectedMonth,
        year: _selectedYear,
        amount: _amountController.text,
        proofFile: _proofFile,
        paymentMethod: 'manual',
      );
      
      if (mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment submitted successfully')),
        );
        _loadData(); // Reload to show updated status/balance
        _amountController.clear();
        setState(() => _proofFile = null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return AppShell(
      title: 'Fee Management',
      actions: [
        if (isDesktop)
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: FilledButton.icon(
              onPressed: () => _showPayModal(),
              icon: const Icon(Icons.add),
              label: const Text('New Payment'),
            ),
          ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadData,
        ),
      ],
      floatingActionButton: !isDesktop ? FloatingActionButton.extended(
        onPressed: () => _showPayModal(),
        label: const Text('New Payment'),
        icon: const Icon(Icons.payments),
      ) : null,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error', style: TextStyle(color: AppColors.danger)))
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: RefreshIndicator(
                      onRefresh: _loadData,
                      child: Scrollbar( // Explicit Scrollbar
                        controller: _scrollController,
                        thumbVisibility: isDesktop, // Always show on desktop
                        child: ListView(
                          controller: _scrollController, // Explicit controller
                          padding: const EdgeInsets.only(bottom: 80, left: 16, right: 16, top: 16),
                          physics: const AlwaysScrollableScrollPhysics(), // Ensure scrollable even if content is short
                          children: [
                            // Fee Stats / Calendar
                            _buildFeeStats(),
                            const SizedBox(height: 24),
                            
                            Text('Payment History', style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 12),
                            
                            if (_fees.isEmpty)
                               Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32.0),
                                  child: Text('No payment history found', style: Theme.of(context).textTheme.bodyLarge),
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _fees.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 12),
                                itemBuilder: (context, index) => _buildFeeCard(_fees[index]),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }
  
  Widget _buildFeeStats() {
    // Extract summary from calendar (student view returns single item with summary)
    Map<String, dynamic>? summary;
    if (_feeCalendar.isNotEmpty && _feeCalendar.first is Map) {
      summary = (_feeCalendar.first as Map<String, dynamic>)['summary'];
    }
    
    final yearlyExpected = (summary?['yearly_expected'] ?? 0.0).toDouble();
    final yearlyPaid = (summary?['yearly_paid'] ?? 0.0).toDouble();
    final yearlyRemaining = (summary?['yearly_remaining'] ?? 0.0).toDouble();
    final progress = yearlyExpected > 0 ? (yearlyPaid / yearlyExpected).clamp(0.0, 1.0) : 0.0;
    
    // Count paid/pending months
    Map<String, dynamic>? fees;
    if (_feeCalendar.isNotEmpty && _feeCalendar.first is Map) {
      fees = (_feeCalendar.first as Map<String, dynamic>)['fees'];
    }
    int paidMonths = 0;
    int pendingMonths = 0;
    fees?.forEach((_, v) {
      if (v['status'] == 'APPROVED' || v['status'] == 'PAID') paidMonths++;
      if (v['status'] == 'PENDING_ADMIN' || v['status'] == 'PARTIAL') pendingMonths++;
    });
    
    return Column(
      children: [
        // Yearly Summary Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primaryContainer,
                Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${DateTime.now().year} Fee Summary', 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('$paidMonths/12 Months Paid', 
                    style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text('Expected', style: AppTypography.caption),
                        Text('\$${yearlyExpected.toStringAsFixed(0)}', 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 40, color: AppColors.border),
                  Expanded(
                    child: Column(
                      children: [
                        Text('Paid', style: TextStyle(color: AppColors.success, fontSize: 12)),
                        Text('\$${yearlyPaid.toStringAsFixed(0)}', 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.success)),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 40, color: AppColors.border),
                  Expanded(
                    child: Column(
                      children: [
                        Text('Remaining', style: TextStyle(color: yearlyRemaining > 0 ? AppColors.danger : AppColors.success, fontSize: 12)),
                        Text('\$${yearlyRemaining.toStringAsFixed(0)}', 
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: yearlyRemaining > 0 ? AppColors.danger : AppColors.success)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  color: progress >= 1.0 ? AppColors.success : AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text('${(progress * 100).toStringAsFixed(0)}% of yearly fees paid', 
                style: AppTypography.caption),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Quick Stats Row
        Row(
          children: [
            Expanded(
              child: _buildStatCard('Paid', '$paidMonths', Icons.check_circle, AppColors.success),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard('Pending', '$pendingMonths', Icons.pending, AppColors.warning),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  void _showPayModal({Fee? fee}) {
    // If paying for existing fee record, pre-fill
    if (fee != null) {
      _selectedMonth = fee.month;
      _selectedYear = fee.year;
      
      // Calculate remaining amount
      double remaining = (fee.expectedAmount ?? 0) - (fee.paidAmount ?? 0);
      if (remaining < 0) remaining = 0;
      _amountController.text = remaining.toStringAsFixed(2);
    } else {
      _selectedMonth = DateTime.now().month;
      _selectedYear = DateTime.now().year;
      _amountController.clear();
    }
    
    // Reset state
    _proofFile = null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  fee != null ? 'Pay Balance' : 'New Payment', 
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold
                  )
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  if (fee == null)
                    Row(
                      children: [
                         Expanded(
                           child: DropdownButtonFormField<int>(
                             initialValue: _selectedMonth,
                             decoration: const InputDecoration(
                               labelText: 'Month',
                               border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                               filled: true,
                              ),
                              items: List.generate(12, (i) => i + 1).map((m) {
                                return DropdownMenuItem(
                                  value: m,
                                  child: Text(DateFormat('MMMM').format(DateTime(2024, m))),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => _selectedMonth = val!),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              initialValue: _selectedYear,
                              decoration: const InputDecoration(
                                labelText: 'Year',
                                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                                filled: true,
                              ),
                              items: [2024, 2025, 2026].map((y) {
                                return DropdownMenuItem(value: y, child: Text('$y'));
                              }).toList(),
                              onChanged: (val) => setState(() => _selectedYear = val!),
                            ),
                          ),
                      ],
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, size: 24, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Payment For',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                DateFormat('MMMM yyyy').format(DateTime(fee.year, fee.month)),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 20),
                  
                  AppFormField(
                    label: 'Amount (PKR)',
                    controller: _amountController,
                    prefixIcon: const Icon(Icons.attach_money),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    readOnly: false, // Explicitly allow editing
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Required';
                      final amount = double.tryParse(val);
                      if (amount == null || amount <= 0) return 'Invalid amount';
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),
                  
                  // Reference Number (Optional)
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Reference / Transaction ID (Optional)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      prefixIcon: Icon(Icons.receipt_long),
                      filled: true,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  InkWell(
                    onTap: _pickProof,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _proofFile != null ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline,
                          style: BorderStyle.solid,
                          width: _proofFile != null ? 1.5 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: _proofFile != null ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1) : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _proofFile != null ? Icons.check_circle : Icons.cloud_upload_outlined, 
                            color: Theme.of(context).colorScheme.primary
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              _proofFile != null 
                                ? 'Selected: ${_proofFile!.path.split(Platform.pathSeparator).last}' 
                                : 'Upload Payment Proof (Image)',
                              style: TextStyle(
                                color: _proofFile != null 
                                  ? Theme.of(context).colorScheme.primary 
                                  : Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w600
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _submitPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Submit Payment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  
  Widget _buildFeeCard(Fee fee) {
    final date = DateFormat('MMMM yyyy').format(DateTime(fee.year, fee.month));
    final expected = fee.expectedAmount ?? 0;
    final paid = fee.paidAmount ?? 0;
    final remaining = expected - paid;
    final progress = expected > 0 ? (paid / expected).clamp(0.0, 1.0) : 0.0;
    
    StatusType statusType = StatusType.pending;
    if (fee.status == 'PAID' || fee.status == 'APPROVED') statusType = StatusType.approved;
    if (fee.status == 'REJECTED') statusType = StatusType.rejected;
    // Handle partial payment (backend now uses PENDING_ADMIN for this to satisfy DB constraint)
    if (fee.status == 'PENDING_ADMIN' && paid > 0 && paid < expected) statusType = StatusType.warning;

    String statusLabel = fee.status.replaceAll('_', ' ');
    if (statusType == StatusType.warning && fee.status == 'PENDING_ADMIN') {
      statusLabel = 'PARTIAL PAYMENT';
    }

    return Card(
      elevation: 0,
       shape: RoundedRectangleBorder(
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          initiallyExpanded: false,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(date, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 4),
                      Text('Fee ID: #${fee.id}', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  StatusBadge(label: statusLabel, type: statusType),
                ],
              ),
              const SizedBox(height: 16),
              
              // Stats Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
                        Text('\$${expected.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Paid', style: TextStyle(color: AppColors.success, fontSize: 12)),
                        Text('\$${paid.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.success)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Balance', style: TextStyle(color: AppColors.danger, fontSize: 12)),
                        Text('\$${remaining.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: remaining > 0 ? AppColors.danger : AppColors.textPrimary)),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                color: progress >= 1.0 ? AppColors.success : AppColors.primary,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            ],
          ),
          children: [
            // Transactions List
            FutureBuilder<List<Transaction>>(
              future: FeeService.getTransactions(fee.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                }
                
                final transactions = snapshot.data ?? [];
                
                if (transactions.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('No transactions yet', style: AppTypography.caption),
                  );
                }
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Transactions (${transactions.length})', 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 12),
                    ...transactions.map((t) {
                      Color statusColor = AppColors.warning;
                      IconData statusIcon = Icons.access_time;
                      if (t.status == 'APPROVED') {
                        statusColor = AppColors.success;
                        statusIcon = Icons.check_circle;
                      } else if (t.status == 'REJECTED') {
                        statusColor = AppColors.danger;
                        statusIcon = Icons.cancel;
                      }
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: statusColor.withValues(alpha: 0.1),
                              radius: 16,
                              child: Icon(statusIcon, color: statusColor, size: 16),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('\$${t.amount.toStringAsFixed(0)}', 
                                        style: const TextStyle(fontWeight: FontWeight.bold)),
                                      Text(t.status, 
                                        style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 12)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('MMM dd, yyyy • hh:mm a').format(t.transactionDate),
                                    style: AppTypography.caption,
                                  ),
                                  if (t.rejectionReason != null && t.rejectionReason!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text('Reason: ${t.rejectionReason}', 
                                        style: TextStyle(color: AppColors.danger, fontSize: 11)),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    
                    const SizedBox(height: 12),
                    
                    // Action Buttons
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 600;
                        return Row(
                          children: [
                            if (remaining > 0 && statusType != StatusType.pending)
                              Expanded(
                                flex: isWide ? 0 : 1,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(minWidth: isWide ? 150 : 0),
                                  child: ElevatedButton(
                                    onPressed: () => _showPayModal(fee: fee),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: const Text('Pay Now'),
                                  ),
                                ),
                              ),
                            if (remaining > 0 && statusType != StatusType.pending)
                              const SizedBox(width: 12),
                            if (fee.status == 'PAID' || fee.status == 'APPROVED')
                              Expanded(
                                flex: isWide ? 0 : 1,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(minWidth: isWide ? 150 : 0),
                                  child: OutlinedButton.icon(
                                    onPressed: () => FileService.downloadAndOpen(
                                      context, 
                                      '/fees/${fee.id}/challan', 
                                      'challan_${fee.id}.pdf'
                                    ),
                                    icon: const Icon(Icons.download, size: 18),
                                    label: const Text('Receipt'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                                    ),
                                  ),
                                ),
                              ),
                             if (isWide) const Spacer(),
                          ],
                        );
                      }
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
