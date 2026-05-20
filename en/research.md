---
title: Research
permalink: /en/research/
lang: en
site_title: Yuen/Nakazawa Laboratory
---

<section class="page-header">
  <p class="eyebrow">Research</p>
  <h1>Research</h1>
  <p>We study programming, information systems, and computation through theoretical and formal perspectives.</p>
</section>

<section class="section">
  <div class="stack">
    {% for item in site.data.research_en %}
      <article class="research-block" id="{{ item.id }}">
        <div>
          <p class="eyebrow">{{ item.area }}</p>
          <h2>{{ item.title }}</h2>
        </div>
        <p>{{ item.description }}</p>
        <ul class="tag-list">
          {% for tag in item.tags %}
            <li>{{ tag }}</li>
          {% endfor %}
        </ul>
      </article>
    {% endfor %}
  </div>
</section>
