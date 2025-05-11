// main.dart
import 'package:flutter/material.dart';

void main() {
  runApp(const ScoutShiftCreatorApp());
}

class ScoutShiftCreatorApp extends StatelessWidget {
  const ScoutShiftCreatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scout Shift Creator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const ScoutShiftCreator(),
    );
  }
}

// Model classes
class Scout {
  String id;
  String name;
  List<String> unavailableMatches;
  List<String> incompatibleScouts;

  Scout({
    required this.id,
    required this.name,
    this.unavailableMatches = const [],
    this.incompatibleScouts = const [],
  });
}

class Match {
  String id;
  String name;

  Match({required this.id, required this.name});
}

class ScoutShiftCreator extends StatefulWidget {
  const ScoutShiftCreator({super.key});

  @override
  _ScoutShiftCreatorState createState() => _ScoutShiftCreatorState();
}

class _ScoutShiftCreatorState extends State<ScoutShiftCreator> {
  List<Scout> scouts = [];
  List<Match> matches = [];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Scout Shift Creator'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.person), text: 'Scouts'),
              Tab(icon: Icon(Icons.event), text: 'Matches'),
              Tab(icon: Icon(Icons.calendar_today), text: 'Schedule'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ScoutsTab(
              scouts: scouts,
              matches: matches,
              onScoutsChanged: (updatedScouts) {
                setState(() {
                  scouts = updatedScouts;
                });
              },
            ),
            MatchesTab(
              matches: matches,
              onMatchesChanged: (updatedMatches) {
                setState(() {
                  matches = updatedMatches;
                });
              },
            ),
            ScheduleTab(scouts: scouts, matches: matches),
          ],
        ),
      ),
    );
  }
}

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
  _ScoutsTabState createState() => _ScoutsTabState();
}

class _ScoutsTabState extends State<ScoutsTab> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addScout() {
    if (_nameController.text.trim().isEmpty) return;

    final newScout = Scout(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
    );

