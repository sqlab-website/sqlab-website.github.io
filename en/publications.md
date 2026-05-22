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
        <div class="publication-list__meta">
          <span class="publication-list__year">{{ pub.year }}</span>
          {% if pub.entry_type == 'techreport' %}
            <span class="publication-list__type">techreport</span>
          {% elsif pub.entry_type == 'inproceedings' %}
            <span class="publication-list__type">proceedings</span>
          {% elsif pub.entry_type == 'article' or pub.entry_type == 'journal' %}
            <span class="publication-list__type">journal</span>
          {% endif %}
        </div>
        <div class="publication-list__title">
          {% if pub.doi %}
            {% assign doi_url = pub.doi %}
            {% unless doi_url contains '://' %}
              {% assign doi_url = pub.doi | prepend: 'https://doi.org/' %}
            {% endunless %}
            <strong><a href="{{ doi_url }}">{{ pub.title }}</a></strong>
          {% else %}
            <strong>{{ pub.title }}</strong>
          {% endif %}
          {% if pub.bibtex_url and pub.entry_type != 'award' %}
            {% assign bibtex_url_en = pub.bibtex_url | replace_first: '/publications/bibtex/', '/en/publications/bibtex/' %}
            <a class="publication-list__bibtex" href="{{ bibtex_url_en | relative_url }}" aria-label="Open BibTeX for {{ pub.title }}" title="BibTeX">BibTeX</a>
          {% endif %}
        </div>
        <p>
          {{ pub.authors }}<br>
          {{ pub.publisher }}
        </p>
      </li>
    {% endfor %}
  </ol>
</section>
