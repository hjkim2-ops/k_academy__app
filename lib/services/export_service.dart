import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:k_academy__app/models/expense.dart';
import 'package:k_academy__app/utils/formatters.dart';
import 'package:intl/intl.dart';
import 'package:universal_html/html.dart' as html;

class ExportService {
  static void downloadFile(List<int> bytes, String fileName) {
    final blob = html.Blob([Uint8List.fromList(bytes)]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  static Future<void> exportToExcel(List<Expense> expenses) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['지출내역'];

    // 헤더 추가
    sheetObject.appendRow([
      TextCellValue('결제일'),
      TextCellValue('자녀'),
      TextCellValue('상호'),
      TextCellValue('과목'),
      TextCellValue('강사'),
      TextCellValue('세부내역'),
      TextCellValue('수업형태'),
      TextCellValue('결제방법'),
      TextCellValue('카드명'),
      TextCellValue('금액'),
      TextCellValue('취소금액'),
      TextCellValue('환불여부'),
      TextCellValue('메모'),
    ]);

    // 데이터 추가
    for (var expense in expenses) {
      sheetObject.appendRow([
        TextCellValue(DateFormat('yyyy-MM-dd').format(expense.paymentDate)),
        TextCellValue(expense.childName),
        TextCellValue(expense.businessName),
        TextCellValue(expense.subject),
        TextCellValue(expense.instructor),
        TextCellValue(expense.detail),
        TextCellValue(expense.classType),
        TextCellValue(expense.paymentMethod),
        TextCellValue(expense.cardName ?? ''),
        IntCellValue(expense.amount),
        IntCellValue(expense.cancellationAmount),
        TextCellValue(expense.isRefunded ? '예' : '아니오'),
        TextCellValue(expense.memo ?? ''),
      ]);
    }

    // 파일 저장
    var fileBytes = excel.save();
    if (fileBytes != null) {
      downloadFile(
        fileBytes,
        'K학원_지출내역_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx',
      );
    }
  }

  static Future<void> exportToPdf(List<Expense> expenses) async {
    final pdf = pw.Document();

    // 총 금액 계산
    final totalAmount = expenses.fold<int>(0, (sum, expense) => sum + expense.amount);
    final totalCancellation = expenses.fold<int>(
      0,
      (sum, expense) => sum + expense.cancellationAmount,
    );
    final netAmount = totalAmount - totalCancellation;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            // 제목
            pw.Header(
              level: 0,
              child: pw.Text(
                'K학원 지출 내역',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 20),

            // 요약 정보
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '생성일: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text('총 항목 수: ${expenses.length}개'),
                  pw.SizedBox(height: 5),
                  pw.Text('총 금액: ${formatNumber(totalAmount)}원'),
                  pw.SizedBox(height: 5),
                  pw.Text('총 취소금액: ${formatNumber(totalCancellation)}원'),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    '순 지출: ${formatNumber(netAmount)}원',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // 지출 내역 테이블
            pw.Table.fromTextArray(
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 8,
              ),
              cellStyle: const pw.TextStyle(fontSize: 7),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              cellAlignment: pw.Alignment.centerLeft,
              headers: [
                '결제일',
                '자녀',
                '상호',
                '과목',
                '강사',
                '세부내역',
                '수업형태',
                '결제방법',
                '금액',
                '취소금액',
                '환불',
              ],
              data: expenses.map((expense) {
                return [
                  DateFormat('yyyy-MM-dd').format(expense.paymentDate),
                  expense.childName,
                  expense.businessName,
                  expense.subject,
                  expense.instructor,
                  expense.detail,
                  expense.classType,
                  expense.paymentMethod,
                  formatNumber(expense.amount),
                  formatNumber(expense.cancellationAmount),
                  expense.isRefunded ? '예' : '아니오',
                ];
              }).toList(),
            ),
          ];
        },
      ),
    );

    // PDF 파일 저장
    final bytes = await pdf.save();
    downloadFile(
      bytes,
      'K학원_지출내역_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf',
    );
  }

  static String formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}
