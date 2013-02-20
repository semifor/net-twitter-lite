import re
import json
import types
import codecs

from scrapy.spider import BaseSpider
from scrapy.selector import HtmlXPathSelector
from scrapy.http import Request

from mscraper.items import SocialItem

class DocsTwitter(BaseSpider):

    name = 'docstwitter'
    
    index = 0
    end_urls = []
    start_urls = [
        'https://dev.twitter.com/docs/api/1.1'
    ]
    
    # write to perl
    tab = 'twitter'
    perl = codecs.open('output/docs_' + tab + '.pm', 'w', encoding='utf-8')
    
    def parse(self,response):
        hxs = HtmlXPathSelector(response)
        endpoints = hxs.select("id('content-main')/div/div/table/tbody/tr/td/a//@href").extract()
        
        for item in endpoints:
            itemUrl = 'https://dev.twitter.com' + item
            DocsTwitter.end_urls.append(itemUrl)
        
        return Request( url=DocsTwitter.end_urls[DocsTwitter.index], callback=self.parseEndpoint )
            
    
    def parseEndpoint(self,response):
        DocsTwitter.index += 1
    
        hxs = HtmlXPathSelector(response)
        
        title = hxs.select("id('title')//text()").extract()
        params = hxs.select("id('content-main')/div/div[@class='field text field-doc-params']/div/div")
        
        method = '';
        function = '';
        optional = []
        required = []
        bools = []
        
        title = ''.join(title)
        title = title.split(' ')
        
        method = title[0]
        function = title[1]
        
        for p in params:
            boolean = p.select(".//p[2]/tt//text()").extract()
            if len(boolean) > 0:
                boolean = boolean[0]
            else:
                boolean = ''
        
            essence = p.select(".//span/span//text()").extract()
            if len(essence) > 0:
                essence = essence[0]
            else:
                essence = ''
                
            name = p.select(".//span//text()").extract()
            if len(name) > 0:
                name = name[0]
            else:
                continue
            
            boolean = re.sub(r'^\s+','',boolean)
            boolean = re.sub(r'\s+$','',boolean)
            
            essence = re.sub(r'^\s+','',essence)
            essence = re.sub(r'\s+$','',essence)
            
            name = re.sub(r'^\s+','',name)
            name = re.sub(r'\s+$','',name)
            
            if boolean == 'true' or boolean == 'false':
                bools.append(name)
            
            optional.append(name)
            if essence == 'required':
                required.append(name)
        
        optionalParams = ' '.join(optional)
        requiredParams = ' '.join(required)
        boolParams = ' '.join(bools)
        
        output = """
{
    aliases         => [ qw// ],
    path            => '%s',
    method          => '%s',
    params          => [ qw/%s/ ],
    required        => [ qw/%s/ ],
    add_source      => 0,
    deprecated      => 0,
    authenticate    => 1,
    booleans        => [ qw/%s/ ],
    base_url_method => 'apiurl',
}
""" % (function,method,optionalParams,requiredParams,boolParams)

        DocsTwitter.perl.write(output)
        
        if DocsTwitter.index < len(DocsTwitter.end_urls):
            return Request( url=DocsTwitter.end_urls[DocsTwitter.index], callback=self.parseEndpoint )
        else:
            return None
        
        