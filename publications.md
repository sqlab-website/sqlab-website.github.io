---
title: 業績
permalink: /publications/
---

<section class="page-header">
  <p class="eyebrow">Publications</p>
  <h1>研究業績</h1>
  <p>主要な論文、発表、受賞を掲載します。(作成中)</p>
</section>

<section class="section">
  <div class="publication-search" data-publication-search>
    <div class="publication-search__controls">
      <label class="publication-search__field">
        <span class="publication-search__label">種別</span>
        <select class="publication-search__select" data-publication-type-filter>
          <option value="all">すべて</option>
          <option value="journal">雑誌論文</option>
          <option value="proceedings">会議予稿</option>
          <option value="techreport">技術報告</option>
        </select>
      </label>
      <label class="publication-search__field">
        <span class="publication-search__label">業績を検索</span>
        <input id="publication-search-input" class="publication-search__input" type="search" placeholder="タイトル、著者、掲載先、年で検索" autocomplete="off" data-publication-search-input>
      </label>
    </div>
    <p class="publication-search__status" aria-live="polite" data-publication-search-status></p>
  </div>

  <ol class="publication-list" data-publication-list>
    {% for pub in site.data.publications %}
      {% capture publication_type %}
        {% if pub.entry_type == 'techreport' %}
          技術報告
        {% elsif pub.entry_type == 'inproceedings' %}
          会議予稿
        {% elsif pub.entry_type == 'article' or pub.entry_type == 'journal' %}
          雑誌論文
        {% elsif pub.entry_type == 'award' %}
          受賞
        {% endif %}
      {% endcapture %}
      {% capture publication_type_key %}
        {% if pub.entry_type == 'techreport' %}
          techreport
        {% elsif pub.entry_type == 'inproceedings' %}
          proceedings
        {% elsif pub.entry_type == 'article' or pub.entry_type == 'journal' %}
          journal
        {% elsif pub.entry_type == 'award' %}
          award
        {% endif %}
      {% endcapture %}
      <li{% if pub.id %} id="{{ pub.id }}"{% endif %} data-publication-item data-publication-type="{{ publication_type_key | strip }}" data-search-text="{{ pub.year | append: ' ' | append: publication_type | append: ' ' | append: pub.title | append: ' ' | append: pub.authors | append: ' ' | append: pub.publisher | strip_html | normalize_whitespace | escape }}">
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
        ? `${visible} / ${total}件の業績を表示しています。`
        : `${visible} / ${total}件の業績が見つかりました。`;
    };

    typeFilter.addEventListener("change", update);
    input.addEventListener("input", update);
    update();
  })();
</script>
