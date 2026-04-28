import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/extracted_entity.dart';
import '../models/screenshot_model.dart';

enum SmartActionKind { upiPay, openLink, wifi, contact, phone, email }

class SmartAction {
  final SmartActionKind kind;
  final String label; // CTA — "Open link", "Send Payment"
  final String title; // Card title — "What we owe the Future"
  final String subtitle; // "Book", "user@upi · ₹500"
  final IconData icon;
  final Screenshot screenshot;
  final ExtractedEntity entity;

  const SmartAction({
    required this.kind,
    required this.label,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.screenshot,
    required this.entity,
  });
}

class SmartActionsService {
  /// Builds a list of actions, most-recent first, capped at [limit].
  List<SmartAction> actionsFor(List<Screenshot> screenshots, {int limit = 8}) {
    final out = <SmartAction>[];
    final sorted = [...screenshots]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    for (final s in sorted) {
      for (final e in s.entities) {
        final action = _toAction(s, e);
        if (action != null) {
          out.add(action);
          if (out.length >= limit) return out;
        }
      }
    }
    return out;
  }

  SmartAction? _toAction(Screenshot s, ExtractedEntity e) {
    switch (e.type) {
      case 'qr_payment':
        final pa = (e.value?['pa'] as String?) ?? '';
        final pn = (e.value?['pn'] as String?) ?? '';
        final am = (e.value?['am'] as String?) ?? '';
        final title = pn.isNotEmpty
            ? pn
            : (pa.isNotEmpty ? pa : 'UPI payment');
        final subtitle = am.isNotEmpty
            ? '₹$am · ${pa.isEmpty ? "UPI QR" : pa}'
            : (pa.isNotEmpty ? pa : 'UPI QR detected');
        return SmartAction(
          kind: SmartActionKind.upiPay,
          label: 'Send Payment',
          title: title,
          subtitle: subtitle,
          icon: Icons.payments_rounded,
          screenshot: s,
          entity: e,
        );
      case 'qr_wifi':
        final ssid = (e.value?['ssid'] as String?) ?? '';
        return SmartAction(
          kind: SmartActionKind.wifi,
          label: 'Copy password',
          title: ssid.isNotEmpty ? ssid : 'Wi-Fi network',
          subtitle: 'Wi-Fi QR detected',
          icon: Icons.wifi_rounded,
          screenshot: s,
          entity: e,
        );
      case 'qr_url':
      case 'url':
        return SmartAction(
          kind: SmartActionKind.openLink,
          label: 'Open link',
          title: _titleFromUrl(e.rawText),
          subtitle: _subtitleFromUrl(e.rawText),
          icon: Icons.open_in_new_rounded,
          screenshot: s,
          entity: e,
        );
      case 'qr_contact':
        return SmartAction(
          kind: SmartActionKind.contact,
          label: 'Save contact',
          title: 'Contact card',
          subtitle: 'vCard QR detected',
          icon: Icons.person_add_rounded,
          screenshot: s,
          entity: e,
        );
      case 'qr_phone':
      case 'phone':
        return SmartAction(
          kind: SmartActionKind.phone,
          label: 'Call',
          title: e.rawText,
          subtitle: 'Phone number',
          icon: Icons.phone_rounded,
          screenshot: s,
          entity: e,
        );
      case 'qr_email':
      case 'email':
        return SmartAction(
          kind: SmartActionKind.email,
          label: 'Email',
          title: e.rawText,
          subtitle: 'Email address',
          icon: Icons.alternate_email_rounded,
          screenshot: s,
          entity: e,
        );
    }
    return null;
  }

  String _titleFromUrl(String url) {
    final u = Uri.tryParse(url);
    if (u == null) return url;
    var host = u.host.toLowerCase();
    if (host.startsWith('www.')) host = host.substring(4);
    final base = host.split('.').first;
    return base.isEmpty
        ? url
        : '${base[0].toUpperCase()}${base.substring(1)}';
  }

  String _subtitleFromUrl(String url) {
    final u = Uri.tryParse(url);
    if (u == null) return url;
    return u.host;
  }

  Future<void> execute(SmartAction a, BuildContext context) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      switch (a.kind) {
        case SmartActionKind.upiPay:
          await launchUrl(
            Uri.parse(a.entity.rawText),
            mode: LaunchMode.externalApplication,
          );
          break;
        case SmartActionKind.openLink:
          await launchUrl(
            Uri.parse(a.entity.rawText),
            mode: LaunchMode.externalApplication,
          );
          break;
        case SmartActionKind.wifi:
          final pw = (a.entity.value?['password'] as String?) ?? '';
          await Clipboard.setData(ClipboardData(text: pw));
          messenger?.showSnackBar(const SnackBar(
            content: Text('Wi-Fi password copied'),
            duration: Duration(seconds: 2),
          ));
          break;
        case SmartActionKind.contact:
          await Clipboard.setData(ClipboardData(text: a.entity.rawText));
          messenger?.showSnackBar(const SnackBar(
            content: Text('Contact copied'),
            duration: Duration(seconds: 2),
          ));
          break;
        case SmartActionKind.phone:
          final tel = a.entity.rawText.replaceAll(RegExp(r'\s+'), '');
          await launchUrl(Uri.parse('tel:$tel'));
          break;
        case SmartActionKind.email:
          await launchUrl(Uri.parse('mailto:${a.entity.rawText}'));
          break;
      }
    } catch (_) {
      messenger?.showSnackBar(const SnackBar(
        content: Text("Couldn't run that action"),
        duration: Duration(seconds: 2),
      ));
    }
  }
}
