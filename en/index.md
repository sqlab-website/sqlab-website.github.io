---
title: Home
permalink: /en/
lang: en
site_title: Yuen/Nakazawa Laboratory
---

<section class="hero">
  <div class="hero__content">
    <p class="hero__labcode">SQLAB</p>
    <p class="eyebrow">{{ site.lab.university_en }}</p>
    <h1>{{ site.title_en }}</h1>
    <div class="hero__actions">
      <a class="button" href="{{ '/en/events/' | relative_url }}">View Events</a>
    </div>
    <p class="hero__location">
      <span>Address</span>
      {{ site.lab.address_en }}
    </p>
  </div>
  <img class="hero__image" src="{{ '/assets/images/lab-hero.svg' | relative_url }}" alt="Theoretical programming and proof-oriented research visual">
</section>

<section class="section">
  <div class="section__heading">
    <p class="eyebrow">Research Topics</p>
    <h2>Research</h2>
  </div>
  <div class="feature-grid">
    {% for item in site.data.research_en limit:3 %}
      <article class="feature">
        <h3>{{ item.title }}</h3>
        <p>{{ item.summary }}</p>
        <a href="{{ '/en/research/' | relative_url }}#{{ item.id }}">Learn more</a>
      </article>
    {% endfor %}
  </div>
</section>

<section class="section section--muted">
  <div class="section__heading">
    <p class="eyebrow">Events</p>
    <h2>Upcoming Events</h2>
  </div>
  <div class="event-list">
    {% for event in site.data.events_en limit:2 %}
      <article class="event-item">
        <time datetime="{{ event.date }}">{{ event.date | date: "%Y.%m.%d" }}</time>
        <div>
          <p class="eyebrow">{{ event.type }}</p>
          <h2>{{ event.title }}</h2>
          <p>{{ event.description }}</p>
        </div>
      </article>
    {% endfor %}
  </div>
</section>

<section class="section section--split">
  <div>
    <p class="eyebrow">Contact</p>
    <h2>Prospective Students and Collaborators</h2>
    <p>
      Please contact us if you are interested in joining the lab, discussing graduate study, or exploring research collaboration.
    </p>
  </div>
  <a class="button" href="{{ '/en/contact/' | relative_url }}">Contact Us</a>
</section>
