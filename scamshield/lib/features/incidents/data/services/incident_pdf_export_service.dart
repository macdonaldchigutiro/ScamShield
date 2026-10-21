import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/entities/incident_record.dart';
import '../../domain/services/evidence_integrity.dart';
import 'platform_download.dart';

/// Builds and downloads a professional ScamShield incident report as a PDF.
///
/// The report is generated locally. `hidePhoneNumbers` produces a share-safe
/// copy by masking phone-like values in user-controlled text fields while the
/// integrity fingerprint continues to identify the original saved evidence.
class IncidentPdfExportService {
  const IncidentPdfExportService();

  Future<String> export(
    IncidentRecord incident, {
    bool hidePhoneNumbers = false,
  }) async {
    final bytes = await buildPdf(
      incident,
      hidePhoneNumbers: hidePhoneNumbers,
    );
    final suffix = hidePhoneNumbers ? '_redacted' : '';
    final fileName =
        'ScamShield_${_safeFileName(incident.id)}$suffix.pdf';

    await downloadBytes(
      bytes: bytes,
      fileName: fileName,
      mimeType: 'application/pdf',
    );

    return fileName;
  }

  /// Generates the report bytes independently from saving/downloading them.
  Future<Uint8List> buildPdf(
    IncidentRecord incident, {
    bool hidePhoneNumbers = false,
  }) async {
    final document = pw.Document(
      title: 'ScamShield Incident Report - ${incident.id}',
      author: 'ScamShield',
      subject: incident.category,
    );

    final accent = _accentFor(incident);
    final fingerprint = evidenceFingerprint(incident);
    const navy = PdfColor.fromInt(0xFF0F172A);
    const muted = PdfColor.fromInt(0xFF64748B);
    const light = PdfColor.fromInt(0xFFF8FAFC);
    const border = PdfColor.fromInt(0xFFE2E8F0);

    String visible(String value) {
      final safe = _pdfSafe(value);
      return hidePhoneNumbers ? _redactPhoneNumbers(safe) : safe;
    }

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(34, 34, 34, 42),
        header: (_) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 9),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: border, width: 0.8),
            ),
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
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'INCIDENT REPORT',
                    style: pw.TextStyle(
                      color: accent,
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  if (hidePhoneNumbers)
                    pw.Text(
                      'PHONE NUMBERS REDACTED',
                      style: const pw.TextStyle(color: muted, fontSize: 6.5),
                    ),
                ],
              ),
            ],
          ),
        ),
        footer: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Container(height: 0.6, color: border),
            pw.SizedBox(height: 5),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Text(
                    'Automated/user-provided ScamShield evidence summary - not a legal finding or official police, bank or telecom determination.',
                    style: const pw.TextStyle(color: muted, fontSize: 6.5),
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: const pw.TextStyle(color: muted, fontSize: 6.5),
                ),
              ],
            ),
          ],
        ),
        build: (_) => [
          pw.SizedBox(height: 18),
          pw.Text(
            visible(incident.category),
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
                      pw.Text(
                        incident.riskScore == 0 ? 'NO SCORE' : 'RISK / 100',
                        style: const pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 7,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 14),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _meta('Incident ID', incident.id),
                      _meta('Saved', _formatDateTime(incident.createdAt)),
                      _meta('Status', _statusLabel(incident.status)),
                      _meta('Source', visible(incident.sourceLabel)),
                      if (incident.sender.isNotEmpty)
                        _meta('Sender / account', visible(incident.sender)),
                      if (incident.amount != null)
                        _meta(
                          'Amount involved',
                          incident.amount!.toStringAsFixed(2),
                        ),
                      if ((incident.transactionReference ?? '').isNotEmpty)
                        _meta(
                          'Transaction / case reference',
                          visible(incident.transactionReference!),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 18),
          _heading('EVIDENCE / CONTENT', accent),
          _card(
            incident.content.isEmpty
                ? 'Not recorded.'
                : visible(incident.content),
          ),
          pw.SizedBox(height: 14),
          _heading('WHY SCAMSHIELD FLAGGED IT', accent),
          if (incident.reasons.isEmpty)
            _card(
              incident.riskScore == 0
                  ? 'This case was started by the user through Emergency help; no automated warning reasons were recorded.'
                  : 'No detailed warning reasons were recorded.',
            )
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
                      pw.Text(
                        visible(reason.title),
                        style: pw.TextStyle(
                          color: navy,
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        visible(reason.explanation),
                        style: const pw.TextStyle(
                          color: muted,
                          fontSize: 9,
                          lineSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          pw.SizedBox(height: 10),
          _heading('RECOMMENDED / RECOVERY ACTIONS', accent),
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
                      child: pw.Text(
                        '${i + 1}',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Expanded(
                      child: pw.Text(
                        visible(incident.recommendedActions[i]),
                        style: const pw.TextStyle(
                          color: navy,
                          fontSize: 9.5,
                          lineSpacing: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          if (incident.notes.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            _heading('USER NOTES / ACTIONS TAKEN', accent),
            _card(visible(incident.notes)),
          ],
          pw.SizedBox(height: 14),
          _heading('EVIDENCE INTEGRITY', accent),
          pw.Container(
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
                _meta(
                  'Original saved timestamp',
                  incident.createdAt.toUtc().toIso8601String(),
                ),
                _meta('SHA-256 evidence fingerprint', fingerprint),
                pw.SizedBox(height: 3),
                pw.Text(
                  'The fingerprint identifies the original saved evidence fields (incident ID, saved timestamp, source, sender and content). Later case notes/status changes do not alter this fingerprint.',
                  style: const pw.TextStyle(
                    color: muted,
                    fontSize: 7.5,
                    lineSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
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
              'Important: This report is generated from locally saved ScamShield evidence. Automated analysis is decision support only and is not a legal finding or an official police, bank, regulator or telecom case reference. Keep original messages, screenshots, receipts and transaction records where available.',
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
            width: 112,
            child: pw.Text(
              _pdfSafe(label),
              style: pw.TextStyle(
                color: const PdfColor.fromInt(0xFF475569),
                fontSize: 8.5,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              _pdfSafe(value),
              style: const pw.TextStyle(
                color: PdfColor.fromInt(0xFF0F172A),
                fontSize: 8.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _heading(String value, PdfColor accent) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 7),
        child: pw.Text(
          _pdfSafe(value),
          style: pw.TextStyle(
            color: accent,
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      );

  pw.Widget _card(String value) => pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(11),
        decoration: pw.BoxDecoration(
          color: const PdfColor.fromInt(0xFFF8FAFC),
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(
            color: const PdfColor.fromInt(0xFFE2E8F0),
          ),
        ),
        child: pw.Text(
          _pdfSafe(value),
          style: const pw.TextStyle(
            color: PdfColor.fromInt(0xFF0F172A),
            fontSize: 9.5,
            lineSpacing: 2,
          ),
        ),
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

  /// Built-in PDF fonts do not cover every smart punctuation glyph reliably.
  /// Normalize common message punctuation so offline reports render cleanly.
  String _pdfSafe(String value) {
    return value
        .replaceAll('’', "'")
        .replaceAll('‘', "'")
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('—', '-')
        .replaceAll('–', '-')
        .replaceAll('…', '...')
        .replaceAll('\u00A0', ' ');
  }

  String _redactPhoneNumbers(String value) {
    final phoneLike = RegExp(
      r'(?<!\w)(?:\+?\d[\d\s().-]{6,}\d)(?!\w)',
    );
    return value.replaceAllMapped(phoneLike, (_) => '[PHONE NUMBER HIDDEN]');
  }
}
