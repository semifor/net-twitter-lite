#!perl -w
use strict;
use warnings;
use Test::More;

plan skip_all => 'set TEST_POD to enable this test'
  unless ($ENV{TEST_POD} || -e 'MANIFEST.SKIP');

eval 'use Test::Spelling 0.11';
plan skip_all => 'Test::Spelling 0.11 not installed' if $@;

set_spell_cmd('aspell list');

add_stopwords(<DATA>);

all_pod_files_spelling_ok();

__DATA__
API
APIs
apiurl
BasicUser
clientname
clienturl
clientver
DirectMessage
ExtendedUser
favorited
friended
geo
geocode
Identica
identica
IM
inline
IP
IRC
lang
Mims
multipart
netrc
OAUTH
OAuth
ok
RateLimitStatus
requester's
return's
retweet
retweeted
retweeting
Retweets
retweets
rpp
SavedSearch
SMS
spammer
SSL
ssl
Str
stringifies
timeline
twitterpm
twittervision
Un
un
unfollow
url
useragent
username
WOEID
woeid
