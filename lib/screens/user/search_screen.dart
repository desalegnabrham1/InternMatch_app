import 'package:flutter/material.dart';
import '../../models/internship_model.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/internship_card.dart';
import '../../widgets/loading_widget.dart' as lw;
import 'internship_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _firestoreService = FirestoreService();
  final _searchController = TextEditingController();

  List<InternshipModel> _results = [];
  List<String> _availableLocations = [];
  String? _selectedLocation;
  bool _loading = false;
  bool _hasSearched = false;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _loadLocations();
    _search('');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLocations() async {
    try {
      final locs = await _firestoreService.getDistinctLocations();
      if (mounted) setState(() => _availableLocations = locs);
    } catch (_) {}
  }

  Future<void> _search(String query) async {
    setState(() {
      _loading = true;
      _hasSearched = true;
    });
    try {
      final results = await _firestoreService.searchInternships(
        query,
        locationFilter: _selectedLocation,
      );
      if (mounted) {
        setState(() {
          _results = results;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _clearFilters() {
    setState(() => _selectedLocation = null);
    _search(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveFilter = _selectedLocation != null;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Internships'),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: hasActiveFilter,
              label: const Text('1'),
              child: const Icon(Icons.filter_list),
            ),
            tooltip: 'Filters',
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
          if (hasActiveFilter)
            IconButton(
              icon: const Icon(Icons.filter_list_off),
              tooltip: 'Clear filters',
              onPressed: _clearFilters,
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: Theme.of(context).cardColor,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextFormField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by title, company, or location...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _search('');
                        },
                      )
                    : null,
              ),
              onChanged: (v) {
                setState(() {});
                _search(v);
              },
              textInputAction: TextInputAction.search,
              onFieldSubmitted: _search,
            ),
          ),

          // Filter panel
          if (_showFilters) ...[
            Container(
              color: Theme.of(context).cardColor,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Text('Filter by Location',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (_availableLocations.isEmpty)
                    Text('No locations available',
                        style: Theme.of(context).textTheme.bodyMedium)
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _availableLocations.map((loc) {
                        final selected = _selectedLocation == loc;
                        return FilterChip(
                          label: Text(loc),
                          selected: selected,
                          selectedColor: AppTheme.primary.withValues(alpha: 0.5),
                          checkmarkColor: AppTheme.primary,
                          labelStyle: TextStyle(
                            color: selected
                                ? AppTheme.primary
                                : AppTheme.textSecondary,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.normal,
                          ),
                          onSelected: (val) {
                            setState(() {
                              _selectedLocation = val ? loc : null;
                            });
                            _search(_searchController.text);
                          },
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ],

          const Divider(height: 1),

          // Active filter indicator
          if (hasActiveFilter)
            Container(
              width: double.infinity,
              color: AppTheme.primary.withValues(alpha: 0.5),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.filter_alt_outlined,
                      size: 14, color: AppTheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Location: $_selectedLocation',
                    style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _clearFilters,
                    child: const Icon(Icons.close,
                        size: 16, color: AppTheme.primary),
                  ),
                ],
              ),
            ),

          // Results count
          if (_hasSearched && !_loading)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  Text(
                    '${_results.length} result${_results.length == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (_searchController.text.isNotEmpty) ...[
                    Text(' for "',
                        style: Theme.of(context).textTheme.bodyMedium),
                    Text(_searchController.text,
                        style: const TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                    Text('"', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ],
              ),
            ),

          // Results
          Expanded(
            child: _loading
                ? const lw.LoadingWidget(message: 'Searching...')
                : _results.isEmpty && _hasSearched
                    ? lw.EmptyStateWidget(
                        title: 'No results found',
                        subtitle:
                            _searchController.text.isEmpty && !hasActiveFilter
                                ? 'No internships available.'
                                : 'Try different keywords or clear filters.',
                        icon: Icons.search_off,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 24),
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final item = _results[index];
                          return InternshipCard(
                            internship: item,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    InternshipDetailScreen(internship: item),
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

