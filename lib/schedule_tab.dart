import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:scouting_shifts_creater/main.dart';

class ScheduleTab extends StatefulWidget {
  final List<Scout> scouts;
  final List<Match> matches;

  const ScheduleTab({super.key, required this.scouts, required this.matches});

  @override
  ScheduleTabState createState() => ScheduleTabState();
}

class ScheduleTabState extends State<ScheduleTab>
    with AutomaticKeepAliveClientMixin {
  int scoutsPerMatch = 2;
  bool useRandomShifts = false;
  int shiftDuration = 1;
  bool allowBackToBackShifts = false;
  List<Map<String, dynamic>> schedule = [];

  void generateSchedule() {
    setState(() {
      schedule = [];

      List<Scout> rotation = [];
      int shiftCounter = 0;
      Set<String> previousShiftScoutIds = {};

      for (final match in widget.matches) {
        if (shiftCounter == 0 || rotation.isEmpty) {
          final availableScouts =
              widget.scouts
                  .where(
                    (scout) =>
                        !scout.unavailableMatches.contains(match.id) &&
                        (allowBackToBackShifts ||
                            !previousShiftScoutIds.contains(scout.id)),
                  )
                  .toList();
          rotation = assignScoutsToMatch(availableScouts, match);
          previousShiftScoutIds = rotation.map((s) => s.id).toSet();
          shiftCounter = shiftDuration;
        }

        final validRotation =
            rotation
                .where((scout) => !scout.unavailableMatches.contains(match.id))
                .toList();

        schedule.add({'match': match, 'scouts': validRotation});
        shiftCounter--;
      }
    });
  }

  List<Scout> assignScoutsToMatch(List<Scout> availableScouts, Match match) {
    if (availableScouts.isEmpty) return [];

    List<Scout> assignedScouts = [];

    if (useRandomShifts) {
      availableScouts.shuffle();
    } else {
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
    }

    for (final scout in availableScouts) {
      if (assignedScouts.length >= scoutsPerMatch) break;

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

  Future<void> exportScheduleToCSV() async {
    final buffer = StringBuffer();

    // Write header
    buffer.write('Match Name');
    for (int i = 1; i <= scoutsPerMatch; i++) {
      buffer.write(',$i');
    }
    buffer.writeln();

    for (final item in schedule) {
      final match = item['match'] as Match;
      final assignedScouts = item['scouts'] as List<Scout>;

      buffer.write('"${match.name}"');
      for (int i = 0; i < scoutsPerMatch; i++) {
        if (i < assignedScouts.length) {
          buffer.write(',${assignedScouts[i].name}');
        } else {
          buffer.write(',');
        }
      }
      buffer.writeln();
    }

    final result = await FilePicker.platform.getDirectoryPath();

    if (result != null) {
      final path = '$result/scouting_schedule.csv';
      final file = File(path);
      await file.writeAsString(buffer.toString());

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('CSV file saved to $path')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No folder selected')));
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
                              max: 8,
                              divisions: 7,
                              label: scoutsPerMatch.toString(),
                              onChanged: (value) {
                                setState(() {
                                  scoutsPerMatch = value.toInt();
                                });
                              },
                            ),
                            const SizedBox(height: 8),
                            const Text('Shift duration (in matches):'),
                            Slider(
                              value: shiftDuration.toDouble(),
                              min: 1,
                              max: 15,
                              divisions: 14,
                              label: shiftDuration.toString(),
                              onChanged: (value) {
                                setState(() {
                                  shiftDuration = value.toInt();
                                });
                              },
                            ),
                            const SizedBox(height: 8),
                            SwitchListTile(
                              title: const Text('Use Random Shifts'),
                              value: useRandomShifts,
                              onChanged: (value) {
                                setState(() {
                                  useRandomShifts = value;
                                });
                              },
                            ),
                            SwitchListTile(
                              title: const Text('Allow Back-to-Back Shifts'),
                              value: allowBackToBackShifts,
                              onChanged: (value) {
                                setState(() {
                                  allowBackToBackShifts = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed:
                            widget.scouts.isNotEmpty &&
                                    widget.matches.isNotEmpty
                                ? generateSchedule
                                : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                        ),
                        child: const Text('Generate Schedule'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child:
                  schedule.isEmpty
                      ? const Center(
                        child: Text(
                          'Generate a schedule to see results here',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
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
                                                    child: Text(
                                                      '• ${scout.name}',
                                                    ),
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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: schedule.isNotEmpty ? exportScheduleToCSV : null,
                icon: const Icon(Icons.download),
                label: const Text('Export to CSV'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
