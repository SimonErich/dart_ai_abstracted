// Fails the build when line coverage in an lcov report is below a threshold.
//
//   dart run tool/check_coverage.dart --min 95 coverage/lcov.info
//
// Reads the `DA:<line>,<hits>` records, counts covered versus total, and exits
// non-zero when the percentage is under the minimum.
import 'dart:io';

void main(List<String> args) {
  final minIndex = args.indexOf('--min');
  if (minIndex == -1 || minIndex + 1 >= args.length) {
    stderr.writeln('usage: check_coverage.dart --min <percent> <lcov.info>');
    exit(2);
  }
  final min = double.tryParse(args[minIndex + 1]);
  final path = args.lastWhere((a) => a.endsWith('.info'), orElse: () => '');
  if (min == null || path.isEmpty) {
    stderr.writeln('usage: check_coverage.dart --min <percent> <lcov.info>');
    exit(2);
  }

  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('coverage file not found: $path');
    exit(2);
  }

  var total = 0;
  var covered = 0;
  for (final line in file.readAsLinesSync()) {
    if (!line.startsWith('DA:')) continue;
    final parts = line.substring(3).split(',');
    if (parts.length < 2) continue;
    total++;
    if ((int.tryParse(parts[1]) ?? 0) > 0) covered++;
  }

  if (total == 0) {
    stderr.writeln('no coverage records found in $path');
    exit(2);
  }

  final percent = 100 * covered / total;
  final rounded = percent.toStringAsFixed(2);
  if (percent + 1e-9 < min) {
    stderr.writeln('coverage $rounded% ($covered/$total) is below the $min% minimum');
    exit(1);
  }
  stdout.writeln('coverage $rounded% ($covered/$total) meets the $min% minimum');
}
