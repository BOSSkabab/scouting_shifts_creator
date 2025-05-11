// main.dart

import 'package:flutter/material.dart';
import 'package:scouting_shifts_creater/main.dart';

class MatchesTab extends StatefulWidget {
  final List<Match> matches;
  final Function(List<Match>) onMatchesChanged;

  const MatchesTab({
    super.key,
    required this.matches,
    required this.onMatchesChanged,
  });

  @override
  MatchesTabState createState() => MatchesTabState();
}

class MatchesTabState extends State<MatchesTab> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _countController = TextEditingController(
    text: '10',
  );

  // Match types
  final List<String> _matchTypes = [
    'Quals',
    'Finals',
    'Pre Scouting',
    'Practice',
    'Double Elims',
  ];
  String _selectedMatchType = 'Quals';

  @override
  void dispose() {
    _nameController.dispose();
    _countController.dispose();
    super.dispose();
  }

  void _addMatch() {
    if (_nameController.text.trim().isEmpty) return;

    if (widget.matches.any(
      (match) => match.name == _nameController.text.trim(),
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Match with this name already exists')),
      );
      return;
    }

    final newMatch = Match(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
    );

    final updatedMatches = [...widget.matches, newMatch];
    widget.onMatchesChanged(updatedMatches);
    _nameController.clear();
  }

  void _deleteMatch(String id) {
    final updatedMatches =
        widget.matches.where((match) => match.id != id).toList();
    widget.onMatchesChanged(updatedMatches);
  }

  void _generateMatches() {
    // Validate inputs
    final countText = _countController.text.trim();

    if (_selectedMatchType.isEmpty || countText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all the fields')),
      );
      return;
    }

    int? matchCount = int.tryParse(countText);

    if (matchCount == null || matchCount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid positive number')),
      );
      return;
    }

    // Generate matches
    List<Match> generatedMatches = [];

    for (int i = 1; i <= matchCount; i++) {
      String matchName;

      // Special naming for finals
      if (_selectedMatchType == 'Finals') {
        if (i == 1) {
          matchName = 'Finals 1';
        } else if (i == 2) {
          matchName = 'Finals 2';
        } else if (i == 3) {
          matchName = 'Finals 3 (Tiebreaker)';
        } else {
          matchName = 'Finals $i';
        }
      } else if (_selectedMatchType == 'Double Elims') {
        // For Double Elims we might want a different format
        if (i <= matchCount / 2) {
          matchName = 'DE Winners $i';
        } else {
          matchName = 'DE Losers ${i - (matchCount ~/ 2)}';
        }
      } else {
        // Standard format
        matchName = '$_selectedMatchType $i';
      }

      if (!widget.matches.any((match) => match.name == matchName)) {
        generatedMatches.add(
          Match(
            id:
                '${DateTime.now().millisecondsSinceEpoch}_${_selectedMatchType}_$i',
            name: matchName,
            type: _selectedMatchType,
          ),
        );
      }
    }

    final updatedMatches = [...widget.matches, ...generatedMatches];
    widget.onMatchesChanged(updatedMatches);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generated $matchCount $_selectedMatchType matches'),
      ),
    );
  }

  void _clearAllMatches() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Clear All Matches'),
            content: const Text(
              'Are you sure you want to delete all matches? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  widget.onMatchesChanged([]);
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Clear All'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedMatchType,
                  items:
                      _matchTypes.map((String type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                  decoration: const InputDecoration(
                    labelText: 'Match Type',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedMatchType = value;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _countController,
                  decoration: const InputDecoration(
                    labelText: 'Match Count',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _generateMatches,
                child: const Text('Generate Matches'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Match Name',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _addMatch,
                child: const Text('Add Match'),
              ),
              IconButton(
                onPressed: _clearAllMatches,
                icon: const Icon(Icons.delete),
              ),
            ],
          ),
        ),
        Expanded(
          child:
              widget.matches.isEmpty
                  ? const Center(child: Text('No matches added yet'))
                  : ListView.builder(
                    itemCount: widget.matches.length,
                    itemBuilder: (context, index) {
                      final match = widget.matches[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          title: Text(match.name),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteMatch(match.id),
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
