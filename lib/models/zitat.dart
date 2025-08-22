class Zitat {
  final String text;
  final String autor;

  const Zitat({
    required this.text,
    required this.autor,
  });

  factory Zitat.fromCsvRow(List<String> row) {
    if (row.length < 2) {
      throw ArgumentError('CSV-Zeile muss mindestens 2 Spalten haben');
    }
    return Zitat(
      text: row[0].trim().replaceAll('"', ''),
      autor: row[1].trim().replaceAll('"', ''),
    );
  }
}
