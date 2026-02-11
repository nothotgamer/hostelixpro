import 'package:flutter/material.dart';
import 'package:hostelixpro/models/transaction.dart';
import 'package:hostelixpro/services/fee_service.dart';

import 'package:hostelixpro/theme/colors.dart';
import 'package:hostelixpro/theme/typography.dart';
import 'package:hostelixpro/widgets/layout/app_shell.dart';
import 'package:intl/intl.dart';

class FeeManagementPage extends StatefulWidget {
  const FeeManagementPage({super.key});

  @override
  State<FeeManagementPage> createState() => _FeeManagementPageState();
}

class _FeeManagementPageState extends State<FeeManagementPage> {
  bool _isLoading = true;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  int _selectedYear = DateTime.now().year;
  List<dynamic> _calendarData = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await FeeService.getFeeCalendar(year: _selectedYear, search: _searchQuery); // Pass search
      setState(() {
        _calendarData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll("Exception: ", "");
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Fee Management',
      actions: [
        // Search Bar
        Container(
          width: 250,
          margin: const EdgeInsets.only(right: 16, top: 4, bottom: 4),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search Name, Roll No...',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Colors.grey)),
              fillColor: Theme.of(context).colorScheme.surface,
              filled: true,
              suffixIcon: _searchController.text.isNotEmpty 
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 16), 
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                      _loadData();
                    }
                  ) 
                : null,
            ),
            onSubmitted: (val) {
               setState(() => _searchQuery = val);
               _loadData();
            },
          ),
        ),
        DropdownButton<int>(
          value: _selectedYear,
          dropdownColor: AppColors.surface,
          style: AppTypography.body,
          underline: Container(),
          icon: const Icon(Icons.arrow_drop_down),
          items: [2024, 2025, 2026].map((y) {
            return DropdownMenuItem(value: y, child: Text('$y'));
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedYear = val);
              _loadData();
            }
          },
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadData,
        ),
      ],
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error', style: TextStyle(color: AppColors.danger)))
              : LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 900) {
                      return _buildMobileView();
                    }
                    return _buildDesktopView();
                  },
                ),
    );
  }
