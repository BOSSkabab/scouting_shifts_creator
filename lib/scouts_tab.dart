import 'package:flutter/material.dart';
import 'package:scouting_shifts_creater/main.dart';

class ScoutsTab extends StatefulWidget {
  final List<Scout> scouts;
  final List<Match> matches;
  final Function(List<Scout>) onScoutsChanged;

  const ScoutsTab({
    super.key,
    required this.scouts,
    required this.matches,
    required this.onScoutsChanged,
  });

  @override
  ScoutsTabState createState() => ScoutsTabState();
}

class ScoutsTabState extends State<ScoutsTab> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addScout() {
    final rawInput = _nameController.text.trim();
    if (rawInput.isEmpty) return;

    final names =
        rawInput
            .split(',')
            .map((name) => name.trim())
            .where((name) => name.isNotEmpty)
            .toList();
    if (names.isEmpty) return;

    final newScouts =
        names.map((name) {
          return Scout(
            id: DateTime.now().millisecondsSinceEpoch.toString() + name,
            name: name,
          );
        }).toList();

    final updatedScouts = [...widget.scouts, ...newScouts];
    widget.onScoutsChanged(updatedScouts);
    _nameController.clear();
  }

  void _deleteScout(String id) {
    final updatedScouts =
        widget.scouts.where((scout) => scout.id != id).toList();
    widget.onScoutsChanged(updatedScouts);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFe0eafc), Color(0xFFcfdef3)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nameController,
                          onSubmitted: (value) => _addScout(),
                          decoration: const InputDecoration(
                            labelText: 'Scout Name',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Add Scout'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _addScout,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child:
                  widget.scouts.isEmpty
                      ? const Center(
                        child: Text(
                          'No scouts added yet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                      : Builder(
                        builder: (context) {
                          final sortedScouts = [...widget.scouts];
                          sortedScouts.sort((a, b) {
                            final aPriority =
                                (a.unavailableMatches.isNotEmpty ||
                                        a.incompatibleScouts.isNotEmpty)
                                    ? 0
                                    : 1;
                            final bPriority =
                                (b.unavailableMatches.isNotEmpty ||
                                        b.incompatibleScouts.isNotEmpty)
                                    ? 0
                                    : 1;
                            return aPriority.compareTo(bPriority);
                          });
                          return ListView.builder(
                            padding: const EdgeInsets.only(bottom: 16),
                            itemCount: sortedScouts.length,
                            itemBuilder: (context, index) {
                              final scout = sortedScouts[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                elevation: 5,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  title: Text(
                                    scout.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Unavailable: ${scout.unavailableMatches.length} matches',
                                      ),
                                      if (scout.unavailableMatches.isNotEmpty)
                                        Text(
                                          '→ ${_formatMatchRanges(scout.unavailableMatches)}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      Text(
                                        'Incompatible: ${scout.incompatibleScouts.length} scouts',
                                      ),
                                      if (scout.incompatibleScouts.isNotEmpty)
                                        Text(
                                          '→ ${scout.incompatibleScouts.map((id) => widget.scouts.firstWhere((s) => s.id == id, orElse: () => Scout(id: id, name: 'Unknown')).name).join(', ')}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black87,
                                          ),
                                        ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.blueGrey,
                                        ),
                                        onPressed: () {
                                          _showEditScoutDialog(scout);
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.redAccent,
                                        ),
                                        onPressed: () => _deleteScout(scout.id),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMatchRanges(List<String> matchIds) {
    if (matchIds.isEmpty) return '';
    final matchIndexMap = {
      for (int i = 0; i < widget.matches.length; i++) widget.matches[i].id: i,
    };

    // Deduplicate and sort by index
    final sorted =
        matchIds.where((id) => matchIndexMap.containsKey(id)).toSet().toList()
          ..sort((a, b) => matchIndexMap[a]!.compareTo(matchIndexMap[b]!));

    List<String> ranges = [];
    int start = 0;
    while (start < sorted.length) {
      int end = start;
      while (end + 1 < sorted.length &&
          matchIndexMap[sorted[end + 1]] == matchIndexMap[sorted[end]]! + 1) {
        end++;
      }
      final startName = widget.matches[matchIndexMap[sorted[start]]!].name;
      final endName = widget.matches[matchIndexMap[sorted[end]]!].name;
      ranges.add(start == end ? startName : '$startName - $endName');
      start = end + 1;
    }
    return ranges.join(', ');
  }

  void _showEditScoutDialog(Scout scout) {
    showDialog(
      context: context,
      builder:
          (context) => EditScoutDialog(
            scout: scout,
            allScouts: widget.scouts,
            matches: widget.matches,
            onSave: (updatedScout) {
              final index = widget.scouts.indexWhere(
                (s) => s.id == updatedScout.id,
              );
              if (index != -1) {
                final updatedScouts = [...widget.scouts];
                updatedScouts[index] = updatedScout;
                widget.onScoutsChanged(updatedScouts);
              }
            },
          ),
    );
  }
}

class EditScoutDialog extends StatefulWidget {
  final Scout scout;
  final List<Scout> allScouts;
  final List<Match> matches;
  final Function(Scout) onSave;

  const EditScoutDialog({
    super.key,
    required this.scout,
    required this.allScouts,
    required this.matches,
    required this.onSave,
  });

  @override
  EditScoutDialogState createState() => EditScoutDialogState();
}

class EditScoutDialogState extends State<EditScoutDialog> {
  late TextEditingController _nameController;
  late List<String> _unavailableMatches;
  late List<String> _incompatibleScouts;
  String? _rangeStartId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.scout.name);
    _unavailableMatches = List.from(widget.scout.unavailableMatches);
    _incompatibleScouts = List.from(widget.scout.incompatibleScouts);
    _rangeStartId = null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: const Color(0xFFF8F9FA),
      title: Text(
        'Edit ${widget.scout.name}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            if (widget.matches.isNotEmpty)
              Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 0),
                  title: const Text(
                    'Unavailable Matches',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                  children:
                      widget.matches.map((match) {
                        return CheckboxListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(match.name),
                          value: _unavailableMatches.contains(match.id),
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                if (_rangeStartId == null) {
                                  _rangeStartId = match.id;
                                  _unavailableMatches.add(match.id);
                                } else {
                                  final matchIds =
                                      widget.matches.map((m) => m.id).toList();
                                  final startIndex = matchIds.indexOf(
                                    _rangeStartId!,
                                  );
                                  final endIndex = matchIds.indexOf(match.id);
                                  final range = matchIds.sublist(
                                    startIndex < endIndex
                                        ? startIndex
                                        : endIndex,
                                    (startIndex < endIndex
                                            ? endIndex
                                            : startIndex) +
                                        1,
                                  );
                                  _unavailableMatches.addAll(range);
                                  _rangeStartId = null;
                                }
                              } else {
                                _unavailableMatches.remove(match.id);
                                _rangeStartId = null;
                              }
                            });
                          },
                        );
                      }).toList(),
                ),
              )
            else
              const Text('No matches created yet'),
            const SizedBox(height: 16),
            Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 0),
                title: const Text(
                  'Incompatible Scouts',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
                children:
                    widget.allScouts.where((s) => s.id != widget.scout.id).map((
                      otherScout,
                    ) {
                      return CheckboxListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(otherScout.name),
                        value: _incompatibleScouts.contains(otherScout.id),
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              _incompatibleScouts.add(otherScout.id);
                            } else {
                              _incompatibleScouts.remove(otherScout.id);
                            }
                          });
                        },
                      );
                    }).toList(),
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () {
            final updatedScout = Scout(
              id: widget.scout.id,
              name: _nameController.text.trim(),
              unavailableMatches: _unavailableMatches,
              incompatibleScouts: _incompatibleScouts,
            );
            widget.onSave(updatedScout);
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
