use strict;
use warnings;
package Test::MooseX::Daemonize;
# ABSTRACT: Tool to help test MooseX::Daemonize applications

our $VERSION = '0.20';

# BEGIN CARGO CULTING
use Sub::Exporter::ForMethods 'method_installer';
use Sub::Exporter -setup => {
    exports => [ qw(daemonize_ok check_test_output) ],
    groups  => { default => [ qw(daemonize_ok check_test_output) ] },
    installer => method_installer,
};

use Test::Builder;

our $Test = Test::Builder->new;

sub daemonize_ok {
    my ( $daemon, $msg ) = @_;
    unless ( my $pid = fork ) {
        $daemon->start();
        exit;
    }
    else {
        sleep(1);    # Punt on sleep time, 1 seconds should be enough
        $Test->ok( $daemon->pidfile->does_file_exist, $msg )
          || $Test->diag(
            'Pidfile (' . $daemon->pidfile->file . ') not found.' );
    }
}

sub check_test_output {
    my ($app) = @_;
    open( my $stdout_in, '<', $app->test_output )
      or die "can't open test output: $!";
    while ( my $line = <$stdout_in> ) {
        $line =~ s/\s+\z//;
        my $label;
        if ( $line =~ /\A(?:(not\s+)?ok)(?:\s+-)(?:\s+(.*))\z/ ) {
            my ( $not, $text ) = ( $1, $2, $3 );
            $text ||= '';

           # We don't just call ok(!$not), because that generates diagnostics of
           # its own for failures. We only want the diagnostics from the child.
            my $orig_no_diag = $Test->no_diag;
            $Test->no_diag(1);
            $Test->ok(!$not, $text);
            $Test->no_diag($orig_no_diag);
        }
        elsif ( $line =~ s/\A#\s?// ) {
            $Test->diag($line);
        }
        else {
            $Test->diag("$label: $line (unrecognised)\n");
        }
    }
}

package Test::MooseX::Daemonize::Testable;

use Moose::Role;

has test_output => (
    isa      => 'Str',
    is       => 'ro',
    required => 1,
);

after daemonize => sub {
    $Test->use_numbers(0);
    $Test->no_ending(1);
    open my $out, '>', $_[0]->test_output or die "Cannot open test output: $!";
    my $fileno = fileno $out;
    open STDERR, ">&=", $fileno
      or die "Can't redirect STDERR";

    open STDOUT, ">&=", $fileno
      or die "Can't redirect STDOUT";

    $Test->output($out);
    $Test->failure_output($out);
    $Test->todo_output($out);
};

1;
__END__

=pod

=head1 SYNOPSIS

    use File::Spec::Functions;
    use File::Temp qw(tempdir);

    my $dir = tempdir( CLEANUP => 1 );

    ## Try to make sure we are in the test directory

    my $file = catfile( $dir, "im_alive" );
    my $daemon = FileMaker->new( pidbase => $dir, filename => $file );

    daemonize_ok( $daemon, 'child forked okay' );
    ok( -e $file, "$file exists" );

=head1 DESCRIPTION

This module provides some basic Test::Builder compatible test methods to
use when writing tests for you MooseX::Daemonize based modules.

=head1 EXPORTED FUNCTIONS

=over 4

=item B<daemonize_ok ( $daemon, ?$msg )>

This will attempt to daemonize your C<$daemon> returning ok on
success and not ok on failure.

=item B<check_test_output ( $daemon )>

This is expected to be used with a C<$daemon> which does the
B<Test::MooseX::Daemonize::Testable> role (included in this package
see the source for more info). It will collect the test output
from your daemon and apply it in the parent process by mucking
around with L<Test::Builder> stuff, again, read the source for
more info. If we get time we will document this more thoroughly.

=back

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-MooseX-Daemonize@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 SEE ALSO

L<MooseX::Daemonize>

=cut