// ... (rest of class)




  Widget _buildDesktopView() {
    return _buildResponsiveGrid();
  }

  Widget _buildMobileView() {
    return _buildResponsiveGrid();
  }

  Widget _buildResponsiveGrid() {
    if (_calendarData.isEmpty) {
      return const Center(child: Text("No data found"));
    }
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        
        // Determine number of columns based on width
        int columns;
        if (screenWidth >= 1400) {
          columns = 4;
        } else if (screenWidth >= 1000) {
          columns = 3;
        } else if (screenWidth >= 600) {
          columns = 2;
        } else {
          columns = 1; // Mobile - single column
        }
        
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  mainAxisExtent: 220, // Fixed height for all cards
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildCompactFeeCard(_calendarData[index]),
                  childCount: _calendarData.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCompactFeeCard(dynamic item) {
    final student = item['student'];
    final fees = item['fees'] as Map<String, dynamic>;
    final summary = item['summary'] as Map<String, dynamic>?;
    
    int paidCount = 0;
    fees.forEach((_, v) {
      if (v['status'] == 'APPROVED' || v['status'] == 'PAID') paidCount++;
    });
    
    final yearlyExpected = summary?['yearly_expected'] ?? 0.0;
    final yearlyPaid = summary?['yearly_paid'] ?? 0.0;
    final yearlyRemaining = summary?['yearly_remaining'] ?? 0.0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () => _showStudentDetails(student, fees, summary),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header - Name + Status Badge
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student['name'], 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "${student['admission_no']} • Room: ${student['room'] ?? '-'}",
                          style: AppTypography.caption,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: paidCount == 12 
                          ? AppColors.success.withValues(alpha: 0.15) 
                          : Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '$paidCount/12',
                      style: TextStyle(
                        color: paidCount == 12 ? AppColors.success : Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 10),
              
              // Financial Summary Row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Expected', '\$${yearlyExpected.toStringAsFixed(0)}', null),
                    Container(width: 1, height: 24, color: AppColors.border),
                    _buildStatItem('Paid', '\$${yearlyPaid.toStringAsFixed(0)}', AppColors.success),
                    Container(width: 1, height: 24, color: AppColors.border),
                    _buildStatItem('Due', '\$${yearlyRemaining.toStringAsFixed(0)}', 
                      yearlyRemaining > 0 ? AppColors.danger : AppColors.success),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Monthly badges row - all 12 months
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(12, (i) {
                  final monthData = fees[(i + 1).toString()];
                  return _buildMonthDot(i + 1, monthData);
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color? color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: color ?? AppColors.textSecondary)),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color)),
      ],
    );
  }

  Widget _buildMonthDot(int month, Map<String, dynamic>? data) {
    final status = data?['status'] ?? 'UNPAID';
    
    Color color;
    if (status == 'APPROVED' || status == 'PAID') {
      color = AppColors.success;
    } else if (status == 'PENDING_ADMIN' || status == 'PARTIAL') {
      color = AppColors.warning;
    } else {
      color = AppColors.danger;
    }
    
    return Tooltip(
      message: DateFormat('MMMM').format(DateTime(2024, month)),
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Center(
          child: Text(
            DateFormat('MMM').format(DateTime(2024, month)).substring(0, 1),
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
          ),
        ),
      ),
    );
  }

  // Keep original card for detail modal



  // ... _buildMiniStatus remains same ...

  void _showTransactionDialog(int feeId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => _TransactionList(
          feeId: feeId,
          scrollController: scrollController,
          onUpdate: () {
            Navigator.pop(context); // Close sheet
            _loadData(); // Reload main data
            // Re-open details if needed, but simple reload is enough for now
          },
        ),
      ),
    );
  }

  // ... _showStudentDetails updated to call _showTransactionDialog ...
  


  void _showStudentDetails(Map<String, dynamic> student, Map<String, dynamic> fees, Map<String, dynamic>? summary) {
    final yearlyExpected = summary?['yearly_expected'] ?? 0.0;
    final yearlyPaid = summary?['yearly_paid'] ?? 0.0;
    final yearlyRemaining = summary?['yearly_remaining'] ?? 0.0;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(student['name'], style: AppTypography.h3),
                        Text("Admission No: ${student['admission_no']} • Room: ${student['room'] ?? '-'}", style: AppTypography.bodySmall),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Yearly Summary
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text('Yearly Expected', style: AppTypography.caption),
                        Text('\$${yearlyExpected.toStringAsFixed(0)}', 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 40, color: AppColors.border),
                  Expanded(
                    child: Column(
                      children: [
                        Text('Total Paid', style: TextStyle(color: AppColors.success, fontSize: 12)),
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
            ),
            
            const SizedBox(height: 8),
            const Divider(),
            
            // Monthly Grid
            Expanded(
              child: GridView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.65,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  final month = index + 1;
                  final monthData = fees[month.toString()];
                  final status = monthData?['status'] ?? 'UNPAID';
                  final fId = monthData?['id'];
                  final expected = monthData?['expected_amount'] ?? 0.0;
                  final paid = monthData?['paid_amount'] ?? 0.0;
                  final remaining = monthData?['remaining_amount'] ?? expected;
                  
                   Color color = AppColors.danger.withValues(alpha: 0.1);
                   Color textColor = AppColors.danger;
                   String label = 'Unpaid';
                   IconData icon = Icons.close;
                    
                   if (status == 'APPROVED' || status == 'PAID') {
                     color = AppColors.success.withValues(alpha: 0.1);
                     textColor = AppColors.success;
                     label = 'Paid';
                     icon = Icons.check_circle;
                   } else if (status == 'PENDING_ADMIN') {
                     color = AppColors.warning.withValues(alpha: 0.1);
                     textColor = AppColors.warning;
                     label = 'Pending';
                     icon = Icons.access_time;
                   } else if (status == 'PARTIAL') {
                     color = AppColors.info.withValues(alpha: 0.1);
                     textColor = AppColors.info;
                     label = 'Partial';
                     icon = Icons.pie_chart;
                   }

                   return InkWell(
                     onTap: () {
                        if (fId != null) {
                           _showTransactionDialog(fId);
                        }
                     },
                     borderRadius: BorderRadius.circular(12),
                     child: Container(
                       padding: const EdgeInsets.all(8),
                       decoration: BoxDecoration(
                         color: color,
                         borderRadius: BorderRadius.circular(12),
                         border: Border.all(color: textColor.withValues(alpha: 0.3)),
                       ),
                       child: Column(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                           Text(
                             DateFormat('MMMM').format(DateTime(2024, month)),
                             style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                           ),
                           const SizedBox(height: 4),
                           Icon(icon, color: textColor, size: 24),
                           const SizedBox(height: 4),
                           Text(
                             label,
                             style: TextStyle(
                               color: textColor,
                               fontWeight: FontWeight.bold,
                               fontSize: 11
                             ),
                           ),
                           const Divider(height: 12),
                           Text('Exp: \$${expected.toStringAsFixed(0)}', style: AppTypography.caption),
                           Text('Paid: \$${paid.toStringAsFixed(0)}', 
                             style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w600)),
                           if (remaining > 0)
                             Text('Due: \$${remaining.toStringAsFixed(0)}', 
                               style: TextStyle(color: AppColors.danger, fontSize: 11, fontWeight: FontWeight.w600)),
                         ],
                       ),
                     ),
                   );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionList extends StatefulWidget {
  final int feeId;
  final ScrollController scrollController;
  final VoidCallback onUpdate;

  const _TransactionList({required this.feeId, required this.scrollController, required this.onUpdate});

  @override
  State<_TransactionList> createState() => _TransactionListState();
}

class _TransactionListState extends State<_TransactionList> {
  List<Transaction> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    try {
      final transactions = await FeeService.getTransactions(widget.feeId);
      // We might need to fetch fee details separately if not passed, but for now we calculate from transactions or assumes passed context.
      // Ideally we should pass Fee object, but to save refactor time, we can calculate 'paid' from approved transactions.
      
      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  void _viewProof(String path) {
     const String baseUrl = 'http://127.0.0.1:3000'; 
     final url = '$baseUrl$path';
     
     showDialog(
       context: context, 
       builder: (context) => Dialog(
         insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
         backgroundColor: Colors.transparent,
         elevation: 0,
         child: Stack(
           alignment: Alignment.center,
           children: [
             // Constrained Container for Image
             Container(
               constraints: const BoxConstraints(maxWidth: 900, maxHeight: 800),
               decoration: BoxDecoration(
                 color: Theme.of(context).colorScheme.surface,
                 borderRadius: BorderRadius.circular(16),
                 boxShadow: [
                   BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))
                 ],
               ),
               clipBehavior: Clip.hardEdge,
               child: Stack(
                children: [
                  InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Center(
                      child: Image.network(
                        url, 
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return SizedBox(
                            height: 300,
                            width: 300,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          padding: const EdgeInsets.all(40),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.broken_image_outlined, size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text("Could not load proof image", style: Theme.of(context).textTheme.bodyLarge),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Close Button (Inside the container, top-right)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.4),
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        customBorder: const CircleBorder(),
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(Icons.close, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ),
                ],
               ),
             ),
           ],
         ),
       )
     );
  }
  
  Future<void> _approve(int id) async {
    try {
      await FeeService.approveTransaction(id);
      await _loadTransactions(); // Reload to update status locally first
      widget.onUpdate();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _reject(int id) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Transaction'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Reason', border: OutlineInputBorder()),
          maxLines: 2,
        ),
        actions: [
           TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
           ElevatedButton(
             onPressed: () async {
               Navigator.pop(context);
               try {
                 await FeeService.rejectTransaction(id, controller.text);
                 await _loadTransactions();
                 widget.onUpdate();
               } catch (e) {
                 if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
               }
             }, 
             style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
             child: const Text('Reject')
           )
        ]
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    
    // Calculate Summary
    double totalPaid = 0;
    for (var t in _transactions) {
      if (t.status == 'APPROVED') totalPaid += (double.tryParse(t.amount.toString()) ?? 0);
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Transaction History", style: AppTypography.h3),
                    const SizedBox(height: 4),
                    Text("${_transactions.length} record(s)", style: AppTypography.bodySmall),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("Total Approved", style: AppTypography.caption),
                  Text(
                    "\$${totalPaid.toStringAsFixed(0)}", 
                    style: TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold, 
                      color: AppColors.success
                    )
                  ),
                ],
              )
            ],
          ),
        ),
        
        if (_transactions.isEmpty)
           Expanded(child: Center(child: Text("No transactions yet", style: AppTypography.body))),
           
        if (_transactions.isNotEmpty)
          Expanded(
            child: ListView.separated(
              controller: widget.scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _transactions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final trx = _transactions[index];
                
                Color statusColor = AppColors.textPrimary;
                IconData statusIcon = Icons.access_time;
                if (trx.status == 'APPROVED') { statusColor = AppColors.success; statusIcon = Icons.check_circle; }
                if (trx.status == 'PENDING') { statusColor = AppColors.warning; statusIcon = Icons.pending; }
                if (trx.status == 'REJECTED') { statusColor = AppColors.danger; statusIcon = Icons.cancel; }
                
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusIcon, color: statusColor, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  trx.status, 
                                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)
                                ),
                              ],
                            ),
                            if (trx.proofPath != null)
                              TextButton.icon(
                                icon: const Icon(Icons.image, size: 16),
                                label: const Text('View Proof', style: TextStyle(fontSize: 12)),
                                onPressed: () => _viewProof(trx.proofPath!),
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                ),
                              ),
                            Text(
                              DateFormat('dd MMM yyyy, HH:mm').format(trx.transactionDate),
                              style: AppTypography.caption
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Amount", style: AppTypography.caption),
                                  Text(
                                    "\$${trx.amount}", 
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Method", style: AppTypography.caption),
                                  Text(trx.paymentMethod, style: const TextStyle(fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                            if (trx.transactionReference != null)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Reference", style: AppTypography.caption),
                                    Text(trx.transactionReference!, style: const TextStyle(fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        
                        if (trx.status == 'PENDING') ...[
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => _reject(trx.id),
                                icon: const Icon(Icons.close, size: 16),
                                label: const Text("Reject"),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.danger,
                                  side: const BorderSide(color: AppColors.danger),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                onPressed: () => _approve(trx.id),
                                icon: const Icon(Icons.check, size: 16),
                                label: const Text("Approve"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                  foregroundColor: Colors.white,
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            ],
                          ),
                        ],
                        
                        if (trx.status == 'REJECTED' && trx.rejectionReason != null) ...[
                           const SizedBox(height: 12),
                           Container(
                             width: double.infinity,
                             padding: const EdgeInsets.all(8),
                             decoration: BoxDecoration(
                               color: AppColors.danger.withValues(alpha: 0.1),
                               borderRadius: BorderRadius.circular(8),
                             ),
                             child: Text("Reason: ${trx.rejectionReason}", style: TextStyle(color: AppColors.danger, fontSize: 12)),
                           ),
                        ]
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
