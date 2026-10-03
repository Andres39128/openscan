/// `Mi Factura 2026!` → `mi_factura_2026`. ASCII, sin espacios (PLAN §2).
String slugify(String input) {
  // Raw obligatorio en \s: sin r matchea la letra s, no espacios.
  var s = input.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
  s = s.replaceAll(RegExp('[^a-z0-9_]+'), '');
  s = s.replaceAll(RegExp('_+'), '_');
  s = s.replaceAll(RegExp(r'^_+|_+$'), '');
  return s.isEmpty ? 'escaneo' : s;
}

/// `openscan_{titulo}_{yyyyMMdd_HHmm}.pdf` (PLAN §2).
String exportFileName(String title, DateTime when) {
  String p(int n) => n.toString().padLeft(2, '0');
  final stamp = '${when.year}${p(when.month)}${p(when.day)}_'
      '${p(when.hour)}${p(when.minute)}';
  return 'openscan_${slugify(title)}_$stamp.pdf';
}
