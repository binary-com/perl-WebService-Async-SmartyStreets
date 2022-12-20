# NAME

WebService::Async::SmartyStreets - calls the SmartyStreets API and checks for the validity of the address

# SYNOPSIS

    my $ss = WebService::Async::SmartyStreets->new(
        # Obtain these from your SmartyStreets account page.
        # These will be used for US lookups
        us_auth_id => '...',
        us_token   => '...',
        # For non-US address lookups, you would also need an international token
        international_auth_id => '...',
        international_token   => '...',
    );
    IO::Async::Loop->new->add($ss);

    print $ss->verify(
        city => 'Atlanta',
        country => 'US',
        geocode => 1
    )->get->status;

# DESCRIPTION

This module provides basic support for the [SmartyStreets API](https://smartystreets.com/).

Note that this module uses [Future::AsyncAwait](https://metacpan.org/pod/Future%3A%3AAsyncAwait).

## verify

Makes connection to SmartyStreets API and parses the response into WebService::Async::SmartyStreets::Address.

    my $addr = $ss->verify(%address_to_check)->get;

Takes the following named parameters:

- `country` - country (required)
- `address1` - address line 1
- `address2` - address line 2
- `organization` - name of organization (usually building names)
- `locality` - city
- `administrative_area` - state
- `postal_code` - post code
- `geocode` - true or false

Returns a [Future](https://metacpan.org/pod/Future) which should resolve to a valid [WebService::Async::SmartyStreets::Address](https://metacpan.org/pod/WebService%3A%3AAsync%3A%3ASmartyStreets%3A%3AAddress) instance.

## METHODS - Accessors

# METHODS - Internal

## get\_decoded\_data

Calls the SmartyStreets API then decode and parses the response give by SmartyStreets

    my $decoded = await get_decoded_data($self, $uri)

Takes the following parameters:

- `$uri` - URI for endpoint

More information on the response can be seen in [SmartyStreets Documentation ](https://metacpan.org/pod/%20https%3A#smartystreets.com-docs-cloud-international-street-api).

Returns a [Future](https://metacpan.org/pod/Future) which resolves to an arrayref of [WebService::Async::SmartyStreets::Address](https://metacpan.org/pod/WebService%3A%3AAsync%3A%3ASmartyStreets%3A%3AAddress) instances.

## configure

Configures the instance.

Takes the following named parameters:

- `international_auth_id` - auth\_id obtained from SmartyStreet
- `international_token` - token obtained from SmartyStreet
- `us_auth_id` - auth\_id obtained from SmartyStreet
- `us_token` - token obtained from SmartyStreet

Note that you can provide US, international or both API tokens - if an API token
is not available for a ["verify"](#verify) call, then it will return a failed [Future](https://metacpan.org/pod/Future).

## ua

Accessor for the [Net::Async::HTTP](https://metacpan.org/pod/Net%3A%3AAsync%3A%3AHTTP) instance which will be used for SmartyStreets API requests.
