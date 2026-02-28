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

  static Future<void> exportToExcel(
    List<Expense> expenses, {
    String? childName,
    String? periodLabel,
  }) async {
    var excel = Excel.createExcel();

    // ── Sheet 1: 지출내역 ──
    Sheet sheet1 = excel['지출내역'];

    // 헤더 스타일
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#4472C4'),
      fontColorHex: ExcelColor.white,
      horizontalAlign: HorizontalAlign.Center,
    );

    // 헤더 추가
    final headers = [
      '결제일', '자녀', '상호', '과목', '강사', '세부내역',
      '수업형태', '결제방법', '카드명', '금액', '취소금액', '실지출', '환불여부', '메모',
    ];
    for (var i = 0; i < headers.length; i++) {
      final cell = sheet1.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    // 데이터 추가
    for (var r = 0; r < expenses.length; r++) {
      final e = expenses[r];
      final row = r + 1;
      sheet1.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value =
          TextCellValue(DateFormat('yyyy-MM-dd').format(e.paymentDate));
      sheet1.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value =
          TextCellValue(e.childName);
      sheet1.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value =
          TextCellValue(e.businessName);
      sheet1.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value =
          TextCellValue(e.subject);
      sheet1.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value =
          TextCellValue(e.instructor);
      sheet1.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).value =
          TextCellValue(e.detail);
      sheet1.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row)).value =
          TextCellValue(e.classType);
      sheet1.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row)).value =
          TextCellValue(e.paymentMethod);
      sheet1.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row)).value =
          TextCellValue(e.cardName ?? '');
      sheet1.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: row)).value =
          IntCellValue(e.amount);
      sheet1.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: row)).value =
          IntCellValue(e.cancellationAmount);
      sheet1.cell(CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: row)).value =
          IntCellValue(e.amount - e.cancellationAmount);
      sheet1.cell(CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: row)).value =
          TextCellValue(e.isRefunded ? '예' : '아니오');
      sheet1.cell(CellIndex.indexByColumnRow(columnIndex: 13, rowIndex: row)).value =
          TextCellValue(e.memo ?? '');
    }

    // ── Sheet 2: 통계 ──
    Sheet sheet2 = excel['통계'];

    final sectionStyle = CellStyle(
      bold: true,
      fontSize: 13,
    );
    final subHeaderStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#D9E2F3'),
      horizontalAlign: HorizontalAlign.Center,
    );

    int currentRow = 0;

    // 필터 정보
    sheet2.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value =
        TextCellValue('조건');
    sheet2.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).cellStyle = sectionStyle;
    currentRow++;
    sheet2.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value =
        TextCellValue('자녀');
    sheet2.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value =
        TextCellValue(childName ?? '전체');
    currentRow++;
    sheet2.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value =
        TextCellValue('기간');
    sheet2.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value =
        TextCellValue(periodLabel ?? '');
    currentRow += 2;

    // 요약
    final totalAmount = expenses.fold<int>(0, (s, e) => s + e.amount);
    final totalCancel = expenses.fold<int>(0, (s, e) => s + e.cancellationAmount);
    final netAmount = totalAmount - totalCancel;

    sheet2.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value =
        TextCellValue('요약');
    sheet2.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).cellStyle = sectionStyle;
    currentRow++;

    for (final entry in [
      ['총 지출', totalAmount],
      ['취소 금액', totalCancel],
      ['실 지출', netAmount],
    ]) {
      sheet2.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value =
          TextCellValue(entry[0] as String);
      sheet2.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value =
          IntCellValue(entry[1] as int);
      currentRow++;
    }
    currentRow++;

    // 월별 지출
    final byMonth = <String, int>{};
    for (final e in expenses) {
      final key = '${e.paymentDate.year}-${e.paymentDate.month.toString().padLeft(2, '0')}';
      byMonth[key] = (byMonth[key] ?? 0) + (e.amount - e.cancellationAmount);
    }
    final sortedMonths = byMonth.keys.toList()..sort();

    sheet2.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value =
        TextCellValue('월별 지출');
    sheet2.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).cellStyle = sectionStyle;
    currentRow++;

    final monthHeaders = ['월', '실 지출'];
    for (var i = 0; i < monthHeaders.length; i++) {
      final cell = sheet2.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: currentRow));
      cell.value = TextCellValue(monthHeaders[i]);
      cell.cellStyle = subHeaderStyle;
    }
    currentRow++;

    for (final key in sortedMonths) {
      final month = int.parse(key.split('-')[1]);
      final year = key.split('-')[0];
      sheet2.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value =
          TextCellValue('$year년 ${month}월');
      sheet2.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value =
          IntCellValue(byMonth[key]!);
      currentRow++;
    }
    currentRow++;

    // 과목별 지출
    final bySubject = <String, int>{};
    for (final e in expenses) {
      bySubject[e.subject] = (bySubject[e.subject] ?? 0) + (e.amount - e.cancellationAmount);
    }

    sheet2.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value =
        TextCellValue('과목별 지출');
    sheet2.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).cellStyle = sectionStyle;
    currentRow++;

    final subjectHeaders = ['과목', '실 지출', '비율'];
    for (var i = 0; i < subjectHeaders.length; i++) {
      final cell = sheet2.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: currentRow));
      cell.value = TextCellValue(subjectHeaders[i]);
      cell.cellStyle = subHeaderStyle;
    }
    currentRow++;

    final subjectTotal = bySubject.values.fold<int>(0, (a, b) => a + b);
    final sortedSubjects = bySubject.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final entry in sortedSubjects) {
      final pct = subjectTotal > 0 ? (entry.value / subjectTotal * 100) : 0.0;
      sheet2.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value =
          TextCellValue(entry.key);
      sheet2.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value =
          IntCellValue(entry.value);
      sheet2.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow)).value =
          TextCellValue('${pct.toStringAsFixed(1)}%');
      currentRow++;
    }
    currentRow++;

    // 자녀별 지출
    final byChild = <String, int>{};
    for (final e in expenses) {
      byChild[e.childName] = (byChild[e.childName] ?? 0) + (e.amount - e.cancellationAmount);
    }

    sheet2.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value =
        TextCellValue('자녀별 지출');
    sheet2.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).cellStyle = sectionStyle;
    currentRow++;

    final childHeaders = ['자녀', '실 지출'];
    for (var i = 0; i < childHeaders.length; i++) {
      final cell = sheet2.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: currentRow));
      cell.value = TextCellValue(childHeaders[i]);
      cell.cellStyle = subHeaderStyle;
    }
    currentRow++;

    final sortedChildren = byChild.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final entry in sortedChildren) {
      sheet2.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value =
          TextCellValue(entry.key);
      sheet2.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value =
          IntCellValue(entry.value);
      currentRow++;
    }

    // 기본 Sheet1 삭제
    excel.delete('Sheet1');

    // 파일 저장
    var fileBytes = excel.save();
    if (fileBytes != null) {
      downloadFile(
        fileBytes,
        'K학원_지출통계_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx',
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
            pw.Header(
              level: 0,
              child: pw.Text(
                'K Academy Expense Report',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text('Total Items: ${expenses.length}'),
                  pw.SizedBox(height: 5),
                  pw.Text('Total Amount: ${formatNumber(totalAmount)} KRW'),
                  pw.SizedBox(height: 5),
                  pw.Text('Total Cancellation: ${formatNumber(totalCancellation)} KRW'),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Net Expense: ${formatNumber(netAmount)} KRW',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
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
                'Date', 'Child', 'Business', 'Subject', 'Instructor',
                'Detail', 'Type', 'Payment', 'Amount', 'Cancel', 'Refund',
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
                  expense.isRefunded ? 'Yes' : 'No',
                ];
              }).toList(),
            ),
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    downloadFile(
      bytes,
      'K_Academy_Expenses_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf',
    );
  }

  static String formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}
