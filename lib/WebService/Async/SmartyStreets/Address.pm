package WebService::Async::SmartyStreets::Address;

use strict;
use warnings;

sub new {
    my ($class, %args) = @_;
    bless \%args, $class
}

sub address_parts {
    my ($self) = @_;
    @{$self}{grep { exists $self->{$_} } map { 'address' . $_ } 1..12 }
}

sub input_id { shift->{input_id} }
sub organization { shift->{organization} }
sub latitude { shift->{metadata}{latitude} }
sub longitude { shift->{metadata}{longitude} }
sub geocode_precision { shift->{metadata}{geocode_precision} }
sub max_geocode_precision { shift->{metadata}{max_geocode_precision} }
sub address_format { shift->{metadata}{address_format} }

sub status { lc shift->{analysis}{verification_status} }
sub address_precision { lc shift->{analysis}{address_precision} }
sub max_address_precision { lc shift->{analysis}{max_address_precision} }

my %status_level = (
    none => 0,
    partial => 1,
    ambiguous => 2,
    verified => 3
);
sub status_at_least {
    my ($self, $target) = @_;
    my $target_level = $status_level{$target} // die 'unknown target status ' . $target;
    my $actual_level = $status_level{$self->status} // die 'unknown status ' . $self->status;
    return $actual_level >= $target_level;
}

my %accuracy_level = (
    none => 0,
    administrative_area => 1,
    locality => 2,
    thoroughfare => 3,
    premise => 4,
    delivery_point => 5,
);

sub accuracy_at_least {
    my ($self, $target) = @_;
    return 0 unless $self->status_at_least('partial');
    my $target_level = $accuracy_level{$target} // die 'unknown target accuracy ' . $target;
    my $actual_level = $accuracy_level{$self->address_precision} // die 'unknown accuracy ' . $self->address_precision;
    return $actual_level >= $target_level;
}

1;

