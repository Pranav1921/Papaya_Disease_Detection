import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/ml_prediction_service.dart';
import '../models/disease_info.dart';

class PdfPrescriptionService {
  /// Generates printable Kannada PDF Treatment Slip
  static Future<Uint8List> generatePrescriptionPdf({
    required MLPredictionResult result,
    required String shopName,
    required String shopPhone,
  }) async {
    final pdf = pw.Document();
    DiseaseInfo disease = result.diseaseInfo;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header Banner
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green900,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'KARNATAKA PAPAYA CROP CARE DOCTOR',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          'Official Crop Disease Diagnosis & Treatment Card',
                          style: const pw.TextStyle(
                            color: PdfColors.yellow300,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    pw.Text(
                      'RSK APPROVED',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              // Date & Location Info Row
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Diagnosed Date: ${result.diagnosedAt}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                  pw.Text('Location: Puttur / Mangaluru Belt (DK)', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                ],
              ),

              pw.Divider(thickness: 1, color: PdfColors.green800),

              // Diagnosis Result Summary Box
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  border: pw.Border.all(color: PdfColors.green800),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Disease Diagnosis:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                        pw.Text(disease.titleEnglish, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
                        pw.Text(disease.titleKannada, style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey800)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Severity Level:', style: const pw.TextStyle(fontSize: 10)),
                        pw.Text('${result.severityPercentage}% DAMAGE', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.red900)),
                        pw.Text('AI Confidence: ${result.confidenceScore}%', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              // Prescribed Medicines Header
              pw.Text('Prescribed Medicines & Price Breakdown:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
              pw.SizedBox(height: 8),

              // Itemized Table
              pw.Table.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.green800),
                rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300))),
                cellAlignment: pw.Alignment.centerLeft,
                data: <List<String>>[
                  <String>['Medicine Name', 'Category', 'Dosage', 'Package', 'MRP Price'],
                  ...disease.prescribedMedicines.map((m) => [
                    m.nameEnglish,
                    m.typeEnglish.replaceAll(RegExp(r'[^\w\s]'), ''),
                    m.dosageEnglish,
                    m.packageSizeEnglish,
                    'Rs. ${m.price.toStringAsFixed(0)}',
                  ]),
                ],
              ),

              pw.SizedBox(height: 12),

              // Total Price Sum Callout
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green900,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('TOTAL ESTIMATED TREATMENT PACKAGE COST:', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 11)),
                    pw.Text('Rs. ${disease.totalPrice.toStringAsFixed(0)}', style: pw.TextStyle(color: PdfColors.yellow300, fontWeight: pw.FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              // Nearest Shop & RSK Subsidy Box
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.yellow50,
                  border: pw.Border.all(color: PdfColors.amber800),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Nearest Supply Center (< 100 KM Radius):', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.amber900)),
                    pw.Text('$shopName | Phone: $shopPhone', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Note: 50% Govt Subsidy on Bio-fertilizers available at Taluk Raitha Samparka Kendra (RSK).', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                  ],
                ),
              ),

              pw.Spacer(),

              // Footer Note
              pw.Divider(thickness: 0.5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Generated by Karnataka Papaya Crop Care Mobile App', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                  pw.Text('Karnataka Agriculture Department Guidelines', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Triggers PDF preview, download or printing sheet
  static Future<void> printOrSharePdf({
    required MLPredictionResult result,
    required String shopName,
    required String shopPhone,
  }) async {
    final pdfBytes = await generatePrescriptionPdf(
      result: result,
      shopName: shopName,
      shopPhone: shopPhone,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Papaya_Treatment_Card_${result.diseaseInfo.id}.pdf',
    );
  }
}
