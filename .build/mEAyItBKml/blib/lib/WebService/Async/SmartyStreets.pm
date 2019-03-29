package WebService::Async::SmartyStreets;
# ABSTRACT: Access SmartyStreet API

use strict;
use warnings;

our $VERSION = '0.001';

=HEAD

WebService::Async::SmartyStreets - calls the SmartyStreets API and checks for the validity of the address

=head1 SYNOPSIS
    
    my $ss;
    sub get_smartystreets {
        return $ss if $ss;
        $ss = WebService::Async::SmartyStreets->new(
            auth_id => #insert auth_id,
            token   => #insert token,
            );
        IO::Async::Loop->new->add($ss);
        return $ss;
    }
    
    $ss = get_smartystreets();

    my $addr = $ss->verify_international(<hash of address element>, geocode => 'true')->get;
    return $addr->status;
    
=head1 DESCRIPTION

This class calls the SmartyStreets API and parse the response to `WebService::Async::SmartyStreets::Address`

Note that this module uses L<Future::AsyncAwait>

=over 4

=cut

use parent qw(IO::Async::Notifier);

use mro;
no indirect;

use URI;
use URI::QueryParam;

use Future::AsyncAwait;
use Net::Async::HTTP;
use JSON::MaybeUTF8 qw(:v1);

use WebService::Async::SmartyStreets::Address;

use Log::Any qw($log);

=head2 configure

Configures the class with the auth_id and token
Takes in: Hash which consists of auth_id and token

=cut

sub configure {
    my ($self, %args) = @_;
    for my $k (qw(auth_id token)) {
        $self->{$k} = delete $args{$k} if exists $args{$k};
    }
    $self->next::method(%args);
}

sub auth_id { shift->{auth_id} }
sub token   { shift->{token} }

sub next_id {
    ++(shift->{id} //= 'AA00000000');
}

=head2 ua

Accessor for the L<Net::Async::HTTP> instance which will be used for SmartyStreets API requests.

=cut

sub ua {
    my ($self) = @_;
    $self->{ua} //= do {
        $self->add_child(
            my $ua = Net::Async::HTTP->new(
                fail_on_error            => 1,
                decode_content           => 1,
                pipeline                 => 0,
                max_connections_per_host => 4,
                user_agent =>
                    'Mozilla/4.0 (WebService::Async::SmartyStreets; BINARY@cpan.org; https://metacpan.org/pod/WebService::Async::SmartyStreets)',
            ));
        $ua;
        }
}

=head2 verify_international

Calls to different API depending on the country of the address.
Takes the following named parameters:

= over 4

= item * C<country> - country
= item * C<address1> - address line 1
= item * C<address2> - address line 2
= item * C<organization> - name of organization (usually building names)
= item * C<locality> - city
= item * C<administrative_area> - state
= item * C<postal_code> - post code
= item * C<geocode> - true or false

= back 

Returns a L<Future> which resolves to a L<WebService::Async::SmartyStreets::Address> instance.

=cut

# async sub verify_international {
#     my ($self, %args) = @_;
#     my $uri = URI->new('https://international-street.api.smartystreets.com/verify');
#     return await $self->verify($uri => %args);
# }

=head2 verify_international

See L<WebService::Async::SmartyStreets/verify_international>.

=cut

async sub verify_usa {
    my ($self, %args) = @_;
    my $uri = URI->new('https://us-street.api.smartystreets.com/street-address');
    return await $self->verify($uri => %args);
}


=head2 verify

Makes connection to SmartyStreets API and parses the response into WebService::Async::SmartyStreets::Address.

Takes the following named parameters:

= over 4

= item * C<uri> - URI address that the process will make the call to
= item * C<args> - address parametes in hash (See L<WebService::Async::SmartyStreets/verify_international>)

= back 

Returns L<WebService::Async::SmartyStreets::Address> object

=cut

async sub verify {
    my ($self, %args) = @_;

    my $uri = URI->new(get_uri());

    $uri->query_param($_ => $args{$_}) for keys %args;
    $uri->query_param(
        'auth-id' => ($self->auth_id // die 'need an auth ID'),
    );
    $uri->query_param(
        'auth-token' => ($self->token // die 'need an auth token'),
    );
    $uri->query_param(
        'input-id' => $self->next_id,
    );
    $log->tracef('GET %s', '' . $uri);
    my $decoded = await get_decoded_data($self, $uri);
    $log->tracef('=> %s', $decoded);
    return map { WebService::Async::SmartyStreets::Address->new(%$_) } @$decoded;
}

=head2 get_decoded_data

Calls the SmartyStreets API then decode and return response
Takes the following named parameters:

= over 4

= item * C<uri> - URI address that the process will make the call to

= back 

Returns: decoded response in Hash

=cut

async sub get_decoded_data {
    my $self = shift;
    my $uri = shift;
    my $response = do {
        my $res = await $self->ua->GET($uri);
        decode_json_utf8($res->decoded_content);
    };
    return $response;
}

sub get_uri {
    die "Subroutine not overriden in the child's module";
}

# sub get_address {
#     die "Subroutine not overriden in the child's module";
# }

1;
