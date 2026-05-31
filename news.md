---
title: ニュース
permalink: /news/
---

<section class="page-header">
  <p class="eyebrow">News</p>
  <h1>お知らせ</h1>
</section>

<section class="section">
  <div class="news-list">
    {% assign today_key = site.time | date: "%Y%m%d" | plus: 0 %}
    {% assign sorted_news = site.news | sort: 'date' | reverse %}
    {% for post in sorted_news %}
      {% assign show_until_key = post.show_until | date: "%Y%m%d" | plus: 0 %}
      {% if post.show_until == nil or post.show_until == "" or today_key < show_until_key %}
        <a class="news-item" href="{{ post.url | relative_url }}">
          <time datetime="{{ post.date | date_to_xmlschema }}">{{ post.date | date: "%Y.%m.%d" }}</time>
          <span>{{ post.title }}</span>
        </a>
      {% endif %}
    {% endfor %}
  </div>
</section>
