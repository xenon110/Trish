import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../core/auth_service.dart';

class DiscoveryFilterScreen extends StatefulWidget {
  const DiscoveryFilterScreen({super.key});

  @override
  State<DiscoveryFilterScreen> createState() => _DiscoveryFilterScreenState();
}

class _DiscoveryFilterScreenState extends State<DiscoveryFilterScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _auth = AuthService();
  
  Map<String, dynamic> _filters = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFilters();
  }

  void _loadFilters() {
    final meta = _auth.currentUser?.userMetadata ?? {};
    setState(() {
      _filters = Map<String, dynamic>.from(meta['discovery_filters'] ?? {
        'interested_in': 'Women',
        'min_age': 18,
        'max_age': 34,
        'distance_km': 139,
        'verified_only': false,
        'interests': [],
        'height_min': 140,
        'height_max': 210,
        'religion': null,
        'politics': null,
        'smoking': null,
        'drinking': null,
        'exercise': null,
        'zodiac': null,
        'education': null,
        'future_plans': null,
        'have_kids': null,
        'languages': [],
        'relationship_type': [],
      });
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final meta = Map<String, dynamic>.from(_auth.currentUser?.userMetadata ?? {});
      meta['discovery_filters'] = _filters;
      await _auth.updateProfile(meta);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Narrow your search', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 18)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryMaroon,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: 'Basic filters'),
            Tab(text: 'Advanced filters'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBasicTab(),
          _buildAdvancedTab(),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        child: ElevatedButton(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: _isSaving 
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Apply', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
        ),
      ),
    );
  }

  Widget _buildBasicTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _label('Who would you like to date?'),
        _selector(_filters['interested_in'] ?? 'Women', ['Women', 'Men', 'Everyone'], (v) => setState(() => _filters['interested_in'] = v)),
        
        const SizedBox(height: 30),
        _label('How old are they?'),
        Text('Between ${_filters['min_age']} and ${_filters['max_age']}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        RangeSlider(
          values: RangeValues((_filters['min_age'] as num).toDouble(), (_filters['max_age'] as num).toDouble()),
          min: 18, max: 80,
          activeColor: Colors.black,
          inactiveColor: Colors.grey[200],
          onChanged: (RangeValues values) {
            setState(() {
              _filters['min_age'] = values.start.round();
              _filters['max_age'] = values.end.round();
            });
          },
        ),

        const SizedBox(height: 30),
        _label('How far away are they?'),
        Text('Up to ${_filters['distance_km']} kilometres away', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        Slider(
          value: (_filters['distance_km'] as num).toDouble(),
          min: 1, max: 500,
          activeColor: Colors.black,
          inactiveColor: Colors.grey[200],
          onChanged: (v) => setState(() => _filters['distance_km'] = v.round()),
        ),

        const SizedBox(height: 30),
        _label('Do they share any of your interests?'),
        _multiChip(['Cricket', 'Bars', 'Beer', 'Creativity', 'Mindfulness', 'Music', 'Travel', 'Art', 'Gaming', 'Fitness'], _filters['interests'] ?? []),
      ],
    );
  }

  Widget _buildAdvancedTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _label('How tall are they?'),
        RangeSlider(
          values: RangeValues((_filters['height_min'] as num).toDouble(), (_filters['height_max'] as num).toDouble()),
          min: 100, max: 250,
          activeColor: Colors.black,
          onChanged: (v) => setState(() { _filters['height_min'] = v.start.round(); _filters['height_max'] = v.end.round(); }),
        ),

        _filterRow(Icons.search_rounded, 'What they looking for?', _filters['relationship_type'], ['Long-term', 'Something casual', 'Marriage', 'New friends'], isMulti: true),
        _filterRow(Icons.family_restroom_rounded, 'Family plans', _filters['future_plans'], ['Want children', 'Open to children', 'Not sure yet', 'Don’t want children']),
        _filterRow(Icons.child_friendly_rounded, 'Do they have kids?', _filters['have_kids'], ['Yes', 'No']),
        _filterRow(Icons.self_improvement_rounded, 'What’s their religion?', _filters['religion'], ['Agnostic', 'Atheist', 'Buddhist', 'Catholic', 'Christian', 'Hindu', 'Jewish', 'Muslim', 'Sikh', 'Spiritual', 'Other']),
        _filterRow(Icons.school_rounded, 'Education level', _filters['education'], ['Bachelors', 'Masters', 'PhD', 'High School', 'Trade School']),
        _filterRow(Icons.account_balance_rounded, 'Political views', _filters['politics'], ['Apolitical', 'Liberal', 'Moderate', 'Conservative', 'Other']),
        _filterRow(Icons.fitness_center_rounded, 'Do they exercise?', _filters['exercise'], ['Active', 'Sometimes', 'Rarely', 'Never']),
        _filterRow(Icons.smoke_free_rounded, 'Do they smoke?', _filters['smoking'], ['Non-smoker', 'Smoker', 'Social smoker']),
        _filterRow(Icons.wine_bar_rounded, 'Do they drink?', _filters['drinking'], ['Sober', 'Drink socially', 'Drink often']),
        _filterRow(Icons.stars_rounded, 'Star sign', _filters['zodiac'], ['Aries ♈', 'Taurus ♉', 'Gemini ♊', 'Cancer ♋', 'Leo ♌', 'Virgo ♍', 'Libra ♎', 'Scorpio ♏', 'Sagittarius ♐', 'Capricorn ♑', 'Aquarius ♒', 'Pisces ♓']),
        
        const SizedBox(height: 20),
        Row(
          children: [
            const Icon(Icons.verified_user_rounded, color: Colors.blue, size: 20),
            const SizedBox(width: 10),
            const Expanded(child: Text('Verified only', style: TextStyle(fontWeight: FontWeight.w700))),
            Switch(
              value: _filters['verified_only'] ?? false,
              onChanged: (v) => setState(() => _filters['verified_only'] = v),
              activeColor: AppTheme.primaryMaroon,
            ),
          ],
        ),
      ],
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF444444))),
    );
  }

  Widget _selector(String current, List<String> options, Function(String) onSelect) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: current,
          isExpanded: true,
          items: options.map((o) => DropdownMenuItem(value: o, child: Text(o, style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
          onChanged: (v) => onSelect(v!),
        ),
      ),
    );
  }

  Widget _multiChip(List<String> options, List current) {
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: options.map((o) {
        final sel = current.contains(o);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (sel) current.remove(o); else current.add(o);
              _filters['interests'] = current;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: sel ? Colors.black : Colors.white,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: sel ? Colors.black : Colors.grey[300]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(o, style: TextStyle(color: sel ? Colors.white : Colors.black, fontWeight: FontWeight.w600, fontSize: 13)),
                if (!sel) ...[const SizedBox(width: 4), const Icon(Icons.add, size: 14, color: Colors.grey)],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _filterRow(IconData icon, String title, dynamic current, List<String> options, {bool isMulti = false}) {
    String displayValue = 'Add this filter';
    if (isMulti && current is List && current.isNotEmpty) {
      displayValue = '${current.length} selected';
    } else if (!isMulti && current != null) {
      displayValue = current.toString();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF444444), fontSize: 15)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _showOptions(title, title.toLowerCase().replaceAll(' ', '_'), options, isMulti),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: Colors.black),
                  const SizedBox(width: 12),
                  Expanded(child: Text(displayValue, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black))),
                  const Icon(Icons.add, size: 20, color: Colors.black),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showOptions(String title, String key, List<String> options, bool isMulti) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setM) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 20),
              Flexible(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 10, runSpacing: 10,
                    children: options.map((o) {
                      bool sel = false;
                      if (isMulti) {
                        sel = (_filters[key] as List?)?.contains(o) ?? false;
                      } else {
                        sel = _filters[key] == o;
                      }
                      return GestureDetector(
                        onTap: () {
                          setM(() {
                            if (isMulti) {
                              final list = List<String>.from(_filters[key] ?? []);
                              if (sel) list.remove(o); else list.add(o);
                              setState(() => _filters[key] = list);
                            } else {
                              setState(() => _filters[key] = o);
                              Navigator.pop(ctx);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: sel ? AppTheme.primaryMaroon : Colors.white,
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(color: sel ? AppTheme.primaryMaroon : Colors.grey[300]!),
                          ),
                          child: Text(o, style: TextStyle(color: sel ? Colors.white : Colors.black, fontWeight: FontWeight.w600)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              if (isMulti) ...[
                const SizedBox(height: 20),
                SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done'))),
              ]
            ],
          ),
        );
      }),
    );
  }
}
