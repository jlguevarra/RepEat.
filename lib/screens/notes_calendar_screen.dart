import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// --- DATA MODELS ---
// A base class for any item that can appear on the calendar
abstract class CalendarEvent {
  final String title;
  CalendarEvent(this.title);
}

// Represents a user-created reminder
class Reminder extends CalendarEvent {
  final int id;
  final String notes;

  Reminder({
    required this.id,
    required String title,
    required this.notes,
  }) : super(title);

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'],
      title: json['title'],
      notes: json['notes'] ?? '',
    );
  }
}

// Represents a public holiday
class Holiday extends CalendarEvent {
  Holiday(String title) : super(title);
}


// --- MAIN CALENDAR WIDGET ---
class NotesCalendarScreen extends StatefulWidget {
  final int userId;
  const NotesCalendarScreen({super.key, required this.userId});

  @override
  State<NotesCalendarScreen> createState() => _NotesCalendarScreenState();
}

class _NotesCalendarScreenState extends State<NotesCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<CalendarEvent>> _events = {};
  bool _isLoading = true;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchAllEvents();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // --- DATA HANDLING ---
  Future<void> _fetchAllEvents() async {
    setState(() => _isLoading = true);
    final events = <DateTime, List<CalendarEvent>>{};

    try {
      final responses = await Future.wait([
        http.get(Uri.parse('http://192.168.100.11/repEatApi/get_reminders.php?user_id=${widget.userId}')),
        http.get(Uri.parse('http://192.168.100.11/repEatApi/get_holidays.php')), // Assumes this file exists
      ]);

      // Process reminders
      if (responses[0].statusCode == 200) {
        final data = json.decode(responses[0].body);
        if (data['success']) {
          for (var reminderJson in data['data']) {
            final date = DateTime.parse(reminderJson['reminder_date']);
            final day = DateTime.utc(date.year, date.month, date.day);
            events.putIfAbsent(day, () => []).add(Reminder.fromJson(reminderJson));
          }
        }
      }

      // Process holidays
      if (responses[1].statusCode == 200) {
        final data = json.decode(responses[1].body);
        if (data['success']) {
          for (var holidayJson in data['data']) {
            final date = DateTime.parse(holidayJson['date']);
            final day = DateTime.utc(date.year, date.month, date.day);
            events.putIfAbsent(day, () => []).add(Holiday(holidayJson['name']));
          }
        }
      }
    } catch (e) {
      _showSnackbar('Error fetching events: $e', isError: true);
    }

    setState(() {
      _events = events;
      _isLoading = false;
    });
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    return _events[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

  // --- UI WIDGETS ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
              });
            },
            tooltip: 'Go to Today',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAllEvents,
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showReminderModal(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          TableCalendar<CalendarEvent>(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2026, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            eventLoader: _getEventsForDay,
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.sunday,
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(color: Colors.blue.shade100, shape: BoxShape.circle),
              selectedDecoration: BoxDecoration(color: Theme.of(context).primaryColor, shape: BoxShape.circle),
              markerDecoration: BoxDecoration(color: Colors.orange.shade600, shape: BoxShape.circle),
            ),
            headerStyle: const HeaderStyle(titleCentered: true, formatButtonVisible: false),
          ),
          const Divider(height: 1),
          Expanded(child: _buildEventList()),
        ],
      ),
    );
  }

  Widget _buildEventList() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final selectedEvents = _getEventsForDay(_selectedDay!);
    if (selectedEvents.isEmpty) {
      return const Center(
        child: Text("No reminders for this day.", style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: selectedEvents.length,
      itemBuilder: (context, index) {
        final event = selectedEvents[index];
        if (event is Reminder) {
          return _buildReminderTile(event);
        } else if (event is Holiday) {
          return _buildHolidayTile(event);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildReminderTile(Reminder reminder) {
    return Card(
      child: ListTile(
        // MODIFICATION: Changed the icon to represent a note
        leading: Icon(Icons.note_alt_outlined, color: Theme.of(context).primaryColor),
        title: Text(reminder.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: reminder.notes.isNotEmpty ? Text(reminder.notes) : null,
        onTap: () => _showReminderModal(reminder: reminder),
      ),
    );
  }

  Widget _buildHolidayTile(Holiday holiday) {
    return Card(
      color: Colors.green.shade50,
      child: ListTile(
        leading: const Icon(Icons.celebration, color: Colors.green),
        title: Text(holiday.title),
      ),
    );
  }

  // --- MODAL & ACTIONS ---
  void _showReminderModal({Reminder? reminder}) {
    final isEditing = reminder != null;
    _titleController.text = isEditing ? reminder.title : '';
    _notesController.text = isEditing ? reminder.notes : '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          top: 20, left: 20, right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(isEditing ? 'Edit Reminder' : 'Add Reminder', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 20),
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _notesController, decoration: const InputDecoration(labelText: 'Notes (Optional)', border: OutlineInputBorder()), maxLines: 3),
            const SizedBox(height: 20),
            Row(
              children: [
                if (isEditing)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteReminder(reminder.id),
                  ),
                const Spacer(),
                TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(context).pop()),
                const SizedBox(width: 8),
                ElevatedButton(
                  child: Text(isEditing ? 'Update' : 'Save'),
                  onPressed: () => _saveReminder(id: reminder?.id),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _saveReminder({int? id}) async {
    if (_titleController.text.isEmpty) {
      _showSnackbar('Title cannot be empty.', isError: true);
      return;
    }

    Navigator.of(context).pop(); // Close modal first
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://192.168.100.11/repEatApi/save_reminder.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'id': id,
          'user_id': widget.userId,
          'title': _titleController.text,
          'notes': _notesController.text,
          'reminder_date': DateFormat('yyyy-MM-dd').format(_selectedDay!),
        }),
      );
      final data = json.decode(response.body);
      if (data['success']) {
        _showSnackbar('Reminder saved!');
        await _fetchAllEvents();
      } else {
        throw Exception(data['message']);
      }
    } catch(e) {
      _showSnackbar('Error saving reminder: $e', isError: true);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteReminder(int id) async {
    Navigator.of(context).pop(); // Close modal
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://192.168.100.11/repEatApi/delete_reminder.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'id': id, 'user_id': widget.userId}),
      );
      final data = json.decode(response.body);
      if (data['success']) {
        _showSnackbar('Reminder deleted.');
        await _fetchAllEvents();
      } else {
        throw Exception(data['message']);
      }
    } catch(e) {
      _showSnackbar('Error deleting reminder: $e', isError: true);
      setState(() => _isLoading = false);
    }
  }

  // MODIFICATION: Changed to a modern, floating snackbar with an icon
  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: Colors.white,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
    ));
  }
}