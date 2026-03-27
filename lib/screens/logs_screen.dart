// ── logs_screen.dart ──
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class LogsScreen extends StatefulWidget {
  final AppUser user;
  const LogsScreen({super.key, required this.user});
  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  List<LessonLog> _logs = [];
  List<LessonLog> _filtered = [];
  bool _loading = true;
  String _subjFilter = 'All';
  String _search = '';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final target = widget.user.role == 'teacher' ? null
      : (widget.user.linkedStudent.isNotEmpty ? widget.user.linkedStudent : widget.user.name);
    final logs = await FirebaseService.getLogs(studentName: target);
    if (mounted) setState(() { _logs = logs; _filter(); _loading = false; });
  }

  void _filter() {
    var l = _logs;
    if (_subjFilter != 'All') l = l.where((x) => x.subject == _subjFilter).toList();
    if (_search.isNotEmpty) {
      l = l.where((x) =>
      x.topic.toLowerCase().contains(_search) ||
      x.subject.toLowerCase().contains(_search) ||
      x.teacher.toLowerCase().contains(_search) ||
      x.observations.toLowerCase().contains(_search)).toList();
    }
    setState(() => _filtered = l);
  }

  static const _invalidSubjects = {'parent', 'teacher', 'student', ''};
  List<String> get _subjects => [
    'All',
    ..._logs
      .map((l) => l.subject.trim())
      .where((s) => s.isNotEmpty && !_invalidSubjects.contains(s.toLowerCase()))
      .toSet()
      .toList()..sort(),
  ];

  @override
  Widget build(BuildContext context) => Column(children: [
    // Search bar
    Container(
      color: AppTheme.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: TextField(
        onChanged: (v) { _search = v.toLowerCase(); _filter(); },
        decoration: InputDecoration(
          hintText: '🔍 Search topic, teacher, observations...',
          hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.slate),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: AppTheme.fog)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: AppTheme.fog)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: AppTheme.purple)),
          filled: true, fillColor: AppTheme.mist, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9)),
      ),
    ),
    // Subject pills
    Container(
      color: AppTheme.white,
      padding: const EdgeInsets.only(bottom: 10, left: 12, right: 12),
      child: SizedBox(height: 32, child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _subjects.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final s = _subjects[i];
          final active = s == _subjFilter;
          return GestureDetector(
            onTap: () { setState(() => _subjFilter = s); _filter(); },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: active ? AppTheme.ink : AppTheme.white,
                border: Border.all(color: active ? AppTheme.ink : AppTheme.fog),
                borderRadius: BorderRadius.circular(20)),
              child: Text(s, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600,
                color: active ? Colors.white : AppTheme.ink3)),
            ),
          );
        },
      )),
    ),
    // Logs list
    Expanded(child: _loading
      ? const Center(child: CircularProgressIndicator())
      : RefreshIndicator(
          onRefresh: _load,
          child: _filtered.isEmpty
            ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('📭', style: TextStyle(fontSize: 40)),
                SizedBox(height: 10),
                Text('No records found'),
              ]))
            : ListView.builder(
                padding: const EdgeInsets.all(14),
                itemCount: _filtered.length,
                itemBuilder: (_, i) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (widget.user.role == 'teacher') Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 2),
                    child: Text(_filtered[i].studentName.toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w700,
                        color: AppTheme.slate, letterSpacing: 0.6)),
                  ),
                  LessonLogCard(log: _filtered[i]),
                ]),
              ),
        )),
  ]);
}
