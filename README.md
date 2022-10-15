
[![Build Status](https://github.com/un3481/exgooglenews/workflows/tests/badge.svg?branch=main)](https://github.com/un3481/exgooglenews/actions) [![Hex pm](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hex.pm/packages/googlenews) [![Hexdocs.pm](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/googlenews/)

# Googlenews
If Google News had an Elixir library

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/googlenews>.

### Table of Contents
- [About](#about)
- [Examples of Use Cases](#usecase)
- [Working with Google News in Production](#production)
- [Motivation](#motivation)
- [Installation](#installation)
- [Quickstart](#quickstart)
- [Documentation](#documentation)
- [Advanced Query Search Examples](#examples)
- [About me](#aboutme)
- [Change Log](#changelog)

<a name="about"/>

## **About**

An Elixir wrapper of the Google News RSS feed.

Top stories, topic related news feeds, geolocation news feed, and an extensive full text search feed.

### **How is it different from other Google News libraries?**

1. URL-escaping user input helper for the search function
2. Extensive support for the search function that makes it simple to use:
    - exact match
    - in title match, in url match, etc
    - search by date range (`from` & `to`), latest published (`when`)
3. Parsing of the sub articles. Almost always, all feeds except the search one contain a subset of similar news for each article in a feed. This package takes care of extracting those sub articles. This feature might be highly useful to ML task when you need to collect a data of similar article headlines

<a name="usecase"/>

## Examples of Use Cases

1. Integrating a news feed to your platform/application/website
2. Collecting data by topic to train your own ML model
3. Search for latest mentions for your new product
4. Media monitoring of people/organizations — PR


<a name="production"/>

## Working with Google News in Production

Before we start, if you want to integrate Google News data to your production then I would advise you to use one of the 2 methods described below. Why? Because you do not want your servers IP address to be locked by Google. Every time you call any function there is an HTTPS request to Google's servers. **Don't get me wrong, this package still works out of the box.**

1. [ScrapingBee API](https://www.scrapingbee.com?fpr=artem26) which handles proxy rotation for you. Each function in this package has `scraping_bee` parameter where you paste your API key. You can also try it for free, no credit card required. See [example](#scrapingbeeexample)
2. Your own proxy — already have a pool of proxies? Each function in this package has `proxy` parameter (elixir tuple) where you just paste your own proxy. 

<a name="motivaion"/>

## **Motivation**

I wanted to implement functionalities from [pygooglenews](https://github.com/kotartemiy/pygooglenews) into an elixir environment.

**This package uses the RSS feed of the Google News. The [top stories page](https://news.google.com/rss), for example.**

RSS is an XML page that is already well structured. The package [FeederEx](https://github.com/manukall/feeder_ex/) was used to parse the RSS feed.

Google News used to have an API but it was deprecated many years ago. (Unofficial) information 
about RSS syntax is decentralized over the web. There is no official documentation.


<a name="installation"/>

## **Installation**

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `googlenews` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:googlenews, "~> 0.1.0"}
  ]
end
```


<a name="quickstart"/>

## **Quickstart**

### **Top Stories**

```elixir
{:ok, top} = Googlenews.top_news()
```

### **Stories by Topic**

```elixir
{:ok, business} = Googlenews.topic_headlines("business")

```

### **Geolocation Specific Stories**

```elixir
{:ok, headquaters} = Googlenews.geo_headlines("San Fran")

```

### **Stories by a Query Search**

```elixir
# search for the best matching articles that mention MSFT and 
# do not mention AAPL (over the past 6 months)
{:ok, search} = Googlenews.search("MSFT -APPL", when: "6m")

```

---
<a name="documentation"/>

## **Documentation - Functions**

### **Language & region**

```elixir
# default 'lang' and 'country' parameters
{:ok, top} = GoogleNews.top_news(lang: "en", country: "US")

```

Every function can accept `:lang` and `:country` options. 

You can try any combination of those 2, however, it does not exist for all. Only the combinations that are supported by Google News will work. Check the official Google News page to check what is covered:

On the bottom left side of the Google News page you may find a `Language & region` section where you can find all of the supported combinations.


For example, for `country: "UA"` (Ukraine), there are 2 languages supported:

- `lang: "uk"` Ukrainian
- `lang: "ru"` Russian

---

### **Top Stories**

```elixir
# returns the top stories for current 'lang' and 'country'
{:ok, top} = Googlenews.top_news()

```

`top_news()` returns the top stories for the selected country and language that are defined in `lang` and `country` arguments. The returned object contains `feed` (FeedParserDict) and `entries` list of articles found with all data parsed.

---

### **Stories by Topic**

```elixir
# returns top stories for 'buisness' topic
{:ok, business} = Googlenews.topic_headlines("business")

```

The returned object contains `feed` (FeedParserDict) and `entries` list of articles found with all data parsed.

Accepted topics are:

- `WORLD`
- `NATION`
- `BUSINESS`
- `TECHNOLOGY`
- `ENTERTAINMENT`
- `SCIENCE`
- `SPORTS`
- `HEALTH`

However, you can find some other topics that are also supported by Google News.

For example, if you search for `corona` in the search tab of `en` + `US` you will find `COVID-19` as a topic.

The URL looks like this: `https://news.google.com/topics/CAAqIggKIhxDQkFTRHdvSkwyMHZNREZqY0hsNUVnSmxiaWdBUAE?hl=en-US&gl=US&ceid=US%3Aen`

We have to copy the text after `topics/` and before `?`, then you can use it as an input for the `top_news()` function.

```elixir
# custom topic that can be passed as argument to 'topic_headlines' function 
topic = "CAAqIggKIhxDQkFTRHdvSkwyMHZNREZqY0hsNUVnSmxiaWdBUAE"

{:ok, covid} = Googlenews.topic_headlines(topic)

```

**However, be aware that this topic will be unique for each language/country combination.**

---

### **Stories by Geolocation**

```elixir
{:ok, kyiv} = Googlenews.geo_headlines("kyiv", lang: "uk", country: "UA")
# or 
{:ok, kyiv} = Googlenews.geo_headlines("kiev", lang: "uk", country: "UA")
# or
{:ok, kyiv} = Googlenews.geo_headlines("киев", lang: "uk", country: "UA")
# or
{:ok, kyiv} = Googlenews.geo_headlines("Київ", lang: "uk", country: "UA")

```

The returned object contains `feed` (FeedParserDict) and `entries` list of articles found with all data parsed.

All of the above variations will return the same feed of the latest news about Kyiv, Ukraine:

```elixir
geo.feed.title

# 'Київ - Останні - Google Новини'

```

It is language agnostic, however, it does not guarantee that the feed for any specific place will exist.

For example, if you want to find the feed on `LA` or `Los Angeles` you can do it with `GoogleNews.top_news(lang: "en", country: "US")`.

The main (`en`, `US`) Google News client will most likely find the feed about the most places.

---

### **Stories by a Query**

```elixir
# search for news containing 'boing' from 24 feburary to 15 september
{:ok, search} = Googlenews.search("boeing", from: "2022-02-24", to: "2022-09-15")

```

The returned object contains `feed` (FeedParserDict) and `entries` list of articles found with all data parsed.

Google News search itself is a complex function that has inherited some features from the standard Google Search.

[The official reference on what could be inserted](https://developers.google.com/custom-search/docs/xml_results)

The biggest obstacle that you might have is to write the URL-escaping input. To ease this process, `helper: true` is turned on by default.

`helper` uses `URI.encode` to automatically convert the input.

For example:

- `'New York metro opening'` --> `'New+York+metro+opening'`
- `'AAPL -MSFT'` --> `'AAPL+-MSFT'`
- `'"Tokyo Olimpics date changes"'` --> `'%22Tokyo+Olimpics+date+changes%22'`

You can turn it off and write your own query in case you need it by `helper: false`

`when` parameter sets the time range for the published datetime. This option appears to work as following:

- `h` for hours. `when: "12h"` will search for only the articles matching the `search` criteria and published for the last 12 hours
- `d` for days.
- `m` for month.

You may try put here anything. Probably, it will work. However, wrong inputs will not lead to an error. Instead, the `when` parameter will be ignored by Google.

`from` and `to` accept the following format of date: `%Y-%m-%d` For example, `2020-07-01` 

---

**[Google's Special Query Terms](https://developers.google.com/custom-search/docs/xml_results#special-query-terms) Cheat Sheet**

Many Google's Special Query Terms have been tested one by one. Most of the core ones have been inherited by Google News service. 

Here is an example of those operators.

* Boolean OR Search [ OR ]

```elixir
{:ok, search} = Googlenews.search("boeing OR airbus")

search.feed.title
# "boeing OR airbus" - Google News

```

* Exclude Query Term [-]

"The exclude (`-`) query term restricts results for a particular search request to documents that do not contain a particular word or phrase. To use the exclude query term, you would preface the word or phrase to be excluded from the matching documents with "-" (a minus sign)."

* Include Query Term [+]

"The include (`+`) query term specifies that a word or phrase must occur in all documents included in the search results. To use the include query term, you would preface the word or phrase that must be included in all search results with "+" (a plus sign).

The URL-escaped version of **`+`** (a plus sign) is `%2B`."


* Phrase Search

"The phrase search (`"`) query term allows you to search for complete phrases by enclosing the phrases in quotation marks or by connecting them with hyphens.

The URL-escaped version of **`"`** (a quotation mark) is **`%22`**.

Phrase searches are particularly useful if you are searching for famous quotes or proper names."

* allintext

"The **`allintext:`** query term requires each document in the search results to contain all of the words in the search query in the body of the document. The query should be formatted as **`allintext:`** followed by the words in your search query.

If your search query includes the **`allintext:`** query term, Google will only check the body text of documents for the words in your search query, ignoring links in those documents, document titles and document URLs."

* intitle

"The `intitle:` query term restricts search results to documents that contain a particular word in the document title. The search query should be formatted as `intitle:WORD` with no space between the intitle: query term and the following word."

* allintitle

"The **`allintitle:`** query term restricts search results to documents that contain all of the query words in the document title. To use the **`allintitle:`** query term, include "allintitle:" at the start of your search query.

Note: Putting **`allintitle:`** at the beginning of a search query is equivalent to putting [intitle:](https://developers.google.com/custom-search/docs/xml_results#TitleSearchqt) in front of each word in the search query."

* inurl

"The `inurl:` query term restricts search results to documents that contain a particular word in the document URL. The search query should be formatted as `inurl:WORD` with no space between the inurl: query term and the following word"

* allinurl

The `allinurl:` query term restricts search results to documents that contain all of the query words in the document URL. To use the `allinurl:` query term, include allinurl: at the start of your search query.


**Tip**. If you want to build a near real-time feed for a specific topic, use `when='1h'`. If Google captured fewer than 100 articles over the past hour, you should be able to retrieve all of them.

Check the [Useful Links](notion://www.notion.so/Google-News-API-Documentation-b95117b9ecd94076bb1d8cf7c2957d78#useful-links) section if you want to dig into how Google Search works.

Especially, [Special Query Terms](https://developers.google.com/custom-search/docs/xml_results#special-query-terms) section of Google XML reference.

---

### **Output Body**

```elixir
# destructuring return of 'top_news' function into 'feed' and 'entries'
{:ok, %{feed: feed, entries: entries}} = Googlenews.top_news()

```

All 4 functions return a `map` that contains 2 items:

- `feed` - contains the information on the feed metadata
- `entries` - contains the parsed articles

Both are inherited from [FeederEx](https://github.com/manukall/feeder_ex/) package. The only change is that each dictionary under `entries` also contains `sub_articles` which are the similar articles found in the description. Usually, it is non-empty for `top_news()` and `topic_headlines()` feeds.

**Tip** To check what is the found feed's name just check the `title` under the `feed` dictionary

---
<a name="scrapingbeeexample"/>

## How to use Googlenews with [ScrapingBee](https://www.scrapingbee.com?fpr=artem26)

Every function has `:scraping_bee` option. It accepts your [ScrapingBee](https://www.scrapingbee.com?fpr=artem26) API key that will be used to get the response from Google's servers. 

You can take a look at what exactly is happening in the source code: check for `get_feed()` function under Googlenews module

Pay attention to the concurrency of each plan at [ScrapingBee](https://www.scrapingbee.com?fpr=artem26)
 
How to use example:

```elixir
# it's a fake API key, do not try to use it
api_key = "I5SYNPRFZI41WHVQWWUT0GNXFMO104343E7CXFIISR01E2V8ETSMXMJFK1XNKM7FDEEPUPRM0FYAHFF5"

{:ok, top} = Googlenews.top_news(scraping_bee: api_key)
```

---

## How to use Googlenews with a proxy

You can use your own HTTP/HTTPS proxy(s) to make requests to Google.

Proxying is enabled through the `:proxy` option. The proxy must be provided in a format supported by the [Mint](https://github.com/elixir-mint/mint) package: A tuple `{scheme, address, port, opts}` that identifies the proxy to connect to. 

How to use example:

```elixir
# proxy with scheme 'https', ip '34.91.135.38' and port '80'
https_proxy = {:https, "34.91.135.38", 80, []}

{:ok, top} = Googlenews.top_news(proxy: https_proxy)
```

---
<a name="examples"/>

## **Advanced Querying Search Examples**

### **Example 1. Search for articles that mention `boeing` and do not mention `airbus`**

```elixir
{:ok, search} = Googlenews.search("boeing -airbus")

search.feed.title
# "boeing -airbus" - Google News

```

### **Example 2. Search for articles that mention `boeing` in title**

```elixir
{:ok, search} = Googlenews.search("intitle:boeing")

search.feed.title
# "intitle:boeing" - Google News

```

### **Example 3. Search for articles that mention `boeing` in title and got published over the past hour**

```elixir
{:ok, search} = Googlenews.search("intitle:boeing", when: "1h")

search.feed.title
# "intitle:boeing when:1h" - Google News

```

### **Example 4. Search for articles that mention `boeing` or `airbus`**

```elixir
{:ok, search} = Googlenews.search("boeing OR airbus", when: "1h")

search.feed.title
# "boeing AND airbus when:1h" - Google News

```

---
<a name="useful-links"/>

## **Useful Links**

[Stack Overflow thread from which it all began](https://stackoverflow.com/questions/51537063/url-format-for-google-news-rss-feed)

[Google XML reference for the search query](https://developers.google.com/custom-search/docs/xml_results)

[Google News Search parameters (The Missing Manual)](http://web.archive.org/web/20150204025359/http://blog.slashpoundbang.com/post/12975232033/google-news-search-parameters-the-missing-manual)

---
<a name="built"/>

## **Built With**

[FeederEx](https://github.com/manukall/feeder_ex/)

[Floki](https://github.com/philss/floki/)

[Req](https://github.com/wojtekmach/req)

