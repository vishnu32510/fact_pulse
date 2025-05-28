// Conditionally export the right file:
export 'local_report_generator_io.dart'
  if (dart.library.html) 'local_report_generator_web.dart';
