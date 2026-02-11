import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hostelixpro/providers/sidebar_provider.dart';
import 'package:hostelixpro/widgets/layout/app_header.dart';
import 'package:hostelixpro/widgets/layout/app_sidebar.dart';

class AppShell extends StatefulWidget {
  final Widget child;
  final String? title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const AppShell({
    super.key,
    required this.child,
    this.title,
    this.actions,
    this.floatingActionButton,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    final backgroundColor = Theme.of(context).colorScheme.surfaceContainerLowest;

    // MOBILE: Use Drawer pattern
    if (isMobile) {
      return Scaffold(
        key: _scaffoldKey,
        backgroundColor: backgroundColor,
        appBar: AppHeader(
          onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
          title: widget.title,
          actions: widget.actions,
        ), 
        drawer: Drawer(
          width: AppSidebar.expandedWidth,
          child: AppSidebar(isCollapsed: false, onToggle: () => Navigator.pop(context)),
        ),
        floatingActionButton: widget.floatingActionButton,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: widget.child,
          ),
        ),
      );
    }

    // DESKTOP: Use Row with Sidebar (Push Layout)
    return Consumer<SidebarProvider>(
      builder: (context, sidebarProvider, _) {
        return Scaffold(
          backgroundColor: backgroundColor,
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sidebar - takes its own space, pushes content
              AppSidebar(
                isCollapsed: sidebarProvider.isCollapsed,
                onToggle: sidebarProvider.toggle,
              ),
              
              // Main Content Area - takes remaining space
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppHeader(
                      title: widget.title,
                      actions: widget.actions,
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        alignment: Alignment.topLeft,
                        child: widget.child,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
