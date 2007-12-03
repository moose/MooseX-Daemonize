use Test::More tests => 4;
use Test::MooseX::Daemonize;
use MooseX::Daemonize;

##  Since a daemon will not be able to print terminal output, we
##  have a test daemon create a file, and another process test for
##  its existence.

{

    package FileMaker;
    use Moose;
    with qw(MooseX::Daemonize);

    has filename => ( isa => 'Str', is => 'ro' );
    
    after start => sub { 
        my $self = shift;
        $self->create_file( $self->filename ) 
            if $self->is_daemon;
    };

    sub create_file {
        my ( $self, $file ) = @_;
        open( my $FILE, ">$file" ) || die $!;
        close($FILE);
    }

    no Moose;
}

package main;
use strict;
use warnings;
use Cwd;

## Try to make sure we are in the test directory
chdir 't' if ( Cwd::cwd() !~ m|/t$| );
my $cwd = Cwd::cwd();

my $app = FileMaker->new(
    pidbase  => $cwd,
    filename => "$cwd/im_alive",
);
daemonize_ok( $app, 'child forked okay' );
ok( -e $app->filename, "file exists" );
ok( $app->stop( no_exit => 1 ), 'app stopped' );
ok( not(-e $app->pidfile) , 'pidfile gone' );
unlink( $app->filename );
