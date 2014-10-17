package BRAEMBL::DefaultLogger;

use Log::Log4perl;
use Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(get_logger);

sub get_logger {
  check_or_init_log();
  return Log::Log4perl->get_logger();
}

sub check_or_init_log {
  if(! Log::Log4perl->initialized()) {
                my $config  = <<'LOG';
# log4perl.logger=DEBUG, ScreenOut, ScreenErr
log4perl.logger=DEBUG, ScreenOut, ScreenErr

log4perl.filter.ErrorFilter = Log::Log4perl::Filter::LevelRange
log4perl.filter.ErrorFilter.LevelMin = WARN
log4perl.filter.ErrorFilter.LevelMax = FATAL
log4perl.filter.ErrorFilter.AcceptOnMatch = true

log4perl.filter.InfoFilter = Log::Log4perl::Filter::LevelRange
log4perl.filter.InfoFilter.LevelMin = TRACE
log4perl.filter.InfoFilter.LevelMax = INFO
log4perl.filter.InfoFilter.AcceptOnMatch = true

log4perl.appender.ScreenOut=Log::Log4perl::Appender::Screen
log4perl.appender.ScreenOut.stderr=0
log4perl.appender.ScreenOut.Threshold=INFO
log4perl.appender.ScreenOut.Filter=InfoFilter
log4perl.appender.ScreenOut.layout=Log::Log4perl::Layout::PatternLayout
log4perl.appender.ScreenOut.layout.ConversionPattern=%d %p> %M{2}::%L - %m%n

log4perl.appender.ScreenErr=Log::Log4perl::Appender::Screen
log4perl.appender.ScreenErr.stderr=1
log4perl.appender.ScreenErr.Threshold=DEBUG
log4perl.appender.ScreenErr.Filter=ErrorFilter
log4perl.appender.ScreenErr.layout=Log::Log4perl::Layout::PatternLayout
log4perl.appender.ScreenErr.layout.ConversionPattern=%d %p> %M{2}::%L - %m%n
LOG
                Log::Log4perl->init(\$config);
  }
  return;
}

1;
