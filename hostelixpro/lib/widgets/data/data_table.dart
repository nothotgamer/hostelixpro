import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Professional Data Table with modern styling
class AppDataTable extends StatefulWidget {
  final List<DataColumn> columns;
  final List<DataRow> rows;
  final bool isLoading;

  const AppDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.isLoading = false,
  });

  @override
  State<AppDataTable> createState() => _AppDataTableState();
}

class _AppDataTableState extends State<AppDataTable> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Loading indicator
          if (widget.isLoading)
            LinearProgressIndicator(
              minHeight: 3,
              backgroundColor: colors.surfaceContainerHighest,
              color: colors.primary,
            ),
          
          // Table with 2D scroll
          Flexible(
            child: Scrollbar(
              controller: _verticalController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _verticalController,
                scrollDirection: Axis.vertical,
                child: Scrollbar(
                  controller: _horizontalController,
                  thumbVisibility: true,
                  notificationPredicate: (notif) => notif.depth == 1, // Differentiate vertical/horizontal? Or just rely on direction
                  child: SingleChildScrollView(
                    controller: _horizontalController,
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: math.max(0.0, MediaQuery.of(context).size.width - 350), // Account for sidebar
                        minHeight: 300, // Minimum height to avoid collapse
                      ),
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(colors.surfaceContainerHigh),
                        headingTextStyle: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: colors.onSurface,
                        ),
                        dataTextStyle: TextStyle(
                          fontSize: 14,
                          color: colors.onSurfaceVariant,
                        ),
                        horizontalMargin: 20,
                        columnSpacing: 32,
                        dataRowMinHeight: 52,
                        dataRowMaxHeight: 64,
                        dividerThickness: 1,
                        columns: widget.columns,
                        rows: widget.rows,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Empty state
          if (widget.rows.isEmpty && !widget.isLoading)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.inbox_outlined, size: 40, color: colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Data Found',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: colors.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'There are no records to display.',
                    style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
