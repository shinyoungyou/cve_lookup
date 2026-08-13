import 'package:flutter/material.dart';
import '../models/cve_model.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import '../widgets/cve_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();
  final DatabaseService _dbService = DatabaseService.instance;

  List<CveModel> _results = [];
  Set<String> _savedIds = {};
  bool _isLoading = false;
  bool _hasSearched = false;
  String? _errorMessage;

  String _selectedYear = '2025';
  String _selectedPeriod = 'Jan – Apr';

  final List<String> _years = [
    '2026', '2025', '2024', '2023', '2022',
    '2021', '2020', '2019', '2018', '2017',
  ];

  final Map<String, Map<String, String>> _periods = {
    'Jan – Apr': {'startMonth': '01-01', 'endMonth': '04-30'},
    'May – Aug': {'startMonth': '05-01', 'endMonth': '08-31'},
    'Sep – Dec': {'startMonth': '09-01', 'endMonth': '12-31'},
  };

  String get _pubStart =>
      '$_selectedYear-${_periods[_selectedPeriod]!['startMonth']}T00:00:00.000';

  String get _pubEnd =>
      '$_selectedYear-${_periods[_selectedPeriod]!['endMonth']}T23:59:59.000';

  @override
  void initState() {
    super.initState();
    _loadSavedIds();
  }

  Future<void> _loadSavedIds() async {
    final saved = await _dbService.getSavedCves();
    setState(() {
      _savedIds = saved.map((c) => c.id).toSet();
    });
  }

  Future<void> _search() async {
    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) return;

    _searchController.clear();

    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _errorMessage = null;
      _results = [];
    });

    try {
      final results = await _apiService.searchCves(
        keyword,
        pubStart: _pubStart,
        pubEnd: _pubEnd,
      );
      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to fetch results. Check your connection.';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleSave(CveModel cve) async {
    if (_savedIds.contains(cve.id)) {
      await _dbService.deleteCve(cve.id);
      setState(() => _savedIds.remove(cve.id));
      _showSnackbar('Removed from saved');
    } else {
      await _dbService.saveCve(cve);
      setState(() => _savedIds.add(cve.id));
      _showSnackbar('Saved successfully');
    }
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

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: Colors.blue.shade700),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_hasSearched && _results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No CVEs found.\nTry a different keyword or time period.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.manage_search, size: 64, color: Colors.blue.shade200),
            const SizedBox(height: 16),
            Text(
              'Search for a CVE by keyword.\nExample: log4j, openssl, apache',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _search,
      color: Colors.blue.shade700,
      child: ListView.builder(
        itemCount: _results.length,
        itemBuilder: (context, index) {
          final cve = _results[index];
          return CveCard(
            cve: cve,
            isSaved: _savedIds.contains(cve.id),
            onSaveToggle: () => _toggleSave(cve),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6FA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                icon: Icon(Icons.keyboard_arrow_down,
                    color: Colors.blue.shade700),
                style: TextStyle(
                  color: Colors.blue.shade900,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                items: items.map((item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      ],
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
          'CVE Search',
          style: TextStyle(
            color: Colors.blue.shade900,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar + dropdowns
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Column(
              children: [
                // Search bar row
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.black87),
                        decoration: InputDecoration(
                          hintText: 'Search CVEs... e.g. log4j',
                          hintStyle:
                          TextStyle(color: Colors.grey.shade400),
                          prefixIcon: Icon(Icons.search,
                              color: Colors.grey.shade400),
                          filled: true,
                          fillColor: const Color(0xFFF4F6FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) => _search(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _search,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Search',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Year dropdown
                _buildDropdown(
                  label: 'Year:',
                  value: _selectedYear,
                  items: _years,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedYear = value);
                    }
                  },
                ),

                const SizedBox(height: 8),

                // Period dropdown
                _buildDropdown(
                  label: 'Period:',
                  value: _selectedPeriod,
                  items: _periods.keys.toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedPeriod = value);
                    }
                  },
                ),
              ],
            ),
          ),

          // Results
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }
}