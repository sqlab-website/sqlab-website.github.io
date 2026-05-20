---
title: Events
permalink: /en/events/
lang: en
site_title: Yuen/Nakazawa Laboratory
---

<section class="page-header">
  <p class="eyebrow">Events</p>
  <h1>Events</h1>
  <p>Information sessions, seminars, presentations, and open lab events.</p>
</section>

<section class="section">
  <div class="event-list">
    {% for event in site.data.events_en %}
      <article class="event-item">
        <time datetime="{{ event.date }}">{{ event.date | date: "%Y.%m.%d" }}</time>
        <div>
          <p class="eyebrow">{{ event.type }}</p>
          <h2>{{ event.title }}</h2>
          <p>{{ event.description }}</p>
          <dl>
            <div>
              <dt>Time</dt>
              <dd>{{ event.time }}</dd>
            </div>
            <div>
              <dt>Place</dt>
              <dd>{{ event.place }}</dd>
            </div>
          </dl>
        </div>
      </article>
    {% endfor %}
  </div>
</section>
