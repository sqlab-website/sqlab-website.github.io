---
title: 業績
permalink: /publications/
---

<section class="page-header">
  <p class="eyebrow">Publications</p>
  <h1>研究業績</h1>
  <p>主要な論文、発表、受賞を掲載します。</p>
</section>

<section class="section">
  <ol class="publication-list">
    {% for pub in site.data.publications %}
      <li{% if pub.id %} id="{{ pub.id }}"{% endif %}>
        <span class="publication-list__year">{{ pub.year }}</span>
        {% if pub.doi %}
          {% assign doi_url = pub.doi %}
          {% unless doi_url contains '://' %}
            {% assign doi_url = pub.doi | prepend: 'https://doi.org/' %}
          {% endunless %}
          <strong><a href="{{ doi_url }}">{{ pub.title }}</a></strong>
        {% else %}
          <strong>{{ pub.title }}</strong>
        {% endif %}
        <p>{{ pub.authors }} / {{ pub.publisher }}</p>
      </li>
    {% endfor %}
  </ol>
</section>
