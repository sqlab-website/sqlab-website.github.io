---
title: Publications
permalink: /en/publications/
lang: en
site_title: Yuen/Nakazawa Laboratory
---

<section class="page-header">
  <p class="eyebrow">Publications</p>
  <h1>Publications</h1>
  <p>Selected papers, presentations, and awards.</p>
</section>

<section class="section">
  <ol class="publication-list">
    {% for pub in site.data.publications_en %}
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
