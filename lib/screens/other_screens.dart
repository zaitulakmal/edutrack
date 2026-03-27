import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

// ═══════════════════════════════════
// SUBJECTS SCREEN
// ═══════════════════════════════════
class SubjectsScreen extends StatefulWidget {
  final AppUser user;
  const SubjectsScreen({super.key, required this.user});
  @override State<SubjectsScreen> createState() => _SubjectsScreenState();
}
class _SubjectsScreenState extends State<SubjectsScreen> {
  List<LessonLog> _logs = [];
  bool _loading = true;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final t = widget.user.role == 'teacher' ? null : (widget.user.linkedStudent.isNotEmpty ? widget.user.linkedStudent : widget.user.name);
    final l = await FirebaseService.getLogs(studentName: t);
    if (mounted) setState(() { _logs = l; _loading = false; });
  }
  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final subjects = _logs.map((l) => l.subject).toSet().toList()..sort();
    return GridView.builder(
      padding: const EdgeInsets.all(14),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.9),
      itemCount: subjects.length,
      itemBuilder: (_, i) {
        final subj = subjects[i];
        final cnt  = _logs.where((l) => l.subject == subj).length;
        final comp = _logs.where((l) => l.subject == subj && l.isDone).length;
        final teachers = _logs.where((l) => l.subject == subj).map((l) => l.teacher).toSet().take(2).toList();
        return SubjectCard(subject: subj, teachers: teachers, total: cnt, completed: comp,
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => _SubjectLogsScreen(subject: subj, logs: _logs.where((l) => l.subject == subj).toList()))));
      },
    );
  }
}

class _SubjectLogsScreen extends StatelessWidget {
  final String subject;
  final List<LessonLog> logs;
  const _SubjectLogsScreen({required this.subject, required this.logs});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(backgroundColor: AppTheme.ink, title: Text(subject),
      leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context))),
    body: ListView(padding: const EdgeInsets.all(14),
      children: logs.map((l) => LessonLogCard(log: l)).toList()),
  );
}

// ═══════════════════════════════════
// EXAMS SCREEN
// ═══════════════════════════════════
class ExamsScreen extends StatefulWidget {
  final AppUser user;
  const ExamsScreen({super.key, required this.user});
  @override State<ExamsScreen> createState() => _ExamsScreenState();
}
class _ExamsScreenState extends State<ExamsScreen> {
  List<ExamResult> _exams = [];
  List<LessonLog> _logs = [];
  bool _loading = true;
  String? _selectedStudent;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final target = widget.user.role == 'teacher'
      ? _selectedStudent
      : (widget.user.linkedStudent.isNotEmpty ? widget.user.linkedStudent : widget.user.name);
    final exams = await FirebaseService.getExams(studentName: target);
    final logs  = await FirebaseService.getLogs(studentName: target);
    if (mounted) setState(() { _exams = exams; _logs = logs; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final terms = ['Early-Term', 'Mid-Term', 'Final-Term'];
    final subjects = _logs.map((l) => l.subject).toSet().toList()..sort();

    return _loading
      ? const Center(child: CircularProgressIndicator())
      : ListView(padding: const EdgeInsets.all(14), children: [
          if (widget.user.role == 'teacher') ...[
            _StudentSelector(onChanged: (s) { setState(() { _selectedStudent = s; _loading = true; }); _load(); }),
            const SizedBox(height: 12),
          ],
          ...terms.map((term) {
            final termExams = _exams.where((e) => e.term == term).toList();
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: AppTheme.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.fog)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                  child: Text(term, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.ink))),
                Table(
                  columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1), 2: FlexColumnWidth(3)},
                  children: [
                    TableRow(decoration: const BoxDecoration(color: AppTheme.mist), children: [
                      _th('Subject'), _th('Score'), _th('Feedback'),
                    ]),
                    ...subjects.map((subj) {
                      final e = termExams.where((x) => x.subject.toLowerCase() == subj.toLowerCase()).firstOrNull;
                      return TableRow(children: [
                        _td('${AppTheme.subjectIcon(subj)} $subj'),
                        _td(e?.score.isNotEmpty == true ? e!.score : '—', bold: e?.score.isNotEmpty == true),
                        _td(e?.feedback.isNotEmpty == true ? e!.feedback : 'Pending...', muted: e?.feedback.isEmpty != false),
                      ]);
                    }),
                  ],
                ),
                const SizedBox(height: 4),
              ]),
            );
          }),
          if (widget.user.role == 'teacher') _ExamAddForm(user: widget.user, subjects: subjects, onSaved: _load),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppTheme.amberBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFFDE68A))),
            child: Text('⚠️ Exam scores are entered by teachers. They appear here once saved to Firebase.',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF92400E))),
          ),
        ]);
  }

  Widget _th(String t) => Padding(padding: const EdgeInsets.all(9),
    child: Text(t.toUpperCase(), style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w700, color: AppTheme.slate, letterSpacing: 0.6)));
  Widget _td(String t, {bool bold = false, bool muted = false}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
    child: Text(t, style: GoogleFonts.plusJakartaSans(fontSize: 11,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      color: muted ? AppTheme.slate : AppTheme.ink3,
      fontStyle: muted ? FontStyle.italic : FontStyle.normal)));
}

