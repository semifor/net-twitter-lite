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
BasicUser
DirectMessage
ExtendedUser
IM
IP
IRC
Identica
Mims
OAUTH
OAuth
RateLimitStatus
SavedSearch
SMS
Str
Un
apiurl
clientname
clienturl
clientver
favorited
friended
geocode
identica
inline
lang
multipart
netrc
ok
requester's
return's
retweet
retweeted
retweeting
Retweets
retweets
rpp
SSL
ssl
stringifies
timeline
twitterpm
twittervision
un
unfollow
url
useragent
username
