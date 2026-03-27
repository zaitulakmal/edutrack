import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';

String _formatDate(String raw) {
  if (raw.isEmpty) return '';
  try {
    final d = DateTime.parse(raw);
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  } catch (_) {
    return raw; // already formatted like "5 Januari 2026", keep as-is
  }
}

// ── Stat Card ──
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final Color? valueColor;
  final IconData? icon;

  const StatCard({super.key, required this.label, required this.value, this.subtitle, this.valueColor, this.icon});

  @override
  Widget build(BuildContext context) {
    final color = valueColor ?? AppTheme.purple;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon ?? Icons.star_rounded, color: color, size: 16),
        ),
        const Spacer(),
        Text(value,
          style: GoogleFonts.fraunces(fontSize: 26, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 2),
        Text(label,
          style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: color.withValues(alpha: 0.75))),
        if (subtitle != null)
          Text(subtitle!,
            style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: color.withValues(alpha: 0.6))),
      ]),
    );
  }
}

// ── Hero Card (student profile) ──
class StudentHeroCard extends StatelessWidget {
  final String name;
  final String meta;
  final List<String> chips;

  const StudentHeroCard({super.key, required this.name, required this.meta, this.chips = const []});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppTheme.ink, AppTheme.ink2],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(children: [
      CircleAvatar(
        radius: 26,
        backgroundColor: AppTheme.avatarColor(name),
        child: Text(AppTheme.initials(name),
          style: GoogleFonts.fraunces(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name, style: GoogleFonts.fraunces(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
        Text(meta, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.slate)),
        if (chips.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(spacing: 6, children: chips.map((c) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(c, style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.8))),
          )).toList()),
        ],
      ])),
    ]),
  );
}

// ── Progress Bar Row ──
class SubjectProgressRow extends StatelessWidget {
  final String subject;
  final int completed;
  final int total;

  const SubjectProgressRow({super.key, required this.subject, required this.completed, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? completed / total : 0.0;
    final color = AppTheme.subjectColor(subject);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Text('${AppTheme.subjectIcon(subject)} ', style: const TextStyle(fontSize: 14)),
        SizedBox(width: 80, child: Text(subject,
          style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.ink3),
          overflow: TextOverflow.ellipsis)),
        const SizedBox(width: 8),
        Expanded(child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct, minHeight: 7,
            backgroundColor: AppTheme.fog,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        )),
        const SizedBox(width: 8),
        SizedBox(width: 32, child: Text('${(pct * 100).round()}%',
          style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: color),
          textAlign: TextAlign.right)),
      ]),
    );
  }
}

// ── Lesson Log Card ──
class LessonLogCard extends StatefulWidget {
  final LessonLog log;
  const LessonLogCard({super.key, required this.log});

  @override
  State<LessonLogCard> createState() => _LessonLogCardState();
}

class _LessonLogCardState extends State<LessonLogCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l = widget.log;
    final color = AppTheme.subjectColor(l.subject);
    final isDone = l.isDone;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.fog),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        InkWell(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 7, height: 7, margin: const EdgeInsets.only(top: 5),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_formatDate(l.date), style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.slate)),
                const SizedBox(height: 2),
                RichText(text: TextSpan(children: [
                  TextSpan(text: l.subject,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
                  if (l.teacher.isNotEmpty)
                    TextSpan(text: ' · ${l.teacher}',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.slate)),
                ])),
                if (l.topic.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(l.topic,
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.ink3),
                    maxLines: _expanded ? 10 : 2,
                    overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis),
                ],
                const SizedBox(height: 6),
                Wrap(spacing: 5, children: [
                  _pill(l.progress.isEmpty ? '—' : l.progress,
                    isDone ? AppTheme.greenBg : AppTheme.amberBg,
                    isDone ? AppTheme.green   : AppTheme.amber),
                  if (l.homework.isNotEmpty)
                    _pill('📝 HW', AppTheme.blueBg, AppTheme.blue),
                ]),
              ])),
              Icon(_expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: AppTheme.slate, size: 18),
            ]),
          ),
        ),
        if (_expanded) _buildBody(l),
      ]),
    );
  }

  Widget _pill(String text, Color bg, Color fg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    child: Text(text, style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
  );

  Widget _buildBody(LessonLog l) => Container(
    padding: const EdgeInsets.fromLTRB(29, 0, 12, 12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (l.observations.isNotEmpty) ...[
        _sectionLabel('Observations'),
        Text(l.observations, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.ink3, height: 1.6)),
        const SizedBox(height: 8),
      ],
      if (l.homework.isNotEmpty) ...[
        _sectionLabel('Homework Assigned'),
        Text(l.homework, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.ink3, height: 1.6)),
        const SizedBox(height: 8),
      ],
      if (l.followUp.isNotEmpty)
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.mist,
            borderRadius: BorderRadius.circular(8),
            border: const Border(left: BorderSide(color: AppTheme.purple, width: 3)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('↩ NEXT CLASS', style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.purple, letterSpacing: 0.8)),
            const SizedBox(height: 2),
            Text(l.followUp, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.ink3)),
          ]),
        ),
    ]),
  );

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 3),
    child: Text(text.toUpperCase(),
      style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.slate, letterSpacing: 0.8)),
  );
}

// ── Subject Card ──
class SubjectCard extends StatelessWidget {
  final String subject;
  final List<String> teachers;
  final int total;
  final int completed;
  final VoidCallback? onTap;

  const SubjectCard({super.key, required this.subject, required this.teachers,
    required this.total, required this.completed, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.subjectColor(subject);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.fog),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(AppTheme.subjectIcon(subject), style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 8),
          Text(subject, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          if (teachers.isNotEmpty)
            Text(teachers.take(2).join(', '),
              style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppTheme.slate),
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Text('$total', style: GoogleFonts.fraunces(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
          Text('lessons · $completed done',
            style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w600, color: AppTheme.slate, letterSpacing: 0.5)),
        ]),
      ),
    );
  }
}

// ── Notification Card ──
class NotifCard extends StatelessWidget {
  final Color dotColor;
  final String title;
  final String body;
  final String time;

  const NotifCard({super.key, required this.dotColor, required this.title, required this.body, required this.time});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppTheme.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppTheme.fog),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 8, height: 8, margin: const EdgeInsets.only(top: 4),
        decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
      ),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.ink)),
        const SizedBox(height: 2),
        Text(body, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.slate, height: 1.5)),
        const SizedBox(height: 3),
        Text(time, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: const Color(0xFFC0C8D4))),
      ])),
    ]),
  );
}

// ── Section Card wrapper ──
class SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final EdgeInsets? padding;

  const SectionCard({super.key, required this.title, required this.child, this.padding});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: AppTheme.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppTheme.fog),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.ink)),
      ),
      Padding(padding: padding ?? const EdgeInsets.fromLTRB(16, 0, 16, 14), child: child),
    ]),
  );
}
