import '../../core/models/screenshot_model.dart';
import '../../core/models/task_model.dart';

class TaskPrefill {
  final String title;
  final DateTime? dueDate;
  final String? url;
  final String? amount;
  final TaskIntent intent;

  const TaskPrefill({
    required this.title,
    this.dueDate,
    this.url,
    this.amount,
    required this.intent,
  });

  static TaskPrefill fromScreenshot(Screenshot s) {
    final title = _extractTitle(s.extractedText);

    DateTime? dueDate;
    final dateEntity =
        s.entities.where((e) => e.type == 'date').firstOrNull;
    if (dateEntity != null) {
      final ts = dateEntity.value?['timestamp'] as int?;
      if (ts != null) dueDate = DateTime.fromMillisecondsSinceEpoch(ts);
    }

    final urlEntity = s.entities
        .where((e) => e.type == 'url' || e.type == 'qr_url')
        .firstOrNull;
    final url = urlEntity?.rawText;

    String? amount;
    final moneyEntity = s.entities
        .where((e) => e.type == 'money' || e.type == 'qr_payment')
        .firstOrNull;
    if (moneyEntity != null) {
      final a = moneyEntity.value?['amount'];
      final c = (moneyEntity.value?['currency'] as String?) ??
          (moneyEntity.value?['unnormalized_currency'] as String?) ??
          '';
      if (a != null) amount = '$c $a'.trim();
    }

    final intent = switch (s.tag) {
      ScreenshotTag.event => TaskIntent.event,
      ScreenshotTag.link => TaskIntent.visitLater,
      ScreenshotTag.qr => TaskIntent.payLater,
      ScreenshotTag.note => TaskIntent.readLater,
      ScreenshotTag.shopping => TaskIntent.buyLater,
    };

    return TaskPrefill(
      title: title,
      dueDate: dueDate,
      url: url,
      amount: amount,
      intent: intent,
    );
  }

  static String _extractTitle(String text) {
    if (text.isEmpty) return '';
    final firstLine = text.split('\n').firstWhere(
          (l) => l.trim().isNotEmpty,
          orElse: () => '',
        );
    final trimmed = firstLine.trim();
    return trimmed.length > 80 ? trimmed.substring(0, 80) : trimmed;
  }
}
