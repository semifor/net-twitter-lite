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
apirealm
APIs
apiurl
BasicUser
clientname
clienturl
clientver
contributees
cursored
DirectMessage
ExtendedUser
favorited
friended
geo
geocode
GPS
granularities
Identi
Identica
identica
IM
inline
IP
ip
IRC
Laconica
lang
maxwidth
Mims
multipart
netrc
OAUTH
OAuth
oEmbed
oembed
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
RWD
SavedSearch
SMS
spammer
SSL
ssl
Str
stringifies
timeline
Twitter's
twitterpm
twittervision
TwitterVision
Un
un
unfollow
Unsubscribes
url
useragent
username
usernames
WiFi
WOEID
woeid
XAuth
xauth