class _StudentSelector extends StatefulWidget {
  final ValueChanged<String?> onChanged;
  const _StudentSelector({required this.onChanged});
  @override State<_StudentSelector> createState() => _StudentSelectorState();
}
class _StudentSelectorState extends State<_StudentSelector> {
  List<AppUser> _students = [];
  String? _selected;
  @override void initState() { super.initState(); FirebaseService.getStudents().then((s) => setState(() => _students = s)); }
  @override
  Widget build(BuildContext context) => Row(children: [
    Text('Student: ', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.slate)),
    Expanded(child: DropdownButtonFormField<String>(
      initialValue: _selected,
      hint: Text('All students', style: GoogleFonts.plusJakartaSans(fontSize: 12)),
      decoration: InputDecoration(isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.fog))),
      items: _students.map((s) => DropdownMenuItem(value: s.name, child: Text(s.name, style: GoogleFonts.plusJakartaSans(fontSize: 12)))).toList(),
      onChanged: (v) { setState(() => _selected = v); widget.onChanged(v); },
    )),
  ]);
}

class _ExamAddForm extends StatefulWidget {
  final AppUser user;
  final List<String> subjects;
  final VoidCallback onSaved;
  const _ExamAddForm({required this.user, required this.subjects, required this.onSaved});
  @override State<_ExamAddForm> createState() => _ExamAddFormState();
}
class _ExamAddFormState extends State<_ExamAddForm> {
  final _scoreCtrl = TextEditingController();
  final _feedbackCtrl = TextEditingController();
  String _term = 'Early-Term';
  String? _subject;
  List<AppUser> _students = [];
  String? _student;
  bool _saving = false;

