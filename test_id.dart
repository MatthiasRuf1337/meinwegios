void main() {
  // Test ID-Generierung für alle PDFs
  final pdfs = [
    'Die Magie des Pilgerns.pdf',
    'Mache dich auf den Weg.pdf',
    'Packliste.pdf',
  ];
  
  for (var fileName in pdfs) {
    final extension = '.pdf';
    String baseName = fileName;
    if (baseName.toLowerCase().endsWith(extension.toLowerCase())) {
      baseName = baseName.substring(0, baseName.length - extension.length);
    }
    final id = 'preloaded_${baseName.replaceAll(' ', '_')}';
    print('$fileName -> ID: $id');
  }
}
