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
    {% assign sorted_news = site.news | sort: 'date' | reverse %}
    {% for post in sorted_news %}
      <a class="news-item" href="{{ post.url | relative_url }}">
        <time datetime="{{ post.date | date_to_xmlschema }}">{{ post.date | date: "%Y.%m.%d" }}</time>
        <span>{{ post.title }}</span>
      </a>
    {% endfor %}
  </div>
</section>

