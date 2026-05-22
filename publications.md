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
        <div class="publication-list__meta">
          <span class="publication-list__year">{{ pub.year }}</span>
          {% if pub.entry_type == 'techreport' %}
            <span class="publication-list__type">技術報告</span>
          {% elsif pub.entry_type == 'inproceedings' %}
            <span class="publication-list__type">会議録</span>
          {% elsif pub.entry_type == 'article' or pub.entry_type == 'journal' %}
            <span class="publication-list__type">雑誌論文</span>
          {% elsif pub.entry_type == 'award' %}
            <span class="publication-list__type">受賞</span>
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
            <a class="publication-list__bibtex" href="{{ pub.bibtex_url | relative_url }}" aria-label="{{ pub.title }} のBibTeXを開く" title="BibTeX">BibTeX</a>
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