  @override void initState() { super.initState(); FirebaseService.getStudents().then((s) => setState(() => _students = s)); }

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppTheme.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.fog)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Add Exam Result', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.ink)),
      const SizedBox(height: 12),
      _drop('Student', _students.map((s) => s.name).toList(), _student, (v) => setState(() => _student = v)),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: _drop('Term', ['Early-Term','Mid-Term','Final-Term'], _term, (v) => setState(() => _term = v!))),
        const SizedBox(width: 8),
        Expanded(child: _drop('Subject', widget.subjects, _subject, (v) => setState(() => _subject = v))),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: _fi('Score', _scoreCtrl)),
        const SizedBox(width: 8),
        Expanded(flex: 2, child: _fi('Feedback', _feedbackCtrl)),
      ]),
      const SizedBox(height: 10),
      ElevatedButton(
        onPressed: _saving ? null : _save,
        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.purple, foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        child: Text(_saving ? 'Saving...' : '💾 Save', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
      ),
    ]),
  );

  Future<void> _save() async {
    if (_student == null || _subject == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a student and subject.')));
      return;
    }
    setState(() => _saving = true);
    try {
      await FirebaseService.addExam(ExamResult(
        studentName: _student!, term: _term, subject: _subject!,
        score: _scoreCtrl.text.trim(), feedback: _feedbackCtrl.text.trim()));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Exam result saved!')));
        _scoreCtrl.clear();
        _feedbackCtrl.clear();
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    if (mounted) setState(() => _saving = false);
  }

  Widget _drop(String lbl, List<String> items, String? val, ValueChanged<String?> onChange) => DropdownButtonFormField<String>(
    initialValue: val,
    hint: Text(lbl, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.slate)),
    decoration: InputDecoration(labelText: lbl, labelStyle: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppTheme.slate),
      isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.fog)),
      filled: true, fillColor: AppTheme.mist),
    items: items.map((s) => DropdownMenuItem(value: s, child: Text(s, style: GoogleFonts.plusJakartaSans(fontSize: 12)))).toList(),
    onChanged: onChange,
  );

  Widget _fi(String lbl, TextEditingController ctrl) => TextField(controller: ctrl,
    decoration: InputDecoration(labelText: lbl, labelStyle: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppTheme.slate),
      isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.fog)),
      filled: true, fillColor: AppTheme.mist),
    style: GoogleFonts.plusJakartaSans(fontSize: 12));
}

// ═══════════════════════════════════
// NOTIFICATIONS SCREEN
// ═══════════════════════════════════
class NotifsScreen extends StatefulWidget {
  final AppUser user;
  const NotifsScreen({super.key, required this.user});
  @override State<NotifsScreen> createState() => _NotifsScreenState();
}
class _NotifsScreenState extends State<NotifsScreen> {
  List<LessonLog> _logs = [];
  bool _loading = true;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final t = widget.user.role == 'teacher' ? null : (widget.user.linkedStudent.isNotEmpty ? widget.user.linkedStudent : widget.user.name);
    final l = await FirebaseService.getLogs(studentName: t);
    if (mounted) setState(() { _logs = l; _loading = false; });
  }
  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final late = <String, int>{}, hw = <String, int>{}, pos = <String, int>{};
    for (final l in _logs) {
      final n = l.studentName.isNotEmpty ? l.studentName : widget.user.name;
      if (l.isLate)          late[n] = (late[n] ?? 0) + 1;
      if (l.homeworkMissed)  hw[n]   = (hw[n] ?? 0) + 1;
      final o = l.observations.toLowerCase();
      if (o.contains('excellent') || o.contains('cemerlang') || o.contains('punctual') || o.contains('very good')) {
        pos[n] = (pos[n] ?? 0) + 1;
      }
    }
    final notifs = <Map<String, dynamic>>[];
    late.entries.toList()..sort((a,b) => b.value.compareTo(a.value))
      ..take(3).forEach((e) => notifs.add({'c': AppTheme.amber, 'title': 'Late Arrivals — ${e.key}', 'body': '${e.key} was flagged late in ${e.value} session${e.value > 1 ? "s" : ""}.', 'time': 'Recurring'}));
    hw.entries.toList()..sort((a,b) => b.value.compareTo(a.value))
      ..take(3).forEach((e) => notifs.add({'c': AppTheme.red, 'title': 'Homework Issues — ${e.key}', 'body': '${e.key} has ${e.value} instance${e.value > 1 ? "s" : ""} of not submitting homework.', 'time': 'Recurring'}));
    pos.entries.toList()..sort((a,b) => b.value.compareTo(a.value))
      ..take(3).forEach((e) => notifs.add({'c': AppTheme.green, 'title': 'Positive Performance — ${e.key}', 'body': '${e.key} showed excellent behaviour in ${e.value} session${e.value > 1 ? "s" : ""}.', 'time': 'Recurring'}));
    if (notifs.isEmpty) notifs.add({'c': AppTheme.blue, 'title': 'No alerts yet', 'body': 'Alerts are auto-generated from teacher observations in Firebase.', 'time': 'System'});
    return ListView(padding: const EdgeInsets.all(14),
      children: notifs.map((n) => NotifCard(dotColor: n['c'], title: n['title'], body: n['body'], time: n['time'])).toList());
  }
}

