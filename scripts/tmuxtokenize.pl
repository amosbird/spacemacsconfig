#!/usr/bin/env perl

use strict;
use utf8;
use IPC::Run3;
use MIME::Base64;
use List::Util qw/first/;
use Encode;

run3 [ "tmux", "list-windows", "-F", "#{window_id}:#{window_active}" ], \undef, \my $windows_input, \undef;

my @windows = split "\n", $windows_input;

my $window = first { /:1/ } @windows;

$window = substr( $window, 0, rindex( $window, ":" ));

run3 [ "tmux", "list-panes", "-t", $window, "-F", "#{pane_id}:#{pane_active} #{pane_tty}" ], \undef, \my $panes_input, \undef;

my @panes = split "\n", $panes_input;

my $pane_a = first { /:1/ } @panes;

my ($pane_b, $tty) = split ' ', $pane_a;

$pane_b = substr( $pane_b, 0, rindex( $pane_b, ":" ));

my $lines;

for my $pane (@panes) {
    my $line;
    run3 [ "tmux", "capture-pane", "-pJS", "0", "-t", substr( $pane, 0, rindex( $pane, ":" )) ], \undef, \$line, \undef;
    $lines = $lines.$line;
}

my %hash = map { $_ => 1 } split ' ', decode("UTF-8", $lines) =~ s/[\s❯⏎]+/ /gmr;
my @unique = keys %hash;
my $s = join "\n",  grep { length $_ > 3 } @unique;

$s = encode_base64(encode("UTF-8", $s), "");
open(TTY, ">".$tty);
*STDOUT = *TTY;
my $osc52 = "\033]52;o;".$s."\07";
my $esc = "\033Ptmux;\033".$osc52."\033\\"; # tmux
print $esc;
close(TTY);
