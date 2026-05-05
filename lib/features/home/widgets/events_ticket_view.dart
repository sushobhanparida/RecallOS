import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/extracted_entity.dart';
import '../../../core/models/screenshot_model.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../shared/widgets/empty_state.dart';

/// Wallet-style ticket cards. Each card has:
/// - A square thumbnail on the left (poster / boarding pass / cinema artwork)
/// - A perforated divider with notch cutouts
/// - A right-hand info column with date / flight / venue / movie metadata
class EventsTicketView extends StatelessWidget {
  final List<Screenshot> screenshots;
  final ValueChanged<Screenshot> onOpen;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const EventsTicketView({
    super.key,
    required this.screenshots,
    required this.onOpen,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    if (screenshots.isEmpty) {
      return const EmptyState(
        icon: Icons.confirmation_number_outlined,
        title: 'No tickets yet',
        subtitle: 'Boarding passes, movie tickets, and event invites land here',
      );
    }

    return ListView.separated(
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
      itemCount: screenshots.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, i) => _TicketCard(
        screenshot: screenshots[i],
        onTap: () => onOpen(screenshots[i]),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final Screenshot screenshot;
  final VoidCallback onTap;

  const _TicketCard({required this.screenshot, required this.onTap});

  _TicketKind get _kind {
    final types = screenshot.entities.map((e) => e.type).toSet();
    if (types.contains('flight')) return _TicketKind.flight;
    final lower = screenshot.extractedText.toLowerCase();
    if (RegExp(r'\b(cinema|movie|imax|inox|pvr|screening|now showing)\b')
        .hasMatch(lower)) {
      return _TicketKind.movie;
    }
    if (RegExp(r'\b(concert|festival|tour|live|show)\b').hasMatch(lower)) {
      return _TicketKind.concert;
    }
    return _TicketKind.generic;
  }

  Color get _accent {
    switch (_kind) {
      case _TicketKind.flight:
        return AppColors.tagLink;
      case _TicketKind.movie:
        return AppColors.tagShopping;
      case _TicketKind.concert:
        return AppColors.tagEvent;
      case _TicketKind.generic:
        return AppColors.tagEvent;
    }
  }

  IconData get _icon {
    switch (_kind) {
      case _TicketKind.flight:
        return Icons.flight_takeoff_rounded;
      case _TicketKind.movie:
        return Icons.movie_rounded;
      case _TicketKind.concert:
        return Icons.music_note_rounded;
      case _TicketKind.generic:
        return Icons.confirmation_number_rounded;
    }
  }

  String get _kindLabel {
    switch (_kind) {
      case _TicketKind.flight:
        return 'Boarding pass';
      case _TicketKind.movie:
        return 'Movie ticket';
      case _TicketKind.concert:
        return 'Live event';
      case _TicketKind.generic:
        return 'Ticket';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: 140,
        child: Stack(
          children: [
            // Card body
            Positioned.fill(
              child: ClipPath(
                clipper: _TicketClipper(),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.bgSurface,
                        AppColors.bgElevated,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      // Thumbnail strip
                      SizedBox(
                        width: 110,
                        child: _Thumb(uri: screenshot.uri),
                      ),
                      // Perforation line — sits visually over the clip notch
                      _Perforation(color: _accent.withValues(alpha: 0.3)),
                      // Info
                      Expanded(child: _TicketInfo(
                        screenshot: screenshot,
                        accent: _accent,
                        kindIcon: _icon,
                        kindLabel: _kindLabel,
                      )),
                    ],
                  ),
                ),
              ),
            ),
            // Outer border that follows the clip path
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _TicketBorderPainter(
                      color: AppColors.borderDefault),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _TicketKind { flight, movie, concert, generic }

class _TicketInfo extends StatelessWidget {
  final Screenshot screenshot;
  final Color accent;
  final IconData kindIcon;
  final String kindLabel;

  const _TicketInfo({
    required this.screenshot,
    required this.accent,
    required this.kindIcon,
    required this.kindLabel,
  });

  ExtractedEntity? _firstOf(String type) {
    for (final e in screenshot.entities) {
      if (e.type == type) return e;
    }
    return null;
  }

  String _title() {
    final flight = _firstOf('flight');
    if (flight != null) {
      final airline = (flight.value?['airline'] as String?)?.trim() ?? '';
      final number = (flight.value?['number'] as String?)?.trim() ?? '';
      if (airline.isNotEmpty || number.isNotEmpty) return '$airline $number'.trim();
    }
    // Fall back: first non-empty line of OCR text, capped.
    final firstLine = screenshot.extractedText
        .split('\n')
        .map((l) => l.trim())
        .firstWhere((l) => l.isNotEmpty, orElse: () => kindLabel);
    return firstLine.length > 40
        ? '${firstLine.substring(0, 40)}…'
        : firstLine;
  }

  String? _dateLine() {
    final date = _firstOf('date');
    if (date == null) return null;
    final ts = date.value?['timestamp'] as int?;
    if (ts != null) {
      final dt = DateTime.fromMillisecondsSinceEpoch(ts);
      return DateFormat('EEE, MMM d · HH:mm').format(dt);
    }
    return date.rawText;
  }

  String? _venueLine() {
    final addr = _firstOf('address');
    if (addr != null) return addr.rawText;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final dateLine = _dateLine();
    final venueLine = _venueLine();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top — kind tag
          Row(
            children: [
              Icon(kindIcon, size: 12, color: accent),
              const SizedBox(width: 6),
              Text(
                kindLabel.toUpperCase(),
                style: AppTypography.monoSm.copyWith(
                  color: accent,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          // Middle — title
          Text(
            _title(),
            style: AppTypography.headingSm
                .copyWith(color: AppColors.textPrimary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          // Bottom — date / venue rows
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (dateLine != null)
                _MetaRow(icon: Icons.event_rounded, text: dateLine),
              if (venueLine != null) ...[
                const SizedBox(height: 4),
                _MetaRow(
                    icon: Icons.location_on_outlined, text: venueLine),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 11, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: AppTypography.labelSm
                .copyWith(color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _Perforation extends StatelessWidget {
  final Color color;
  const _Perforation({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 1,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(11, (i) {
          return Container(
            width: 1,
            height: 4,
            color: i.isEven ? color : Colors.transparent,
          );
        }),
      ),
    );
  }
}

/// Clips the card with two semicircular notches on the perforation seam,
/// giving the wallet-style ticket silhouette.
class _TicketClipper extends CustomClipper<Path> {
  static const _radius = 8.0;
  static const _splitAt = 110.0;
  static const _cornerRadius = 14.0;

  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    final cr = _cornerRadius;

    // Start top-left
    path.moveTo(cr, 0);
    path.lineTo(_splitAt - _radius, 0);
    path.arcToPoint(
      Offset(_splitAt + _radius, 0),
      radius: const Radius.circular(_radius),
      clockwise: false,
    );
    path.lineTo(w - cr, 0);
    path.arcToPoint(Offset(w, cr), radius: Radius.circular(cr));
    path.lineTo(w, h - cr);
    path.arcToPoint(Offset(w - cr, h), radius: Radius.circular(cr));
    path.lineTo(_splitAt + _radius, h);
    path.arcToPoint(
      Offset(_splitAt - _radius, h),
      radius: const Radius.circular(_radius),
      clockwise: false,
    );
    path.lineTo(cr, h);
    path.arcToPoint(Offset(0, h - cr), radius: Radius.circular(cr));
    path.lineTo(0, cr);
    path.arcToPoint(Offset(cr, 0), radius: Radius.circular(cr));
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _TicketBorderPainter extends CustomPainter {
  final Color color;
  _TicketBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final clipPath = _TicketClipper().getClip(size);
    canvas.drawPath(clipPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Thumb extends StatelessWidget {
  final String uri;
  const _Thumb({required this.uri});

  @override
  Widget build(BuildContext context) {
    if (uri.startsWith('http')) {
      return Image.network(uri,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              Container(color: AppColors.bgElevated));
    }
    return Image.file(File(uri),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            Container(color: AppColors.bgElevated));
  }
}
