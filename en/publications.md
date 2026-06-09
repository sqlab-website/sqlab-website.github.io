---
title: Publications
permalink: /en/publications/
lang: en
site_title: Yuen/Nakazawa Laboratory
---

<section class="page-header">
  <p class="eyebrow">Publications</p>
  <h1>Publications</h1>
  <p>Selected papers, presentations, and awards. (Under construction)</p>
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
        {% elsif pub.entry_type == 'poster' %}
          Poster
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
  <div class="publication-download">
    <button class="button publication-search__download" type="button" data-publication-bibtex-download>Download visible BibTeX</button>
    <p class="publication-search__status" aria-live="polite" data-publication-bibtex-status></p>
  </div>
</section>

<script>
  (() => {
    const search = document.querySelector("[data-publication-search]");
    const typeFilter = document.querySelector("[data-publication-type-filter]");
    const input = document.querySelector("[data-publication-search-input]");
    const status = document.querySelector("[data-publication-search-status]");
    const downloadButton = document.querySelector("[data-publication-bibtex-download]");
    const downloadStatus = document.querySelector("[data-publication-bibtex-status]");
    const items = Array.from(document.querySelectorAll("[data-publication-item]"));

    if (!search || !typeFilter || !input || !status || !downloadButton || !downloadStatus || items.length === 0) {
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

      const visibleBibtexCount = items.filter((item) => !item.hidden && item.querySelector(".publication-list__bibtex")).length;
      downloadButton.disabled = visibleBibtexCount === 0;
      downloadStatus.textContent = visibleBibtexCount === 0 ? "No BibTeX is available for the visible items." : "";
    };

    const bibtexEntryFrom = async (url) => {
      const response = await fetch(url);
      if (!response.ok) {
        throw new Error(`${response.status} ${url}`);
      }
      const html = await response.text();
      const doc = new DOMParser().parseFromString(html, "text/html");
      return doc.querySelector(".bibtex-entry code")?.textContent.trim() || "";
    };

    const downloadVisibleBibtex = async () => {
      const links = items
        .filter((item) => !item.hidden)
        .map((item) => item.querySelector(".publication-list__bibtex"))
        .filter(Boolean);

      if (links.length === 0) {
        downloadStatus.textContent = "No BibTeX is available for the visible items.";
        return;
      }

      downloadButton.disabled = true;
      downloadStatus.textContent = `Preparing ${links.length} BibTeX entries.`;

      try {
        const entries = (await Promise.all(links.map((link) => bibtexEntryFrom(link.href)))).filter(Boolean);
        if (entries.length === 0) {
          downloadStatus.textContent = "No BibTeX entries could be downloaded.";
          return;
        }

        const blob = new Blob([`${entries.join("\n\n")}\n`], { type: "application/x-bibtex;charset=utf-8" });
        const url = URL.createObjectURL(blob);
        const anchor = document.createElement("a");
        anchor.href = url;
        anchor.download = "sqlab-publications.bib";
        document.body.append(anchor);
        anchor.click();
        anchor.remove();
        URL.revokeObjectURL(url);
        downloadStatus.textContent = `Downloaded ${entries.length} BibTeX entries.`;
      } catch (error) {
        downloadStatus.textContent = "Failed to prepare BibTeX entries.";
        console.error(error);
      } finally {
        downloadButton.disabled = false;
      }
    };

    downloadButton.addEventListener("click", downloadVisibleBibtex);
    typeFilter.addEventListener("change", update);
    input.addEventListener("input", update);
    update();
  })();
</script>
