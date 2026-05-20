---
title: Members
permalink: /en/members/
lang: en
site_title: Yuen/Nakazawa Laboratory
---

<section class="page-header">
  <p class="eyebrow">Members</p>
  <h1>Members</h1>
  <p>Lab members and their research interests.</p>
</section>

<section class="section">
  <div class="member-grid">
    {% for member in site.data.members_en %}
      <article class="member-card">
        <div class="avatar" aria-hidden="true">{{ member.initial }}</div>
        <p class="eyebrow">{{ member.role }}</p>
        <h2>{{ member.name }}</h2>
        <p>{{ member.theme }}</p>
        {% if member.slug %}
          <a class="member-card__link" href="{{ '/en/members/' | append: member.slug | append: '/' | relative_url }}">Profile</a>
        {% endif %}
      </article>
    {% endfor %}
  </div>
</section>
