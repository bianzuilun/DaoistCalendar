import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';

String weekdayCN(DateTime date) => '星期${'一二三四五六日'[date.weekday - 1]}';

Color categoryColor(String category) =>
    Color(categoryColors[category] ?? 0xFF8A857A);

Color groupColor(String id) {
  switch (id) {
    case 'shengdan':
      return categoryColor('神诞');
    case 'xiajiang':
      return categoryColor('下降');
    case 'jiuhuang':
      return const Color(0xFF2C3E5A);
    case 'zhaijie':
      return categoryColor('斋戒');
    case 'jiehui':
      return categoryColor('节会');
    default:
      return categoryColor('纪事');
  }
}

class PaperCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;

  const PaperCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: T.cardShadow,
      ),
      child: Material(
        color: T.card,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: T.line),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const PageHeader({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: T.title),
          const SizedBox(height: 6),
          Text(subtitle, style: T.bodyMuted),
        ],
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 2, 4, 8),
      child: Text(text, style: T.section),
    );
  }
}

/// 朱文小印，取名号首字。
class SealMark extends StatelessWidget {
  final String text;
  final double size;

  const SealMark(this.text, {super.key, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final glyph = text.isEmpty ? '经' : String.fromCharCode(text.runes.first);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: T.accent, width: 1.3),
      ),
      child: Text(
        glyph,
        style: TextStyle(
          fontSize: size * 0.46,
          height: 1,
          color: T.accent,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class DaoYearSeal extends StatelessWidget {
  final int year;
  const DaoYearSeal({super.key, required this.year});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SealMark('道', size: 46),
        const SizedBox(height: 6),
        SizedBox(
          width: 52,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              daoYearCN(year),
              style: const TextStyle(
                fontSize: 11,
                height: 1.1,
                color: T.accent,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class Pillar extends StatelessWidget {
  final String label;
  final String value;

  const Pillar({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: T.paper.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              height: 1.1,
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
              color: T.ink,
            ),
          ),
          const SizedBox(height: 3),
          Text(label, style: T.caption),
        ],
      ),
    );
  }
}

class JieQiTag extends StatelessWidget {
  final String text;
  const JieQiTag(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: T.jieqiBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          height: 1.2,
          color: T.jieqi,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class EventTile extends StatelessWidget {
  final DaoEvent event;

  const EventTile({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final color = categoryColor(event.category);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.name,
            style: const TextStyle(fontSize: 14, height: 1.35, color: T.ink),
          ),
          const SizedBox(height: 2),
          Text(
            event.category,
            style: TextStyle(
              fontSize: 11,
              height: 1.2,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class InkRule extends StatelessWidget {
  const InkRule({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(height: 1, thickness: 0.6, color: T.line)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                border: Border.all(color: T.accent.withValues(alpha: 0.75)),
              ),
            ),
          ),
        ),
        const Expanded(child: Divider(height: 1, thickness: 0.6, color: T.line)),
      ],
    );
  }
}

class RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const RoundIconButton({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: T.paperDeep,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 22, color: T.ink),
        ),
      ),
    );
  }
}

class DaoNavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;

  const DaoNavBar({super.key, required this.index, required this.onChanged});

  static const _items = <({IconData icon, IconData selected, String label})>[
    (icon: Icons.calendar_month_outlined, selected: Icons.calendar_month, label: '日历'),
    (icon: Icons.menu_book_outlined, selected: Icons.menu_book, label: '经典'),
    (icon: Icons.notifications_outlined, selected: Icons.notifications, label: '提醒'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Material(
      color: T.card,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: T.line)),
        ),
        padding: EdgeInsets.only(top: 4, bottom: bottom > 0 ? bottom : 8),
        child: Row(
          children: [
            for (var i = 0; i < _items.length; i++)
              Expanded(
                child: InkWell(
                  onTap: () => onChanged(i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          width: index == i ? 16 : 0,
                          height: 2.5,
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: T.accent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Icon(
                          index == i ? _items[i].selected : _items[i].icon,
                          size: 22,
                          color: index == i ? T.accent : T.muted,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _items[i].label,
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.1,
                            fontWeight: index == i ? FontWeight.w600 : FontWeight.w500,
                            color: index == i ? T.accent : T.muted,
                          ),
                        ),
                      ],
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
