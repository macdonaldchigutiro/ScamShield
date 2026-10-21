import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/entities/incident_record.dart';
import 'platform_download.dart';

/// Builds and downloads a professional ScamShield incident report as a PDF.
///
/// PDF creation is deliberately separate from platform download. That keeps
/// the report reusable for future email/share/upload features and avoids
/// forcing browser-specific code into the domain or presentation layers.
class IncidentPdfExportService {
  const IncidentPdfExportService();

  Future<String> export(IncidentRecord incident) async {
    final bytes = await buildPdf(incident);
    final fileName = 'ScamShield_${_safeFileName(incident.id)}.pdf';

    await downloadBytes(
      bytes: bytes,
      fileName: fileName,
      mimeType: 'application/pdf',
    );

    return fileName;
  }

  /// Generates the report bytes independently from saving/downloading them.
  Future<Uint8List> buildPdf(IncidentRecord incident) async {
    final document = pw.Document(
      title: 'ScamShield Incident Report - ${incident.id}',
      author: 'ScamShield',
      subject: incident.category,
    );

    final accent = _accentFor(incident);
    const navy = PdfColor.fromInt(0xFF0F172A);
    const muted = PdfColor.fromInt(0xFF64748B);
    const light = PdfColor.fromInt(0xFFF8FAFC);
    const border = PdfColor.fromInt(0xFFE2E8F0);

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(34),
        header: (_) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 9),
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: border, width: 0.8)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'SCAMSHIELD',
                    style: pw.TextStyle(
                      color: navy,
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  pw.Text(
                    'DIGITAL FRAUD DEFENCE',
                    style: const pw.TextStyle(color: muted, fontSize: 7.5),
                  ),
                ],
              ),
              pw.Text(
                'INCIDENT REPORT',
                style: pw.TextStyle(
                  color: accent,
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(incident.id,
                style: const pw.TextStyle(color: muted, fontSize: 7)),
            pw.Text('Page ${context.pageNumber} of ${context.pagesCount}',
                style: const pw.TextStyle(color: muted, fontSize: 7)),
          ],
        ),
        build: (_) => [
          pw.SizedBox(height: 18),
          pw.Text(
            incident.category,
            style: pw.TextStyle(
              color: navy,
              fontSize: 23,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: light,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: border),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 72,
                  padding: const pw.EdgeInsets.symmetric(vertical: 10),
                  decoration: pw.BoxDecoration(
                    color: accent,
                    borderRadius: pw.BorderRadius.circular(7),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        '${incident.riskScore}',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 26,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text('RISK / 100',
                          style: const pw.TextStyle(
                              color: PdfColors.white, fontSize: 7)),
                    ],
                  ),
                ),
                pw.SizedBox(width: 14),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _meta('Incident ID', incident.id),
                      _meta('Created', _formatDateTime(incident.createdAt)),
                      _meta('Status', _statusLabel(incident.status)),
                      _meta('Source', incident.sourceLabel),
                      if (incident.sender.isNotEmpty)
                        _meta('Sender / account', incident.sender),
                      if (incident.amount != null)
                        _meta('Amount involved', incident.amount!.toStringAsFixed(2)),
                      if ((incident.transactionReference ?? '').isNotEmpty)
                        _meta('Transaction / case reference',
                            incident.transactionReference!),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 18),
          _heading('EVIDENCE / CONTENT', accent),
          _card(incident.content.isEmpty ? 'Not recorded.' : incident.content),
          pw.SizedBox(height: 14),
          _heading('WHY SCAMSHIELD FLAGGED IT', accent),
          if (incident.reasons.isEmpty)
            _card('No detailed warning reasons were recorded.')
          else
            ...incident.reasons.map(
              (reason) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 7),
                child: pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: light,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: border),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(reason.title,
                          style: pw.TextStyle(
                              color: navy,
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 3),
                      pw.Text(reason.explanation,
                          style: const pw.TextStyle(
                              color: muted, fontSize: 9, lineSpacing: 2)),
                    ],
                  ),
                ),
              ),
            ),
          pw.SizedBox(height: 10),
          _heading('RECOMMENDED ACTIONS', accent),
          if (incident.recommendedActions.isEmpty)
            _card('No recommended actions were recorded.')
          else
            for (var i = 0; i < incident.recommendedActions.length; i++)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: 18,
                      height: 18,
                      alignment: pw.Alignment.center,
                      decoration: pw.BoxDecoration(
                        color: accent,
                        shape: pw.BoxShape.circle,
                      ),
                      child: pw.Text('${i + 1}',
                          style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Expanded(
                      child: pw.Text(incident.recommendedActions[i],
                          style: const pw.TextStyle(
                              color: navy, fontSize: 9.5, lineSpacing: 2)),
                    ),
                  ],
                ),
              ),
          if (incident.notes.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            _heading('USER NOTES / ACTIONS TAKEN', accent),
            _card(incident.notes),
          ],
          pw.SizedBox(height: 16),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFFFF7ED),
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(
                color: const PdfColor.fromInt(0xFFFED7AA),
              ),
            ),
            child: pw.Text(
              'Important: This report is generated by ScamShield from locally saved investigation evidence. It is decision support and is not a police, bank, telecom or official case reference. Keep original messages, screenshots, receipts and transaction records where available.',
              style: const pw.TextStyle(
                color: PdfColor.fromInt(0xFF9A3412),
                fontSize: 8,
                lineSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );

    return document.save();
  }

  pw.Widget _meta(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 105,
            child: pw.Text(label,
                style: pw.TextStyle(
                    color: const PdfColor.fromInt(0xFF475569),
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold)),
          ),
          pw.Expanded(
            child: pw.Text(value,
                style: const pw.TextStyle(
                    color: PdfColor.fromInt(0xFF0F172A), fontSize: 8.5)),
          ),
        ],
      ),
    );
  }

  pw.Widget _heading(String value, PdfColor accent) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 7),
        child: pw.Text(value,
            style: pw.TextStyle(
                color: accent,
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 1.2)),
      );

  pw.Widget _card(String value) => pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(11),
        decoration: pw.BoxDecoration(
          color: const PdfColor.fromInt(0xFFF8FAFC),
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: const PdfColor.fromInt(0xFFE2E8F0)),
        ),
        child: pw.Text(value,
            style: const pw.TextStyle(
                color: PdfColor.fromInt(0xFF0F172A),
                fontSize: 9.5,
                lineSpacing: 2)),
      );

  PdfColor _accentFor(IncidentRecord incident) {
    switch (incident.verdict.name) {
      case 'highRisk':
        return const PdfColor.fromInt(0xFFE11D48);
      case 'suspicious':
        return const PdfColor.fromInt(0xFFF59E0B);
      default:
        return const PdfColor.fromInt(0xFF10B981);
    }
  }

  String _statusLabel(IncidentStatus status) {
    switch (status) {
      case IncidentStatus.reviewing:
        return 'Reviewing';
      case IncidentStatus.actionRequired:
        return 'Action required';
      case IncidentStatus.reported:
        return 'Reported';
      case IncidentStatus.resolved:
        return 'Resolved';
    }
  }

  String _formatDateTime(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '${value.year}-${two(value.month)}-${two(value.day)} '
        '${two(value.hour)}:${two(value.minute)}';
  }

  String _safeFileName(String value) {
    return value.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
  }
}
