---
title: イベント
permalink: /events/
---

<section class="page-header">
  <p class="eyebrow">Events</p>
  <h1>イベント</h1>
  <p>研究室説明会、輪講、研究発表会、オープンラボなどの予定を掲載します。</p>
</section>

<section class="section">
  <div class="event-list">
    {% for event in site.data.events %}
      <article class="event-item">
        <time datetime="{{ event.date }}">{{ event.date | date: "%Y.%m.%d" }}</time>
        <div>
          <p class="eyebrow">{{ event.type }}</p>
          <h2>{{ event.title }}</h2>
          <p>{{ event.description }}</p>
          <dl>
            <div>
              <dt>時間</dt>
              <dd>{{ event.time }}</dd>
            </div>
            <div>
              <dt>場所</dt>
              <dd>{{ event.place }}</dd>
            </div>
          </dl>
        </div>
      </article>
    {% endfor %}
  </div>
</section>

