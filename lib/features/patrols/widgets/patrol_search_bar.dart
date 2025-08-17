import 'package:flutter/material.dart';

/// Search bar widget for filtering patrols
class PatrolSearchBar extends StatefulWidget {
  final Function(String) onSearch;
  final String selectedStatus;
  final Function(String) onStatusChanged;

  const PatrolSearchBar({
    super.key,
    required this.onSearch,
    required this.selectedStatus,
    required this.onStatusChanged,
  });

  @override
  State<PatrolSearchBar> createState() => _PatrolSearchBarState();
}

class _PatrolSearchBarState extends State<PatrolSearchBar> {
  final TextEditingController _searchController = TextEditingController();
  bool _isExpanded = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        children: [
          // Search field and filter button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search patrols...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              widget.onSearch('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Theme.of(context).primaryColor),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: widget.onSearch,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Theme.of(context).primaryColor,
                ),
                onPressed: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                ),
              ),
            ],
          ),
          
          // Expandable filters
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter by Status',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  _buildStatusChips(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChips() {
    final statuses = [
      {'value': 'all', 'label': 'All', 'color': Colors.grey},
      {'value': 'pending', 'label': 'Pending', 'color': Colors.orange},
      {'value': 'in_progress', 'label': 'In Progress', 'color': Colors.blue},
      {'value': 'completed', 'label': 'Completed', 'color': Colors.green},
      {'value': 'cancelled', 'label': 'Cancelled', 'color': Colors.red},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: statuses.map((status) {
        final isSelected = widget.selectedStatus == status['value'];
        final color = status['color'] as Color;
        
        return FilterChip(
          label: Text(
            status['label'] as String,
            style: TextStyle(
              color: isSelected ? Colors.white : color,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
          selected: isSelected,
          onSelected: (selected) {
            widget.onStatusChanged(status['value'] as String);
          },
          backgroundColor: Colors.grey.shade100,
          selectedColor: color,
          checkmarkColor: Colors.white,
          side: BorderSide(
            color: isSelected ? color : Colors.grey.shade300,
            width: 1,
          ),
          elevation: isSelected ? 2 : 0,
          pressElevation: 4,
        );
      }).toList(),
    );
  }
}

/// Quick filter chips for common patrol filters
class PatrolQuickFilters extends StatelessWidget {
  final Function(String) onFilterChanged;
  final String? selectedFilter;

  const PatrolQuickFilters({
    super.key,
    required this.onFilterChanged,
    this.selectedFilter,
  });

  @override
  Widget build(BuildContext context) {
    final quickFilters = [
      {'value': 'my_patrols', 'label': 'My Patrols', 'icon': Icons.person},
      {'value': 'urgent', 'label': 'Urgent', 'icon': Icons.priority_high},
      {'value': 'overdue', 'label': 'Overdue', 'icon': Icons.warning},
      {'value': 'today', 'label': 'Today', 'icon': Icons.today},
    ];

    return Container(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: quickFilters.length,
        itemBuilder: (context, index) {
          final filter = quickFilters[index];
          final isSelected = selectedFilter == filter['value'];
          
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              avatar: Icon(
                filter['icon'] as IconData,
                size: 16,
                color: isSelected ? Colors.white : Theme.of(context).primaryColor,
              ),
              label: Text(
                filter['label'] as String,
                style: TextStyle(
                  color: isSelected ? Colors.white : Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                onFilterChanged(selected ? filter['value'] as String : '');
              },
              backgroundColor: Colors.grey.shade100,
              selectedColor: Theme.of(context).primaryColor,
              checkmarkColor: Colors.white,
              side: BorderSide(
                color: Theme.of(context).primaryColor,
                width: 1,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Sort options dropdown for patrol lists
class PatrolSortDropdown extends StatelessWidget {
  final String selectedSort;
  final Function(String) onSortChanged;

  const PatrolSortDropdown({
    super.key,
    required this.selectedSort,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    final sortOptions = [
      {'value': 'due_date', 'label': 'Due Date'},
      {'value': 'priority', 'label': 'Priority'},
      {'value': 'status', 'label': 'Status'},
      {'value': 'created_at', 'label': 'Created'},
      {'value': 'completion', 'label': 'Completion'},
    ];

    return DropdownButton<String>(
      value: selectedSort,
      onChanged: (value) => onSortChanged(value ?? 'due_date'),
      items: sortOptions.map((option) {
        return DropdownMenuItem<String>(
          value: option['value'],
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getSortIcon(option['value'] as String),
                size: 16,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(option['label'] as String),
            ],
          ),
        );
      }).toList(),
      underline: const SizedBox.shrink(),
      icon: const Icon(Icons.sort),
      dropdownColor: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(8),
    );
  }

  IconData _getSortIcon(String sortValue) {
    switch (sortValue) {
      case 'due_date':
        return Icons.schedule;
      case 'priority':
        return Icons.priority_high;
      case 'status':
        return Icons.flag;
      case 'created_at':
        return Icons.access_time;
      case 'completion':
        return Icons.check_circle;
      default:
        return Icons.sort;
    }
  }
}