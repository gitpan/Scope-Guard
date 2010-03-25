package Scope::Guard;

use strict;
use warnings;

use Exporter ();

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(guard scope_guard);
our $VERSION = '0.11';

sub new {
    my $class = shift;
    my $handler = shift() || die 'Scope::Guard::new: no handler supplied';
    my $ref = ref $handler || '';

    die "Scope::Guard::new: invalid handler - expected CODE ref, got: '$ref'"
	unless (UNIVERSAL::isa($handler, 'CODE'));

    bless [ 0, $handler ], ref $class || $class;
}

sub dismiss {
    my $self = shift;
    my $dismiss = @_ ? shift : 1;

    $self->[0] = $dismiss;
}

sub guard(&) { __PACKAGE__->new(shift) }
sub scope_guard($) { __PACKAGE__->new(shift) }

sub DESTROY {
    my $self = shift;
    my ($dismiss, $handler) = @$self;

    $handler->() unless ($dismiss);
}

1;

__END__

=pod

=head1 NAME

Scope::Guard - lexically scoped resource management

=head1 SYNOPSIS

    my $guard = guard { ... };

      # or

    my $guard = scope_guard \&handler;

      # or

    my $guard = Scope::Guard->new(\&handler);

    $guard->dismiss(); # disable the handler

=head1 DESCRIPTION

This module provides a convenient way to perform cleanup or other forms of resource
management at the end of a scope. It is particularly useful when dealing with exceptions:
the C<Scope::Guard> constructor takes a reference to a subroutine that is guaranteed to
be called even if the thread of execution is aborted prematurely. This effectively allows
lexically-scoped "promises" to be made that are automatically honoured by perl's garbage
collector.

For more information, see: L<http://www.drdobbs.com/cpp/184403758>

=head1 METHODS

=head2 new

    my $guard = Scope::Guard->new(sub { ... });

      # or

    my $guard = Scope::Guard->new(\&handler);

The C<new> method creates a new C<Scope::Guard> object which calls the supplied handler when its C<DESTROY> method is
called, typically when it goes out of scope.

=head2 dismiss

    $guard->dismiss();

      # or

    $guard->dismiss(1);

C<dismiss> detaches the handler from the C<Scope::Guard> object. This revokes the "promise" to call the
handler when the object is destroyed.

The handler can be re-enabled by calling:

    $guard->dismiss(0);

=head1 EXPORTS

=head2 guard

C<guard> takes a block and returns a new C<Scope::Guard> object. It can be used
as a shorthand for:

    Scope::Guard->new(...)

e.g.

    my $guard = guard { ... };
    
- or it can be called in void context to create a guard for the current scope e.g.

    guard { ... };

Because there is no way to dismiss the guard in the latter case, it is assumed that
the block knows how to deal with situations in which the resource has already been
managed e.g.

    guard {
	unless ($resource->disposed) {
            $resource->dispose;
	}
    };

=head2 scope_guard

C<scope_guard> is the same as C<guard>, but it takes a scalar (e.g. a code ref) rather than a block.
e.g.

    my $guard = scope_guard \&handler;

or:

    my $guard = scope_guard sub { ... };

or:

    my $guard = scope_guard $handler;

Like C<guard>, it can be called in void context to install an anonymous guard in the current scope.

=head1 VERSION

0.11

=head1 SEE ALSO

=over

=item * L<B::Hooks::EndOfScope|B::Hooks::EndOfScope>

=item * L<End|End>

=item * L<Guard|Guard>

=item * L<Hook::Scope|Hook::Scope>

=item * L<Object::Destroyer|Object::Destroyer>

=item * L<Perl::AtEndOfScope|Perl::AtEndOfScope>

=item * L<ReleaseAction|ReleaseAction>

=item * L<Scope::OnExit|Scope::OnExit>

=item * L<Sub::ScopeFinalizer|Sub::ScopeFinalizer>

=back

=head1 AUTHOR

chocolateboy <chocolate@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2010, chocolateboy.

This module is free software. It may be used, redistributed and/or modified under the same terms
as Perl itself.

=cut
