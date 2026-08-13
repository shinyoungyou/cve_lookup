import 'package:flutter/material.dart';
import '../models/cve_model.dart';
import '../services/database_service.dart';
import '../widgets/cve_card.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  final DatabaseService _dbService = DatabaseService.instance;

  List<CveModel> _savedCves = [];
  String _selectedFilter = 'ALL';
  bool _isLoading = true;

  final List<String> _filters = ['ALL', 'CRITICAL', 'HIGH', 'MEDIUM', 'LOW'];

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    setState(() => _isLoading = true);
    final saved = await _dbService.getSavedCves();
    setState(() {
      _savedCves = saved;
      _isLoading = false;
    });
  }

  Future<void> _deleteCve(CveModel cve) async {
    await _dbService.deleteCve(cve.id);
    _showSnackbar('Removed from saved');
    _loadSaved();
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<CveModel> get _filteredCves {
    if (_selectedFilter == 'ALL') return _savedCves;
    return _savedCves
        .where((c) => c.severity?.toUpperCase() == _selectedFilter)
        .toList();
  }

  Widget _buildFilterChips() {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: _filters.map((filter) {
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.blueGrey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                selected: isSelected,
                onSelected: (_) {
                  setState(() => _selectedFilter = filter);
                },
                backgroundColor: const Color(0xFFF4F6FA),
                selectedColor: Colors.blue.shade700,
                checkmarkColor: Colors.white,
                side: BorderSide.none,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: Colors.blue.shade700),
      );
    }

    if (_savedCves.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No saved CVEs yet.\nBookmark CVEs from the Search tab.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_filteredCves.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.filter_list_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No CVEs match this filter.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSaved,
      color: Colors.blue.shade700,
      child: ListView.builder(
        itemCount: _filteredCves.length,
        itemBuilder: (context, index) {
          final cve = _filteredCves[index];
          return CveCard(
            cve: cve,
            isSaved: true,
            onSaveToggle: () => _deleteCve(cve),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          'Saved CVEs',
          style: TextStyle(
            color: Colors.blue.shade900,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                '${_savedCves.length} saved',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }
}