#!/usr/bin/env perl 
use strict;
use warnings;

use Future::AsyncAwait;

use IO::Async::Loop;
use WebService::Async::SmartyStreets;

use Log::Any qw($log);
use Log::Any::Adapter qw(Stdout), log_level => 'trace';

my $loop = IO::Async::Loop->new;
$loop->add(
    my $ss = WebService::Async::SmartyStreets->new(
        # International token
        auth_id => '...'
        token => '...'
    )
);

(async sub {
    my $addr = await $ss->verify_international(
        address1            => 'Jl.pelabuhan 2 gang langgeng jaya 2 no 22',
        address2            => '03/03',
        locality            => 'Sukabumi',
        administrative_area => 'JB',
        postal_code         => '43145',
        country             => 'Indonesia',
        # Need to pass this if you want to do verification
        geocode             => 'true',
    );

    $log->infof('Verification status: %s', $addr->status);
    $log->warnf('Inaccurate address - only verified to %s precision', $addr->precision) unless $addr->accuracy_at_least('street');
    $log->infof('Address info is %s', { %$addr });
})->()->get;