// ═══════════════════════════════════
// ADD ENTRY SCREEN
// ═══════════════════════════════════
class AddEntryScreen extends StatefulWidget {
  final AppUser user;
  const AddEntryScreen({super.key, required this.user});
  @override State<AddEntryScreen> createState() => _AddEntryScreenState();
}
class _AddEntryScreenState extends State<AddEntryScreen> {
  final _topicCtrl = TextEditingController();
  final _hwCtrl    = TextEditingController();
  final _obsCtrl   = TextEditingController();
  final _fuCtrl    = TextEditingController();
  final _subjCtrl  = TextEditingController();
  final _teacherCtrl = TextEditingController();
  String _progress = 'Completed';
  DateTime _date = DateTime.now();
  String? _student;
  List<AppUser> _students = [];
  bool _saving = false;

  @override void initState() { super.initState(); FirebaseService.getStudents().then((s) => setState(() { _students = s; if (s.isNotEmpty) _student = s.first.name; })); }

  Future<void> _save() async {
    if (_topicCtrl.text.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter the topic.'))); return; }
    setState(() => _saving = true);
    await FirebaseService.addLog(LessonLog(
      studentName: _student ?? '',
      date: '${_date.day} ${['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][_date.month-1]} ${_date.year}',
      subject: _subjCtrl.text.trim(),
      teacher: _teacherCtrl.text.trim(),
      topic: _topicCtrl.text.trim(),
      progress: _progress,
      homework: _hwCtrl.text.trim(),
      observations: _obsCtrl.text.trim(),
      followUp: _fuCtrl.text.trim(),
    ));
    if (mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Entry saved to Firebase!'))); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(backgroundColor: AppTheme.ink, title: const Text('Add Lesson Entry'),
      leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context))),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      _fi('Student', child: DropdownButtonFormField<String>(
        initialValue: _student,
        items: _students.map((s) => DropdownMenuItem(value: s.name, child: Text(s.name, style: GoogleFonts.plusJakartaSans(fontSize: 13)))).toList(),
        onChanged: (v) => setState(() => _student = v),
        decoration: _dec('Select student'),
      )),
      Row(children: [
        Expanded(child: _fi('Date', child: InkWell(
          onTap: () async {
            final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime(2030));
            if (d != null) setState(() => _date = d);
          },
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(color: AppTheme.mist, border: Border.all(color: AppTheme.fog), borderRadius: BorderRadius.circular(9)),
            child: Text('${_date.day}/${_date.month}/${_date.year}', style: GoogleFonts.plusJakartaSans(fontSize: 13))),
        ))),
        const SizedBox(width: 10),
        Expanded(child: _fi('Progress', child: DropdownButtonFormField<String>(
          initialValue: _progress,
          items: ['Completed','Ongoing','Selesai'].map((s) => DropdownMenuItem(value: s, child: Text(s, style: GoogleFonts.plusJakartaSans(fontSize: 13)))).toList(),
          onChanged: (v) => setState(() => _progress = v!),
          decoration: _dec('Progress'),
        ))),
      ]),
      Row(children: [
        Expanded(child: _fi('Subject', child: _input(_subjCtrl, 'e.g. Sejarah'))),
        const SizedBox(width: 10),
        Expanded(child: _fi('Teacher', child: _input(_teacherCtrl, 'e.g. Ms Amirah'))),
      ]),
      _fi('Topic Covered', child: _input(_topicCtrl, 'e.g. Bab 2 Kebangkitan Nasionalisme')),
      _fi('Homework Assigned', child: _input(_hwCtrl, 'e.g. Workbook page 13')),
      _fi('Observations / Notes', child: _textarea(_obsCtrl, 'Student engagement, challenges, strengths...')),
      _fi('Follow-up for Next Class', child: _textarea(_fuCtrl, 'Next topic or action...')),
      const SizedBox(height: 8),
      SizedBox(width: double.infinity, child: ElevatedButton(
        onPressed: _saving ? null : _save,
        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.purple, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        child: Text(_saving ? 'Saving to Firebase...' : '💾 Save to Firebase',
          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700)),
      )),
    ]),
  );

  Widget _fi(String label, {required Widget child}) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label.toUpperCase(), style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.slate, letterSpacing: 0.6)),
    const SizedBox(height: 5), child, const SizedBox(height: 12),
  ]);
  Widget _input(TextEditingController c, String hint) => TextField(controller: c,
    style: GoogleFonts.plusJakartaSans(fontSize: 13),
    decoration: _dec(hint));
  Widget _textarea(TextEditingController c, String hint) => TextField(controller: c, maxLines: 3,
    style: GoogleFonts.plusJakartaSans(fontSize: 13),
    decoration: _dec(hint));
  InputDecoration _dec(String hint) => InputDecoration(hintText: hint,
    hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.slate),
    filled: true, fillColor: AppTheme.mist, isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: AppTheme.fog)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: AppTheme.fog)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: AppTheme.purple)));
}

