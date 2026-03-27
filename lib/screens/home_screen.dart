import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import 'login_screen.dart';
import 'logs_screen.dart';
import 'subjects_screen.dart';
import 'exams_screen.dart';
import 'notifs_screen.dart';
import 'add_entry_screen.dart';
import 'manage_users_screen.dart';
import 'student_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final AppUser user;
  const HomeScreen({super.key, required this.user});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  bool _loading = true;
  Map<String, dynamic> _stats = {};
  List<AppUser> _students = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final target = widget.user.role == 'teacher'
          ? null
          : (widget.user.linkedStudent.isNotEmpty ? widget.user.linkedStudent : widget.user.name);
      final stats = await FirebaseService.getDashboardStats(target);
      List<AppUser> students = [];
      if (widget.user.role == 'teacher') students = await FirebaseService.getStudents();
      if (mounted) setState(() { _stats = stats; _students = students; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _logout() async {
    await FirebaseService.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  void _showEditProfile() {
    final nameCtrl = TextEditingController(text: widget.user.name);
    final passCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Edit Profile', style: GoogleFonts.fraunces(fontSize: 18, fontWeight: FontWeight.w700)),
          content: Form(
            key: formKey,
            child: SizedBox(width: 360, child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Name required' : null,
              ),
              const SizedBox(height: 14),
              Text('Email: ${widget.user.email}',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.slate)),
              const SizedBox(height: 14),
              TextFormField(
                controller: passCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'New Password (optional)',
                  hintText: 'Leave blank to keep current',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                ),
                validator: (v) => v != null && v.isNotEmpty && v.length < 6
                  ? 'Min 6 characters' : null,
              ),
            ])),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: AppTheme.slate)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.purple,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: saving ? null : () async {
                if (!formKey.currentState!.validate()) return;
                setS(() => saving = true);
                try {
                  await FirebaseService.updateProfile(
                    uid: widget.user.uid,
                    name: nameCtrl.text.trim(),
                    newPassword: passCtrl.text.isNotEmpty ? passCtrl.text : null,
                  );
                  widget.user.name = nameCtrl.text.trim();
                  if (mounted) setState(() {});
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile updated!'), backgroundColor: Color(0xFF059669)),
                  );
                } catch (e) {
                  setS(() => saving = false);
                  if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              child: saving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text('Save', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  List<_NavItem> get _navItems => [
    _NavItem('Dashboard', Icons.dashboard_rounded, 0),
    _NavItem(widget.user.role == 'teacher' ? 'All Lessons' : 'My Log', Icons.list_alt_rounded, 1),
    _NavItem('By Subject', Icons.menu_book_rounded, 2),
    _NavItem('Exams', Icons.bar_chart_rounded, 3),
    _NavItem('Alerts', Icons.notifications_rounded, 4),
    if (widget.user.role == 'teacher')
      _NavItem('Add Entry', Icons.add_circle_outline_rounded, 5),
  ];

  Widget _buildPage() {
    switch (_tab) {
      case 1: return LogsScreen(user: widget.user);
      case 2: return SubjectsScreen(user: widget.user);
      case 3: return ExamsScreen(user: widget.user);
      case 4: return NotifsScreen(user: widget.user);
      case 5: return AddEntryScreen(user: widget.user);
      case 6: return const ManageUsersScreen();
      default: return _buildHome();
    }
  }

  Widget _buildHome() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return widget.user.role == 'teacher' ? _teacherHome() : _studentHome();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.mist,
    body: Row(children: [
      _buildSidebar(),
      Expanded(child: Column(children: [
        _buildTopBar(),
        Expanded(child: _buildPage()),
      ])),
    ]),
  );

  // ── SIDEBAR ──
  Widget _buildSidebar() => SizedBox(
    width: 220,
    child: Container(
    color: AppTheme.ink,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
        child: Row(children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(color: AppTheme.purple, borderRadius: BorderRadius.circular(7)),
            child: const Icon(Icons.school_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Text('EduTrack', style: GoogleFonts.fraunces(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: _badgeBg, borderRadius: BorderRadius.circular(10)),
            child: Text(widget.user.role.toUpperCase(),
              style: GoogleFonts.plusJakartaSans(fontSize: 8, fontWeight: FontWeight.w700, color: _badgeFg)),
          ),
        ]),
      ),
      Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
      const SizedBox(height: 16),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Text('MENU', style: GoogleFonts.plusJakartaSans(
          fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white38, letterSpacing: 1.5)),
      ),
      const SizedBox(height: 8),
      ..._navItems.map(_buildNavTile),
      const Spacer(),
    ]),
  ));

  Widget _buildNavTile(_NavItem item) {
    final selected = _tab == item.index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: InkWell(
        onTap: () => setState(() => _tab = item.index),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppTheme.blue.withValues(alpha: 0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(children: [
            Icon(item.icon,
              color: selected ? AppTheme.blue : Colors.white.withValues(alpha: 0.45), size: 17),
            const SizedBox(width: 10),
            Text(item.label, style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? Colors.white : Colors.white.withValues(alpha: 0.55),
            )),
          ]),
        ),
      ),
    );
  }

  // ── TOP BAR ──
  Widget _buildTopBar() => Container(
    height: 54,
    color: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 24),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xFFE8ECF4))),
    ),
    child: Row(children: [
      Text(_pageTitle, style: GoogleFonts.plusJakartaSans(
        fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.ink)),
      const Spacer(),
      if (widget.user.role == 'teacher') ...[
        TextButton.icon(
          onPressed: () => setState(() => _tab = 5),
          icon: const Icon(Icons.add, size: 15),
          label: Text('Add Entry', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600)),
          style: TextButton.styleFrom(foregroundColor: AppTheme.purple),
        ),
        const SizedBox(width: 8),
      ],
      PopupMenuButton(
        offset: const Offset(0, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        itemBuilder: (_) => [
          PopupMenuItem(
            onTap: _showEditProfile,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              const Icon(Icons.edit_rounded, size: 16, color: Color(0xFF6B7280)),
              const SizedBox(width: 10),
              Text('Edit Profile', style: GoogleFonts.plusJakartaSans(fontSize: 13)),
            ]),
          ),
          PopupMenuItem(
            onTap: _logout,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              Icon(Icons.logout_rounded, size: 16, color: AppTheme.red),
              const SizedBox(width: 10),
              Text('Logout', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.red)),
            ]),
          ),
        ],
        child: Row(children: [
          Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(widget.user.name, style: GoogleFonts.plusJakartaSans(
              fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.ink)),
            Text('${widget.user.role[0].toUpperCase()}${widget.user.role.substring(1)}',
              style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppTheme.slate)),
          ]),
          const SizedBox(width: 10),
          CircleAvatar(radius: 15, backgroundColor: _avatarBg,
            child: Text(AppTheme.initials(widget.user.name),
              style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white))),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF9CA3AF)),
        ]),
      ),
    ]),
  );

  String get _pageTitle {
    switch (_tab) {
      case 1: return widget.user.role == 'teacher' ? 'All Lessons' : 'My Lessons';
      case 2: return 'By Subject';
      case 3: return 'Exams';
      case 4: return 'Alerts';
      case 5: return 'Add Entry';
      case 6: return 'Manage Users';
      default: return 'Dashboard';
    }
  }

  // ── TEACHER HOME ──
  Widget _teacherHome() {
    final allLogs = (_stats['logs'] as List<LessonLog>?) ?? [];
    final logs = allLogs.where((l) => l.subject.isNotEmpty).toList();
    final total = logs.length;
    final done = logs.where((l) => l.isDone).length;
    final late = logs.where((l) => l.isLate).length;
    final hwDone = logs.where((l) => !l.homeworkMissed && l.homework.isNotEmpty).length;
    final hwTotal = logs.where((l) => l.homework.isNotEmpty).length;

    final subjectCounts = <String, int>{};
    final subjectLate = <String, int>{};
    for (final l in logs) {
      subjectCounts[l.subject] = (subjectCounts[l.subject] ?? 0) + 1;
      if (l.isLate) subjectLate[l.subject] = (subjectLate[l.subject] ?? 0) + 1;
    }
    final sortedSubjects = subjectCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final sortedLate = subjectLate.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final recentLogs = logs.reversed.take(5).toList();
    final maxSubj = subjectCounts.values.isEmpty ? 1 : subjectCounts.values.reduce((a, b) => a > b ? a : b);
    final maxLate = subjectLate.values.isEmpty ? 1 : subjectLate.values.reduce((a, b) => a > b ? a : b);

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Teacher Overview', style: GoogleFonts.fraunces(
            fontSize: 24, fontWeight: FontWeight.w700, color: AppTheme.ink)),
          const SizedBox(height: 4),
          Text('${_students.isNotEmpty ? _students.map((s) => s.name).join(", ") : "All Students"} · Form 4 KSSM · Academic Year 2025/2026',
            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.slate)),
          const SizedBox(height: 20),

          _statRow([
            _Stat('TOTAL LESSONS', '$total', 'Across all subjects', null, dark: true),
            _Stat('COMPLETED', '$done', '${total > 0 ? (done / total * 100).round() : 0}% completion rate', AppTheme.green),
            _Stat('LATE ARRIVALS', '$late', '${total > 0 ? (late / total * 100).round() : 0}% of lessons', AppTheme.amber),
            _Stat('HOMEWORK DONE', hwTotal > 0 ? '${(hwDone / hwTotal * 100).round()}%' : '—', '$hwDone/$hwTotal submitted', AppTheme.blue),
            _Stat('STUDENTS', '${_students.length}', 'Enrolled', AppTheme.purple),
          ]),
          const SizedBox(height: 20),

          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: _barCard('📊 Lessons Per Subject', sortedSubjects, maxSubj, AppTheme.subjectColor)),
            const SizedBox(width: 16),
            Expanded(child: _barCard('⏰ Late Arrivals by Subject', sortedLate, maxLate, (_) => AppTheme.amber,
              secondary: subjectCounts)),
          ]),
          const SizedBox(height: 20),

          _recentTable(recentLogs),
          const SizedBox(height: 20),

          // Student grid
          if (_students.isNotEmpty) _studentGrid(logs),
        ]),
      ),
    );
  }

  // ── STUDENT HOME ──
  Widget _studentHome() {
    final allLogs = (_stats['logs'] as List<LessonLog>?) ?? [];
    final logs = allLogs.where((l) => l.subject.isNotEmpty && l.date.isNotEmpty).toList();
    final subjects = logs.map((l) => l.subject).toSet().toList();
    final name = widget.user.linkedStudent.isNotEmpty ? widget.user.linkedStudent : widget.user.name;
    final total = logs.length;
    final done = logs.where((l) => l.isDone).length;
    final late = logs.where((l) => l.isLate).length;
    final hwMissed = logs.where((l) => l.homeworkMissed).length;
    final recentLogs = logs.reversed.take(5).toList();

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('My Progress', style: GoogleFonts.fraunces(
            fontSize: 24, fontWeight: FontWeight.w700, color: AppTheme.ink)),
          const SizedBox(height: 4),
          Text('$name · ${widget.user.studentClass.isNotEmpty ? widget.user.studentClass : "Form 4"} KSSM · Academic Year 2025/2026',
            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.slate)),
          const SizedBox(height: 20),

          _statRow([
            _Stat('TOTAL LESSONS', '$total', 'Across all subjects', null, dark: true),
            _Stat('COMPLETED', '$done', '${total > 0 ? (done / total * 100).round() : 0}% completion rate', AppTheme.green),
            _Stat('LATE ARRIVALS', '$late', '${total > 0 ? (late / total * 100).round() : 0}% of lessons', AppTheme.amber),
            _Stat('HW ISSUES', '$hwMissed', 'Missed submissions', AppTheme.red),
          ]),
          const SizedBox(height: 20),

          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: _subjectProgressCard(logs, subjects)),
            const SizedBox(width: 16),
            Expanded(child: _barCard('📊 Lessons Per Subject',
              subjects.map((s) => MapEntry(s, logs.where((l) => l.subject == s).length)).toList()
                ..sort((a, b) => b.value.compareTo(a.value)),
              subjects.isEmpty ? 1 : subjects.map((s) => logs.where((l) => l.subject == s).length).reduce((a, b) => a > b ? a : b),
              AppTheme.subjectColor)),
          ]),
          const SizedBox(height: 20),
          _recentTable(recentLogs),
        ]),
      ),
    );
  }

  // ── SHARED COMPONENTS ──

  Widget _statRow(List<_Stat> stats) => Row(
    children: stats.asMap().entries.map((e) {
      final s = e.value;
      final last = e.key == stats.length - 1;
      return Expanded(child: Padding(
        padding: EdgeInsets.only(right: last ? 0 : 12),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: s.dark ? const Color(0xFF1A2235) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.label, style: GoogleFonts.plusJakartaSans(
              fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8,
              color: s.dark ? Colors.white.withValues(alpha: 0.55) : AppTheme.slate)),
            const SizedBox(height: 8),
            Text(s.value, style: GoogleFonts.fraunces(
              fontSize: 32, fontWeight: FontWeight.w700,
              color: s.dark ? Colors.white : (s.color ?? AppTheme.ink))),
            const SizedBox(height: 4),
            Text(s.subtitle, style: GoogleFonts.plusJakartaSans(
              fontSize: 11, color: s.dark ? Colors.white.withValues(alpha: 0.45) : AppTheme.slate)),
          ]),
        ),
      ));
    }).toList(),
  );

  Widget _barCard(String title, List<MapEntry<String, int>> entries, int maxVal,
      Color Function(String) colorFn, {Map<String, int>? secondary}) =>
    Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.ink)),
        const SizedBox(height: 16),
        if (entries.isEmpty)
          Padding(padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(child: Text('No data', style: GoogleFonts.plusJakartaSans(color: AppTheme.slate))))
        else
          ...entries.take(6).map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              SizedBox(width: 90, child: Text(e.key,
                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.ink3),
                overflow: TextOverflow.ellipsis, textAlign: TextAlign.right)),
              const SizedBox(width: 10),
              Expanded(child: Stack(children: [
                Container(height: 18, decoration: BoxDecoration(color: AppTheme.fog, borderRadius: BorderRadius.circular(4))),
                FractionallySizedBox(
                  widthFactor: maxVal > 0 ? (e.value / maxVal).clamp(0.0, 1.0) : 0,
                  child: Container(height: 18,
                    decoration: BoxDecoration(color: colorFn(e.key), borderRadius: BorderRadius.circular(4))),
                ),
              ])),
              const SizedBox(width: 8),
              SizedBox(width: 40, child: Text(
                secondary != null ? '${e.value}/${secondary[e.key] ?? 0}' : '${e.value}',
                style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.ink3))),
            ]),
          )),
      ]),
    );

  Widget _recentTable(List<LessonLog> logs) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('📋 Recent Lessons', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.ink)),
        const Spacer(),
        Text('Last ${logs.length} entries', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.slate)),
      ]),
      const SizedBox(height: 12),
      if (logs.isEmpty)
        Padding(padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(child: Text('No lessons yet', style: GoogleFonts.plusJakartaSans(color: AppTheme.slate))))
      else
        ...logs.map((l) => LessonLogCard(log: l)),
    ]),
  );

  Widget _subjectProgressCard(List<LessonLog> logs, List<String> subjects) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('📚 Progress by Subject', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.ink)),
      const SizedBox(height: 16),
      if (subjects.isEmpty)
        Text('No data', style: GoogleFonts.plusJakartaSans(color: AppTheme.slate))
      else
        ...subjects.map((subj) {
          final cnt = logs.where((l) => l.subject == subj).length;
          final comp = logs.where((l) => l.subject == subj && l.isDone).length;
          return SubjectProgressRow(subject: subj, completed: comp, total: cnt);
        }),
    ]),
  );

  Widget _studentGrid(List<LessonLog> logs) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('👥 Students', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.ink)),
      const SizedBox(height: 16),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 180, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.5),
        itemCount: _students.length,
        itemBuilder: (_, i) {
          final s = _students[i];
          final sLogs = logs.where((l) => l.studentName.toLowerCase() == s.name.toLowerCase()).toList();
          final done = sLogs.where((l) => l.isDone).length;
          return InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => StudentDetailScreen(studentName: s.name, user: widget.user))),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.mist,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.fog),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                CircleAvatar(radius: 16, backgroundColor: AppTheme.avatarColor(s.name),
                  child: Text(AppTheme.initials(s.name),
                    style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white))),
                const SizedBox(height: 8),
                Text(s.name, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.ink),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('${sLogs.length} lessons · $done done',
                  style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppTheme.slate)),
              ]),
            ),
          );
        },
      ),
    ]),
  );

  Color get _badgeBg => widget.user.role == 'teacher'
    ? AppTheme.amber.withValues(alpha: 0.2)
    : widget.user.role == 'student'
      ? AppTheme.blue.withValues(alpha: 0.2)
      : AppTheme.purple.withValues(alpha: 0.2);

  Color get _badgeFg => widget.user.role == 'teacher'
    ? const Color(0xFFFBBF24)
    : widget.user.role == 'student'
      ? const Color(0xFF38BDF8)
      : const Color(0xFFC4B5FD);

  Color get _avatarBg => widget.user.role == 'teacher'
    ? AppTheme.amber
    : widget.user.role == 'student' ? AppTheme.blue : AppTheme.purple;
}

class _NavItem {
  final String label;
  final IconData icon;
  final int index;
  _NavItem(this.label, this.icon, this.index);
}

class _Stat {
  final String label, value, subtitle;
  final Color? color;
  final bool dark;
  const _Stat(this.label, this.value, this.subtitle, this.color, {this.dark = false});
}
