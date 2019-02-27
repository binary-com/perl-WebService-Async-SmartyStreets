package WebService::Async::SmartyStreets;

use strict;
use warnings;

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

sub configure {
    my ($self, %args) = @_;
    for my $k (qw(auth_id token)) {
        $self->{$k} = delete $args{$k} if exists $args{$k};
    }
    $self->next::method(%args);
}

sub auth_id { shift->{auth_id} }
sub token { shift->{token} }

sub next_id {
    ++(shift->{id} //= 'AA00000000')
}

sub ua {
    my ($self) = @_;
    $self->{ua} //= do {
        $self->add_child(
            my $ua = Net::Async::HTTP->new(
                fail_on_error => 1,
                decode_content => 1,
                pipeline => 0,
                max_connections_per_host => 4,
                user_agent => 'Mozilla/4.0 (WebService::Async::SmartyStreets; TEAM@cpan.org; https://metacpan.org/pod/WebService::Async::SmartyStreets)',
            )
        );
        $ua
    }
}

async sub verify_international {
    my ($self, %args) = @_;
    my $uri = URI->new('https://international-street.api.smartystreets.com/verify');
    return await $self->verify($uri => %args)
}
async sub verify_usa {
    my ($self, %args) = @_;
    my $uri = URI->new('https://us-street.api.smartystreets.com/street-address');
    return await $self->verify($uri => %args)
}

async sub verify {
    my ($self, $uri, %args) = @_;
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
    my $decoded = do {
        my $res = await $self->ua->GET(
            $uri
        );
        decode_json_utf8($res->decoded_content);
    };
    $log->tracef('=> %s', $decoded);
    return map {
        WebService::Async::SmartyStreets::Address->new(
            %$_
        )
    } @$decoded;
}

1;

