import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/resi.dart';
import '../services/api_service.dart';
import 'add_tracking.dart';
import 'login_page.dart';
import 'tracking_detail_page.dart';
import 'profile_page.dart';
import '../constants/courier_constants.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Resi> _resiList = [];
  bool _isLoading = true;
  late ApiService _apiService;
  List<Resi> _filteredResis = [];
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initApiService();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initApiService() async {
    final prefs = await SharedPreferences.getInstance();
    _apiService = ApiService(prefs);
    await _loadResis();
  }

  Future<void> _loadResis() async {
    try {
      final resis = await _apiService.getResis();
      if (mounted) {
        setState(() {
          _resiList = resis;
          _filteredResis = resis;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (e.toString().contains('Token is invalid')) {
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/login',
            (route) => false,
            arguments: 'Please login again.',
          );
        }
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
      _filteredResis = List.from(_resiList);
    });
  }

  void _handleSearch(String value) {
    setState(() {
      if (value.isEmpty) {
        _filteredResis = List.from(_resiList);
      } else {
        _filteredResis = _resiList.where((resi) {
          return resi.title.toLowerCase().contains(value.toLowerCase()) ||
              resi.noResi.toLowerCase().contains(value.toLowerCase()) ||
              (CourierConstants.courierNames[resi.courier] ?? resi.courier)
                  .toLowerCase()
                  .contains(value.toLowerCase());
        }).toList();
      }
    });
  }

  void _navigateToDetail(Resi resi) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrackingDetailPage(
          resi: resi,
          onResiUpdated: _loadResis,
        ),
      ),
    );
  }

  void _navigateToAddTracking() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddTrackingPage(),
      ),
    );
    if (result == true && mounted) {
      _loadResis();
    }
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProfilePage(),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Check if we need to refresh
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['refresh'] == true) {
      _loadResis(); // Refresh data
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        centerTitle: !_isSearching,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: 'Search by title, resi, or courier',
                  hintStyle: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onChanged: _handleSearch,
              )
            : Text(
                'My Shipments',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
        leading: _isSearching
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: colorScheme.primary,
                ),
                onPressed: _stopSearch,
              )
            : null,
        actions: [
          if (_isSearching && _searchController.text.isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.close,
                color: colorScheme.primary,
              ),
              onPressed: () {
                _searchController.clear();
                _handleSearch('');
              },
            )
          else if (!_isSearching)
            IconButton(
              icon: Icon(
                Icons.search,
                color: colorScheme.primary,
              ),
              onPressed: _startSearch,
            ),
          if (!_isSearching) ...[
            IconButton(
              icon: Icon(
                Icons.person_outline,
                color: colorScheme.primary,
              ),
              onPressed: _navigateToProfile,
            ),
          ],
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: colorScheme.primary,
              ),
            )
          : _filteredResis.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.local_shipping_outlined,
                        size: 80,
                        color: colorScheme.primary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No shipments yet',
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap + to add your first shipment',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: colorScheme.primary,
                  onRefresh: _loadResis,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredResis.length,
                    itemBuilder: (context, index) {
                      final resi = _filteredResis[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          elevation: 0,
                          color: colorScheme.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: colorScheme.outlineVariant,
                              width: 1,
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _navigateToDetail(resi),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colorScheme.primaryContainer,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          CourierConstants.courierNames[resi.courier] ?? resi.courier,
                                          style: TextStyle(
                                            color: colorScheme.onPrimaryContainer,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        DateFormat('dd MMM yyyy').format(resi.createdAt),
                                        style: TextStyle(
                                          color: colorScheme.onSurfaceVariant,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    resi.title,
                                    style: TextStyle(
                                      color: colorScheme.onSurface,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    resi.noResi,
                                    style: TextStyle(
                                      color: colorScheme.primary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddTracking,
        elevation: 2,
        backgroundColor: colorScheme.primaryContainer,
        child: Icon(
          Icons.add,
          color: colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
