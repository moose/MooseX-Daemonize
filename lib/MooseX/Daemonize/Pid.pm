use strict;
use warnings;
package MooseX::Daemonize::Pid;
# ABSTRACT: PID management for MooseX::Daemonize

our $VERSION = '0.23';

use Moose;
use Moose::Util::TypeConstraints qw(coerce from via);
use namespace::autoclean;

coerce 'MooseX::Daemonize::Pid'
    => from 'Int'
        => via { MooseX::Daemonize::Pid->new( pid => $_ ) };


has 'pid' => (
    is        => 'rw',
    isa       => 'Int',
    lazy      => 1,
    clearer   => 'clear_pid',
    predicate => 'has_pid',
    default   => sub { $$ }
);

sub is_running { kill(0, (shift)->pid) ? 1 : 0 }

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 DESCRIPTION

This is a very basic Pid management object, it doesn't do all that
much, and mostly just serves as a base class for L<MooseX::Daemonize::Pid::File>.

=head1 ATTRIBUTES

=over 4

=item I<pid Int>

=back

=head1 METHODS

=over 4

=item B<clear_pid>

This will clear the value of the I<pid> attribute. It is useful for making sure
that the parent process does not have a bad value stored in it.

=item B<has_pid>

This is a predicate method to tell you if your I<pid> attribute has
been initialized yet.

=item B<is_running>

This checks to see if the I<pid> is running.

=item meta()

The C<meta()> method from L<Class::MOP::Class>

=back

=cut
