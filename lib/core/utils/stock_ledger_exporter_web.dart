// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:convert';
import 'dart:html' as html;

bool _isWebDownloading = false;

/// Web implementation using browser anchor and window APIs
void downloadLedgerCsv(String filename, String csvContent) {
  if (_isWebDownloading) return;
  _isWebDownloading = true;

  try {
    final bytes = utf8.encode(csvContent);
    final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..style.display = 'none';
    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
    Future.delayed(const Duration(seconds: 5), () {
      html.Url.revokeObjectUrl(url);
    });
  } finally {
    Future.delayed(const Duration(milliseconds: 1500), () {
      _isWebDownloading = false;
    });
  }
}

/// Web implementation for downloading binary XLSX file
void downloadLedgerXlsx(String filename, List<int> bytes) {
  if (_isWebDownloading) return;
  _isWebDownloading = true;

  try {
    final blob = html.Blob(
      [bytes],
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..style.display = 'none';
    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
    Future.delayed(const Duration(seconds: 5), () {
      html.Url.revokeObjectUrl(url);
    });
  } finally {
    Future.delayed(const Duration(milliseconds: 1500), () {
      _isWebDownloading = false;
    });
  }
}

void printLedger() {
  html.window.print();
}

