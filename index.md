---
title: ホーム
permalink: /
---

<section class="hero">
  <div class="hero__content">
    <p class="hero__labcode">SQLAB</p>
    <p class="eyebrow">{{ site.lab.university }}</p>
    <h1>{{ site.title }}</h1>
    <div class="hero__actions">
      <a class="button" href="{{ '/events/' | relative_url }}">イベントを見る</a>
    </div>
    <p class="hero__location">
      <span>所在地</span>
      {{ site.lab.address }}
    </p>
  </div>
  <img class="hero__image" src="{{ '/assets/images/lab-hero.svg' | relative_url }}" alt="研究データとネットワークを表す抽象ビジュアル">
</section>

<section class="section section--muted">
  <div class="section__heading">
    <p class="eyebrow">News</p>
    <h2>お知らせ</h2>
  </div>
  <div class="news-list">
    {% assign latest_news = site.news | sort: 'date' | reverse %}
    {% for post in latest_news limit:4 %}
      <a class="news-item" href="{{ post.url | relative_url }}">
        <time datetime="{{ post.date | date_to_xmlschema }}">{{ post.date | date: "%Y.%m.%d" }}</time>
        <span>{{ post.title }}</span>
      </a>
    {% endfor %}
  </div>
</section>

<section class="section">
  <div class="section__heading">
    <p class="eyebrow">Research Topics</p>
    <h2>研究テーマ</h2>
  </div>
  <div class="feature-grid">
    {% for item in site.data.research limit:3 %}
      <article class="feature">
        <h3>{{ item.title }}</h3>
        <p>{{ item.summary }}</p>
        <a href="{{ '/research/' | relative_url }}#{{ item.id }}">詳しく見る</a>
      </article>
    {% endfor %}
  </div>
</section>