    final updatedScouts = [...widget.scouts, newScout];
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Scout Name',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _addScout,
                child: const Text('Add Scout'),
              ),
            ],
          ),
        ),
        Expanded(
          child:
              widget.scouts.isEmpty
                  ? const Center(child: Text('No scouts added yet'))
                  : ListView.builder(
                    itemCount: widget.scouts.length,
                    itemBuilder: (context, index) {
                      final scout = widget.scouts[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          title: Text(scout.name),
                          subtitle: Text(
                            'Unavailable: ${scout.unavailableMatches.length} matches\n'
                            'Incompatible: ${scout.incompatibleScouts.length} scouts',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  _showEditScoutDialog(scout);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _deleteScout(scout.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
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
  _EditScoutDialogState createState() => _EditScoutDialogState();
}

class _EditScoutDialogState extends State<EditScoutDialog> {
  late TextEditingController _nameController;
  late List<String> _unavailableMatches;
  late List<String> _incompatibleScouts;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.scout.name);
    _unavailableMatches = List.from(widget.scout.unavailableMatches);
    _incompatibleScouts = List.from(widget.scout.incompatibleScouts);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit ${widget.scout.name}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Unavailable Matches:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            widget.matches.isEmpty
                ? const Text('No matches created yet')
                : Column(
                  children:
                      widget.matches.map((match) {
                        return CheckboxListTile(
                          title: Text(match.name),
                          value: _unavailableMatches.contains(match.id),
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                _unavailableMatches.add(match.id);
                              } else {
                                _unavailableMatches.remove(match.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                ),
            const SizedBox(height: 16),
            const Text(
              'Incompatible Scouts:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Column(
              children:
                  widget.allScouts.where((s) => s.id != widget.scout.id).map((
                    otherScout,
                  ) {
                    return CheckboxListTile(
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
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
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

class MatchesTab extends StatefulWidget {
  final List<Match> matches;
  final Function(List<Match>) onMatchesChanged;

  const MatchesTab({
    super.key,
    required this.matches,
    required this.onMatchesChanged,
  });

  @override
  _MatchesTabState createState() => _MatchesTabState();
}

class _MatchesTabState extends State<MatchesTab> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addMatch() {
    if (_nameController.text.trim().isEmpty) return;

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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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

class ScheduleTab extends StatefulWidget {
  final List<Scout> scouts;
  final List<Match> matches;

  const ScheduleTab({super.key, required this.scouts, required this.matches});

  @override
  _ScheduleTabState createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<ScheduleTab> {
  int scoutsPerMatch = 2;
  List<Map<String, dynamic>> schedule = [];

  void _generateSchedule() {
    setState(() {
      schedule = [];

      for (final match in widget.matches) {
        // Filter available scouts for this match
        final availableScouts =
            widget.scouts
                .where((scout) => !scout.unavailableMatches.contains(match.id))
                .toList();

        // Try to assign scouts to this match
        final assignedScouts = _assignScoutsToMatch(availableScouts, match);

        schedule.add({'match': match, 'scouts': assignedScouts});
      }
    });
  }

  List<Scout> _assignScoutsToMatch(List<Scout> availableScouts, Match match) {
    if (availableScouts.isEmpty) return [];

    // Simple greedy algorithm - can be improved
    List<Scout> assignedScouts = [];

    // Sort by scouts with fewer assignments first (for balanced distribution)
    availableScouts.sort((a, b) {
      final aCount =
          schedule
              .where(
                (s) => (s['scouts'] as List).any((scout) => scout.id == a.id),
              )
              .length;
      final bCount =
          schedule
              .where(
                (s) => (s['scouts'] as List).any((scout) => scout.id == b.id),
              )
              .length;
      return aCount - bCount;
    });

    for (final scout in availableScouts) {
      if (assignedScouts.length >= scoutsPerMatch) break;

      // Check compatibility with already assigned scouts
      bool isCompatible = true;
      for (final assignedScout in assignedScouts) {
        if (scout.incompatibleScouts.contains(assignedScout.id) ||
            assignedScout.incompatibleScouts.contains(scout.id)) {
          isCompatible = false;
          break;
        }
      }

      if (isCompatible) {
        assignedScouts.add(scout);
      }
    }

    return assignedScouts;
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Scouts per match:'),
                    Slider(
                      value: scoutsPerMatch.toDouble(),
                      min: 1,
                      max: 5,
                      divisions: 4,
                      label: scoutsPerMatch.toString(),
                      onChanged: (value) {
                        setState(() {
                          scoutsPerMatch = value.toInt();
                        });
                      },
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed:
                    widget.scouts.isNotEmpty && widget.matches.isNotEmpty
                        ? _generateSchedule
                        : null,
                child: const Text('Generate Schedule'),
              ),
            ],
          ),
        ),
        Expanded(
          child:
              schedule.isEmpty
                  ? const Center(
                    child: Text('Generate a schedule to see results here'),
                  )
                  : ListView.builder(
                    itemCount: schedule.length,
                    itemBuilder: (context, index) {
                      final item = schedule[index];
                      final match = item['match'] as Match;
                      final assignedScouts = item['scouts'] as List<Scout>;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                match.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const Divider(),
                              assignedScouts.isEmpty
                                  ? const Text(
                                    'No scouts available for this match',
                                    style: TextStyle(color: Colors.red),
                                  )
                                  : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children:
                                        assignedScouts
                                            .map(
                                              (scout) => Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 4,
                                                    ),
                                                child: Text('• ${scout.name}'),
                                              ),
                                            )
                                            .toList(),
                                  ),
                              if (assignedScouts.length < scoutsPerMatch)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    'Warning: Only assigned ${assignedScouts.length}/$scoutsPerMatch scouts',
                                    style: const TextStyle(
                                      color: Colors.orange,
                                    ),
                                  ),
                                ),
                            ],
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
