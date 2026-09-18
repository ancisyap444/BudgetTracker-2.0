// lib/core/services/export_service.dart
import 'package:intl/intl.dart';
import '../../data/models/models.dart';

class ExportService {
  /// Converts a list of transactions into a standard CSV string (RFC 4180 compliant).
  static String toCsv(List<TransactionModel> transactions) {
    final buffer = StringBuffer();
    // CSV Header
    buffer.writeln('ID,Date,Title,Type,Category,Amount,Note');

    final dateFmt = DateFormat('yyyy-MM-dd');

    for (final tx in transactions) {
      final id = _escape(tx.id);
      final date = dateFmt.format(tx.date);
      final title = _escape(tx.title);
      final type = tx.type;
      final category = _escape(tx.categoryName ?? 'Uncategorized');
      final amount = tx.amount.toStringAsFixed(2);
      final note = _escape(tx.note ?? '');

      buffer.writeln('$id,$date,$title,$type,$category,$amount,$note');
    }

    return buffer.toString();
  }

  /// Escapes CSV values to handle commas, newlines, quotes, and prevent CSV Formula Injection (CWE-1236)
  static String _escape(String value) {
    var v = value;
    if (v.isNotEmpty &&
        (v.startsWith('=') ||
            v.startsWith('+') ||
            v.startsWith('-') ||
            v.startsWith('@') ||
            v.startsWith('\t') ||
            v.startsWith('\r'))) {
      v = "'$v";
    }
    if (v.contains(',') || v.contains('"') || v.contains('\n')) {
      final escaped = v.replaceAll('"', '""');
      return '"$escaped"';
    }
    return v;
  }
}