// ═══════════════════════════════════
// MANAGE USERS SCREEN
// ═══════════════════════════════════
class ManageUsersScreen extends StatelessWidget {
  const ManageUsersScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(backgroundColor: AppTheme.ink, title: const Text('Manage Users'),
      leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context))),
    body: const _AddUserForm(),
  );
}
class _AddUserForm extends StatefulWidget {
  const _AddUserForm();
  @override State<_AddUserForm> createState() => _AddUserFormState();
}
class _AddUserFormState extends State<_AddUserForm> {
  final _nameCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _linkedCtrl  = TextEditingController();
  final _classCtrl   = TextEditingController();
  String _role = 'student';
  bool _saving = false;

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppTheme.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.fog)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Add New User', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 14),
        Row(children: ['student','teacher','parent'].map((r) => Expanded(child: Padding(
          padding: const EdgeInsets.only(right: 6),
          child: GestureDetector(
            onTap: () => setState(() => _role = r),
            child: Container(padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: _role == r ? AppTheme.ink : AppTheme.mist,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _role == r ? AppTheme.ink : AppTheme.fog)),
              child: Center(child: Text(r[0].toUpperCase() + r.substring(1),
                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600,
                  color: _role == r ? Colors.white : AppTheme.ink3)))),
          ),
        ))).toList()),
        const SizedBox(height: 12),
        _fi('Full Name', _nameCtrl, 'e.g. Ahmad bin Ali'),
        _fi('Email', _emailCtrl, 'user@email.com'),
        _fi('Password', _passCtrl, 'Set a password'),
        _fi('Linked Student Name', _linkedCtrl, 'Same name as in lesson logs'),
        _fi('Class', _classCtrl, 'e.g. Form 4'),
        const SizedBox(height: 4),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.purple, foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          child: Text(_saving ? 'Adding...' : '💾 Add User to Firebase',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        )),
      ])),
    const SizedBox(height: 12),
    Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppTheme.blueBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFBAE6FD))),
      child: Text('💡 Once added, the user can immediately log in with their email and password.\nFor students/parents, set Linked Student Name to match exactly how the name appears in lesson logs.',
        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF0369A1), height: 1.6))),
  ]);

  Widget _fi(String label, TextEditingController ctrl, String hint) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label.toUpperCase(), style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.slate, letterSpacing: 0.6)),
    const SizedBox(height: 4),
    TextField(controller: ctrl, style: GoogleFonts.plusJakartaSans(fontSize: 13),
      decoration: InputDecoration(hintText: hint, hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.slate),
        filled: true, fillColor: AppTheme.mist, isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.fog)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.fog)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.purple)))),
    const SizedBox(height: 10),
  ]);

  Future<void> _save() async {
    if (_nameCtrl.text.isEmpty || _emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill name, email and password.')));
      return;
    }
    setState(() => _saving = true);
    try {
      await FirebaseService.addUser(AppUser(uid: '', email: _emailCtrl.text, name: _nameCtrl.text,
        role: _role, linkedStudent: _linkedCtrl.text, studentClass: _classCtrl.text), _passCtrl.text);
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ User added!'))); _nameCtrl.clear(); _emailCtrl.clear(); _passCtrl.clear(); _linkedCtrl.clear(); _classCtrl.clear(); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    if (mounted) setState(() => _saving = false);
  }
}

