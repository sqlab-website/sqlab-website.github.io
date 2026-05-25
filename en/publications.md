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
  <div class="publication-search" data-publication-search>
    <div class="publication-search__controls">
      <label class="publication-search__field">
        <span class="publication-search__label">Type</span>
        <select class="publication-search__select" data-publication-type-filter>
          <option value="all">All</option>
          <option value="journal">Journal</option>
          <option value="proceedings">Proceedings</option>
          <option value="techreport">Techreport</option>
        </select>
      </label>
      <label class="publication-search__field">
        <span class="publication-search__label">Search publications</span>
        <input id="publication-search-input" class="publication-search__input" type="search" placeholder="Search by title, author, venue, or year" autocomplete="off" data-publication-search-input>
      </label>
    </div>
    <p class="publication-search__status" aria-live="polite" data-publication-search-status></p>
  </div>

  <ol class="publication-list" data-publication-list>
    {% for pub in site.data.publications_en %}
      {% capture publication_type %}
        {% if pub.entry_type == 'techreport' %}
          techreport
        {% elsif pub.entry_type == 'inproceedings' %}
          proceedings
        {% elsif pub.entry_type == 'article' or pub.entry_type == 'journal' %}
          journal
        {% endif %}
      {% endcapture %}
      {% assign publication_type_key = publication_type | strip %}
      <li{% if pub.id %} id="{{ pub.id }}"{% endif %} data-publication-item data-publication-type="{{ publication_type_key }}" data-search-text="{{ pub.year | append: ' ' | append: publication_type | append: ' ' | append: pub.title | append: ' ' | append: pub.authors | append: ' ' | append: pub.publisher | strip_html | normalize_whitespace | escape }}">
        <div class="publication-list__meta">
          <span class="publication-list__year">{{ pub.year }}</span>
          {% assign publication_type_label = publication_type | strip %}
          {% if publication_type_label != '' %}
            <span class="publication-list__type">{{ publication_type_label }}</span>
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

<script>
  (() => {
    const search = document.querySelector("[data-publication-search]");
    const typeFilter = document.querySelector("[data-publication-type-filter]");
    const input = document.querySelector("[data-publication-search-input]");
    const status = document.querySelector("[data-publication-search-status]");
    const items = Array.from(document.querySelectorAll("[data-publication-item]"));

    if (!search || !typeFilter || !input || !status || items.length === 0) {
      return;
    }

    search.classList.add("publication-search--ready");

    const normalize = (value) => value.toLowerCase().replace(/\s+/g, " ").trim();
    const total = items.length;

    const update = () => {
      const selectedType = typeFilter.value;
      const terms = normalize(input.value).split(" ").filter(Boolean);
      let visible = 0;

      items.forEach((item) => {
        const text = normalize(item.dataset.searchText || item.textContent || "");
        const typeMatches = selectedType === "all" || item.dataset.publicationType === selectedType;
        const textMatches = terms.every((term) => text.includes(term));
        const matches = typeMatches && textMatches;
        item.hidden = !matches;
        if (matches) {
          visible += 1;
        }
      });

      status.textContent = terms.length === 0
        ? `Showing ${visible} of ${total} publications.`
        : `${visible} of ${total} publications found.`;
    };

    typeFilter.addEventListener("change", update);
    input.addEventListener("input", update);
    update();
  })();
</script>
