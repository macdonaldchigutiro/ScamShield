import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/entities/incident_record.dart';

/// Builds and saves a professional ScamShield incident report as a PDF.
///
/// This lives in the data/platform layer because PDF rendering and file saving
/// depend on third-party/platform APIs. The incident domain model stays free of
/// Flutter, browser and file-system concerns.
class IncidentPdfExportService {
  const IncidentPdfExportService();

  Future<String> export(IncidentRecord incident) async {
    final bytes = await buildPdf(incident);
    final fileName = 'ScamShield_${_safeFileName(incident.id)}';

    await FileSaver.instance.saveFile(
      name: fileName,
      bytes: bytes,
      fileExtension: 'pdf',
      mimeType: MimeType.pdf,
    );

    return '$fileName.pdf';
  }

  /// Generates bytes separately so future email/share/upload actions can reuse
  /// exactly the same report without coupling those actions to file saving.
  Future<Uint8List> buildPdf(IncidentRecord incident) async {
    final document = pw.Document(
      title: 'ScamShield Incident Report - ${incident.id}',
      author: 'ScamShield',
      subject: incident.category,
    );

    final accent = _accentFor(incident);
    const navy = PdfColor.fromInt(0xFF0A1226);
    const muted = PdfColor.fromInt(0xFF64748B);
    const light = PdfColor.fromInt(0xFFF8FAFC);
    const border = PdfColor.fromInt(0xFFE2E8F0);

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(34),
        header: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 10),
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
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 2,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'DIGITAL FRAUD DEFENCE',
                    style: const pw.TextStyle(
                      color: muted,
                      fontSize: 7.5,
                      letterSpacing: 1.5,
                    ),
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
        footer: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: border, width: 0.8)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                incident.id,
                style: const pw.TextStyle(color: muted, fontSize: 7),
              ),
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: const pw.TextStyle(color: muted, fontSize: 7),
              ),
            ],
          ),
        ),
        build: (context) => [
          pw.SizedBox(height: 18),
          pw.Text(
            incident.category,
            style: pw.TextStyle(
              color: navy,
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
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
                        'RISK / 100',
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
                      _metaRow('Incident ID', incident.id),
                      _metaRow('Created', _formatDateTime(incident.createdAt)),
                      _metaRow('Status', _statusLabel(incident.status)),
                      _metaRow('Source', incident.sourceLabel),
                      if (incident.sender.isNotEmpty)
                        _metaRow('Sender / account', incident.sender),
                      if (incident.amount != null)
                        _metaRow('Amount involved', incident.amount!.toStringAsFixed(2)),
                      if ((incident.transactionReference ?? '').isNotEmpty)
                        _metaRow(
                          'Transaction / case reference',
                          incident.transactionReference!,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 18),
          _sectionTitle('EVIDENCE / CONTENT', accent),
          pw.SizedBox(height: 7),
          _bodyCard(
            incident.content.isEmpty ? 'Not recorded.' : incident.content,
            light,
            border,
            navy,
          ),
          pw.SizedBox(height: 16),
          _sectionTitle('WHY SCAMSHIELD FLAGGED IT', accent),
          pw.SizedBox(height: 7),
          if (incident.reasons.isEmpty)
            _bodyCard(
              'No detailed warning reasons were recorded.',
              light,
              border,
              navy,
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
                        reason.title,
                        style: pw.TextStyle(
                          color: navy,
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        reason.explanation,
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
          pw.SizedBox(height: 12),
          _sectionTitle('RECOMMENDED ACTIONS', accent),
          pw.SizedBox(height: 7),
          if (incident.recommendedActions.isEmpty)
            _bodyCard(
              'No recommended actions were recorded.',
              light,
              border,
              navy,
            )
          else
            pw.Column(
              children: [
                for (var index = 0;
                    index < incident.recommendedActions.length;
                    index++)
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
                            shape: pw.BoxShape.circle,
                            color: accent,
                          ),
                          child: pw.Text(
                            '${index + 1}',
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
                            incident.recommendedActions[index],
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
              ],
            ),
          if (incident.notes.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            _sectionTitle('USER NOTES / ACTIONS TAKEN', accent),
            pw.SizedBox(height: 7),
            _bodyCard(incident.notes, light, border, navy),
          ],
          pw.SizedBox(height: 18),
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
              'Important: This document is generated by ScamShield from locally saved investigation evidence. It is decision support and is not a police, bank, telecom or official case reference. Keep original messages, screenshots, receipts and transaction records where available.',
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

  pw.Widget _metaRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 105,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 8.5,
                fontWeight: pw.FontWeight.bold,
                color: const PdfColor.fromInt(0xFF475569),
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(
                fontSize: 8.5,
                color: PdfColor.fromInt(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _sectionTitle(String title, PdfColor accent) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        color: accent,
        fontWeight: pw.FontWeight.bold,
        fontSize: 9,
        letterSpacing: 1.2,
      ),
    );
  }

  pw.Widget _bodyCard(
    String text,
    PdfColor background,
    PdfColor border,
    PdfColor foreground,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(11),
      decoration: pw.BoxDecoration(
        color: background,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: border),
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: foreground,
          fontSize: 9.5,
          lineSpacing: 2,
        ),
      ),
    );
  }

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