// ═══════════════════════════════════
// STUDENT DETAIL SCREEN (teacher drill-down)
// ═══════════════════════════════════
class StudentDetailScreen extends StatefulWidget {
  final String studentName;
  final AppUser user;
  const StudentDetailScreen({super.key, required this.studentName, required this.user});
  @override State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}
class _StudentDetailScreenState extends State<StudentDetailScreen> {
  List<LessonLog> _logs = [];
  bool _loading = true;
  String _subj = 'All';

  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final l = await FirebaseService.getLogs(studentName: widget.studentName);
    if (mounted) setState(() { _logs = l; _loading = false; });
  }

  List<LessonLog> get _filtered => _subj == 'All' ? _logs : _logs.where((l) => l.subject == _subj).toList();
  List<String> get _subjects => ['All', ..._logs.map((l) => l.subject).toSet().toList()..sort()];

  @override
  Widget build(BuildContext context) {
    final doneCount = _logs.where((l) => l.isDone).length;
    final late      = _logs.where((l) => l.isLate).length;
    final hwMiss    = _logs.where((l) => l.homeworkMissed).length;
    final subjects  = _logs.map((l) => l.subject).toSet().toList();

    return Scaffold(
      appBar: AppBar(backgroundColor: AppTheme.ink, title: Text(widget.studentName),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context))),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(padding: const EdgeInsets.all(14), children: [
          StudentHeroCard(name: widget.studentName, meta: 'Individual Progress Report · Firebase',
            chips: ['${subjects.length} Subjects', '${_logs.length} Lessons']),
          const SizedBox(height: 12),
          GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 9, crossAxisSpacing: 9, childAspectRatio: 1.8,
            children: [
              StatCard(label: 'Lessons', value: '${_logs.length}'),
              StatCard(label: 'Completed', value: '$doneCount', valueColor: AppTheme.green),
              StatCard(label: 'Late', value: '$late', valueColor: AppTheme.amber),
              StatCard(label: 'HW Issues', value: '$hwMiss', valueColor: AppTheme.red),
            ]),
          const SizedBox(height: 12),
          if (subjects.isNotEmpty) SectionCard(
            title: 'Progress by Subject',
            child: Column(children: subjects.map((s) {
              final cnt  = _logs.where((l) => l.subject == s).length;
              final comp = _logs.where((l) => l.subject == s && l.isDone).length;
              return SubjectProgressRow(subject: s, completed: comp, total: cnt);
            }).toList()),
          ),
          SectionCard(
            title: 'Lesson Records',
            child: Column(children: [
              SizedBox(height: 32, child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _subjects.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) {
                  final s = _subjects[i]; final active = s == _subj;
                  return GestureDetector(
                    onTap: () => setState(() => _subj = s),
                    child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: active ? AppTheme.ink : AppTheme.white,
                        border: Border.all(color: active ? AppTheme.ink : AppTheme.fog),
                        borderRadius: BorderRadius.circular(20)),
                      child: Text(s, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: active ? Colors.white : AppTheme.ink3))),
                  );
                },
              )),
              const SizedBox(height: 10),
              ..._filtered.map((l) => LessonLogCard(log: l)),
            ]),
          ),
        ]),
    );
  }
}
