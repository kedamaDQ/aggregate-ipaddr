#!/usr/bin/perl
#
# Consolidate IP Addresses.
#
# [Files on Regional Internet Registries]
#   ftp://ftp.arin.net/pub/stats/arin/delegated-arin-extended-latest
#   ftp://ftp.ripe.net/pub/stats/ripencc/delegated-ripencc-extended-latest
#   ftp://ftp.apnic.net/pub/stats/apnic/delegated-apnic-extended-latest
#   ftp://ftp.lacnic.net/pub/stats/lacnic/delegated-lacnic-extended-latest
#   ftp://ftp.afrinic.net/pub/stats/afrinic/delegated-afrinic-extended-latest
#
# [Input file format]
#   http://www.apnic.net/db/rir-stats-format.html
#
# [Output file format]
#   <cc>\t<ip address>/<cidr>
#
use strict;
use warnings;
use utf8;

my $DEBUG = 0;
my $GLOB_FILENAME = 'delegated-*-extended-latest';
my $REGEX_IP_ADDR = '^(?:\d{1,3}\.){3}\d{1,3}$';

################################################################################
# decralation
################################################################################
sub load_and_filter($);
sub hostmask($);
sub msb($);
sub split_block($);
sub log2($);
sub value2cidr($);
sub value2mask($);
sub ip2int($);
sub int2ip($);

################################################################################
# args
################################################################################
unless (scalar(@ARGV)) {
  print STDERR "\nUsage: $0 <dir name>\n";
  exit 1;
}

my $dir = shift(@ARGV);
$dir =~ s|/$||;

unless (-d $dir || -x $dir) {
  print STDERR "[EE] Cannot read directory: ${dir}\n";
  exit 1;
}

################################################################################
# main
################################################################################
my @lines = ();

##
# load file
#
while (my $file = glob("${dir}/${GLOB_FILENAME}")) {
  my $fh;

  if (!open($fh, '<', $file)) {
    print STDERR "[EE] Cannot load file, skipped: ${file}: $!\n";
    next;
  }
  print STDERR "[II] Load file: ${file}...\n";
  push(@lines, load_and_filter($fh));
  close($fh);
}

unless(scalar(@lines)) {
  print STDERR "[WW] No valid lines.\n";
  exit 3;
}

##
# aggregate delegated address blocks
#
my @aggregated;
my @buf = ();

my $buf;
foreach my $hashref (sort { $a->{'start'} <=> $b->{'start'} } @lines) {

  if ($buf) {
    print STDERR 
      int2ip($buf->{'start'}), ' ',
      $buf->{'value'}, ' ',
      $buf->{'cc'}, ' ',
      int2ip($buf->{'start'} + $buf->{'value'}), "\n" if ($DEBUG);

    if ($buf->{'cc'} eq $hashref->{'cc'} &&
        $buf->{'start'} + $buf->{'value'} == $hashref->{'start'}) {
      $buf->{'value'} += $hashref->{'value'};
      next;
    } else {
      push(@aggregated, split_block($buf));
    }
  }
  $buf = $hashref;
}

push(@aggregated, split_block($buf));

##
# output
#
print STDOUT (
  $_->{'cc'}, "\t", int2ip($_->{'start'}), $_->{'cidr'}, "\n"
) foreach (@aggregated);

exit 0;

################################################################################
# sub routines
################################################################################
sub load_and_filter($) {
  my $fh = shift;
  my @lines = ();

  while (my $line = <$fh>) {
    # skip comment or blank.
    next if ($line =~ /^\s*#/ || $line =~ /^\s*$/);

    my (
      $registry,
      $cc,
      $type,
      $start,
      $value,
      $date,
      $status,
      $extensions,
    ) = split(/\|/, $line, 8);

    # skip unnecessary data.
    next unless ($cc && $type eq 'ipv4' && $start =~ m/${REGEX_IP_ADDR}/o);

    # skip country code 'ZZ' as Unknown or unspecified country.
    next if ($cc eq 'ZZ');

    push(@lines, {
      'cc' => $cc,
      'start' => ip2int($start),
      'value' => $value,
    });
  }
  return @lines;
}

sub hostmask($) {
  return (($_[0] & (-$_[0])) - 1) & 0xffffffff;
}

sub msb($) {
  my $mask = 0xffffffff;
  my $val = shift;
  $val &= $mask;

  return 0 if ($val == 0);

  $val |= ($val >> 1);
  $val |= ($val >> 2);
  $val |= ($val >> 4);
  $val |= ($val >> 8);
  $val |= ($val >> 16);

  return ($val + 1) >> 1;
}

sub split_block($) {
  my $UNIT = 256;
  my $cc = $_[0]->{'cc'};
  my $value = $_[0]->{'value'};
  my $start = $_[0]->{'start'};
  my @blocks = ();

  my $assigned = 0;
  while ($value) {
    my $block = ((msb($value) - 1) & (hostmask($start + $assigned))) + 1;
    push(@blocks, {
      'cc' => $cc,
      'start' => $start + $assigned,
      'value' => $block,
      'cidr' => value2cidr($block),
      'mask' => value2mask($block),
    });
    $value -= $block;
    $assigned += $block;
  }
  return @blocks;
}

sub log2($) {
  return log($_[0]) / log(2);
}

sub value2cidr($) {
  return '/'. (32 - log2($_[0]));
}

sub value2mask($) {
  return int2ip((~0 << log2($_[0])) & 0xffffffff);
}

sub ip2int($) {
  my @bytes = map { sprintf('%08b', $_) } split(/\./, $_[0]);
  return oct('0b'. join('', @bytes));
}

sub int2ip($) {
  my $binary = sprintf("%032b", $_[0]);
  my @bytes;
  foreach my $byte ($binary =~ m/\d{8}/og) {
    push(@bytes, oct('0b'. $byte));
  }
  return join('.', @bytes);
}

